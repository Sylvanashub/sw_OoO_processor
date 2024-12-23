accuracy_requirement = 0.75
analytical_delay = True
bank_select = "bank_select"
bitcell = "bitcell_1port"
bitcell_array = "bitcell_array"
bl_format = "X{name}{hier_sep}xbank0{hier_sep}bl_{row}_{col}"
br_format = "X{name}{hier_sep}xbank0{hier_sep}br_{row}_{col}"
buf_dec = "pbuf"
cell_format = "X{name}{hier_sep}xbank0{hier_sep}xbitcell_array{hier_sep}xreplica_bitcell_array{hier_sep}xbitcell_array{hier_sep}xbit_r{row}_c{col}"
check_lvsdrc = False
column_decoder = "column_decoder"
column_mux_array = "column_mux_array"
config_file = "/pool/gxli/project/Idlefish/mp/mp_ooo_adv/sram/output/btb_sram/btb_sram.py"
control_logic = "control_logic"
coverage = 1
coverage_exe = "coverage run -p "
data_type = "bin"
debug = False
decoder = "hierarchical_decoder"
delay_chain = "delay_chain"
delay_chain_fanout_per_stage = 4
delay_chain_stages = 9
detailed_lef = False
dff = "dff"
dff_array = "dff_array"
drc_exe = None
drc_name = None
dummy_bitcell = "dummy_bitcell_1port"
functional_seed = None
hier_seperator = "."
inline_lvsdrc = False
inv_dec = "pinv"
is_unit_test = False
keep_temp = False
load_scales = [0.5, 1, 4]
local_array_size = 0
lvs_exe = None
lvs_name = None
magic_exe = None
model_name = "elmore"
multi_delay_chain_pinouts = [2, 10, 11, 17, 31]
nand2_dec = "pnand2"
nand3_dec = "pnand3"
nand4_dec = "pnand4"
netlist_only = False
nominal_corner_only = True
num_banks = 1
num_ports = 1
num_r_ports = 0
num_rw_ports = 1
num_sim_threads = 3
num_spare_cols = 0
num_spare_rows = 0
num_threads = 4
num_w_ports = 0
num_words = 16
only_use_config_corners = False
openram_tech = "/pool/gxli/project/Idlefish/mp/OpenRAM-stable/technology/freepdk45/"
openram_temp = "/tmp/openram_gxli_1147_temp/"
output_datasheet_info = True
output_extended_config = True
output_name = "btb_sram"
output_path = "/pool/gxli/project/Idlefish/mp/mp_ooo_adv/sram/output/btb_sram/"
overridden = {'__name__': True, '__doc__': True, '__package__': True, '__loader__': True, '__spec__': True, '__file__': True, '__cached__': True, '__builtins__': True, 'tech_name': True, 'num_rw_ports': True, 'num_r_ports': True, 'num_w_ports': True, 'word_size': True, 'write_size': True, 'num_words': True, 'nominal_corner_only': True, 'process_corners': True, 'supply_voltages': True, 'temperatures': True, 'netlist_only': True, 'route_supplies': True, 'check_lvsdrc': True, 'perimeter_pins': True, 'load_scales': True, 'slew_scales': True, 'output_name': True, 'output_path': True, 'print_banner': True, 'num_threads': True, 'output_extended_config': True}
perimeter_pins = False
pex_exe = None
pex_name = None
precharge = "precharge"
precharge_array = "precharge_array"
print_banner = False
process_corners = ['TT']
ptx = "ptx"
rbl_delay_percentage = 0.5
replica_bitcell = "replica_bitcell_1port"
replica_bitline = "replica_bitline"
rom_data = None
rom_endian = "little"
route_supplies = False
scramble_bits = True
sen_format = "X{name}{hier_sep}xbank0{hier_sep}s_en"
sense_amp = "sense_amp"
sense_amp_array = "sense_amp_array"
sim_data_path = None
slew_scales = [0.5, 1]
spice_exe = ""
spice_name = None
spice_raw_file = None
strap_spacing = 8
supply_pin_type = "ring"
supply_voltages = [1.0]
tech_name = "freepdk45"
temperatures = [25]
top_process = "openram"
tri_gate = "tri_gate"
tri_gate_array = "tri_gate_array"
trim_netlist = True
use_conda = True
use_pex = False
use_specified_corners = None
use_specified_load_slew = None
verbose_level = 0
word_size = 56
wordline_driver = "wordline_driver"
words_per_row = 1
write_driver = "write_driver"
write_driver_array = "write_driver_array"
write_graph = False
write_mask_and_array = "write_mask_and_array"
write_size = 56
