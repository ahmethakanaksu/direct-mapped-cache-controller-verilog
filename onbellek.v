`timescale 1ns / 1ps

module onbellek (
    input               clk_i,
    input               rst_i,

    //Ana bellek elementleri
    output reg  [31:0]  anabellek_istek_adres_o,
    output reg  [127:0] anabellek_istek_veri_o,
    output reg          anabellek_istek_gecerli_o,
    output reg          anabellek_istek_yaz_gecerli_o,
    input               anabellek_istek_hazir_i,
    input       [127:0] anabellek_cevap_veri_i,
    input               anabellek_cevap_gecerli_i,
    output reg          anabellek_cevap_hazir_o,

    //Ýþlemci elementleri
    input       [31:0]  islemci_istek_adres_i,
    input       [31:0]  islemci_istek_veri_i,
    input               islemci_istek_gecerli_i,
    input               islemci_istek_yaz_i,
    output reg          islemci_istek_hazir_o,
    output reg  [31:0]  islemci_cevap_veri_o,
    output reg          islemci_cevap_gecerli_o,
    input               islemci_cevap_hazir_i,

    //BRAM elementleri (test)
    output reg          onbellek_istek_gecerli_o,
    output reg          onbellek_istek_yaz_o,
    output reg  [127:0] onbellek_istek_veri_o,
    output reg  [31:0]  onbellek_istek_adres_o,
    input       [127:0] onbellek_cevap_veri_i
);

    // Tag, valid ve veri alanlarý
    reg [20:0] tag_array [127:0];
    reg        valid_array [127:0];
    reg [127:0] data_array [127:0];

    wire [6:0] index = islemci_istek_adres_i[10:4];
    wire [3:0] offset = islemci_istek_adres_i[3:0];
    wire [20:0] tag = islemci_istek_adres_i[31:11];

    reg [3:0] state;
    localparam IDLE = 0,
               MISS = 1,
               WRITE_BACK = 2,
               WAIT_MEM = 3,
               RESPOND = 4;

    reg [3:0] next_state;

    reg miss_flag;
    reg [31:0] cached_word;
    reg [127:0] block_data;

    always @(*) begin
        onbellek_istek_gecerli_o = 0;
        onbellek_istek_yaz_o = 0;
        onbellek_istek_veri_o = 0;
        onbellek_istek_adres_o = 0;

        anabellek_istek_adres_o = {islemci_istek_adres_i[31:4], 4'b0000};
        anabellek_istek_veri_o = 128'b0;
        anabellek_istek_gecerli_o = 0;
        anabellek_istek_yaz_gecerli_o = 0;
        anabellek_cevap_hazir_o = 0;

        islemci_istek_hazir_o = 0;
        islemci_cevap_gecerli_o = 0;
        islemci_cevap_veri_o = 0;

        next_state = state;

        case (state)
            IDLE: begin
                if (islemci_istek_gecerli_i) begin
                    if (valid_array[index] && tag_array[index] == tag) begin
                        // HIT
                        block_data = data_array[index];
                        case (offset[3:2])
                            2'b00: cached_word = block_data[31:0];
                            2'b01: cached_word = block_data[63:32];
                            2'b10: cached_word = block_data[95:64];
                            2'b11: cached_word = block_data[127:96];
                        endcase

                        islemci_cevap_veri_o = cached_word;
                        islemci_cevap_gecerli_o = 1;
                        islemci_istek_hazir_o = 1;

                        // Write-through
                        if (islemci_istek_yaz_i) begin
                            case (offset[3:2])
                                2'b00: data_array[index][31:0]   = islemci_istek_veri_i;
                                2'b01: data_array[index][63:32]  = islemci_istek_veri_i;
                                2'b10: data_array[index][95:64]  = islemci_istek_veri_i;
                                2'b11: data_array[index][127:96] = islemci_istek_veri_i;
                            endcase

                            // BRAM'e yaz
                            onbellek_istek_gecerli_o = 1;
                            onbellek_istek_yaz_o = 1;
                            onbellek_istek_adres_o = {islemci_istek_adres_i[31:4], 4'b0000};
                            onbellek_istek_veri_o = data_array[index];

                            // Ana belleðe yaz
                            anabellek_istek_adres_o = {islemci_istek_adres_i[31:4], 4'b0000};
                            anabellek_istek_veri_o = data_array[index];
                            anabellek_istek_gecerli_o = 1;
                            anabellek_istek_yaz_gecerli_o = 1;
                        end
                    end else begin
                        // MISS
                        anabellek_istek_adres_o = {islemci_istek_adres_i[31:4], 4'b0000};
                        anabellek_istek_gecerli_o = 1;
                        anabellek_istek_yaz_gecerli_o = 0;
                        next_state = WAIT_MEM;
                    end
                end
            end

            WAIT_MEM: begin
                if (anabellek_cevap_gecerli_i) begin
                    // Cevabý al ve arraye yaz
                    data_array[index] = anabellek_cevap_veri_i;
                    tag_array[index] = tag;
                    valid_array[index] = 1;

                    // BRAM'e yaz
                    onbellek_istek_gecerli_o = 1;
                    onbellek_istek_yaz_o = 1;
                    onbellek_istek_adres_o = {islemci_istek_adres_i[31:4], 4'b0000};
                    onbellek_istek_veri_o = anabellek_cevap_veri_i;

                    anabellek_cevap_hazir_o = 1;
                    next_state = RESPOND;
                end
            end

            RESPOND: begin
                islemci_istek_hazir_o = 1;
                islemci_cevap_gecerli_o = 1;

                block_data = data_array[index];
                case (offset[3:2])
                    2'b00: cached_word = block_data[31:0];
                    2'b01: cached_word = block_data[63:32];
                    2'b10: cached_word = block_data[95:64];
                    2'b11: cached_word = block_data[127:96];
                endcase
                islemci_cevap_veri_o = cached_word;

                // write-allocate
                if (islemci_istek_yaz_i) begin
                    case (offset[3:2])
                        2'b00: data_array[index][31:0]   = islemci_istek_veri_i;
                        2'b01: data_array[index][63:32]  = islemci_istek_veri_i;
                        2'b10: data_array[index][95:64]  = islemci_istek_veri_i;
                        2'b11: data_array[index][127:96] = islemci_istek_veri_i;
                    endcase

                    // BRAM'e yaz
                    onbellek_istek_gecerli_o = 1;
                    onbellek_istek_yaz_o = 1;
                    onbellek_istek_adres_o = {islemci_istek_adres_i[31:4], 4'b0000};
                    onbellek_istek_veri_o = data_array[index];

                    // Ana belleðe yaz
                    anabellek_istek_adres_o = {islemci_istek_adres_i[31:4], 4'b0000};
                    anabellek_istek_veri_o = data_array[index];
                    anabellek_istek_gecerli_o = 1;
                    anabellek_istek_yaz_gecerli_o = 1;
                end
                next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk_i) begin
        if (rst_i)
            state <= IDLE;
        else
            state <= next_state;
    end

endmodule
