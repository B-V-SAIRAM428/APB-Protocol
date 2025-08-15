`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 13.08.2025 10:53:26
// Design Name: 
// Module Name: APB_Master
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


module APB_Master(
    input pclk,               /// Clock 
    input presetn,            /// Active low signal
    input pready,           
    input [7:0]prdata,
    input transfer,
    input write,
    
    //// Test bench inputs
    input [5:0]apb_read_addr,
    input [5:0]apb_write_addr,
    input [7:0]apb_write_data,
    
    output reg psel,
    output reg penable,
    output reg [4:0] paddr,
    output reg pwrite,
    output reg [7:0] pwdata,
    output reg [7:0] apb_read_data
    );

    
    reg [1:0] present_state, next_state;
    
    parameter IDLE = 2'b00;
    parameter SETUP = 2'b01;
    parameter ACCESS = 2'b10;
              
    always@(posedge pclk) begin
        if(!presetn) 
            present_state <= IDLE;
        else
            present_state <= next_state;
    end
    
    always@(*)begin
        case(present_state)
            IDLE: begin                     
                     if(!transfer)
                        next_state = IDLE;
                     else 
                        next_state = SETUP;  
                  end
                  
            SETUP:begin
                     next_state = ACCESS;
                  end
            
            ACCESS:begin
                     if (pready == 0)
                        next_state = ACCESS;  
                     else if (pready == 1 && transfer)
                        next_state = SETUP;  
                     else if (pready == 1 && !transfer)
                        next_state = IDLE;
                   end
        endcase
    end
    
    always@(posedge pclk) begin
        if (!presetn) begin
            psel <= 1'b0;
            penable <= 1'b0;
            paddr <= 5'd0;
            pwrite <= 1'b0;
            pwdata <= 8'd0;
            apb_read_data <= 8'd0;
        end else begin
            case(present_state)
                IDLE: begin
                        psel <= 1'b0;
                        penable <= 1'b0;
                        paddr <= 5'd0;
                        pwrite <= 1'b0;
                        pwdata <= 8'd0;
                        apb_read_data <= 8'd0;
                      end
                
                SETUP: begin
                        if(apb_read_addr[5] ==0 && apb_write_addr[5] ==0 ) begin
                            psel <= 0;
                            penable <= 0;
                            if(write ==1) begin
                                pwrite <=1;
                                pwdata <= apb_write_data;
                                paddr <= apb_write_addr; 
                            end else begin
                                pwrite <=0;
                                apb_read_data <= prdata; 
                            end   
                                
                        /////// I write this below for second slave connection  
                        end else if(apb_read_addr[5] ==1 && apb_write_addr[5] ==1 ) begin
                            psel <= 1;
                            penable <= 0;
                            if(write ==1) begin
                                pwrite <=1;
                                pwdata <= apb_write_data;
                                paddr <= apb_write_addr; 
                            end else begin
                                pwrite <=0;
                                apb_read_data <= prdata; 
                            end 
                        end
                       end
                       
                ACCESS: begin
                           if(apb_read_addr[5] ==1 && apb_write_addr[5] ==1 ) begin
                                psel <= 1;
                                penable <= 1;
                           end else if(apb_read_addr[5] ==0 && apb_write_addr[5] ==0 ) begin
                                psel <= 0;
                                penable <= 1;
                           end
                        end
           endcase
        end
    end
endmodule
