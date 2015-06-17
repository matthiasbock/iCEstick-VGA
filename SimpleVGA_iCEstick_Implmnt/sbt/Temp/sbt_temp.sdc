####---- CreateClock list ----1
create_clock  -period 1000.00 -waveform {0.00 500.00} -name {SimpleVGA|Clock12MHz} [get_ports {Clock12MHz}] 

####---- CreateGenClock list ----1
create_generated_clock  [get_pins {ClockVGA/Q}]  -source [get_pins {ClockVGA/C}]  -add -master_clock [get_clocks {SimpleVGA|Clock12MHz}] -name {SimpleVGA|ClockVGA_derived_clock} 

####---- SetMultCyclePath list ----1
set_multicycle_path -setup  -from [get_clocks {SimpleVGA|ClockVGA_derived_clock}]  -to [get_clocks {SimpleVGA|ClockVGA_derived_clock}] 2 

