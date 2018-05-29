/*
* This file is part of John the Ripper password cracker,
* Copyright (c) 2013 by Katja Malvoni <kmalvoni at gmail dot com>
* It is hereby released to the general public under the following terms:
* Redistribution and use in source and binary forms,
* with or without modification, are permitted.
*/

(* RAM_STYLE="{auto | block}" *)
module ram_initialized #(parameter DATA_WIDTH=32, parameter ADDR_WIDTH=9, parameter WHICH=1)
(
        input clka,
        input wea,
        input [ADDR_WIDTH - 1 : 0] addra,
        input [DATA_WIDTH - 1 : 0] dina,
        output reg [DATA_WIDTH - 1 : 0] douta,
        input clkb,
        input web,
        input [ADDR_WIDTH - 1 : 0] addrb,
        input [DATA_WIDTH - 1 : 0] dinb,
        output reg [DATA_WIDTH - 1 : 0] doutb
);

        reg [DATA_WIDTH - 1 : 0] mem [2**ADDR_WIDTH - 1 : 0];
        
        initial begin
        	if(WHICH == 0) 
			$readmemh("others_half1.mif", mem, 0, 2**ADDR_WIDTH - 1);
		else
			$readmemh("others_half2.mif", mem, 0, 2**ADDR_WIDTH - 1);
        end
        
        always @ (posedge clka) begin
                if (wea) begin
                        mem[addra] <= dina;
                        douta <= dina;
                end
                else begin
                        douta <= mem[addra];
                end
        end

        always @ (posedge clkb) begin
                if(web) begin
                        mem[addrb] <= dinb;
                        doutb <= dinb;
                end
                else begin
                        doutb <= mem[addrb];
                end
        end

endmodule