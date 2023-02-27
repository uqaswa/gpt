///////////////////////////////////////////////////////////////////////////////////////////////////
#include<pic.h>
#include<htc.h>
#include<stdio.h>
__CONFIG(OSC_IntRC & WDT_OFF & CP_ON & MCLRE_OFF & IOSCFS_OFF);
#define _XTAL_FREQ 4000000 //if use delay, put this sentence
// __delay_ms() / __delay_us() / _delay() / __delay_ms(125) = 1s
#define __delay_us(x) _delay((unsigned long)((x)*(_XTAL_FREQ/4000000.0)))
#define __delay_ms(x) _delay((unsigned long)((x)*(_XTAL_FREQ/4000.0)))
unsigned short cnt = 0;
unsigned short cnt1 = 0;
unsigned short cnt2 = 0;
unsigned short cnt3 = 0;
unsigned short cnt4 = 0;
unsigned short timer1 = 0;
unsigned short timer2 = 0;
unsigned char state;

void Init_set(){
	ADCON0 = 0x00; //set digital I/O PIN
	CM1CON0 = 0x00; // disable comparator
	TRISGPIO = 0b00011000; // GP0~2,5 = OUTPUT /GP   3,4 = INPUT 
	OPTION = 0b11000111;
	GPIO = 0b00000000; // GPIO level = LOW
}
//HR33 의 경우 GP1->GP0 // // HFE20-1의 경우 GP0 -> GP1//
void Emr_zc(){
	if(GP3 == 0){
		state = 0;
		cnt = cnt + 1;
  		if(cnt == 30){
			cnt = 0;
			timer2 = 0;
			timer1 ++;
			GP5 = ~GP5;
			switch(timer1){
				case 2: GP0 = 1; __delay_ms(100); GP0 = 0; break;
				case 4: GP2 = 1; break;
				case 12: GP1 = 1; __delay_ms(100); GP1 = 0; GP5=0; timer1=20; break;				
			}  
		}
		__delay_ms(12);
	}
	if(GP4 == 0){timer1 = 0; timer2 = 0; state = 1;}
}

void Nor_zc(){
	timer1 = 0;
	if(GP4 == 0){
		cnt= 0;
		cnt1 = cnt1 + 1;
		if(cnt1 == 30){
			GP2 = 0;
			cnt1 = 0;
			timer1 = 0;
			timer2 ++;
			GP5 = 0;
			switch(timer2){
				case 2: GP0 = 1; __delay_ms(100); GP0 = 0; break;
				case 4: GP2 = 0; break;
				case 12: GP1 = 1; __delay_ms(100); GP1 = 0; timer2=20; break;
			}
		}
		__delay_ms(12);
		TMR0=0;
	}
	
	else if(GP4 == 1){ // -> 상시전원의 공급이 끊어졌을때 비상 시퀸스를 다시한번해야함
		cnt3 = GP4;
		if(TMR0 > 50){
			TMR0 = 0;
			cnt4 = GP4;			
			if(cnt3 == cnt4){
				timer1, timer2 = 0;
				state = 0;
			}
		}
	}
}



void main(){
	Init_set(); // 초기 설정
	state = 0;
	while(timer1 < 13 && timer2 < 13 ){
	///////////////////////////////////////// 비상전원 이벤트
		switch(state){
			case 0: Emr_zc(); break;
			case 1: Nor_zc(); break;
		}
		 
	}//end while(timer1 <13 && timer2 < 13)
	//////////////////////////////////////// //////////////////////////////////// 비상전원 공급 중 상시전원 공급시
	while(timer1 == 20){
		GP5 = 0;
		if(GP4 == 0){
			GP2 = 0;
			timer2 = 0;
			timer1 = 0;
			state = 1;  


		}
	}
	///////////////////////////////////////// &% 상시전원 비상전원 둘다
	
	while(timer2 == 20){
		
		if(GP4 == 0){ // 비상전원과 상시전원이 둘다 들어올때
			TMR0=0;
		}	
		else if(GP4 == 1){ // -> 상시전원의 공급이 끊어졌을때 비상 시퀸스를 다시한번해야함
			cnt3 = GP4;
			if(TMR0>50){
				TMR0 = 0;
				cnt4 = GP4;			
				if(cnt3 == cnt4){
					Emr_zc();
				}
			}
		}
	}    
}	
