// 译码阶段

`include "defines.v"

module id(

	input wire rst,
	input wire[`InstAddrBus] pc_i,
	input wire[`InstBus] inst_i,

	//处于执行阶段的指令要写入的目的寄存器信息
	input wire ex_wreg_i,
	input wire[`RegBus] ex_wdata_i,
	input wire[`RegAddrBus] ex_wd_i,
	
	//处于访存阶段的指令要写入的目的寄存器信息
	input wire mem_wreg_i,
	input wire[`RegBus] mem_wdata_i,
	input wire[`RegAddrBus] mem_wd_i,
	
	input wire[`RegBus] reg1_data_i,
	input wire[`RegBus] reg2_data_i,

	// 判断上一条指令为转移指令之后下一条指令在ID阶段的输入变�?
	input wire is_in_delayslot_i,

	input wire[`AluOpBus] aluop_id_i_ex_o,		// 处于执行阶段指令的运算子类型

	// …�?�转移�?��?�输出�?��??
	output reg next_inst_in_delayslot_o,
	output reg branch_flag_o,
	output reg[`RegBus] branch_target_address_o,
	output reg[`RegBus] link_addr_o,
	output reg is_in_delayslot_o,

	//送到regfile的信�?
	output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[`RegAddrBus]       reg1_addr_o,
	output reg[`RegAddrBus]       reg2_addr_o, 	      
	
	//送到执行阶段的信�?
	output reg[`AluOpBus]         aluop_o,
	output reg[`AluSelBus]        alusel_o,
	output reg[`RegBus]           reg1_o,
	output reg[`RegBus]           reg2_o,
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output wire[`RegBus] 		  inst_o,		// 输出当前处于译码阶段的指�?
	
	output wire stallreq,

	output wire[`InstAddrBus] pc_id_o


);

	assign pc_id_o = pc_i;
	
	// assign stallreq = `NoStop;
	assign inst_o = inst_i;

	wire[5:0] op = inst_i[31:26];
	wire[4:0] op2 = inst_i[10:6];
	wire[5:0] op3 = inst_i[5:0];
	wire[4:0] op4 = inst_i[20:16];
	reg[`RegBus]	imm;
	reg instvalid;

	wire[`RegBus] pc_plus_4;
	wire[`RegBus] pc_plus_8;

	wire[`RegBus] imm_sll2_signedext;
	// 将分支指令中的offset左移两位然后符号拓展�?32位，赋�?�给imm_sll2_signedext
	assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};

	assign pc_plus_4 = pc_i + 4;		// 下一�?
	assign pc_plus_8 = pc_i + 8;		// 下下�?�?

	reg stallreq_for_reg1_loadrelate;		// 要读取的寄存�?1是否与上�?条指令存在load相关
	reg stallreq_for_reg2_loadrelate;		// 要读取的寄存�?2是否与上�?条指令存�?
	wire pre_inst_is_load;					// 上一条指令是否是load指令

	assign pre_inst_is_load = ((aluop_id_i_ex_o == `EXE_LB_OP) || 
  							   (aluop_id_i_ex_o == `EXE_LBU_OP)||
  							   (aluop_id_i_ex_o == `EXE_LH_OP) ||
  							   (aluop_id_i_ex_o == `EXE_LHU_OP)||
  							   (aluop_id_i_ex_o == `EXE_LW_OP)) ? 1'b1 : 1'b0;
  
	always @ (*) begin
		// pc_id_o <= pc_i;	
		if (rst == `RstEnable) begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instvalid <= `InstValid;
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_addr_o <= `NOPRegAddr;
			imm <= 32'h0;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;	
	  	end else begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];			// 默认目的寄存器地�?wd_o
			wreg_o <= `WriteDisable;
			instvalid <= `InstInvalid;	   
			reg1_read_o <= 1'b0;
			reg2_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];	// 默认的reg1_addr_o
			reg2_addr_o <= inst_i[20:16];	// 默认的reg1_addr_o	
			imm <= `ZeroWord;
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
		  	case (op)
		    	`EXE_SPECIAL_INST:		begin
					case (op2)
						5'b00000:			begin
							case (op3)
								`EXE_OR:	begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_OR_OP;
									alusel_o <= `EXE_RES_LOGIC; 	
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;	
									end  
								`EXE_AND:	begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_AND_OP;
									alusel_o <= `EXE_RES_LOGIC;	  
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;	
									instvalid <= `InstValid;	
									end  	
								`EXE_XOR:	begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_XOR_OP;
									alusel_o <= `EXE_RES_LOGIC;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;	
									instvalid <= `InstValid;	
									end  				
								`EXE_NOR:	begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_NOR_OP;
									alusel_o <= `EXE_RES_LOGIC;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;	
									instvalid <= `InstValid;	
								end 
								`EXE_SLLV: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_SLL_OP;
									alusel_o <= `EXE_RES_SHIFT;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;	
								end 
								`EXE_SRLV: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_SRL_OP;
									alusel_o <= `EXE_RES_SHIFT;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;	
								end 					
								`EXE_SRAV: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_SRA_OP;
									alusel_o <= `EXE_RES_SHIFT;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;			
								end
								`EXE_MFHI: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_MFHI_OP;
									alusel_o <= `EXE_RES_MOVE;   
									reg1_read_o <= 1'b0;	
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;	
								end
								`EXE_MFLO: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_MFLO_OP;
									alusel_o <= `EXE_RES_MOVE;   
									reg1_read_o <= 1'b0;	
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;	
								end
								`EXE_MTHI: begin
									wreg_o <= `WriteDisable;		
									aluop_o <= `EXE_MTHI_OP;
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b0; 
									instvalid <= `InstValid;	
								end
								`EXE_MTLO: begin
									wreg_o <= `WriteDisable;		
									aluop_o <= `EXE_MTLO_OP;
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b0; 
									instvalid <= `InstValid;	
								end
								`EXE_MOVN: begin
									aluop_o <= `EXE_MOVN_OP;
									alusel_o <= `EXE_RES_MOVE;   
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
									if(reg2_o != `ZeroWord) begin
										wreg_o <= `WriteEnable;
									end else begin
										wreg_o <= `WriteDisable;
									end
								end
								`EXE_MOVZ: begin
									aluop_o <= `EXE_MOVZ_OP;
									alusel_o <= `EXE_RES_MOVE;   
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;
									if(reg2_o == `ZeroWord) begin
										wreg_o <= `WriteEnable;
									end else begin
										wreg_o <= `WriteDisable;
									end		  							
								end
								`EXE_SLT: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_SLT_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;	
								end
								`EXE_SLTU: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_SLTU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;	
								end
								`EXE_ADD: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_ADD_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;	
								end
								`EXE_ADDU: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_ADDU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;	
								end
								`EXE_SUB: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_SUB_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;	
								end
								`EXE_SUBU: begin
									wreg_o <= `WriteEnable;		
									aluop_o <= `EXE_SUBU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;		
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1;
									instvalid <= `InstValid;	
								end
								`EXE_MULT: begin
									wreg_o <= `WriteDisable;		
									aluop_o <= `EXE_MULT_OP;
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1; 
									instvalid <= `InstValid;	
								end
								`EXE_MULTU: begin
									wreg_o <= `WriteDisable;		
									aluop_o <= `EXE_MULTU_OP;
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1; 
									instvalid <= `InstValid;	
								end
								`EXE_DIV: begin
									wreg_o <= `WriteDisable;		
									aluop_o <= `EXE_DIV_OP;
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1; 
									instvalid <= `InstValid;	
								end
								`EXE_DIVU: begin
									wreg_o <= `WriteDisable;		
									aluop_o <= `EXE_DIVU_OP;
									reg1_read_o <= 1'b1;	
									reg2_read_o <= 1'b1; 
									instvalid <= `InstValid;	
								end
								`EXE_JR: begin
									wreg_o <= `WriteDisable;			// 不需要保存返回地�?
									aluop_o <= `EXE_JR_OP;
									alusel_o <= `EXE_RES_JUMP_BRANCH;
									reg1_read_o <= 1'b1;				// 转移的目标地�?从rs寄存器读�?
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;									
									link_addr_o <= `ZeroWord;			// 设置返回地址�?0
									branch_flag_o <= `Branch;
									branch_target_address_o <= reg1_o;
									next_inst_in_delayslot_o <= `InDelaySlot;	// 下一条指令是延迟槽指�?
								end
								`EXE_JALR: begin
									wreg_o <= `WriteEnable;			// �?要保存返回地�?
									aluop_o <= `EXE_JALR_OP;
									alusel_o <= `EXE_RES_JUMP_BRANCH;	
									reg1_read_o <= 1'b1;				// 转移的目标地�?从rs寄存器读�?
									reg2_read_o <= 1'b0;
									instvalid <= `InstValid;									
									link_addr_o <= pc_plus_8;			// 返回地址link_addr_o为当前转移指令下下一条指令的地址
									branch_flag_o <= `Branch;
									branch_target_address_o <= reg1_o;
									next_inst_in_delayslot_o <= `InDelaySlot;
									wd_o <= inst_i[15:11];				// 目的写入的寄存器地址(rd)
								end							 											  											
								default:	begin
								end
							endcase
						end
						default: begin
						end
					endcase	
				end									  
				`EXE_ORI: begin
					wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_OR_OP;
					alusel_o <= `EXE_RES_LOGIC; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;	
				end
				`EXE_ANDI: begin
					wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_AND_OP;
					alusel_o <= `EXE_RES_LOGIC;	
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		
					wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end	 	
				`EXE_XORI: begin
					wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_XOR_OP;
					alusel_o <= `EXE_RES_LOGIC;	
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  	
					imm <= {16'h0, inst_i[15:0]};		
					wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end	 		
				`EXE_LUI: begin
					wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_OR_OP;
					alusel_o <= `EXE_RES_LOGIC; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  	
					imm <= {inst_i[15:0], 16'h0};		
					wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end			
				`EXE_SLTI: begin
					wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_SLT_OP;
					alusel_o <= `EXE_RES_ARITHMETIC; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		
					wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_SLTIU:	begin
		  			wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_SLTU_OP;
		  			alusel_o <= `EXE_RES_ARITHMETIC; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		
					wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_ADDI: begin
					wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_ADDI_OP;
					alusel_o <= `EXE_RES_ARITHMETIC; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		
					wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_ADDIU: begin
					wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_ADDIU_OP;
					alusel_o <= `EXE_RES_ARITHMETIC; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  	
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};		
					wd_o <= inst_i[20:16];		  	
					instvalid <= `InstValid;	
				end
				`EXE_SPECIAL2_INST: begin
					case ( op3 )
						`EXE_CLZ: begin
							wreg_o <= `WriteEnable;		
							aluop_o <= `EXE_CLZ_OP;
		  					alusel_o <= `EXE_RES_ARITHMETIC; 
							reg1_read_o <= 1'b1;	
							reg2_read_o <= 1'b0;	  	
							instvalid <= `InstValid;	
						end
						`EXE_CLO: begin
							wreg_o <= `WriteEnable;		
							aluop_o <= `EXE_CLO_OP;
		  					alusel_o <= `EXE_RES_ARITHMETIC; 
							reg1_read_o <= 1'b1;	
							reg2_read_o <= 1'b0;	  	
							instvalid <= `InstValid;	
						end
						`EXE_MUL: begin
							wreg_o <= `WriteEnable;		
							aluop_o <= `EXE_MUL_OP;
							alusel_o <= `EXE_RES_MUL; 
							reg1_read_o <= 1'b1;	
							reg2_read_o <= 1'b1;	
							instvalid <= `InstValid;	  			
						end
						`EXE_MADD: begin
							wreg_o <= `WriteDisable;		
							aluop_o <= `EXE_MADD_OP;
							alusel_o <= `EXE_RES_MUL; 
							reg1_read_o <= 1'b1;	
							reg2_read_o <= 1'b1;	  			
							instvalid <= `InstValid;	
						end
						`EXE_MADDU: begin
							wreg_o <= `WriteDisable;		
							aluop_o <= `EXE_MADDU_OP;
							alusel_o <= `EXE_RES_MUL; 
							reg1_read_o <= 1'b1;	
							reg2_read_o <= 1'b1;	  			
							instvalid <= `InstValid;	
						end
						`EXE_MSUB: begin
							wreg_o <= `WriteDisable;		
							aluop_o <= `EXE_MSUB_OP;
							alusel_o <= `EXE_RES_MUL; 
							reg1_read_o <= 1'b1;	
							reg2_read_o <= 1'b1;	  			
							instvalid <= `InstValid;	
						end
						`EXE_MSUBU:		begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_MSUBU_OP;
							alusel_o <= `EXE_RES_MUL; 
							reg1_read_o <= 1'b1;	
							reg2_read_o <= 1'b1;	  			
							instvalid <= `InstValid;	
						end						
						default:	begin
						end
					endcase
				end
				`EXE_J: begin			// 与JR指令类似，区别在于转移目标地�?不需要从通用寄存器读�?
					wreg_o <= `WriteDisable;		
					aluop_o <= `EXE_J_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					instvalid <= `InstValid;									
					link_addr_o <= `ZeroWord;
					branch_flag_o <= `Branch;
					branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
					next_inst_in_delayslot_o <= `InDelaySlot;
				end
				`EXE_JAL: begin			// 与JALR类似，区别：1. 同样不需要读取�?�用寄存器；2. 将返回地�?写到$31
					wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_JAL_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b0;	
					reg2_read_o <= 1'b0;
					instvalid <= `InstValid;									
					link_addr_o <= pc_plus_8;
					branch_flag_o <= `Branch;
					branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
					next_inst_in_delayslot_o <= `InDelaySlot;
					wd_o <= 5'b11111;
				end
				`EXE_BEQ: begin
		  			wreg_o <= `WriteDisable;		// 不需要保存返回地�?	
					aluop_o <= `EXE_BEQ_OP;
		  			alusel_o <= `EXE_RES_JUMP_BRANCH; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;	
					if(reg1_o == reg2_o) begin		// 如果相等则转�?
						branch_flag_o <= `Branch;
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    	end
				end
				`EXE_BGTZ: begin
					wreg_o <= `WriteDisable;		// 不需要保存返回地�?
					aluop_o <= `EXE_BGTZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;
					instvalid <= `InstValid;	
					if((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord)) begin		// rs寄存器的�?>0则转�?
						branch_flag_o <= `Branch;
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						next_inst_in_delayslot_o <= `InDelaySlot;		  	
					end
				end
				`EXE_BLEZ: begin
					wreg_o <= `WriteDisable;		
					aluop_o <= `EXE_BLEZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;
					instvalid <= `InstValid;	
					if((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord)) begin						
						branch_flag_o <= `Branch;
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    	end
				end
				`EXE_BNE: begin			// 与BEQ类似
					wreg_o <= `WriteDisable;		
					aluop_o <= `EXE_BLEZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b1;
					instvalid <= `InstValid;	
					if(reg1_o != reg2_o) begin		// 不相等则转移
						branch_flag_o <= `Branch;
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						next_inst_in_delayslot_o <= `InDelaySlot;		  	
			    	end
				end
				`EXE_REGIMM_INST: begin
					case (op4)
						`EXE_BGEZ: begin
							wreg_o <= `WriteDisable;		
							aluop_o <= `EXE_BGEZ_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH; 
							reg1_read_o <= 1'b1;	
							reg2_read_o <= 1'b0;
							instvalid <= `InstValid;	
							if(reg1_o[31] == 1'b0) begin
								branch_flag_o <= `Branch;
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								next_inst_in_delayslot_o <= `InDelaySlot;		  	
							end
						end
						`EXE_BGEZAL: begin
							wreg_o <= `WriteEnable;			// �?要保存返回地�?
							aluop_o <= `EXE_BGEZAL_OP;
		  					alusel_o <= `EXE_RES_JUMP_BRANCH; 
							reg1_read_o <= 1'b1;	
						  	reg2_read_o <= 1'b0;
							link_addr_o <= pc_plus_8; 		// 返回地址为pc+8
							wd_o <= 5'b11111;  				// 将返回地�?保存�?$31
							instvalid <= `InstValid;
							if(reg1_o[31] == 1'b0) begin
								branch_flag_o <= `Branch;
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
						end
						`EXE_BLTZ: begin
						  	wreg_o <= `WriteDisable;		
						  	aluop_o <= `EXE_BGEZAL_OP;
		  					alusel_o <= `EXE_RES_JUMP_BRANCH; 
							reg1_read_o <= 1'b1;	
						  	reg2_read_o <= 1'b0;
							instvalid <= `InstValid;	
							if(reg1_o[31] == 1'b1) begin		// 负数则转�?
								branch_flag_o <= `Branch;
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								next_inst_in_delayslot_o <= `InDelaySlot;		  	
							end
						end
						`EXE_BLTZAL: begin
							wreg_o <= `WriteEnable;		
							aluop_o <= `EXE_BGEZAL_OP;
		  					alusel_o <= `EXE_RES_JUMP_BRANCH; 
						  	reg1_read_o <= 1'b1;	
						  	reg2_read_o <= 1'b0;
							link_addr_o <= pc_plus_8;	
							wd_o <= 5'b11111; instvalid <= `InstValid;
							if(reg1_o[31] == 1'b1) begin		// 负数则转�?
								branch_flag_o <= `Branch;
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
						end
						default: begin
						end
					endcase
				end
				`EXE_LB: begin
					wreg_o <= `WriteEnable;			// �?要将加载结果写入目的寄存�?
					aluop_o <= `EXE_LB_OP;
					alusel_o <= `EXE_RES_LOAD_STORE; 
					reg1_read_o <= 1'b1;			// 读取base寄存器的�?
					reg2_read_o <= 1'b0;	  			
					instvalid <= `InstValid;
					wd_o <= inst_i[20:16];
				end
				`EXE_LBU: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LBU_OP;
					alusel_o <= `EXE_RES_LOAD_STORE; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  			
					instvalid <= `InstValid;
					wd_o <= inst_i[20:16];
				end
				`EXE_LH: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LH_OP;
					alusel_o <= `EXE_RES_LOAD_STORE; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  			
					instvalid <= `InstValid;
					wd_o <= inst_i[20:16];
				end
				`EXE_LHU: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LHU_OP;
					alusel_o <= `EXE_RES_LOAD_STORE; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  			
					instvalid <= `InstValid;
					wd_o <= inst_i[20:16];
				end
				`EXE_LW: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LW_OP;
					alusel_o <= `EXE_RES_LOAD_STORE; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b0;	  			
					instvalid <= `InstValid;
					wd_o <= inst_i[20:16];
				end
				`EXE_SB: begin
					wreg_o <= `WriteDisable;			// 不需要写通用寄存�?
					aluop_o <= `EXE_SB_OP;
					alusel_o <= `EXE_RES_LOAD_STORE; 
					reg1_read_o <= 1'b1;				// 读取base寄存器的�?
					reg2_read_o <= 1'b1;	  			// 读取rt寄存器的�?	
					instvalid <= `InstValid;
					// wd_o <= inst_i[20:16];
				end
				`EXE_SH: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SH_OP;
					alusel_o <= `EXE_RES_LOAD_STORE; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b1;	  			
					instvalid <= `InstValid;
					// wd_o <= inst_i[20:16];
				end
				`EXE_SW: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SW_OP;
					alusel_o <= `EXE_RES_LOAD_STORE; 
					reg1_read_o <= 1'b1;	
					reg2_read_o <= 1'b1;	  			
					instvalid <= `InstValid;
					// wd_o <= inst_i[20:16];
				end															  	
				default: begin
				end
			endcase
		  	if (inst_i[31:21] == 11'b00000000000) begin
		  		if (op3 == `EXE_SLL) begin
		  			wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_SLL_OP;
		  			alusel_o <= `EXE_RES_SHIFT; 
					reg1_read_o <= 1'b0;	
					reg2_read_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		
					wd_o <= inst_i[15:11];
					instvalid <= `InstValid;	
				end else if ( op3 == `EXE_SRL ) begin
					wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_SRL_OP;
					alusel_o <= `EXE_RES_SHIFT; 
					reg1_read_o <= 1'b0;	
					reg2_read_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		
					wd_o <= inst_i[15:11];
					instvalid <= `InstValid;	
				end else if ( op3 == `EXE_SRA ) begin
					wreg_o <= `WriteEnable;		
					aluop_o <= `EXE_SRA_OP;
					alusel_o <= `EXE_RES_SHIFT; 
					reg1_read_o <= 1'b0;	
					reg2_read_o <= 1'b1;	  	
					imm[4:0] <= inst_i[10:6];		
					wd_o <= inst_i[15:11];
					instvalid <= `InstValid;	
				end
			end else if (inst_i[10:0] == 11'b00000000000) begin
				if (inst_i[31:21] == 11'b01000000100) begin				// mtc0
					aluop_o <= `EXE_MTC0_OP;
					alusel_o <= `EXE_RES_NOP;
					wreg_o <= `WriteDisable;
					instvalid <= `InstValid;
					reg1_read_o <= 1'b1;
					reg1_addr_o <= inst_i[20:16];
					reg2_read_o <= 1'b0;
				end else if (inst_i[31:21] == 11'b01000000000) begin	// mfc0
					aluop_o <= `EXE_MFC0_OP;
					alusel_o <= `EXE_RES_MOVE;
					wreg_o <= `WriteEnable;
					wd_o <= inst_i[20:16];
					instvalid <= `InstValid;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
				end
			end		  
		end
	end
	
	always @ (*) begin
		stallreq_for_reg1_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg1_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_read_o == 1'b1 ) begin
		  	stallreq_for_reg1_loadrelate <= `Stop;	
		end else if((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o)) begin
			reg1_o <= ex_wdata_i; 
		end else if((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o)) begin
			reg1_o <= mem_wdata_i; 			
		end else if(reg1_read_o == 1'b1) begin
			reg1_o <= reg1_data_i;
		end else if(reg1_read_o == 1'b0) begin
			reg1_o <= imm;
		end else begin
			reg1_o <= `ZeroWord;
	  	end
	end
	
	always @ (*) begin
		stallreq_for_reg2_loadrelate <= `NoStop;
		if(rst == `RstEnable) begin
			reg2_o <= `ZeroWord;
		end else if(pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_read_o == 1'b1 ) begin
		  	stallreq_for_reg2_loadrelate <= `Stop;
		end else if((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o)) begin
			reg2_o <= ex_wdata_i; 
		end else if((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o)) begin
			reg2_o <= mem_wdata_i;			
		end else if(reg2_read_o == 1'b1) begin
			reg2_o <= reg2_data_i;
		end else if(reg2_read_o == 1'b0) begin
			reg2_o <= imm;
		end else begin
			reg2_o <= `ZeroWord;
		end
	end

	// is_in_delayslot_o表示当前指令是否是延迟槽指令
	always @ (*) begin
		if(rst == `RstEnable) begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end else begin
			is_in_delayslot_o <= is_in_delayslot_i;
		end
	end

	assign stallreq = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

endmodule