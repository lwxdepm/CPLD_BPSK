`timescale 1ns / 1ps

/*******************************************************************
* Module:         psk_modulator
* Description:    Generates a BPSK modulated signal from a 7.68MHz 
* input clock. The two internal clocks are no longer
* output ports.
* - Carrier Freq: 3.84MHz (Internal)
* - Baseband Rate: 14.1176kbps (Internal)
* Author:         CTZ
*******************************************************************/
module psk_modulator (
    input  wire  clk_in,       // ����ʱ�� (7.68MHz)
    output reg   bpsk_out      // �����BPSK�����ź�
);

// --- BPSK �������� ---
// ����: 0000_1010_1110_1100_0111_1100_1101_0010 (��32λ), �ظ�4��
localparam [127:0] DATA_SEQUENCE = {4{32'b00001010111011000111110011010010}};

// --- 14.1176kHz ʱ�ӷ�Ƶ���� ---
localparam DIV_FACTOR_14K = 544;
localparam MAX_COUNT_14K = DIV_FACTOR_14K - 1;
localparam TOGGLE_POINT_14K = DIV_FACTOR_14K / 2;

// --- �ڲ��źŶ��� ---
// �ڲ�3.84MHz��Ƶʱ��
reg clk_out_3_84M;
// �ڲ�14.1176kHz��ʱ��
reg clk_out_14k;

// 14.1176kHz ʱ�Ӽ�����
reg [9:0] counter_14k = 10'd0;

// BPSK ���ں����ݱ��ؼ����� (8λ: 0-127Ϊ��������, 128-255Ϊ��������)
reg [7:0] cycle_counter = 8'd0;

// --- ��ʼ���ź� ---
initial begin
    clk_out_3_84M = 1'b0;
    clk_out_14k   = 1'b0;
    bpsk_out      = 1'b0;
end

// --- ʱ���߼� ---
always @(posedge clk_in) begin
    // --- Clock Generation (Internal) ---
    // 3.84MHz clock (Divide-by-2)
    clk_out_3_84M <= ~clk_out_3_84M;

    // 14.1176kHz clock counter
    if (counter_14k == MAX_COUNT_14K) begin
        counter_14k <= 10'd0;
    end else begin
        counter_14k <= counter_14k + 1;
    end
    
    // 14.1176kHz clock generation
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
        // ʹ�� (127 - cycle_counter[6:0]) ��Ϊ������ʵ�ִ�MSB��LSB����
        bpsk_out <= clk_out_3_84M ^ DATA_SEQUENCE[127 - cycle_counter[6:0]];
    end else begin
        // --- �������� ---
        // ���ֵ͵�ƽ
        bpsk_out <= 1'b0;
    end
end

endmodule
