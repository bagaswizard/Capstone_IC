`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Company: Digilent
// Engineer: Arthur Brown
// 
// Create Date: 04/13/2018 03:33:26 PM
// Design Name: Cmod S7-25 Out-of-Box Demo
// Module Name: top
// Target Devices: Cmod S7-25
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tt_um_top (
    // 12MHz System Clock
    input wire clk,
    // RGB LED (Active Low)
    output wire led0_r,
    output wire led0_g,
    output wire led0_b,
    // 4 LEDs
    output wire [3:0] led,
    // UART TX
    output wire tx,
    // 2 Buttons
    // input wire [1:0] btn, // No longer needed
    // DS18B20 1-Wire Data
    inout wire ds18b20_dq,

    input wire ena,
    input [7:0] ui_in,
    input wire rst_n
);
    localparam CD_COUNT_MAX = 12000000/2;
    localparam UART_PERIOD_CLOCKS = 12000000; // 1 second period
    wire brightness;
    reg [$clog2(CD_COUNT_MAX-1)-1:0] cd_count = 'b0;
    reg [3:0] led_shift = 4'b0001;
    // wire [1:0] db_btn; // No longer needed
    wire [15:0] uart_data;
    wire ds18b20_sign;
    
    // UART periodic trigger
    reg [$clog2(UART_PERIOD_CLOCKS)-1:0] uart_trig_counter = 'b0;
    wire uart_trig;
    
    always @(posedge clk) begin
        if (uart_trig_counter >= UART_PERIOD_CLOCKS - 1) begin
            uart_trig_counter <= 'b0;
        end else begin
            uart_trig_counter <= uart_trig_counter + 1;
        end
    end
    assign uart_trig = (uart_trig_counter == UART_PERIOD_CLOCKS - 1);

    // The ds18b20_dri module provides the temperature data, which is then sent via UART.
    // The button press will trigger the UART transmission.
    // assign uart_data = 16'd30000; // This is now driven by the DS18B20 module
        
    pwm #(
        .COUNTER_WIDTH(8),
        .MAX_COUNT(255)
    ) m_pwm (
        .clk(clk),
        .duty(8'd127),
        .pwm_out(brightness)
    );
    
    always@(posedge clk)
        if (cd_count >= CD_COUNT_MAX-1) begin // 2Hz
            cd_count <= 'b0;
            led_shift <= {led_shift[2:0], led_shift[3]}; // cycle the LEDs and the color of the RGB LED
        end else
            cd_count <= cd_count + 1'b1;
    assign led = led_shift;
    assign {led0_r, led0_g, led0_b} = ~(led_shift[2:0] & {3{brightness}});
    
    /* debouncer #( // No longer needed
        .WIDTH(2),
        .CLOCKS(1024),
        .CLOCKS_CLOG2(10)
    ) m_db_btn (
        .clk(clk),
        .din(btn),
        .dout(db_btn)
    ); */
    
    // Instantiate DS18B20 temperature sensor driver
    ds18b20_dri m_ds18b20 (
        .clk(clk),          // 12MHz clock
        .rst_n(1'b1),       // No reset connected, tied high
        .dq(ds18b20_dq),    // 1-wire data pin
        .temp_data(uart_data), // Output temperature data to uart_data wire
        .sign(ds18b20_sign) // Temperature sign bit
    );

    // Transmit temperature data periodically
    uart_tx #(
        .BAUD_2_CLOCK_RATIO(12000000 / 9600),
        .UART_DATA_BITS(8),
        .UART_STOP_BITS(2),
        .INPUT_DATA_WIDTH(16)
    ) m_uart_tx (
        .clk(clk),
        .start_tx(uart_trig),
        .data_in(uart_data),
        .tx(tx)
    );
endmodule
