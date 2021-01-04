// Description: 基于OpenMIPS处理器的一个简单SOPC，用于验证具备了
//              wishbone总线接口的openmips，该SOPC包含openmips、
//              wb_conmax、GPIO controller、flash controller，uart 
//              controller，以及用来仿真flash的模块flashmem，在其中
//              存储指令，用来仿真外部ram的模块datamem，在其中存储
//              数据，并且具有wishbone总线接口

`include "defines.v"

module openmips_min_sopc(

	input wire clk,
	input wire rst
	
);

	// 连接指令存储器
	wire[`InstAddrBus] inst_addr;
	wire[`InstBus] inst;
	wire rom_ce;

	// 连接数据存储器
	wire[`DataAddrBus] ram_addr;
	wire[`DataBus] ram_data_i;			// 数据从top输入到ram
	wire[3:0] ram_sel;
	wire ram_we;
	wire ram_ce;
	wire[`DataBus] ram_data_o;			// 数据从ram输出到top

 	openmips openmips0(
		.clk(clk),
		.rst(rst),

		// 和rom之间传递
		//// from rom to top
		.data_rom_o_top_i(inst),
		//// from top to rom
		.addr_top_o_rom_i(inst_addr),
		.ce_top_o_rom_i(rom_ce),

		// 和ram之间传递
		//// from ram to top
		.data_ram_o_top_i(ram_data_o),
		//// from top to ram		
		.addr_top_o_ram_i(ram_addr),
		.data_top_o_ram_i(ram_data_i),
		.sel_top_o_ram_i(ram_sel),
		.we_top_o_ram_i(ram_we),
		.ce_top_o_ram_i(ram_ce)
	
	);
	
	inst_rom inst_rom0(
		//// from top to rom
		.ce(rom_ce),
		.addr(inst_addr),

		//// from rom to top
		.inst(inst)	
	);

	data_ram data_ram0(
		.clk(clk),

		//// from top to ram
		.addr(ram_addr),
		.data_i(ram_data_i),
		.sel(ram_sel),
		.we(ram_we),
		.ce(ram_ce),

		//// from ram to top
		.data_o(ram_data_o)
	);


endmodule