// OpenMIPS处理器的顶层文件

`include "defines.v"

module openmips(

	input wire clk,
	input wire rst,
	
	// 连接rom
	//// 从rom输入
	input wire[`RegBus] data_rom_o_top_i,
	//// 输出到rom
	output wire[`RegBus] addr_top_o_rom_i,
	output wire ce_top_o_rom_i,					// ROM使能信号

	// 连接ram
	//// 从ram输入
	input wire[`RegBus] data_ram_o_top_i,			// 从RAM读取数据
	//// 输出到ram
	output wire[`RegBus] addr_top_o_ram_i,			// 要访问的RAM地址
	output wire we_top_o_ram_i,					// 是否是对RAM的写操作，1：写
	output wire[3:0] sel_top_o_ram_i,				// 字节选择信号
	output wire[`RegBus] data_top_o_ram_i,			// 要写入RAM的数据
	output wire ce_top_o_ram_i						// RAM使能信号
	
);

	wire[`InstAddrBus] pc;
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	
	//连接译码阶段ID模块的输出与ID/EX模块的输入
	wire[`AluOpBus] id_aluop_o;
	wire[`AluSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	//// 用作分支跳转处理
	wire id_is_in_delayslot_o;		
	wire[`RegBus] id_link_addr_o;
	wire id_next_inst_in_delayslot_o; 

	wire[`RegBus] id_inst_o;
	
	//连接ID/EX模块的输出与执行阶段EX模块的输入
	wire[`AluOpBus] ex_aluop_i;
	wire[`AluSelBus] ex_alusel_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_wreg_i;
	wire[`RegAddrBus] ex_wd_i;
	//// 用作分支跳转处理
	wire ex_is_in_delayslot_i;
	wire[`RegBus] ex_link_addr_i;

	wire[`RegBus] ex_inst_i;
	
	//连接执行阶段EX模块的输出与EX/MEM模块的输入
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire[`RegBus] ex_hi_o;
	wire[`RegBus] ex_lo_o;
	wire ex_whilo_o;

	wire[`AluOpBus]	ex_aluop_o;
	wire[`RegBus] ex_mem_addr_o;
	wire[`RegBus] ex_reg2_o;
	//// 协处理器访问操作相关  from EX to EX/MEM
	wire cp0_reg_we_ex_o_next_i;
	wire[4:0] cp0_reg_write_addr_ex_o_next_i;
	wire[`RegBus] cp0_reg_data_ex_o_next_i;

	//连接EX/MEM模块的输出与访存阶段MEM模块的输入
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire[`RegBus] mem_hi_i;
	wire[`RegBus] mem_lo_i;
	wire mem_whilo_i;

	wire[`AluOpBus]	mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg2_i;
	//// 协处理器访问操作相关  from EX/MEM to MEM
	wire cp0_reg_we_prev_o_mem_i;
	wire[4:0] cp0_reg_write_addr_prev_o_mem_i;
	wire[`RegBus] cp0_reg_data_prev_o_mem_i;		

	//连接访存阶段MEM模块的输出与MEM/WB模块的输入
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	wire mem_whilo_o;
	//// 协处理器访问操作相关  from MEM to MEM/WB and EX
	wire cp0_reg_we_mem_o_next_and_ex_i;
	wire[4:0] cp0_reg_write_addr_mem_o_next_and_ex_i;
	wire[`RegBus] cp0_reg_data_mem_o_next_and_ex_i;	
	
	//连接MEM/WB模块的输出与回写阶段的输入	
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire[`RegBus] wb_hi_i;
	wire[`RegBus] wb_lo_i;
	wire wb_whilo_i;
	
	//连接译码阶段ID模块与通用寄存器Regfile模块
	wire reg1_read;
	wire reg2_read;
	wire[`RegBus] reg1_data;
	wire[`RegBus] reg2_data;
	wire[`RegAddrBus] reg1_addr;
	wire[`RegAddrBus] reg2_addr;

	//连接执行阶段与hilo模块的输出，读取HI、LO寄存器
	wire[`RegBus] 	hi;
	wire[`RegBus]   lo;

  	//连接执行阶段与ex_reg模块，用于多周期的MADD、MADDU、MSUB、MSUBU指令
	wire[`DoubleRegBus] hilo_temp_o;
	wire[1:0] cnt_o;
	
	wire[`DoubleRegBus] hilo_temp_i;
	wire[1:0] cnt_i;

	wire[`DoubleRegBus] div_result;
	wire div_ready;
	wire[`RegBus] div_opdata1;
	wire[`RegBus] div_opdata2;
	wire div_start;
	wire div_annul;
	wire signed_div;

	wire[5:0] stall;
	wire stallreq_from_id;	
	wire stallreq_from_ex;

	// 用来实现分支跳转
	//// ID输出传递到PC		
	wire[`RegBus] id_branch_target_addr_o;
	wire id_branch_flag_o;
	//// ID/EX输出传递到ID
	wire id_is_in_delayslot_i;

	// 连接MEM/WB与CP0
	//// 协处理器访问操作相关 from MEM/WB to CP0 and EX
	wire cp0_reg_we_cp0_and_ex_i;
	wire[4:0] cp0_reg_write_addr_cp0_and_ex_i;
	wire[`RegBus] cp0_reg_data_cp0_and_ex_i;

	// 连接EX与CP0
	//// 协处理器访问操作相关 from EX to CP0
	wire[4:0] cp0_reg_read_addr_ex_o_cp0_i;
	//// 协处理器访问操作相关 from CP0 to EX
	wire[`RegBus] cp0_reg_data_cp0_o_ex_i;
  
  	// pc_reg例化
	pc_reg pc_reg0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.pc(pc),
		.ce(ce_top_o_rom_i),

		// 用来实现分支跳转的输入
		// from ID
		.branch_target_address_i(id_branch_target_addr_o),
		.branch_flag_i(id_branch_flag_o)	
			
	);
	
  	assign addr_top_o_rom_i = pc;

  	// IF/ID模块例化
	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.stall(stall),
		.if_pc(pc),
		.if_inst(data_rom_o_top_i),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)      	
	);
	
	//译码阶段ID模块
	id id0(
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),

		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),

	  	// 处于执行阶段的指令要写入的目的寄存器信息
		.ex_wreg_i(ex_wreg_o),
		.ex_wdata_i(ex_wdata_o),
		.ex_wd_i(ex_wd_o),

	  	// 处于访存阶段的指令要写入的目的寄存器信息
		.mem_wreg_i(mem_wreg_o),
		.mem_wdata_i(mem_wdata_o),
		.mem_wd_i(mem_wd_o),

		// 送到regfile的信息
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  

		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	  
		// 送到ID/EX模块的信息
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),

		.inst_o(id_inst_o),

		// 用来实现分支的输入
		// from ID/EX
		.is_in_delayslot_i(id_is_in_delayslot_i),

		// 用来实现分支的输出
		// to PC
		.branch_target_address_o(id_branch_target_addr_o),
		.branch_flag_o(id_branch_flag_o),
		// to ID/EX
		.is_in_delayslot_o(id_is_in_delayslot_o),
		.link_addr_o(id_link_addr_o),
		.next_inst_in_delayslot_o(id_next_inst_in_delayslot_o),

		// 用来解决load相关
		// from EX
		.aluop_id_i_ex_o(ex_aluop_o),
		// to ctrl
		.stallreq(stallreq_from_id)

	);

	// ID/EX模块
	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		
		.stall(stall),
		
		// 从译码阶段ID模块传递的信息
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),

		.id_inst(id_inst_o),
	
		// 传递到执行阶段EX模块的信息
		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),

		.ex_inst(ex_inst_i),

		// 用来实现分支跳转的输入
		// from ID 
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.id_link_address(id_link_addr_o),
		.next_inst_in_delayslot_i(id_next_inst_in_delayslot_o),

		// 用来实现分支跳转的输出
		// to EX
		.ex_is_in_delayslot(ex_is_in_delayslot_i),
		.ex_link_address(ex_link_addr_i),
		// to ID
		.is_in_delayslot_o(id_is_in_delayslot_i)

	);		
	
	// EX模块
	ex ex0(
		.rst(rst),
	
		//送到执行阶段EX模块的信息
		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
		.hi_i(hi),
		.lo_i(lo),

		.wb_hi_i(wb_hi_i),
		.wb_lo_i(wb_lo_i),
		.wb_whilo_i(wb_whilo_i),
		.mem_hi_i(mem_hi_o),
		.mem_lo_i(mem_lo_o),
		.mem_whilo_i(mem_whilo_o),

		.div_result_i(div_result),
		.div_ready_i(div_ready), 
		
		.inst_i(ex_inst_i),
			  
	  	// EX模块的输出到EX/MEM模块信息
		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),

		.hi_o(ex_hi_o),
		.lo_o(ex_lo_o),
		.whilo_o(ex_whilo_o),

		.div_opdata1_o(div_opdata1),
		.div_opdata2_o(div_opdata2),
		.div_start_o(div_start),
		.signed_div_o(signed_div),	
		
		.stallreq(stallreq_from_ex), 

		.aluop_o(ex_aluop_o),
		.mem_addr_o(ex_mem_addr_o),
		.reg2_o(ex_reg2_o),

		// 用来实现分支跳转的输入
		// from ID/EX
		.is_in_delayslot_i(ex_is_in_delayslot_i),
		.link_address_i(ex_link_addr_i),

		// 协处理器访问操作相关输入
		//// from cp0
		.cp0_reg_data_i(cp0_reg_data_cp0_o_ex_i),
		//// from MEM
		.mem_cp0_reg_we(cp0_reg_we_mem_o_next_and_ex_i),
		.mem_cp0_reg_write_addr(cp0_reg_write_addr_mem_o_next_and_ex_i),
		.mem_cp0_reg_data(cp0_reg_data_mem_o_next_and_ex_i),
		//// from MEM/WB
		.wb_cp0_reg_we(cp0_reg_we_cp0_and_ex_i),
		.wb_cp0_reg_write_addr(cp0_reg_write_addr_cp0_and_ex_i),
		.wb_cp0_reg_data(cp0_reg_data_cp0_and_ex_i),

		// 协处理器访问相关输出
		//// to EX/MEM
		.cp0_reg_we_o(cp0_reg_we_ex_o_next_i),
		.cp0_reg_write_addr_o(cp0_reg_write_addr_ex_o_next_i),
		.cp0_reg_data_o(cp0_reg_data_ex_o_next_i),
		//// to CP0
		.cp0_reg_read_addr_o(cp0_reg_read_addr_ex_o_cp0_i)
		
	);

 	// EX/MEM模块
  	ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
	  
	  	.stall(stall),
	  
		// 来自执行阶段EX模块的信息	
		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		.ex_hi(ex_hi_o),
		.ex_lo(ex_lo_o),
		.ex_whilo(ex_whilo_o),

		.ex_aluop(ex_aluop_o),
		.ex_mem_addr(ex_mem_addr_o),
		.ex_reg2(ex_reg2_o),	

		// 送到访存阶段MEM模块的信息
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i),
		.mem_hi(mem_hi_i),
		.mem_lo(mem_lo_i),
		.mem_whilo(mem_whilo_i),

		.mem_aluop(mem_aluop_i),
		.mem_mem_addr(mem_mem_addr_i),
		.mem_reg2(mem_reg2_i),

		// 协处理器访问操作相关输入
		//// from EX
		.ex_cp0_reg_we(cp0_reg_we_ex_o_next_i),
		.ex_cp0_reg_write_addr(cp0_reg_write_addr_ex_o_next_i),
		.ex_cp0_reg_data(cp0_reg_data_ex_o_next_i),

		// 协处理器访问操作相关输出
		//// to MEM
		.mem_cp0_reg_we(cp0_reg_we_prev_o_mem_i),
		.mem_cp0_reg_write_addr(cp0_reg_write_addr_prev_o_mem_i),
		.mem_cp0_reg_data(cp0_reg_data_prev_o_mem_i)
						       	
	);
	
  	// MEM模块例化
	mem mem0(
		.rst(rst),
	
		// 来自EX/MEM模块的信息	
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
		.hi_i(mem_hi_i),
		.lo_i(mem_lo_i),
		.whilo_i(mem_whilo_i),

		.aluop_i(mem_aluop_i),
		.mem_addr_i(mem_mem_addr_i),
		.reg2_i(mem_reg2_i),
		// .mem_data_i(mem_data_i),	
	  
		// 送到MEM/WB模块的信息
		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
		.hi_o(mem_hi_o),
		.lo_o(mem_lo_o),
		.whilo_o(mem_whilo_o),

		// 访存指令相关
		//// from RAM
		.mem_data_i(data_ram_o_top_i),

		//// to RAM
		.mem_addr_o(addr_top_o_ram_i),
		.mem_we_o(we_top_o_ram_i),
		.mem_sel_o(sel_top_o_ram_i),
		.mem_data_o(data_top_o_ram_i),
		.mem_ce_o(ce_top_o_ram_i),

		// 协处理器访问操作相关输入
		//// from EX/MEM
		.cp0_reg_we_i(cp0_reg_we_prev_o_mem_i),
		.cp0_reg_write_addr_i(cp0_reg_write_addr_prev_o_mem_i),
		.cp0_reg_data_i(cp0_reg_data_prev_o_mem_i),

		// 协处理器访问操作相关输出
		//// to MEM/WB && EX
		.cp0_reg_we_o(cp0_reg_we_mem_o_next_and_ex_i),
		.cp0_reg_write_addr_o(cp0_reg_write_addr_mem_o_next_and_ex_i),
		.cp0_reg_data_o(cp0_reg_data_mem_o_next_and_ex_i)

	);

  	// MEM/WB模块
	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),

    	.stall(stall),

		// 来自访存阶段MEM模块的信息	
		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
		.mem_hi(mem_hi_o),
		.mem_lo(mem_lo_o),
		.mem_whilo(mem_whilo_o),		
	
		// 送到回写阶段的信息
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i),
		.wb_hi(wb_hi_i),
		.wb_lo(wb_lo_i),
		.wb_whilo(wb_whilo_i),

		// 协处理器访问操作相关输入
		//// from MEM
		.mem_cp0_reg_we(cp0_reg_we_mem_o_next_and_ex_i),
		.mem_cp0_reg_write_addr(cp0_reg_write_addr_mem_o_next_and_ex_i),
		.mem_cp0_reg_data(cp0_reg_data_mem_o_next_and_ex_i),

		// 协处理器访问操作相关输出
		//// to CP0 && EX
		.wb_cp0_reg_we(cp0_reg_we_cp0_and_ex_i),
		.wb_cp0_reg_write_addr(cp0_reg_write_addr_cp0_and_ex_i),
		.wb_cp0_reg_data(cp0_reg_data_cp0_and_ex_i)	
									       	
	);

	// 通用寄存器Regfile例化
	regfile regfile1(
		.clk (clk),
		.rst (rst),
		.we	(wb_wreg_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.re1 (reg1_read),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (reg2_read),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data)
	);

	hilo_reg hilo_reg0(
		.clk(clk),
		.rst(rst),
	
		// 写端口
		.we(wb_whilo_i),
		.hi_i(wb_hi_i),
		.lo_i(wb_lo_i),
	
		// 读端口1
		.hi_o(hi),
		.lo_o(lo)	
	);
	
	ctrl ctrl0(
		.rst(rst),
	
		.stallreq_from_id(stallreq_from_id),
  		// 来自执行阶段的暂停请求
		.stallreq_from_ex(stallreq_from_ex),

		.stall(stall)       	
	);

	div div0(
		.clk(clk),
		.rst(rst),
	
		.signed_div_i(signed_div),
		.opdata1_i(div_opdata1),
		.opdata2_i(div_opdata2),
		.start_i(div_start),
		.annul_i(1'b0),
	
		.result_o(div_result),
		.ready_o(div_ready)
	);

	cp0_reg cp0_reg(
		.clk(clk),
		.rst(rst),

		.int_i(int_i),

		// input from EX
		.raddr_i(cp0_reg_read_addr_ex_o_cp0_i),
		// input from MEM/WB
		.data_i(cp0_reg_data_cp0_and_ex_i),
		.waddr_i(cp0_reg_write_addr_cp0_and_ex_i),
		.we_i(cp0_reg_we_cp0_and_ex_i),

		// output to EX
		.data_o(cp0_reg_data_cp0_o_ex_i),

		.timer_int_o(timer_int_o)

	);

endmodule