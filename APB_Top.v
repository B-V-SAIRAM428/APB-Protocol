`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2025 21:48:05
// Design Name: 
// Module Name: APB_Top
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


module APB_Top(
    input pclk,               
    input presetn,            
    input pready,           
    input [7:0]prdata,
    input transfer,
    input write,
    input [5:0]apb_read_addr,
    input [5:0]apb_write_addr,
    input [7:0]apb_write_data
   
    );
    wire psel;
    wire penable;
    wire [4:0] paddr;
    wire pwrite;
    wire [7:0] pwdata;
    wire [7:0] apb_read_data;
    wire error_flag;
    
    APB_Master m1 (
            .pclk(pclk),
            .presetn(presetn),
            .pready(pready),         
            .prdata(prdata),
            .transfer(transfer),
            .write(write),
            .apb_read_addr(apb_read_addr),
            .apb_write_addr(apb_write_addr),
            .apb_write_data(apb_write_data),
            .psel(psel),
            .penable(penable),
            .paddr(paddr),
            .pwrite(pwrite),
            .pwdata(pwdata),
            .apb_read_data(apb_read_data)
            );
         APB_Slave s0(
                    . pclk(pclk),
                    . presetn(presetn),
                    . psel(psel),
                    . penable(penable),
                    . pwrite(pwrite),
                    . paddr(paddr),
                    . pwdata(pwdata),
                    . pready(pready),
                    . prdata(prdata)
                    );
    
        
endmodule
