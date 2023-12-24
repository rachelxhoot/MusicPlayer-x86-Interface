;8255 实现 ADC0809模拟量通道号选择信号   通道0
;启动信号
;读数据允许信号

;EOC的中断请求：  直接连到系统总线的IRQ3上  


;通道0的数据采集相关程序段：


STACKS SEGMENT 
    DW 256 DUP(?)
STACKS  ENDS

DATA SEGMENT 
    OLD_OFF DW ?
    OLD_SEG DW ?
    BUFR DB 100 DUP(0)
    PRT DW ?
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, ES:DATA
ADC_START:
    MOV AX,DATA
    MOV DS,AX
    MOV ES,AX
    MOV AX,STACKS
    MOV SS,AX

    MOV AX,350BH;
    INT 21H

    MOV OLD_OFF ,BX
    MOV BX,ES
    MOV OLD_SEG,BX      ;保护现场

    CLI   ;关中断，写中断向量表

    MOV AX,250BH;  置新中断向量
    MOV DX, SEG A_D  ;段地址
    MOV DS,DX
    MOV DX,OFFSET A_D;  偏移地址
    INT 21H;  回调，向量表填写


    MOV AX,DATA;  恢复数据段
    MOV  DS,AX
    STI;  开中断

    IN AL,21H  奇数端口读取
    AND AL,11110111B  ;开放IRQ3
    OUT 21H,AL

    MOV BX,100 ;设置采集字节数
    MOV AX,OFFSET BUFR;  设置内存指针
    MOV PRT,AX

    


BEGIN: 
    MOV DX,298H
    OUT DX,AL    ;启动转换
    

    STI ; 开中断
    HLT; 等待中断
    CALL DELAY
    ;DEC CX ; 采样次数-1
    CMP BX,0
    JNZ BEGIN;  计数没完返回BEGIN


    CLI; 计数已完，关中断 
    MOV AX,250BH; 恢复IRQ3的原中断向量，子功能号的0CH

    MOV DX, OLD_SEG
    MOV DS,DX
    MOV DX , OLD_OFF
    INT 21H 
    MOV AX,DATA
    MOV DS,AX ;恢复现场
    STI; 开中断
    IN AL,21H
    OR AL,00001000B ;关屏蔽字
    OUT 21H, AL  写入奇数端口
    MOV AX, 4C00H
    INT 21H

A_D PROC FAR   ;中断服务程序
    PUSH AX  ;保护现场
    ;PUSH CX;
    PUSH DX;
    PUSH DI;
    CLI ;关中断
    DEC BX


    MOV DX,298H
    IN  AL,DX;  从PA口读数据， 
    NOP
    MOV DI,PRT
    MOV [DI] ,AL
    INC DI
    MOV PRT,DI  ;更新PRT

    MOV CH,AL; 保存AL值
    MOV CL,4
    SHR AL,CL; 右移四位，
    CALL  DISP ; 调用子程序显示高4位

    MOV AL,CH
    AND AL,0FH;  保存的高四位重新放入AL,相与,取低四位数
    CALL DISP 

    MOV AH ,02H
    MOV DL,'H'
    INT 21H

    MOV DL,0DH
    INT 21H
    MOV DL,0AH
    INT 21H

    
    MOV AL,20H  ;发中断结束指令
    OUT 20H,AL

    ;MOV [DI],AH ;  存数据
    ;INC DI
    
    POP DI
    POP DX  ;恢复现场
   ; POP CX
    POP AX 
    STI  ;开中断
    IRET
A_D ENDP

DISP PROC NEAR 
    MOV DL,AL
    CMP DL,9
    JLE SHUZI
    ADD DL,7
SHUZI:
    ADD DL,30H
    MOV AH,02
    INT 21H ;+30后显示
    RET
DISP ENDP

DELAY PROC NEAR    ;延时子程序
      PUSH CX  
      PUSH BX      
      MOV CX,0870H  
    LP1:MOV BX,0184FH  
    LP2: DEC BX
        JNZ LP2
        DEC CX
        JNZ LP1
        POP BX
        POP CX
        RET  
DELAY ENDP   


CODE ENDS
    END ADC_START



    






