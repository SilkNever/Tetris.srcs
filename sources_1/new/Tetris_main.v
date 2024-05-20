`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/03/11 17:10:06
// Design Name:
// Module Name: Tetris_main
// Project Name: Tetris
// Target Devices: BASYS3
// Tool Versions: 2020.2
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module Tetris_main (
    input clk_100m,
    input left,
    input right,
    input fall,
    input rotate,
    input change,
    input pause,
    input reset,
    output light0,
    output light1,
    output reg [11:0] rgb,
    output x_sync,
    output y_sync);
    
    //使用640x480分辨率，��?要时钟频��?25MHz，输入clk_100m��?100MHz��?
    reg clk = 0;
    reg tCount = 0;
    always @(posedge clk_100m) begin
        if (tCount == 1) begin
            clk = ~clk;
            tCount = 0;
        end 
        else begin
            tCount = tCount + 1;
        end
    end
    
    //640x480屏幕像素基本设置
    parameter xSyncWidth = 10'd96,
              xLBoard = 10'd48,
              xRBoard = 10'd16,
              xWidth = 10'd640,
              xTotal = 10'd800,
              ySyncHeight = 10'd2,
              yUBoard = 10'd33,
              yDBoard = 10'd10,
              yHeight = 10'd480,
              yTotal = 10'd525;
    
    //设置行同步和列同��?
    reg [9:0] xCount, yCount;
    always @(posedge clk) begin
        if (xCount == xTotal - 1) begin
            xCount = 0;
            yCount = yCount + 1;
        end 
        else begin
            xCount = xCount + 1;
        end
        if (yCount == yTotal - 1) begin
            yCount = 0;
        end
    end
    //过了行同步和列同步的宽度将其��? 1，提示显示器即将发光
    assign x_sync = (xCount >= xSyncWidth);
    assign y_sync = (yCount >= ySyncHeight);
    
    //--------上面为显示设置，下面是项目设��??--------
    
    //显示要的宽度和高��?
    parameter width = 10'd320, 
              height = 10'd320;
    //颜色
    parameter black = 4'h0, 
              grey = 4'h5;
    //限定320x320项目显示区域
    wire isEnable;
    wire figStart;
    //左右上下边界之内enable
    assign isEnable = (xCount >= xSyncWidth + xLBoard + (xWidth - width) / 2) && (xCount < xSyncWidth + xLBoard + (xWidth + width) / 2) && (yCount >= ySyncHeight + yUBoard + (yHeight - height) / 2) && (yCount < ySyncHeight + yUBoard + (yHeight + height) / 2);
    assign figStart = (xCount == xSyncWidth + xLBoard + (xWidth - width) / 2) && (yCount == ySyncHeight + yUBoard + (yHeight - height) / 2);
    
    //基本参数和变��?
    // reg[3:0] screen[319:0][319:0];
    reg [16:0] address;
    
    //change picture address
    always @(posedge clk) begin
        if (figStart) begin
            address <= 17'b0;
        end
        else if (isEnable) begin
            address <= address + 1'b1;
        end
    end
    
    wire [15:0] bgColor;
    wire isFinish;
    wire haveCube;
    
    //控制输出颜色
    always @(posedge clk) begin
        if (isEnable) begin
            if (haveCube == 1) begin
                rgb = {grey, grey, grey};
            end 
            else begin
                rgb[11:8] = bgColor[15:12];
                rgb[7:4]  = bgColor[10:7];
                rgb[3:0]  = bgColor[4:1];
            end
        end 
        else begin
            rgb = 0;
        end
        
        // rgb = {color, color, color};
    end
    
    // assign light1 = ~haveCube;
    assign light0 = isFinish;
    
    LogicImplement imp (
        .clk(clk),
        .left(left),
        .right(right),
        .rotate(rotate),
        .fall(fall),
        .change(change),
        .isPause(pause),
        .reset(reset),
        .addr(address),
        .isFinish(isFinish),
        .haveCube(haveCube),
        .flag(light1)
    );
    
    GameBg bg (
        .clka (clk),
        .addra(address),
        .douta(bgColor)
    );
endmodule
