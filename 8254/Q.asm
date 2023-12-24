code segment
    assume cs:code
start:
    mov dx,287h ;表示方式命令寄存器
    mov al,00110001B;    00选计数器0，11表示从低到高读取，000表示方式0，BCD码十进制；
    out dx,al  ；将方式命令字写进去，
    mov dx,284h ;0号计时器
    mov ax,5; 送入数字
    out dx,al
    mov al,ah
    out dx,al  ;两次送入数据
code ends
 end start