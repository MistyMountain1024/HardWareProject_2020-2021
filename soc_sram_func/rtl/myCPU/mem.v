// 访存阶段

`include "defines.v"

module mem(

	input wire rst,

	
	//来自执行阶段的信??	
	input wire[`RegAddrBus] wd_i,
	input wire wreg_i,
	input wire[`RegBus] wdata_i,
	input wire[`RegBus] hi_i,
	input wire[`RegBus] lo_i,
	input wire whilo_i,			// 访存阶段的指令是否要写HI、LO寄存??

	input wire[`InstAddrBus] pc_mem_i,

	// 访存指令相关
	//// 来自执行阶段的信??
	input wire[`AluOpBus] aluop_i,		// 访存阶段的指令要进行的运算的子类??
	input wire[`RegBus] mem_addr_i,		// 访存阶段的访存指令对应的存储器地??
	input wire[`RegBus] reg2_i,			// 访存指令要存储的数据
	//// 来自RAM的信??
	input wire[`RegBus] mem_data_i,		// 从数据存储器读取的数??

	// 协处理器访问(??)操作相关输入
	input wire cp0_reg_we_i,
	input wire[4:0] cp0_reg_write_addr_i,
	input wire[`RegBus] cp0_reg_data_i,
	
	//送到回写阶段的信??
	output reg[`RegAddrBus] wd_o,
	output reg wreg_o,
	output reg[`RegBus] wdata_o,
	output reg[`RegBus] hi_o,
	output reg[`RegBus] lo_o,
	output reg whilo_o,			// 访存阶段的指令最终是否要写HI、LO寄存??
	// 访存指令相关，???到RAM的信??
	output reg[`RegBus] mem_addr_o,		// 要访问的的存储器地址
	//output wire mem_we_o,				// 是否是写操作??1：写
	output reg[3:0]	mem_sel_o,			// 字节选择信号，宽度对应数据???线??4个字??
	output reg[`RegBus] mem_data_o,		// 要写?? 数据存储器的数据
	output reg mem_ce_o,				// 数据存储器使能信??

	// 协处理器访问(??)操作相关输出
	output reg cp0_reg_we_o,
	output reg[4:0] cp0_reg_write_addr_o,
	output reg[`RegBus] cp0_reg_data_o,

	output wire[`InstAddrBus] pc_mem_o

	
);
	wire[`RegBus] zero32;
	reg mem_we;

	assign pc_mem_o = pc_mem_i;
	
	assign zero32 = `ZeroWord;
	//assign mem_we_o = mem_we;			// RAM的读、写信号
	
	always @ (*) begin
		// pc_mem_o <= pc_mem_i;
		if(rst == `RstEnable) begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
		  	wdata_o <= `ZeroWord;
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b0000;
			mem_ce_o <= `ChipDisable;
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_data_o <= `ZeroWord;
		end else begin
		  	wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			hi_o <= hi_i;
			lo_o <= lo_i;
			whilo_o <= whilo_i;
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b1111;
			mem_ce_o <= `ChipDisable;
			// 把写CP0的相关信息向下传??
			cp0_reg_we_o <= cp0_reg_we_i;
			cp0_reg_write_addr_o <= cp0_reg_write_addr_i;
			cp0_reg_data_o <= cp0_reg_data_i;
			case (aluop_i)
				`EXE_LB_OP: begin
					// mem_addr_o <= mem_addr_i;
					mem_addr_o <= (mem_addr_i[31] == 1) ? {3'b000, mem_addr_i[28:0]} : mem_addr_i;
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b0000;
					mem_ce_o <= `ChipEnable;				// ??要访问数据存储器
					// 依据数据存储器的输入数据??后两位的值确定要读取的字??
					case (mem_addr_i[1:0])			
						2'b00: begin				//mem_data_i[31:24]
							wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
							// mem_sel_o <= 4'b1000;
						end
						2'b01: begin				//mem_data_i[23:16]
							wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
							// mem_sel_o <= 4'b0100;
						end
						2'b10: begin				//mem_data_i[15:8]
							wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
							// mem_sel_o <= 4'b0010;
						end
						2'b11: begin				//mem_data_i[7:0]
							wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
							// mem_sel_o <= 4'b0001;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LBU_OP: begin
					// mem_addr_o <= mem_addr_i;
					mem_addr_o <= (mem_addr_i[31] == 1) ? {3'b000, mem_addr_i[28:0]} : mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					mem_sel_o <= 4'b0000;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[31:24]};
							// mem_sel_o <= 4'b1000;
						end
						2'b01: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[23:16]};
							// mem_sel_o <= 4'b0100;
						end
						2'b10: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[15:8]};
							// mem_sel_o <= 4'b0010;
						end
						2'b11: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[7:0]};
							// mem_sel_o <= 4'b0001;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LH_OP: begin
					// mem_addr_o <= mem_addr_i;
					mem_addr_o <= (mem_addr_i[31] == 1) ? {3'b000, mem_addr_i[28:0]} : mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					mem_sel_o <= 4'b0000;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
							// mem_sel_o <= 4'b1100;
						end
						2'b10: begin
							wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
							// mem_sel_o <= 4'b0011;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LHU_OP: begin
					// mem_addr_o <= mem_addr_i;
					mem_addr_o <= (mem_addr_i[31] == 1) ? {3'b000, mem_addr_i[28:0]} : mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					mem_sel_o <= 4'b0000;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{16{1'b0}}, mem_data_i[31:16]};
							// mem_sel_o <= 4'b1100;
						end
						2'b10: begin
							wdata_o <= {{16{1'b0}}, mem_data_i[15:0]};
							// mem_sel_o <= 4'b0011;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LW_OP: begin
					mem_addr_o <= (mem_addr_i[31] == 1) ? {3'b000, mem_addr_i[28:0]} : mem_addr_i;
					mem_we <= `WriteDisable;
					mem_ce_o <= `ChipEnable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b0000;
					// mem_sel_o <= 4'b1111;
				end
				`EXE_SB_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					mem_data_o <= {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b1000;
						end
						2'b01: begin
							mem_sel_o <= 4'b0100;
						end
						2'b10: begin
							mem_sel_o <= 4'b0010;
						end
						2'b11: begin
							mem_sel_o <= 4'b0001;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SH_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					mem_data_o <= {reg2_i[15:0], reg2_i[15:0]};
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b1100;
						end
						2'b10: begin
							mem_sel_o <= 4'b0011;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SW_OP: begin
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_ce_o <= `ChipEnable;
					mem_data_o <= {reg2_i[31:0]};
					mem_sel_o <= 4'b1111;
				end
			endcase
		end
	end		

endmodule