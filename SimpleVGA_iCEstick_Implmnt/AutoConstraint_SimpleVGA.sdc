
#Begin clock constraint
define_clock -name {SimpleVGA|Clock12MHz} {p:SimpleVGA|Clock12MHz} -period 28.601 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 14.300 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {PixelClock_PLL|PLLOUTCORE_derived_clock} {n:PixelClock_PLL|PLLOUTCORE_derived_clock} -period 28.601 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 14.300 -route 0.000 
#End clock constraint
