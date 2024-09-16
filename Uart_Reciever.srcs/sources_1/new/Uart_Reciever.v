`timescale 1ns / 1ps


// This constraints for this code is for boolean fpga board

module Uart_Reciever(
input clk, rx,rst, output reg [6:0]seg, output reg [3:0]an
    );
    // Setting baud rates and counters 
    parameter clk_cycles = 868;
    reg [7:0]RXbits;
    reg indicator;
    //state declarations 
    parameter idle = 3'b000;
    parameter start_bit = 3'b001;
    parameter data_bits = 3'b010;
    parameter stop_bit = 3'b011;
    parameter cleanup = 3'b100;
    //variable declerations
    reg [2:0]state = 0;
    reg [9:0]clk_ctr = 0;
    reg [2:0]no_bits = 0;
    //State machine
    always@(posedge clk, posedge rst) begin
    if(rst==1) begin
        state <= idle;
        clk_ctr <= 0;
        no_bits <= 0;
        RXbits <= 0;
        indicator <= 0;
    end
    else begin
    case(state)
    // IDLE STATE 
    idle: begin
        indicator <= 1'b0;
        clk_ctr <= 0;
        RXbits <= 0;
        if(rx==1'b0)
        state <= start_bit;
        else
        state <= idle;
        end
    //START BIT STATE
    start_bit: begin
        if(clk_ctr == ((clk_cycles-1)/2))
        begin 
        if(rx==1'b0) begin
        clk_ctr <= 0;
        state <= data_bits;
        end
        else 
        state <= idle;
        end
        else begin
        clk_ctr<=clk_ctr+1;
        state<=start_bit;
        end
        end
        //DATA BITS STATE
        data_bits: begin
        if(clk_ctr == clk_cycles-1) begin 
        RXbits[no_bits] <= rx; 
        clk_ctr <= 0;
        if(no_bits<7) begin
        no_bits<=no_bits+1;
        state <= data_bits;
        end
        else begin
        state <= stop_bit;
        no_bits<=0;
        end
        end
        else begin 
        clk_ctr <= clk_ctr+1;
        state <= data_bits;
        end
        end
        //STOP BIT STATE
        stop_bit: begin
        if(clk_ctr < clk_cycles-1) begin
        clk_ctr<=clk_ctr+1;
        state<=stop_bit;
        end
        else begin
        clk_ctr<=0;
        indicator <= 1'b1;
        state<=cleanup;
        end
        end
        //CLEANUP STATE
        cleanup: begin
        indicator <= 1'b0;
        state <= idle;
        end
        default: state <= idle; 
        endcase
        end
        end
//-----------------------------------------------------------------------------------
        // DISPLAYING THE DATA BITS IN 7 SEGMENT DISPLAY
//-----------------------------------------------------------------------------------
//Generating a seven segment display refresh signal, we choose 60Hz
//This means we refresh 60 times every second, time perioed between refreshes  = 16.6 ms
//
reg [19:0] refresh_counter;
wire [1:0] activating_ctr;
always@(posedge clk or posedge rst) begin
if(rst==1)
refresh_counter<=1;
else 
refresh_counter<=refresh_counter+1;
end
assign activating_ctr = refresh_counter[19:18];
//-----------------------------------------------------
//Creating anode signals and updating values of 7 segment display
// data is a 16 bit number every 4 bit will be displayed on different 7 segs 

//flip flop for registering last transferred data over uart
reg [3:0]single_disp;
reg [7:0]bit_store;
always@(posedge indicator) begin
bit_store <= RXbits;
end

always @(*) begin
case (activating_ctr)
    2'b00:begin
     an = 4'b0111;
     single_disp = bit_store/1000;
     end
    2'b01: begin
    an = 4'b1011;
    single_disp =(bit_store % 1000)/100;
     end
    2'b10: begin
    an = 4'b1101;
    single_disp = ((bit_store % 1000)%100)/10;
     end
    2'b11: begin
     an = 4'b1110;
     single_disp = ((bit_store % 1000)%100)%10;
     end
//    default: begin 
//    an = 4'b0111;
//    single_disp = num_display[15:12];
//     end
    endcase
end
//-------Cathode pattern for 7 segment display---------
always@(*) begin
case(single_disp)
        4'b0000: seg = 7'b1000000; // "0"     
        4'b0001: seg = 7'b1111001; // "1" 
        4'b0010: seg = 7'b0100100; // "2" 
        4'b0011: seg = 7'b0110000; // "3" 
        4'b0100: seg = 7'b0011001; // "4" 
        4'b0101: seg = 7'b0010010; // "5" 
        4'b0110: seg = 7'b0000010; // "6" 
        4'b0111: seg = 7'b1111000; // "7" 
        4'b1000: seg = 7'b0000000; // "8"     
        4'b1001: seg = 7'b0010000; // "9" 
        default: seg = 7'b1000000; // "0"
        endcase
end
//----------------------------------------------------------------
endmodule