// ***************************************************************************
// ***************************************************************************
// Copyright (C) 2024 Analog Devices, Inc. All rights reserved.
//
// In this HDL repository, there are many different and unique modules, consisting
// of various HDL (Verilog or VHDL) components. The individual modules are
// developed independently, and may be accompanied by separate and unique license
// terms.
//
// The user should read each of these license terms, and understand the
// freedoms and responsibilities that he or she has by using this source/core.
//
// This core is distributed in the hope that it will be useful, but WITHOUT ANY
// WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
// A PARTICULAR PURPOSE.
//
// Redistribution and use of source or resulting binaries, with or without modification
// of this file, are permitted under one of the following two license terms:
//
//   1. The GNU General Public License version 2 as published by the
//      Free Software Foundation, which can be found in the top level directory
//      of this repository (LICENSE_GPL2), and also online at:
//      <https://www.gnu.org/licenses/old-licenses/gpl-2.0.html>
//
// OR
//
//   2. An ADI specific BSD license, which can be found in the top level directory
//      of this repository (LICENSE_ADIBSD), and also on-line at:
//      https://github.com/analogdevicesinc/hdl/blob/master/LICENSE_ADIBSD
//      This will allow to generate bit files and not release the source code,
//      as long as it attaches to an ADI device.
//
// ***************************************************************************
// ***************************************************************************

package rtp_engine_package;

  typedef struct packed {
    logic [ 1:0]  version;
    logic         padding;
    logic         extension;
    logic [ 3:0]  csrc_count;
    logic         marker;
    logic [ 6:0]  payload_type;
    logic [15:0]  sequence_nr;
    logic [31:0]  timestamp;
    logic [31:0]  ssrc_field; //12 bytes - without csrc sources identifiers
  } rtp_pckt_header;

  typedef struct packed {
    logic [15:0]  ext_seq_num;
    logic [15:0]  length_l1; // 48 bits for line in the payload header + 16b - 64b - 8 bytes
    logic         field_identif_l1;
    logic [14:0]  line_num_l1;
    logic         continuation_l1;
    logic [14:0]  offset_l1;
    logic [15:0]  length_l2;
    logic         field_identif_l2;
    logic [14:0]  line_num_l2;
    logic         continuation_l2;
    logic [14:0]  offset_l2; // 2 full lines of data - 7680 bytes occupied as a payload for udp data transmission
  } rtp_payload_header;

 // total - 12B(RTP_H)+8B(RTP_P_H)+8B(UDP_H)+20B(IPv4 - without options _H)
 // - 48B header

  // possible number of bits per pixel for transmission
  typedef enum logic [6:0] {
    video_1ppc = 'd16,
    video_2ppc = 'd32,
    video_4ppc = 'd64} num_b_ppc;

  typedef enum logic [2:0] {
    cam0 = 'd0,
    cam1 = 'd1,
    cam2 = 'd2,
    cam3 = 'd3,
    cam4 = 'd4,
    cam5 = 'd5,
    cam6 = 'd6,
    cam7 = 'd7} cam_n_id;

  typedef enum logic [0:0] {
    IDLE = 'h0,
    F_COUNT = 'h1} state_vid_fr;

  typedef enum logic [0:0] {
    IDLE_RTP = 'h0,
    PIX_COUNT = 'h1} state_rtp_pckt;

    
endpackage
