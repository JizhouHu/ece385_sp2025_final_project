module bullet_2
( 
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [2:0]  TankDir,
    input  logic [9:0]  TankX,
    input  logic [9:0]  TankY,
    input  logic [31:0] keycode,
    input  logic [2:0]  game_state,
    input  logic [3:0]  SW,
    input  logic        TankDead_1,
    input  logic        TankDead_2,
    input logic [9:0]  obs_left   [11:0],
    input logic [9:0]  obs_right  [11:0],
    input logic [8:0]  obs_top    [11:0],
    input logic [8:0]  obs_bottom [11:0],
    input logic        shoot_en,

    output logic [9:0]  BulletX [4:0],
    output logic [9:0]  BulletY [4:0],
    output logic [4:0]  Is_bullet_active,
    output logic [9:0]  BulletS
    //output logic [3:0]  BulletAge [4:0] // spawn immunity
);

    localparam [9:0] Bullet_X_Min = 0;
    localparam [9:0] Bullet_X_Max = 639;
    localparam [9:0] Bullet_Y_Min = 16;
    localparam [9:0] Bullet_Y_Max = 479;
    localparam int SHOT_COOLDOWN_MAX = 60; // 1s at 60Hz
    int refill_time = 600; // 10 seconds @ 60 FPS

    logic [9:0] Bullet_X_Motion [4:0];
    logic [9:0] Bullet_Y_Motion [4:0];
    logic [4:0] shot_cooldown_counter;
    int lifetime_counter [4:0];
    
    logic [9:0] BulletX_next;
    logic [9:0] BulletY_next;

    assign BulletS = 4;

    logic [7:0] shoot_key;

    always_comb 
    begin
        if (Reset)
            refill_time = 600;
        else if (game_state == 3'd2) begin
            unique case (SW)
                4'b0001: //5s
                    refill_time = 300;
                4'b0010: //10s
                    refill_time = 600;
                4'b0100: //15s
                    refill_time = 900;
                4'b1000: //20s
                    refill_time = 1200;
                default:
                    refill_time = 600;
            endcase
        end
    end

    // Extract shooting key (spacebar for P2)
    always_comb begin
        shoot_key = 8'h00;
        if (keycode[7:0] == 8'h2C)         shoot_key = keycode[7:0];
        else if (keycode[15:8] == 8'h2C)    shoot_key = keycode[15:8];
        else if (keycode[23:16] == 8'h2C)   shoot_key = keycode[23:16];
        else if (keycode[31:24] == 8'h2C)   shoot_key = keycode[31:24];
    end

    always_ff @(posedge frame_clk or posedge Reset) begin

        if (Reset) begin
            shot_cooldown_counter <= 0;
        end else begin
            if (shot_cooldown_counter > 0)
                shot_cooldown_counter <= shot_cooldown_counter - 1;
        end

        if (TankDead_1 || TankDead_2) begin
            for (int i = 0; i < 5; i++) begin
                Is_bullet_active[i] <= 0;
            end
        end

        if (Reset) begin
            for (int i = 0; i < 5; i++) begin
                BulletX[i] <= 0;
                BulletY[i] <= 0;
                Bullet_X_Motion[i] <= 0;
                Bullet_Y_Motion[i] <= 0;
                Is_bullet_active[i] <= 0;
                lifetime_counter[i] <= 0;
            end
        end 
        else begin
            // Firing new bullet if there's an available slot
            if (shoot_key == 8'h2C && shot_cooldown_counter == 0 && shoot_en) begin
                for (int i = 0; i < 5; i++) begin
                    if (!Is_bullet_active[i]) begin
                        Is_bullet_active[i] <= 1'b1;
                        lifetime_counter[i] <= 0;

                        case (TankDir)
                            3'b000: begin // Up
                                BulletX[i] <= TankX;
                                BulletY[i] <= TankY - 20;
                                Bullet_X_Motion[i] <= 0;
                                Bullet_Y_Motion[i] <= -3;
                            end
                            3'b001: begin // Down
                                BulletX[i] <= TankX;
                                BulletY[i] <= TankY + 20;
                                Bullet_X_Motion[i] <= 0;
                                Bullet_Y_Motion[i] <= 3;
                            end
                            3'b010: begin // Left
                                BulletX[i] <= TankX - 20;
                                BulletY[i] <= TankY;
                                Bullet_X_Motion[i] <= -3;
                                Bullet_Y_Motion[i] <= 0;
                            end
                            3'b011: begin // Right
                                BulletX[i] <= TankX + 20;
                                BulletY[i] <= TankY;
                                Bullet_X_Motion[i] <= 3;
                                Bullet_Y_Motion[i] <= 0;
                            end
                            default: ;
                        endcase

                        shot_cooldown_counter <= SHOT_COOLDOWN_MAX;
                        break; // Fire only one bullet per key press
                    end
                end
            end

            // Update all active bullets
            for (int i = 0; i < 5; i++) begin
                if (Is_bullet_active[i]) begin
                    //BulletAge[i] <= BulletAge[i] + 1;
                    BulletX_next = BulletX[i] + Bullet_X_Motion[i];
                    BulletY_next = BulletY[i] + Bullet_Y_Motion[i];

                    // Bounce on walls
                    if (BulletX_next <= Bullet_X_Min || BulletX_next >= Bullet_X_Max)
                        Bullet_X_Motion[i] <= -Bullet_X_Motion[i];
                    if (BulletY_next <= Bullet_Y_Min || BulletY_next >= Bullet_Y_Max)
                        Bullet_Y_Motion[i] <= -Bullet_Y_Motion[i];

                    // Bounce on obstacles 
                    for (int j = 0; j < 12; j++) begin
                         if (!(BulletX_next + 2 <= obs_left[j] || BulletX_next - 2 >= obs_right[j] ||
                             BulletY_next + 2 <= obs_top[j]  || BulletY_next - 2 >= obs_bottom[j])) begin

                            // // horizontal surface: bounce Y
                            // if ((BulletY[i] < obs_top[j] && BulletY_next >= obs_top[j]) ||
                            //     (BulletY[i] > obs_bottom[j] && BulletY_next <= obs_bottom[j])) begin
                            //     Bullet_Y_Motion[i] <= -Bullet_Y_Motion[i];
                            // end

                            // // vertical surface: bounce X
                            // if ((BulletX[i] < obs_left[j] && BulletX_next >= obs_left[j]) ||
                            //     (BulletX[i] > obs_right[j] && BulletX_next <= obs_right[j])) begin
                            //     Bullet_X_Motion[i] <= -Bullet_X_Motion[i];
                            // end

                            // horizontal surface: bounce Y
                            if ((BulletY_next + 4 >= obs_top[j]) ||
                                (BulletY_next - 4 <= obs_bottom[j])) begin
                                Bullet_Y_Motion[i] <= -Bullet_Y_Motion[i];
                            end

                            // vertical surface: bounce X
                            if ((BulletX_next + 4 >= obs_left[j]) ||
                                (BulletX_next - 4 <= obs_right[j])) begin
                                Bullet_X_Motion[i] <= -Bullet_X_Motion[i];
                            end

                         end
                    end

                    // Move bullet
                    BulletX[i] <= BulletX[i] + Bullet_X_Motion[i];
                    BulletY[i] <= BulletY[i] + Bullet_Y_Motion[i];

                    // Lifetime update
                    lifetime_counter[i] <= lifetime_counter[i] + 1;
                    if (lifetime_counter[i] >= refill_time)
                        Is_bullet_active[i] <= 1'b0;
                end
            end
        end
    end
endmodule
