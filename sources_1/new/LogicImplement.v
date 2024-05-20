`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/18 15:37:48
// Design Name: 
// Module Name: LogicImplement
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module LogicImplement(
    input clk,
    input left,
    input right,
    input rotate,
    input fall,
    input change,
    input isPause,
    input reset,
    input [16:0] addr,
    output reg isFinish,
    output reg haveCube,
    output flag);

    parameter width = 10'd320;

    //框定方块和分数显示区�????????????
    parameter cubeLeft = 10'd10,
              cubeWidth = 10'd150,
              cubeTop = 10'd10,
              cubeHeight = 10'd300,
              nextLeft = 10'd212,
              nextWidth = 10'd60,
              nextTop = 10'd56,
              nextHeight = 10'd30,
              scoreLeft = 10'd196,
              scoreWidth = 10'd16,
              scoreTop = 10'd134,
              scoreHeight = 10'd32,
              scoreSpan = 10'd19;

    reg[0:10] gameArea[0:19];
    reg[0:10] gameAreaWithoutCurrent[0:19];
    reg[0:7] currentCube;
    reg[0:7] nextCube;
    reg[0:7] randomCube;
    reg[0:55] cubes = 56'b1111_0000_0100_1110_1100_1100_0110_1100_1100_0110_1110_1000_1000_1110;
    
    integer i;
    reg[3:0] rst = 0;
    reg rst_up;
    reg rst_down;
    reg gamePaused;
    reg[0:2] rand; 

    parameter initX = 3,
              initY = 0;
    // 方块方向, 0: 横向�?????????1: 纵向
    reg rotation = 0;
    reg[0:3] positionX;
    reg[0:4] positionY;

    reg initFinish = 0;

    // 随机方块，所有下�???个方块在这里�???
    always @(posedge clk) begin
        //rand = {$random} % 7;
        randomCube = cubes[0:7];
    end

    reg[16:0] addresses;
    reg[4:0] posX;
    reg[4:0] posY;
    reg cubeArea;

    integer j;

    // 判断当前地址是否存在方块，存在显示方块，不存在显示背�???????
    always @(posedge clk) begin
        haveCube = 0;
        cubeArea = 0;
        // cubeArea
        addresses = addr - width * cubeTop - cubeLeft - 1;

        for (j = 0; j < 20 && addresses >= 4800; j = j + 1) begin
            addresses = addresses - 4800;
        end
        if (j < 20) begin
            posY = j;
            for (j = 0; j < 15 && addresses >= 320; j = j + 1) begin
                addresses = addresses - 320;
            end
            for (j = 0; j < 10 && addresses >= 15; j = j + 1) begin
                addresses = addresses - 15;
            end
            if (j < 10) begin
                posX = j;
                haveCube = gameArea[posY][posX];
                // haveCube = gameArea[0][0];
                cubeArea = 1;
            end
        end

        // nextArea
        if (~cubeArea) begin
            posY = 2;
            posX = 4;
            addresses = addr - width * nextTop - nextLeft - 1;

            for (j = 0; j < 2 && addresses >= 4800; j = j + 1) begin
                addresses = addresses - 4800;
            end
            if (j < 2) begin
            posY = j;
                for (j = 0; j < 15 && addresses >= 320; j = j + 1) begin
                    addresses = addresses - 320;
                end
                for (j = 0; j < 4 && addresses >= 15; j = j + 1) begin
                    addresses = addresses - 15;
                end
                if (j < 4) begin
                    posX = j;
                    haveCube = nextCube[posY * 4 + posX];
                    // haveCube = 1;
                end
            end
        end
    end

    //-----上：确定是否有方块�?�下：运行�?�辑部分�???????????------
    
    assign flag = gamePaused;

    parameter maxCnt = 25000000;
    reg[24:0] cnt = 0;
    
    reg[3:0] lef = 0;
    reg lef_p;
    reg[3:0] rig = 0;
    reg rig_p;
    reg[3:0] rot = 0;
    reg rot_p;
    reg[0:7] tempCube;// ?
    reg isDown = 0;
    reg canLeft = 0;
    reg canRight = 0;

    integer k;
    
    // 初始化加各种功能
    // 又到了最讨厌的一个变量不能放在两个always里赋值的时�??
    always @(posedge clk) begin
        // init
        rst = {rst[2:0], reset};
        rst_up = ~rst[3] & rst[2];
        rst_down = rst[3] & ~rst[2];
        if (rst_up == 1) begin
            for (i = 0; i < 20; i = i + 1) begin
                gameArea[i] = 0;
                gameAreaWithoutCurrent[i] = 0;
            end
            //currentCube = cubes[{$random} % 7];
            currentCube = cubes[0:7];
            nextCube = randomCube;
            positionX = initX;
            positionY = initY;
            initFinish = 1;
            isFinish = 0;
            rotation = 0;
            gameArea[positionY][positionX] = currentCube[0];
            gameArea[positionY][positionX + 1] = currentCube[1];
            gameArea[positionY][positionX + 2] = currentCube[2];
            gameArea[positionY][positionX + 3] = currentCube[3];
            gameArea[positionY + 1][positionX] = currentCube[4];
            gameArea[positionY + 1][positionX + 1] = currentCube[5];
            gameArea[positionY + 1][positionX + 2] = currentCube[6];
            gameArea[positionY + 1][positionX + 3] = currentCube[7];
        end
        if (reset || isPause) begin
            gamePaused = 0;
        end
        else begin
            gamePaused = 1;
        end

        if (gamePaused && initFinish && ~isFinish) begin
            initFinish = 1;
            // 下落
            if (fall == 1) begin
                cnt = cnt + 2;
            end
            else begin
                cnt = cnt + 1;
            end
            if (cnt >= maxCnt) begin
                cnt = 0;
                // check and fall
                case(rotation) 
                0: begin
                    if (positionY == 19) begin
                        isDown = 1;
                    end
                    else if (positionY == 18) begin
                        // 贴地或�?�下面有东西
                        isDown = (currentCube[4] | currentCube[5] | currentCube[6] | currentCube[7]) | (currentCube[0] & gameAreaWithoutCurrent[positionY + 1][positionX]) | (currentCube[1] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[2] & gameAreaWithoutCurrent[positionY + 1][positionX + 2]) | (currentCube[3] & gameAreaWithoutCurrent[positionY + 1][positionX + 3]);
                    end
                    else begin
                        isDown = (currentCube[0] & gameAreaWithoutCurrent[positionY + 1][positionX]) | (currentCube[1] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[2] & gameAreaWithoutCurrent[positionY + 1][positionX + 2]) | (currentCube[3] & gameAreaWithoutCurrent[positionY + 1][positionX + 3]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 2][positionX]) | (currentCube[5] & gameAreaWithoutCurrent[positionY + 2][positionX + 1]) | (currentCube[6] & gameAreaWithoutCurrent[positionY + 2][positionX + 2]) | (currentCube[7] & gameAreaWithoutCurrent[positionY + 2][positionX + 3]);
                    end
                end
                1: begin
                    if (positionY == 18) begin
                        isDown = 1;
                    end
                    else if (positionY == 17) begin
                        isDown = (currentCube[4] | currentCube[5]) | (currentCube[0] & gameAreaWithoutCurrent[positionY + 1][positionX]) | (currentCube[1] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[2] & gameAreaWithoutCurrent[positionY + 2][positionX]) | (currentCube[3] & gameAreaWithoutCurrent[positionY + 2][positionX + 1]);
                    end
                    else if (positionY == 16) begin
                        isDown = (currentCube[6] | currentCube[7]) | (currentCube[0] & gameAreaWithoutCurrent[positionY + 1][positionX]) | (currentCube[1] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[2] & gameAreaWithoutCurrent[positionY + 2][positionX]) | (currentCube[3] & gameAreaWithoutCurrent[positionY + 2][positionX + 1]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 3][positionX]) | (currentCube[5] & gameAreaWithoutCurrent[positionY + 3][positionX + 1]);
                    end
                    else begin
                        isDown = (currentCube[0] & gameAreaWithoutCurrent[positionY + 1][positionX]) | (currentCube[1] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[2] & gameAreaWithoutCurrent[positionY + 2][positionX]) | (currentCube[3] & gameAreaWithoutCurrent[positionY + 2][positionX + 1]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 3][positionX]) | (currentCube[5] & gameAreaWithoutCurrent[positionY + 3][positionX + 1]) | (currentCube[6] & gameAreaWithoutCurrent[positionY + 4][positionX]) | (currentCube[7] & gameAreaWithoutCurrent[positionY + 4][positionX + 1]);
                    end
                end
                endcase
                if (isDown == 1) begin
                    // 到底了就判断一波有没有能消除的行
                    for(k = 19; k <= 0; k = k - 1) begin
                        
                    end
                    for(k = 0; k < 20; k = k + 1) begin
                        gameAreaWithoutCurrent[k] = gameArea[k];
                    end
                    currentCube = nextCube;
                    nextCube = randomCube;
                    positionX = initX;
                    positionY = initY;
                    rotation = 0;

                    // 此处插入判断是否已经满了，满了就结束
                    if ((currentCube[0] & gameAreaWithoutCurrent[positionY][positionX]) | (currentCube[1] & gameAreaWithoutCurrent[positionY][positionX + 1]) | (currentCube[2] & gameAreaWithoutCurrent[positionY][positionX + 2]) | (currentCube[3] & gameAreaWithoutCurrent[positionY][positionX + 3]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 1][positionX]) | (currentCube[5] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[6] & gameAreaWithoutCurrent[positionY + 1][positionX + 2]) | (currentCube[7] & gameAreaWithoutCurrent[positionY + 1][positionX + 3])) begin
                        isFinish = 1;
                    end

                    gameArea[positionY][positionX] = currentCube[0] | gameAreaWithoutCurrent[positionY][positionX];
                    gameArea[positionY][positionX + 1] = currentCube[1] | gameAreaWithoutCurrent[positionY][positionX + 1];
                    gameArea[positionY][positionX + 2] = currentCube[2] | gameAreaWithoutCurrent[positionY][positionX + 2];
                    gameArea[positionY][positionX + 3] = currentCube[3] | gameAreaWithoutCurrent[positionY][positionX + 3];
                    gameArea[positionY + 1][positionX] = currentCube[4] | gameAreaWithoutCurrent[positionY + 1][positionX];
                    gameArea[positionY + 1][positionX + 1] = currentCube[5] | gameAreaWithoutCurrent[positionY + 1][positionX + 1];
                    gameArea[positionY + 1][positionX + 2] = currentCube[6] | gameAreaWithoutCurrent[positionY + 1][positionX + 2];
                    gameArea[positionY + 1][positionX + 3] = currentCube[7] | gameAreaWithoutCurrent[positionY + 1][positionX + 3];
                end
                else begin
                    for(k = 0; k < 20; k = k + 1) begin
                        gameArea[k] = gameAreaWithoutCurrent[k];
                    end
                    positionY = positionY + 1;
                    case (rotation)
                    0: begin
                        gameArea[positionY][positionX] = currentCube[0] | gameAreaWithoutCurrent[positionY][positionX];
                        gameArea[positionY][positionX + 1] = currentCube[1] | gameAreaWithoutCurrent[positionY][positionX + 1];
                        gameArea[positionY][positionX + 2] = currentCube[2] | gameAreaWithoutCurrent[positionY][positionX + 2];
                        gameArea[positionY][positionX + 3] = currentCube[3] | gameAreaWithoutCurrent[positionY][positionX + 3];
                        gameArea[positionY + 1][positionX] = currentCube[4] | gameAreaWithoutCurrent[positionY + 1][positionX];
                        gameArea[positionY + 1][positionX + 1] = currentCube[5] | gameAreaWithoutCurrent[positionY + 1][positionX + 1];
                        gameArea[positionY + 1][positionX + 2] = currentCube[6] | gameAreaWithoutCurrent[positionY + 1][positionX + 2];
                        gameArea[positionY + 1][positionX + 3] = currentCube[7] | gameAreaWithoutCurrent[positionY + 1][positionX + 3];
                    end
                    1: begin
                        gameArea[positionY][positionX] = currentCube[0] | gameAreaWithoutCurrent[positionY][positionX];
                        gameArea[positionY][positionX + 1] = currentCube[1] | gameAreaWithoutCurrent[positionY][positionX + 1];
                        gameArea[positionY + 1][positionX] = currentCube[2] | gameAreaWithoutCurrent[positionY + 1][positionX];
                        gameArea[positionY + 1][positionX + 1] = currentCube[3] | gameAreaWithoutCurrent[positionY + 1][positionX + 1];
                        gameArea[positionY + 2][positionX] = currentCube[4] | gameAreaWithoutCurrent[positionY + 2][positionX];
                        gameArea[positionY + 2][positionX + 1] = currentCube[5] | gameAreaWithoutCurrent[positionY + 2][positionX + 1];
                        gameArea[positionY + 3][positionX] = currentCube[6] | gameAreaWithoutCurrent[positionY + 3][positionX];
                        gameArea[positionY + 3][positionX + 1] = currentCube[7] | gameAreaWithoutCurrent[positionY + 3][positionX + 1];
                    end
                    endcase
                end
            end

            // 左
            lef = {lef[2:0], left};
            lef_p = ~lef[3] & lef[2];
            if (lef_p) begin
                if (positionX == 0) begin
                    canLeft = 0
                end
                else begin
                    case (rotation)
                    0: begin
                        canLeft = ~((currentCube[0] & gameAreaWithoutCurrent[positionY][positionX - 1]) | (currentCube[1] & gameAreaWithoutCurrent[positionY][positionX]) | (currentCube[2] & gameAreaWithoutCurrent[positionY][positionX + 1]) | (currentCube[3] & gameAreaWithoutCurrent[positionY][positionX + 2]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 1][positionX - 1]) | (currentCube[5] & gameAreaWithoutCurrent[positionY + 1][positionX]) | (currentCube[6] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[7] & gameAreaWithoutCurrent[positionY + 1][positionX + 2]));
                    end
                    1: begin
                        canLeft = ~((currentCube[0] & gameAreaWithoutCurrent[positionY][positionX - 1]) | (currentCube[1] & gameAreaWithoutCurrent[positionY][positionX]) | (currentCube[2] & gameAreaWithoutCurrent[positionY + 1][positionX - 1]) | (currentCube[3] & gameAreaWithoutCurrent[positionY + 1][positionX]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 2][positionX - 1]) | (currentCube[5] & gameAreaWithoutCurrent[positionY + 2][positionX]) | (currentCube[6] & gameAreaWithoutCurrent[positionY + 3][positionX - 1]) | (currentCube[7] & gameAreaWithoutCurrent[positionY + 3][positionX]));
                    end
                    endcase
                end
                if (canLeft) begin
                    for(k = 0; k < 20; k = k + 1) begin
                        gameArea[k] = gameAreaWithoutCurrent[k];
                    end
                    positionX = positionX - 1;
                    case (rotation)
                    0: begin
                        gameArea[positionY][positionX] = currentCube[0] | gameAreaWithoutCurrent[positionY][positionX];
                        gameArea[positionY][positionX + 1] = currentCube[1] | gameAreaWithoutCurrent[positionY][positionX + 1];
                        gameArea[positionY][positionX + 2] = currentCube[2] | gameAreaWithoutCurrent[positionY][positionX + 2];
                        gameArea[positionY][positionX + 3] = currentCube[3] | gameAreaWithoutCurrent[positionY][positionX + 3];
                        gameArea[positionY + 1][positionX] = currentCube[4] | gameAreaWithoutCurrent[positionY + 1][positionX];
                        gameArea[positionY + 1][positionX + 1] = currentCube[5] | gameAreaWithoutCurrent[positionY + 1][positionX + 1];
                        gameArea[positionY + 1][positionX + 2] = currentCube[6] | gameAreaWithoutCurrent[positionY + 1][positionX + 2];
                        gameArea[positionY + 1][positionX + 3] = currentCube[7] | gameAreaWithoutCurrent[positionY + 1][positionX + 3];
                    end
                    1: begin
                        gameArea[positionY][positionX] = currentCube[0] | gameAreaWithoutCurrent[positionY][positionX];
                        gameArea[positionY][positionX + 1] = currentCube[1] | gameAreaWithoutCurrent[positionY][positionX + 1];
                        gameArea[positionY + 1][positionX] = currentCube[2] | gameAreaWithoutCurrent[positionY + 1][positionX];
                        gameArea[positionY + 1][positionX + 1] = currentCube[3] | gameAreaWithoutCurrent[positionY + 1][positionX + 1];
                        gameArea[positionY + 2][positionX] = currentCube[4] | gameAreaWithoutCurrent[positionY + 2][positionX];
                        gameArea[positionY + 2][positionX + 1] = currentCube[5] | gameAreaWithoutCurrent[positionY + 2][positionX + 1];
                        gameArea[positionY + 3][positionX] = currentCube[6] | gameAreaWithoutCurrent[positionY + 3][positionX];
                        gameArea[positionY + 3][positionX + 1] = currentCube[7] | gameAreaWithoutCurrent[positionY + 3][positionX + 1];
                    end
                    endcase
                end
            end

            // 右
            rig = {rig[2:0], right};
            rig_p = ~rig[3] & rig[2];
            if (rig_p) begin
                case (rotation)
                0: begin
                    if (positionX == 8) begin
                        canRight = 0;
                    end
                    else if (positionX == 7) begin
                        canRight = ~((currentCube[2] | currentCube[6]) | (currentCube[0] & gameAreaWithoutCurrent[positionY][positionX + 1]) | (currentCube[1] & gameAreaWithoutCurrent[positionY][positionX + 2]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[5] & gameAreaWithoutCurrent[positionY + 1][positionX + 2]));
                    end
                    else if (positionX == 6) begin
                        canRight = ~((currentCube[3] | currentCube[7]) | (currentCube[0] & gameAreaWithoutCurrent[positionY][positionX + 1]) | (currentCube[1] & gameAreaWithoutCurrent[positionY][positionX + 2]) | (currentCube[2] & gameAreaWithoutCurrent[positionY][positionX + 3]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[5] & gameAreaWithoutCurrent[positionY + 1][positionX + 2]) | (currentCube[6] & gameAreaWithoutCurrent[positionY + 1][positionX + 3]));
                    end
                    else begin
                        canRight = ~((currentCube[0] & gameAreaWithoutCurrent[positionY][positionX + 1]) | (currentCube[1] & gameAreaWithoutCurrent[positionY][positionX + 2]) | (currentCube[2] & gameAreaWithoutCurrent[positionY][positionX + 3]) | (currentCube[3] & gameAreaWithoutCurrent[positionY][positionX + 4]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[5] & gameAreaWithoutCurrent[positionY + 1][positionX + 2]) | (currentCube[6] & gameAreaWithoutCurrent[positionY + 1][positionX + 3]) | (currentCube[7] & gameAreaWithoutCurrent[positionY + 1][positionX + 4]));
                    end
                end
                1: begin
                    if (positionX == 9) begin
                        canRight = 0;
                    end
                    else if (positionX == 8) begin
                        canRight = ~((currentCube[1] | currentCube[3] | currentCube[5] | currentCube[7]) | (currentCube[0] & gameAreaWithoutCurrent[positionY][positionX + 1]) | (currentCube[2] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 2][positionX + 1]) | (currentCube[6] & gameAreaWithoutCurrent[positionY + 3][positionX + 1]));
                    end
                    else begin
                        canRight = ~((currentCube[0] & gameAreaWithoutCurrent[positionY][positionX + 1]) | (currentCube[1] & gameAreaWithoutCurrent[positionY][positionX + 2]) | (currentCube[2] & gameAreaWithoutCurrent[positionY + 1][positionX + 1]) | (currentCube[3] & gameAreaWithoutCurrent[positionY + 1][positionX + 2]) | (currentCube[4] & gameAreaWithoutCurrent[positionY + 2][positionX + 1]) | (currentCube[5] & gameAreaWithoutCurrent[positionY + 2][positionX + 2]) | (currentCube[6] & gameAreaWithoutCurrent[positionY + 3][positionX + 1]) | (currentCube[7] & gameAreaWithoutCurrent[positionY + 3][positionX + 2])); 
                    end
                end
                endcase
                if (canRight) begin
                    for(k = 0; k < 20; k = k + 1) begin
                        gameArea[k] = gameAreaWithoutCurrent[k];
                    end
                    positionX = positionX + 1;
                    case (rotation)
                    0: begin
                        gameArea[positionY][positionX] = currentCube[0] | gameAreaWithoutCurrent[positionY][positionX];
                        gameArea[positionY][positionX + 1] = currentCube[1] | gameAreaWithoutCurrent[positionY][positionX + 1];
                        gameArea[positionY][positionX + 2] = currentCube[2] | gameAreaWithoutCurrent[positionY][positionX + 2];
                        gameArea[positionY][positionX + 3] = currentCube[3] | gameAreaWithoutCurrent[positionY][positionX + 3];
                        gameArea[positionY + 1][positionX] = currentCube[4] | gameAreaWithoutCurrent[positionY + 1][positionX];
                        gameArea[positionY + 1][positionX + 1] = currentCube[5] | gameAreaWithoutCurrent[positionY + 1][positionX + 1];
                        gameArea[positionY + 1][positionX + 2] = currentCube[6] | gameAreaWithoutCurrent[positionY + 1][positionX + 2];
                        gameArea[positionY + 1][positionX + 3] = currentCube[7] | gameAreaWithoutCurrent[positionY + 1][positionX + 3];
                    end
                    1: begin
                        gameArea[positionY][positionX] = currentCube[0] | gameAreaWithoutCurrent[positionY][positionX];
                        gameArea[positionY][positionX + 1] = currentCube[1] | gameAreaWithoutCurrent[positionY][positionX + 1];
                        gameArea[positionY + 1][positionX] = currentCube[2] | gameAreaWithoutCurrent[positionY + 1][positionX];
                        gameArea[positionY + 1][positionX + 1] = currentCube[3] | gameAreaWithoutCurrent[positionY + 1][positionX + 1];
                        gameArea[positionY + 2][positionX] = currentCube[4] | gameAreaWithoutCurrent[positionY + 2][positionX];
                        gameArea[positionY + 2][positionX + 1] = currentCube[5] | gameAreaWithoutCurrent[positionY + 2][positionX + 1];
                        gameArea[positionY + 3][positionX] = currentCube[6] | gameAreaWithoutCurrent[positionY + 3][positionX];
                        gameArea[positionY + 3][positionX + 1] = currentCube[7] | gameAreaWithoutCurrent[positionY + 3][positionX + 1];
                    end
                    endcase
                end
            end

            // 旋转
            rot = {rot[2:0], rotate};
            rot_p = ~rot[3] & rot[2];
            if (rot_p) begin
                case(rotation) 
                0: begin
                    
                end
                1: begin
                    tempCube[0] <= currentCube[7];
                    tempCube[1] <= currentCube[5];
                    tempCube[2] <= currentCube[3];
                    tempCube[3] <= currentCube[1];
                    tempCube[4] <= currentCube[6];
                    tempCube[5] <= currentCube[4];
                    tempCube[6] <= currentCube[2];
                    tempCube[7] <= currentCube[0];
                end
                endcase
                // check tempCube, if can rotate, then do it
                
                // rotation = ~rotation;
            end
        end
    end
    
endmodule
