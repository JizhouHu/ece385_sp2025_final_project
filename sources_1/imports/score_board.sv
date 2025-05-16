module score_board
(
    input logic Reset,
    input logic frame_clk,
    input logic TankDead_1,
    input logic TankDead_2,
    input logic [3:0] SW,
    input logic [2:0] game_state,

    output logic relife,
    output logic [3:0] p1_score,
    output logic [3:0] p2_score,
    output logic [3:0] wins_need
);

    logic td1_d, td2_d;
    wire  td1_rise =  TankDead_1 & !td1_d;
    wire  td2_rise =  TankDead_2 & !td2_d;

    logic [3:0] battle_number;   // 3,5,7,9,11

    assign wins_need = (battle_number >> 1) + 1;

    // --------------------- set battle number ------------------------------
    always_comb begin
        if (Reset)
            battle_number = 4'd3;
        else if (game_state == 3'd1) begin
            unique case (SW)
                4'b0001: battle_number = 4'd5;
                4'b0010: battle_number = 4'd7;
                4'b0100: battle_number = 4'd9;
                4'b1000: battle_number = 4'd11;
                default: battle_number = 4'd3;
            endcase
        end
    end

    // delay registers for edge detect
    always_ff @(posedge frame_clk) begin
        td1_d <= TankDead_1;
        td2_d <= TankDead_2;
    end

    // -------------- score registers & relife pulse --------------------------
    logic relife_q;

    assign relife = relife_q;

    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset) begin
            p1_score <= 4'd0;
            p2_score <= 4'd0;
            relife_q <= 1'b0;
        end
        else begin
            relife_q <= 1'b0;

            if (game_state == 3'd3 && (td1_rise || td2_rise)) begin
                if (td1_rise) p2_score <= p2_score + 1;
                if (td2_rise) p1_score <= p1_score + 1;

                if ( ( (td1_rise && (p2_score + 1) < wins_need) ||
                       (td2_rise && (p1_score + 1) < wins_need) ) )
                    relife_q <= 1'b1;          // pulse for next frame
            end
        end
    end
    
endmodule