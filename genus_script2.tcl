# =============================================================================
# 1. SETUP & READ 111
# =============================================================================
set_db init_lib_search_path [list /home/advancedresearch/asic_synth/run1/mem/lib /home/advancedresearch/asic_synth/run1/mem/sram_macros/lib]
set_db init_hdl_search_path [list /home/advancedresearch/asic_synth/run1/scripts]

set_db library [list stdcells.lib \
  sram_64x1024_1r1w_freepdk45_TT_1p0V_25C.lib \
  sram_64x2048_1r1w_freepdk45_TT_1p0V_25C.lib]

read_hdl -sv -f /home/advancedresearch/asic_synth/run1/scripts/rtl.f

# =============================================================================
# 1.5 CORNER / OPERATING CONDITION
# =============================================================================
puts "OOOOOOOOOOOOOCCCCCCCCCCCCCCCCCCCCCCCCC"
foreach lib [get_db libraries *] {
    puts "LIB: [get_db $lib .name]"
    foreach oc [get_db $lib .operating_conditions] {
        puts "   OC: [get_db $oc .name]"
    }
}

set std_oc [get_db [get_db libraries *stdcells*] .operating_conditions -if {.name == "typical"}]

if {$std_oc != ""} {
    set_db / .operating_conditions [lindex $std_oc 0]
} else {
    set_db / .operating_conditions [lindex [get_db [get_db libraries *stdcells*] .operating_conditions] 0]
}

# --- 3. Elaborate ---
elaborate Top
current_design Top

puts "CHECKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK"
puts "=== SRAM LIB CELLS ==="
foreach c [get_db lib_cells *sram*] {
    puts [get_db $c .name]
}

puts "=== SRAM HDL MODULES ==="
foreach m [get_db modules *sram*] {
    puts [get_db $m .name]
}

puts "=== SRAM INSTANCES ==="
foreach i [get_db insts *u_sram*] {
    puts "inst=[get_db $i .name]"
}
puts "DONE CHECKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK"



# --- 2. VERIFICATION ---
check_design -unresolved
catch {report_ports -direction out}

# --- 3. HIERARCHY PROTECTION ---
# Use 'force_preserve_hierarchy' as 'preserve_hierarchy' failed before
catch {set_db [get_db designs Top] .force_preserve_hierarchy true}


# Keep only the top output nets (safe, light)
catch {set_db [get_nets -hier *dout*] .dont_touch true}
catch {set_db [get_nets -hier *dbg_valid*] .dont_touch true}
catch {set_db [get_nets -hier *done*] .dont_touch true}

# =============================================================================
# 4. OOM / PBS MEMORY REDUCTION
# =============================================================================
catch {set_db / .max_num_cpus 1}
catch {set_db / .max_cpus_per_server 1}
catch {set_db / .max_cpus_per_host 1}
catch {set_db / .distributed_synthesis false}
catch {set_db / .partition_based_synthesis false}

catch {set_db / .syn_global_effort low}
catch {set_db / .syn_generic_effort low}
catch {set_db / .syn_map_effort low}
catch {set_db / .syn_opt_effort low}

# =============================================================================
# 5. DISABLE TURBO / PRE_RTLOPT
# =============================================================================
catch {set_db / .syn_use_turbo false}
catch {set_db / .use_turbo false}
catch {set_db / .turbo_flow false}
catch {set_db / .enable_turbo false}
catch {set_db / .turbo false}
catch {set_db / .rtl_optimize false}
catch {set_db / .enable_rtlopt false}
catch {set_db / .do_rtlopt false}

# =============================================================================
# 6. SYNTHESIS
# =============================================================================
read_sdc /home/advancedresearch/asic_synth/run1/constraints/top.sdc
set_db [get_db designs Top] .activity_rate 0.1
set_db [get_db designs Top] .toggle_rate 0.1

# syn_generic
set _no_turbo_ok 1
if {[catch {syn_generic -no_turbo} _msg]} {
    puts "NOTE: syn_generic -no_turbo not supported on this Genus. Falling back to syn_generic."
    set _no_turbo_ok 0
    syn_generic
}



report_area   > /home/advancedresearch/asic_synth/run1/reports/report_area_generic.rpt
report_qor    > /home/advancedresearch/asic_synth/run1/reports/report_qor_generic.rpt
report_timing > /home/advancedresearch/asic_synth/run1/reports/report_timing_generic.rpt
puts "SYN GENERIC DONEEEEEEEEEEEEEEEEEEEEEE (turbo disabled=${_no_turbo_ok})."

# syn_map
syn_map
report_area   > /home/advancedresearch/asic_synth/run1/reports/report_area_map.rpt
report_qor    > /home/advancedresearch/asic_synth/run1/reports/report_qor_map.rpt
report_timing > /home/advancedresearch/asic_synth/run1/reports/report_timing_map.rpt

# syn_opt
syn_opt
report_area   > /home/advancedresearch/asic_synth/run1/reports/report_area_opt.rpt
report_qor    > /home/advancedresearch/asic_synth/run1/reports/report_qor_opt.rpt
report_timing > /home/advancedresearch/asic_synth/run1/reports/report_timing_opt.rpt


puts "SYN OPT DONEEEEEEEEEEEEEEEEEE Mapped reports generated."

puts "SENDING TO WINDOWSSSSSSSSSSSSSSSSSSSSSSSSS."

catch {exec cp -r /home/advancedresearch/asic_synth/run1/logs/* /media/sf_srcs_asic/asic_synth_offload/run1/logs/}
catch {exec cp -r /home/advancedresearch/asic_synth/run1/reports/* /media/sf_srcs_asic/asic_synth_offload/run1/reports/}
exit