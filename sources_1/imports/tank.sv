module tank
(
	input  logic    	Reset,
	input  logic    	frame_clk,
	input  logic [31:0] keycode,

	input  logic [9:0]	TankX_other,
	input  logic [9:0]	TankY_other,

	input  logic [9:0] 	BulletX [4:0],
	input  logic [9:0] 	BulletY [4:0],
	//input  logic [3:0]  BulletAge [4:0],
	input  logic [4:0] 	Is_bullet_active,

	input  logic [9:0] 	BulletX_2 [4:0],
	input  logic [9:0] 	BulletY_2 [4:0],
	//input  logic [3:0]	BulletAge_2 [4:0],
	input  logic [4:0] 	Is_bullet_active_2,

	input  logic relife,

	input logic [9:0]  obs_left   [11:0],
	input logic [9:0]  obs_right  [11:0],
	input logic [8:0]  obs_top    [11:0],
	input logic [8:0]  obs_bottom [11:0],

	input [1:0] random_seed,

	output logic [9:0]  TankX,
	output logic [9:0]  TankY,
	output logic [9:0]  TankS,
	output logic [2:0]  TankDir, // for 8 direction (up down left right 000->011)
	output logic        TankDead, // 1 means tank is dead
	output logic        shoot_en
);
    
	logic [9:0] Tank_X_Center;		// start position
	logic [9:0] Tank_Y_Center; 
	parameter [9:0] Tank_X_Min=0;   	// Leftmost point on the X axis
	parameter [9:0] Tank_X_Max=639; 	// Rightmost point on the X axis
	parameter [9:0] Tank_Y_Min=16;   	// Topmost point on the Y axis
	parameter [9:0] Tank_Y_Max=479; 	// Bottommost point on the Y axis
	parameter [9:0] Tank_X_Step=2;  	// Step size on the X axis
	parameter [9:0] Tank_Y_Step=2;  	// Step size on the Y axis

	logic [9:0] Tank_X_Motion;
	logic [9:0] Tank_X_Motion_next;
	logic [9:0] Tank_Y_Motion;
	logic [9:0] Tank_Y_Motion_next;

	logic [9:0] Tank_X_next;
	logic [9:0] Tank_Y_next;

	logic [7:0] keycode_dir;

	//------------------- function for obs detection -----------------
    function logic tank_hits_obstacle(
        input logic [9:0] TankX,
        input logic [9:0] TankY,
        input logic [9:0] TankS,
        input logic [9:0] obs_left   [0:11],
        input logic [9:0] obs_right  [0:11],
        input logic [8:0] obs_top    [0:11],
        input logic [8:0] obs_bottom [0:11]
    );
        for (int i = 0; i < 12; i++) begin
            if (!(TankX + TankS <= obs_left[i] || TankX - TankS >= obs_right[i] ||
                  TankY + TankS <= obs_top[i]  || TankY - TankS >= obs_bottom[i])) begin
                return 1'b1;
            end
        end
        return 1'b0;
    endfunction

	//-------------------- start position random ------------------------
	always_ff @(posedge frame_clk or posedge Reset or posedge relife) begin
		if (Reset || relife) begin
			case (random_seed)
				2'b00: begin
					Tank_X_Center <= 10'd30;
					Tank_Y_Center <= 10'd30;
				end

				2'b01: begin
					Tank_X_Center <= 10'd30;
					Tank_Y_Center <= 10'd240;
				end

				2'b10: begin
					Tank_X_Center <= 10'd30;
					Tank_Y_Center <= 10'd450;
				end

				2'b11: begin
					Tank_X_Center <= 10'd320;
					Tank_Y_Center <= 10'd450;
				end

				default: begin
					Tank_X_Center <= 10'd30;
					Tank_Y_Center <= 10'd30;
				end
			endcase
		end
	end
    //--------------------- tank should not shoot when facing towards boundary/obs -----------
    localparam BULLET_RADIUS = 2;
    localparam SHOOT_OFFSET = 20;
    logic [9:0] bullet_x_next;
    logic [9:0] bullet_y_next;

    always_comb begin
        shoot_en = 1'b1;  // Default
    
        // Boundary check
        case (TankDir)
            3'b000: if (TankY - TankS <= Tank_Y_Min + 3) shoot_en = 1'b0; // Up
            3'b001: if (TankY + TankS >= Tank_Y_Max - 3) shoot_en = 1'b0; // Down
            3'b010: if (TankX - TankS <= Tank_X_Min + 3) shoot_en = 1'b0; // Left
            3'b011: if (TankX + TankS >= Tank_X_Max - 3) shoot_en = 1'b0; // Right
            default: ;
        endcase
    
        // Predict bullet spawn location
        bullet_x_next = TankX;
        bullet_y_next = TankY;
        case (TankDir)
            3'b000: bullet_y_next = TankY - SHOOT_OFFSET; // Up
            3'b001: bullet_y_next = TankY + SHOOT_OFFSET; // Down
            3'b010: bullet_x_next = TankX - SHOOT_OFFSET; // Left
            3'b011: bullet_x_next = TankX + SHOOT_OFFSET; // Right
            default: ;
        endcase
    
        // Obstacle check
        if (tank_hits_obstacle(bullet_x_next, bullet_y_next, BULLET_RADIUS, obs_left, obs_right, obs_top, obs_bottom))
            shoot_en = 1'b0;
    end

	//---------------------------- up: 0; down: 1; left: 2; right: 3 -----------------------------
	always_ff @(posedge frame_clk or posedge Reset or posedge relife) begin
		if (Reset || relife) begin
			TankDir <= 3'b011; // right as default
		end
		else begin
			case(keycode_dir)
			8'h1A : begin
				TankDir <= 3'b000; //W
			end
			8'h16: begin
				TankDir <= 3'b001; //S
			end
			8'h04: begin
				TankDir <= 3'b010; //A
			end
			8'h07: begin
				TankDir <= 3'b011; //D
			end
			default:
				TankDir <= TankDir;
			endcase
		end
	end

	always_comb begin					// extract direction key from keycode
		keycode_dir = 8'h00;
		if ((keycode[7:0] == 8'h1A) || (keycode[7:0] == 8'h16) || (keycode[7:0] == 8'h04) || (keycode[7:0] == 8'h07))
			keycode_dir = keycode[7:0];
		else if ((keycode[15:8] == 8'h1A) || (keycode[15:8] == 8'h16) || (keycode[15:8] == 8'h04) || (keycode[15:8] == 8'h07))
			keycode_dir = keycode[15:8];
		else if ((keycode[23:16] == 8'h1A) || (keycode[23:16] == 8'h16) || (keycode[23:16] == 8'h04) || (keycode[23:16] == 8'h07))
			keycode_dir = keycode[23:16];
		else if ((keycode[31:24] == 8'h1A) || (keycode[31:24] == 8'h16) || (keycode[31:24] == 8'h04) || (keycode[31:24] == 8'h07))
			keycode_dir = keycode[31:24];
	end

	always_comb begin
    	Tank_X_Motion_next = 10'd0; // default: no movement
    	Tank_Y_Motion_next = 10'd0;

    	//modify to control tank motion with the keycode
    	case (keycode_dir)
        	8'h1A: begin // W
            	Tank_Y_Motion_next = -Tank_Y_Step;
            	Tank_X_Motion_next = 10'd0;
        	end
        	8'h16: begin // S
            	Tank_Y_Motion_next = Tank_Y_Step;
            	Tank_X_Motion_next = 10'd0;
        	end
        	8'h04: begin // A
            	Tank_X_Motion_next = -Tank_X_Step;
            	Tank_Y_Motion_next = 10'd0;
        	end
        	8'h07: begin // D
            	Tank_X_Motion_next = Tank_X_Step;
            	Tank_Y_Motion_next = 10'd0;
        	end
        	default : begin
            	// no movement
        	end
    	endcase


    	if ( keycode_dir == 8'h16 && (TankY + TankS) >= Tank_Y_Max )  // Tank is at the bottom edge
    	begin
        	Tank_Y_Motion_next = 10'd0;
    	end
    	else if ( keycode_dir == 8'h1A && (TankY - TankS) <= Tank_Y_Min )  // Tank is at the top edge
    	begin
        	Tank_Y_Motion_next = 10'd0;
    	end  
    	if (keycode_dir == 8'h07 && (TankX + TankS) >= Tank_X_Max) begin
        	Tank_X_Motion_next = 10'd0;  // Right edge
    	end
    	else if (keycode_dir == 8'h04 && (TankX - TankS) <= Tank_X_Min) begin
        	Tank_X_Motion_next = 10'd0;   // Left edge
    	end  

	end

	assign TankS = 16;  // default tank size
	assign Tank_X_next = (TankX + Tank_X_Motion_next);
	assign Tank_Y_next = (TankY + Tank_Y_Motion_next);
   
	always_ff @(posedge frame_clk or posedge Reset or posedge relife) //make sure the frame clock is instantiated correctly
	begin: Move_Tank
    	if (Reset || relife) begin
        	Tank_Y_Motion <= 10'd0; //Tank_Y_Step;
        	Tank_X_Motion <= 10'd0; //Tank_X_Step;
       	 
        	TankY <= Tank_Y_Center;
        	TankX <= Tank_X_Center;
    	end else begin
        	Tank_Y_Motion <= Tank_Y_Motion_next;
        	Tank_X_Motion <= Tank_X_Motion_next;

			if (
				((Tank_X_next + TankS <= TankX_other - TankS) ||  		// tanks overlap detection
				 (Tank_X_next - TankS >= TankX_other + TankS) ||
				 (Tank_Y_next + TankS <= TankY_other - TankS) || 
				 (Tank_Y_next - TankS >= TankY_other + TankS)) &&		// obs overlap detection
				 (!tank_hits_obstacle(Tank_X_next, Tank_Y_next, TankS, obs_left, obs_right, obs_top, obs_bottom)) 
			) begin
				TankX <= Tank_X_next;
				TankY <= Tank_Y_next;
			end else begin
				TankX <= TankX; // stay
				TankY <= TankY; // stay
			end
    	end  
	end

    always_ff @(posedge frame_clk or posedge Reset or posedge relife)				// bullet detection
    begin: Bullet_detection
        if (Reset || relife) begin
            TankDead <= 1'b0;
        end else begin
            if (TankDead == 1'b0) begin // Only check if tank is still alive
                for (int i = 0; i < 5; i++) begin
                    if (Is_bullet_active[i]) begin
                        if (!((BulletX[i] + 2 <= TankX - TankS) || (BulletX[i] - 2 >= TankX + TankS) ||
                            (BulletY[i] + 2 <= TankY - TankS) || (BulletY[i] - 2 >= TankY + TankS))) begin
                            TankDead <= 1'b1;
                        end
                    end
                end

                for (int i = 0; i < 5; i++) begin
                    if (Is_bullet_active_2[i]) begin
                        if (!((BulletX_2[i] + 2 <= TankX - TankS) || (BulletX_2[i] - 2 >= TankX + TankS) ||
                            (BulletY_2[i] + 2 <= TankY - TankS) || (BulletY_2[i] - 2 >= TankY + TankS))) begin
                            TankDead <= 1'b1;
                        end
                    end
                end
            end
        end
    end
	 
endmodule
