# Memory map for demo

Demo is BBC Master only so 128Kb RAM available.

```
&0400 - &07FF
&0800 - &08FF
&0900 - &0CFF
&0E00 - &1100
&1100 - &3000
&3000 - &7BFF - Main
&3000 - &7BFF - Shadow

&7C00 - &7FFF - Main & Shadow screen display/draw buffers

&8000 - &BFFF - SWR Bank 0
&8000 - &BFFF - SWR Bank 1
&8000 - &BFFF - SWR Bank 2
&8000 - &BFFF - SWR Bank 3

&C000 - &DFFF - Scratch RAM
```


