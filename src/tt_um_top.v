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
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    // Internal signals for the original design
    wire led0_r;
    wire led0_g;
    wire led0_b;
    wire [3:0] led;
    wire tx;
    wire ds18b20_dq; // This wire connects to the inout port of the sensor module

    // The ds18b20_dq_out and ds18b20_dq_oe signals are no longer needed
    // wire ds18b20_dq_out;
    // wire ds18b20_dq_oe;

    // Map outputs to uo_out
    // uo_out[0] = led0_r
    // uo_out[1] = led0_g
    // uo_out[2] = led0_b
    // uo_out[6:3] = led[3:0]
    // uo_out[7] = tx
    assign uo_out = {tx, led, led0_b, led0_g, led0_r};

    // Map inout ds18b20_dq to uio bidirectional port 0
    // The ds18b20_dri module drives ds18b20_dq when it needs to write,
    // and leaves it high-Z when it needs to read.
    assign uio_out[0] = ds18b20_dq;
    // The output enable is 1 when the ds18b20_dq wire is being driven (not Z).
    assign uio_oe[0] = (ds18b20_dq !== 1'bz);
    // When the pin is not driven by this module, read the value from the input.
    assign ds18b20_dq = (uio_oe[0] == 1'b0) ? uio_in[0] : 1'bz;

    // Set other uio ports as inputs
    assign uio_out[7:1] = 8'h00;
    assign uio_oe[7:1] = 8'h00;


    // Original top module logic
    localparam CD_COUNT_MAX = 12000000/2;
    localparam UART_PERIOD_CLOCKS = 12000000; // 1 second period
    wire brightness;
    reg [$clog2(CD_COUNT_MAX-1)-1:0] cd_count = 'b0;
    reg [3:0] led_shift = 4'b0001;
    wire [15:0] uart_data;
    wire ds18b20_sign;
    
    // UART periodic trigger
    reg [$clog2(UART_PERIOD_CLOCKS)-1:0] uart_trig_counter = 'b0;
    wire uart_trig;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_trig_counter <= 'b0;
        end else if (ena) begin
            if (uart_trig_counter >= UART_PERIOD_CLOCKS - 1) begin
                uart_trig_counter <= 'b0;
            end else begin
                uart_trig_counter <= uart_trig_counter + 1;
            end
        end
    end
    assign uart_trig = (uart_trig_counter == UART_PERIOD_CLOCKS - 1) && ena;
        
    pwm #(
        .COUNTER_WIDTH(8),
        .MAX_COUNT(255)
    ) m_pwm (
        .clk(clk),
        .duty(8'd127),
        .pwm_out(brightness)
    );
    
    always@(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cd_count <= 'b0;
            led_shift <= 4'b0001;
        end else if (ena) begin
            if (cd_count >= CD_COUNT_MAX-1) begin // 2Hz
                cd_count <= 'b0;
                led_shift <= {led_shift[2:0], led_shift[3]}; // cycle the LEDs and the color of the RGB LED
            end else
                cd_count <= cd_count + 1'b1;
        end
    end
    assign led = led_shift;
    assign {led0_r, led0_g, led0_b} = ~(led_shift[2:0] & {3{brightness}});
    
    // Instantiate DS18B20 temperature sensor driver
    ds18b20_dri m_ds18b20 (
        .clk(clk),          // 12MHz clock
        .rst_n(rst_n),
        .dq(ds18b20_dq),       // Connect to the single inout pin
        .temp_data(uart_data), // Output temperature data to uart_data wire
        .sign(ds18b20_sign)    // Temperature sign bit
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
