# Wrapper so that `make` works from PowerShell / Windows Terminal.
# GNU make runs recipes with cmd.exe here (no sh on PATH).
# makekc.bat is the variant that finds beebasm through ..\..\bin (D:\beeb\Bin);
# make.bat expects BeebAsm.exe on the PATH, which it is not on this machine.
.PHONY: all build help
all: build

build:
	cmd /c .\makekc.bat

help:
	@echo make        - build teletextr.ssd (runs makekc.bat; listing in compile.txt)
	@echo make help   - this list
	@echo runkc.bat launches B-em with teletextr.ssd.
