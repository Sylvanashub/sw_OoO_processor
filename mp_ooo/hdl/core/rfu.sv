
module rfu #(

   parameter   TAG_W = 32'D4

) (

    input   logic                clk
   ,input   logic                rst

   ,dec2rfu_itf.rfu              dec2rfu_itf
   ,cdb_itf.slv                  cdb_itf

);

logic [31:0]      busy     ;
logic [TAG_W-1:0] tag [32] ;
logic [31:0]      mem [32]  ;
wire _x = |cdb_itf.inst_id ;
//assign busy[0] = '0 ;
//assign tag[0]  = '0 ;
//assign mem[0]  = '0 ;

//logic [31:1] rx_tag_match  ;
//
//assign dec2rfu_itf.rd_busy = (|dec2rfu_itf.rd_tag) && (|rx_tag_match) ;

genvar i ;
generate
for(i=0;i<32;i++)
begin : rf

   if( i == 0 )
   begin : reg0
      always@(posedge clk)
      begin
         if( rst )
         begin
            mem[i]    <= '0 ;
            busy[i]  <= '0 ;
            tag[i]   <= '0 ;
         end
      end
   end
   else
   begin : reg1_31

      always@(posedge clk)
      begin
         if( rst )
         begin
            mem[i]    <= '0 ;
            busy[i]  <= '0 ;
            tag[i]   <= '0 ;
         end
         else if( dec2rfu_itf.rd_wr && dec2rfu_itf.rd_addr == i[4:0] )
         begin
            busy[i] <= '1 ;
            tag[i]  <= dec2rfu_itf.rd_tag ;
         end
         else if( cdb_itf.wr && cdb_itf.tag == tag[i] )
         begin
            mem[i]   <= cdb_itf.wdata ;
            busy[i]  <= '0 ;
            tag[i]   <= '0 ;
         end
      end

   end

   //assign rx_tag_match[i] = tag[i] == dec2rfu_itf.rd_tag ;

end
endgenerate

logic [TAG_W-1:0] rs1_tag ;
logic [TAG_W-1:0] rs2_tag ;
logic             rs1_busy ;
logic             rs2_busy ;
logic [31:0]      rs1_rdata ;
logic [31:0]      rs2_rdata ;

logic             rs1_cdb_vld ;
logic             rs2_cdb_vld ;

assign rs1_rdata = mem[dec2rfu_itf.rs1_addr] ;
assign rs1_busy  = busy[dec2rfu_itf.rs1_addr] ;
assign rs1_tag   = tag[dec2rfu_itf.rs1_addr] ;

assign rs2_rdata = mem[dec2rfu_itf.rs2_addr] ;
assign rs2_busy  = busy[dec2rfu_itf.rs2_addr] ;
assign rs2_tag   = tag[dec2rfu_itf.rs2_addr] ;

assign rs1_cdb_vld = cdb_itf.wr && cdb_itf.tag == rs1_tag ;
assign rs2_cdb_vld = cdb_itf.wr && cdb_itf.tag == rs2_tag ;

assign dec2rfu_itf.rs1_rdata = rs1_cdb_vld ? cdb_itf.wdata  : rs1_rdata ;
assign dec2rfu_itf.rs1_busy  = rs1_cdb_vld ? 1'H0           : rs1_busy  ;
assign dec2rfu_itf.rs1_tag   = rs1_cdb_vld ? '0             : rs1_tag   ;

assign dec2rfu_itf.rs2_rdata = rs2_cdb_vld ? cdb_itf.wdata  : rs2_rdata ;
assign dec2rfu_itf.rs2_busy  = rs2_cdb_vld ? 1'H0           : rs2_busy  ;
assign dec2rfu_itf.rs2_tag   = rs2_cdb_vld ? '0             : rs2_tag   ;

endmodule
