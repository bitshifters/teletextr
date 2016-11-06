# Task list for demo

## routines

* SWR switcher
* SWR loader/unpacker
* Install exomizer into mem
* IRQ handler
* Display manager
* Routine address vector table (for registering routines)
* Interpolator
* Intro sequencer
* Effect manager
* Music player
* Support multiple exo streams (since VGM unpacks as it goes)

## Tools

* Module compiler
* Sequencer compiler


## modules

A module is a chunk of code (upto 16kb uncompressed) loaded into a memory location or SWR bank 
Modules are stored on disk in compressed format, they are unpacked at runtime

Modules contain effects
- an effect is a specific layer that can render or run


* Modules are assembled individually
* They are loaded into SWR banks at &8000
* They can use any ZP from &00-&6F
* Each module has a header:
* 
* `initialise` routine address
* `update` routine address
*
* Any active module cannot access data or code from another module

&0400 = 1Kb
&0800 = 2Kb
&0C00 = 3Kb
&1000 = 4Kb
&4000 = 16Kb


&8000-&BFFF = 16Kb
&2000-&2FFF = 4Kb

&0E00-&11FF = 4Kb 
&1200-&31FF = 8Kb
&3200-&5FFF = 8Kb

&1000-&6FFF = 

&7000-&73ff = 1Kb
&7400-&77FF = 1Kb
&7800-&7BFF = 1Kb
&7C00-&7FFF = 1Kb

4x16Kb SWR = 64Kb memory

SSD = 200kb, approx 12x 16Kb blocks. 

1 bank for 

DFS loading speed is about 5.3Kb/sec
Assume EXO gives 50% compression, takes half as long to load and Saves disk space. 
If unpack rate > than load speed, then there's a speed saving too

filling one 16Kb ram bank takes 3.08 secs
filling 3 takes 9.24 secs




## logging

bput print to logfile on the SSD

1. want fast loading
2. dont want load delays during demo
3. dont want resources packed during demo (for speed)
4. full ram = 64K SWR plus 20Kb vram, plus 8Kb &1000-&2fff, use lower mem for workspace, total 92Kb
5. want to make it easy to test effects standalone
6. each effect will likely use a lot of common code, dont want to duplicate code either in memory or on disk

compression = 46Kb = 9 seconds load + 4 seconds unpack = 13 seconds full load
disk = 200Kb = 4 full memory loads

can run IRQ rendering in BG


demo framework runs at &900?


# scheme 1
use main mem for code routines
use swr for data?
problem - makes it harder to create standalone effects (with data contained within)


# scheme 2
use main mem for common routines
use swr for compiled effects
problem - effects must fit into 16kb and harder to code standalone effects

# scheme 3
use swr as decompression buffer, store effects in compressed format
unpack to main memory and run

gain - can treat each demo as a standalone executable and pack them all upto
can treat 48kb of SWR as data area

problems
how to run different effects together?
need to build each effect with own org address that is compatible with other effects

# scheme 4
treat code as one big compilation of code
put resources/data into swr banks

main demo is a sequencer of effects
each effect has an init and an update routine
main memory for code
swr for data

each effect in a separate folder and contains:
    demo
    module
    data

ALL COMMON CODE GOES INTO LIB
ALL DEMO SPECIFIC CODE GOES INTO EFFECT MODULE


maindemo
    include player code
    include common LIB code
        for all effects:
            include effect code module - (incudes ORG 0 for headers but preserves ORG for code, does not include common code )
        for all effects:
            include effect data, into 16Kb banks
    save code
    save data banks

demo
    include common code dependencies
    include effect code module
    main loop for demo
    compiled to standalone ssd



one big load
&