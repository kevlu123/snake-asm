nasm.exe src/snake.asm -f win32 -o intermediates/snake.obj
nasm.exe src/io.asm -f win32 -o intermediates/io.obj
link.exe intermediates/snake.obj intermediates/io.obj lib/kernel32.lib lib/user32.lib /out:build/snake.exe /subsystem:console /entry:main /nologo
