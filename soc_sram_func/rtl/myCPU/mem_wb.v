// MEM/WB阶段的寄存器

`include "defines.v"

module mem_wb(

	input wire clk,
	input wire rst,
	
	//来自访存阶段的信�?	
	input wire[`RegAddrBus] mem_wd,
	input wire mem_wreg,
	input wire[`RegBus] mem_wdata,
	input wire[`RegBus] mem_hi,
	input wire[`RegBus] mem_lo,
	input wire mem_whilo,			// 访存阶段的指令是否要写HI、LO寄存�?

	input wire[5:0] stall,

	input wire[`InstAddrBus] pc_mem_o,

	// 协处理器访问(�?)操作相关输入
	input wire mem_cp0_reg_we,
	input wire[4:0] mem_cp0_reg_write_addr,
	input wire[`RegBus] mem_cp0_reg_data,

	//送到回写阶段的信�?
	output reg[`RegAddrBus] wb_wd,//连接到regfile的waddr
	output reg wb_wreg,//连接到regfile的we，回写阶段的指令是否有要写入的目的寄存器
	output reg[`RegBus] wb_wdata,//连接到regfile的wdata
	output reg[`RegBus] wb_hi,
	output reg[`RegBus] wb_lo,
	output reg wb_whilo,				// 写回阶段的指令是否要写HI、LO寄存�?	       

	// 协处理器访问(�?)操作相关输出
	output reg wb_cp0_reg_we,
	output reg[4:0] wb_cp0_reg_write_addr,
	output reg[`RegBus] wb_cp0_reg_data,

	output reg[`InstAddrBus] pc_for_debug
	
);

	// assign pc_for_debug = pc_mem_o;

	always @ (posedge clk) begin
		pc_for_debug <= pc_mem_o;
		if(rst == `RstEnable) begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
		  	wb_wdata <= `ZeroWord;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
			pc_for_debug <= `ZeroWord;
		end else if (stall[4] == `Stop && stall[5] == `NoStop) begin		// 访存阶段暂停，写回阶段继�?
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
			pc_for_debug <= `ZeroWord;
		end else if (stall[4] == `NoStop) begin								// 访存阶段继续
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
			wb_hi <= mem_hi;
			wb_lo <= mem_lo;
			wb_whilo <= mem_whilo;
			wb_cp0_reg_we <= mem_cp0_reg_we;
			wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
			wb_cp0_reg_data <= mem_cp0_reg_data;
			pc_for_debug <= pc_mem_o;
		end
	end

endmodule