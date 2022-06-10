nasm.exe src/snake.asm -f win32 -o intermediates/snake.obj
nasm.exe src/io.asm -f win32 -o intermediates/io.obj
nasm.exe src/util.asm -f win32 -o intermediates/util.obj
nasm.exe src/rng.asm -f win32 -o intermediates/rng.obj
link.exe intermediates/snake.obj intermediates/io.obj intermediates/util.obj intermediates/rng.obj lib/kernel32.lib lib/user32.lib /out:build/snake.exe /subsystem:console /entry:main /nologo
