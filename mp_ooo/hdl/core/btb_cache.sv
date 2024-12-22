
module btb_cache (

    input   logic          clk
   ,input   logic          rst

   ,input   logic          rd
   ,input   logic          wr
   ,input   logic [31:0]   raddr
   ,input   logic [31:0]   waddr
   ,input   logic [31:0]   din
   ,output  logic [31:0]   dout
   ,output  logic          hit

);

localparam  CACHE_WAY_NUM  = 4   ;
localparam  CACHE_SET_NUM  = 16  ;

localparam  SET_W = $clog2(CACHE_SET_NUM);
localparam  TAG_W = 30 - SET_W ;

localparam  SET_START_BIT  = 2;
localparam  TAG_START_BIT  = SET_START_BIT + SET_W ;

//------------------------------------------------------------------------------
// TAG      SET
// 31:6     5:2
// 26       4
//------------------------------------------------------------------------------

logic [SET_W-1:0] raddr_set ;
logic [TAG_W-1:0] raddr_tag ;
logic [TAG_W-1:0] raddr_tag_r;
logic [SET_W-1:0] waddr_set ;
logic [TAG_W-1:0] waddr_tag ;

logic                      cache_line_rd_csb ;
logic [SET_W-1:0]          cache_line_rd_addr;
logic [31:0]               cache_data_dout [CACHE_WAY_NUM] ;
logic [TAG_W-1:0]          cache_tag_dout [CACHE_WAY_NUM] ;
logic [CACHE_WAY_NUM-1:0]  cache_valid_out ;
logic [CACHE_WAY_NUM-1:0]  cache_tag_match ;
logic [CACHE_WAY_NUM-1:0]  cache_hit ;

logic                      cache_line_wr_csb ;
logic [CACHE_WAY_NUM-1:0]  cache_line_wr_web ;
logic [SET_W-1:0]          cache_line_wr_addr;
logic [31:0]               cache_data_din ;
logic [TAG_W-1:0]          cache_tag_din  ;

always_ff@(posedge clk)
begin
   if( rst )
      raddr_tag_r <= '0;
   else if( rd )
      raddr_tag_r <= raddr_tag ;
end

always_comb
begin

   raddr_set = raddr[SET_START_BIT +: SET_W] ;
   raddr_tag = raddr[TAG_START_BIT +: TAG_W] ;

   waddr_set = waddr[SET_START_BIT +: SET_W] ;
   waddr_tag = waddr[TAG_START_BIT +: TAG_W] ;

   cache_line_rd_csb    = ~rd ;
   cache_line_rd_addr   = raddr_set ;
   

   cache_line_wr_csb    = ~wr ;
   cache_line_wr_addr   = waddr_set ;
   cache_data_din       = din ;
   cache_tag_din        = waddr_tag ;

   dout = ({32{cache_hit[0]}} & cache_data_dout[0]) |
          ({32{cache_hit[1]}} & cache_data_dout[1]) |
          ({32{cache_hit[2]}} & cache_data_dout[2]) |
          ({32{cache_hit[3]}} & cache_data_dout[3]) ;

   hit = |cache_hit ;
end



generate 
for(genvar i=0;i<CACHE_WAY_NUM;i++)begin:arrays
   dpsram #(
      .S_INDEX(4),
      .WIDTH(32)
   ) data_array(

      .clk0    (clk              ),
      .rst0    (rst              ),

      .csb0    (cache_line_rd_csb   ),
      .web0    ('1                  ),
      .addr0   (cache_line_rd_addr  ),
      .din0    ('0                  ),
      .dout0   (cache_data_dout[i]  ),

      .csb1    (cache_line_wr_csb   ),
      .web1    (cache_line_wr_web[i]),
      .addr1   (cache_line_wr_addr  ),
      .din1    (cache_data_din      ),
      .dout1   (  )

   );
   
   dpsram #(
      .S_INDEX(4),
      .WIDTH(TAG_W)
   )tag_array(

      .clk0    (clk              ),
      .rst0    (rst              ),

      .csb0    (cache_line_rd_csb   ),
      .web0    ('1                  ),
      .addr0   (cache_line_rd_addr  ),
      .din0    ('0                  ),
      .dout0   (cache_tag_dout[i]   ),

      .csb1    (cache_line_wr_csb   ),
      .web1    (cache_line_wr_web[i]),
      .addr1   (cache_line_wr_addr  ),
      .din1    (cache_tag_din       ),
      .dout1   ( )

   );
   
   valid_array valid_array(
      .clk0    (clk              ),
      .rst0    (rst              ),
      .csb0    (cache_line_wr_csb & cache_line_rd_csb ),
      .web0    (cache_line_wr_web[i]),
      .addr0   (wr ? cache_line_wr_addr:cache_line_rd_addr ),
      .din0    (1'H1             ),
      .dout0   (cache_valid_out[i])
   );

   assign cache_tag_match[i]  = cache_tag_dout[i] == raddr_tag_r ;
   assign cache_hit[i]        = cache_valid_out[i] && cache_tag_match[i] ;

   assign cache_line_wr_web[i]= ~(waddr[3:2] == i[1:0]) ; 

end
endgenerate


endmodule
