
#Begin clock constraint
define_clock -name {SimpleVGA|Clock12MHz} {p:SimpleVGA|Clock12MHz} -period 31.165 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 15.582 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {PLL|PLLOUTCORE_derived_clock} {n:PLL|PLLOUTCORE_derived_clock} -period 31.165 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 15.582 -route 0.000 
#End clock constraint
