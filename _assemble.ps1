rgbasm -L -o build/main.o main.asm
rgbasm -L -o build/gameboy_helpers.o gameboy_helpers.asm
rgblink -o build/gamerom.gb -m build/gamerom.map -n build/gamerom.sym build/main.o build/gameboy_helpers.o
rgbfix -v -p 0xFF build/gamerom.gb
PAUSE