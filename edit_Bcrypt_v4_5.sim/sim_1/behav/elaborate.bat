@echo off
set xv_path=D:\\Xilinx\\Vivado\\2017.2\\bin
call %xv_path%/xelab  -wto fb343f76d1f74518a75b7fa8be319b54 -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L proc_common_v3_00_a -L axi_slave_burst_v1_00_a -L unisims_ver -L unimacro_ver -L secureip --snapshot bcrypt_behav xil_defaultlib.bcrypt xil_defaultlib.glbl -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
