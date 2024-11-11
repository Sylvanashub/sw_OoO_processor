class sync_fifo_rnd ;

typedef enum int {

   IDLE  ,
   READ  ,
   WRITE ,
   RW    

} eOpType ;

rand bit       bIsBurst ;
rand eOpType    eRndType ;
rand bit [63:0] bRndWdata ;
rand int        iWrLen ;
rand int        iRdLen ;

constraint cstLen {
   iWrLen > 0 ;
   iWrLen < 32 ;
   iRdLen > 0 ;
   iRdLen < 32 ;
}

constraint cstBurst {
   bIsBurst dist { 1:=1 , 0:=4 } ;
}

endclass
