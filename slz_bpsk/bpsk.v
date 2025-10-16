`timescale 1ns / 1ps

/*******************************************************************
* Module:         psk_modulator
* Description:    Generates clocks and a BPSK modulated signal from a
* 7.68MHz input clock.
* - Carrier Freq: 3.84MHz
* - Baseband Rate: 14.1176kbps
* Author:         Gemini
*******************************************************************/
module psk_modulator (
    input  wire  clk_in,         // 输入时钟 (7.68MHz)
    
    output reg   clk_out_3_84M,  // 输出的中频时钟 (3.84MHz)
    output reg   clk_out_14k,    // 输出的子时钟 (14.1176kHz)
    output reg   bpsk_out        // 输出的BPSK调制信号
);

// --- BPSK 数据序列 ---
localparam [127:0] DATA_SEQUENCE = {32'b00011011000111100001101100011110, 
                                     32'b00011011000111100001101100011110,
                                     32'b00011011000111100001101100011110,
                                     32'b00011011000111100001101100011110};

// --- 14.1176kHz 时钟分频参数 ---
localparam DIV_FACTOR_14K = 544;
localparam MAX_COUNT_14K = DIV_FACTOR_14K - 1;
localparam TOGGLE_POINT_14K = DIV_FACTOR_14K / 2;

// --- 内部信号定义 ---
// 14.1176kHz 时钟计数器
reg [9:0] counter_14k = 10'd0;

// BPSK 周期和数据比特计数器 (8位: 0-127为发送周期, 128-255为空闲周期)
reg [7:0] cycle_counter = 8'd0;

// --- 初始化输出信号 ---
initial begin
    clk_out_3_84M = 1'b0;
    clk_out_14k   = 1'b0;
    bpsk_out      = 1'b0;
end

// --- 时序逻辑 ---
always @(posedge clk_in) begin
    // --- Clock Generation ---
    // 3.84MHz clock (Divide-by-2)
    clk_out_3_84M <= ~clk_out_3_84M;

    // 14.1176kHz clock counter
    if (counter_14k == MAX_COUNT_14K) begin
        counter_14k <= 10'd0;
    end else begin
        counter_14k <= counter_14k + 1;
    end
    
    // 14.1176kHz clock output generation
    if (counter_14k < TOGGLE_POINT_14K) begin
        clk_out_14k <= 1'b1;
    end else begin
        clk_out_14k <= 1'b0;
    end

    // --- BPSK Signal Generation ---
    // 每个基带周期 (1/14.1176kHz) 结束时，更新周期计数器
    // 这个计数器控制着发送哪一位数据，以及何时进入空闲状态
    if (counter_14k == MAX_COUNT_14K) begin
        cycle_counter <= cycle_counter + 1; // 8位计数器会自动从255回绕到0
    end

    // 根据周期计数器决定输出
    // 周期计数器的 MSB (第7位) 用来区分发送周期和空闲周期
    // cycle_counter[7] == 0  ->  0-127   (发送)
    // cycle_counter[7] == 1  ->  128-255 (空闲)
    if (cycle_counter[7] == 1'b0) begin
        // --- 发送周期 ---
        // BPSK 调制的实现: 载波(carrier) XOR 数据(data)
        // 0 -> carrier ^ 0 = carrier (相位0°)
        // 1 -> carrier ^ 1 = ~carrier (相位180°)
        // 使用 cycle_counter 的低7位 [6:0] 作为数据序列的索引 (0 to 127)
        bpsk_out <= clk_out_3_84M ^ DATA_SEQUENCE[cycle_counter[6:0]];
    end else begin
        // --- 空闲周期 ---
        // 保持低电平
        bpsk_out <= 1'b0;
    end
end

endmodule