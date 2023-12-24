;地址译码(280H～287H) 接 8255 片选端口；
;单脉冲开关 接 总线 MIRQ3 口；
;8255 PB 口 接 LED 模块 L0～L7。




DATA SEGMENT
MESS DB 'TPCA ********ZHU****INTERRUPT3!',0DH,0AH,'$'
MESS1 DB 'TPCA ********CONG****!',0DH,0AH,'$'
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA


START:
    CLI 			;关中断
    MOV AX, CS ;
    MOV DS, AX		 ;将调用参数“段基址地址 CS”装入 DS 中  送主中断
    MOV DX, OFFSET INT3	 ;将调用参数“中断服务程序的偏移地址 IP”装入 DX 中
    MOV AX, 250BH		 ;送 DOS 功能号 25H 到 AH，25 号功能为向中断向量表
   			 ;中写入中断向量
  			  ;送子功能号（中断向量号）0BH 到 AL
    INT 21H	 	;调用 DOS

    MOV DX, OFFSET CONG2	 ;将调用参数“中断服务程序的偏移地址 IP”装入 DX 中
    MOV AX, 2572H 		;送 DOS 功能号 25H 到 AH，25 号功能为向中断向量表
   			 ;中写入中断向量  从中断
  			  ;送子功能号（中断向量号）72H 到 AL
    INT 21H 		;调用 DOS


    IN AL, 21H 		;回读 21H 端口的内容
    AND AL, 0F7H 		;设置中断屏蔽字为 11110111B，开放 IRQ3
    OUT 21H, AL		 ;送 OCW1 内容到奇端口

    IN AL,0A1H
    AND AL,11111011B 	 ;开放从片IRQ2
    OUT 0A1H,AL 		 ;送屏蔽字

    MOV CX, 10		 ;设置计数值为 10





MOV DX, 283H 		;设置 8255 命令口地址
MOV AL, 10000000B 	;初始化命令字，方式 0，B 口输出
OUT DX, AL		 ;送命令字到命令口
MOV DX, 281H		 ;设置 PB 数据口地址
MOV BL, 11110000B 	;设置 LED 灯初始状态，用 BL 保存
MOV AL, BL ;
OUT DX, AL		 ;送 LED 灯状态到数据口

LL:
    STI
    CMP CX, 0
    JNE  LL;


IN AL, 21H 		;回读 21H 端口的内容
OR AL, 08H 		;中断结束，设置中断屏蔽字为 00001000B，屏蔽
			;IRQ3
OUT 21H, AL		 ;送 OCW1 内容到 21H 端口

;STI			 ;开中断

IN AL, 0A1H		 ;回读 21H 端口的内容
OR AL, 00000100 		;中断结束，设置中断屏蔽字为 00001000B，屏蔽
			;IRQ2
OUT 0A1H, AL 		;送 OCW1 内容到 0A1H 端口
;STI 			;开中断

MOV AX, 4C00H		 ;选择 DOS 的 4CH 号功能，返回 DOS
INT 21H 			;调用 DOS




CONG2 PROC NEAR	 ;从中断服务程序
    MOV AX, DATA
    DEC CX
    MOV DS, AX
    MOV DX, OFFSET MESS1     ;送“字符串的偏移地址”到 DX
    MOV AH, 09		 ;选择 DOS 的 09 号功能，显示字符串
    INT 21H		 ;调用 DOS
    XOR BL, 11111111B 	;异或操作，将 LED 灯的状态取反
    MOV AL, BL ;
    MOV DX, 281H		 ;设置 PB 数据口地址
    OUT DX, AL 		;输出 LED 灯的新状态
    MOV AL, 20H 		;01100010B，指定中断结束方式: ;完全嵌套方式，结束当前中断，非自动结束，中断等
           			 ;级编号为 010
    OUT 0A0H, AL 		;送 OCW2 内容到 0A0H 端口
     OUT 20H,AL
    IRET
    CONG2 ENDP


INT3 PROC NEAR
    			 ;中断服务程序
    MOV AX, DATA
    MOV DS, AX
    DEC CX
    MOV DX, OFFSET MESS 	;送“字符串的偏移地址”到 DX
    MOV AH, 09 		;选择 DOS 的 09 号功能，显示字符串
    INT 21H		 ;调用 DOS
    XOR BL, 11111111B	 ;异或操作，将 LED 灯的状态取反
    MOV AL, BL ;
    MOV DX, 281H		 ;设置 PB 数据口地址
    OUT DX, AL 		;输出 LED 灯的新状态
    MOV AL, 20H		 ;01100011B，指定中断结束方式: ;完全嵌套方式，结束当前中断，非自动结束，中断等
   			 ;级编号为 011
    OUT 20H, AL 		;送 OCW2 内容到 20H 端口
    IRET
    INT3 ENDP

DELAY PROC NEAR
    PUSH BX
    PUSH CX
    MOV CX, 1FFFH
    DL1:MOV BX, 4FFFH
    DL2:DEC BX
    JNZ DL2
    DEC CX
    JNZ DL1
    POP CX
    POP BX
    RET
    DELAY ENDP

CODE ENDS
    END START