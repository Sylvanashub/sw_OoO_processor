module rob_performance 
import rv32i_types::* ;
(

    input   logic clk
   ,input   logic rst
   
   ,input   logic          mon_valid
   ,input   logic [31:0]   mon_inst
   ,input   logic [63:0]   mon_order
   ,input   logic          flush

);

//------------------------------------------------------------------------------
// Instruction cycle counter
//------------------------------------------------------------------------------
int   iJalCnt     ;
int   iJalrCnt    ;
int   iBrCnt      ;
int   iStoreCnt   ;
int   iLoadCnt    ;
int   iCycleCnt   ;
int   iOtherCnt   ;
int   iFlushCnt   ;


int   iInstJalCnt     ;
int   iInstJalrCnt    ;
int   iInstBrCnt      ;
int   iInstStoreCnt   ;
int   iInstLoadCnt    ;
int   iInstOtherCnt  ;


rv32i_opcode oOpCode ;
rv32i_opcode oCurOpCode ;

logic is_flush ;

assign oCurOpCode = rv32i_opcode'(mon_inst[6:0]) ;

initial
begin
   iJalCnt   = '0 ;
   iJalrCnt  = '0 ;
   iBrCnt    = '0 ;
   iStoreCnt = '0 ;
   iLoadCnt  = '0 ;
   iCycleCnt = '0 ;
   iFlushCnt = '0 ;

iInstJalCnt  = '0 ;
iInstJalrCnt = '0 ;
iInstBrCnt   = '0 ;
iInstStoreCnt= '0 ;
iInstLoadCnt = '0 ;
iOtherCnt = '0 ;
iInstOtherCnt = '0 ;
is_flush = '0 ;
end

always@(negedge clk iff !rst)
begin
   if( mon_valid )
   begin
      is_flush <= flush ;
      oOpCode <= rv32i_opcode'(mon_inst[6:0]) ;
      case( oOpCode )
      op_b_jal    : iInstJalCnt++ ;
      op_b_jalr   : iInstJalrCnt++ ;
      op_b_br     : iInstBrCnt++ ;
      op_b_store  : iInstStoreCnt++ ;
      op_b_load   : iInstLoadCnt++  ;
      endcase
   end

   iCycleCnt++ ;

   if( flush )
      iFlushCnt++ ;
end

always@(negedge clk iff !rst)
begin
   if( mon_valid )
   begin
      case( oCurOpCode )
      op_b_jal    : iJalCnt++ ;
      op_b_jalr   : iJalrCnt++ ;
      op_b_br     : iBrCnt++ ;
      endcase
   end
   else if( is_flush )
   begin
      case( oOpCode )
      op_b_jal    : iJalCnt++ ;
      op_b_jalr   : iJalrCnt++ ;
      op_b_br     : iBrCnt++ ;
      endcase
   end

   case( oCurOpCode )
   op_b_store  : iStoreCnt++ ;
   op_b_load   : iLoadCnt++ ;
   endcase

   //   iOtherCnt = 0 ;

   //end
   //else
   //begin
   //   iOtherCnt++ ;
   //end
end

final
begin
   $display("============================================================");
   $display("[INF] %m Instruction Performance Info:");
   $display("[INF] jal cycle#(%%)    : %6d (%.1f%%)", iJalCnt   , real'(iJalCnt  )*100/real'(iCycleCnt));
   $display("[INF] jalr cycle#(%%)   : %6d (%.1f%%)", iJalrCnt  , real'(iJalrCnt )*100/real'(iCycleCnt));
   $display("[INF] br cycle#(%%)     : %6d (%.1f%%)", iBrCnt    , real'(iBrCnt   )*100/real'(iCycleCnt));
   $display("[INF] store cycle#(%%)  : %6d (%.1f%%)", iStoreCnt , real'(iStoreCnt)*100/real'(iCycleCnt));
   $display("[INF] load cycle#(%%)   : %6d (%.1f%%)", iLoadCnt  , real'(iLoadCnt )*100/real'(iCycleCnt));

   $display("[INF] jal inst#(%%)    : %6d (%4.1f%%) ; IPC = (%5.3f)", iInstJalCnt   , real'(iInstJalCnt  )*100/real'(mon_order),real'(iInstJalCnt  )/real'(iJalCnt  ));
   $display("[INF] jalr inst#(%%)   : %6d (%4.1f%%) ; IPC = (%5.3f)", iInstJalrCnt  , real'(iInstJalrCnt )*100/real'(mon_order),real'(iInstJalrCnt )/real'(iJalrCnt ));
   $display("[INF] br inst#(%%)     : %6d (%4.1f%%) ; IPC = (%5.3f)", iInstBrCnt    , real'(iInstBrCnt   )*100/real'(mon_order),real'(iInstBrCnt   )/real'(iBrCnt   ));
   $display("[INF] store inst#(%%)  : %6d (%4.1f%%) ; IPC = (%5.3f)", iInstStoreCnt , real'(iInstStoreCnt)*100/real'(mon_order),real'(iInstStoreCnt)/real'(iStoreCnt));
   $display("[INF] load inst#(%%)   : %6d (%4.1f%%) ; IPC = (%5.3f)", iInstLoadCnt  , real'(iInstLoadCnt )*100/real'(mon_order),real'(iInstLoadCnt )/real'(iLoadCnt ));


   iOtherCnt   = iCycleCnt - iJalCnt - iJalrCnt - iBrCnt - iStoreCnt - iLoadCnt ;
   iInstOtherCnt = int'(mon_order) - iInstJalCnt - iInstJalrCnt - iInstBrCnt - iInstStoreCnt - iInstLoadCnt ;
   $display("[INF] other inst#(%%)   : %6d (%4.1f%%) ; IPC = (%5.3f)", iInstOtherCnt  , real'(iInstOtherCnt )*100/real'(mon_order),real'(iInstOtherCnt )/real'(iOtherCnt ));



   $display("[INF] Total cycle#  : %0d", iCycleCnt  );
   $display("[INF] Total Inst#   : %0d", mon_order );

   $display("[INF] Total flush#   : %0d", iFlushCnt );
   $display("============================================================\n");

end

endmodule

//bind rob rob_performance u_rob_performance (
//   .*
//);


module cache_performance (

    input   logic clk
   ,input   logic rst
   ,input   logic [2:0] state_r
   ,input   logic       hit
   ,input   logic [3:0] ufp_rmask
   ,input   logic [3:0] ufp_wmask
);

//------------------------------------------------------------------------------
// Cache hit/miss rate
//------------------------------------------------------------------------------

int   iRdNumber ;
int   iWrNumber ;
int   iRWNumber ;
int   iHitNumber  ;
int   iMissNumber ;

initial
begin
   iRWNumber   = '0 ;
   iHitNumber  = '0 ;
   iMissNumber = '0 ;
end

always@(posedge clk )
begin
   if( ~rst )
   begin

      if( |ufp_rmask )
      begin
         iRWNumber++ ;
         iRdNumber++ ;
      end

      if( |ufp_wmask )
      begin
         iRWNumber++ ;
         iWrNumber++ ;
      end

      if( state_r == cache.CMP_TAG )
      begin
         if( hit )
            iHitNumber++ ;
         else
            iMissNumber++ ;
      end

   end
end

final
begin
   $display("============================================================");
   $display("[INF] %m Cache Performance Info :");
   $display("[INF] Total Access Number = %0d(rd: %0d / wr: %0d)",iRWNumber,iRdNumber,iWrNumber);
   $display("[INF] Hit/Miss Number  = %0d/%0d ",iHitNumber,iMissNumber);
   $display("[INF] Hit/Miss Rate  = %.1f%%/%.1f%% ",real'(iHitNumber)*100/real'(iRWNumber),real'(iMissNumber)*100/real'(iRWNumber));
   $display("============================================================\n");
end


endmodule

//bind cache cache_performance u_cache_performance (
//   .*
//);

module rvs_performance (
    input   logic    clk
   ,input   logic    rst
   ,dec2rvs_itf.rvs  dec2rvs_itf
);

int iReqCnt ;
int iWaitCnt ;

initial
begin
   iReqCnt = '0 ;
   iWaitCnt = '0 ;
end

always@(posedge clk iff !rst)
begin
   if( dec2rvs_itf.req )
   begin
      iReqCnt++ ;
   end
   if( dec2rvs_itf.req && ~dec2rvs_itf.rdy)
   begin
      iWaitCnt++ ;
   end
end

final
begin
   $display("============================================================");
   $display("[INF] %m Reservation Station Performance Info :");
   $display("[INF] Wait cyc# = %0d ; Req cyc# = %0d ; Wait Rate = %.1f%%",
   iWaitCnt,iReqCnt,real'(iWaitCnt)*100/real'(iReqCnt));
   $display("============================================================\n");

end
endmodule

//bind rvs rvs_performance u_rvs_performance (
//   .*
//);
