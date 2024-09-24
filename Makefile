%:
	g++ -mavx512f -Wall -Wextra -std=c++17 -o ./solution$@/main ./solution$@/main.cpp
	./solution$@/main

	nasm -f elf -o solution$@/main.o solution$@/main.asm
	ld -m elf_i386 -o solution$@/main solution$@/main.o
	./solution$@/main