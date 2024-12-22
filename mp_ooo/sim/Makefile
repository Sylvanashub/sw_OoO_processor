SHELL=/bin/bash -o pipefail
.SHELLFLAGS += -e

PKG_SRCS  := $(PWD)/../pkg/types.sv
HDL_SRCS  := $(shell find $(PWD)/../hdl -name '*.sv')
COMM_HVL  := $(shell find $(PWD)/../hvl/common -name '*.sv' -o -name '*.v')
VCS_HVL   := $(COMM_HVL) $(shell find $(PWD)/../hvl/vcs -name '*.sv' -o -name '*.v')
VER_HVL   := $(COMM_HVL) $(shell find $(PWD)/../hvl/verilator -name '*.sv' -o -name '*.v')
SRAM_SRCS := $(shell find $(PWD)/../sram/output -name '*.v')
HDRS      := $(shell find $(PWD)/../hvl -name '*.svh') $(PWD)/../hvl/common/rvfi_reference.json
DW_IP     := $(shell python3 $(PWD)/../bin/get_options.py dw_ip)
VCS_SRCS  := $(PKG_SRCS) $(HDL_SRCS) $(VCS_HVL) $(SRAM_SRCS) $(DW_IP)
VER_SRCS  := $(PKG_SRCS) $(HDL_SRCS) $(VER_HVL) $(SRAM_SRCS) $(DW_IP)
VER_EX    := $(PWD)/../hvl/verilator/verilator_harness.cpp

TIMEOUT         ?= 10000000
VER_TRACE_START ?= -1
VER_TRACE_END   ?= -1

# ../pkg/types.sv
#
# ../hdl/core/alu.sv
# ../hdl/core/rvs.sv
# ../hdl/core/sync_fifo.sv
# ../hdl/core/rfu.sv
# ../hdl/core/gpr.sv
# ../hdl/core/rat.sv
# ../hdl/core/dec.sv
# ../hdl/core/rob.sv
# ../hdl/core/itf.sv
# ../hdl/core/lsu.sv
# ../hdl/core/jmp.sv
# ../hdl/core/cdb.sv
# ../hdl/core/fetch.sv
# ../hdl/core/btb.sv
# ../hdl/core/bht.sv
# ../hdl/core/ooo.sv
# ../hdl/core/mdu.sv
# ../hdl/core/bpu.sv
# ../hdl/core/btb_cache.sv
# ../hdl/core/dpsram.sv
# ../hdl/core/pcsb.sv
# ../hdl/core/dtcm.sv
# ../hdl/cpu.sv
# ../hdl/cache/lru_array.sv
# ../hdl/cache/cacheline_adapter.sv
# ../hdl/cache/valid_array.sv
# ../hdl/cache/cache.sv
# ../hdl/cache/icache.sv
#
# ../hvl/common/banked_memory.sv
# ../hvl/common/rvfi_reference.svh
# ../hvl/common/rvfi_reference.json
# ../hvl/common/rvfimon.v
# ../hvl/common/monitor.sv
# ../hvl/common/mem_itf.sv
# ../hvl/common/dram_w_burst_frfcfs_controller.sv
# ../hvl/common/mon_itf.sv
# ../hvl/vcs/rvfi_connect.sv
# ../hvl/vcs/performance.sv
# ../hvl/vcs/randinst.svh
# ../hvl/vcs/top_tb.sv
# ../hvl/vcs/instr_cg.svh
# ../hvl/vcs/random_tb.sv
# ../hvl/vcs/rob_mon.sv
# ../hvl/vcs/visualization.sv


export VCS_ARCH_OVERRIDE=linux
ifdef f
#VCS_FLAGS= -full64 -lca -sverilog -timescale=1ps/1ps -debug_access+all -suppress=LCA_FEATURES_ENABLED -msg_config=../vcs_warn.config -xprop=../xprop.config -xprop=flowctrl +incdir+$(DW)/sim_ver +define+DW_SUPPRESS_WARN +incdir+$(PWD)/../hvl/vcs +incdir+$(PWD)/../hvl/common
VCS_FLAGS :=
VCS_FLAGS += -full64
VCS_FLAGS += -lca
VCS_FLAGS += -sverilog
VCS_FLAGS += -timescale=1ps/1ps
VCS_FLAGS += -debug_access+all
VCS_FLAGS += -kdb
VCS_FLAGS += -suppress=LCA_FEATURES_ENABLED
VCS_FLAGS += -msg_config=../vcs_warn.config
VCS_FLAGS += -xprop=../xprop.config
VCS_FLAGS += -xprop=flowctrl
VCS_FLAGS += +incdir+$(DW)/sim_ver
VCS_FLAGS += +define+DW_SUPPRESS_WARN
VCS_FLAGS += +incdir+$(PWD)/../hvl/vcs
VCS_FLAGS += +incdir+$(PWD)/../hvl/common
else
VCS_FLAGS= -full64 -lca -sverilog -timescale=1ps/1ps -debug_acc+all -kdb -fsdb -suppress=LCA_FEATURES_ENABLED -msg_config=../vcs_warn.config -xprop=../xprop.config -xprop=flowctrl +incdir+$(DW)/sim_ver +define+DW_SUPPRESS_WARN +incdir+$(PWD)/../hvl/vcs +incdir+$(PWD)/../hvl/common
endif

ifdef rand
VCS_FLAGS += +define+RND_TEST
endif


VER_FLAGS= -Wall --timescale 1ps/1ps --trace-structs --trace-max-array 128 -Mdir build -O3 -CFLAGS "-Ofast -march=native" --x-assign fast --x-initial fast --noassert --cc ../verilator_warn.vlt +incdir+$(DW)/sim_ver +incdir+$(PWD)/../hvl/vcs +incdir+$(PWD)/../hvl/common

INST ?= jal

#S_FILE := ../testcode/ooo_test.s
#S_FILE := ../testcode/dependency_test.s
#S_FILE := ../testcode/ls_test.s
#S_FILE := ../testcode/$(INST).s
S_FILE := ../testcode/coremark_im.elf
#S_FILE := ../testcode/cp3_release_benches/aes_sha.elf
#S_FILE := ../testcode/cp3_release_benches/fft.elf
#S_FILE ?= ../testcode/cp3_release_benches/mergesort.elf
isa:
	/eda/tools_22/synopsys/icc2/T-2022.03/etc/Python/bin/python3 ../bin/generate_memory_file.py -32 ../testcode/$(INST).S
run:
	mkdir -p vcs
	mkdir -p spike
	/eda/tools_22/synopsys/icc2/T-2022.03/etc/Python/bin/python3 ../bin/rvfi_reference.py
	/eda/tools_22/synopsys/icc2/T-2022.03/etc/Python/bin/python3 ../bin/generate_memory_file.py -32 $(S_FILE)
	cd vcs && vcs $(VCS_SRCS) $(VCS_FLAGS) -l compile.log -top top_tb -o top_tb
	bash check_compile_error.sh
	export ECE411_MEMLST=$(PWD)/bin/memory ;\
	cd vcs && ./top_tb -l simulation.log -exitstatus \
	+TIMEOUT_ECE411=$(TIMEOUT) \
	+MEMLST_ECE411="$(PWD)/bin/memory_32.lst" \
	+CLOCK_PERIOD_PS_ECE411=$(shell python3 $(PWD)/../bin/get_options.py clock) \
	+BRAM_0_ON_X_ECE411=$(shell python3 $(PWD)/../bin/get_options.py bmem_x)


vcs/top_tb: $(VCS_SRCS) $(HDRS)
	mkdir -p vcs
	python3 check_sus.py
	python3 ../bin/rvfi_reference.py
	cd vcs && vcs $(VCS_SRCS) $(VCS_FLAGS) -l compile.log -top top_tb -o top_tb
	bash check_compile_error.sh

.PHONY: run_vcs_top_tb
run_vcs_top_tb: vcs/top_tb $(PROG)
	mkdir -p spike
	python3 ../bin/generate_memory_file.py -32 $(PROG)
	rm -f vcs/dump.fsdb
	python3 $(PWD)/../bin/get_options.py clock
	python3 $(PWD)/../bin/get_options.py bmem_x
	cd vcs && ./top_tb -l simulation.log -exitstatus \
		+TIMEOUT_ECE411=$(TIMEOUT) \
		+CLOCK_PERIOD_PS_ECE411=$(shell python3 $(PWD)/../bin/get_options.py clock) \
		+MEMLST_ECE411="$(PWD)/bin/memory_32.lst" \
		+BRAM_0_ON_X_ECE411=$(shell python3 $(PWD)/../bin/get_options.py bmem_x)

verilator/build/Vtop_tb: $(VER_SRCS) $(HDRS) $(VER_EX)
	mkdir -p verilator
	python3 check_sus.py
	python3 ../bin/rvfi_reference.py
	cd verilator ;\
	verilator -trace-fst +define+ECE411_VER_DUMP +define+ECE411_FST_DUMP $(VER_FLAGS) $(VER_SRCS) --top-module top_tb --exe $(VER_EX)
	cd verilator/build ;\
	$(MAKE) --jobs=$(shell echo $(shell nproc)-2 | bc) -f Vtop_tb.mk

.PHONY: run_verilator_top_tb
run_verilator_top_tb: verilator/build/Vtop_tb $(PROG)
	mkdir -p spike
	find ./verilator -maxdepth 1 -type f -delete
	python3 ../bin/generate_memory_file.py -32 $(PROG)
	python3 $(PWD)/../bin/get_options.py clock
	python3 $(PWD)/../bin/get_options.py bmem_x
	cd verilator && ./build/Vtop_tb \
		+TIMEOUT_ECE411=$(TIMEOUT) \
		+CLOCK_PERIOD_PS_ECE411=$(shell python3 $(PWD)/../bin/get_options.py clock) \
		+BRAM_0_ON_X_ECE411=$(shell python3 $(PWD)/../bin/get_options.py bmem_x) \
		+MEMLST_ECE411="$(PWD)/bin/memory_32.lst"

.PHONY: run_verilator_lint
run_verilator_lint: $(VER_SRCS) $(HDRS) $(VER_EX)
	mkdir -p verilator
	python3 check_sus.py
	python3 ../bin/rvfi_reference.py
	cd verilator ;\
	verilator --lint-only +define+ECE411_VER_DUMP +define+ECE411_FST_DUMP $(VER_FLAGS) $(VER_SRCS) --top-module top_tb --exe $(VER_EX)

.PHONY: covrep
covrep: vcs/top_tb.vdb
	cd vcs && urg -dir top_tb.vdb

.PHONY: verdi
verdi:
	mkdir -p verdi
	cd verdi && timeout $(ECE411_GUI_TIMEOUT) $(VERDI_HOME)/bin/verdi -ssf $(PWD)/vcs/dump.fsdb

fsdb:
	cd vcs && verdi -sv $(VCS_SRCS) $(VCS_FLAGS) -ssf dump.fsdb &

.PHONY: spike
spike: $(ELF)
	mkdir -p spike
	spike --isa=$(shell python3 $(PWD)/../bin/get_options.py arch) -m0x1eceb000:0xe1315000 --log-commits $(ELF) |& tail -n +6 > spike/spike.log

.PHONY: interactive_spike
interactive_spike: $(ELF)
	spike --isa=$(shell python3 $(PWD)/../bin/get_options.py arch) -m0x1eceb000:0xe1315000 --log-commits -d $(ELF)

.PHONY: clean
clean:
	rm -rf bin vcs verdi verilator spike

DFILE := 
ifeq ($(SUB),cache)
DFILE += ../../hvl/common/banked_memory.sv
DFILE += ../../hvl/common/mem_itf.sv
DFILE += ../../hvl/sub/cacheline_adapter_tb.sv
DFILE += ../../hdl/cache/cacheline_adapter.sv
else
DFILE += ../../hvl/sub/sync_fifo_rnd.sv
DFILE += ../../hvl/sub/sync_fifo_tb.sv
DFILE += ../../hvl/sub/sync_fifo_rm.sv
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
