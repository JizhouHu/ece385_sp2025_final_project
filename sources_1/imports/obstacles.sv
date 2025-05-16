module obstacles
#(
    localparam int NUM_OBS = 12,
    localparam int SCR_W   = 640,
    localparam int SCR_H   = 480
)
(   
    input logic [1:0] random_seed,

    output logic [9:0] obs_left   [0:NUM_OBS-1],
    output logic [9:0] obs_right  [0:NUM_OBS-1],
    output logic [8:0] obs_top    [0:NUM_OBS-1],
    output logic [8:0] obs_bottom [0:NUM_OBS-1]
);

    always_comb begin
        unique case(random_seed)
            2'b00: begin
                obs_left[0]   =  50; obs_top[0]    =  50; obs_right[0]  =  80; obs_bottom[0] =  90;
                obs_left[1]   = 120; obs_top[1]    = 200; obs_right[1]  = 170; obs_bottom[1] = 240;
                obs_left[2]   = 200; obs_top[2]    = 100; obs_right[2]  = 250; obs_bottom[2] = 150;
                obs_left[3]   = 300; obs_top[3]    =  60; obs_right[3]  = 360; obs_bottom[3] = 110;
                obs_left[4]   = 400; obs_top[4]    = 180; obs_right[4]  = 450; obs_bottom[4] = 230;
                obs_left[5]   = 500; obs_top[5]    =  40; obs_right[5]  = 550; obs_bottom[5] = 100;
                obs_left[6]   =  60; obs_top[6]    = 300; obs_right[6]  = 100; obs_bottom[6] = 350;
                obs_left[7]   = 150; obs_top[7]    = 360; obs_right[7]  = 210; obs_bottom[7] = 410;
                obs_left[8]   = 270; obs_top[8]    = 320; obs_right[8]  = 330; obs_bottom[8] = 370;
                obs_left[9]   = 400; obs_top[9]    = 300; obs_right[9]  = 450; obs_bottom[9] = 350;
                obs_left[10]  = 470; obs_top[10]   = 370; obs_right[10] = 520; obs_bottom[10]= 420;
                obs_left[11]  = 550; obs_top[11]   = 250; obs_right[11] = 600; obs_bottom[11]= 300;
            end
            
            2'b01: begin
                obs_left[0]   =  80; obs_top[0]    =  160; obs_right[0]  =  120; obs_bottom[0] =  240;
                obs_left[1]   =  80; obs_top[1]    = 240; obs_right[1]  = 120; obs_bottom[1] = 320;
                obs_left[2]   = 120; obs_top[2]    = 220; obs_right[2]  = 200; obs_bottom[2] = 260;
                obs_left[3]   = 220; obs_top[3]    =  60; obs_right[3]  = 300; obs_bottom[3] = 100;
                obs_left[4]   = 300; obs_top[4]    = 60; obs_right[4]  = 380; obs_bottom[4] = 100;
                obs_left[5]   = 280; obs_top[5]    =  100; obs_right[5]  = 320; obs_bottom[5] = 180;
                obs_left[6]   =  280; obs_top[6]    = 300; obs_right[6]  = 320; obs_bottom[6] = 380;
                obs_left[7]   = 220; obs_top[7]    = 380; obs_right[7]  = 300; obs_bottom[7] = 420;
                obs_left[8]   = 300; obs_top[8]    = 380; obs_right[8]  = 380; obs_bottom[8] = 420;
                obs_left[9]   = 400; obs_top[9]    = 220; obs_right[9]  = 480; obs_bottom[9] = 260;
                obs_left[10]  = 480; obs_top[10]   = 160; obs_right[10] = 520; obs_bottom[10]= 240;
                obs_left[11]  = 480; obs_top[11]   = 240; obs_right[11] = 520; obs_bottom[11]= 320;//map2
            end

            2'b10: begin
                obs_left[0]   =  120; obs_top[0]    =  60; obs_right[0]  =  140; obs_bottom[0] =  160;
                obs_left[1]   =  140; obs_top[1]    = 60; obs_right[1]  = 380; obs_bottom[1] = 80;
                obs_left[2]   = 260; obs_top[2]    = 120; obs_right[2]  = 280; obs_bottom[2] = 200;
                obs_left[3]   = 40; obs_top[3]    =  200; obs_right[3]  = 280; obs_bottom[3] = 220;
                obs_left[4]   = 320; obs_top[4]    = 140; obs_right[4]  = 340; obs_bottom[4] = 260;
                obs_left[5]   = 420; obs_top[5]    =  180; obs_right[5]  = 520; obs_bottom[5] = 200;
                obs_left[6]   =  180; obs_top[6]    = 260; obs_right[6]  = 460; obs_bottom[6] = 280;
                obs_left[7]   = 500; obs_top[7]    = 180; obs_right[7]  = 520; obs_bottom[7] = 360;
                obs_left[8]   = 120; obs_top[8]    = 260; obs_right[8]  = 140; obs_bottom[8] = 340;
                obs_left[9]   = 120; obs_top[9]    = 340; obs_right[9]  = 340; obs_bottom[9] = 360;
                obs_left[10]  = 400; obs_top[10]   = 340; obs_right[10] = 420; obs_bottom[10]= 400;
                obs_left[11]  = 260; obs_top[11]   = 400; obs_right[11] = 520; obs_bottom[11]= 420;//map3
            end
            
            2'b11: begin
                obs_left[0]   =  120; obs_top[0]    =  60; obs_right[0]  =  160; obs_bottom[0] =  200;
                obs_left[1]   =  160; obs_top[1]    = 60; obs_right[1]  = 260; obs_bottom[1] = 100;
                obs_left[2]   = 360; obs_top[2]    = 60; obs_right[2]  = 460; obs_bottom[2] = 100;
                obs_left[3]   = 460; obs_top[3]    =  60; obs_right[3]  = 500; obs_bottom[3] = 200;
                obs_left[4]   = 260; obs_top[4]    = 140; obs_right[4]  = 360; obs_bottom[4] = 160;
                obs_left[5]   = 200; obs_top[5]    =  200; obs_right[5]  = 220; obs_bottom[5] = 280;
                obs_left[6]   =  400; obs_top[6]    = 200; obs_right[6]  = 420; obs_bottom[6] = 280;
                obs_left[7]   = 260; obs_top[7]    = 320; obs_right[7]  = 360; obs_bottom[7] = 340;
                obs_left[8]   = 120; obs_top[8]    = 280; obs_right[8]  = 160; obs_bottom[8] = 420;
                obs_left[9]   = 160; obs_top[9]    = 380; obs_right[9]  = 260; obs_bottom[9] = 420;
                obs_left[10]  = 360; obs_top[10]   = 380; obs_right[10] = 460; obs_bottom[10]= 420;
                obs_left[11]  = 460; obs_top[11]   = 280; obs_right[11] = 500; obs_bottom[11]= 420;//map4
            end
        endcase
    end
    
endmodule