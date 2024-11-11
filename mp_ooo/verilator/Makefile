
DFILE :=
DFILE += ./lint.vlt
DFILE += ../pkg/types.sv
DFILE += ../hdl/core/itf.sv
DFILE += ../hdl/core/ooo.sv
DFILE += ../hdl/core/alu.sv
DFILE += ../hdl/core/rvs.sv
DFILE += ../hdl/core/rfu.sv
DFILE += ../hdl/core/dec.sv
DFILE += ../hdl/core/cdb.sv
DFILE += ../hdl/core/lsu.sv
DFILE += ../hdl/core/rob.sv
DFILE += ../hdl/core/mdu.sv

DFILE += ../hdl/cpu.sv
DFILE += ../hdl/cache/lru_array.sv
DFILE += ../hdl/cache/cacheline_adapter.sv
DFILE += ../hdl/cache/valid_array.sv
DFILE += ../hdl/cache/cache.sv
DFILE += ../hdl/cache/icache.sv
DFILE += ../hdl/core/sync_fifo.sv
DFILE += ../hdl/core/fetch.sv
DFILE += ./DW_div_seq.sv
DFILE += ./DW_mult_seq.v

DFILE += ../sram/output/mp_cache_data_array/mp_cache_data_array.v
DFILE += ../sram/output/mp_cache_tag_array/mp_cache_tag_array.v

OPTS :=
OPTS += --lint-only
OPTS += -Wall
#OPTS += -I../
OPTS += -Wno-DECLFILENAME
OPTS += -Wno-PINCONNECTEMPTY


all:
	verilator $(OPTS) $(DFILE)
