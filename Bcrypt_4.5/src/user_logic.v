/*
 * This file is part of John the Ripper password cracker,
 * Copyright (c) 2014 by Katja Malvoni <kmalvoni at gmail dot com>
 * It is hereby released to the general public under the following terms:
 * Redistribution and use in source and binary forms, 
 * with or without modification, are permitted.
 */

module user_logic
(
  Bus2IP_Clk,                     // Bus to IP clock
  Bus2IP_Resetn,                  // Bus to IP reset
  Bus2IP_Addr,                    // Bus to IP address bus
  Bus2IP_CS,                      // Bus to IP chip select for user logic memory selection
  Bus2IP_RNW,                     // Bus to IP read/not write
  Bus2IP_Data,                    // Bus to IP data bus
  Bus2IP_BE,                      // Bus to IP byte enables
  Bus2IP_RdCE,                    // Bus to IP read chip enable
  Bus2IP_WrCE,                    // Bus to IP write chip enable
  Bus2IP_Burst,                   // Bus to IP burst-mode qualifier
  Bus2IP_BurstLength,             // Bus to IP burst length
  Bus2IP_RdReq,                   // Bus to IP read request
  Bus2IP_WrReq,                   // Bus to IP write request
  Type_of_xfer,                   // Transfer Type
  IP2Bus_AddrAck,                 // IP to Bus address acknowledgement
  IP2Bus_Data,                    // IP to Bus data bus
  IP2Bus_RdAck,                   // IP to Bus read transfer acknowledgement
  IP2Bus_WrAck,                   // IP to Bus write transfer acknowledgement
  IP2Bus_Error                    // IP to Bus error response ------------------
);

parameter C_SLV_AWIDTH                   = 32;
parameter C_SLV_DWIDTH                   = 32;
parameter C_NUM_MEM                      = 3;
parameter NUM_CORES			  = 28;

input                                     Bus2IP_Clk;
input                                     Bus2IP_Resetn;
input      [C_SLV_AWIDTH-1 : 0]           Bus2IP_Addr;
input      [C_NUM_MEM-1 : 0]              Bus2IP_CS;
input                                     Bus2IP_RNW;
input      [C_SLV_DWIDTH-1 : 0]           Bus2IP_Data;
input      [C_SLV_DWIDTH/8-1 : 0]         Bus2IP_BE;
input      [C_NUM_MEM-1 : 0]              Bus2IP_RdCE;
input      [C_NUM_MEM-1 : 0]              Bus2IP_WrCE;
input                                     Bus2IP_Burst;
input      [7 : 0]                        Bus2IP_BurstLength;
input                                     Bus2IP_RdReq;
input                                     Bus2IP_WrReq;
output                                    Type_of_xfer;
output                                    IP2Bus_AddrAck;
output     [C_SLV_DWIDTH-1 : 0]           IP2Bus_Data;
output                                    IP2Bus_RdAck;
output                                    IP2Bus_WrAck;
output                                    IP2Bus_Error;

parameter NUM_BYTE_LANES = (C_SLV_DWIDTH+7)/8;
reg [9 : 0] mem_address_o [NUM_CORES : 0];
wire [C_NUM_MEM - 1 : 0] mem_select;
wire [C_NUM_MEM - 1 : 0] mem_read_enable;
reg  [C_SLV_DWIDTH-1 : 0] mem_ip2bus_data;
reg [C_NUM_MEM - 1 : 0] mem_read_ack_dly1;
reg [C_NUM_MEM - 1 : 0] mem_read_ack_dly2; 
wire[C_NUM_MEM - 1 : 0]  mem_read_ack; 
wire [C_NUM_MEM - 1 : 0] mem_write_ack; 
reg [NUM_BYTE_LANES-1 : 0] write_enable [C_NUM_MEM - 1 : 0];
reg [C_SLV_DWIDTH-1 : 0] data_in [C_NUM_MEM-1 : 0];

reg [C_SLV_DWIDTH-1 : 0] mem_handshake [1 : 0];
wire [NUM_CORES : 0] wea_o;
wire [NUM_CORES : 0] wea_PL_o;
reg [NUM_CORES : 0] wea_PS_o;
wire [NUM_CORES : 0] web_o;
wire [9:0] addra_o [NUM_CORES : 0];
wire [9:0] addra_PL_o [NUM_CORES : 0];
wire [9:0] addrb_o [NUM_CORES : 0];
wire [31:0] dina_o [NUM_CORES : 0];
reg [31:0] dina_PS_o [NUM_CORES : 0];
wire [31:0] dina_PL_o [NUM_CORES : 0];
wire [31:0] dinb_o [NUM_CORES : 0];
wire [31:0] douta_o [NUM_CORES : 0];
reg [31:0] douta_PL;
wire [31:0] doutb_o [NUM_CORES : 0];
reg [NUM_CORES - 1 : 0] start = 0;
wire [NUM_CORES - 1 : 0] bcrypt_done;
reg [NUM_CORES - 1 : 0] done = 0;

wire [6 : 0] core_select_others;

integer i;
integer byte_index;

assign mem_select = Bus2IP_CS;
assign mem_read_enable = Bus2IP_RdCE;
assign mem_read_ack = (mem_read_ack_dly1 && (!mem_read_ack_dly2));
assign mem_write_ack = Bus2IP_WrCE;
assign core_select_others = (mem_select == 'd2) ? Bus2IP_Addr[15 : 9] : 0;

genvar t;
generate
	for(t=1;t<=NUM_CORES;t=t+1) begin : control
		assign wea_o[t] = (start[t - 1] == 1) ? wea_PL_o[t] : wea_PS_o[t];
		assign addra_o[t] = (start[t - 1] == 1) ? addra_PL_o[t] : mem_address_o[t];
		assign dina_o[t] = (start[t - 1] == 1) ? dina_PL_o[t] : dina_PS_o[t];
	end
endgenerate

assign douta_o[0] = douta_PL;

generate
	for(t=1;t<=NUM_CORES;t=t+2) begin : inst_bcrypt
		ram_initialized #(32, 10, 0) mem_other0 (Bus2IP_Clk, wea_o[t], addra_o[t], dina_o[t], douta_o[t], 
						Bus2IP_Clk, web_o[t], addrb_o[t], dinb_o[t], doutb_o[t]);
		ram_initialized #(32, 10, 1) mem_other1 (Bus2IP_Clk, wea_o[t+1], addra_o[t+1], dina_o[t+1], douta_o[t+1],
						Bus2IP_Clk, web_o[t+1], addrb_o[t+1], dinb_o[t+1], doutb_o[t+1]);
		bcrypt_loop bcrypt (Bus2IP_Clk, wea_PL_o[t], web_o[t], addra_PL_o[t], addrb_o[t], dina_PL_o[t], dinb_o[t], 
					douta_o[t], doutb_o[t], wea_PL_o[t+1], web_o[t+1], addra_PL_o[t+1], addrb_o[t+1], 
					dina_PL_o[t+1], dinb_o[t+1], douta_o[t+1], doutb_o[t+1], start[t:t-1], bcrypt_done[t:t-1]);
	end
endgenerate

generate
	for(t=0;t<NUM_CORES;t=t+1) begin : check_done			
		always @(posedge Bus2IP_Clk)
		begin
			if(bcrypt_done[t] == 1) begin
				done[t] <= 1;
			end
			if(mem_handshake[0] == 'd0) begin
				done[t] <= 0;
			end
		end
	end
endgenerate

generate
	for(t=0;t<NUM_CORES;t=t+1) begin : start_cores	
		always @(posedge Bus2IP_Clk) 
		begin
			if(mem_handshake[0] == 1 && (done[t] != 'd1))begin
				start[t] <= 1;
			end
			else begin
				start[t] <= 0;
			end
		end
	end
endgenerate

always @(posedge Bus2IP_Clk)
begin
	if(Bus2IP_Resetn == 0) begin
		mem_read_ack_dly1 <= 0;
		mem_read_ack_dly2 <= 0;
	end
	else begin
		mem_read_ack_dly1 <= mem_read_enable;
		mem_read_ack_dly2 <= mem_read_ack_dly1;
	end
end

always @(*) 
begin
	for (i=0;i<=C_NUM_MEM-1;i=i+1) begin
		for (byte_index=0;byte_index<=NUM_BYTE_LANES-1;byte_index=byte_index+1) begin
			write_enable[i][byte_index] <= Bus2IP_WrCE[i] && Bus2IP_BE[byte_index];
			data_in[i][(byte_index*8) +: 8] <= Bus2IP_Data[(byte_index*8) +: 8];
		end
	end
end

always @(posedge Bus2IP_Clk) 
begin
	if(mem_address_o[0] == 'd0) begin
		if(write_enable[0][0] == 1) begin 
			mem_handshake[mem_address_o[0]] <= dina_PS_o[0];
			douta_PL <= dina_PS_o[0];
			mem_handshake[1] <= 0;
		end
		else begin
			douta_PL <= mem_handshake[0];
		end
	end
	else if(mem_address_o[0] == 'd1) begin
		douta_PL <= mem_handshake[1];
	end
	
	if(done == 28'hFFFFFFF) begin
		mem_handshake[0] <= 0;
		mem_handshake[1] <= 32'hFF;
	end
end

always @(*)
begin
	for (i=0;i<=NUM_CORES;i=i+1) begin
		mem_address_o[i] <= 0;
	end
	case(mem_select)
		1: mem_address_o[0] <= Bus2IP_Addr[11:2];
		2: begin
			case(core_select_others)
				0: mem_address_o[1] <= Bus2IP_Addr[8:2];
				1: mem_address_o[2] <= Bus2IP_Addr[8:2];
				2: mem_address_o[3] <= Bus2IP_Addr[8:2];
				3: mem_address_o[4] <= Bus2IP_Addr[8:2];
				4: mem_address_o[5] <= Bus2IP_Addr[8:2];
				5: mem_address_o[6] <= Bus2IP_Addr[8:2];
				6: mem_address_o[7] <= Bus2IP_Addr[8:2];
				7: mem_address_o[8] <= Bus2IP_Addr[8:2];
				8: mem_address_o[9] <= Bus2IP_Addr[8:2];
				9: mem_address_o[10] <= Bus2IP_Addr[8:2];
				10: mem_address_o[11] <= Bus2IP_Addr[8:2];
				11: mem_address_o[12] <= Bus2IP_Addr[8:2];
				12: mem_address_o[13] <= Bus2IP_Addr[8:2];
				13: mem_address_o[14] <= Bus2IP_Addr[8:2];
				14: mem_address_o[15] <= Bus2IP_Addr[8:2];
				15: mem_address_o[16] <= Bus2IP_Addr[8:2];
				16: mem_address_o[17] <= Bus2IP_Addr[8:2];
				17: mem_address_o[18] <= Bus2IP_Addr[8:2];
				18: mem_address_o[19] <= Bus2IP_Addr[8:2];
				19: mem_address_o[20] <= Bus2IP_Addr[8:2];
				20: mem_address_o[21] <= Bus2IP_Addr[8:2];
				21: mem_address_o[22] <= Bus2IP_Addr[8:2];
				22: mem_address_o[23] <= Bus2IP_Addr[8:2];
				23: mem_address_o[24] <= Bus2IP_Addr[8:2];
				24: mem_address_o[25] <= Bus2IP_Addr[8:2];
				25: mem_address_o[26] <= Bus2IP_Addr[8:2];
				26: mem_address_o[27] <= Bus2IP_Addr[8:2];
				27: mem_address_o[28] <= Bus2IP_Addr[8:2];
			endcase
		end 
	endcase
end

always @(*)
begin
	for (i=0;i<=NUM_CORES;i=i+1) begin
		dina_PS_o[i] <= 0;
	end
	case(mem_select)
		1: dina_PS_o[0] <= data_in[0];
		2: begin
			case(core_select_others)
				0: dina_PS_o[1] <= data_in[1];
				1: dina_PS_o[2] <= data_in[1];
				2: dina_PS_o[3] <= data_in[1];
				3: dina_PS_o[4] <= data_in[1];
				4: dina_PS_o[5] <= data_in[1];
				5: dina_PS_o[6] <= data_in[1];
				6: dina_PS_o[7] <= data_in[1];
				7: dina_PS_o[8] <= data_in[1];
				8: dina_PS_o[9] <= data_in[1];
				9: dina_PS_o[10] <= data_in[1];
				10: dina_PS_o[11] <= data_in[1];
				11: dina_PS_o[12] <= data_in[1];
				12: dina_PS_o[13] <= data_in[1];
				13: dina_PS_o[14] <= data_in[1];
				14: dina_PS_o[15] <= data_in[1];
				15: dina_PS_o[16] <= data_in[1];
				16: dina_PS_o[17] <= data_in[1];
				17: dina_PS_o[18] <= data_in[1];
				18: dina_PS_o[19] <= data_in[1];
				19: dina_PS_o[20] <= data_in[1];
				20: dina_PS_o[21] <= data_in[1];
				21: dina_PS_o[22] <= data_in[1];
				22: dina_PS_o[23] <= data_in[1];
				23: dina_PS_o[24] <= data_in[1];
				24: dina_PS_o[25] <= data_in[1];
				25: dina_PS_o[26] <= data_in[1];
				26: dina_PS_o[27] <= data_in[1];
				27: dina_PS_o[28] <= data_in[1];
			endcase
		end 
	endcase
end

always @(*)
begin
	for (i=1;i<=NUM_CORES;i=i+1) begin
		wea_PS_o[i] <= 0;
	end
	case(mem_select)
		2: begin
			case(core_select_others)
				0: wea_PS_o[1] <= write_enable[1][0];
				1: wea_PS_o[2] <= write_enable[1][0];
				2: wea_PS_o[3] <= write_enable[1][0];
				3: wea_PS_o[4] <= write_enable[1][0];
				4: wea_PS_o[5] <= write_enable[1][0];
				5: wea_PS_o[6] <= write_enable[1][0];
				6: wea_PS_o[7] <= write_enable[1][0];
				7: wea_PS_o[8] <= write_enable[1][0];
				8: wea_PS_o[9] <= write_enable[1][0];
				9: wea_PS_o[10] <= write_enable[1][0];
				10: wea_PS_o[11] <= write_enable[1][0];
				11: wea_PS_o[12] <= write_enable[1][0];
				12: wea_PS_o[13] <= write_enable[1][0];
				13: wea_PS_o[14] <= write_enable[1][0];
				14: wea_PS_o[15] <= write_enable[1][0];
				15: wea_PS_o[16] <= write_enable[1][0];
				16: wea_PS_o[17] <= write_enable[1][0];
				17: wea_PS_o[18] <= write_enable[1][0];
				18: wea_PS_o[19] <= write_enable[1][0];
				19: wea_PS_o[20] <= write_enable[1][0];
				20: wea_PS_o[21] <= write_enable[1][0];
				21: wea_PS_o[22] <= write_enable[1][0];
				22: wea_PS_o[23] <= write_enable[1][0];
				23: wea_PS_o[24] <= write_enable[1][0];
				24: wea_PS_o[25] <= write_enable[1][0];
				25: wea_PS_o[26] <= write_enable[1][0];
				26: wea_PS_o[27] <= write_enable[1][0];
				27: wea_PS_o[28] <= write_enable[1][0];
			endcase
		end 
	endcase
end

always @(*)
begin
	case(mem_select)
		1 : mem_ip2bus_data <= douta_o[0];
		2: begin
			case(core_select_others)
				0: mem_ip2bus_data <= douta_o[1];
				1: mem_ip2bus_data <= douta_o[2];
				2: mem_ip2bus_data <= douta_o[3];
				3: mem_ip2bus_data <= douta_o[4];
				4: mem_ip2bus_data <= douta_o[5];
				5: mem_ip2bus_data <= douta_o[6];
				6: mem_ip2bus_data <= douta_o[7];
				7: mem_ip2bus_data <= douta_o[8];
				8: mem_ip2bus_data <= douta_o[9];
				9: mem_ip2bus_data <= douta_o[10];
				10: mem_ip2bus_data <= douta_o[11];
				11: mem_ip2bus_data <= douta_o[12];
				12: mem_ip2bus_data <= douta_o[13];
				13: mem_ip2bus_data <= douta_o[14];
				14: mem_ip2bus_data <= douta_o[15];
				15: mem_ip2bus_data <= douta_o[16];
				16: mem_ip2bus_data <= douta_o[17];
				17: mem_ip2bus_data <= douta_o[18];
				18: mem_ip2bus_data <= douta_o[19];
				19: mem_ip2bus_data <= douta_o[20];
				20: mem_ip2bus_data <= douta_o[21];
				21: mem_ip2bus_data <= douta_o[22];
				22: mem_ip2bus_data <= douta_o[23];
				23: mem_ip2bus_data <= douta_o[24];
				24: mem_ip2bus_data <= douta_o[25];
				25: mem_ip2bus_data <= douta_o[26];
				26: mem_ip2bus_data <= douta_o[27];
				27: mem_ip2bus_data <= douta_o[28];
			endcase
		end 
		default: mem_ip2bus_data <= 0;
	endcase
end

assign IP2Bus_Data  = (mem_read_ack[0] == 1'b1 || mem_read_ack[1] == 1'b1 || mem_read_ack[2] == 1'b1) ? mem_ip2bus_data : 0;
assign IP2Bus_AddrAck = ((mem_write_ack[0] == 1'b1 || mem_write_ack[1] == 1'b1 || mem_write_ack[2] == 1'b1) || 
		((mem_read_enable[0] == 1'b1 || mem_read_enable[1] == 1'b1 || mem_read_enable[2] == 1'b1) && 
		(mem_read_ack[0] == 1'b1 || mem_read_ack[1] == 1'b1 || mem_read_ack[2] == 1'b1)));
assign IP2Bus_WrAck = (mem_write_ack[0] == 1'b1 || mem_write_ack[1] == 1'b1 || mem_write_ack[2] == 1'b1);
assign IP2Bus_RdAck = (mem_read_ack[0] == 1'b1 || mem_read_ack[1] == 1'b1 || mem_read_ack[2] == 1'b1);
assign IP2Bus_Error = 0;

endmodule