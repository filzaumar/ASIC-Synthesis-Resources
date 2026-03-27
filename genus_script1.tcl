set_db init_lib_search_path [list /home/advancedresearch/asic_synth/run1/mem/lib /home/advancedresearch/asic_synth/run1/mem/sram_macros/lib]
set_db init_hdl_search_path [list /home/advancedresearch/asic_synth/run1/scripts]

set_db library [list slow_vdd1v0_basicCells.lib \
  sram_64x1024_1r1w_freepdk45_TT_1p0V_25C.lib \
  sram_64x2048_1r1w_freepdk45_TT_1p0V_25C.lib]

read_hdl -sv -f /home/advancedresearch/asic_synth/run1/scripts/rtl.f

# Instead of searching and matching, we will grab the first valid nominal condition
set nominal_cond [get_db [get_db libraries *sram*] .operating_conditions -if {.name == "*nominal*"}]

if {$nominal_cond != ""} {
    set_db / .operating_conditions [lindex $nominal_cond 0]
} else {
    # Fallback: Just use the SRAM library's default condition directly
    set_db / .operating_conditions [get_db [get_db libraries *sram*] .operating_conditions]
}

# --- Correct Debug Command ---
elaborate Top
put "PORTSSSSSSSSSSSSSSSSSSSSSSS
report_ports
puts "PORTS:"
foreach p [get_db ports *] {
    puts [get_db $p .name]
}