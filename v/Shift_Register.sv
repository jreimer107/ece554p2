module Shift_Register(
	input iCLK,
	input iRST,
	input iDVAL,
	input [11:0] grayVal,
	output oDVAL,
	output [11:0] oDATA;
	);

wire row_end;
assign row_end = 0;

reg [11:0] shift_reg[1281:0];

reg [18:0] PXL_cnt;
reg [19:0] TARG_cnt;

always @(posedge iCLK, negedge iRST)
  if(!iRST)
    shift_reg <= '{default:0};
  else if(iDVAL)
    shift_reg <= {shift_reg[1281:0], grayVal};
  else if(iDVAL && row_end)
    shift_reg <= {shift_reg[1279:0], 12'b0, 12'b0, grayVal};

always @(posedge iCLK, negedge iRST)
  if(!iRST)
    PXL_cnt <= 0;
  else if(iDVAL && PXL_cnt < 19'd307200)
    PXL_cnt <= PXL_cnt + 1;
  else if(iCLK_cnt == 19'd307200)
    PXL_cnt <= 0;

always @(posedge iCLK, negedge iRST)
  if(!iRST)
    TARG_cnt <= -20'd640;
  else if(TARG_cnt == 20'd307200)
    TARG_cnt <= PXL_cnt - 20'd640;
  else if(iDVAL || TARG_cnt > 20'306560)
    TARG_cnt <= TARG_cnt + 1;

assign oDVAL = TARG_cnt >= 0

always_comb begin
  if (TARG_cnt < 0)
    oDVAL = 0;
  else if (TARG_cnt > 306560)
    oDVAL = 1;
  else
    oDVAL = iDVAL;
end;

signed wire [10:0] X, Y;
assign X = TARG_cnt % 640;
assign Y = TARG_cnt / 640;

wire edge_N, edge_S, edge_E, edge_W;
assign edge_N = Y == 0;
assign edge_S = Y == 479;
assign edge_W = X == 0;
assign edge_E = X == 639;

wire [11:0] kernel [2:0][2:0];
assign kernel[0][0] = edge_N || edge_W ? 12'b0 : shift_reg[1281];
assign kernel[0][1] = edge_N ? 12'b0 : shift_reg[1280];
assign kernel[0][2] = edge_N || edge_E ? 12'b0 : shift_reg[1279];
assign kernel[1][0] = edge_W ? 12'b0 : shift_reg[641];
assign kernel[1][1] = shift_reg[640];
assign kernel[1][2] = edge_E ? 12'b0 : shift_reg[639];
assign kernel[2][0] = edge_S || edge_W ? 12'b0 : shift_reg[1];
assign kernel[2][1] = edge_S ? 12'b0 : shift_reg[0];
assign kernel[2][2] = edge_S || edge_E ? 12'b0 : grayVal;

signed wire [2:0] sobel_v [2:0][2:0], sobel_h[2:0][2:0];
assign sobel_v[0][0] = -1;
assign sobel_v[0][1] = 0;
assign sobel_v[0][2] = 1;
assign sobel_v[1][0] = -2;
assign sobel_v[1][1] = 0;
assign sobel_v[1][2] = 2;
assign sobel_v[2][0] = -1;
assign sobel_v[2][1] = 0;
assign sobel_v[2][2] = 1;

assign sobel_h[0][0] = -1;
assign sobel_h[0][1] = -2;
assign sobel_h[0][2] = -1;
assign sobel_h[1][0] = 0;
assign sobel_h[1][1] = 0;
assign sobel_h[1][2] = 0;
assign sobel_h[2][0] = 1;
assign sobel_h[2][1] = 2;
assign sobel_h[2][2] = 1;

assign oDATA = 
  sobel_v[0][0] * kernel[0][0] +
  sobel_v[0][1] * kernel[0][1] +
  sobel_v[0][2] * kernel[0][2] +
  sobel_v[1][0] * kernel[1][0] +
  sobel_v[1][1] * kernel[1][1] +
  sobel_v[1][2] * kernel[1][2] +
  sobel_v[2][0] * kernel[2][0] +
  sobel_v[2][1] * kernel[2][1] +
  sobel_v[2][2] * kernel[2][2];


endmodule
