@echo off
set xv_path=G:\\Digital_Logic\\Vnew\\Vivado\\2015.2\\bin
call %xv_path%/xsim openmips_min_sopc_tb_behav -key {Behavioral:sim_1:Functional:openmips_min_sopc_tb} -tclbatch openmips_min_sopc_tb.tcl -view D:/yingzong/vOld/project_1/openmips_min_sopc_tb_behav.wcfg -log simulate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
