.model small 
.386
DSEG SEGMENT
    PORTA EQU 280H; A端口
    PORTB EQU 281H; B端口
    PORTC EQU 282H; C端口
    PORTD EQU 283H; 命令与状态口
    K8254 EQU 28FH; 8254命令口
    A8254 EQU 28CH; 8254A口

porth equ 298H
PORTR EQU 290H

    INT_OFF DW ?
    INT_SEG DW ?
    BUF DB 'Input song number:' ,0DH,0AH,'$' ;0DH回车，0AH换行
    BUF2 DB 'IN SW!' ,0DH,0AH,'$' ;0DH回车，0AH换行
    BUF3 DB 'NEXT SONG!' ,0DH,0AH,'$' ;0DH回车，0AH换行
    BUF4 DB 'END SW!' ,0DH,0AH,'$' ;0DH回车，0AH换行
    SONG DB ?        ;输入歌曲序号
    
    STT1 DB 0
    STT2 DB 0
    STT3 DB 0

    STIME DW 0
    ;小键盘输入判断
    TABLE2 DW 0770H,0B70H,0D70H,0E70H,07B0H,0BB0H,0DB0H,0EB0H
           DW 07D0H,0BD0H,0DD0H,0ED0H,07E0H,0BE0H,0DE0H,0EE0H

    ;输出按键的字符
    CHAR DB '0123456789ABCDEF'

    ; 音符
    TABLE1 DW 524,588,660,698,784,880,988
           DW 262,294,330,347,392,440,494

    ; 曲子
    ;频率
    ASONGF DB 1,2,3,1,1,2,3,1,3,4,5,3,4,5
           DB 5,6,5,4,3,1,5,6,5,4,3,1,1,12,1,1,12,1,0FFH
    ;时长
    ASONGT DB 2,2,2,2,2,2,2,2,2,2,4,2,2,4,1,1,1,1,2,2
           DB 1,1,1,1,2,2,2,2,4,2,2,4

    BSONGF DB 3,2,1,7,5,5,6,5,3,1,7,7,1,2,3,1,2,3,2,1,1,7,4,2,3,4,3,2,1,7,5,0FFH
    ;时长
    BSONGT DB 1,2,1,2,2,3,2,2,2,2,4,2,2,2,4,1,1,2,2,1,2,1,3,4,1,1,1,3,1,2,1,2

    CSONGF DB 1,1,5,5,6,6,5,4,4,3,3,2,2,1,5,5,4,4,3,3,2,5,5,4,4,3,3,2,0FFH
    ;时长
    CSONGT DB 1,1,1,1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,1,1,2,1,1,1,1,1,1,2
           

DSEG ENDS


CSEG SEGMENT
ASSUME CS:CSEG,DS: DSEG
START: 


MAIN PROC
      MOV AX,DSEG
      MOV DS,AX  

      ;获取原中断向量
      MOV AX,350BH
      INT 21H      ;设置MIRQ3的中断矢量
      MOV INT_OFF,BX   ;获取中断向量的偏移地址
      MOV INT_SEG,ES   ;获取中断向量的段地址

      ;装入新中断向量
      CLI          ;关中断，避免扰乱中断向量
      MOV DX,SEG SW_INT ;设置新的中断向量
      MOV DS,DX         ;DS指向新中断服务程序段地址
      MOV DX,OFFSET SW_INT   ;DX指向新中断服务程序偏移量
      MOV AX,250BH ;新中断向量
      INT 21H
      MOV AX,DSEG  ;恢复数据段
      MOV DS,AX

      ;开放主片MIRQ3的中断屏蔽
      IN AL,21H
      AND AL,11110111B  ;将主片的IRQ3置零，IMR允许中断申请
      OUT 21H,AL

      ;初始化8254
      MOV DX,K8254
      MOV AL,36H ; 0号计数器（A），两次读取先低后高，选择方式3，计数初值为2进制
      OUT DX,AL

INPUT:STI              ;开中断
      MOV DX,OFFSET BUF
      MOV AH,9
      INT 21H
     
      MOV DX,A8254
      MOV AX,0000H
      OUT DX,AL
      MOV AL,AH
      OUT DX,AL

      CALL DELAY2
      CALL GET_SONG
      MOV AL,SONG
      CMP AL,0
      JZ INPUT  

      CALL CHANGE_SONG      ;切换歌曲

      JMP INPUT
      
      ;中断结束恢复原中断向量
      CLI              ;关中断
      MOV DX,INT_SEG
      MOV DS,DX
      MOV DX,INT_OFF
      MOV AX,250BH     ;恢复主片
      INT 21H
      MOV AX,DSEG
      MOV DS,AX

      ;中断结束屏蔽主片MIRQ3
      IN AL,21H
      OR AL,00001000B  
      OUT 21H,AL

      MOV AX, 4C00H
      INT 21H
MAIN ENDP


SW_INT PROC FAR
      ;CLI          ;关中断
      PUSH AX
      PUSH DX

      MOV DX,OFFSET BUF2
      MOV AH,9    ;DOS功能号，显示字符串
      INT 21H

INPUT1:MOV DX,OFFSET BUF3
      MOV AH,9
      INT 21H

      MOV DX,A8254
      MOV AX,0000H
      OUT DX,AL
      MOV AL,AH
      OUT DX,AL

      MOV AL,SONG
      INC AL
      MOV SONG,AL
      CMP AL,'4'
      JE CC
      JMP DDD
   CC:MOV SONG,'1'
     

DDD:CALL CHANGE_SONG  ;换歌

      MOV DX,OFFSET BUF4
      MOV AH,9    ;DOS功能号，显示字符串
      INT 21H

      MOV AL, 20H
      OUT 20H,AL

      POP DX
      POP AX
      STI ;开中断
      IRET
SW_INT ENDP 

DELAY PROC NEAR
      PUSH DX
      PUSH BX
      PUSH CX
      PUSH AX

      MOV AL,15

      MOV BL,STT1
      MOV BH,0
      MOV DL,[ASONGT+BX]
      MUL DL ;DL与AL相乘送至AX

   X1:MOV CX,0FFFFH
   X2:DEC CX
      JNZ X2
      DEC AX ;延时与AX有关
      JNZ X1

      POP AX
      POP CX
      POP BX
      POP DX
      RET
DELAY ENDP

DELAY2 PROC NEAR
      PUSH AX
      PUSH BX
      MOV AX, 0FFH
      DL2:MOV BX, 0FFFFH
      DL1:DEC BX
      JNZ DL1
      DEC AX
      JNZ DL2
      POP BX
      POP AX
      RET
DELAY2 ENDP 

DELAY3 PROC NEAR
      PUSH DX
      PUSH BX
      PUSH CX
      PUSH AX

      MOV AL,15

      MOV BL,STT2
      MOV BH,0
      MOV DL,[BSONGT+BX]
      MUL DL ;DL与AL相乘送至AX

   X1:MOV CX,0FFFFH
   X2:DEC CX
      JNZ X2
      DEC AX ;延时与AX有关
      JNZ X1

      POP AX
      POP CX
      POP BX
      POP DX
      RET
DELAY3 ENDP

DELAY4 PROC NEAR
      PUSH DX
      PUSH BX
      PUSH CX
      PUSH AX

      MOV AL,15

      MOV BL,STT3
      MOV BH,0
      MOV DL,[CSONGT+BX]
      MUL DL ;DL与AL相乘送至AX

   X1:MOV CX,0FFFFH
   X2:DEC CX
      JNZ X2
      DEC AX ;延时与AX有关
      JNZ X1

      POP AX
      POP CX
      POP BX
      POP DX
      RET
DELAY4 ENDP

LS1 PROC FAR
PUSH SI

MOV STT1,00H
;-----------开始播放
EEE:MOV SI,OFFSET ASONGF
EEB:MOV CL,[SI]

;判断是否播放结束
    CMP CL,0FFH
    JE EE;播放结束跳出该程序-------------
    DEC CL
    MOV AL,2
    MUL CL ;CL与AL相乘送至AX BX
    MOV BX,AX
    JMP EEA

EEA:MOV AX,4240H
    MOV DX,0FH
    MOV DI,WORD PTR[TABLE1+BX]
    DIV DI ; DI/(DX AX) 结果AX存商 DX存余数

; 将计算得到的计数初值送入8253A口-----------
    MOV BX,AX
    MOV DX,A8254
    MOV AX,BX ;?
    OUT DX,AL
    MOV AL,AH
    OUT DX,AL

;new
MOV DX,PORTH
OUT DX,FFH
MOV AH,CL
MOV AL,AH
SHL AH,4
ADD AH,AL

;MOV CX,0008H
MOV DX,PORTR
MOV AL,AH
OUT DX,AL

    MOV DX,PORTD
    MOV AL,10000000B
    OUT DX,AL

    MOV DX,PORTC
    MOV AL,03H
    OUT DX,AL ;C0C1=11 开始发声

    CALL DELAY

    MOV AL,00H
    OUT DX,AL ;

SSS:ADD STT1,01H
    ADD SI,01H ;播放下一个音符
    JMP EEB

 EE:
 POP SI
    RET
   
    
LS1 ENDP

LS3 PROC FAR

PUSH SI
;-----------开始播放
MOV STT3,00H
EEE:MOV SI,OFFSET CSONGF
EEB:MOV CL,[SI]

;判断是否播放结束
    CMP CL,0FFH
    JE EE;播放结束跳出该程序-------------
    DEC CL
    MOV AL,2
    MUL CL ;CL与AL相乘送至AX BX
    MOV BX,AX
    JMP EEA

EEA:MOV AX,4240H
    MOV DX,0FH
    MOV DI,WORD PTR[TABLE1+BX]
    DIV DI ; DI/(DX AX) 结果AX存商 DX存余数

; 将计算得到的计数初值送入8253A口-----------
    MOV BX,AX
    MOV DX,A8254
    MOV AX,BX ;?
    OUT DX,AL
    MOV AL,AH
    OUT DX,AL
;new
MOV DX,PORTH
OUT DX,FFH
MOV AH,CL
MOV AL,AH
SHL AH,4
ADD AH,AL

;MOV CX,0008H
MOV DX,PORTR
MOV AL,AH

    MOV DX,PORTD
    MOV AL,10000000B
    OUT DX,AL

    MOV DX,PORTC
    MOV AL,03H
    OUT DX,AL ;C0C1=11 开始发声

    CALL DELAY4

    MOV AL,00H
    OUT DX,AL ;

SSS:ADD STT3,01H
    ADD SI,01H ;播放下一个音符
    JMP EEB

 EE:
 POP SI
    RET
    
    
LS3 ENDP

LS2 PROC FAR

PUSH SI
;-----------开始播放
MOV STT2,00H
EEE:MOV SI,OFFSET BSONGF
EEB:MOV CL,[SI]

;判断是否播放结束
    CMP CL,0FFH
    JE EE;播放结束跳出该程序-------------
    DEC CL
    MOV AL,2
    MUL CL ;CL与AL相乘送至AX BX
    MOV BX,AX
    JMP EEA

EEA:MOV AX,4240H
    MOV DX,0FH
    MOV DI,WORD PTR[TABLE1+BX]
    DIV DI ; DI/(DX AX) 结果AX存商 DX存余数

; 将计算得到的计数初值送入8253A口-----------
    MOV BX,AX
    MOV DX,A8254
    MOV AX,BX ;?
    OUT DX,AL
    MOV AL,AH
    OUT DX,AL

;new
MOV DX,PORTH
OUT DX,FFH
MOV AH,CL
MOV AL,AH
SHL AH,4
ADD AH,AL

;MOV CX,0008H
MOV DX,PORTR
MOV AL,AH

    MOV DX,PORTD
    MOV AL,10000000B
    OUT DX,AL

    MOV DX,PORTC
    MOV AL,03H
    OUT DX,AL ;C0C1=11 开始发声

    CALL DELAY3

    MOV AL,00H
    OUT DX,AL ;

SSS:ADD STT2,01H
    ADD SI,01H ;播放下一个音符
    JMP EEB

 EE:
 POP SI
    RET
    
LS2 ENDP


;---------获取歌曲序号-------
GET_SONG PROC NEAR
      PUSH AX
      PUSH BX
      PUSH CX
      PUSH SI
      PUSH DX
      PUSH DI

      ;初始化8255
      MOV DX,PORTD
      MOV AL,10000001B ;C(0-3)作为输入口
      OUT DX,AL

   LP:MOV DX,PORTC  
      MOV AL,0FH
      OUT DX,AL     ;为啥给C口送0FH？
      IN AL,DX      ;读入行
      AND AL,0FH    
      CMP AL,0FH
      JZ LP         ;是否读入，没读入继续读
      CALL DELAY2

      MOV AH,AL     ;将读入的数放在AH中
      MOV DX,PORTD
      MOV AL,88H    ;在初始化8255，将C(4-7)置为输入
      OUT DX,AL

      MOV DX,PORTC
      MOV AL,AH
      OR AL,0F0H    ;为啥OR？
      OUT DX,AL
      IN AL,DX      ;读入列
      AND AL,0F0H
      CMP AL,0F0H
      JZ LP         ;没读入继续读

      MOV SI,OFFSET TABLE2  ;键盘扫描表的首址
      MOV DI,OFFSET CHAR    ;字符的首地址
      MOV CX,16             ;扫描表的大小

KEY_TONEXT:
      CMP AX,[SI]           ;对比扫描表的每一个值
      JZ KEY_FINDKEY        ;取得的值在表中跳转
      DEC CX
      JZ LP
      ADD SI,2
      INC DI
      JMP KEY_TONEXT

KEY_FINDKEY:
      MOV DL,[DI]           
      MOV AH,02             ;显示字符
      INT 21H
      MOV SONG,DL           ;将获取的字符放入SONG变量

KEY_WAITUP:
    MOV DX,PORTD
    MOV AL,81H              ;C(0-3)置为输入
    OUT DX,AL

    MOV DX,PORTC
    MOV AL,0FH
    OUT DX,AL
    IN AL,DX
    AND AL,0FH
    CMP AL,0FH
    JNZ KEY_WAITUP          ;判断按键是否松开
    CALL DELAY2

      POP DI
      POP DX
      POP SI
      POP CX
      POP BX
      POP AX
      RET
GET_SONG ENDP

CHANGE_SONG PROC NEAR
      PUSH AX
      PUSH BX
      PUSH CX
      
      MOV AL,SONG1

      CMP AL,'1'
      JNE L1
      CALL LS1
      JMP EXIT

   L1:CMP AL,'2'
      JNE L2
      CALL LS2
      JMP EXIT

   L2:CMP AL,'3'
      JNE EXIT
      CALL LS3
      JMP EXIT

 EXIT:POP CX
      POP BX
      POP AX
      RET
CHANGE_SONG ENDP

CSEG ENDS
END START