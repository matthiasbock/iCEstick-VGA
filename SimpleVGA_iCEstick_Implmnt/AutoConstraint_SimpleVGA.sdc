
#Begin clock constraint
define_clock -name {SimpleVGA|Clock12MHz} {p:SimpleVGA|Clock12MHz} -period 27.199 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 13.599 -route 0.000 
#End clock constraint

#Begin clock constraint
define_clock -name {PLL|PLLOUTCORE_derived_clock} {n:PLL|PLLOUTCORE_derived_clock} -period 27.199 -clockgroup Autoconstr_clkgroup_0 -rise 0.000 -fall 13.599 -route 0.000 
#End clock constraint
