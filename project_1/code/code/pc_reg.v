// 指令寄存器PC

`include "defines.v"

module pc_reg(

	input wire clk,
	input wire rst,
	
	// 暂停控制
	input wire[5:0] stall,

	// 来自译码阶段ID模块的信息
	input wire branch_flag_i,
	input wire[`RegBus] branch_target_address_i,
	
	output reg[`InstAddrBus] pc,
	output reg ce
	
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ce <= `ChipDisable;
		end else begin
			ce <= `ChipEnable;
		end
	end

	always @ (posedge clk) begin
		if (ce == `ChipDisable) begin
			pc <= 32'h00000000;
		end else if (stall[0] == `NoStop) begin			// 当stall[0]为NoStop时进行转移判断
			if(branch_flag_i == `Branch) begin			// 如果是转移指令且满足转移条件，将转移目标地址赋给pc
				pc <= branch_target_address_i;
			end else begin								// 否则pc+4
				pc <= pc + 4'h4;
			end
		end
	end

endmodule