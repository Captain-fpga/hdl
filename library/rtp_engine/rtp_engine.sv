module rtp_engine #(
  parameter         S_TDATA_WIDTH = 32,
  parameter         S_TDEST_WIDTH = 4,
  parameter         S_TUSER_WIDTH = 96,
  parameter         M_TDATA_WIDTH = 16,
  parameter         M_TID_WIDTH = 1,
  parameter         M_TDEST_WIDTH = 4,
  parameter         M_TUSER_WIDTH = 1,
  parameter         SSRC_ID = 0,
  parameter         INTERV_FRAME = 30,
  parameter         VERSION = 1
  ) (

  input  logic                          aclk,
  input  logic                          aresetn,

  /* input axi stream slave interface */

  input  logic                          s_axis_tvalid,
  input  logic [(S_TDATA_WIDTH-1):0]    s_axis_tdata,
  input  logic                          s_axis_tlast,
  input  logic [(S_TDEST_WIDTH-1):0]    s_axis_tdest,
  input  logic [(S_TUSER_WIDTH-1):0]    s_axis_tuser,
  output logic                          s_axis_tready,

  /* output axi stream master interface */

  output  logic                         m_axis_tvalid,
  output  logic [(M_TDATA_WIDTH-1):0]   m_axis_tdata,
  output  logic [(M_TDATA_WIDTH-1)/8:0] m_axis_tstrb,
  output  logic [(M_TDATA_WIDTH-1)/8:0] m_axis_tkeep,
  output  logic                         m_axis_tlast,
  output  logic [(M_TID_WIDTH-1):0]     m_axis_tid,
  output  logic [(M_TDEST_WIDTH-1):0]   m_axis_tdest,
  output  logic [(M_TUSER_WIDTH-1):0]   m_axis_tuser,
  output  logic                         m_axis_twakeup,
  input   logic                         m_axis_tready,

  /* ptp-ts-formats - 64 bits/96 and pps signal */

  input   logic [95:0]                 ptp_ts_96,
  input   logic [63:0]                 ptp_ts_64,
  input   logic                        ptp_pps,
  input   logic                        ptp_clk,

  // axi interface

  input   logic                        s_axi_aclk,
  input   logic                        s_axi_aresetn,
  input   logic                        s_axi_awvalid,
  input   logic [15:0]                 s_axi_awaddr,
  input   logic [ 2:0]                 s_axi_awprot,
  output  logic                        s_axi_awready,
  input   logic                        s_axi_wvalid,
  input   logic [31:0]                 s_axi_wdata,
  input   logic [ 3:0]                 s_axi_wstrb,
  output  logic                        s_axi_wready,
  output  logic                        s_axi_bvalid,
  output  logic [ 1:0]                 s_axi_bresp,
  input   logic                        s_axi_bready,
  input   logic                        s_axi_arvalid,
  input   logic [15:0]                 s_axi_araddr,
  input   logic [ 2:0]                 s_axi_arprot,
  output  logic                        s_axi_arready,
  output  logic                        s_axi_rvalid,
  output  logic [ 1:0]                 s_axi_rresp,
  output  logic [31:0]                 s_axi_rdata,
  input   logic                        s_axi_rready

);

  /* internal axi4-lite signals */
  wire            up_clk;
  wire            up_rstn;
  wire            up_rreq_s;
  wire            up_wack_s;
  wire            up_rack_s;
  wire   [13:0]   up_raddr_s;
  wire   [31:0]   up_rdata_s;
  wire            up_wreq_s;
  wire   [13:0]   up_waddr_s;
  wire   [31:0]   up_wdata_s;

  wire   [15:0]   seq_number_h;
  wire   [15:0]   seq_number_l;

  assign up_clk = s_axi_aclk;
  assign up_rstn = s_axi_aresetn;

  /*
  * Master interface of the CSI-2 RX susbystem
  * out- video_out_tvalid - data valid
  * in- video_out_tready - slave ready to accept data
  * out- video_out_tuser - bits - 96 possible:
	  * 95-80 CRC
	  * 79-72 ECC
	  * 71-70 Reserved
	  * 69-64 Data type
	  * 63-48 Word count
	  * 47-32 Line number
	  * 31-16 Frame number
	  * 15-2 Reserved
	  * 1 Packet error
	  * 0 Start of frame
  * out- video_out_tlast - end of line
  * out- video_out_tdata - data
  * out- video_out_tdest -
	  * 9-4 Data
	  * 3-0 Virtual channel identifier (VC)
  * */

  localparam RTP_CLK = 90000;
  localparam RTP_INCREASE = RTP_CLK/INTERV_FRAME;
  localparam NUM_LINES = 1080;
  localparam NUM_PIX_PER_PCKT = 2231;//2231 * 2 pix/pgroup = 4462 pixels per packet

  /* 3 length fields = 4462 */
  /* 2.3 lines per packet -> 2 line number fields  */
  /* 3 field identification fields*/
  /* 3 continuation fields */
  /* 3 offset fields fields */

  import rtp_engine_package::*;

  rtp_pckt_header rtp_header;
  rtp_payload_header rtp_pd_header;

  reg [31:0]   data_video_r = 1'b0;
  reg          s_axis_tready_r = 1'b0;
  reg [8:0]    count_packets = 'h0;
  reg          l_pckt_frame = 1'b0;
  reg          rtp_pckt_sent = 1'b0;
  reg          end_of_packet = 1'b0;
  reg          m_axis_tuser_r = 1'b0;

  reg [15:0]   ext_seq_num_r = 'h0;

  state_vid_fr transfer_state;
  state_rtp_pckt rtp_pckt_state;
  state_vid_fr transfer_state_next;
  state_rtp_pckt rtp_pckt_state_next;

  reg  [10:0]  line_counter = 'h0;
  reg  [11:0]  pix_counter = 'h0;
  reg          pause_pckt = 'h0;
  wire         start_transfer_s;
  wire         start_pckt;
  wire         end_of_rtp_pckt;
//  wire         start_of_vid_fram;

  // tready of the slave is off when the module is in reset - whole system is
  // in reset
  always @(posedge aclk) begin
    if (!aresetn) begin
      s_axis_tready_r <= 1'b0;
    end else begin
      s_axis_tready_r <= 1'b1;
    end
  end

  always @(posedge aclk) begin
    if (!aresetn) begin
      data_video_r <= 'h0;
    end else begin
      if (s_axis_tready & s_axis_tvalid) begin
        data_video_r <= s_axis_tdata; //2 pixels received in one clock cycle 
      end
    end
  end

  //tuser data related to start of frame
  // sof_ind

  assign s_axis_tready = s_axis_tready_r;

  assign rtp_header.version = 'h2; //rtp version 2 for rfc3550 - used as is in rfc 4175 for uncrompressed video
  assign rtp_header.padding = 'h0; //no padding at the end of packets
  assign rtp_header.extension = 'h0; //no extensions to the header
  assign rtp_header.csrc_count = 'h0; //1 source from 8 cameras in the system
  // assign rtp_header.marker =  for last packet in frame in this case of
  // progressive scan video
  assign rtp_header.payload_type = 'd96; //uncrompressed video
  // assign rtp_header.sequence_number = low-order bits of RTP sequence number
  // + 16 bits in payload header
  // assign rtp_header.timestamp = progressive video - same timestamp for
  // packets related to same frame
  //
  // will be assigned per rtp engine instance
  assign rtp_header.ssrc_field = SSRC_ID;

 
  // assign rtp_pd_header.ext_seq_num = / extended sequence number in nbo
  // assign rtp_pd_header.length = / num B data in scan line - nbo
  assign rtp_pd_header.field_identif_l1 = 'h0; // 0 for progressive video - field identification
  assign rtp_pd_header.field_identif_l2 = 'h0; // 0 for progressive video - field identification
//  assign rtp_pd_header.field_identif_l3 = 'h0; // 0 for progressive video - field identification
  // assign rtp_pd_header.line_num = line number in nbo - multiple of pgroup
  // - pgroup is 4 in this case 4 bytes per pgroup 
  // assign rtp_pd_header.c = continuation if a new scan line header follows
	 // the current one
  // assign rtp_pd_header.offset = offset to the first pixel in scan line - in
  // nbo
  //
  //
  // example with 1920x1080 - sampling 4:2:2 8-bit frame-rate - 30 fps
  // udp payload = 1460 (from 1500 max) - UDP :8 - RTP :12 - Payload:14 = 1426
  // bytes
  // 1426/4 = 356.5 down to 356
  // 356 pgroups x 2pix/pgroup  - 721 pix/packet
  // 1920 x 1080 = 2073600 pix/frame
  // 2073600/721 = 2876.0055 - up to 2877 pkt/frame
  // 2 lines with 9000 mtu
  // udp paylod = 8926
  // 8926/4 = 2231
  // 2231 x 2pix/pgroup - 4462 - 2.324 lines of data for 1080p resolution
  // 2073600/4462 = 464.72 - 465 packets per frame
  //

  always @(posedge aclk) begin
    if (!aresetn) begin
      rtp_header.timestamp <= 'h0;
    end else begin
       if (start_transfer_s) begin
        rtp_header.timestamp <= rtp_header.timestamp + RTP_INCREASE;
      end
    end
  end
  
  always @(posedge aclk) begin
    if (!aresetn) begin
      rtp_header.marker <= 1'b0;
    end else begin
      if (line_counter == (NUM_LINES-1)) begin // rtp marker indicate the last packet in frame with 1 pulse
        rtp_header.marker <= 1'b1;
      end else begin
        rtp_header.marker <= 1'b0;
      end
    end
  end
  
  always @(posedge aclk) begin
    if (!aresetn) begin
      rtp_header.sequence_nr <= seq_number_l;
    end else begin
      if (end_of_packet) begin
        rtp_header.sequence_nr <= rtp_header.sequence_nr + 1;
      end else if (rtp_header.sequence_nr == 'hFFFF) begin
        rtp_header.sequence_nr <= 'h0;
      end else begin
        rtp_header.sequence_nr <= rtp_header.sequence_nr;
      end
    end
  end

  always @(posedge aclk) begin
    if (!aresetn) begin
      ext_seq_num_r <= seq_number_h;
    end else begin
      if (end_of_packet) begin // when the packet is done
        ext_seq_num_r <= ext_seq_num_r + 1;
      end else if (ext_seq_num_r == 'hFFFF) begin // if the high part is max, reset to 0
        ext_seq_num_r <= 'h0;
      end else begin
        ext_seq_num_r <= ext_seq_num_r;
      end
    end
  end

  assign rtp_pd_header.ext_seq_num = {{ext_seq_num_r[7:0]},{ext_seq_num_r[15:8]}}; //ext seq number in nbo - big endian of 16b

  assign end_of_rtp_pckt = (pix_counter == (NUM_PIX_PER_PCKT - 1)) ? 1'b1 : 1'b0;

  always @(posedge aclk) begin
    if (!aresetn) begin
      transfer_state <= IDLE;
    end else begin
      transfer_state <= transfer_state_next;
    end
  end

  always @(posedge aclk) begin
    if (!aresetn) begin
      rtp_pckt_state <= IDLE_RTP;
    end else begin
      rtp_pckt_state <= rtp_pckt_state_next;
    end
  end

  always @(posedge aclk) begin
    if (!aresetn) begin
      line_counter <= 'h0;
    end else begin
      if (transfer_state == F_COUNT) begin
        if (s_axis_tlast) begin
          line_counter <= line_counter + 1;
        end else begin
          line_counter <= line_counter;
        end
      end else begin
        line_counter <= 'h0; // line counter is increased when the state is inside a frame, else is in reset state 0
      end
    end
  end

  always @(posedge aclk) begin
    if (!aresetn) begin
      pix_counter <= 'h0;
      pause_pckt <= 'h0;
    end else begin
      if (rtp_pckt_state == PIX_COUNT) begin
        if (s_axis_tready & s_axis_tvalid) begin
          pix_counter <= pix_counter + 2;
        end else begin
          pix_counter <= pix_counter;
        end
      end else if (rtp_pckt_state == IDLE_RTP) begin
        if (!pause_pckt) begin
          if (s_axis_tready & s_axis_tvalid & start_transfer_s) begin
            pix_counter <= pix_counter + 2;
            pause_pckt <= 1'b1;
          end else begin 
            pix_counter <= 'h0;
          end
        end else begin
          pix_counter <= pix_counter;
          pause_pckt <= 1'b0;
        end
      end
    end
  end

  always @(posedge aclk) begin
    if (!aresetn) begin
      end_of_packet <= 'h0;
    end else begin
      if (rtp_pckt_state == PIX_COUNT && pix_counter == (NUM_PIX_PER_PCKT - 1)) begin
        end_of_packet <= 1'b1;
      end else begin
        end_of_packet <= 1'b0;
      end
    end
  end
  
  always @(posedge aclk) begin
    if (!aresetn) begin
      m_axis_tuser_r <= 1'b0;
    end else begin
      m_axis_tuser_r <= end_of_packet;
    end
  end

  assign start_transfer_s = (s_axis_tuser[0]) ? 1'b1 : 1'b0; // start of frame indication
  assign start_pckt = start_transfer_s | end_of_packet; // start of frame or end of rtp packet with pixel group counter indication
  assign m_axis_tlast = start_pckt; // end of RTP packet indicated in the m_axis_tuser
  assign m_axis_tuser = m_axis_tuser_r; // start of RTP packet indicated after the last counter of pixels 
  

  always @(*) begin
    case (transfer_state)
      IDLE: begin
        transfer_state_next <= (start_transfer_s) ? F_COUNT : IDLE; // go in start of frame state
      end
      F_COUNT : begin
        transfer_state_next <= (line_counter == (NUM_LINES-1) ) ? IDLE : F_COUNT; // 1080 lines in a fraame
      end
      default : begin
        transfer_state_next <= IDLE;
      end
    endcase
  end

  always @(*) begin
    case (rtp_pckt_state)
      IDLE_RTP: begin
        rtp_pckt_state_next <= (start_pckt) ? PIX_COUNT : IDLE_RTP;
      end
      PIX_COUNT: begin
        rtp_pckt_state_next <= (pix_counter == (NUM_PIX_PER_PCKT - 1)) ? IDLE_RTP : PIX_COUNT; // 2231 pixel groups in a rtp packet
      end
      default: begin
        rtp_pckt_state_next <= IDLE_RTP;
      end
    endcase
  end

  rtp_engine_regmap #(
    .VERSION (VERSION)
  ) i_regmap (
    .seq_number_h (seq_number_h),
    .seq_number_l (seq_number_l),
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s),
    .up_rack (up_rack_s));

  up_axi #(
    .AXI_ADDRESS_WIDTH(16)
  ) i_up_axi (
    .up_rstn (up_rstn),
    .up_clk (up_clk),
    .up_axi_awvalid (s_axi_awvalid),
    .up_axi_awaddr (s_axi_awaddr),
    .up_axi_awready (s_axi_awready),
    .up_axi_wvalid (s_axi_wvalid),
    .up_axi_wdata (s_axi_wdata),
    .up_axi_wstrb (s_axi_wstrb),
    .up_axi_wready (s_axi_wready),
    .up_axi_bvalid (s_axi_bvalid),
    .up_axi_bresp (s_axi_bresp),
    .up_axi_bready (s_axi_bready),
    .up_axi_arvalid (s_axi_arvalid),
    .up_axi_araddr (s_axi_araddr),
    .up_axi_arready (s_axi_arready),
    .up_axi_rvalid (s_axi_rvalid),
    .up_axi_rresp (s_axi_rresp),
    .up_axi_rdata (s_axi_rdata),
    .up_axi_rready (s_axi_rready),
    .up_wreq (up_wreq_s),
    .up_waddr (up_waddr_s),
    .up_wdata (up_wdata_s),
    .up_wack (up_wack_s),
    .up_rreq (up_rreq_s),
    .up_raddr (up_raddr_s),
    .up_rdata (up_rdata_s),
    .up_rack (up_rack_s));

endmodule
