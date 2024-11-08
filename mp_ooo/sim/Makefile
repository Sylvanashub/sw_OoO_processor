SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

PKG_SRCS  := $(PWD)/../pkg/types.sv
HDL_SRCS  := $(shell find $(PWD)/../hdl -name '*.sv')
COMM_HVL  := $(shell find $(PWD)/../hvl/common -name '*.sv' -o -name '*.v')
VCS_HVL   := $(COMM_HVL) $(shell find $(PWD)/../hvl/vcs -name '*.sv' -o -name '*.v')
VER_HVL   :=
SRAM_SRCS := $(shell find $(PWD)/../sram/output -name '*.v')
HDRS      := $(shell find $(PWD)/../hvl -name '*.svh')
DW_IP     := $(shell python3 $(PWD)/../bin/get_options.py dw_ip)
VCS_SRCS  := $(PKG_SRCS) $(HDL_SRCS) $(VCS_HVL) $(SRAM_SRCS) $(DW_IP)
VER_SRCS  := $(PKG_SRCS) $(HDL_SRCS) $(VER_HVL) $(SRAM_SRCS) $(DW_IP)

EXCLUDE :=
EXCLUDE += ../hvl/vcs/sync_fifo_rm.sv
EXCLUDE += ../hvl/vcs/sync_fifo_rnd.sv
EXCLUDE += ../hvl/vcs/sync_fifo_tb.sv
EXCLUDE += ../hvl/vcs/cacheline_adapter_tb.sv

#EXCLUDE += ../hdl/core/itf.sv
#EXCLUDE += ../tmp/DW_div_seq.sv
#EXCLUDE += ../hdl/core/ooo.sv
#EXCLUDE += ../hdl/core/alu.sv
#EXCLUDE += ../hdl/core/rvs.sv
#EXCLUDE += ../hdl/core/rfu.sv
#EXCLUDE += ../hdl/core/dec.sv
#EXCLUDE += ../hdl/core/cdb.sv
#EXCLUDE += ../hdl/core/lsu.sv
#EXCLUDE += ../hdl/core/rob.sv
#EXCLUDE += ../hdl/core/mdu.sv
#EXCLUDE += ../hdl/core/ifu.sv
#EXCLUDE += ../hdl/core/exu.sv
#EXCLUDE += ../hdl/core/lsu.sv
#EXCLUDE += ../hdl/core/pipeline.sv
#EXCLUDE += ../hdl/core/regfile.sv
#EXCLUDE += ../hdl/core/idu.sv

EXCLUDE := $(addprefix $(PWD)/,$(EXCLUDE))
VCS_HVL := $(filter-out $(EXCLUDE),$(VCS_HVL))
VCS_SRCS:= $(filter-out $(EXCLUDE),$(VCS_SRCS))

export VCS_ARCH_OVERRIDE=linux
VCS_FLAGS= -full64 -lca -sverilog -timescale=1ps/1ps -debug_acc+all -kdb -fsdb -suppress=LCA_FEATURES_ENABLED -msg_config=../vcs_warn.config -xprop=../xprop.config -xprop=flowctrl +incdir+$(DW)/sim_ver +define+DW_SUPPRESS_WARN +incdir+$(PWD)/../hvl/vcs +incdir+$(PWD)/../hvl/common 
ifdef f
VCS_FLAGS= -full64 -lca -sverilog -timescale=1ps/1ps -debug_access+all -kdb -suppress=LCA_FEATURES_ENABLED -msg_config=../vcs_warn.config -xprop=../xprop.config -xprop=flowctrl +incdir+$(DW)/sim_ver +define+DW_SUPPRESS_WARN +incdir+$(PWD)/../hvl/vcs +incdir+$(PWD)/../hvl/common
endif

DFILE += ../pkg/types.sv
DFILE += ../hdl/cpu.sv
DFILE += ../hdl/cache/lru_array.sv
DFILE += ../hdl/cache/cacheline_adapter.sv
DFILE += ../hdl/cache/valid_array.sv
DFILE += ../hdl/cache/cache.sv
DFILE += ../hdl/cache/icache.sv
DFILE += ../hdl/core/decode.sv
DFILE += ../hdl/core/sync_fifo.sv
DFILE += ../hdl/core/ifu.sv
DFILE += ../hdl/core/exu.sv
DFILE += ../hdl/core/lsu.sv
DFILE += ../hdl/core/pipeline.sv
DFILE += ../hdl/core/regfile.sv
DFILE += ../hdl/core/fetch.sv
DFILE += ../hdl/core/idu.sv
TFILE += ../hvl/common/banked_memory.sv
TFILE += ../hvl/common/rvfi_reference.json
TFILE += ../hvl/common/rvfi_reference.svh
TFILE += ../hvl/common/rvfimon.v
TFILE += ../hvl/common/monitor.sv
TFILE += ../hvl/common/mem_itf.sv
TFILE += ../hvl/common/mon_itf.sv
TFILE += ../hvl/vcs/sync_fifo_rnd.sv
TFILE += ../hvl/vcs/top_tb.sv
TFILE += ../hvl/vcs/sync_fifo_rm.sv
TFILE += ../hvl/vcs/sync_fifo_tb.sv
TFILE += ../hvl/vcs/cacheline_adapter_tb.sv

run:
	mkdir -p vcs
	cd vcs && vcs $(VCS_SRCS) $(VCS_FLAGS) -l compile.log -top top_tb -o top_tb
	rm -f vcs/dump.fsdb
	python3 $(PWD)/../bin/get_options.py clock
	python3 $(PWD)/../bin/get_options.py bmem_x
	export ECE411_CLOCK_PERIOD_PS=$(shell python3 $(PWD)/../bin/get_options.py clock) ;\
	export ECE411_BRAM_0_ON_X=$(shell python3 $(PWD)/../bin/get_options.py bmem_x) ;\
	export ECE411_MEMLST=$(PWD)/bin/memory ;\
	cd vcs && ./top_tb -l simulation.log -exitstatus

vcs/top_tb: $(VCS_SRCS) $(HDRS)
	mkdir -p vcs
	python3 check_sus.py
	python3 ../bin/rvfi_reference.py
	cd vcs && vcs $(VCS_SRCS) $(VCS_FLAGS) -l compile.log -top top_tb -o top_tb
	bash check_compile_error.sh
	cat vcs/xprop.log
	bash check_xprop.sh

.PHONY: run_vcs_top_tb
run_vcs_top_tb: vcs/top_tb $(PROG)
	mkdir -p spike
	python3 ../bin/generate_memory_file.py -32 $(PROG)
	rm -f vcs/dump.fsdb
	python3 $(PWD)/../bin/get_options.py clock
	python3 $(PWD)/../bin/get_options.py bmem_x
	export ECE411_CLOCK_PERIOD_PS=$(shell python3 $(PWD)/../bin/get_options.py clock) ;\
	export ECE411_BRAM_0_ON_X=$(shell python3 $(PWD)/../bin/get_options.py bmem_x) ;\
	export ECE411_MEMLST=$(PWD)/bin/memory ;\
	cd vcs && ./top_tb -l simulation.log -exitstatus

.PHONY: covrep
covrep: vcs/top_tb.vdb
	cd vcs && urg -dir top_tb.vdb

.PHONY: verdi
verdi:
	mkdir -p verdi
	cd verdi && timeout $(ECE411_GUI_TIMEOUT) $(VERDI_HOME)/bin/verdi -ssf $(PWD)/vcs/dump.fsdb

.PHONY: spike
spike: $(ELF)
	mkdir -p spike
	spike --isa=rv32imc -m0x1eceb000:0xe1315000 --log-commits $(ELF) |& tail -n +6 > spike/spike.log

.PHONY: interactive_spike
interactive_spike: $(ELF)
	spike --isa=rv32imc -m0x1eceb000:0xe1315000 --log-commits -d $(ELF)

.PHONY: clean
clean:
	rm -rf bin vcs verdi spike

DFILE := 
ifeq ($(SUB),cache)
DFILE += ../../hvl/common/banked_memory.sv
DFILE += ../../hvl/common/mem_itf.sv
DFILE += ../../hvl/vcs/cacheline_adapter_tb.sv
DFILE += ../../hdl/cache/cacheline_adapter.sv
else
DFILE += ../../hvl/vcs/sync_fifo_rnd.sv
DFILE += ../../hvl/vcs/sync_fifo_tb.sv
DFILE += ../../hvl/vcs/sync_fifo_rm.sv
DFILE += ../../hdl/core/sync_fifo.sv
endif

OPTS :=
OPTS += -full64 -lca -sverilog -timescale=1ns/1ps -debug_access+all -kdb 
OPTS += -R -l vcs.log
OPTS += -fsdb 

ss:
	mkdir -p vcs
	python3 ../bin/generate_memory_file.py -32 ../testcode/ooo_test.s
	export ECE411_MEMLST=$(PWD)/bin/memory ;\
	cd vcs && vcs $(VCS_FLAGS) -R $(DFILE)
