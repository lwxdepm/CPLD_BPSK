`timescale 1ns / 1ps

/*******************************************************************
* Module:       psk_modulator_parameterized
* Description:  Generates a BPSK modulated signal with a 
* parameter-selectable carrier frequency.
*
* Input Clock:  7.68MHz
* Baseband Rate: 14.1176kbps (Internal)
*
* Carrier Freq: Selectable (0.96MHz to 2.88MHz, 15kHz steps)
* F_out = M_SELECT * 15kHz
*
* Author:       CTZ (Framework by Gemini)
*******************************************************************/
module cpld288 (
    input  wire  clk_in,       // 输入时钟 (7.68MHz)
    output reg   bpsk_out, // 输出的BPSK调制信号
    output wire  carrier_out   // 可配置的载波时钟输出
);

// --- BPSK 数据序列 ---
localparam [127:0] DATA_SEQUENCE = {4{32'b00001010111011000111110011010010}};

// --- 14.1176kHz 时钟分频参数 ---
localparam DIV_FACTOR_14K = 544;
localparam MAX_COUNT_14K = DIV_FACTOR_14K - 1;

// --- 内部信号定义 ---

// --- 可配置载波时钟 (Fractional-N) ---
//
// F_out = M_SELECT * 15 kHz
//
// *******************************************************************
// * 用户配置参数: M_SELECT
// * M_SELECT = 目标频率(kHz) / 15(kHz)
// *
// * 范围: 64 (0.96MHz) 到 192 (2.88MHz)
// *
// * 示例:
// * 0.96 MHz -> M = 960 / 15  = 64
// * 1.50 MHz -> M = 1500 / 15 = 100
// * 2.85 MHz -> M = 2850 / 15 = 190
// * 2.88 MHz -> M = 2880 / 15 = 192
// *******************************************************************
//
// V--- 唯一需要修改的参数 ---V
localparam M_SELECT = 8'd64; // 示例: 192 * 15kHz = 2.88 MHz
// ^--- 唯一需要修改的参数 ---^


// --- 累加器逻辑 (M / 256) ---
reg clk_out_carrier = 1'b0;      // 内部载波时钟
reg [7:0] carrier_acc = 8'd0;     // 8-bit 相位累加器
// 累加器加法和进位检测
wire [8:0] carrier_sum = {1'b0, carrier_acc} + M_SELECT;
wire carrier_toggle = carrier_sum[8]; // 溢出/进位信号 (第9位)


// --- 14.1176kHz 子时钟 ---
reg [9:0] counter_14k = 10'd0;    // 14.1176kHz 时钟计数器

// BPSK 周期和数据比特计数器
reg [7:0] cycle_counter = 8'd0;


// --- 将内部载波时钟连接到输出端口 ---
assign carrier_out = clk_out_carrier;


// --- 时序逻辑 ---
always @(posedge clk_in) begin
    
    // --- Carrier Clock Generation (Internal) ---
    // 累加器在每个 7.68MHz 周期累加 M_SELECT
    carrier_acc <= carrier_sum[7:0]; // 取低8位
    // 当累加器溢出时，翻转输出
    if (carrier_toggle) begin
        clk_out_carrier <= ~clk_out_carrier;
    end

    // --- 14.1176kHz clock counter (Internal) ---
    if (counter_14k == MAX_COUNT_14K) begin
        counter_14k <= 10'd0;
    end else begin
        counter_14k <= counter_14k + 1;
    end
    
    // --- BPSK Signal Generation ---
    // 每个基带周期 (1/14.1176kHz) 结束时，更新周期计数器
    if (counter_14k == MAX_COUNT_14K) begin
        cycle_counter <= cycle_counter + 1; 
    end

    // 根据周期计数器决定输出
    if (cycle_counter[7] == 1'b0) begin
        // --- 发送周期 ---
        // BPSK 调制的实现: 载波(carrier) XOR 数据(data)
        bpsk_out <= clk_out_carrier ^ DATA_SEQUENCE[127 - cycle_counter[6:0]];
    end else begin
        // --- 空闲周期 ---
        bpsk_out <= 1'b0;
    end
end

endmodule