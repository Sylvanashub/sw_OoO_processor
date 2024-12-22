
class isb_html_table :

	def __init__ ( self , strName , iColNum , iRowNum ):

		self.strName = strName 
		self.iColNum = iColNum
		self.iRowNum = iRowNum
		#self.strContentLst = [["&nbsp;"] * iColNum] * iRowNum
		self.strContentLst = [["&nbsp;"] * iColNum for _ in range(iRowNum)]
		self.iTdHeadLst = []

	def set_title ( self , strTxtLst ):

		self.strContentLst[0] = strTxtLst

	def set_row ( self , iRow , strTxtLst ):

		self.strContentLst[iRow] = strTxtLst

	def set_col ( self , iCol , strTxtLst ):
		for iRow in range(self.iRowNum):
			self.strContentLst[iRow][iCol] = strTxtLst[iRow] 
			#print("[DBG] set Table[%0d][%0d] = %s" % (iRow,iCol, strTxtLst[iRow]))

	def gen_html_id ( self ):

		strID = self.strName
		strID = strID.replace(" ","_")
		strID += "_tb"
		
		return strID

	def gen_html ( self ):

		strHTML = "<table border='1' id='"+self.gen_html_id()+"'>"
		#print("[DBG] row# = {} ; col# = {}".format(self.iRowNum,self.iColNum))
		#print(self.strContentLst)
		for iRow in range(self.iRowNum):
			if( iRow == 0 ):
				strHTML += "<thead><tr class='tb_title'>"
			else:
				strHTML += "<tr >"
			for iCol in range(self.iColNum):
				strHTML += "<td>{}</td>".format(self.strContentLst[iRow][iCol])

			if( iRow == 0 ):
				strHTML += "</tr></thead><tbody>"
			else:
				strHTML += "</tr>"

		strHTML += "</tbody></table>"

		return strHTML

class isb_html_table2(isb_html_table):

	def __init__ ( self , strName , iColNum , iRowNum ):
		isb_html_table.__init__( self, strName , iColNum , iRowNum )

	def gen_html ( self ):

		strHTML = "<table border='1' id='"+self.gen_html_id()+"'><tbody>"
		#print("[DBG] row# = {} ; col# = {}".format(self.iRowNum,self.iColNum))
		#print(self.strContentLst)
		for iRow in range(self.iRowNum):
			strHTML += "<tr>"
			for iCol in range(self.iColNum):
				if( iCol in self.iTdHeadLst ):
					strHTML += "<td class='td_head'>{}</td>".format(self.strContentLst[iRow][iCol])
				else:
					strHTML += "<td>{}</td>".format(self.strContentLst[iRow][iCol])

	
			strHTML += "</tr>"
		strHTML += "</tbody></table>"

		return strHTML


class isb_html_board :

	def __init__ ( self , strName , iWidth = 100 , iHeight = 300 ):

		self.strName 	= strName
		self.oTableLst 	= []

		self.iWidth	= iWidth
		self.iHeight	= iHeight

	
	def add_table ( self , strName , iColNum , iRowNum ):

		oTable = isb_html_table(strName,iColNum,iRowNum)
		self.oTableLst.append( oTable )
		return oTable

	def add_table2 ( self , strName , iColNum , iRowNum ):

		oTable = isb_html_table2(strName,iColNum,iRowNum)
		self.oTableLst.append( oTable )
		return oTable

	def gen_html ( self ):

		strStyle = "style='height:{};width:{}'".format(self.iHeight,self.iWidth)

		strHTML = "<div class='module' "+strStyle+">"

		strHTML += self.strName
		
		for oTable in self.oTableLst:
			strHTML += oTable.gen_html()

		strHTML += "</div>"

		return strHTML

class isb_html_frame :

	def __init__ ( self , strName, iWidth = 100 , iHeight = 300 ):
		self.strName 	= strName
		self.iWidth = iWidth
		self.iHeight = iHeight
		self.strStyle = "height:{};width:{};".format(iHeight,iWidth)

		self.strHTML = ""
		self.oBoardLst = []

	def add_board ( self , strName , iWidth , iHeight ):

		oBoard = isb_html_board(strName,iWidth,iHeight)
		self.oBoardLst.append( oBoard )
		return oBoard
	
	def add_style ( self , strText ):

		self.strStyle += strText

	def gen_html ( self ):

		strHTML = ""

		strHTML += "<div class='frame' style='"+self.strStyle+"'>"
		strHTML += "<div class='frame_title'>" + self.strName + "</div>"
		
		for oBoard in self.oBoardLst:
			strHTML += oBoard.gen_html()

		strHTML += self.strHTML

		strHTML += "</div>"

		return strHTML

class isb_main :

	def __init__ ( self ):

		self.oFrameLst = []
		self.strHTML = ""


	def add_frame ( self , strName , iWidth , iHeight ):

		oFrame = isb_html_frame(strName,iWidth,iHeight)
		self.oFrameLst.append( oFrame )
		return oFrame

	def gen_html_head ( self ):

		self.strHTML += '''
		<html>
		<head>
		<link rel="stylesheet" href="./isb.css">
		<script src="../html/js/.jquery.js"></script>
		<script src="../html/rvd.js"></script>
		<script src="../dat/inst_buffer_ary.js"></script>
		<script src="../dat/rob_ary.js"></script>
		<script src="../dat/gpr_ary.js"></script>
		<script src="../dat/alu_rvs_ary.js"></script>
		<script src="../dat/mdu_rvs_ary.js"></script>
		<script src="../dat/lsu_rvs_ary.js"></script>
		<script src="../dat/jmp_rvs_ary.js"></script>
		<script src="../dat/dec_ary.js"></script>
		<script src="../html/isb.js"></script>
		</head>
		<body>
		'''

	def gen_html_foot ( self ):

		self.strHTML += '''
		</body>
		</html>
		'''

	def gen_html_body ( self ):

		for oFrame in self.oFrameLst:
			self.strHTML += oFrame.gen_html()


	def gen_html ( self , strFilePath ):

		self.gen_html_head()
		self.gen_html_body()
		self.gen_html_foot()

		with open(strFilePath,'w') as oFile:
			oFile.write( self.strHTML )

		oFile.close()

	def do_main ( self ):

		oFrameIfu = self.add_frame("fetch",220,620);
		oFrameDec = self.add_frame("decode",600,620);
		oFrameRob = self.add_frame("rob",350,620);
		oFrameGpr = self.add_frame("Reigster",170,620);
		oFrameCtl = self.add_frame("Control",1000,100);

		oBoard = oFrameIfu.add_board("inst buffer",220,200)
		oTable = oBoard.add_table("inst buffer",4,16+1)
		oTable.set_title(["#","pc","inst","ptr"])
		#oTable.set_row(1,["1","0x1ecf0000","0x23fd430b",""])
		#oTable.set_row(2,["2","0x1ecf0004","0x23fd430b",""])
		#oTable.set_row(3,["3","0x1ecf0008","0x23fd430b","<"])
		#oTable.set_row(4,["4","0x1ecf0010","0x23fd430b",""])
		#oTable.set_row(5,["5","0x1ecf0014","0x23fd430b",""])
		#oTable.set_row(6,["6","0x1ecf0018","0x23fd430b",""])
		#oTable.set_row(7,["7","0x1ecf001C","0x23fd430b",">"])

		oBoard = oFrameDec.add_board("decocde",580,150)
		oTable = oBoard.add_table2("dec",4,7)
		oTable.iTdHeadLst = [0,2]
		oTable.set_col(0,["opcode","rs1","rs2","rd","funct3","funct7","imm"])
		oTable.set_col(2,["Assembly","Binary","Hex","Format","Inst Set","Manual","Status"])

		oBoard = oFrameDec.add_board("alu reservation station",290,200)
		oTable = oBoard.add_table("alu rs",6,4+1)
		oTable.set_title(["#","src1 tag","src1 data","src2 tag","src2 data","ptr"])

		oBoard = oFrameDec.add_board("mdu reservation station",290,200)
		oTable = oBoard.add_table("mdu rs",6,4+1)
		oTable.set_title(["#","src1 tag","src1 data","src2 tag","src2 data","ptr"])

		oBoard = oFrameDec.add_board("lsu reservation station",290,200)
		oTable = oBoard.add_table("lsu rs",6,4+1)
		oTable.set_title(["#","src1 tag","src1 data","src2 tag","src2 data","ptr"])

		oBoard = oFrameDec.add_board("jmp reservation station",290,200)
		oTable = oBoard.add_table("jmp rs",6,4+1)
		oTable.set_title(["#","src1 tag","src1 data","src2 tag","src2 data","ptr"])

		oBoard = oFrameRob.add_board("reorder buffer",350,300)
		oTable = oBoard.add_table("rob",8,16+1)
		oTable.set_title(["#","pc","inst","disasm","tag","vld","rdy","ptr"])


		oBoard = oFrameGpr.add_board("register",170,300)
		oTable = oBoard.add_table("register",4,32+1)
		oTable.set_title(["#","data","vld","rob#"])


		oFrameCtl.strHTML += "<input id='inpInstOrder' type='text' value='0'>"
		oFrameCtl.strHTML += "<button id='btnPrevious' onClick='step_backward()'>Previous</button>"
		oFrameCtl.strHTML += "<button id='btnNext' onClick='step_forward()'>Next</button>"
