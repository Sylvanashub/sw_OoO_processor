
module bpu #(

    parameter  PHT_DEPTH= 64

) (

    input   logic    clk
   ,input   logic    rst

   ,ifu2bpu_itf.bpu  ifu2bpu_itf
   ,jmp2bpu_itf.bpu  jmp2bpu_itf

);

localparam  PHT_AW   = $clog2(PHT_DEPTH);

logic [PHT_AW-1:0] ghr  ;

logic [1:0] pht_cnt [PHT_DEPTH] ;

//logic [PHT_AW-1:0] pht_addr ;
logic [PHT_AW-1:0] ifu_pht_pc ;
logic [PHT_AW-1:0] jmp_pht_pc ;

logic branch_commit ;

assign branch_commit = jmp2bpu_itf.execute && ~jmp2bpu_itf.opc[3] ;

//------------------------------------------------------------------------------
// GHR
//------------------------------------------------------------------------------
always_ff@(posedge clk)
begin
   if( rst )
      ghr <= '0 ;
   //else if( jmp2bpu_itf.execute )
   else if( branch_commit  )
      ghr <= {ghr[PHT_AW-2:0],1'H0};//jmp2bpu_itf.execute_taken} ;
end


//------------------------------------------------------------------------------
// PHT
//------------------------------------------------------------------------------

assign ifu_pht_pc = ifu2bpu_itf.fetch_pc[2+:PHT_AW] ^ ghr ;
assign jmp_pht_pc = jmp2bpu_itf.execute_pc[2+:PHT_AW] ^ ghr ;

//assign pht_addr = jmp2bpu_itf.execute ? jmp_pht_pc^ghr : ifu_pht_pc^ghr ;
//assign pht_addr = branch_commit ? jmp_pht_pc : ifu_pht_pc ;

generate
for(genvar i=0;i<PHT_DEPTH;i++)
begin : pht

   always_ff@(posedge clk)
   begin
      if( rst )
      begin
         pht_cnt[i] <= '0 ;
      end
      //else if( jmp2bpu_itf.execute && i[PHT_AW-1:0] == pht_addr )
      else if( branch_commit && i[PHT_AW-1:0] == jmp_pht_pc )
      begin
         if( jmp2bpu_itf.execute_taken )
         begin
            if( pht_cnt[i] != 2'H3 )
               pht_cnt[i] <= pht_cnt[i] + 2'H1 ;
         end
         else
         begin
            if( pht_cnt[i] != 2'H0 )
               pht_cnt[i] <= pht_cnt[i] - 2'H1 ;
         end
      end
   end

end

endgenerate

always_ff@(posedge clk)
begin
   if( rst )
      ifu2bpu_itf.predict_taken <= '0 ;
   else if( ifu2bpu_itf.fetch )
      ifu2bpu_itf.predict_taken <= pht_cnt[ifu_pht_pc][1] ;
   //else   
   //   ifu2bpu_itf.predict_taken <= '0 ;
end

//------------------------------------------------------------------------------
// BTB
//------------------------------------------------------------------------------

localparam  SPLIT_JAL_BTB = 0 ;
generate
if( SPLIT_JAL_BTB == 0 )
begin : unique_btb

   btb #(
      .BTB_SIZE ( 16 ) 
   ) u_btb (
      .*
   
      //update 
      ,.pc           ( jmp2bpu_itf.execute_pc      )
      ,.target       ( jmp2bpu_itf.execute_target  )
      ,.update       ( jmp2bpu_itf.update          )
   
      //read
      ,.fetch        ( ifu2bpu_itf.fetch           )
      ,.fetch_pc     ( ifu2bpu_itf.fetch_pc        )
      ,.predict_pc   ( ifu2bpu_itf.predict_pc      )
      ,.predict_valid( ifu2bpu_itf.predict_valid   )
   );

end
else
begin : split_btb

   logic  [31:0] br_predict_pc ;
   logic         br_predict_valid ;
   logic  [31:0] jal_predict_pc ;
   logic         jal_predict_valid ;
   
   btb #(
      .BTB_SIZE ( 64 ) 
   ) u_br_btb (
      .*
   
      //update 
      ,.pc           ( jmp2bpu_itf.execute_pc      )
      ,.target       ( jmp2bpu_itf.execute_target  )
      ,.update       ( jmp2bpu_itf.update && ~jmp2bpu_itf.opc[3]         )
   
      //read
      ,.fetch        ( ifu2bpu_itf.fetch           )
      ,.fetch_pc     ( ifu2bpu_itf.fetch_pc        )
      ,.predict_pc   ( br_predict_pc      )
      ,.predict_valid( br_predict_valid   )
   );
   
   btb #(
      .BTB_SIZE ( 64 ) 
   ) u_jal_btb (
      .*
   
      //update 
      ,.pc           ( jmp2bpu_itf.execute_pc      )
      ,.target       ( jmp2bpu_itf.execute_target  )
      ,.update       ( jmp2bpu_itf.update && jmp2bpu_itf.opc[3]          )
   
      //read
      ,.fetch        ( ifu2bpu_itf.fetch           )
      ,.fetch_pc     ( ifu2bpu_itf.fetch_pc        )
      ,.predict_pc   ( jal_predict_pc      )
      ,.predict_valid( jal_predict_valid   )
   );
   
   assign ifu2bpu_itf.predict_valid = jal_predict_valid | br_predict_valid ;
   assign ifu2bpu_itf.predict_pc = jal_predict_valid ? jal_predict_pc : br_predict_pc ;

end
endgenerate

endmodule
