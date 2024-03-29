# 
# Synthesis run script generated by Vivado
# 

create_project -in_memory -part xc7z020clg484-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir d:/projects/coolcracker/vivado/ip_repo/edit_Bcrypt_v4_5.cache/wt [current_project]
set_property parent.project_path d:/projects/coolcracker/vivado/ip_repo/edit_Bcrypt_v4_5.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language VHDL [current_project]
set_property board_part em.avnet.com:zed:part0:1.3 [current_project]
set_property ip_repo_paths {
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5
  d:/Projects/CoolCracker/Vivado/ip_repo
} [current_project]
set_property ip_output_repo d:/projects/coolcracker/vivado/ip_repo/edit_Bcrypt_v4_5.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
read_mem {
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/others_half1.mif
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/others_half2.mif
}
read_verilog -library xil_defaultlib {
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/bcrypt_loop.v
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/ram.v
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/ram_initialized.v
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/user_logic.v
}
read_vhdl -library proc_common_v3_00_a {
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/proc_common_pkg.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/ipif_pkg.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/family_support.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/counter_f.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/pselect_f.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/or_gate128.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/cntr_incr_decr_addn_f.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/muxf_struct_f.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/dynshreg_f.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/srl_fifo_rbu_f.vhd
}
read_vhdl -library axi_slave_burst_v1_00_a {
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/addr_gen.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/address_decode.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/control_state_machine.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/read_data_path.vhd
  d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/axi_slave_burst.vhd
}
read_vhdl -library xil_defaultlib d:/Projects/CoolCracker/Vivado/ip_repo/Bcrypt_4.5/src/bcrypt.vhd
# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.
foreach dcp [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
  set_property used_in_implementation false $dcp
}

synth_design -top bcrypt -part xc7z020clg484-1


write_checkpoint -force -noxdef bcrypt.dcp

catch { report_utilization -file bcrypt_utilization_synth.rpt -pb bcrypt_utilization_synth.pb }
