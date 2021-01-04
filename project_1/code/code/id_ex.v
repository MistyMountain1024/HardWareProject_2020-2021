// ID/EX阶段的寄存器

`include "defines.v"

module id_ex(

	input wire clk,
	input wire rst,
	
	//从译码阶段传递的信息
	input wire[`AluOpBus]         id_aluop,
	input wire[`AluSelBus]        id_alusel,
	input wire[`RegBus]           id_reg1,
	input wire[`RegBus]           id_reg2,
	input wire[`RegAddrBus]       id_wd,
	input wire                    id_wreg,
	input wire[`RegBus]			  id_inst,	// 从ID阶段传递过来的当前处于译码阶段的信息

	// ctrl暂停控制
	input wire[5:0] 			  stall,

	// 分支指令处理 输入
	input wire id_is_in_delayslot,			// 当前处于译码阶段的指令是否位于延迟槽
	input wire[`RegBus] id_link_address,	// 处于译码阶段的转移指令要保存的返回地址
	input wire next_inst_in_delayslot_i,	// 下一条进入译码阶段的指令是否位于延迟槽
	
	// 分支指令处理 输出
	output reg ex_is_in_delayslot,			// 当前处于执行阶段的指令是否位于延迟槽
	output reg[`RegBus] ex_link_address,	// 处于执行阶段的转移指令要保存的返回地址
	output reg is_in_delayslot_o,			// 当前处于译码阶段的指令是否位于延迟槽
	
	//传递到执行阶段的信息
	output reg[`AluOpBus]         ex_aluop,
	output reg[`AluSelBus]        ex_alusel,
	output reg[`RegBus]           ex_reg1,
	output reg[`RegBus]           ex_reg2,
	output reg[`RegAddrBus]       ex_wd,
	output reg                    ex_wreg,
	output reg[`RegBus]			  ex_inst	// 当前处于执行阶段的指令
	
);

	always @ (negedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
			is_in_delayslot_o <= `NotInDelaySlot;
		end else if (stall[2] == `Stop && stall[3] == `NoStop) begin	// 译码阶段暂停，执行阶段继续
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
		end else if(stall[2] == `NoStop) begin							// 译码阶段没有被暂停
			ex_aluop <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;
			ex_link_address <= id_link_address;
			ex_is_in_delayslot <= id_is_in_delayslot;
			is_in_delayslot_o <= next_inst_in_delayslot_i;
			// 在译码阶段没有暂停的情况下，直接将ID模块的输入通过接口ex_inst输出
			ex_inst <= id_inst;	
		end
	end
	
endmodule