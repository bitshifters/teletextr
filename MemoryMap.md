# Memory map for demo

Demo is BBC Master only so 128Kb RAM available.

```
&0400 - &07FF (1kb)
Exomiser 1Kb decompression buffer

&0800 - &08FF (256 bytes)
Sound workspace

&0900 - &0CFF (1kb)
Free

&0D00 - &0D07
NMI handler (RTI)

&0D07 - &0D9F (156 bytes)
Exomizer workspace

&0E00 - &11FF (1Kb) 
Disksys & Filesys workspace
Offscreen draw buffer

&1200 - &3000
Main exe code

&3000 - &7BFF (Main memory)
Free

&3000 - &7BFF (Shadow memory)
Free

&7C00 - &7FFF
Main & Shadow screen display/draw buffers

&8000 - &BFFF (16kb) - SWR Bank 0
Effects

&8000 - &BFFF (16kb) - SWR Bank 1
Effects

&8000 - &BFFF (16kb) - SWR Bank 2
Effects

&8000 - &BFFF (16kb) - SWR Bank 3
Effects

&8000 - &8FFF (4Kb) - MOS RAM
Free

&C000 - &DFFF (8kb) 
Free / Scratch RAM

```


