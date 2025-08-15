`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2025 10:57:46
// Design Name: 
// Module Name: APB_Slave
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module APB_Slave(
    input pclk,
    input presetn,
    input psel,
    input penable,
    input pwrite,
    input [4:0] paddr,
    input [7:0] pwdata,
    
    output reg pready,
    output reg [7:0] prdata
    );
    
    reg [7:0] mem [31:0];
    integer i;
    always@(posedge pclk) begin
        if(!presetn) begin
            for (i=0; i<32; i=i+1)
                mem[i]<=0;
            pready <= 0;
            prdata <= 0;
        end else begin
            if (!psel) begin
                if (!penable && !pwrite)
                    pready <=0;
                else if (penable && !pwrite) begin
                    pready <= 1; 
                    prdata <= mem[paddr];
                end else if (!penable && pwrite)
                    pready <=0;
                else if (penable && pwrite) begin
                    pready <= 1; 
                    mem[paddr] <= pwdata;
                end
                
            end else begin
                pready <= 0;
                prdata <= 0;
            end
        end
    end
endmodule
