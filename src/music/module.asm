; Music data module

ORG &8000
GUARD &BFFF

.module_start

.initialise EQUW 0
.update     EQUW 0

INCBIN "src/music/data/music.raw.exo"
;music player cant be in SWR as it accesses data in another bank

.module_end


PRINT "Code from", ~module_start, "to", ~module_end, ", size is", (module_end-module_start), "bytes"

SAVE "bin/music.bin", module_start, module_end