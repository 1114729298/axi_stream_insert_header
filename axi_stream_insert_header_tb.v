`timescale 		1ns/1ns

module main_tb();
parameter DATA_WD = 32;
parameter DATA_BYTE_WD = DATA_WD / 8 ;
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD);

reg	clk		= 'd0;
reg	rst_n	= 'd0;
reg                        valid_insert;
reg   [DATA_WD-1 : 0]      data_insert;
reg   [DATA_BYTE_WD-1 : 0] keep_insert;
wire                       ready_insert;
reg   [BYTE_CNT_WD : 0]  byte_insert_cnt; 
reg                        valid_in;
reg   [DATA_WD-1 : 0]      data_in;
reg   [DATA_BYTE_WD-1 : 0] keep_in;
reg                        last_in;
wire                       ready_in;
wire                       valid_out;
wire  [DATA_WD-1 : 0]      data_out;
wire  [DATA_BYTE_WD-1 : 0] keep_out;
wire                       last_out;
reg                        ready_out;


task data_transfer;
	begin
		valid_in =1'b1;
		data_in = $random;
		keep_in = 4'hf;
		last_in =1'b0;
	end
endtask

task last_data_transfer;
	reg [BYTE_CNT_WD-1 : 0] data_keep_cnt;
	begin
		valid_in =1'b1;
		last_in = 1'b1;
		data_in = $random;
		data_keep_cnt = $urandom_range(0, DATA_BYTE_WD-1);
		keep_in = 4'hf << data_keep_cnt;
		@(posedge clk)
		valid_in =1'b0;
		last_in = 1'b0;
	end
endtask

task header_transfer;
	reg [BYTE_CNT_WD-1 : 0] header_keep_cnt;
    begin
		valid_insert =1'b1;
		data_insert = $random;
		header_keep_cnt = $urandom_range(0, DATA_BYTE_WD-1);
		keep_insert = 4'hf >> header_keep_cnt;
		byte_insert_cnt = DATA_BYTE_WD-header_keep_cnt;
	end
endtask


task test1;
	begin
		data_transfer;
		header_transfer;
		@(posedge clk)
		repeat (6)
		begin
			data_transfer;
			@(posedge clk);
		end
			last_data_transfer;
	end
endtask

task test2;
    begin
	    data_transfer;
		header_transfer;
		@(posedge clk)
		repeat (3)
		begin
			data_transfer;
			@(posedge clk);
		end
		ready_out = 1'b0;
		valid_in = 1'b0;
		@(posedge clk);
		ready_out = 1'b1;
		valid_in = 1'b1;
		@(posedge clk)
		repeat (3)
		begin
			data_transfer;
			@(posedge clk);
		end
			last_data_transfer;
	end

endtask

task test3;
    begin
	    data_transfer;
		header_transfer;
		@(posedge clk)
		repeat (3)
		begin
			data_transfer;
			@(posedge clk);
		end
		ready_out = 1'b0;
		repeat (8)@(posedge clk);
		ready_out = 1'b1;
		@(posedge clk)
		repeat (3)
		begin
			data_transfer;
			@(posedge clk);
		end
			last_data_transfer;
	end

endtask

initial 
begin
	clk		= 'd0;
	rst_n	= 'd1;
	ready_out =1'b1;
	@(posedge clk);
	rst_n = 'd0;
	repeat(2)@(posedge clk);
	rst_n = 'd1;
	test1;
	@(posedge clk);
	test2;
	@(posedge clk);
	test1;
	@(posedge clk);
	test3;
end

always #10 clk = ~clk;
//---------DUT-------------------
axi_stream_insert_header axi_u0(
	.clk			( clk			),
	.rst_n			( rst_n			),
	.valid_in		( valid_in		),
	.data_in		( data_in		),
	.keep_in		( keep_in		),
	.last_in		( last_in		),
	.ready_in		( ready_in		),
	.valid_out		( valid_out		),
	.data_out		( data_out		),
	.keep_out		( keep_out		),
	.last_out		( last_out		),
	.ready_out		( ready_out		),
	.valid_insert	( valid_insert	),
	.data_insert	( data_insert	),
	.byte_insert_cnt(byte_insert_cnt),
	.keep_insert	( keep_insert	),
	.ready_insert	( ready_insert	)
);
endmodule