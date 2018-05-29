/*
 * This file is part of John the Ripper password cracker,
 * Copyright (c) 2013, 2014 by Katja Malvoni <kmalvoni at gmail dot com>
 * It is hereby released to the general public under the following terms:
 * Redistribution and use in source and binary forms, 
 * with or without modification, are permitted.
 */

module bcrypt_loop
(
	clk,
	wea0,
	web0,
	addra0, 
	addrb0,
	dina0, 
	dinb0,
	douta0, 
	doutb0,
	wea1,
	web1,
	addra1, 
	addrb1,
	dina1, 
	dinb1,
	douta1, 
	doutb1,
	start,
	done
);

parameter INIT				= 4'b0000;
parameter P_XOR_EXP			= 4'b0001;
parameter ENCRYPT_INIT			= 4'b0010;
parameter FEISTEL			= 4'b0011;
parameter STORE_L_R			= 4'b0100;
parameter P_XOR_SALT			= 4'b0101;
parameter LOOP				= 4'b0110;
parameter DONE				= 4'b0111;
parameter SET				= 4'b1000;
parameter LOAD_S			= 4'b1100;
parameter UPDATE_L_R			= 4'b1101;
parameter XOR_SALT			= 4'b1110;
parameter FINAL			= 4'b1111;

parameter C_MST_NATIVE_DATA_WIDTH      = 32;
parameter C_LENGTH_WIDTH               = 12;
parameter C_MST_AWIDTH                 = 32;
parameter C_NUM_REG                    = 6;
parameter C_SLV_DWIDTH                 = 32;

input 	clk;
output	wea0;
output	wea1;
output 	web0;
output 	web1;
output  [9:0] addra0;
output  [9:0] addra1;
output  [9:0] addrb0;
output  [9:0] addrb1;
output  [31:0] dina0;
output  [31:0] dina1;
output  [31:0] dinb0;
output  [31:0] dinb1;
input   [31:0] douta0;
input   [31:0] douta1;
input   [31:0] doutb0;
input   [31:0] doutb1;
input   [1:0] start;
output	[1:0] done;
  
reg [1:0] done_reg;
reg [4:0] P_index = 0;
reg [4:0] ROUND_index = 0;
reg [9:0] init_index = 0;
reg [10:0] ptr = 0;
reg tmp_cnt = 0;
reg first_or_second = 0;
reg P_or_S = 0;
reg [1:0] mem_delay = 0;
reg which_xor = 0;
reg prep = 1;
reg enc_final = 0;
reg [31:0] count = 0;

reg [31:0] L1 = 0;
reg [31:0] L2 = 0;
reg [31:0] L3 = 0;
reg [31:0] L4 = 0;
reg [31:0] R1 = 0;
reg [31:0] R2 = 0;
reg [31:0] R3 = 0;
reg [31:0] R4 = 0;
reg [31:0] tmp1 = 0;
reg [3:0] state = INIT;
reg [1:0] inst = 0;
		
reg wea_0, wea_1, web_0, web_1;
reg wea_S1, wea_S2, web_S1, web_S2;
reg wea_S3, wea_S4, web_S3, web_S4;
reg wea_S5, wea_S6, web_S5, web_S6;
reg wea_S7, wea_S8, web_S7, web_S8;
reg [9:0] addra_0, addrb_0;
reg [9:0] addra_1, addrb_1;
reg [8:0] addra_S1, addrb_S1;
reg [8:0] addra_S2, addrb_S2;
reg [8:0] addra_S3, addrb_S3;
reg [8:0] addra_S4, addrb_S4;
reg [8:0] addra_S5, addrb_S5;
reg [8:0] addra_S6, addrb_S6;
reg [8:0] addra_S7, addrb_S7;
reg [8:0] addra_S8, addrb_S8;
reg [31:0] dina_0, dinb_0;
reg [31:0] dina_1, dinb_1;
reg [31:0] dina_S1, dinb_S1;
reg [31:0] dina_S2, dinb_S2;
reg [31:0] dina_S3, dinb_S3;
reg [31:0] dina_S4, dinb_S4;
reg [31:0] dina_S5, dinb_S5;
reg [31:0] dina_S6, dinb_S6;
reg [31:0] dina_S7, dinb_S7;
reg [31:0] dina_S8, dinb_S8;
wire [31:0] doutaS1, doutbS1;
wire [31:0] doutaS2, doutbS2;
wire [31:0] doutaS3, doutbS3;
wire [31:0] doutaS4, doutbS4;
wire [31:0] doutaS5, doutbS5;
wire [31:0] doutaS6, doutbS6;
wire [31:0] doutaS7, doutbS7;
wire [31:0] doutaS8, doutbS8;

ram #(32, 9) mem_S1 (clk, wea_S1, addra_S1, dina_S1, doutaS1, clk, web_S1, addrb_S1, dinb_S1, doutbS1);
ram #(32, 9) mem_S2 (clk, wea_S2, addra_S2, dina_S2, doutaS2, clk, web_S2, addrb_S2, dinb_S2, doutbS2);
ram #(32, 9) mem_S3 (clk, wea_S3, addra_S3, dina_S3, doutaS3, clk, web_S3, addrb_S3, dinb_S3, doutbS3);
ram #(32, 9) mem_S4 (clk, wea_S4, addra_S4, dina_S4, doutaS4, clk, web_S4, addrb_S4, dinb_S4, doutbS4);
ram #(32, 9) mem_S5 (clk, wea_S5, addra_S5, dina_S5, doutaS5, clk, web_S5, addrb_S5, dinb_S5, doutbS5);
ram #(32, 9) mem_S6 (clk, wea_S6, addra_S6, dina_S6, doutaS6, clk, web_S6, addrb_S6, dinb_S6, doutbS6);
ram #(32, 9) mem_S7 (clk, wea_S7, addra_S7, dina_S7, doutaS7, clk, web_S7, addrb_S7, dinb_S7, doutbS7);
ram #(32, 9) mem_S8 (clk, wea_S8, addra_S8, dina_S8, doutaS8, clk, web_S8, addrb_S8, dinb_S8, doutbS8);

assign done = done_reg;

assign wea0 = wea_0;
assign web0 = web_0;
assign addra0 = addra_0;
assign addrb0 = addrb_0;
assign dina0 = dina_0;
assign dinb0 = dinb_0;
assign wea1 = wea_1;
assign web1 = web_1;
assign addra1 = addra_1;
assign addrb1 = addrb_1;
assign dina1 = dina_1;
assign dinb1 = dinb_1;

always @(*)
begin
	wea_0 <= 0;
	web_0 <= 0;
	addra_0 <= 0;
	addrb_0 <= 0;
	dina_0 <= 0;
	dinb_0 <= 0;
	wea_1 <= 0;
	web_1 <= 0;
	addra_1 <= 0;
	addrb_1 <= 0;
	dina_1 <= 0;
	dinb_1 <= 0;
	wea_S1 <= 0;
	web_S1 <= 0;
	wea_S2 <= 0;
	web_S2 <= 0;
	wea_S3 <= 0;
	web_S3 <= 0;
	wea_S4 <= 0;
	web_S4 <= 0;
	wea_S5 <= 0;
	web_S5 <= 0;
	wea_S6 <= 0;
	web_S6 <= 0;
	wea_S7 <= 0;
	web_S7 <= 0;
	wea_S8 <= 0;
	web_S8 <= 0;
	addra_S1 <= 0;
	addrb_S1 <= 0;
	addra_S2 <= 0;
	addrb_S2 <= 0;
	addra_S3 <= 0;
	addrb_S3 <= 0;
	addra_S4 <= 0;
	addrb_S4 <= 0;
	addra_S5 <= 0;
	addrb_S5 <= 0;
	addra_S6 <= 0;
	addrb_S6 <= 0;
	addra_S7 <= 0;
	addrb_S7 <= 0;
	addra_S8 <= 0;
	addrb_S8 <= 0;
	dina_S1 <= 0;
	dinb_S1 <= 0;
	dina_S2 <= 0;
	dinb_S2 <= 0;
	dina_S3 <= 0;
	dinb_S3 <= 0;
	dina_S4 <= 0;
	dinb_S4 <= 0;
	dina_S5 <= 0;
	dinb_S5 <= 0;
	dina_S6 <= 0;
	dinb_S6 <= 0;
	dina_S7 <= 0;
	dinb_S7 <= 0;
	dina_S8 <= 0;
	dinb_S8 <= 0;
	if(state == INIT) begin
		if(init_index < 'd512) begin
			if(mem_delay < 'd1) begin
				addra_0[9] <= 1;
				addra_1[9] <= 1;
				addrb_0[9] <= 1;
				addrb_1[9] <= 1;
				addra_0[8:0] <= init_index;
				addrb_0[8:0] <= init_index + 9'd1;
				addra_1[8:0] <= init_index;
				addrb_1[8:0] <= init_index + 9'd1;
			end
			else begin
				wea_S1 <= 1;
				web_S1 <= 1;
				wea_S2 <= 1;
				web_S2 <= 1;
				wea_S3 <= 1;
				web_S3 <= 1;
				wea_S4 <= 1;
				web_S4 <= 1;
				wea_S5 <= 1;
				web_S5 <= 1;
				wea_S6 <= 1;
				web_S6 <= 1;
				wea_S7 <= 1;
				web_S7 <= 1;
				wea_S8 <= 1;
				web_S8 <= 1;
				dina_S1 <= douta0;
				dinb_S1 <= doutb0;
				dina_S2 <= douta1;
				dinb_S2 <= doutb1;
				dina_S3 <= douta0;
				dinb_S3 <= doutb0;
				dina_S4 <= douta1;
				dinb_S4 <= doutb1;
				dina_S5 <= douta0;
				dinb_S5 <= doutb0;
				dina_S6 <= douta1;
				dinb_S6 <= doutb1;
				dina_S7 <= douta0;
				dinb_S7 <= doutb0;
				dina_S8 <= douta1;
				dinb_S8 <= doutb1;
				addra_S1[8:0] <= init_index;
				addrb_S1[8:0] <= init_index + 9'd1;
				addra_S2[8:0] <= init_index;
				addrb_S2[8:0] <= init_index + 9'd1;
				addra_S3[8:0] <= init_index;
				addrb_S3[8:0] <= init_index + 9'd1;
				addra_S4[8:0] <= init_index;
				addrb_S4[8:0] <= init_index + 9'd1;
				addra_S5[8:0] <= init_index;
				addrb_S5[8:0] <= init_index + 9'd1;
				addra_S6[8:0] <= init_index;
				addrb_S6[8:0] <= init_index + 9'd1;
				addra_S7[8:0] <= init_index;
				addrb_S7[8:0] <= init_index + 9'd1;
				addra_S8[8:0] <= init_index;
				addrb_S8[8:0] <= init_index + 9'd1;
			end
		end
		else begin
			if(mem_delay < 'd1)
				addra_0 <= 7'd40;
		end
	end	
	else if(state == XOR_SALT) begin
		if(ptr < 'd18) begin
			if(mem_delay < 'd1) begin
				case (inst) 
					0: begin
						addra_0 <= 7'd36 + (ptr & 'd2);
						addrb_0 <= 7'd36 + (ptr & 'd2) + 1;
						addra_1 <= 7'd36 + (ptr & 'd2);
						addrb_1 <= 7'd36 + (ptr & 'd2) + 1;
					end
					1: begin
						addra_0 <= 7'd77 + (ptr & 'd2);
						addrb_0 <= 7'd77 + (ptr & 'd2) + 1;
						addra_1 <= 7'd77 + (ptr & 'd2);
						addrb_1 <= 7'd77 + (ptr & 'd2) + 1;
					end
				endcase
			end
		end
		else if(ptr < 'd1042) begin
			if(which_xor == 0) begin
				if(mem_delay < 'd1) begin
					case (inst)
						0: begin
							addra_0 <= 7'd38;
							addrb_0 <= 7'd39;
							addra_1 <= 7'd38;
							addrb_1 <= 7'd39;
						end
						1: begin
							addra_0 <= 7'd79;
							addrb_0 <= 7'd80;
							addra_1 <= 7'd79;
							addrb_1 <= 7'd80;
						end
					endcase
				end
			end
			else begin
				if(mem_delay < 'd1) begin
					case (inst)
						0: begin
							addra_0 <= 7'd36;
							addrb_0 <= 7'd37;
							addra_1 <= 7'd36;
							addrb_1 <= 7'd37;
						end
						1: begin
							addra_0 <= 7'd77;
							addrb_0 <= 7'd78;
							addra_1 <= 7'd77;
							addrb_1 <= 7'd78;
						end
					endcase
				end
			end
		end
	end
	else if(state == P_XOR_EXP) begin
		if(mem_delay < 'd1) begin
			case (inst)
				0: begin
					addra_0 <= P_index;
					addrb_0 <= 7'd18 + P_index;
					addra_1 <= P_index;
					addrb_1 <= 7'd18 + P_index;
				end
				1: begin
					addra_0 <= 7'd41 + P_index;
					addrb_0 <= 7'd59 + P_index;
					addra_1 <= 7'd41 + P_index;
					addrb_1 <= 7'd59 + P_index;
				end
			endcase
		end
		else begin
			wea_0 <= 1;
			wea_1 <= 1;
			case (inst)
				0: begin 
					addra_0 <= P_index;
					addra_1 <= P_index;
				end
				1: begin
					addra_0 <= 'd41 + P_index;
					addra_1 <= 'd41 + P_index;
				end
			endcase
			dina_0 <= douta0 ^ doutb0;
			dina_1 <= douta1 ^ doutb1;
		end
	end
	else if(state == ENCRYPT_INIT) begin
		if(mem_delay < 'd1) begin
			addra_0 <= 7'd0;
			addrb_0 <= 7'd41;
			addra_1 <= 7'd0;
			addrb_1 <= 7'd41;
		end
		else begin
			addra_0 <= 'd1;
			addra_S1[8] <= 0;
			addrb_S1[8] <= 1;
			addra_S2[8] <= 0;
			addrb_S2[8] <= 1;
			addra_S1[7:0] <= L1[31:24] ^ douta0[31:24];
			addrb_S1[7:0] <= L1[23:16] ^ douta0[23:16];
			addra_S2[7:0] <= L1[15:8] ^ douta0[15:8];
			addrb_S2[7:0] <= L1[7:0] ^ douta0[7:0];
			addrb_0 <= 'd42;
			addra_S3[8] <= 0;
			addrb_S3[8] <= 1;
			addra_S4[8] <= 0;
			addrb_S4[8] <= 1;
			addra_S3[7:0] <= L2[31:24] ^ doutb0[31:24];
			addrb_S3[7:0] <= L2[23:16] ^ doutb0[23:16];
			addra_S4[7:0] <= L2[15:8] ^ doutb0[15:8];
			addrb_S4[7:0] <= L2[7:0] ^ doutb0[7:0];
			addra_1 <= 'd1;
			addra_S5[8] <= 0;
			addrb_S5[8] <= 1;
			addra_S6[8] <= 0;
			addrb_S6[8] <= 1;
			addra_S5[7:0] <= L3[31:24] ^ douta1[31:24];
			addrb_S5[7:0] <= L3[23:16] ^ douta1[23:16];
			addra_S6[7:0] <= L3[15:8] ^ douta1[15:8];
			addrb_S6[7:0] <= L3[7:0] ^ douta1[7:0];
			addrb_1 <= 'd42;
			addra_S7[8] <= 0;
			addrb_S7[8] <= 1;
			addra_S8[8] <= 0;
			addrb_S8[8] <= 1;
			addra_S7[7:0] <= L4[31:24] ^ doutb1[31:24];
			addrb_S7[7:0] <= L4[23:16] ^ doutb1[23:16];
			addra_S8[7:0] <= L4[15:8] ^ doutb1[15:8];
			addrb_S8[7:0] <= L4[7:0] ^ doutb1[7:0];
		end
	end
	else if(state == FEISTEL) begin
		addra_S1[8] <= 0;
		addrb_S1[8] <= 1;
		addra_S2[8] <= 0;
		addrb_S2[8] <= 1;
		addra_S1[7:0] <= (((R1 ^ douta0) ^ (((doutaS1 + doutbS1) ^ doutaS2) + doutbS2))&32'hFF000000)>>24;
		addrb_S1[7:0] <= (((R1 ^ douta0) ^ (((doutaS1 + doutbS1) ^ doutaS2) + doutbS2))&32'h00FF0000)>>16;
		addra_S2[7:0] <= (((R1 ^ douta0) ^ (((doutaS1 + doutbS1) ^ doutaS2) + doutbS2))&32'h0000FF00)>>8;
		addrb_S2[7:0] <= (R1[7:0] ^ douta0[7:0]) ^ (((doutaS1[7:0] + doutbS1[7:0]) ^ doutaS2[7:0]) + doutbS2[7:0]);
		addra_0 <= ROUND_index + 'd2;
		addra_S3[8] <= 0;
		addrb_S3[8] <= 1;
		addra_S4[8] <= 0;
		addrb_S4[8] <= 1;
		addra_S3[7:0] <= (((R2 ^ doutb0) ^ (((doutaS3 + doutbS3) ^ doutaS4) + doutbS4))&32'hFF000000)>>24;
		addrb_S3[7:0] <= (((R2 ^ doutb0) ^ (((doutaS3 + doutbS3) ^ doutaS4) + doutbS4))&32'h00FF0000)>>16;
		addra_S4[7:0] <= (((R2 ^ doutb0) ^ (((doutaS3 + doutbS3) ^ doutaS4) + doutbS4))&32'h0000FF00)>>8;
		addrb_S4[7:0] <= (R2[7:0] ^ doutb0[7:0]) ^ (((doutaS3[7:0] + doutbS3[7:0]) ^ doutaS4[7:0]) + doutbS4[7:0]);
		addrb_0 <= 'd41 + ROUND_index + 'd2;
		addra_S5[8] <= 0;
		addrb_S5[8] <= 1;
		addra_S6[8] <= 0;
		addrb_S6[8] <= 1;
		addra_S5[7:0] <= (((R3 ^ douta1) ^ (((doutaS5 + doutbS5) ^ doutaS6) + doutbS6))&32'hFF000000)>>24;
		addrb_S5[7:0] <= (((R3 ^ douta1) ^ (((doutaS5 + doutbS5) ^ doutaS6) + doutbS6))&32'h00FF0000)>>16;
		addra_S6[7:0] <= (((R3 ^ douta1) ^ (((doutaS5 + doutbS5) ^ doutaS6) + doutbS6))&32'h0000FF00)>>8;
		addrb_S6[7:0] <= (R3[7:0] ^ douta1[7:0]) ^ (((doutaS5[7:0] + doutbS5[7:0]) ^ doutaS6[7:0]) + doutbS6[7:0]);
		addra_1 <= ROUND_index + 'd2;
		addra_S7[8] <= 0;
		addrb_S7[8] <= 1;
		addra_S8[8] <= 0;
		addrb_S8[8] <= 1;
		addra_S7[7:0] <= (((R4 ^ doutb1) ^ (((doutaS7 + doutbS7) ^ doutaS8) + doutbS8))&32'hFF000000)>>24;
		addrb_S7[7:0] <= (((R4 ^ doutb1) ^ (((doutaS7 + doutbS7) ^ doutaS8) + doutbS8))&32'h00FF0000)>>16;
		addra_S8[7:0] <= (((R4 ^ doutb1) ^ (((doutaS7 + doutbS7) ^ doutaS8) + doutbS8))&32'h0000FF00)>>8;
		addrb_S8[7:0] <= (R4[7:0] ^ doutb1[7:0]) ^ (((doutaS7[7:0] + doutbS7[7:0]) ^ doutaS8[7:0]) + doutbS8[7:0]);
		addrb_1 <= 'd41 + ROUND_index + 'd2;
	end
	else if(state == STORE_L_R) begin
		if(ptr < 'd18) begin
			wea_0 <= 1;
			web_0 <= 1;
			wea_1 <= 1;
			web_1 <= 1;
			case (inst)
				0: begin
					dina_0 <= L1;
					dinb_0 <= R1;
					addra_0 <= ptr;
					addrb_0 <= ptr + 'd1;
					dina_1 <= L3;
					dinb_1 <= R3;
					addra_1 <= ptr;
					addrb_1 <= ptr + 'd1;
				end
				1: begin
					dina_0 <= L2;
					dinb_0 <= R2;
					addra_0 <= 'd41 + ptr;
					addrb_0 <= 'd41 + ptr + 'd1;
					dina_1 <= L4;
					dinb_1 <= R4;
					addra_1 <= 'd41 + ptr;
					addrb_1 <= 'd41 + ptr + 'd1;
				end
			endcase
		end
		else if (ptr >= 'd18 && ptr < 'd1042) begin
			if((ptr - 'd18) < 'd512) begin
				wea_S1 <= 1;
				web_S1 <= 1;
				wea_S3 <= 1;
				web_S3 <= 1;
				dina_S1 <= L1;
				dinb_S1 <= R1;
				dina_S3 <= L2;
				dinb_S3 <= R2;
				addra_S1 <= ptr - 'd18;
				addrb_S1 <= ptr - 'd17;
				addra_S3 <= ptr - 'd18;
				addrb_S3 <= ptr - 'd17;
				wea_S5 <= 1;
				web_S5 <= 1;
				wea_S7 <= 1;
				web_S7 <= 1;
				dina_S5 <= L3;
				dinb_S5 <= R3;
				dina_S7 <= L4;
				dinb_S7 <= R4;
				addra_S5 <= ptr - 'd18;
				addrb_S5 <= ptr - 'd17;
				addra_S7 <= ptr - 'd18;
				addrb_S7 <= ptr - 'd17;
			end 
			else begin			
				wea_S2 <= 1;
				web_S2 <= 1;			
				wea_S4 <= 1;
				web_S4 <= 1;
				dina_S2 <= L1;
				dinb_S2 <= R1;
				dina_S4 <= L2;
				dinb_S4 <= R2;
				addra_S2 <= ptr - 'd530;
				addrb_S2 <= ptr - 'd529;
				addra_S4 <= ptr - 'd530;
				addrb_S4 <= ptr - 'd529;			
				wea_S6 <= 1;
				web_S6 <= 1;			
				wea_S8 <= 1;
				web_S8 <= 1;
				dina_S6 <= L3;
				dinb_S6 <= R3;
				dina_S8 <= L4;
				dinb_S8 <= R4;
				addra_S6 <= ptr - 'd530;
				addrb_S6 <= ptr - 'd529;
				addra_S8 <= ptr - 'd530;
				addrb_S8 <= ptr - 'd529;
			end
		end
	end
	else if(state == P_XOR_SALT) begin
		if(mem_delay < 'd1) begin
			case (inst)
				0: begin
					addra_0 <= P_index;
					addrb_0 <= 7'd36 + P_index%'d4;
					addra_1 <= P_index;
					addrb_1 <= 7'd36 + P_index%'d4;
				end
				1: begin
					addra_0 <= 7'd41 + P_index;
					addrb_0 <= 7'd77 + P_index%'d4;
					addra_1 <= 7'd41 + P_index;
					addrb_1 <= 7'd77 + P_index%'d4;
				end
			endcase
		end
		else begin
			wea_0 <= 1;
			wea_1 <= 1;
			case (inst)
				0: begin 
					addra_0 <= P_index;
					addra_1 <= P_index;
				end
				1: begin
					addra_0 <= 'd41 + P_index;
					addra_1 <= 'd41 + P_index;
				end
			endcase
			dina_0 <= douta0 ^ doutb0;
			dina_1 <= douta1 ^ doutb1;
		end
	end
	else if(state == DONE) begin
		case (inst)
			0: begin
				wea_0 <= 1;
				web_0 <= 1;
				dina_0 <= L1;
				dinb_0 <= R1;
				addra_0 <= 'd0;
				addrb_0 <= 'd1;
				wea_1 <= 1;
				web_1 <= 1;
				dina_1 <= L3;
				dinb_1 <= R3;
				addra_1 <= 'd0;
				addrb_1 <= 'd1;
			end
			1: begin		
				wea_0 <= 1;
				web_0 <= 1;
				dina_0 <= L2;
				dinb_0 <= R2;
				addra_0 <= 'd41;
				addrb_0 <= 'd42;		
				wea_1 <= 1;
				web_1 <= 1;
				dina_1 <= L4;
				dinb_1 <= R4;
				addra_1 <= 'd41;
				addrb_1 <= 'd42;
			end
		endcase
	end
end

always @ (posedge clk)
begin
	if (start == 2'b11) begin
		if(state == INIT) begin
			if(init_index < 'd512) begin
				if(mem_delay < 'd1) begin
					mem_delay <= mem_delay + 'd1;
				end
				else begin
					mem_delay <= 0;
					init_index <= init_index + 'd2;
				end
			end
			else begin
				if(mem_delay < 'd1) begin
					mem_delay <= mem_delay + 'd1;
				end
				else begin
					count <= douta0;
					init_index <= 0;
					mem_delay <= 0;
					state <= SET;
				end
			end
		end
		else if(state == SET) begin
			count <= 'd1 << count;
			L1 <= 0;
			L2 <= 0;
			L3 <= 0;
			L4 <= 0;
			R1 <= 0;
			R2 <= 0;
			R3 <= 0;
			R4 <= 0;
			ptr <= 0;
			which_xor <= 0;
			state <= XOR_SALT;
		end
		else if(state == XOR_SALT) begin
			if(ptr < 'd18) begin
				if(mem_delay < 'd1) begin
					mem_delay <= mem_delay + 'd1;
				end
				else begin
					mem_delay <= 0;
					if(inst == 0) begin
						L1 <= L1 ^ douta0;
						R1 <= R1 ^ doutb0;
						L3 <= L3 ^ douta1;
						R3 <= R3 ^ doutb1;
						inst <= 1;
					end
					else begin
						L2 <= L2 ^ douta0;
						R2 <= R2 ^ doutb0;
						L4 <= L4 ^ douta1;
						R4 <= R4 ^ doutb1;
						inst <= 0;
						state <= ENCRYPT_INIT;
					end
				end
			end
			else begin
				if(mem_delay < 'd1) begin
					mem_delay <= mem_delay + 'd1;
				end
				else begin
					mem_delay <= 0;
					if(inst == 0) begin
						L1 <= L1 ^ douta0;
						R1 <= R1 ^ doutb0;
						L3 <= L3 ^ douta1;
						R3 <= R3 ^ doutb1;
						inst <= 1;
					end
					else begin
						L2 <= L2 ^ douta0;
						R2 <= R2 ^ doutb0;
						L4 <= L4 ^ douta1;
						R4 <= R4 ^ doutb1;
						inst <= 0;
						which_xor <= ~which_xor;
						state <= ENCRYPT_INIT;
					end
				end
			end
		end
		else if(state == P_XOR_EXP) begin
			if(P_index < 5'd18) begin
				if(mem_delay < 'd1) begin
					mem_delay <= mem_delay + 'd1;
				end
				else begin
					P_index <= P_index + 5'd1;
					mem_delay <= 0;
				end
			end
			else begin
				P_index <= 5'd0;
				if(inst == 0) begin
					inst <= 1;
				end
				else begin
					inst <= 0;
					L1 <= 0;
					L2 <= 0;
					L3 <= 0;
					L4 <= 0;
					R1 <= 0;
					R2 <= 0;
					R3 <= 0;
					R4 <= 0;
					state <= ENCRYPT_INIT;
					ptr <= 0;
				end
			end
		end
		else if(state == ENCRYPT_INIT) begin
			if(mem_delay < 'd1) begin
				mem_delay <= mem_delay + 'd1;
			end
			else begin
				mem_delay <= 3'd0;
				L1 <= L1 ^ douta0;
				L2 <= L2 ^ doutb0;
				L3 <= L3 ^ douta1;
				L4 <= L4 ^ doutb1;
				state <= FEISTEL;
			end
		end
		else if(state == FEISTEL) begin
			if(ROUND_index < 16) begin
				if(ROUND_index == 15) begin
					R1 <= (R1 ^ douta0) ^ (((doutaS1 + doutbS1) ^ doutaS2) + doutbS2);
					R2 <= (R2 ^ doutb0) ^ (((doutaS3 + doutbS3) ^ doutaS4) + doutbS4);
					R3 <= (R3 ^ douta1) ^ (((doutaS5 + doutbS5) ^ doutaS6) + doutbS6);
					R4 <= (R4 ^ doutb1) ^ (((doutaS7 + doutbS7) ^ doutaS8) + doutbS8);
				end
				else begin
					L1 <= (R1 ^ douta0) ^ (((doutaS1 + doutbS1) ^ doutaS2) + doutbS2);
					L2 <= (R2 ^ doutb0) ^ (((doutaS3 + doutbS3) ^ doutaS4) + doutbS4);
					R1 <= L1;
					R2 <= L2;
					L3 <= (R3 ^ douta1) ^ (((doutaS5 + doutbS5) ^ doutaS6) + doutbS6);
					L4 <= (R4 ^ doutb1) ^ (((doutaS7 + doutbS7) ^ doutaS8) + doutbS8);
					R3 <= L3;
					R4 <= L4;
				end
				ROUND_index <= ROUND_index + 5'd1;
			end
			else begin
				L1 <= L1 ^ douta0;
				L2 <= L2 ^ doutb0;
				L3 <= L3 ^ douta1;
				L4 <= L4 ^ doutb1;
				mem_delay <= 0;
				ROUND_index <= 5'd0;
				if(enc_final == 0)
					state <= STORE_L_R;
				else
					state <= FINAL;
			end
		end
		else if(state == STORE_L_R) begin
			if(ptr < 'd1042) begin
				if(ptr < 'd18) begin
					if (inst == 0) begin
						inst <= 1;
					end
					else begin
						ptr <= ptr + 'd2;
						if(prep == 1)
							state <= XOR_SALT;
						else
							state <= ENCRYPT_INIT;
						inst <= 0;
					end
				end
				else begin
					ptr <= ptr + 'd2;
					if(prep == 1)
						state <= XOR_SALT;
					else
						state <= ENCRYPT_INIT;
				end
			end
			else begin
				if(prep == 1) begin
					state <= P_XOR_EXP;
					prep <= 0;
				end
				else begin
					if(first_or_second == 0) begin
						ptr <= 0;
						P_or_S <= 0;
						first_or_second <= 'b1;
						state <= P_XOR_SALT;
					end
					else begin
						first_or_second <= 'b0;
						state <= LOOP;
						ptr <= 0;
						P_or_S <= 0;
					end
				end
			end	
		end		
		else if(state == P_XOR_SALT) begin
			if(P_index < 5'd18) begin
				if(mem_delay < 'd1) begin
					mem_delay <= mem_delay + 'd1;
				end
				else begin
					P_index <= P_index + 5'd1;
					mem_delay <= 0;
				end
			end
			else begin
				P_index <= 5'd0;
				if(inst == 0) begin
					inst <= 1;
				end
				else begin
					inst <= 0;
					L1 <= 0;
					L2 <= 0;
					L3 <= 0;
					L4 <= 0;
					R1 <= 0;
					R2 <= 0;
					R3 <= 0;
					R4 <= 0;
					state <= ENCRYPT_INIT;
				end
			end
		end
		else if(state == LOOP) begin
			if(count > 1) begin
				count <= count - 32'd1;
				state <= P_XOR_EXP;
			end
			else begin
				state <= FINAL;
				enc_final <= 1;
				count <= 32'd64;
				L1 <= 32'h4F727068;
				L2 <= 32'h4F727068;
				R1 <= 32'h65616E42;
				R2 <= 32'h65616E42;
				L3 <= 32'h4F727068;
				L4 <= 32'h4F727068;
				R3 <= 32'h65616E42;
				R4 <= 32'h65616E42;
			end
		end
		else if(state == FINAL) begin
			if(count > 0) begin
				count <= count - 32'd1;
				state <= ENCRYPT_INIT;
			end
			else begin
				state <= DONE;
				enc_final <= 0;
				prep <= 1;
			end
		end
		else if(state == DONE) begin
			if(inst == 0) begin
				inst <= 1;
			end
			else begin
				inst <= 0;
				done_reg <= 2'b11;
			end
		end	
	end
	else begin
		count <= 0;
		state <= INIT;
		init_index <= 0;
		done_reg <= 0;
		enc_final <= 0;
	end
end

endmodule