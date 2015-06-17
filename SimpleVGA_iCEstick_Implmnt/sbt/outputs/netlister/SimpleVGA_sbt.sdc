create_clock -period 1000.00 -name {SimpleVGA|Clock12MHz} -waveform [list 0.00 500.00] [get_ports Clock12MHz]
create_generated_clock -name {SimpleVGA|ClockVGA_derived_clock} -source [get_pins ClockVGA_LC_1_7_6/clk] [get_pins ClockVGA_LC_1_7_6/lcout] -add -master_clock [get_clocks SimpleVGA|Clock12MHz]
set_multicycle_path 2 -setup -from [get_clocks SimpleVGA|ClockVGA_derived_clock] -to [get_clocks SimpleVGA|ClockVGA_derived_clock]
