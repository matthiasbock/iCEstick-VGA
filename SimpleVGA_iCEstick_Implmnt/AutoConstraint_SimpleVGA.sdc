
#Begin clock constraint
define_clock -name {SimpleVGA|Clock12MHz} {p:SimpleVGA|Clock12MHz} -period 1000.000 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 500.000 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {SimpleVGA|ClockVGA_derived_clock} {n:SimpleVGA|ClockVGA_derived_clock} -period 1000.000 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 500.000 -route 0.000 
#End clock constraint
