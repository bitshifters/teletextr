@echo off
for %%x in (*.txt) do ..\..\tools\teletext2bin.py %%x %%x.bin


for %%x in (*.bin) do ..\..\tools\exomizer.exe raw -c -m 1024 %%x -o %%x.exo
pause