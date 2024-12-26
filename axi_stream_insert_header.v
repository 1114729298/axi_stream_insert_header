module axi_stream_insert_header #(
parameter DATA_WD = 32,
parameter DATA_BYTE_WD = DATA_WD / 8,
parameter BYTE_CNT_WD = $clog2(DATA_BYTE_WD)
) (
input clk,
input rst_n,
// AXI Stream input original data
input valid_in,
input [DATA_WD-1 : 0] data_in,
input [DATA_BYTE_WD-1 : 0] keep_in,
input last_in,
output ready_in,
// AXI Stream output with header inserted
output valid_out,
output [DATA_WD-1 : 0] data_out,
output [DATA_BYTE_WD-1 : 0] keep_out,
output last_out,
input ready_out,
// The header to be inserted to AXI Stream input
input valid_insert,
input [DATA_WD-1 : 0] data_insert,
input [DATA_BYTE_WD-1 : 0] keep_insert,
input [BYTE_CNT_WD : 0] byte_insert_cnt,
output ready_insert
);

reg [DATA_WD-1 : 0]        data_in_r;
reg [DATA_BYTE_WD-1 : 0]   keep_in_r;
reg                        last_in_r;
reg                        valid_in_r;
reg [DATA_WD-1 : 0]        data_insert_r;
reg [DATA_BYTE_WD-1 : 0]   keep_insert_r;
reg                        valid_insert_r;
reg                        last_out_r;
reg [DATA_BYTE_WD-1 : 0]   keep_o;
reg [2*DATA_WD-1 : 0]      data_o_1;
reg [2*DATA_WD-1 : 0]      data_o_2;
reg                        valid_out_r;
reg                        insert_flag;                      //插入标志信号，0表示未插入，1表示已插入
wire                       data_in_flag;
wire                       data_insert_flag;
assign data_in_flag=valid_in&&ready_in?1:0;
assign data_insert_flag=valid_insert&&ready_insert?1:0;
assign transfer_flag=data_insert_flag&&data_in_flag?1:0;
assign ready_in = ready_out || (~valid_in&&valid_in_r);
assign ready_insert = ready_out || (~valid_insert&&valid_insert_r);

////////////////////////////////////////////////////
//数据打拍
////////////////////////////////////////////////////
always@(posedge clk or negedge rst_n)
if(!rst_n)begin
     data_in_r<=0;
     keep_in_r<=0;
	 last_in_r<=0;
     end
else if(data_in_flag)begin
     data_in_r<=data_in;
     keep_in_r<=keep_in;
	 last_in_r<=last_in;
     end
else begin
     data_in_r<=data_in;
     keep_in_r<='b0;
	 last_in_r<='b0;
     end

always@(posedge clk or negedge rst_n)
if(!rst_n)begin
     data_insert_r<=0;
     keep_insert_r<=0;
     end
else if(data_insert_flag)begin
     data_insert_r<=data_insert;
     keep_insert_r<=keep_insert;
     end
else begin
     data_insert_r<=data_insert_r;
     keep_insert_r<=keep_insert_r;
     end

always@(posedge clk or negedge rst_n)
if(!rst_n)
     last_out_r<=1'b0;
else last_out_r<=last_in_r;
	 
always@(posedge clk or negedge rst_n)
if(!rst_n) begin
     valid_in_r<=1'b0;
	 valid_insert_r<=1'b0;
	 end
else begin 
     valid_in_r<=valid_in;
	 valid_insert_r<=valid_insert;
	 end
//////////////////////////////////////////////////////
//输出数据产生
//////////////////////////////////////////////////////            

always@(posedge clk or negedge rst_n)
if(!rst_n)begin
	 data_o_1<=32'b0;
	 data_o_2<=32'b0;
     end
else if(data_in_flag&&data_insert_flag&&~insert_flag)begin
     data_o_1={data_insert,data_in};
	 data_o_2=data_o_1<<(DATA_BYTE_WD-byte_insert_cnt)*8;
	 insert_flag=1'b1;
     end
else if(ready_in&&insert_flag)begin
     data_o_1={data_in_r,data_in};
	 data_o_2=data_o_1<<(DATA_BYTE_WD-byte_insert_cnt)*8;
     end 
else if(last_in_r)
     data_o_2<=data_o_2<<DATA_WD;
else data_o_2<=data_o_2;
	 
always@(posedge clk or negedge rst_n)
if(!rst_n)
    insert_flag<='b0;
else if(last_in)
    insert_flag<='b0;
else insert_flag<=insert_flag;

always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        keep_o<=4'b0;
    else if(!last_in_r)
        keep_o <= 4'b1111;
    else if(last_in_r) 
	keep_o <= keep_in<<(DATA_BYTE_WD-byte_insert_cnt);
 else;
end

//always@(posedge clk or negedge rst_n)
//if(!rst_n)
//    valid_out_r<='b0;
//else if(ready_in)
//    valid_out_r<=valid_in;
//else valid_out_r<='b0;

assign valid_out = ready_out? valid_in:valid_in_r;
//assign valid_out = valid_out_r;
assign data_out=data_o_2[2*DATA_WD-1 : DATA_WD];
assign keep_out=keep_o;
assign last_out=last_out_r;

endmodule

