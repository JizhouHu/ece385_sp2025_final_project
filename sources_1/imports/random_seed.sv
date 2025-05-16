// module counter(
//     input logic frame_clk,
//     input logic Reset,
    
//     input logic [31:0] keycode,
//     input logic         relife,
//     input logic [2:0]   game_state,
//     input logic [3:0]   SW,

//     output logic [1:0] seed_1,
//     output logic [1:0] seed_2,
//     output logic [15:0] key_counter
// );

// logic [31:0] game_timer;
// logic [31:0] prev_keycode;

// always_ff @(posedge frame_clk or posedge Reset) begin
//     if (Reset || relife)
//         game_timer <= 0;
//     else if (game_state == 3'd3)
//         game_timer <= game_timer + 1;
// end

// always_ff @(posedge frame_clk or posedge Reset) begin
//     if (Reset || relife) begin
//         key_counter   <= 16'd0;
//         prev_keycode  <= 32'd0;
//     end
//     else begin
//         if (keycode != 32'd0 && prev_keycode != keycode) begin
//             key_counter <= key_counter + 1;
//         end
//         prev_keycode <= keycode;
//     end
// end

// always_ff @(posedge frame_clk or posedge Reset) begin
//     if (Reset) begin
//         seed_1 <= SW[1:0];
//         seed_2 <= SW[3:2];
//     end
//     else if (relife)
//     begin
//         seed_1 <= game_timer[1:0] ^ game_timer[3:2] ^ game_timer[5:4];
//         seed_2 <= key_counter[1:0] ^ key_counter[3:2] ^ key_counter[5:4];
//     end
// end

// endmodule

module counter (
    input  logic        frame_clk,
    input  logic        Reset,
    input  logic [31:0] keycode,
    input  logic        relife,
    input  logic [2:0]  game_state,
    input  logic [3:0]  SW,

    output logic [1:0]  seed_1,
    output logic [1:0]  seed_2,
    output logic [15:0] key_counter
);

    logic [31:0] game_timer;
    logic [31:0] prev_keycode;
    logic        seed_latched;

    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset || relife)
            game_timer <= 0;
        else if (game_state == 3'd3)
            game_timer <= game_timer + 1;
    end

    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset || relife) begin
            key_counter   <= 16'd0;
            prev_keycode  <= 32'd0;
        end else begin
            if (keycode != 32'd0 && prev_keycode != keycode)
                key_counter <= key_counter + 1;

            prev_keycode <= keycode;
        end
    end

    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset) begin
            seed_1       <= SW[1:0];
            seed_2       <= SW[3:2];
            seed_latched <= 1'b0;
        end else if (relife && !seed_latched) begin
            seed_1       <= game_timer[1:0] ^ game_timer[3:2] ^ game_timer[5:4];
            seed_2       <= key_counter[1:0] ^ key_counter[3:2] ^ key_counter[5:4];
            seed_latched <= 1'b1;
        end else if (!relife) begin
            seed_latched <= 1'b0;
        end
    end

endmodule
