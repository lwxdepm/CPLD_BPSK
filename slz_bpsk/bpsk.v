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
    input  wire  clk_in,         // ����ʱ�� (7.68MHz)
    
    output reg   clk_out_3_84M,  // �������Ƶʱ�� (3.84MHz)
    output reg   clk_out_14k,    // �������ʱ�� (14.1176kHz)
    output reg   bpsk_out        // �����BPSK�����ź�
);

// --- BPSK �������� ---
localparam [127:0] DATA_SEQUENCE = {32'b00011011000111100001101100011110, 
                                     32'b00011011000111100001101100011110,
                                     32'b00011011000111100001101100011110,
                                     32'b00011011000111100001101100011110};

// --- 14.1176kHz ʱ�ӷ�Ƶ���� ---
localparam DIV_FACTOR_14K = 544;
localparam MAX_COUNT_14K = DIV_FACTOR_14K - 1;
localparam TOGGLE_POINT_14K = DIV_FACTOR_14K / 2;

// --- �ڲ��źŶ��� ---
// 14.1176kHz ʱ�Ӽ�����
reg [9:0] counter_14k = 10'd0;

// BPSK ���ں����ݱ��ؼ����� (8λ: 0-127Ϊ��������, 128-255Ϊ��������)
reg [7:0] cycle_counter = 8'd0;

// --- ��ʼ������ź� ---
initial begin
    clk_out_3_84M = 1'b0;
    clk_out_14k   = 1'b0;
    bpsk_out      = 1'b0;
end

// --- ʱ���߼� ---
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
    // ÿ���������� (1/14.1176kHz) ����ʱ���������ڼ�����
    // ��������������ŷ�����һλ���ݣ��Լ���ʱ�������״̬
    if (counter_14k == MAX_COUNT_14K) begin
        cycle_counter <= cycle_counter + 1; // 8λ���������Զ���255���Ƶ�0
    end

    // �������ڼ������������
    // ���ڼ������� MSB (��7λ) �������ַ������ںͿ�������
    // cycle_counter[7] == 0  ->  0-127   (����)
    // cycle_counter[7] == 1  ->  128-255 (����)
    if (cycle_counter[7] == 1'b0) begin
        // --- �������� ---
        // BPSK ���Ƶ�ʵ��: �ز�(carrier) XOR ����(data)
        // 0 -> carrier ^ 0 = carrier (��λ0��)
        // 1 -> carrier ^ 1 = ~carrier (��λ180��)
        // ʹ�� cycle_counter �ĵ�7λ [6:0] ��Ϊ�������е����� (0 to 127)
        bpsk_out <= clk_out_3_84M ^ DATA_SEQUENCE[cycle_counter[6:0]];
    end else begin
        // --- �������� ---
        // ���ֵ͵�ƽ
        bpsk_out <= 1'b0;
    end
end

endmodule