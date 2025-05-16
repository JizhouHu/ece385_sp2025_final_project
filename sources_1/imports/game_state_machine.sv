module game_state_machine
(
    input  logic        clk,
    input  logic        reset,

    //---------------- user controls / round result ---------------------------
    input  logic        CONT,          // menu advance
    input  logic        TankDead_1,
    input  logic        TankDead_2,

    //---------------- live scores from scoreboard ---------------------------
    input  logic [3:0]  p1_score,
    input  logic [3:0]  p2_score,
    input  logic [3:0]  wins_need,

    //---------------- outputs -------------------------------------------------
    output logic [2:0]  game_state
);

    typedef enum logic [2:0] {
        START_SCREEN         = 3'd0,
        SET_TANK_BA          = 3'd1,
        SET_BULLET_COOLDOWN  = 3'd2,
        PLAY_GAME            = 3'd3,
        CHECK_SCORE          = 3'd4,
        END_SCREEN           = 3'd5
    } state_t;

    state_t curr_state, next_state;

    always_ff @(posedge clk or posedge reset)
        if (reset) curr_state <= START_SCREEN;
        else       curr_state <= next_state;


    // --------------------- next state logic -----------------------------------
    always_comb begin
        next_state = curr_state;

        unique case (curr_state)
            //--------------------------------  MENU FLOW
            START_SCREEN:
                if (CONT) next_state = SET_TANK_BA;

            SET_TANK_BA:
                if (CONT) next_state = SET_BULLET_COOLDOWN;

            SET_BULLET_COOLDOWN:
                if (CONT) next_state = PLAY_GAME;

            //--------------------------------  GAME PLAY
            PLAY_GAME: begin
                if (TankDead_1 || TankDead_2)
                    next_state = CHECK_SCORE;
            end

            //--------------------------------  CHECK SCORE
            CHECK_SCORE: begin
                if (p1_score >= wins_need || p2_score >= wins_need)
                    next_state = END_SCREEN;   // overall winner
                else begin
                    next_state = PLAY_GAME;
                end
            end

            //--------------------------------  END
            END_SCREEN:
                if (reset) next_state = START_SCREEN;
        endcase
    end

    assign game_state = curr_state;
endmodule