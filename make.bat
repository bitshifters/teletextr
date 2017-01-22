@echo off
if not exist "bin" mkdir bin


rem BeebAsm.exe -v -i src/music/module.asm 
rem BeebAsm.exe -v -i src/3d/module.asm

BeebAsm.exe -v -i teletextr.asm -do teletextr.ssd -boot Teletxr
