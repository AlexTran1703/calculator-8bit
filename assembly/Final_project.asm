.include<m32def.inc>

.DEF data = R16
.DEF num = R21
.DEF op = R22
.DEF new_num = R23
.DEF char_op = R24

.DEF num_a = R11
.DEF num_b = R13
.DEF char_num = R17
.DEF num_convert = R19

.DEF flag_clear = R5;
.DEF num_div = R6
.DEF divider = R7
.DEF quotient = R8
.DEF remainder = R9

//LCD instructions
.EQU Clear_display = 0x01
.EQU Shift_left_cursor = 0x04
.EQU Shift_right_cursor = 0x06
.EQU Shift_left_display = 0x07
.EQU Shift_right_display = 0x05
.EQU Display_On = 0x0E
.EQU LCD_2_lines = 0x38
.EQU LCD_cursor_1st = 0X80
.EQU LCD_cursor_2nd = 0XC0

//LCD PORT B, Control PORT D
.EQU LCD_PORT = PORTB
.EQU LCD_DDR = DDRB
.EQU LCD_PIN = PINB
.EQU LCD_Control_PORT = PORTD
.EQU LCD_Control_DDR = DDRD
.EQU LCD_Control_PIN = PIND
.EQU LCD_RS = 5
.EQU LCD_RW = 6
.EQU LCD_EN = 7


.cseg
.org 0x00
	rjmp main
.org 0x02
	rjmp keyboard_int

.org 0x02A
main:
	;Initialize Stack pointer
	LDI R20, HIGH(RAMEND)
	OUT SPH, R20
	LDI R20, LOW(RAMEND)
	OUT SPL, R20
	
	;Make PORT B to LCD as output
	LDI R20, 0XFF
	OUT LCD_DDR, R20
	LDI R20, 0X00
	OUT DDRC, R20
	;Enable control pin for LCD
	LDI R20, (1<<LCD_RS)|(1<<LCD_RW)|(1<<LCD_EN)
	OUT LCD_Control_DDR, R20
	CBI LCD_Control_PORT, LCD_EN
	
	;INT0 Enable
	LDI R20, 0xC0;
	OUT GICR, R20
	LDI R20, 0X0F;
	OUT MCUCR, R20;
	LDI R20, 0X00
	OUT MCUCSR, R20
	LDI R20, 0XC0
	OUT GIFR, R20
	sei;


	CALL delay_2ms
	LDI data, LCD_2_lines
	CALL CMNDWRT
	CALL delay_2ms
	LDI data, Display_On
	CALL CMNDWRT
	CALL delay_2ms
	LDI data, Clear_display
	CALL CMNDWRT
	CALL delay_2ms
	LDI data, Shift_right_cursor
	CALL CMNDWRT

	
	CALL display_name
	
	
	
	
	ldi R25, 1
	ldi R26, 1
	ldi R27, 0
	ldi R28, 1
	ldi R29, 0
	ldi r30, 0
	mov num_a, r30
	mov num_b, r30

here:
	cpi new_num, 1
	brne here
	
	mov R31, flag_clear
	cpi R31, 1
	brne input
	ldi R26, 1;
	ldi R27, 0;
	ldi r30, 0;
	mov num_a, r30
	mov num_b, r30
	mov flag_clear, r30
	ldi data, Clear_display
	CALL CMNDWRT
	ldi R25, 1
	
	input:
		ldi new_num, 0
		;Add number a on Calculator
		cpi op, 0
		;Branch to operation
		brne Operation
	
		cpi R27, 1
		brne number_1;
	number_2:	
		ldi r28, 10
		mul num_b, r28
		mov num_b, R0;
		add num_b, num
		mov char_num, num
		subi char_num, -0x30;
		
		mov data, char_num
		CALL DATAWRT
		
		jmp here

	number_1:	
		ldi r28, 10
		mul num_a, r28
		mov num_a, R0;
		add num_a, num
		mov char_num, num
		subi char_num, -0x30;	

		CALL delay_2ms
		cpi R25, 1
		brne Initalize_1st;
		LDI data, LCD_cursor_1st
		CALL CMNDWRT
		clr R25;	

		Initalize_1st:
		mov data, char_num
		CALL DATAWRT
		jmp here

	Operation:
		cpi op, 5
		breq Compute

		cpi op, 6
		breq Clear_Cal
		
		cpi R26, 1
		brne here

		ldi R27, 1;

		clr R26;
		CALL delay_2ms
		MOV data, char_op
		CALL DATAWRT
		rjmp here			
	
	Compute:

		Addi:
			cpi char_op, '+'
			brne Subtract
			add num_a, num_b


		Subtract:
			cpi char_op, '-'
			brne Multiply
			sub num_a, num_b	


		Multiply:
			cpi char_op, 'x'
			brne Divide
			mul num_a, num_b
			mov num_a, R0


		Divide:
			cpi char_op, '/'
			brne Equal
			mov num_div, num_a
			mov divider, num_b
			CALL div8;
			mov num_a, quotient	

		Equal:
			CALL delay_2ms

			LDI data, LCD_cursor_2nd
			CALL CMNDWRT
		
			ldi data, '='
			CALL DATAWRT
		
			cpi char_op, '/'
			brne Display_Calculation;
			CALL display_remainder;
		
		Display_Calculation:
			CALL Result_display
			
			jmp here

	Clear_Cal:
		ldi R26, 1;
		ldi R27, 0;
		ldi r30, 0;
		mov num_a, r30
		mov num_b, r30
		mov flag_clear, r30
		ldi data, Clear_display
		CALL CMNDWRT
		ldi R25, 1
		
		jmp  here

;-----------------------------------------------------------------------------------
;Interupt Keyboard routine;----------------------
keyboard_int:
	push r20
	CALL delay_2ms;

	ldi op, 0
	IN r20, PINC
	ANDI r20, 0x0F 
	;NEW_NUM
	LDI new_num, 1
	
	cpi r20, 7
	brne next0
	ldi num, 0
	jmp end;
next0:
	cpi r20, 2
	brne next1
	ldi num, 1
	jmp end;
next1:
	cpi r20, 6
	brne next2
	ldi num, 2

next2:
	cpi r20, 10
	brne next3
	ldi num, 3
	jmp end;
next3:
	cpi r20, 1
	brne next4
	ldi num, 4
	jmp end;
next4:
	cpi r20, 5
	brne next5
	ldi num, 5
	jmp end;
next5:
	cpi r20, 9
	brne next6
	ldi num, 6
	jmp end;
next6:
	cpi r20, 0
	brne next7
	ldi num, 7
	jmp end;
next7:
	cpi r20, 4
	brne next8
	ldi num, 8

next8:
	cpi r20, 8
	brne next9
	ldi num, 9
	jmp end;
;Operation 
;Op +
next9:
	cpi r20, 15
	brne next10
	ldi num, 0
	ldi op, 1
	ldi char_op, '+';
	jmp end;
;Op -
next10:
	cpi r20, 14
	brne next11
	ldi num, 0
	ldi op, 2
	ldi char_op, '-';
	jmp end;
;Op x
next11:
	cpi r20, 13
	brne next12
	ldi num, 0
	ldi op, 3
	ldi char_op, 'x';
	jmp end;
;Op /
next12:
	cpi r20, 12
	brne next13
	ldi num, 0
	ldi op, 4
	ldi char_op, '/';
	jmp end;
;Op =
next13:
	cpi r20, 11
	brne next14
	ldi num, 0
	ldi op, 5
	jmp end;
	;ldi char_op, '=';
;Op Clear
next14:
	cpi r20, 3
	brne end
	ldi num, 0
	ldi op, 6
	;ldi char_op, '=';
end:
	pop r20
	reti
;-----------------------------------------------------------------
;Control Subroutine-------

CMNDWRT:
	PUSH R20
	;OUT Data to LCD Port
	OUT LCD_PORT, data
	;EN = 1, RS = 0, RW = 0
	;LDI R20, (1<<LCD_EN) & (~(1<<LCD_RS)) & (~(1<<LCD_RW));
	;OUT LCD_Control_PORT, R20
	CBI LCD_Control_PORT, LCD_RS
	CBI LCD_Control_PORT, LCD_RW
	SBI LCD_Control_PORT, LCD_EN

	CALL SDELAY

	;LDI R20, ~(1<<LCD_EN)
	;OUT LCD_Control_PORT, R20
	CBI LCD_Control_PORT, LCD_EN
	CALL delay_100us
	POP R20
	RET
;Data Subroutine----------
DATAWRT:
	PUSH R20
	OUT LCD_PORT, data
	;EN = 1; RS = 1, RW = 0
	;LDI R20, (1<<LCD_EN) | (1<<LCD_RS) &(~(1<<LCD_RW));
	;OUT LCD_Control_PORT, R20

	SBI LCD_Control_PORT, LCD_RS
	CBI LCD_Control_PORT, LCD_RW
	SBI LCD_Control_PORT, LCD_EN
	CALL SDELAY

	;LDI R20, (~(1<<LCD_EN))
	;OUT LCD_Control_PORT, R20
	CBI LCD_Control_PORT, LCD_EN
	CALL delay_100us

	POP R20

	RET
;------------------------------------------------------------------------
;Subroutines;-------------------
;Result_Display-----------------
Result_display:
	PUSH R30
	;Result = x00;
	Result_x00:
		mov num_div, num_a
		ldi R29, 100
		mov divider, R29
		CALL div8;

		mov num_convert, quotient	
		mov char_num, num_convert
		subi char_num, -0x30;

		mov R30, quotient
		cpi R30, 0
		breq Result_0x0;		
		mov data, char_num
		CALL DATAWRT
	
		;Result = 0x0;
	Result_0x0:
		mul num_convert, R29
		mov num_convert, R0
		sub num_a, num_convert
	
		mov num_div, num_a
		ldi R29, 10
		mov divider, R29
		CALL div8;

		;mov R30, quotient
		;cpi R30, 0
		;breq Result_00x;

		mov num_convert, quotient	
		mov char_num, num_convert
		subi char_num, -0x30;	
	
	
		mov data, char_num
		CALL DATAWRT		
		
		;Result = 00x;
	Result_00x:
		mul num_convert, R29
		mov num_convert, R0
		sub num_a, num_convert
		mov char_num, num_a
		subi char_num, -0x30;
		mov data, char_num
		CALL DATAWRT

		LDI R30, 1;
		mov flag_clear, R30;

		POP R30;
		ret

;Diplay Remainder---------
display_remainder:
	push r29
	mov R29, remainder
	cpi R29, 0
	breq Return_no_display

	mov R29, divider
	cpi R29, 10
	brsh Return_no_display

	mov char_num, remainder
	subi char_num, -0x30;		
	mov data, char_num
	CALL DATAWRT
		
	ldi r29, '/'		
	mov data, r29
	CALL DATAWRT

	mov char_num, divider
	subi char_num, -0x30;		
	mov data, char_num
	CALL DATAWRT
	
	ldi data, ' '
	CALL DATAWRT	
	ldi data, '+'
	CALL DATAWRT
	ldi data, ' '
	CALL DATAWRT

	Return_no_display:
	pop r29
	ret

;Division 8bit------------------
div8:
	push r30
	ldi r30, 0
	mov quotient, r30
	division:	
		sub num_div, divider; 64 - 10
		brcc carry0

		add num_div, divider; num = 4
		mov remainder, num_div; Remainder = 4
		pop r30
		reti

	carry0:; carry = 0 label	
		inc quotient; Increase Quotient
		rjmp division;

;Display Name----------------
display_name:
;Display Name Final Project	
	Display_1st:
		CALL delay_2ms
		LDI data, LCD_cursor_1st
		CALL CMNDWRT
		LDI ZH, HIGH(array1<<1);
		LDI ZL, LOW(array1<<1);
	Loop1:
		LPM data, Z+
		CPI data, 0
		BREQ Display_2nd
		CALL DATAWRT;
		RJMP Loop1

	Display_2nd:
		CALL delay_2ms
		LDI data, LCD_cursor_2nd
		CALL CMNDWRT
		LDI ZH, HIGH(array2<<1);
		LDI ZL, LOW(array2<<1);
	Loop2:
		LPM data, Z+
		CPI data, 0
		BREQ Out_display1
		CALL DATAWRT;
		RJMP Loop2

	Out_display1:
		CALL delay_1s
		CALL delay_2ms
		LDI data, Clear_display
		CALL CMNDWRT

	Display_3rd:
		CALL delay_2ms
		LDI data, LCD_cursor_1st
		CALL CMNDWRT
		LDI ZH, HIGH(array3<<1);
		LDI ZL, LOW(array3<<1);
	Loop3:
		LPM data, Z+
		CPI data, 0
		BREQ Display_4th
		CALL DATAWRT;
		RJMP Loop3

	Display_4th:
		CALL delay_2ms
		LDI data, LCD_cursor_2nd
		CALL CMNDWRT
		LDI ZH, HIGH(array4<<1);
		LDI ZL, LOW(array4<<1);
	Loop4:
		LPM data, Z+
		CPI data, 0
		BREQ Out_display2
		CALL DATAWRT;
		RJMP Loop4
	
	Out_display2:
		CALL delay_1s
		CALL delay_2ms
		LDI data, Clear_display
		CALL CMNDWRT
		
	ret
;-----------------------------------------------------------------
;Delay Subroutines
SDELAY:
	NOP
	NOP
	RET

;-----
delay_100us:
	PUSH R17
	LDI R17, 60
DR0:
	CALL SDELAY
	DEC R17
	BRNE DR0
	POP R17
	RET
;-----
delay_2ms:
	PUSH R17
	LDI R17, 20
LDR0:
	CALL delay_100us
	DEC R17
	BRNE LDR0
	POP R17
	RET
;-----
delay_200ms:
	PUSH R17
	LDI R17, 100
DR1:
	CALL delay_2ms
	DEC R17
	BRNE DR1
	POP R17
	RET

;-----
delay_1s:
	PUSH R17
	LDI R17, 5
DR2:
	CALL delay_200ms
	DEC R17
	BRNE DR2
	POP R17
	RET

;-------------------------------------------------------------------------------------
;String;-----------------
array1: .DB "Tran Duy Khanh", 0
array2: .DB "Final Project", 0
array3: .DB "Calculator", 0
array4: .DB "AVR in Assembly", 0


