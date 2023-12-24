code segment
    assume cs:code
start:
    mov dx,287h ;表示方式命令寄存器
    mov al,00110111b
    out dx,al  ；将方式命令字写进去，
    mov dx,284h ;0号计时器
    mov ax,1000; 送入数字
    out dx,al
    mov al,ah
    out dx,al
    mov dx,287h ;表示方式命令寄存器
    mov al,01110111b
    out dx,al  ；将方式命令字写进去，
    mov dx,285h ;1号计时器
    mov ax,1000; 送入数字
    out dx,al
    mov al,ah
    out dx,al
  code ends
    end start
  