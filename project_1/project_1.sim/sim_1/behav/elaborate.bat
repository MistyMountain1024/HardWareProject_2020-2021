@echo off
set xv_path=G:\\Digital_Logic\\Vnew\\Vivado\\2015.2\\bin
call %xv_path%/xelab  -wto 68bf695aeac948cdb35854984d21ae43 -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip --snapshot openmips_min_sopc_tb_behav xil_defaultlib.openmips_min_sopc_tb xil_defaultlib.glbl -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
