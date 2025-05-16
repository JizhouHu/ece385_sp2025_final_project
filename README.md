# ECE 385 Final Project (SP25)
# Team Members: jizhouh2, yimingn4
# Project Title: Tank War

Overview
Tank War is a two-player competitive video game implemented on the FPGA (Urbana Board) platform. This project builds upon the IP design and MicroBlaze setup introduced in Lab 6.2. Players control tanks using a USB keyboard, and the game is displayed on an HDMI monitor.

Setup Instructions
1. Vivado Project Configuration
Follow the instructions provided in the Lab 6.2 documentation to configure the FPGA IP design.

Import the SystemVerilog source files (.sv) and the constraint file (.xdc) into the Vivado project.

Generate the bitstream and export the hardware with the bitstream included.

2. Vitis Project Setup
Create an application project in Vitis using the exported hardware platform.

Reuse the AXI read/write functions as implemented in Lab 6.2 for communication between MicroBlaze and memory-mapped peripherals.

Build the application and prepare it for debugging.

3. Programming and Debugging
Set up the GDB debugger and load the bitstream onto the FPGA using the Vitis Serial Terminal.

Ensure the FPGA is connected to:

A USB keyboard (for player input)

An HDMI monitor (for game output)

4. Running the Game
After launching the debugger and loading the application, the title screen with the text “TANK WAR” should appear.

The title color will alternate between red and blue. 

Press BTN0 (Reset) to initialize or restart the game.

Press BTN1 (Continue) to advance through the game menu.

Use switches [3:0] to select gameplay parameters during menu navigation.
