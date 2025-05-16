//-------------------------------------------------------------------------
//    mb_usb_hdmi_top.sv                                                 --
//    Zuofu Cheng                                                        --
//    2-29-24                                                            --
//                                                                       --
//                                                                       --
//    Spring 2024 Distribution                                           --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module mb_usb_hdmi_top(
    input logic Clk,
    input logic reset_rtl_0,    // BTN0
    input logic [3:0] SW,
    input logic CONT,           // BTN1
    
    //USB signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,
        
    //HEX displays
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB
);
    
    logic [31:0] keycode0_gpio, keycode1_gpio;
    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah;

    logic [3:0] p1_score;
    logic [3:0] p2_score;
    logic [3:0] wins;
    
    assign reset_ah = reset_rtl_0;
    
    hex_driver HexA (
        .clk(Clk),
        .reset(reset_ah),
        .in({key_counter[7:4], key_counter[3:0], p1_score, p2_score}),
        .hex_seg(hex_segA),
        .hex_grid(hex_gridA)
    );

    hex_driver HexB (
        .clk(Clk),
        .reset(reset_ah),
        .in({keycode0_gpio[15:12], keycode0_gpio[11:8], keycode0_gpio[7:4], keycode0_gpio[3:0]}),
        .hex_seg(hex_segB),
        .hex_grid(hex_gridB)
    );

    logic [3:0] SW_S;
    logic CONT_S, CONT_En;

    sync_debounce SW_sync [3:0] (
        .clk(Clk),
        .d(SW),
        .q(SW_S)
    );

    sync_debounce BTN_sync (
        .clk(Clk),
        .d(CONT),
        .q(CONT_S)
    );

    negedge_detector Cont_B (
        .clk(Clk),
        .in(CONT_S),
        .out(CONT_En)
    );
    
    mb_usb mb_block_i (
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_ah), //Block designs expect active low reset, all other modules are active high
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );

    logic [2:0] tankdirsig;
    logic [2:0] tankdirsig_2;
    logic [9:0] tankxsig, tankysig, tanksizesig;
    logic [9:0] tankxsig_2, tankysig_2, tanksizesig_2;
    logic       tankdead;
    logic       tankdead_2;
    
    logic [9:0] bulletxsig [4:0]; 
    logic [9:0] bulletysig [4:0];
    logic [4:0] bullet_active;
    logic [9:0] bulletxsig_2 [4:0]; 
    logic [9:0] bulletysig_2 [4:0];
    logic [4:0] bullet_active_2;
    // logic [3:0] bullet_age [4:0];
    // logic [3:0] bullet_age_2 [4:0];
    logic [2:0] game_state_sig;
    logic relife;
    
    logic [9:0]  obs_left   [11:0];
    logic [9:0]  obs_right  [11:0];
    logic [8:0]  obs_top    [11:0];
    logic [8:0]  obs_bottom [11:0];
    
    logic shoot_en, shoot_en_2;

    logic [1:0] seed_1, seed_2;
    logic [15:0] key_counter;

    counter Random_Gen(
        .frame_clk(vsync),                    //Figure out what this should be so that the tank will move
        .Reset(reset_ah),
        .keycode(keycode0_gpio[31:0]),
        .relife(relife),
        .game_state(game_state_sig),
        .SW(SW_S),

        .seed_1(seed_1),
        .seed_2(seed_2),
        .key_counter(key_counter)
    );

    game_state_machine FSM(
        .clk(Clk),
        .reset(reset_ah),
        .CONT(CONT_En),
        .TankDead_1(tankdead),
        .TankDead_2(tankdead_2),
        .p1_score(p1_score),
        .p2_score(p2_score),
        .wins_need(wins),

        .game_state(game_state_sig)
    );

    //tank Module
    tank tank_instance(
        .Reset(reset_ah),
        .frame_clk(vsync),                    //Figure out what this should be so that the tank will move
        .keycode(keycode0_gpio[31:0]),    //Notice: only one keycode connected to tank by default
        .TankX_other(tankxsig_2),
        .TankY_other(tankysig_2),

        .BulletX(bulletxsig),
        .BulletY(bulletysig),
        //.BulletAge(bullet_age),
        .Is_bullet_active(bullet_active),

        .BulletX_2(bulletxsig_2),
        .BulletY_2(bulletysig_2),
        //.BulletAge_2(bullet_age_2),
        .Is_bullet_active_2(bullet_active_2),

        .obs_left(obs_left),
        .obs_right(obs_right),
        .obs_top(obs_top),
        .obs_bottom(obs_bottom),
        .random_seed(seed_2),

        .TankX(tankxsig),
        .TankY(tankysig),
        .TankS(tanksizesig),
        .TankDir(tankdirsig),
        .TankDead(tankdead),

        .relife(relife),
        .shoot_en(shoot_en)
    );

    tank_2 tank_instance_2(
        .Reset(reset_ah),
        .frame_clk(vsync),                    //Figure out what this should be so that the tank will move
        .keycode(keycode0_gpio[31:0]),    //Notice: only one keycode connected to tank by default

        .TankX_other(tankxsig),
        .TankY_other(tankysig),

        .BulletX(bulletxsig),
        .BulletY(bulletysig),
        //.BulletAge(bullet_age),
        .Is_bullet_active(bullet_active),

        .BulletX_2(bulletxsig_2),
        .BulletY_2(bulletysig_2),
        //.BulletAge_2(bullet_age_2),
        .Is_bullet_active_2(bullet_active_2),

        .obs_left(obs_left),
        .obs_right(obs_right),
        .obs_top(obs_top),
        .obs_bottom(obs_bottom),
        .random_seed(seed_2),

        .TankX(tankxsig_2),
        .TankY(tankysig_2),
        .TankS(tanksizesig_2),
        .TankDir(tankdirsig_2),
        .TankDead(tankdead_2),

        .relife(relife),
        .shoot_en(shoot_en_2)
    );

    score_board score(
        .Reset(reset_ah),
        .frame_clk(vsync),
        .TankDead_1(tankdead),
        .TankDead_2(tankdead_2),
        .SW(SW_S),
        .game_state(game_state_sig),

        .relife(relife),
        .p1_score(p1_score),
        .p2_score(p2_score),
        .wins_need(wins)
    );

    bullet bullet_instance(
        .Reset(reset_ah), 
        .frame_clk(vsync),
        .TankDir(tankdirsig),
        .TankX(tankxsig),
        .TankY(tankysig),
        .keycode(keycode0_gpio[31:0]),

        .BulletX(bulletxsig), 
        .BulletY(bulletysig), 
        //.BulletS(), 
        .Is_bullet_active(bullet_active),
        .shoot_en(shoot_en),
        //.BulletAge(bullet_age),

        .obs_left(obs_left),
        .obs_right(obs_right),
        .obs_top(obs_top),
        .obs_bottom(obs_bottom),

        .SW(SW_S),
        .game_state(game_state_sig),
        .TankDead_1(tankdead),
        .TankDead_2(tankdead_2)
    );

    bullet_2 bullet_instance_2(
        .Reset(reset_ah), 
        .frame_clk(vsync),
        .TankDir(tankdirsig_2),
        .TankX(tankxsig_2),
        .TankY(tankysig_2),
        .keycode(keycode0_gpio[31:0]),

        .BulletX(bulletxsig_2), 
        .BulletY(bulletysig_2), 
        //.BulletS(), 
        .Is_bullet_active(bullet_active_2),
        .shoot_en(shoot_en_2),
        //.BulletAge(bullet_age_2),

        .obs_left(obs_left),
        .obs_right(obs_right),
        .obs_top(obs_top),
        .obs_bottom(obs_bottom),

        .SW(SW_S),
        .game_state(game_state_sig),
        .TankDead_1(tankdead),
        .TankDead_2(tankdead_2)
    );
    
    //Color Mapper Module   
    color_mapper color_instance(
        .DrawX(drawX),
        .DrawY(drawY),
        .TankX(tankxsig),
        .TankY(tankysig),
        .TankDir(tankdirsig),
        .TankX_2(tankxsig_2),
        .TankY_2(tankysig_2),
        .TankDir_2(tankdirsig_2),
        //.Tank_size(tanksizesig),
        .BulletX(bulletxsig),
        .BulletY(bulletysig),
        .Is_bullet_active(bullet_active),
        .BulletX_2(bulletxsig_2),
        .BulletY_2(bulletysig_2),
        .Is_bullet_active_2(bullet_active_2),
        .TankDead(tankdead),
        .TankDead_2(tankdead_2),
        .game_state(game_state_sig),
        .SW(SW_S),
        .p1_score(p1_score),
        .p2_score(p2_score),
        .wins(wins),

        .clk(vsync),
        .reset(reset_ah),

        .obs_left(obs_left),
        .obs_right(obs_right),
        .obs_top(obs_top),
        .obs_bottom(obs_bottom),

        .Red(red),
        .Green(green),
        .Blue(blue)
    );

    obstacles obstacles_instace(
        .random_seed(seed_1),
        .obs_left(obs_left),
        .obs_right(obs_right),
        .obs_top(obs_top),
        .obs_bottom(obs_bottom)
    );

endmodule
