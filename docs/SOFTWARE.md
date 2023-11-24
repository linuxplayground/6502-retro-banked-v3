# ROM

I have leaned hevily on the commander x16 project for this work.  Rather than use Commodore Basic, I have
gone with ehBasic.  ehBasic has quite an extensive zeropage usage.  See the linker scripts in the 
`rom/cfg` folder for details.

## JSRFAR and RSTFAR

I have not been able to successfully use JSRFAR to reset the CPU into a specific ROM.  My workaround is the
`rstfar` function defined in `rom/kern/memory.s`.

