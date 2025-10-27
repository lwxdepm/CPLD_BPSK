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
    input  wire  clk_in,       // ����ʱ�� (7.68MHz)
    output reg   bpsk_out, // �����BPSK�����ź�
    output wire  carrier_out   // �����õ��ز�ʱ�����
);

// --- BPSK �������� ---
localparam [127:0] DATA_SEQUENCE = {4{32'b00001010111011000111110011010010}};

// --- 14.1176kHz ʱ�ӷ�Ƶ���� ---
localparam DIV_FACTOR_14K = 544;
localparam MAX_COUNT_14K = DIV_FACTOR_14K - 1;

// --- �ڲ��źŶ��� ---

// --- �������ز�ʱ�� (Fractional-N) ---
//
// F_out = M_SELECT * 15 kHz
//
// *******************************************************************
// * �û����ò���: M_SELECT
// * M_SELECT = Ŀ��Ƶ��(kHz) / 15(kHz)
// *
// * ��Χ: 64 (0.96MHz) �� 192 (2.88MHz)
// *
// * ʾ��:
// * 0.96 MHz -> M = 960 / 15  = 64
// * 1.50 MHz -> M = 1500 / 15 = 100
// * 2.85 MHz -> M = 2850 / 15 = 190
// * 2.88 MHz -> M = 2880 / 15 = 192
// *******************************************************************
//
// V--- Ψһ��Ҫ�޸ĵĲ��� ---V
localparam M_SELECT = 8'd64; // ʾ��: 192 * 15kHz = 2.88 MHz
// ^--- Ψһ��Ҫ�޸ĵĲ��� ---^


// --- �ۼ����߼� (M / 256) ---
reg clk_out_carrier = 1'b0;      // �ڲ��ز�ʱ��
reg [7:0] carrier_acc = 8'd0;     // 8-bit ��λ�ۼ���
// �ۼ����ӷ��ͽ�λ���
wire [8:0] carrier_sum = {1'b0, carrier_acc} + M_SELECT;
wire carrier_toggle = carrier_sum[8]; // ���/��λ�ź� (��9λ)


// --- 14.1176kHz ��ʱ�� ---
reg [9:0] counter_14k = 10'd0;    // 14.1176kHz ʱ�Ӽ�����

// BPSK ���ں����ݱ��ؼ�����
reg [7:0] cycle_counter = 8'd0;


// --- ���ڲ��ز�ʱ�����ӵ�����˿� ---
assign carrier_out = clk_out_carrier;


// --- ʱ���߼� ---
always @(posedge clk_in) begin
    
    // --- Carrier Clock Generation (Internal) ---
    // �ۼ�����ÿ�� 7.68MHz �����ۼ� M_SELECT
    carrier_acc <= carrier_sum[7:0]; // ȡ��8λ
    // ���ۼ������ʱ����ת���
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
    // ÿ���������� (1/14.1176kHz) ����ʱ���������ڼ�����
    if (counter_14k == MAX_COUNT_14K) begin
        cycle_counter <= cycle_counter + 1; 
    end

    // �������ڼ������������
    if (cycle_counter[7] == 1'b0) begin
        // --- �������� ---
        // BPSK ���Ƶ�ʵ��: �ز�(carrier) XOR ����(data)
        bpsk_out <= clk_out_carrier ^ DATA_SEQUENCE[127 - cycle_counter[6:0]];
    end else begin
        // --- �������� ---
        bpsk_out <= 1'b0;
    end
end

endmodule