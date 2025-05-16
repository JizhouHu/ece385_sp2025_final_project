module  color_mapper ( input  logic [9:0] TankX, TankY, DrawX, DrawY, 
                       input  logic [9:0] TankX_2, TankY_2,
                       input  logic [9:0] BulletX [4:0], 
                       input  logic [9:0] BulletY [4:0],
                       input  logic [9:0] BulletX_2 [4:0], 
                       input  logic [9:0] BulletY_2 [4:0],
                       input  logic [2:0] TankDir,
                       input  logic [2:0] TankDir_2,
                       input  logic [4:0] Is_bullet_active,
                       input  logic [4:0] Is_bullet_active_2,
                       input  logic       TankDead,
                       input  logic       TankDead_2,
                       input  logic [2:0] game_state,
                       input  logic [3:0] SW,
                       input  logic [3:0] p1_score,
                       input  logic [3:0] p2_score,

                       input  logic clk,
                       input  logic reset,

                       input logic [9:0]  obs_left   [11 : 0],
                       input logic [9:0]  obs_right  [11 : 0],
                       input logic [8:0]  obs_top    [11 : 0],
                       input logic [8:0]  obs_bottom [11 : 0],
                       input logic [3:0]  wins,
                       
                       output logic [3:0]  Red, Green, Blue );
    
    logic down_on, down_on_2;
    logic up_on, up_on_2;
    logic bullet_on, bullet_on_2;

    logic obs_on = 1'b0;
	  
    int DistX, DistY, up_radius, barrel_width, barrel_height; // tank
    int DistX_2, DistY_2;
    assign DistX = DrawX - TankX;
    assign DistY = DrawY - TankY;
    assign DistX_2 = DrawX - TankX_2;
    assign DistY_2 = DrawY - TankY_2;
    assign up_radius = 8;
    assign barrel_width = 2;
    assign barrel_height = 15;

    int DistX_bullet [4:0]; 
    int DistY_bullet [4:0];

    int DistX_bullet_2 [4:0]; 
    int DistY_bullet_2 [4:0];

logic [15:0] turret_mask [0:15];            // Circle with radius of 8
initial begin
    turret_mask[ 0] = 16'b0000011111100000;
    turret_mask[ 1] = 16'b0001111111111000;
    turret_mask[ 2] = 16'b0011111111111100;
    turret_mask[ 3] = 16'b0111111111111110;
    turret_mask[ 4] = 16'b0111111111111110;
    turret_mask[ 5] = 16'b1111111111111111;
    turret_mask[ 6] = 16'b1111111111111111;
    turret_mask[ 7] = 16'b1111111111111111;
    turret_mask[ 8] = 16'b1111111111111111;
    turret_mask[ 9] = 16'b1111111111111111;
    turret_mask[10] = 16'b1111111111111111;
    turret_mask[11] = 16'b0111111111111110;
    turret_mask[12] = 16'b0111111111111110;
    turret_mask[13] = 16'b0011111111111100;
    turret_mask[14] = 16'b0001111111111000;
    turret_mask[15] = 16'b0000011111100000;
end

logic [3:0] bullet_mask [0:3];            // Circle with radius of 2
initial begin
    bullet_mask[ 0] = 4'b0110;
    bullet_mask[ 1] = 4'b1111;
    bullet_mask[ 2] = 4'b1111;
    bullet_mask[ 3] = 4'b0110;
end
    
//----------------------- bullet explosion -----------------------
    // -------------------- explosion for p1 -----------------------
    logic [4:0]                   expl_active;
    logic [4:0][4:0]              expl_timer;
    logic [9:0]                   expl_x   [4:0];
    logic [9:0]                   expl_y   [4:0];
    logic [4:0]                   prev_active;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_active  <= '0;
            expl_active  <= '0;
            expl_timer   <= '{default:5'd0};
        end else begin
            prev_active <= Is_bullet_active;    // capture current state

            for (int i = 0; i < 5; i++) begin
                if (prev_active[i] && !Is_bullet_active[i]) begin
                    expl_active[i] <= 1'b1;
                    expl_timer [i] <= 5'd19;
                    expl_x[i]      <= BulletX[i];
                    expl_y[i]      <= BulletY[i];
                end
                else if (expl_active[i]) begin
                    if (expl_timer[i] == 5'd0)
                        expl_active[i] <= 1'b0;
                    else
                        expl_timer [i] <= expl_timer[i] - 5'd1;
                end
            end
        end
    end

    logic explosion_on;
    logic [3:0] expl_R, expl_G, expl_B;
    int radius, dx, dy;

    always_comb begin
        explosion_on = 1'b0;
        expl_R = 4'h0; expl_G = 4'h0; expl_B = 4'h0;

        for (int i = 0; i < 5; i++) begin
            if (expl_active[i]) begin
                dx = DrawX - expl_x[i];
                dy = DrawY - expl_y[i];

                radius = (6'd20 - {1'b0, expl_timer[i]}); // 1 px bigger each frame
                if (dx*dx + dy*dy <= radius*radius) begin
                    explosion_on = 1'b1;
                    case (expl_timer[i])      // remaining frames
                        5'd15,5'd14,5'd13,5'd12,5'd11 : begin expl_R=4'hF; expl_G=4'h0; expl_B=4'h0; end // red
                        5'd10,5'd9 ,5'd8 ,5'd7 ,5'd6  : begin expl_R=4'hF; expl_G=4'h6; expl_B=4'h0; end // orange
                        5'd5 ,5'd4 ,5'd3 ,5'd2 ,5'd1  : begin expl_R=4'hF; expl_G=4'hF; expl_B=4'h0; end // yellow
                        default                       : begin expl_R=4'hF; expl_G=4'hF; expl_B=4'hF; end // white
                    endcase
                end
            end
        end
    end

    // -------------------- explosion for p2 -----------------------
    logic [4:0]        expl_active_2;
    logic [4:0][4:0]   expl_timer_2;
    logic [9:0]        expl_x_2   [4:0];
    logic [9:0]        expl_y_2   [4:0];
    logic [4:0]        prev_active_2;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_active_2 <= '0;
            expl_active_2 <= '0;
            expl_timer_2  <= '{default:5'd0};
        end else begin
            prev_active_2 <= Is_bullet_active_2;

            for (int i = 0; i < 5; i++) begin
                if (prev_active_2[i] && !Is_bullet_active_2[i]) begin
                    expl_active_2[i] <= 1'b1;
                    expl_timer_2[i]  <= 5'd19;  
                    expl_x_2[i]      <= BulletX_2[i];
                    expl_y_2[i]      <= BulletY_2[i];
                end
                else if (expl_active_2[i]) begin
                    if (expl_timer_2[i] == 5'd0)
                        expl_active_2[i] <= 1'b0; 
                    else
                        expl_timer_2[i]  <= expl_timer_2[i] - 5'd1;
                end
            end
        end
    end

    logic        explosion_on_2;
    logic [3:0]  expl_R_2, expl_G_2, expl_B_2;
    int          radius_2,  dx_2,      dy_2;

    always_comb begin
        explosion_on_2 = 1'b0;
        expl_R_2 = 4'h0;  expl_G_2 = 4'h0;  expl_B_2 = 4'h0;

        for (int i = 0; i < 5; i++) begin
            if (expl_active_2[i]) begin
                dx_2 = DrawX - expl_x_2[i];
                dy_2 = DrawY - expl_y_2[i];

                radius_2 = (6'd20 - {1'b0, expl_timer_2[i]});
                if (dx_2*dx_2 + dy_2*dy_2 <= radius_2*radius_2) begin
                    explosion_on_2 = 1'b1;

                    case (expl_timer_2[i])  
                        5'd15,5'd14,5'd13,5'd12,5'd11 : begin expl_R_2=4'hF; expl_G_2=4'h0; expl_B_2=4'h0; end // red
                        5'd10,5'd9 ,5'd8 ,5'd7 ,5'd6  : begin expl_R_2=4'hF; expl_G_2=4'h6; expl_B_2=4'h0; end // orange
                        5'd5 ,5'd4 ,5'd3 ,5'd2 ,5'd1  : begin expl_R_2=4'hF; expl_G_2=4'hF; expl_B_2=4'h0; end // yellow
                        default                       : begin expl_R_2=4'hF; expl_G_2=4'hF; expl_B_2=4'hF; end // white
                    endcase
                end
            end
        end
    end

//----------------------- tank render -----------------------    
    always_comb                         // draw tank lower square
    begin:down_lower_layer_tank
        if ((DistX >= -11 && DistX <= 11) && (DistY >= -11 && DistY <= 11))
            down_on = 1'b1;
        else 
            down_on = 1'b0;
    end 

    always_comb                         // draw tank_2 lower square
    begin:down_lower_layer_tank_2
        if ((DistX_2 >= -11 && DistX_2 <= 11) && (DistY_2 >= -11 && DistY_2 <= 11))
            down_on_2 = 1'b1;
        else 
            down_on_2 = 1'b0;
    end 

    always_comb 
    begin:up_layer                      // draw tank upper turret
        up_on = 1'b0;

        if ((DistX >= -8 && DistX < 8) && (DistY >= -8 && DistY < 8)) begin
            if (turret_mask[DistY + 8][DistX + 8])
                up_on = 1'b1;
        end

        else begin
            case (TankDir)
                3'b000: // Up
                    if ((DistY >= -15 && DistY <= 0) && (DistX >= -2 && DistX <= 2)) up_on = 1'b1;
                3'b001: // Down
                    if ((DistY <= 15 && DistY >= 0) && (DistX >= -2 && DistX <= 2)) up_on = 1'b1;
                3'b010: // Left
                    if ((DistX >= -15 && DistX <= 0) && (DistY >= -2 && DistY <= 2)) up_on = 1'b1;
                3'b011: // Right
                    if ((DistX <= 15 && DistX >= 0) && (DistY >= -2 && DistY <= 2)) up_on = 1'b1;
                default: ;
            endcase
        end
    end

    always_comb 
    begin:up_layer_2                      // draw tank_2 upper turret
        up_on_2 = 1'b0;

        if ((DistX_2 >= -8 && DistX_2 < 8) && (DistY_2 >= -8 && DistY_2 < 8)) begin
            if (turret_mask[DistY_2 + 8][DistX_2 + 8])
                up_on_2 = 1'b1;
        end

        else begin
            case (TankDir_2)
                3'b000: // Up
                    if ((DistY_2 >= -15 && DistY_2 <= 0) && (DistX_2 >= -2 && DistX_2 <= 2)) up_on_2 = 1'b1;
                3'b001: // Down
                    if ((DistY_2 <= 15 && DistY_2 >= 0) && (DistX_2 >= -2 && DistX_2 <= 2)) up_on_2 = 1'b1;
                3'b010: // Left
                    if ((DistX_2 >= -15 && DistX_2 <= 0) && (DistY_2 >= -2 && DistY_2 <= 2)) up_on_2 = 1'b1;
                3'b011: // Right
                    if ((DistX_2 <= 15 && DistX_2 >= 0) && (DistY_2 >= -2 && DistY_2 <= 2)) up_on_2 = 1'b1;
                default: ;
            endcase
        end
    end

    always_comb 
    begin: bullet                        // draw bullet
        bullet_on = 1'b0;
        for (int i = 0; i < 5; i++) begin
            if (Is_bullet_active[i]) begin
                DistX_bullet[i] = DrawX - BulletX[i];
                DistY_bullet[i] = DrawY - BulletY[i];
        
                if ((DistX_bullet[i] >= -2 && DistX_bullet[i] < 2) &&
                    (DistY_bullet[i] >= -2 && DistY_bullet[i] < 2)) begin
                    if (bullet_mask[DistY_bullet[i] + 2][DistX_bullet[i] + 2])
                        bullet_on = 1'b1;
                end
            end
        end
    end

    always_comb 
    begin: bullet_2                       // draw bullet_2
        bullet_on_2 = 1'b0;
        for (int i = 0; i < 5; i++) begin
            if (Is_bullet_active_2[i]) begin
                DistX_bullet_2[i] = DrawX - BulletX_2[i];
                DistY_bullet_2[i] = DrawY - BulletY_2[i];
        
                if ((DistX_bullet_2[i] >= -2 && DistX_bullet_2[i] < 2) &&
                    (DistY_bullet_2[i] >= -2 && DistY_bullet_2[i] < 2)) begin
                    if (bullet_mask[DistY_bullet_2[i] + 2][DistX_bullet_2[i] + 2])
                        bullet_on_2 = 1'b1;
                end
            end
        end
    end

    //--------------------- draw obstacles ---------------------------
    int i;

    always_comb begin
        obs_on = 1'b0;

        for (i = 0; i < 12; i++) begin
            if (DrawX >= obs_left[i] && DrawX <= obs_right[i] &&
                DrawY >= obs_top[i]  && DrawY <= obs_bottom[i]) begin
                obs_on = 1'b1;
            end
        end
    end
    //--------------------- font draw --------------------------
    logic [4:0] char_index;
    logic [3:0] font_row;
    logic [7:0] row_pixels;

    font_rom font_inst (
        .char_index(char_index),
        .row(font_row),
        .pixels(row_pixels)
    );

    parameter int CHAR_WIDTH  = 8;
    parameter int CHAR_HEIGHT = 16;
    
    //---------------- "TANK WAR" parameter -------------------
    parameter int TITLE_SCALE  = 5;
    parameter int TITLE_LENGTH  = 8;  // "TANK WAR"

    parameter int TITLE_WIDTH  = TITLE_LENGTH * CHAR_WIDTH * TITLE_SCALE;
    parameter int TITLE_HEIGHT = CHAR_HEIGHT * TITLE_SCALE;

    parameter int TITLE_X = (640 - TITLE_WIDTH) / 2;
    parameter int TITLE_Y = (480 - TITLE_HEIGHT) / 2; 

    int title_idx [0:7] = {0, 1, 2, 3, 25, 5, 1, 6};
    int rel_x_t, rel_y_t, char_col_t, x_in_char_t, y_in_char_t;


    //------------------ "BATTLE" parameter ----------------------
    parameter int BA_SCALE = 3;

    parameter int BA_LENGTH  = 10;  // "BATTLE  03"
    parameter int BA_WIDTH  = BA_LENGTH * CHAR_WIDTH * BA_SCALE;
    parameter int BA_HEIGHT = CHAR_HEIGHT * BA_SCALE;

    parameter int BA_X = (640 - BA_WIDTH ) / 2;
    parameter int BA_Y = (480 - BA_HEIGHT) / 2; 

    int ba_idx [0:9] = {7, 1, 0, 0, 12, 9, 25, 25, 4, 17}; // "BATTLE  03"
    int rel_x_ba, rel_y_ba, char_col_ba, x_in_char_ba, y_in_char_ba;

    always_comb begin
        case (SW)                                   // draw differen battles based on SW input
            4'b0001: // 5 games
                ba_idx = {7, 1, 0, 0, 12, 9, 25, 25, 4, 19};
            4'b0010: // 7 games
                ba_idx = {7, 1, 0, 0, 12, 9, 25, 25, 4, 21};
            4'b0100: // 9 games
                ba_idx = {7, 1, 0, 0, 12, 9, 25, 25, 4, 23};
            4'b1000: // 11 games
                ba_idx = {7, 1, 0, 0, 12, 9, 25, 25, 15, 15};
            default: // default to 3 games
                ba_idx = {7, 1, 0, 0, 12, 9, 25, 25, 4, 17};
        endcase
    end

    //------------------ "REFILL TIME" parameter ----------------
    parameter int RT_SCALE = 3;

    parameter int RT_LENGTH  = 15;  // "REFILL TIME"
    parameter int RT_WIDTH  = RT_LENGTH * CHAR_WIDTH * RT_SCALE;
    parameter int RT_HEIGHT = CHAR_HEIGHT * RT_SCALE;

    parameter int RT_X = (640 - RT_WIDTH ) / 2; 
    parameter int RT_Y = (480 - RT_HEIGHT) / 2; 

    int rt_idx [0:14] = {6, 9, 10, 11, 12, 12, 25, 0, 11, 24, 9, 24, 24, 15, 4}; // "REFILL TIME  10"
    int rel_x_rt, rel_y_rt, char_col_rt, x_in_char_rt, y_in_char_rt;

    always_comb begin
        case (SW)                                   // draw differen refill time based on SW input
            4'b0001: // 5s
                rt_idx = {6, 9, 10, 11, 12, 12, 25, 0, 11, 24, 9, 25, 25, 4, 19};
            4'b0010: // 10s
                rt_idx = {6, 9, 10, 11, 12, 12, 25, 0, 11, 24, 9, 25, 25, 15, 4};
            4'b0100: // 15s
                rt_idx = {6, 9, 10, 11, 12, 12, 25, 0, 11, 24, 9, 25, 25, 15, 19};
            4'b1000: // 20s
                rt_idx = {6, 9, 10, 11, 12, 12, 25, 0, 11, 24, 9, 25, 25, 16, 4};
            default: // default to 10s 
                rt_idx = {6, 9, 10, 11, 12, 12, 25, 0, 11, 24, 9, 25, 25, 15, 4};
        endcase
    end

    //------------------ "P1 WIN" parameter ---------------------
    parameter int WIN_SCALE = 5; 

    parameter int WIN_LENGTH  = 6;  // "P1 WIN"
    parameter int WIN_WIDTH  = WIN_LENGTH * CHAR_WIDTH * WIN_SCALE;
    parameter int WIN_HEIGHT = CHAR_HEIGHT * WIN_SCALE;

    parameter int WIN_X = (640 - WIN_WIDTH ) / 2;
    parameter int WIN_Y = (480 - WIN_HEIGHT) / 2; 

    int win_idx [0:5];

    always_comb begin
        if (TankDead) 
            win_idx = {8, 16, 25, 5, 11, 2};
        else if (TankDead_2) 
            win_idx = {8, 15, 25, 5, 11, 2};
    end
    
    int rel_x_win, rel_y_win, char_col_win, x_in_char_win, y_in_char_win;
    // -------------------- In Game SCORE BOARD ----------------------
    parameter int SB1_SCALE = 1; 

    parameter int SB1_LENGTH  = 4;  // "P1 X"
    parameter int SB1_WIDTH  = SB1_LENGTH * CHAR_WIDTH * SB1_SCALE;
    parameter int SB1_HEIGHT = CHAR_HEIGHT * SB1_SCALE;

    parameter int SB1_X = 0;  // upper-left corner
    parameter int SB1_Y = 0; 

    parameter int SB2_SCALE = 1; 

    parameter int SB2_LENGTH  = 4;  // "P1 X"
    parameter int SB2_WIDTH  = SB2_LENGTH * CHAR_WIDTH * SB2_SCALE;
    parameter int SB2_HEIGHT = CHAR_HEIGHT * SB2_SCALE;

    parameter int SB2_X = 640 - SB2_WIDTH;  // upper-right corner
    parameter int SB2_Y = 0; 

    int sb1_idx [0:3];
    int sb2_idx [0:3];

    parameter int WIN_N_SCALE = 1; 

    parameter int WIN_N_LENGTH  = 1;  // "X" Wins Need
    parameter int WIN_N_WIDTH  = WIN_N_LENGTH * CHAR_WIDTH * WIN_N_SCALE;
    parameter int WIN_N_HEIGHT = CHAR_HEIGHT * WIN_N_SCALE;

    parameter int WIN_N_X = (640 - (CHAR_WIDTH * WIN_N_SCALE)) / 2;  // first line middle
    parameter int WIN_N_Y = 0; 

    int win_n_idx;

    always_comb begin
        case(p1_score)
        4'd0: sb1_idx = {8, 15, 25, 4};
        4'd1: sb1_idx = {8, 15, 25, 15};
        4'd2: sb1_idx = {8, 15, 25, 16};
        4'd3: sb1_idx = {8, 15, 25, 17};
        4'd4: sb1_idx = {8, 15, 25, 18};
        4'd5: sb1_idx = {8, 15, 25, 19};
        4'd6: sb1_idx = {8, 15, 25, 20};
        endcase
        
        case(wins)
        4'd2: win_n_idx = 16;
        4'd3: win_n_idx = 17;
        4'd4: win_n_idx = 18;
        4'd5: win_n_idx = 19;
        4'd6: win_n_idx = 20;
        endcase

        case(p2_score)
        4'd0: sb2_idx = {8, 16, 25, 4};
        4'd1: sb2_idx = {8, 16, 25, 15};
        4'd2: sb2_idx = {8, 16, 25, 16};
        4'd3: sb2_idx = {8, 16, 25, 17};
        4'd4: sb2_idx = {8, 16, 25, 18};
        4'd5: sb2_idx = {8, 16, 25, 19};
        4'd6: sb2_idx = {8, 16, 25, 20};
        endcase
    end
    
    int rel_x_sb1, rel_y_sb1, char_col_sb1, x_in_char_sb1, y_in_char_sb1;
    int rel_x_sb2, rel_y_sb2, char_col_sb2, x_in_char_sb2, y_in_char_sb2;
    int rel_x_win_n, rel_y_win_n, char_col_win_n, x_in_char_win_n, y_in_char_win_n;
//------------------- RGB Output ----------------------------
    //------------------ title alterbating color -------------------
        logic [7:0] frame_counter;  // 8 bits for 120 frames (2 sec at 60Hz)
        logic title_color_phase;
        
        always_ff @(posedge clk or posedge reset) begin
            if (reset) begin
                frame_counter <= 0;
                title_color_phase <= 0;
            end else begin
                if (frame_counter == 8'd119) begin  // 120 frames = 2 sec at 60Hz
                    frame_counter <= 0;
                    title_color_phase <= ~title_color_phase;
                end else begin
                    frame_counter <= frame_counter + 1;
                end
            end
        end
        
    always_comb
    begin:RGB_Display
        case (game_state)
            3'd0: begin             // Start Screen
                Red   = 4'h0;
                Green = 4'h0;
                Blue  = 4'h0;

                if (DrawX >= TITLE_X && DrawX < TITLE_X + TITLE_WIDTH &&
                    DrawY >= TITLE_Y && DrawY < TITLE_Y + TITLE_HEIGHT) begin

                    rel_x_t = DrawX - TITLE_X;
                    rel_y_t = DrawY - TITLE_Y;

                    char_col_t = rel_x_t / (CHAR_WIDTH * TITLE_SCALE);
                    x_in_char_t = (rel_x_t / TITLE_SCALE) % CHAR_WIDTH;
                    y_in_char_t = (rel_y_t / TITLE_SCALE) % CHAR_HEIGHT;

                    char_index = title_idx[char_col_t];
                    font_row   = y_in_char_t;

                    if (row_pixels[7 - x_in_char_t]) begin  // left to right
                        if (title_color_phase) begin
                            Red   = 4'hF;  // Red phase
                            Green = 4'h0;
                            Blue  = 4'h0;
                        end else begin
                            Red   = 4'h0;  // Blue phase
                            Green = 4'h0;
                            Blue  = 4'hF;
                        end
                    end
                end
            end
            // --------------------- SET BALLTES ------------------------------
            3'd1: begin             
                Red   = 4'h0;
                Green = 4'h0;
                Blue  = 4'h0;

                if (DrawX >= BA_X && DrawX < BA_X + BA_WIDTH &&
                    DrawY >= BA_Y && DrawY < BA_Y + BA_HEIGHT) begin

                    rel_x_ba = DrawX - BA_X;
                    rel_y_ba = DrawY - BA_Y;

                    char_col_ba = rel_x_ba / (CHAR_WIDTH * BA_SCALE);
                    x_in_char_ba = (rel_x_ba / BA_SCALE) % CHAR_WIDTH;
                    y_in_char_ba = (rel_y_ba / BA_SCALE) % CHAR_HEIGHT;

                    char_index = ba_idx[char_col_ba];
                    font_row   = y_in_char_ba;

                    if (row_pixels[7 - x_in_char_ba]) begin  // left to right
                        Red = 4'hF;
                        Green = 4'hF;
                        Blue = 4'hF;  // white font
                    end
                end
            end
            // --------------------- SET REFILL TIME ------------------------------
            3'd2: begin             
                Red   = 4'h0;
                Green = 4'h0;
                Blue  = 4'h0;

                char_index = 0; 
                font_row   = 0;

                if (DrawX >= RT_X && DrawX < RT_X + RT_WIDTH &&
                    DrawY >= RT_Y && DrawY < RT_Y + RT_HEIGHT) begin

                    rel_x_rt = DrawX - RT_X;
                    rel_y_rt = DrawY - RT_Y;

                    char_col_rt = rel_x_rt / (CHAR_WIDTH * RT_SCALE);
                    x_in_char_rt = (rel_x_rt / RT_SCALE) % CHAR_WIDTH;
                    y_in_char_rt = (rel_y_rt / RT_SCALE) % CHAR_HEIGHT;

                    char_index = rt_idx[char_col_rt];
                    font_row   = y_in_char_rt;

                    if (row_pixels[7 - x_in_char_rt]) begin  // left to right
                        Red = 4'hF;
                        Green = 4'hF;
                        Blue = 4'hF;  // white font
                    end
                end
            end
            // ------------------------------------ IN GAME ---------------------------------------
            3'd3: begin
                // -------------------------------- Score Board Display ---------------------------
                if (DrawY < 16) begin
                    Red   = 4'h0;
                    Green = 4'h0;
                    Blue  = 4'h0;
                    
                    if (DrawX >= SB1_X && DrawX < SB1_X + SB1_WIDTH &&
                        DrawY >= SB1_Y && DrawY < SB1_Y + SB1_HEIGHT) begin

                        rel_x_sb1 = DrawX - SB1_X;
                        rel_y_sb1 = DrawY - SB1_Y;

                        char_col_sb1 = rel_x_sb1 / (CHAR_WIDTH * SB1_SCALE);
                        x_in_char_sb1 = (rel_x_sb1 / SB1_SCALE) % CHAR_WIDTH;
                        y_in_char_sb1 = (rel_y_sb1 / SB1_SCALE) % CHAR_HEIGHT;

                        char_index = sb1_idx[char_col_sb1];
                        font_row   = y_in_char_sb1;

                        if (row_pixels[7 - x_in_char_sb1]) begin  // left to right
                            Red = 4'h0;
                            Green = 4'h0;
                            Blue = 4'hF;  // white font
                        end
                    end

                    if (DrawX >= SB2_X && DrawX < SB2_X + SB2_WIDTH &&
                        DrawY >= SB2_Y && DrawY < SB2_Y + SB2_HEIGHT) begin

                        rel_x_sb2 = DrawX - SB2_X;
                        rel_y_sb2 = DrawY - SB2_Y;

                        char_col_sb2 = rel_x_sb2 / (CHAR_WIDTH * SB2_SCALE);
                        x_in_char_sb2 = (rel_x_sb2 / SB2_SCALE) % CHAR_WIDTH;
                        y_in_char_sb2 = (rel_y_sb2 / SB2_SCALE) % CHAR_HEIGHT;

                        char_index = sb2_idx[char_col_sb2];
                        font_row   = y_in_char_sb2;

                        if (row_pixels[7 - x_in_char_sb2]) begin  // left to right
                            Red = 4'hF;
                            Green = 4'h0;
                            Blue = 4'h0;  // white font
                        end
                    end

                    if (DrawX >= WIN_N_X && DrawX < WIN_N_X + WIN_N_WIDTH &&
                        DrawY >= WIN_N_Y && DrawY < WIN_N_Y + WIN_N_HEIGHT) begin

                        rel_x_win_n = DrawX - WIN_N_X;
                        rel_y_win_n = DrawY - WIN_N_Y;

                        char_col_win_n = rel_x_win_n / (CHAR_WIDTH * WIN_N_SCALE);
                        x_in_char_win_n = (rel_x_win_n / WIN_N_SCALE) % CHAR_WIDTH;
                        y_in_char_win_n = (rel_y_win_n / WIN_N_SCALE) % CHAR_HEIGHT;

                        char_index = win_n_idx;
                        font_row   = y_in_char_win_n;

                        if (row_pixels[7 - x_in_char_win_n]) begin  // left to right
                            Red = 4'hF;
                            Green = 4'hF;
                            Blue = 4'hF;  // white font
                        end
                    end
                // ------------------------------ BattleField Graphics ---------------------------
                end else begin 
                    if (explosion_on) begin
                        Red   = expl_R;
                        Green = expl_G;
                        Blue  = expl_B;
                    end else if (explosion_on_2) begin
                        Red   = expl_R_2;
                        Green = expl_G_2;
                        Blue  = expl_B_2;   
                    end else if (TankDead == 1'b0 && down_on == 1'b1 && up_on == 1'b0) begin  // Green Lower Layer of Tank (0, f, 0)
                        Red   = 4'h0;
                        Green = 4'h0;
                        Blue  = 4'hF;
                    end else if (TankDead == 1'b0 && up_on == 1'b1) begin   // Upper Layer of Tank
                        Red   = 4'h0;
                        Green = 4'h0;
                        Blue  = 4'h8;
                    end else if (TankDead_2 == 1'b0 && down_on_2 == 1'b1 && up_on_2 == 1'b0) begin // Tank 2 lower
                        Red   = 4'hF;
                        Green = 4'h0;
                        Blue  = 4'h0;
                    end else if (TankDead_2 == 1'b0 && up_on_2 == 1'b1) begin // Tank 2 upper
                        Red   = 4'h8;
                        Green = 4'h0;
                        Blue  = 4'h0;
                    end else if (bullet_on == 1'b1) begin // bullet (blue)
                        Red   = 4'h0;
                        Green = 4'hF;
                        Blue  = 4'h0;
                    end else if (bullet_on_2 == 1'b1) begin // Bullet 2 (yellow)
                        Red   = 4'hF;
                        Green = 4'hF;
                        Blue  = 4'h0;
                    end 
                    else if (obs_on == 1'b1) begin
                        Red   = 4'h4;                      // grey obstalces
                        Green = 4'h4;
                        Blue  = 4'h4;
                    end 
                    else begin                     // Sand Background
                        Red   = 4'hC; 
                        Green = 4'hB;
                        Blue  = 4'h8;    
                    end
                end
            end
            // ----------------------------- END SCREEN -----------------------------------------
            3'd5: begin
                Red   = 4'h0;
                Green = 4'h0;
                Blue  = 4'h0;

                if (DrawX >= WIN_X && DrawX < WIN_X + WIN_WIDTH &&
                    DrawY >= WIN_Y && DrawY < WIN_Y + WIN_HEIGHT) begin

                    rel_x_win = DrawX - WIN_X;
                    rel_y_win = DrawY - WIN_Y;

                    char_col_win = rel_x_win / (CHAR_WIDTH * WIN_SCALE);
                    x_in_char_win = (rel_x_win / WIN_SCALE) % CHAR_WIDTH;
                    y_in_char_win = (rel_y_win / WIN_SCALE) % CHAR_HEIGHT;

                    char_index = win_idx[char_col_win];
                    font_row   = y_in_char_win;

                    if (row_pixels[7 - x_in_char_win]) begin  // left to right
                        Red = 4'hF;
                        Green = 4'hF;
                        Blue = 4'hF;  // white font
                    end
                end
            end
            // -------------------- test CHECK_SCORE STAGE (Green) ---------------------------
            3'd4: begin                 
                Red   = 4'h0;
                Green = 4'hf;
                Blue  = 4'h0;
            end
        endcase      
    end 
endmodule
