
# ad9250-xcvr

add_instance avl_ad9250_xcvr avl_adxcvr
set_instance_parameter_value avl_ad9250_xcvr {ID} {0}
set_instance_parameter_value avl_ad9250_xcvr {TX_OR_RX_N} {0}
set_instance_parameter_value avl_ad9250_xcvr {PCS_CONFIG} {JESD_PCS_CFG2}
set_instance_parameter_value avl_ad9250_xcvr {LANE_RATE} {5000.0}
set_instance_parameter_value avl_ad9250_xcvr {REFCLK_FREQUENCY} {250.0}
set_instance_parameter_value avl_ad9250_xcvr {NUM_OF_LANES} {4}
set_instance_parameter_value avl_ad9250_xcvr {NUM_OF_CONVS} {4}
set_instance_parameter_value avl_ad9250_xcvr {FRM_BCNT} {4}
set_instance_parameter_value avl_ad9250_xcvr {FRM_SCNT} {1}
set_instance_parameter_value avl_ad9250_xcvr {MF_FCNT} {32}
set_instance_parameter_value avl_ad9250_xcvr {HD} {0}

add_connection sys_clk.clk avl_ad9250_xcvr.sys_clk
add_connection sys_clk.clk_reset avl_ad9250_xcvr.sys_resetn
add_interface rx_ref_clk clock sink
set_interface_property rx_ref_clk EXPORT_OF avl_ad9250_xcvr.ref_clk
add_interface rx_data_0 conduit end
set_interface_property rx_data_0 EXPORT_OF avl_ad9250_xcvr.rx_data_0
add_interface rx_data_1 conduit end
set_interface_property rx_data_1 EXPORT_OF avl_ad9250_xcvr.rx_data_1
add_interface rx_data_2 conduit end
set_interface_property rx_data_2 EXPORT_OF avl_ad9250_xcvr.rx_data_2
add_interface rx_data_3 conduit end
set_interface_property rx_data_3 EXPORT_OF avl_ad9250_xcvr.rx_data_3
add_interface rx_sysref conduit end
set_interface_property rx_sysref EXPORT_OF avl_ad9250_xcvr.sysref
add_interface rx_sync conduit end
set_interface_property rx_sync EXPORT_OF avl_ad9250_xcvr.sync
add_interface rx_ip_sof conduit end
set_interface_property rx_ip_sof EXPORT_OF avl_ad9250_xcvr.ip_sof
add_interface rx_ip_data avalon_streaming source
set_interface_property rx_ip_data EXPORT_OF avl_ad9250_xcvr.ip_data

# ad9250-xcvr

add_instance axi_ad9250_xcvr axi_adxcvr
set_instance_parameter_value axi_ad9250_xcvr {ID} {0}
set_instance_parameter_value axi_ad9250_xcvr {TX_OR_RX_N} {0}
set_instance_parameter_value axi_ad9250_xcvr {NUM_OF_LANES} {4}

add_connection sys_clk.clk axi_ad9250_xcvr.s_axi_clock
add_connection sys_clk.clk_reset axi_ad9250_xcvr.s_axi_reset
add_connection axi_ad9250_xcvr.if_up_rst avl_ad9250_xcvr.rst
add_connection avl_ad9250_xcvr.ready axi_ad9250_xcvr.ready
add_connection axi_ad9250_xcvr.core_pll_locked avl_ad9250_xcvr.core_pll_locked

# ad9250

add_instance axi_ad9250_core_0 axi_ad9250
set_instance_parameter_value axi_ad9250_core_0 {ID} {0}

add_connection avl_ad9250_xcvr.core_clk axi_ad9250_core_0.if_rx_clk
add_interface rx_ip_sof_0 conduit end
set_interface_property rx_ip_sof_0 EXPORT_OF axi_ad9250_core_0.if_rx_sof
add_interface rx_ip_data_0 avalon_streaming sink
set_interface_property rx_ip_data_0 EXPORT_OF axi_ad9250_core_0.if_rx_data
add_connection sys_clk.clk_reset axi_ad9250_core_0.s_axi_reset
add_connection sys_clk.clk axi_ad9250_core_0.s_axi_clock

add_instance axi_ad9250_core_1 axi_ad9250
set_instance_parameter_value axi_ad9250_core_1 {ID} {1}

add_connection avl_ad9250_xcvr.core_clk axi_ad9250_core_1.if_rx_clk
add_interface rx_ip_sof_1 conduit end
set_interface_property rx_ip_sof_1 EXPORT_OF axi_ad9250_core_1.if_rx_sof
add_interface rx_ip_data_1 avalon_streaming sink
set_interface_property rx_ip_data_1 EXPORT_OF axi_ad9250_core_1.if_rx_data
add_connection sys_clk.clk_reset axi_ad9250_core_1.s_axi_reset
add_connection sys_clk.clk axi_ad9250_core_1.s_axi_clock

# ad9250-pack

add_instance util_ad9250_cpack_0 util_cpack
set_instance_parameter_value util_ad9250_cpack_0 {CHANNEL_DATA_WIDTH} {32}
set_instance_parameter_value util_ad9250_cpack_0 {NUM_OF_CHANNELS} {2}

add_connection sys_clk.clk_reset util_ad9250_cpack_0.if_adc_rst
add_connection avl_ad9250_xcvr.core_clk util_ad9250_cpack_0.if_adc_clk
add_connection axi_ad9250_core_0.adc_ch_0 util_ad9250_cpack_0.adc_ch_0
add_connection axi_ad9250_core_0.adc_ch_1 util_ad9250_cpack_0.adc_ch_1

add_instance util_ad9250_cpack_1 util_cpack
set_instance_parameter_value util_ad9250_cpack_1 {CHANNEL_DATA_WIDTH} {32}
set_instance_parameter_value util_ad9250_cpack_1 {NUM_OF_CHANNELS} {2}

add_connection sys_clk.clk_reset util_ad9250_cpack_1.if_adc_rst
add_connection avl_ad9250_xcvr.core_clk util_ad9250_cpack_1.if_adc_clk
add_connection axi_ad9250_core_1.adc_ch_0 util_ad9250_cpack_1.adc_ch_0
add_connection axi_ad9250_core_1.adc_ch_1 util_ad9250_cpack_1.adc_ch_1

# ad9250-dma

add_instance axi_ad9250_dma_0 axi_dmac
set_instance_parameter_value axi_ad9250_dma_0 {ID} {0}
set_instance_parameter_value axi_ad9250_dma_0 {DMA_TYPE_SRC} {2}
set_instance_parameter_value axi_ad9250_dma_0 {DMA_TYPE_DEST} {0}
set_instance_parameter_value axi_ad9250_dma_0 {SYNC_TRANSFER_START} {1}
set_instance_parameter_value axi_ad9250_dma_0 {DMA_LENGTH_WIDTH} {24}
set_instance_parameter_value axi_ad9250_dma_0 {DMA_DATA_WIDTH_SRC} {64}
set_instance_parameter_value axi_ad9250_dma_0 {DMA_DATA_WIDTH_DEST} {64}

add_connection avl_ad9250_xcvr.core_clk axi_ad9250_dma_0.if_fifo_wr_clk
add_connection util_ad9250_cpack_0.if_adc_valid axi_ad9250_dma_0.if_fifo_wr_en
add_connection util_ad9250_cpack_0.if_adc_sync axi_ad9250_dma_0.if_fifo_wr_sync
add_connection util_ad9250_cpack_0.if_adc_data axi_ad9250_dma_0.if_fifo_wr_din
add_connection axi_ad9250_dma_0.if_fifo_wr_overflow axi_ad9250_core_0.if_adc_dovf
add_connection sys_clk.clk_reset axi_ad9250_dma_0.s_axi_reset
add_connection sys_clk.clk axi_ad9250_dma_0.s_axi_clock
add_connection sys_dma_clk.clk_reset axi_ad9250_dma_0.m_dest_axi_reset
add_connection sys_dma_clk.clk axi_ad9250_dma_0.m_dest_axi_clock

add_instance axi_ad9250_dma_1 axi_dmac
set_instance_parameter_value axi_ad9250_dma_1 {ID} {1}
set_instance_parameter_value axi_ad9250_dma_1 {DMA_TYPE_SRC} {2}
set_instance_parameter_value axi_ad9250_dma_1 {DMA_TYPE_DEST} {0}
set_instance_parameter_value axi_ad9250_dma_1 {SYNC_TRANSFER_START} {1}
set_instance_parameter_value axi_ad9250_dma_1 {DMA_DATA_WIDTH_SRC} {64}
set_instance_parameter_value axi_ad9250_dma_1 {DMA_DATA_WIDTH_DEST} {64}

add_connection avl_ad9250_xcvr.core_clk axi_ad9250_dma_1.if_fifo_wr_clk
add_connection util_ad9250_cpack_1.if_adc_valid axi_ad9250_dma_1.if_fifo_wr_en
add_connection util_ad9250_cpack_1.if_adc_sync axi_ad9250_dma_1.if_fifo_wr_sync
add_connection util_ad9250_cpack_1.if_adc_data axi_ad9250_dma_1.if_fifo_wr_din
add_connection axi_ad9250_dma_1.if_fifo_wr_overflow axi_ad9250_core_1.if_adc_dovf
add_connection sys_clk.clk_reset axi_ad9250_dma_1.s_axi_reset
add_connection sys_clk.clk axi_ad9250_dma_1.s_axi_clock
add_connection sys_dma_clk.clk_reset axi_ad9250_dma_1.m_dest_axi_reset
add_connection sys_dma_clk.clk axi_ad9250_dma_1.m_dest_axi_clock

# core-clock

add_instance rx_core_clk altera_clock_bridge
add_connection avl_ad9250_xcvr.core_clk rx_core_clk.in_clk
add_interface rx_core_clk clock source
set_interface_property rx_core_clk EXPORT_OF rx_core_clk.out_clk

# addresses

ad_cpu_interconnect 0x00010000 avl_ad9250_xcvr.phy_reconfig_0
ad_cpu_interconnect 0x00012000 avl_ad9250_xcvr.phy_reconfig_1
ad_cpu_interconnect 0x00014000 avl_ad9250_xcvr.phy_reconfig_2
ad_cpu_interconnect 0x00016000 avl_ad9250_xcvr.phy_reconfig_3
ad_cpu_interconnect 0x0001b000 avl_ad9250_xcvr.core_pll_reconfig
ad_cpu_interconnect 0x0001c000 avl_ad9250_xcvr.ip_reconfig
ad_cpu_interconnect 0x00030000 axi_ad9250_xcvr.s_axi
ad_cpu_interconnect 0x00040000 axi_ad9250_core_0.s_axi
ad_cpu_interconnect 0x00050000 axi_ad9250_core_1.s_axi
ad_cpu_interconnect 0x00060000 axi_ad9250_dma_0.s_axi
ad_cpu_interconnect 0x00070000 axi_ad9250_dma_1.s_axi

# dma interconnects

ad_dma_interconnect axi_ad9250_dma_0.m_dest_axi
ad_dma_interconnect axi_ad9250_dma_1.m_dest_axi

# interrupts

ad_cpu_interrupt 11 axi_ad9250_dma_0.interrupt_sender
ad_cpu_interrupt 12 axi_ad9250_dma_1.interrupt_sender

