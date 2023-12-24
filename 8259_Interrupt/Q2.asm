;利用 8255PC6 口作为中断源
DATA SEGMENT
MESS DB 'TPCA INTERRUPT3!',0DH,0AH,'$'
DATA ENDS
CODE SEGMENT
ASSUME CS:CODE, DS:DATA

DELAY PROC NEAR
    PUSH BX
    PUSH CX
    MOV CX, 1FFFH
    DL1:MOV BX, 0FFFH
    DL2:DEC BX
        JNZ DL2
    DEC CX
    JNZ DL1
    POP CX
    POP BX
    RET
DELAY ENDP

INT3 PROC NEAR  ;中断服务程序
    DEC CX
    MOV AX, DATA
    MOV DS, AX
    MOV DX, OFFSET MESS ;送“字符串的偏移地址”到 DX
    MOV AH, 09 ;选择 DOS 的 09 号功能，显示字符串
    INT 21H ;调用 DOS
    XOR BL, 11111111B ;异或操作，将 LED 灯的状态取反
    MOV AL, BL ;
    MOV DX, 281H ;设置 PB 数据口地址
    OUT DX, AL ;输出 LED 灯的新状态
    CALL DELAY 
    MOV AL, 63H ;01100011B，指定中断结束方式: ;完全嵌套方式，最高级中断结束，自动结束，中断等
;级编号为 011
    OUT 20H, AL ;送 OCW2 内容到 20H 端口
    IRET
    INT3 ENDP


START:
    CLI ;关中断
    MOV AX, CS ;
    MOV DS, AX ;将调用参数“段基址地址 CS”装入 DS 中
    MOV DX, OFFSET INT3 ;将调用参数“中断服务程序的偏移地址 IP”装入 DX 中
    MOV AX, 250BH ;送 DOS 功能号 25H 到 AH，25 号功能为向中断向量表
;中写入中断向量
    ;送子功能号（中断向量号）0BH 到 AL
    INT 21H ;调用 DOS

    IN AL, 21H ;回读 21H 端口的内容
    AND AL, 0F7H ;设置中断屏蔽字为 11110111B，开放 IRQ3
    OUT 21H, AL ;送 OCW1 内容到奇端口

    MOV CX, 5 ;设置计数值为 5
    STI ;开中断

    MOV DX, 283H ;设置 8255 命令口地址
    MOV AL, 10000000B ;初始化命令字，方式 0，B 口输出
    OUT DX, AL ;送命令字到命令口
    MOV DX, 281H ;设置 PB 数据口地址
    MOV BL, 00000000B ;设置 LED 灯初始状态，用 BL 保存
    MOV AL, BL ;
    OUT DX, AL ;送 LED 灯状态到数据口
LL:
    MOV DX, 283H
    MOV AL, 00001100B ;将 PC6 置为低电平
    OUT DX, AL
   ; CALL DELAY ;维持低电平
    MOV DX, 283H
    MOV AL, 00001101B ;将 PC6 置为高电平
    OUT DX, AL
    ;CALL DELAY
    CMP CX,0
    JNE LL

    IN AL, 21H ;回读 21H 端口的内容
    OR AL, 08H ;中断结束，设置中断屏蔽字为 00001000B，屏蔽
    ;IRQ3
    OUT 21H, AL ;送 OCW1 内容到 21H 端口
    STI ;开中断
    MOV AX, 4C00H ;选择 DOS 的 4CH 号功能，返回 DOS
    INT 21H ;调用 DOS

CODE ENDS
END START