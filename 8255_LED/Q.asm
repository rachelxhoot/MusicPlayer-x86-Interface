code segment
assume cs:code
start:
	mov dx,283h  ；     对芯片工作状态初始化
	mov al,10001001b  ； 送入方式命令字 （1特征位表示方式命令，00表示0方式，0默认A口，1代表pc4-7为输入，0表示B组方式为0，0表示pb为输出，1：pc0-3为输入）
	out dx,al   ；将方式命令字送入端口
	xor bx,bx ；清零备用下面bx
	


main: call check_look   ;检查开关状态，更新
      call show_light   ；显示LED灯
      jmp main	；无条件跳转

check_look proc near
    mov dx,282h   ;  pc端口状态，pc为开关输入
    in al,dx    	；读取pc状态
    
    cmp al,bh  	 ；bh存的是之前状态，bh与al比较查看是否更新状态
    je tuichu       	；同退出
    mov bl,al 	 ;   不同，则将当前状态输入bl，流水保存
    mov bh,al  	 ; 更新当前状态
tuichu: ret    	；退出
check_look endp

show_light proc near     
    mov dx,281h         ;b端口为输出，故用281
    mov  al,bl ;     bl读入开关状态
    out dx,al   ；将开关状态送给b端口
    call delay    ；时延
    ror bl,1   ;循环右移
    ret
show_light endp

delay proc near
    push bx
    push cx  ;先将寄存器存的值入栈

    mov cx, 04fffh  ；第一层循环
delay1: 
    mov bx,00ffh ；第二层循环
delay2: dec bx
    jnz delay2
    dec cx
    jnz delay1
    pop cx
    pop bx
ret
delay endp
code ends
 end start

	