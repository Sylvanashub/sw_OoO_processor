
module btb #(

   parameter   BTB_SIZE = 16

) (

    input   logic          clk
   ,input   logic          rst

   ,input   logic [31:0]   pc
   ,input   logic [31:0]   target
   ,input   logic          update

   ,input   logic          fetch
   ,input   logic [31:0]   fetch_pc
   ,output  logic [31:0]   predict_pc
   ,output  logic          predict_valid

);

localparam  AW = $clog2(BTB_SIZE) ;
localparam  DW = 30 + (30 - AW) ;
localparam  TAG_W = 30 - AW ;

logic [AW-1:0] sram_addr   ;
logic [DW-1:0] sram_din    ;
logic [DW-1:0] sram_dout   ;
logic          sram_csb    ;
logic          sram_web    ;

logic [TAG_W-1:0] pc_tag ;
logic [BTB_SIZE-1:0] valid ;
logic valid_out ;
logic [31:2] fetch_pc_r ;

always_comb
begin

   sram_addr   = update ? pc[2 +: AW] : fetch_pc[2 +: AW] ;
   sram_din    = {pc[31:2+AW],target[31:2]} ;

   sram_csb    = ~(update | fetch) ;
   sram_web    = ~update ;

   {pc_tag,predict_pc[31:2]}  = sram_dout ;
   predict_pc[1:0] = '0 ;

   predict_valid = valid_out && pc_tag == fetch_pc_r[31-:TAG_W] ;

end

btb_sram #(
    .ADDR_WIDTH ( AW )
   ,.DATA_WIDTH ( DW )
) u_btb_sram (

    .clk0   ( clk       )
   ,.csb0   ( sram_csb  )
   ,.web0   ( sram_web  )
   ,.addr0  ( sram_addr )
   ,.din0   ( sram_din  )
   ,.dout0  ( sram_dout )

);

always_ff@(posedge clk)
begin
   if( rst )
      valid <= '0 ;
   else if( update )
      valid[sram_addr] <= 1'H1 ;
end

always_ff@(posedge clk)
begin
   if( rst )
   begin
      valid_out <= '0 ;
      fetch_pc_r <= '0 ;
   end
   else if( fetch )
   begin
      valid_out <= valid[fetch_pc[2 +: AW]] ;
      fetch_pc_r <= fetch_pc[31:2] ;
   end
end

endmodule
