
module rvs 
#(

   parameter   DEPTH    = 32'D4 ,
   parameter   TAG_W    = 32'D4 ,
   parameter   OPC_W    = 32'D4 ,
   parameter   START_ID = 32'D1 ,
   parameter   PTR_W    = $clog2(DEPTH)
//   parameter   IS_LSU   = 32'H0

) (

    input   logic    clk
   ,input   logic    rst

   ,dec2rvs_itf.rvs  dec2rvs_itf

   ,rvs2exu_itf.rvs  rvs2exu_itf

   ,rvs2rob_itf.rvs  rvs2rob_itf
   
   ,cdb_itf.slv      cdb_itf

);

logic [DEPTH-1:0] vld1 ;
logic [DEPTH-1:0] vld2 ;

logic [OPC_W-1:0] opc [DEPTH] ;

logic [TAG_W-1:0] tag1 [DEPTH];
logic [TAG_W-1:0] tag2 [DEPTH];
logic [31:0]      src1 [DEPTH];
logic [31:0]      src2 [DEPTH];

//generate
//if( IS_LSU == 1 ) begin : GEN_OFFSET_DEF
logic [11:0]      offset [DEPTH] ;
//end
//endgenerate
logic [PTR_W:0]   wptr  ;
logic [PTR_W:0]   rptr  ;
logic             is_full  ;
logic             is_empty ;

logic rvs_wr_en   ;

assign rvs_wr_en = dec2rvs_itf.req && dec2rvs_itf.rdy ;

assign dec2rvs_itf.tag = {{(TAG_W-PTR_W){1'H0}},wptr[PTR_W-1:0]} + START_ID[TAG_W-1:0] ;

genvar i ;
generate
for(i=0;i<DEPTH;i++)
begin : item
   always_ff@(posedge clk)
   begin
      if( rst )
      begin
         vld1[i]  <= '0 ;
         vld2[i]  <= '0 ;
         tag1[i]  <= '0 ;
         tag2[i]  <= '0 ;
         src1[i]  <= '0 ;
         src2[i]  <= '0 ;
         opc[i]   <= '0 ;
      end
      else 
      begin

         if( cdb_itf.wr && cdb_itf.tag == tag1[i] )
         begin
            vld1[i]  <= '1 ;
            tag1[i]  <= '0 ;
            src1[i]  <= cdb_itf.wdata ;
         end
         else if( rvs_wr_en && wptr[PTR_W-1:0] == i[PTR_W-1:0] )
         begin
            vld1[i]  <= dec2rvs_itf.src1_vld ;
            tag1[i]  <= dec2rvs_itf.src1_tag ;
            src1[i]  <= dec2rvs_itf.src1_wdata ;
         end

         if( cdb_itf.wr && cdb_itf.tag == tag2[i] )
         begin
            vld2[i]  <= '1 ;
            tag2[i]  <= '0 ;
            src2[i]  <= cdb_itf.wdata ;
         end
         else if( rvs_wr_en && wptr[PTR_W-1:0] == i[PTR_W-1:0] )
         begin
            vld2[i]  <= dec2rvs_itf.src2_vld ;
            tag2[i]  <= dec2rvs_itf.src2_tag ;
            src2[i]  <= dec2rvs_itf.src2_wdata ;
         end

         if( rvs_wr_en && wptr[PTR_W-1:0] == i[PTR_W-1:0] )
         begin
            opc[i]   <= dec2rvs_itf.opc ;
            //if( IS_LSU == 1 ) begin : GEN_OFFSET
            offset[i]  <= dec2rvs_itf.offset ;
            //end
         end
      end
   end
end
endgenerate

//------------------------------------------------------------------------------
// pointer and status
//------------------------------------------------------------------------------

wire rvi_valid = vld1[rptr[PTR_W-1:0]] && vld2[rptr[PTR_W-1:0]] ;

always_ff@(posedge clk)
begin
   if( rst )
      wptr <= '0 ;
   else if( rvs_wr_en )
      wptr <= wptr + {{(PTR_W-1){1'H0}},1'H1} ;
end

always_ff@(posedge clk)
begin
   if( rst )
      rptr <= '0 ;
   else if( ~is_empty && rvs2exu_itf.rdy && rvi_valid )
      rptr <= rptr + {{(PTR_W-1){1'H0}},1'H1} ;
end

wire catch_up = wptr[PTR_W-1:0] == rptr[PTR_W-1:0] ;
wire extra_eq = wptr[PTR_W] == rptr[PTR_W] ;
assign is_full  = ~extra_eq && catch_up ;
assign is_empty = extra_eq && catch_up ;


assign rvs2rob_itf.tag = dec2rvs_itf.tag ;

//assign dec2rvs_itf.rdy = ~is_full && rvs2exu_itf.rdy ;
assign dec2rvs_itf.rdy = ~is_full && ~rvs2rob_itf.busy ;

assign rvs2exu_itf.req = ~is_empty && rvi_valid ;//&& exu_req ;
assign rvs2exu_itf.tag = {{(TAG_W-PTR_W){1'H0}},rptr[PTR_W-1:0]} + START_ID[TAG_W-1:0] ;
assign rvs2exu_itf.opc = opc[rptr[PTR_W-1:0]] ;
assign rvs2exu_itf.src1= src1[rptr[PTR_W-1:0]] ;
assign rvs2exu_itf.src2= src2[rptr[PTR_W-1:0]] ;
assign rvs2exu_itf.offset= offset[rptr[PTR_W-1:0]] ;

endmodule

