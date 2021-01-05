// 用来实现流水线暂停的模块

`include "defines.v"

module ctrl(

    input wire rst,

    input wire stallreq_from_id,        // 来自译码阶段的暂停请求
    input wire stallreq_from_ex,        // 来自执行阶段的暂停请求

    output reg[5:0] stall

);

    always @ (*) begin
        if (rst == `RstEnable) begin
            stall <= 6'b000000;
        end else if (stallreq_from_ex == `Stop) begin       // 取指、译码阶段暂停
            stall <= 6'b001111;
        end else if (stallreq_from_id == `Stop) begin       // 取指、译码、执行阶段暂停
            stall <= 6'b000111;
        end else begin
            stall <= 6'b000000;
        end
    end

endmodule    
