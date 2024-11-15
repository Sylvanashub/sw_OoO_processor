////////////////////////////////////////////////////////////////////////////////
//
//       This confidential and proprietary software may be used only
//     as authorized by a licensing agreement from Synopsys Inc.
//     In the event of publication, the following notice is applicable:
//
//                    (C) COPYRIGHT 2002 - 2022 SYNOPSYS INC.
//                           ALL RIGHTS RESERVED
//
//       The entire notice above must be reproduced on all authorized
//     copies.
//
// AUTHOR:    Aamir Farooqui                February 12, 2002
//
// VERSION:   Verilog Simulation Model for DW_mult_seq
//
// DesignWare_version: e7c3a965
// DesignWare_release: S-2021.06-DWBB_202106.0
//
////////////////////////////////////////////////////////////////////////////////

//------------------------------------------------------------------------------
//
//ABSTRACT:  Sequential Multiplier 
// Uses modeling functions from DW_Foundation.
//
//MODIFIED:
// 2/26/16 LMSU Updated to use blocking and non-blocking assigments in
//              the correct way
// 8/06/15 RJK Update to support VCS-NLP
// 2/06/15 RJK  Updated input change monitor for input_mode=0 configurations to better
//             inform designers of severity of protocol violations (STAR 9000851903)
// 5/20/14 RJK  Extended corruption of output until next start for configurations
//             with input_mode = 0 (STAR 9000741261)
// 9/25/12 RJK  Corrected data corruption detection to catch input changes
//             during the first cycle of calculation (related to STAR 9000505348)
// 1/5/12 RJK Change behavior when inputs change during calculation with
//          input_mode = 0 to corrupt output (STAR 9000505348)
//
//------------------------------------------------------------------------------

module DW_mult_seq ( clk, rst_n, hold, start, a,  b, complete, product);


// parameters 

  parameter  integer a_width     = 3; 
  parameter  integer b_width     = 3;
  parameter  integer tc_mode     = 0;
  parameter  integer num_cyc     = 3;
  parameter  integer rst_mode    = 0;
  parameter  integer input_mode  = 1;
  parameter  integer output_mode = 1;
  parameter  integer early_start = 0;
 
//-----------------------------------------------------------------------------

// ports 
  input clk, rst_n;
  input hold, start;
  input [a_width-1:0] a;
  input [b_width-1:0] b;

  output complete;
  output [a_width+b_width-1:0] product;

//-----------------------------------------------------------------------------
// synopsys translate_off

localparam signed [31:0] CYC_CONT = (input_mode==1 & output_mode==1 & early_start==0)? 3 :
                                    (input_mode==early_start & output_mode==0)? 1 : 2;

//-------------------Integers-----------------------
  integer count;
  integer next_count;
 

//-----------------------------------------------------------------------------
// wire and registers 

  wire clk, rst_n;
  wire hold, start;
  wire [a_width-1:0] a;
  wire [b_width-1:0] b;
  wire complete;
  wire [a_width+b_width-1:0] product;

  wire [a_width+b_width-1:0] temp_product;
  reg [a_width+b_width-1:0] ext_product;
  reg [a_width+b_width-1:0] next_product;
  wire [a_width+b_width-2:0] long_temp1,long_temp2;
  reg [a_width-1:0]   in1;
  reg [b_width-1:0]   in2;
  reg [a_width-1:0]   next_in1;
  reg [b_width-1:0]   next_in2;
 
  wire [a_width-1:0]   temp_a;
  wire [b_width-1:0]   temp_b;

  wire start_n;
  wire hold_n;
  reg ext_complete;
  reg next_complete;
 


//-----------------------------------------------------------------------------
  
  
 
  initial begin : parameter_check
    integer param_err_flg;

    param_err_flg = 0;
    
    
    if (b_width < 3) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter b_width (lower bound: 3)",
	b_width );
    end
    
    if ( (a_width < 3) || (a_width > b_width) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter a_width (legal range: 3 to b_width)",
	a_width );
    end
    
    if ( (num_cyc < 3) || (num_cyc > a_width) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter num_cyc (legal range: 3 to a_width)",
	num_cyc );
    end
    
    if ( (tc_mode < 0) || (tc_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter tc_mode (legal range: 0 to 1)",
	tc_mode );
    end
    
    if ( (rst_mode < 0) || (rst_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter rst_mode (legal range: 0 to 1)",
	rst_mode );
    end
    
    if ( (input_mode < 0) || (input_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter input_mode (legal range: 0 to 1)",
	input_mode );
    end
    
    if ( (output_mode < 0) || (output_mode > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter output_mode (legal range: 0 to 1)",
	output_mode );
    end
    
    if ( (early_start < 0) || (early_start > 1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m :\n  Invalid value (%d) for parameter early_start (legal range: 0 to 1)",
	early_start );
    end
    
    if ( (input_mode===0 && early_start===1) ) begin
      param_err_flg = 1;
      $display(
	"ERROR: %m : Invalid parameter combination: when input_mode=0, early_start=1 is not possible" );
    end

  
    if ( param_err_flg == 1) begin
      $display(
        "%m :\n  Simulation aborted due to invalid parameter value(s)");
      $finish;
    end

  end // parameter_check 


//------------------------------------------------------------------------------

  assign start_n      = ~start;
  assign complete     = ext_complete & start_n;

  assign temp_a       = (in1[a_width-1])? (~in1 + 1'b1) : in1;
  assign temp_b       = (in2[b_width-1])? (~in2 + 1'b1) : in2;
  assign long_temp1   = temp_a*temp_b;
  assign long_temp2   = ~(long_temp1 - 1'b1);
  assign temp_product = (tc_mode)? (((in1[a_width-1] ^ in2[b_width-1]) && (|long_temp1))?
                                {1'b1,long_temp2} : {1'b0,long_temp1}) : in1*in2;

// Begin combinational next state assignments
  always @ (start or hold or a or b or count or in1 or in2 or
            temp_product or ext_product or ext_complete) begin
    if (start === 1'b1) begin                     // Start operation
      next_in1      = a;
      next_in2      = b;
      next_count    = 0;
      next_complete = 1'b0;
      next_product  = {a_width+b_width{1'bX}};
    end else if (start === 1'b0) begin            // Normal operation
      if (hold === 1'b0) begin
        if (count >= (num_cyc+CYC_CONT-4)) begin
          next_in1      = in1;
          next_in2      = in2;
          next_count    = count; 
          next_complete = 1'b1;
          next_product  = temp_product;
        end else if (count === -1) begin
          next_in1      = {a_width{1'bX}};
          next_in2      = {b_width{1'bX}};
          next_count    = -1; 
          next_complete = 1'bX;
          next_product  = {a_width+b_width{1'bX}};
        end else begin
          next_in1      = in1;
          next_in2      = in2;
          next_count    = count+1; 
          next_complete = 1'b0;
          next_product  = {a_width+b_width{1'bX}};
        end
      end else if (hold === 1'b1) begin           // Hold operation
        next_in1      = in1;
        next_in2      = in2;
        next_count    = count; 
        next_complete = ext_complete;
        next_product  = ext_product;
      end else begin                              // hold == x
        next_in1      = {a_width{1'bX}};
        next_in2      = {b_width{1'bX}};
        next_count    = -1;
        next_complete = 1'bX;
        next_product  = {a_width+b_width{1'bX}};
      end
    end else begin                                // start == x
      next_in1      = {a_width{1'bX}};
      next_in2      = {b_width{1'bX}};
      next_count    = -1;
      next_complete = 1'bX;
      next_product  = {a_width+b_width{1'bX}};
    end
  end
// end combinational next state assignments

generate
  if (rst_mode == 0) begin : GEN_RM_EQ_0

  // Begin sequential assignments
    always @ ( posedge clk or negedge rst_n ) begin: ar_register_PROC
      if (rst_n === 1'b0) begin                   // initialize everything asyn reset
        count        <= 0;
        in1          <= 0;
        in2          <= 0;
        ext_product  <= 0;
        ext_complete <= 0;
      end else if (rst_n === 1'b1) begin          // rst_n == 1
        count        <= next_count;
        in1          <= next_in1;
        in2          <= next_in2;
        ext_product  <= next_product;
        ext_complete <= next_complete & start_n;
      end else begin                              // rst_n == X
        in1          <= {a_width{1'bX}};
        in2          <= {b_width{1'bX}};
        count        <= -1;
        ext_product  <= {a_width+b_width{1'bX}};
        ext_complete <= 1'bX;
      end 
   end // ar_register_PROC

  end else  begin : GEN_RM_NE_0

  // Begin sequential assignments
    always @ ( posedge clk ) begin: sr_register_PROC 
      if (rst_n === 1'b0) begin                   // initialize everything asyn reset
        count        <= 0;
        in1          <= 0;
        in2          <= 0;
        ext_product  <= 0;
        ext_complete <= 0;
      end else if (rst_n === 1'b1) begin          // rst_n == 1
        count        <= next_count;
        in1          <= next_in1;
        in2          <= next_in2;
        ext_product  <= next_product;
        ext_complete <= next_complete & start_n;
      end else begin                              // rst_n == X
        in1          <= {a_width{1'bX}};
        in2          <= {b_width{1'bX}};
        count        <= -1;
        ext_product  <= {a_width+b_width{1'bX}};
        ext_complete <= 1'bX;
      end 
   end // ar_register_PROC

  end
endgenerate

  wire corrupt_data;

generate
  if (input_mode == 0) begin : GEN_IM_EQ_0

    localparam [0:0] NO_OUT_REG = (output_mode == 0)? 1'b1 : 1'b0;
    reg [a_width-1:0] ina_hist;
    reg [b_width-1:0] inb_hist;
    wire next_corrupt_data;
    reg  corrupt_data_int;
    wire data_input_activity;
    reg  init_complete;
    wire next_alert1;
    integer change_count;

    assign next_alert1 = next_corrupt_data & rst_n & init_complete &
                                    ~start & ~complete;

    if (rst_mode == 0) begin : GEN_A_RM_EQ_0
      always @ (posedge clk or negedge rst_n) begin : ar_hist_regs_PROC
	if (rst_n === 1'b0) begin
	    ina_hist        <= a;
	    inb_hist        <= b;
	    change_count    <= 0;

	  init_complete   <= 1'b0;
	  corrupt_data_int <= 1'b0;
	end else begin
	  if ( rst_n === 1'b1) begin
	    if ((hold != 1'b1) || (start == 1'b1)) begin
	      ina_hist        <= a;
	      inb_hist        <= b;
	      change_count    <= (start == 1'b1)? 0 :
	                         (next_alert1 == 1'b1)? change_count + 1 : change_count;
	    end

	    init_complete   <= init_complete | start;
	    corrupt_data_int<= next_corrupt_data | (corrupt_data_int & ~start);
	  end else begin
	    ina_hist        <= {a_width{1'bx}};
	    inb_hist        <= {b_width{1'bx}};
	    change_count    <= -1;
	    init_complete   <= 1'bx;
	    corrupt_data_int <= 1'bX;
	  end
	end
      end
    end else begin : GEN_A_RM_NE_0
      always @ (posedge clk) begin : sr_hist_regs_PROC
	if (rst_n === 1'b0) begin
	    ina_hist        <= a;
	    inb_hist        <= b;
	    change_count    <= 0;
	  init_complete   <= 1'b0;
	  corrupt_data_int <= 1'b0;
	end else begin
	  if ( rst_n === 1'b1) begin
	    if ((hold != 1'b1) || (start == 1'b1)) begin
	      ina_hist        <= a;
	      inb_hist        <= b;
	      change_count    <= (start == 1'b1)? 0 :
	                         (next_alert1 == 1'b1)? change_count + 1 : change_count;
	    end

	    init_complete   <= init_complete | start;
	    corrupt_data_int<= next_corrupt_data | (corrupt_data_int & ~start);
	  end else begin
	    ina_hist        <= {a_width{1'bx}};
	    inb_hist        <= {b_width{1'bx}};
	    init_complete    <= 1'bx;
	    corrupt_data_int <= 1'bX;
	    change_count     <= -1;
	  end
	end
      end
    end // GEN_A_RM_NE_0

    assign data_input_activity =  (((a !== ina_hist)?1'b1:1'b0) |
				 ((b !== inb_hist)?1'b1:1'b0)) & rst_n;

    assign next_corrupt_data = (NO_OUT_REG | ~complete) &
                              (data_input_activity & ~start &
					~hold & init_complete);

`ifdef UPF_POWER_AWARE
  `protected
g\B@L6=aE26Pd5KVbIACdb\Z\@#G_RW]3R0S##-JIIY<YJ8R0+6_1)b6[ICN9e=C
24K#XE>O.;JOEHEV,6MC&:H6Y(:+9g9IW763&W_XYBTWQIU5860<dJAYM3L-@8c/
Sg<36\^P(eTI:[?_Q]9I@Nd3cVb_aZI[cWTX[DI2F8_>78R0]0d,N@Q=1^&L6=P@
>>&O8bQ=gZI?.OKaM<W5:1dJU:LIMM0S@K)81:S)d>O9f,8IX?RB:HF/+bUFL,9d
U;5GX\UD.:C7+aG.X,3Z)Z[6ETFcJa2:MHN7XDP0F7\6NE5R\LfT/,9Ua37LHd\?
.&0\Mc#E@fBJR1?fMYYJ2559PERTUU8AWON/-V=a))W\VYZXU8O@8>A,.-(>CZS<
-N)S\f:Vg_8)I8N(Y)/[f-A)NS<>&\3-d:PP<WC+C65C/;<Z>KB56-D0:F#9H>2/
>5L?[#RM,fNM9?N#&NA#0>>ZJAXW#]]GB89T&;\X=@]+;JG,)D2=#a<Q4NAgW=I.
D)F.SHK3gO3bOKW(,-^Qa:VD23=0\K+;-;]YJd8=9A@VOXBR]K@cI2U,Vg])#f?8
C4JDc6bC#6I^97CM)YHbML^fe#A(0QJ^BMC1cV0;UagHeI)cA2KK/A,B,/,[+MC_
-]g87NVZUZVGONX:GF3+V>A.g[,E=F/]0LY39<MHDH\f5=@@-(\(B0cReJ5ALY0d
,+<)1STW0d]=[fd5.-YY0b5S#aN)UK<[J]fa4HNMU[@1fU\-1WV]&V3+5BUAZPYc
9]5#_/=-_W]D/8OTHS4;a;B;[>bgP]Re/H#A@aKGA&,>F(fdPCI1#2aTSO&:QO:5
3A4JR;-^>S-5bYeC+U_Z.Z:ZReRZ4Y2EJI>/=S=_G.,1;3E?VIIO4X3<Y43Rc\A.
08?:+&C5XH)]cIV<RF7EHTOJeW/[=>9d5>dPPCXI]AI\+-RP6?^FHL,D5=gg#T])
/I2LZ2TMG.9]_ERPKPDLaK2J2UEg.H8)/,PTM\#KBA80F2><0LL)4OW6Z;[Ef1BV
Df2Q;-Wac;4[.K=&F&cY-)>FA0GA<N4OO=1EQ-4N-V<Ad1FK,8^4H31L(KK.RL,3
3^5]A;<=+CRf_FXO@D)&CVgCG<DDK@MDZVBcYX57eCeHX0;H^M,)/8S#dV13O>cA
\]B,WaJ9Za,DW2,;)6gbf7ScAA(@,OX6)_MI3SZVCC;HWI.+c;.+8S&51#I,#UZf
OO5ZT6,54/C2]H<7G+CT@BWQ..GCMM?B1e+HL2V&8IcaZ1[Y0gXH9M;[F;:A=7I9
2&WID]NC:V-cedZK(RP#QGO\-1cTI?RA8/8]DbDd(aed5,fe6EQQZBJ/d0C3VS9U
)9NXAOeT=C2-5,0_-RZUc=3fY2S@\-.gR=GEI2[PZ(#+YFEG-[E+O5_U2.Rd-9-E
WZA&&(##bMDCP9^PgH:A41MJ_V&\M9:a+KDAJBf0/&IGJaLX3+RRN[YRO;<Y>(YG
QD+64/A=<?)C^Oc&R]F.+JMaNDFV4WfXJRY++dc?gEf&e)a&(H=_;TI(#1+IYW(d
?/U5+T/Q?:A+)eJ(9?.E,0AgHdZGZ5:+g27SI>f5EdC[&A]DN/Ue_<c[^XV&Z;=0
^7@YAS+VZ^+D:&bNeS;)gIKcJH5F=LVcWP],Y/K<5IKYdfgQ9P9MC3:/JB/32Gd,
)LY_ZO)B4Q1(19(ec>cb#)6DW]#Tb8aBK06E9Y^:f<1>/=9bM)V7bEK+DV)]U6][
7fE_PaA4Ee+H@e(Bbb1)3,=&Y[&c#V=^].?&(LRGe)EJY64/THA_7]&-JBWWLd_+
T#fF^D+bK\eYR87YC,9KPX[K6-R^=3N=Z#IAUG/GI-d.d,cE@^V3T2R1O#C,(XR9
7@6I2g_=MX:OCYcV6EDIJb905S5Lc4DE0W7f)DXDA)eD6((HLeRHSQ\:+(R0F_1>
???CE(8SULQfb.4HJCDLUS:FDJWKJ9.97X1TW)1LK<\:dZ6X+AP?^3LT9&dL_ZEE
dK.;-P-T.cLfS;>LGBb-XA]\[.bfSHR76SU_UcLLJH81G<OT)A?1Yd?SdL2>BgFg
>(EC@-STRP/eUF+ab-#,4_SKZ\@0=J]#_aQPM(OI,8>+[9P5@N[G7<7&7GQSJM:B
,(^[.gOVQ5Q,f/>b;G5?RHR[E09\FGLK7dLR1OAZ2/4<S[a2X.QICF&YC3D;\]K0
1U^L&3?c>G313=ELWT8S,570671,gabEFY>^NQ-V@bMLbF=VIb&77LVVVDW)486F
1431&ZJ0dBXMU=LG00^eFSR.[E-JL#,SBFef#]ZXEKO64/_6(86)NQTb#ZYf6]@H
KCe\9U..cA\cT5JC;X:PL0Y]Z93AL&UZ\(1b-1&XO;_@Ae[4)CP=Y83Ne84+cbfd
,E)\L8R[g]3\>07(S(ZKd:(/AE]A(0PE1fC^VX-;cP2EP-g(^B#/)g;^FSC)]E/4
F.dPLBWCDeG/H:N1E4f&XH8F1JXBJ2DG#WTBJg@(I;<08/cJBGHE/(^ZZg\ZZ-F/
X<RNKd-<\PX@-L+0K,6:4U+W-_g&35fA2?D9+Z@cXW-)B]N>2Z+af^79F&_6EF6a
:=W[N#V(?N4J\LV>?gA.R8C1)&+_dLV)[.MCB<7ETHWR66TTPd/MDIF88XDY#:\X
bf1K-O.G7:2J0$
`endprotected

`else
    always @ (posedge clk) begin : corrupt_alert_PROC
      integer updated_count;

      updated_count = change_count;

      if (next_alert1 == 1'b1) begin
`ifndef DW_SUPPRESS_WARN
          $display ("WARNING: %m:\n at time = %0t: Operand input change on DW_mult_seq during calculation (configured without an input register) will cause corrupted results if operation is allowed to complete.", $time);
`endif
	updated_count = updated_count + 1;
      end

      if (((rst_n & init_complete & ~start & ~complete & next_complete) == 1'b1) &&
          (updated_count > 0)) begin
	$display(" ");
	$display("############################################################");
	$display("############################################################");
	$display("##");
	$display("## Error!! : from %m");
	$display("##");
	$display("##    This instance of DW_mult_seq has encountered %0d change(s)", updated_count);
	$display("##    on operand input(s) after starting the calculation.");
	$display("##    The instance is configured with no input register.");
	$display("##    So, the result of the operation was corrupted.  This");
	$display("##    message is generated at the point of completion of");
	$display("##    the operation (at time %0d), separate warning(s) were", $time );
`ifndef DW_SUPPRESS_WARN
	$display("##    generated earlier during calculation.");
`else
	$display("##    suppressed earlier during calculation.");
`endif
	$display("##");
	$display("############################################################");
	$display("############################################################");
	$display(" ");
      end
    end
`endif

    assign corrupt_data = corrupt_data_int;

  if (output_mode == 0) begin : GEN_OM_EQ_0
    reg  alert2_issued;
    wire next_alert2;

    assign next_alert2 = next_corrupt_data & rst_n & init_complete &
                                     ~start & complete & ~alert2_issued;

`ifdef UPF_POWER_AWARE
  `protected
WfGF7c<4_6H1MUa6B7A=_VEICcP6fLE0RZfK2@c_C[PXP3AS(4[A1)M\TC[6WXIQ
Y)(.-<gM^T5&=_5L]RKLNG=a^5DQIC1L4aaL^JXO=bTL[5)?7(be5([)IK-^MJBF
=@P)JI,,9P2a@d#RT+^0fS^0e(&_S])/5&ACS0_]&3.+3G_5c_FP\dYdJDE4[:TU
=<Mc.bUeU3Q8bKA2/>(;O<Na/HYFW]ROB2K/HC9\O\Xb1aGI/ed^K(XM[HL;#J7(
V4QIDbMY_A6^_AVcL61.A.WR@&QQdV(;\@^3389Cg^K]KUUG:>S7M?\AT07S=,AE
UKFXMZD\=_8)/S>MZ?X^#a5Id[AI0R;4.)?1c;Xf]F?[\3cHW?c/>VZJg;(Y:\E<
f;8/Y0DI9^.K.ERL-]J>;#]P]Y:D@2a;:DJ>aV/^bTF^4[E;eOK744ELC@T_CI/B
F/XQC)A.USPBd4)74XYO6J&GFE895/;W-PE:RZX_e0Eb]CL//ZW8cUcHWW2\a;TP
&I7Ebg,UA)c##JVYY(ULN6V]FJ6IHL\_5=+P_W9_)3DG(YZ#R(VLFIB?^-K(#7-+
e<IYAJ83&(M[WaSL@.e28/R>EW75K<1@](5DA@>C:JHO\N^D:.OPWg]C)a>&S1.X
I^Nea<Ybe5_A2Z:cZ6@NF]IZ-MgKW7U.>$
`endprotected

`else
  `ifndef DW_SUPPRESS_WARN
    always @ (posedge clk) begin : corrupt_alert2_PROC
      if (next_alert2 == 1'b1) begin
        $display( "## Warning from %m: DW_mult_seq operand input change near %0d causes output to no longer retain result of previous operation.", $time);
      end
    end
  `endif
`endif

    if (rst_mode == 0) begin : GEN_AI_REG_AR
      always @ (posedge clk or negedge rst_n) begin : ar_alrt2_reg_PROC
        if (rst_n == 1'b0) alert2_issued <= 1'b0;

	  else alert2_issued <= ~start & (alert2_issued | next_alert2);
      end
    end else begin : GEN_AI_REG_SR
      always @ (posedge clk) begin : sr_alrt2_reg_PROC
        if (rst_n == 1'b0) alert2_issued <= 1'b0;

	  else alert2_issued <= ~start & (alert2_issued | next_alert2);
      end
    end

  end  // GEN_OM_EQ_0

  // GEN_IM_EQ_0
  end else begin : GEN_IM_NE_0
    assign corrupt_data = 1'b0;
  end // GEN_IM_NE_0
endgenerate

  assign product      = ((((input_mode==0)&&(output_mode==0)) || (early_start == 1)) && start == 1'b1) ?
			  {a_width+b_width{1'bX}} :
                          (corrupt_data === 1'b0)? ext_product : {a_width+b_width{1'bX}};


 
`ifndef DW_DISABLE_CLK_MONITOR
`ifndef DW_SUPPRESS_WARN
  always @ (clk) begin : P_monitor_clk 
    if ( (clk !== 1'b0) && (clk !== 1'b1) && ($time > 0) )
      $display ("WARNING: %m:\n at time = %0t: Detected unknown value, %b, on clk input.", $time, clk);
    end // P_monitor_clk 
`endif
`endif
// synopsys translate_on

endmodule




