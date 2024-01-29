/*	Tran Duy Khanh EEEEIU20031
	Final Project
	Calculator on AVR ATMEGA32
	Programming in C
							*/
#ifndef F_CPU
#define F_CPU 8000000UL
#endif

#include<avr/io.h>    		// Standard AVR header
#include<util/delay.h> 	// Delay loop functions
#include<avr/interrupt.h>
#include<inttypes.h>
#include<stdio.h>
#include<math.h>
#include<stdlib.h>

//LCD instructions
#define Clear_display 0x01
#define Shift_left_cursor 0x04
#define Shift_right_cursor 0x06
#define Shift_left_display 0x07
#define Shift_right_display 0x05
#define Display_On 0x0E
#define LCD_2_lines 0x38
#define LCD_cursor_1st 0X80
#define LCD_cursor_2nd 0XC0

//LCD PORT B
#define LCD_PORT PORTB
#define LCD_DDR DDRB
#define LCD_PIN PINB
#define LCD_Control_PORT PORTD
#define LCD_Control_DDR DDRD
#define LCD_Control_PIN PIND
#define LCD_RS 5
#define LCD_RW 6
#define LCD_EN 7

//Values for computation
volatile unsigned int number;
volatile unsigned int new_number;
volatile unsigned int op;
volatile unsigned int number_a_done = 0;

volatile unsigned char char_op;

volatile unsigned int flag_clear = 0;

/////////////////////
//Delay
void delay_ms(int time){
	_delay_ms(time);
}
void delay_us(int time){
	_delay_us(time);
}
////////////////////////////////////////////////////////////////
//Functions declare
void LCD_init(void);
void LCD_command(unsigned char);
void LCD_data(unsigned char);
void LCD_cursor(unsigned char , unsigned char );
void LCD_display(char *);

//Interupt 0
ISR(INT0_vect){   
	unsigned char key_pressed;
    op = 0;
    new_number = 1;
	//read the 74C922 outputs
	key_pressed=PINC&0x0F;
	//A new key has been pressed
	
	//Determine what key is pressed
	if(key_pressed==7)
		number=0; //Number 0
		
	else if(key_pressed==2)
		number=1;
		
	else if(key_pressed==6)
		number=2;
				
	else if(key_pressed==10)
		number=3;	
		
	else if(key_pressed==1)
		number=4;
		
	else if(key_pressed==5)
		number=5;
		
	else if(key_pressed==9)
		number=6;
		
	else if(key_pressed==0)
		number=7;
		
	else if(key_pressed==4)
		number=8;
		
	else if(key_pressed==8)
		number=9;
		
	else if(key_pressed==15){
		number=0;//add
		op=1;
		char_op='+';
	}	
	
	else if(key_pressed==14){	
		number=0;//subtraction
		op=2;
		char_op='-';
	}			
	
	else if(key_pressed==13){
		number=0;//mult
		op=3;
		char_op='x';
	}		

	else if(key_pressed==12){		
		number=0;//div
		op=4;
		char_op='/';
	}		
		
	else if(key_pressed==11){	
		number=0;//execute
		op=5;
	}		
	
	else if(key_pressed==3){
		number=0;//on/c
		op=6;
	}		
		
}

void ports_setup(void){
    // set port C for input 
    DDRC = 0x00;
    DDRB = 0xFF;
    //Interupt service INT0
    DDRD &= ~(1<<INT0);
}


int main(){
	char buffer_lcd[16];
	volatile long number_a, number_b;
	volatile double result = 0.0;
	
	number=0; new_number = 0;
	number_a=0; number_b=0;
	result=0;
	op=0;
	char_op='+';
	
	ports_setup();
	//Enable interupt INT0
	GICR|=0xC0; // GICR |= 1<<INT0;
    MCUCR=0x0F;
    MCUCSR=0x02;
    GIFR=0xC0;
    sei();
    
    //Initialize LCD
    LCD_init();
    //LCD display information about Final Project
    LCD_cursor(1,1);
    LCD_display("Tran Duy Khanh");
    LCD_cursor(1,2);
    LCD_display("Final Project");
    
    delay_ms(1000);
    LCD_command(Clear_display); 
    
    //Tran Duy Khanh display Final Project
    LCD_cursor(1,1);
    LCD_display("Calculator");
    LCD_cursor(1,2);
    LCD_display("AVR in C Program");
    delay_ms(1000);

    LCD_command(Clear_display); 
    LCD_cursor(1,1);
    
    while(1){
    	//If a new number is pressed
		if(new_number){
			//Clear the LCD when the computation completed
			if(flag_clear){
				number_a = 0;
				number_b = 0;
				result = 0;
				flag_clear = 0;
				number_a_done = 0;
				LCD_command(Clear_display);
    			LCD_cursor(1,1);
			}
			//If the number is input
			if(op==0){
				//If number a input is done
    			if(number_a_done){
    				delay_ms(2);
    				number_b=number_b*10+number;
					LCD_data(number + 0x30);
				}
				//Input number a
				else{
					delay_ms(2);
					number_a=number_a*10+number;
					LCD_data(number + 0x30);
				}
			}
			
			//Display operation character
			//'+', '-', 'x', '/'
			//Set flag show that number input is done
			else if (op==1 || op==2 || op==3 || op==4){
				LCD_data(char_op);
				number_a_done = 1;
			}
			
			//Compute the two number when '=' is pressed
			else if(op==5){
				unsigned int display_float;	
				LCD_cursor(1,2);
				
				if(char_op=='+')
					result= number_a+number_b;
				
				else if(char_op=='-')
					result= number_a-number_b;					
					
				else if(char_op=='x')
					result= number_a*number_b;							
					
				else if(char_op=='/')
					result=(double) number_a/number_b;
			
				//Display float number if '/' has remainder
				if(char_op == '/' && number_a-(number_a/number_b)*number_b)
				 	display_float = 4;
				else
				 	display_float = 0;
				 	
				//Display the result
				LCD_display("= "); 	
				dtostrf(result, 1, display_float, buffer_lcd); 
				LCD_display(buffer_lcd);
				flag_clear = 1;
			}
			
			//Clear the calculator when on/C is pressed
			else if(op==6){
				number_a = 0;
				number_b = 0;
				number_a_done = 0;
				result = 0;
				flag_clear = 0;
				LCD_command(Clear_display);
    			LCD_cursor(1,1);
			}
    		
			new_number=0;
			}
		asm("nop");
	}
    return 0;
}

//////////////////////////////////////
//Functions define
//////////////////////LCD functions/////////////////////////
void LCD_command(unsigned char cmnd){
	LCD_PORT = cmnd;
	LCD_Control_PORT &= ~(1<<LCD_RS);
	LCD_Control_PORT &= ~(1<<LCD_RW);
	LCD_Control_PORT |= (1<<LCD_EN);
	delay_us(1);
	LCD_Control_PORT &= ~(1<<LCD_EN);
	delay_us(100);
}

void LCD_init(void){
	LCD_DDR = 0xFF;
	LCD_Control_DDR |= 0xF0;
	LCD_Control_PORT &= ~(1<<LCD_EN);
	delay_us(2000);
	LCD_command(LCD_2_lines);
	LCD_command(Display_On);
	LCD_command(Clear_display);
	delay_us(2000);
	LCD_command(Shift_right_cursor);
}



void LCD_data(unsigned char data){
	LCD_PORT = data;
	LCD_Control_PORT |= 1<<LCD_RS;
	LCD_Control_PORT &= ~(1<<LCD_RW);
	LCD_Control_PORT |= 1<<LCD_EN;
	delay_us(1);
	LCD_Control_PORT &= ~(1<<LCD_EN);
	delay_us(100);
}

void LCD_cursor(unsigned char x, unsigned char y){
	unsigned char cursor[] = {0x80, 0xC0, 0x94, 0xD4};
	LCD_command(cursor[y-1] + x - 1);
	delay_us(100);
}

void LCD_display(char *str){
	unsigned char i = 0;
	while(str[i] != 0){
		LCD_data(str[i]);
		i++;
	}
}
/////////////////////////////////////////////////////////
/*	Tran Duy Khanh EEEEIU20031
	Final Project
	Calculator on AVR ATMEGA32
	Programming in C
							*/
