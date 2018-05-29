# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "C_S_AXI_AWUSER_WIDTH" -parent ${Page_0}
  set C_S_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {Width of S_AXI data bus} ${C_S_AXI_DATA_WIDTH}
  set C_S_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S_AXI_ADDR_WIDTH" -parent ${Page_0}]
  set_property tooltip {Width of S_AXI address bus} ${C_S_AXI_ADDR_WIDTH}
  ipgui::add_param $IPINST -name "C_S_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_HIGHADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_RDATA_FIFO_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_INCLUDE_TIMEOUT_CNT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_TIMEOUT_CNTR_VAL" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_ALIGN_BE_RDADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_SUPPORTS_WRITE" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_SUPPORTS_READ" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_MEM0_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_MEM0_HIGHADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_MEM1_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_MEM1_HIGHADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_MEM2_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_MEM2_HIGHADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S_AXI_ID_WIDTH" -parent ${Page_0}

  #Adding Page
  set Page_1 [ipgui::add_page $IPINST -name "Page 1"]
  ipgui::add_param $IPINST -name "C_S_AXI_ARUSER_WIDTH" -parent ${Page_1}
  ipgui::add_param $IPINST -name "C_S_AXI_WUSER_WIDTH" -parent ${Page_1}
  ipgui::add_param $IPINST -name "C_S_AXI_RUSER_WIDTH" -parent ${Page_1}
  ipgui::add_param $IPINST -name "C_S_AXI_BUSER_WIDTH" -parent ${Page_1}


}

proc update_PARAM_VALUE.C_ALIGN_BE_RDADDR { PARAM_VALUE.C_ALIGN_BE_RDADDR } {
	# Procedure called to update C_ALIGN_BE_RDADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_ALIGN_BE_RDADDR { PARAM_VALUE.C_ALIGN_BE_RDADDR } {
	# Procedure called to validate C_ALIGN_BE_RDADDR
	return true
}

proc update_PARAM_VALUE.C_INCLUDE_TIMEOUT_CNT { PARAM_VALUE.C_INCLUDE_TIMEOUT_CNT } {
	# Procedure called to update C_INCLUDE_TIMEOUT_CNT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_INCLUDE_TIMEOUT_CNT { PARAM_VALUE.C_INCLUDE_TIMEOUT_CNT } {
	# Procedure called to validate C_INCLUDE_TIMEOUT_CNT
	return true
}

proc update_PARAM_VALUE.C_RDATA_FIFO_DEPTH { PARAM_VALUE.C_RDATA_FIFO_DEPTH } {
	# Procedure called to update C_RDATA_FIFO_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_RDATA_FIFO_DEPTH { PARAM_VALUE.C_RDATA_FIFO_DEPTH } {
	# Procedure called to validate C_RDATA_FIFO_DEPTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S_AXI_ARUSER_WIDTH } {
	# Procedure called to update C_S_AXI_ARUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ARUSER_WIDTH { PARAM_VALUE.C_S_AXI_ARUSER_WIDTH } {
	# Procedure called to validate C_S_AXI_ARUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S_AXI_AWUSER_WIDTH } {
	# Procedure called to update C_S_AXI_AWUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_AWUSER_WIDTH { PARAM_VALUE.C_S_AXI_AWUSER_WIDTH } {
	# Procedure called to validate C_S_AXI_AWUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_BUSER_WIDTH { PARAM_VALUE.C_S_AXI_BUSER_WIDTH } {
	# Procedure called to update C_S_AXI_BUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_BUSER_WIDTH { PARAM_VALUE.C_S_AXI_BUSER_WIDTH } {
	# Procedure called to validate C_S_AXI_BUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_MEM0_BASEADDR { PARAM_VALUE.C_S_AXI_MEM0_BASEADDR } {
	# Procedure called to update C_S_AXI_MEM0_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_MEM0_BASEADDR { PARAM_VALUE.C_S_AXI_MEM0_BASEADDR } {
	# Procedure called to validate C_S_AXI_MEM0_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_MEM0_HIGHADDR { PARAM_VALUE.C_S_AXI_MEM0_HIGHADDR } {
	# Procedure called to update C_S_AXI_MEM0_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_MEM0_HIGHADDR { PARAM_VALUE.C_S_AXI_MEM0_HIGHADDR } {
	# Procedure called to validate C_S_AXI_MEM0_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_MEM1_BASEADDR { PARAM_VALUE.C_S_AXI_MEM1_BASEADDR } {
	# Procedure called to update C_S_AXI_MEM1_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_MEM1_BASEADDR { PARAM_VALUE.C_S_AXI_MEM1_BASEADDR } {
	# Procedure called to validate C_S_AXI_MEM1_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_MEM1_HIGHADDR { PARAM_VALUE.C_S_AXI_MEM1_HIGHADDR } {
	# Procedure called to update C_S_AXI_MEM1_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_MEM1_HIGHADDR { PARAM_VALUE.C_S_AXI_MEM1_HIGHADDR } {
	# Procedure called to validate C_S_AXI_MEM1_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_MEM2_BASEADDR { PARAM_VALUE.C_S_AXI_MEM2_BASEADDR } {
	# Procedure called to update C_S_AXI_MEM2_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_MEM2_BASEADDR { PARAM_VALUE.C_S_AXI_MEM2_BASEADDR } {
	# Procedure called to validate C_S_AXI_MEM2_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_MEM2_HIGHADDR { PARAM_VALUE.C_S_AXI_MEM2_HIGHADDR } {
	# Procedure called to update C_S_AXI_MEM2_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_MEM2_HIGHADDR { PARAM_VALUE.C_S_AXI_MEM2_HIGHADDR } {
	# Procedure called to validate C_S_AXI_MEM2_HIGHADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_RUSER_WIDTH { PARAM_VALUE.C_S_AXI_RUSER_WIDTH } {
	# Procedure called to update C_S_AXI_RUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_RUSER_WIDTH { PARAM_VALUE.C_S_AXI_RUSER_WIDTH } {
	# Procedure called to validate C_S_AXI_RUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_SUPPORTS_READ { PARAM_VALUE.C_S_AXI_SUPPORTS_READ } {
	# Procedure called to update C_S_AXI_SUPPORTS_READ when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_SUPPORTS_READ { PARAM_VALUE.C_S_AXI_SUPPORTS_READ } {
	# Procedure called to validate C_S_AXI_SUPPORTS_READ
	return true
}

proc update_PARAM_VALUE.C_S_AXI_SUPPORTS_WRITE { PARAM_VALUE.C_S_AXI_SUPPORTS_WRITE } {
	# Procedure called to update C_S_AXI_SUPPORTS_WRITE when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_SUPPORTS_WRITE { PARAM_VALUE.C_S_AXI_SUPPORTS_WRITE } {
	# Procedure called to validate C_S_AXI_SUPPORTS_WRITE
	return true
}

proc update_PARAM_VALUE.C_S_AXI_WUSER_WIDTH { PARAM_VALUE.C_S_AXI_WUSER_WIDTH } {
	# Procedure called to update C_S_AXI_WUSER_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_WUSER_WIDTH { PARAM_VALUE.C_S_AXI_WUSER_WIDTH } {
	# Procedure called to validate C_S_AXI_WUSER_WIDTH
	return true
}

proc update_PARAM_VALUE.C_TIMEOUT_CNTR_VAL { PARAM_VALUE.C_TIMEOUT_CNTR_VAL } {
	# Procedure called to update C_TIMEOUT_CNTR_VAL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_TIMEOUT_CNTR_VAL { PARAM_VALUE.C_TIMEOUT_CNTR_VAL } {
	# Procedure called to validate C_TIMEOUT_CNTR_VAL
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ID_WIDTH { PARAM_VALUE.C_S_AXI_ID_WIDTH } {
	# Procedure called to update C_S_AXI_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ID_WIDTH { PARAM_VALUE.C_S_AXI_ID_WIDTH } {
	# Procedure called to validate C_S_AXI_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_BASEADDR { PARAM_VALUE.C_S_AXI_BASEADDR } {
	# Procedure called to update C_S_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_BASEADDR { PARAM_VALUE.C_S_AXI_BASEADDR } {
	# Procedure called to validate C_S_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S_AXI_HIGHADDR { PARAM_VALUE.C_S_AXI_HIGHADDR } {
	# Procedure called to update C_S_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_HIGHADDR { PARAM_VALUE.C_S_AXI_HIGHADDR } {
	# Procedure called to validate C_S_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_S_AXI_ID_WIDTH { MODELPARAM_VALUE.C_S_AXI_ID_WIDTH PARAM_VALUE.C_S_AXI_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ID_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.C_RDATA_FIFO_DEPTH { MODELPARAM_VALUE.C_RDATA_FIFO_DEPTH PARAM_VALUE.C_RDATA_FIFO_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_RDATA_FIFO_DEPTH}] ${MODELPARAM_VALUE.C_RDATA_FIFO_DEPTH}
}

proc update_MODELPARAM_VALUE.C_INCLUDE_TIMEOUT_CNT { MODELPARAM_VALUE.C_INCLUDE_TIMEOUT_CNT PARAM_VALUE.C_INCLUDE_TIMEOUT_CNT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_INCLUDE_TIMEOUT_CNT}] ${MODELPARAM_VALUE.C_INCLUDE_TIMEOUT_CNT}
}

proc update_MODELPARAM_VALUE.C_TIMEOUT_CNTR_VAL { MODELPARAM_VALUE.C_TIMEOUT_CNTR_VAL PARAM_VALUE.C_TIMEOUT_CNTR_VAL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_TIMEOUT_CNTR_VAL}] ${MODELPARAM_VALUE.C_TIMEOUT_CNTR_VAL}
}

proc update_MODELPARAM_VALUE.C_ALIGN_BE_RDADDR { MODELPARAM_VALUE.C_ALIGN_BE_RDADDR PARAM_VALUE.C_ALIGN_BE_RDADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_ALIGN_BE_RDADDR}] ${MODELPARAM_VALUE.C_ALIGN_BE_RDADDR}
}

proc update_MODELPARAM_VALUE.C_S_AXI_SUPPORTS_WRITE { MODELPARAM_VALUE.C_S_AXI_SUPPORTS_WRITE PARAM_VALUE.C_S_AXI_SUPPORTS_WRITE } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_SUPPORTS_WRITE}] ${MODELPARAM_VALUE.C_S_AXI_SUPPORTS_WRITE}
}

proc update_MODELPARAM_VALUE.C_S_AXI_SUPPORTS_READ { MODELPARAM_VALUE.C_S_AXI_SUPPORTS_READ PARAM_VALUE.C_S_AXI_SUPPORTS_READ } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_SUPPORTS_READ}] ${MODELPARAM_VALUE.C_S_AXI_SUPPORTS_READ}
}

proc update_MODELPARAM_VALUE.C_S_AXI_MEM0_BASEADDR { MODELPARAM_VALUE.C_S_AXI_MEM0_BASEADDR PARAM_VALUE.C_S_AXI_MEM0_BASEADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_MEM0_BASEADDR}] ${MODELPARAM_VALUE.C_S_AXI_MEM0_BASEADDR}
}

proc update_MODELPARAM_VALUE.C_S_AXI_MEM0_HIGHADDR { MODELPARAM_VALUE.C_S_AXI_MEM0_HIGHADDR PARAM_VALUE.C_S_AXI_MEM0_HIGHADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_MEM0_HIGHADDR}] ${MODELPARAM_VALUE.C_S_AXI_MEM0_HIGHADDR}
}

proc update_MODELPARAM_VALUE.C_S_AXI_MEM1_BASEADDR { MODELPARAM_VALUE.C_S_AXI_MEM1_BASEADDR PARAM_VALUE.C_S_AXI_MEM1_BASEADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_MEM1_BASEADDR}] ${MODELPARAM_VALUE.C_S_AXI_MEM1_BASEADDR}
}

proc update_MODELPARAM_VALUE.C_S_AXI_MEM1_HIGHADDR { MODELPARAM_VALUE.C_S_AXI_MEM1_HIGHADDR PARAM_VALUE.C_S_AXI_MEM1_HIGHADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_MEM1_HIGHADDR}] ${MODELPARAM_VALUE.C_S_AXI_MEM1_HIGHADDR}
}

proc update_MODELPARAM_VALUE.C_S_AXI_MEM2_BASEADDR { MODELPARAM_VALUE.C_S_AXI_MEM2_BASEADDR PARAM_VALUE.C_S_AXI_MEM2_BASEADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_MEM2_BASEADDR}] ${MODELPARAM_VALUE.C_S_AXI_MEM2_BASEADDR}
}

proc update_MODELPARAM_VALUE.C_S_AXI_MEM2_HIGHADDR { MODELPARAM_VALUE.C_S_AXI_MEM2_HIGHADDR PARAM_VALUE.C_S_AXI_MEM2_HIGHADDR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_MEM2_HIGHADDR}] ${MODELPARAM_VALUE.C_S_AXI_MEM2_HIGHADDR}
}

