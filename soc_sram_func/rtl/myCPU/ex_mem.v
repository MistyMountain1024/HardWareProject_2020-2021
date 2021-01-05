// EX/MEM??????????????

`include "defines.v"

module ex_mem(

	input wire clk,
	input wire rst,
	
	// form ex	
	input wire[`RegAddrBus]       	ex_wd,
	input wire                    	ex_wreg,
	input wire[`RegBus]			  	ex_wdata,
	input wire[`RegBus]				ex_hi,
	input wire[`RegBus]				ex_lo,
	input wire 						ex_whilo,

	input wire[`InstAddrBus] pc_ex_o,

	// 访存操作相关输入
	input wire[`AluOpBus]			ex_aluop,			// 访存阶段的指令要进行的运算的子类�?
	input wire[`RegBus]				ex_mem_addr,		// 访存阶段的访存指令对应的存储器的地址
	input wire[`RegBus]				ex_reg2,			// 访存阶段的访存指令要存储的数�?

	input wire[5:0] stall,

	// 协处理器访问操作相关输入
	input wire                     ex_cp0_reg_we,
	input wire[4:0]                ex_cp0_reg_write_addr,
	input wire[`RegBus]            ex_cp0_reg_data,
			
	// to mem
	output reg[`RegAddrBus]       	mem_wd,
	output reg                    	mem_wreg,
	output reg[`RegBus]			  	mem_wdata,
	output reg[`RegBus]				mem_hi,
	output reg[`RegBus]				mem_lo,
	output reg 						mem_whilo,
	// 访存操作相关输出
	output reg[`AluOpBus]			mem_aluop,			// 访存阶段的指令要进行的运算的子类�?
	output reg[`RegBus]				mem_mem_addr,		// 访存阶段的访存指令对应的存储器的地址
	output reg[`RegBus]				mem_reg2,			// 访存阶段的访存指令要存储的数�?

	// 协处理器访问操作相关输出
	output reg                   	mem_cp0_reg_we,
	output reg[4:0]              	mem_cp0_reg_write_addr,
	output reg[`RegBus]          	mem_cp0_reg_data,

	output reg[`InstAddrBus] pc_mem_i
	
);

	// assign pc_mem_i = pc_ex_o;

	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		  	mem_wdata <= `ZeroWord;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
			mem_whilo <= `WriteDisable;
			mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;
			pc_mem_i <= `ZeroWord;
			mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;
		end else if (stall[3] == `Stop && stall[4] == `NoStop) begin		// ?????????????
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			mem_hi <= `ZeroWord;		
			mem_lo <= `ZeroWord;
			mem_whilo <= `WriteDisable;
			mem_cp0_reg_we <= `WriteDisable;
			mem_cp0_reg_write_addr <= 5'b00000;
			mem_cp0_reg_data <= `ZeroWord;
			pc_mem_i <= `ZeroWord;
			mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;
		end else if (stall[3] == `NoStop) begin							// ??????
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;
			mem_hi <= ex_hi;		
			mem_lo <= ex_lo;
			mem_whilo <= ex_whilo;
			mem_aluop <= ex_aluop;
			mem_mem_addr <= ex_mem_addr;
			mem_reg2 <= ex_reg2;
			// 如果执行阶段不暂停则把写CP0的相关数据向下传�?
			mem_cp0_reg_we <= ex_cp0_reg_data;
			mem_cp0_reg_write_addr <= ex_cp0_reg_write_addr;
			mem_cp0_reg_data <= ex_cp0_reg_data;
			pc_mem_i <= pc_ex_o;
			
		end
	end
			

endmodule