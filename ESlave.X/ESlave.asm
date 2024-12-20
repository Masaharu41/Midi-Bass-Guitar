;***************************************************************************
;
;	    Filename: Eslave.ASM
;	    Date: 11/05/2024
;	    File Version: 1
;	    Author: Owen Fujii
;	    Company: Idaho State University
;	    Description: A Program for a slave I2C device that plays notes on the
;			    E string of a Bass guitar
;**************************************************************************
	
;*************************************************************************
; 
;	    Revision History:
;   
;	    Modified as listed
;	    Started 11/05/2024
;
;*************************************************************************
    
    ; PIC16F1788 Configuration Bit Settings

; Assembly source line config statements

	#include "p16f1789.inc"
	#INCLUDE <ESlaveSetup.inc>
	#INCLUDE <ESlavePOPout.inc>
	#INCLUDE <ESlavePUSHin.inc>

; CONFIG1
; __config 0xE9A4
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _CLKOUTEN_ON & _IESO_OFF & _FCMEN_ON
; CONFIG2
; __config 0xDFFF
 __CONFIG _CONFIG2, _WRT_OFF & _VCAPEN_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_OFF

 
 ;*********************
 ;Define Constants
 ;*********************
 
        PITCH	    EQU H'022'
	BUFFER	    EQU H'041'
	TEMP	    EQU H'042'
; SET STORAGE REGISTERS FOR EACH NOTE AND ITS MIDI VALUES
	E1MIDI	    EQU H'023'
	F1MIDI	    EQU H'024'
	FS1MIDI	    EQU H'025'
	G1MIDI	    EQU H'026'
	GS1MIDI	    EQU H'027'
	A1MIDI	    EQU H'028'
	AS1MIDI	    EQU H'029'
	B1MIDI	    EQU H'030'
	C2MIDI	    EQU H'031'
	CS2MIDI	    EQU H'032'
	D2MIDI	    EQU H'033'
	DS2MIDI	    EQU H'034'
	E2MIDI	    EQU H'035'
	F2MIDI	    EQU H'036'
	FS2MIDI	    EQU H'037'
	G2MIDI	    EQU H'038'
	GS2MIDI	    EQU H'039'
	A2MIDI	    EQU H'040'
	AS2MIDI	    EQU H'041'
	B2MIDI	    EQU H'042'
	C3MIDI	    EQU H'043'
	  
	

    ORG H'000'					
    GOTO SETUP					;RESET CONDITION GOTO SETUP
    ORG H'004'
    GOTO INTER
    
    
    
SETUP
    BANKSEL OSCCON
    MOVLW H'07B'	    ; SET 16MHZ INTERNAL OSSCILATOR
    MOVWF OSCCON
    BANKSEL OSCSTAT
    BTFSC OSCSTAT,OSTS	    ; WAIT FOR OSSCILATOR TO BE READY
    GOTO $-1
    CALL START		    ; CALL SETUP INCLUDE
    ; SET UP I2C AS SLAVE
    BANKSEL SSP1CON1
    MOVLW H'036'	    ; SET 7 BIT SLAVE I2C
    MOVWF SSP1CON1
    BANKSEL SSP1ADD
    MOVLW H'002'	    ; SET SLAVE ADDRESS A 0X01
    MOVWF SSP1ADD
    BANKSEL SSP1CON2
    CLRF SSP1CON2
    BSF SSP1CON2,SEN	    ; ENABLE CLOCK STRETCH
    BANKSEL SSP1CON3
    CLRF SSP1CON3
    BSF SSP1CON3,BOEN
    BSF SSP1CON3,AHEN	    ; ENABLE CLOCK STRETCH FOR ADDRESS AND DATA
    BSF SSP1CON3,DHEN
    ; CONFIGURE PORT PINS
    BANKSEL APFCON1
    CLRF APFCON1	    ; SET PORTS
    BANKSEL APFCON2
    CLRF APFCON2	    ; SET PORTS
    ; SET MIDI NOTES INTO GPRS
    MOVLW H'01C'    ; MIDI 28 // E1
    MOVWF E1MIDI
    MOVLW H'01D'    ; MIDI 29 // F1
    MOVWF F1MIDI
    MOVLW H'01E'    ; MIDI 30 // F#1
    MOVWF FS1MIDI
    MOVLW H'01F'    ; MIDI 31 // G1
    MOVWF G1MIDI
    MOVLW H'020'    ; MIDI 32 // G#1
    MOVWF GS1MIDI
    MOVLW H'021'    ; MIDI 33 // A1
    MOVWF A1MIDI
    MOVLW H'022'    ; MIDI 34 // A#1
    MOVWF AS1MIDI
    MOVLW H'023'    ; MIDI 35 // B1
    MOVWF B1MIDI
    MOVLW H'024'    ; MIDI 36 // C2
    MOVWF C2MIDI
    MOVLW H'025'    ; MIDI 37 // C#2
    MOVWF CS2MIDI
    MOVLW H'026'    ; MIDI 38 // D2
    MOVWF D2MIDI
    MOVLW H'027'    ; MIDI 39 // D#2
    MOVWF DS2MIDI
    MOVLW H'028'    ; MIDI 40 // E2
    MOVWF E2MIDI
    MOVLW H'029'    ; MIDI 41 // F2
    MOVWF F2MIDI
    MOVLW H'02A'    ; MIDI 42 // F#2
    MOVWF FS2MIDI
    MOVLW H'02B'    ; MIDI 43 // G2
    MOVWF G2MIDI
    MOVLW H'02C'    ; MIDI 44 // G#2
    MOVWF GS2MIDI
    MOVLW H'02D'    ; MIDI 45 // A2
    MOVWF A2MIDI
    MOVLW H'02E'    ; MIDI 46 // A#2
    MOVWF AS2MIDI
    MOVLW H'02F'    ; MIDI 47 // B2
    MOVWF B2MIDI
    MOVLW H'030'    ; MIDI 48 // C3
    MOVWF C3MIDI    
    ; SET GPRS
    CLRF BUFFER
    CLRF PITCH
    ; ENABLE INTERRUPTS
    BANKSEL PIE1
    BSF PIE1,SSP1IE
    BSF INTCON,GIE	    ; ENABLE INTERRUPTS
    BSF INTCON,PEIE
    BANKSEL PORTE
    BSF PORTE,1		    ; SET STATUS FLAG
    GOTO MAIN

MAIN
    NOP
    BANKSEL PORTB
    BTFSS BUFFER,0	; WAIT FOR DATA BUFFER FLAG TO BE SET
    GOTO MAIN
;    BTFSS PITCH,7
;    GOTO CLEAR		; INDICATE NOTE IS TO BE ON
    BCF PITCH,7		; CLEAR UPPER BIT
    BSF PORTD,0
    ; CHECK IF PITCH IS E1
    MOVFW E1MIDI
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO CLEAR		; CLEAR ALL SOLENOIDS
    ; CHECK IF PITCH IS F1
    MOVFW F1MIDI	; MOVE MIDI NOTE INTO WORKING
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETF1
    ; CHECK IF PITCH IS F#1
    MOVFW FS1MIDI
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETFS1
    ; CHECK IF PITCH IS G1
    MOVFW G1MIDI
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETG1
    ; CHECK IF PITCH IS G#1
    MOVFW GS1MIDI
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETGS1
    ; CHECK IF PITCH IS A1
    MOVF A1MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETA1
    GOTO MAIN
    ; CHECK IF PITCH IS A#1
    MOVF AS1MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETF1
    ; CHECK IF PITCH IS B1
    MOVF B1MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETB1
    ; CHECK IF PITCH IS C2
    MOVF C2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETC2
    ; CHECK IF PITCH IS C#2
    MOVF CS2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETCS2
    ; CHECK IF PITCH IS D2
    MOVF D2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETD2
    ; CHECK IF PITCH IS D#2
    MOVF DS2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETDS2
    ; CHECK IF PITCH IS E2
    MOVF E2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETE2
    ; CHECK IF PITCH IS F2
    MOVF F2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETF2
    ; CHECK IF PITCH IS F#2
    MOVF FS2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETFS2
    ; CHECK IF PITCH IS G2
    MOVF G2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETG2
    ; CHECK IF PITCH IS G#2
    MOVF GS2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETGS2
    ; CHECK IF PITCH IS A2
    MOVF A2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETA2
    ; CHECK IF PITCH IS A#2
    MOVF AS2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETAS2
    ; CHECK IF PITCH IS B2
    MOVF B2MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETB2
    ; CHECK IF PITCH IS C3
    MOVF C3MIDI,0
    BCF STATUS,Z
    SUBWF PITCH,0	; STORE IN WORKING
    BTFSC STATUS,Z
    GOTO SETC3
    BANKSEL PORTB
    CLRF BUFFER
    CLRF PITCH
    GOTO MAIN	; RETURN TO MAIN AFTER CLEARING BUFFER AND PITCH
    

CLEAR
    BANKSEL PORTA
    CLRF PORTA	;CLEAR OUTPUTS FOR ENTIRE STRING
    CLRF PORTD
    CLRF PORTB
    CLRF BUFFER
    CLRF PITCH
    BSF PORTD,0
    GOTO MAIN
    
STOP
    BANKSEL SSP1CON1
    BCF SSP1CON1,SSPEN
    NOP
    NOP
    BSF SSP1CON1,SSPEN
    RETURN

    
SETF1
    BANKSEL PORTB
    BSF PORTB,0
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN
   
SETFS1
    BANKSEL PORTB
    BSF PORTB,1
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN    
    
SETG1
    BANKSEL PORTB
    BSF PORTB,2
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN    
      
SETGS1
    BANKSEL PORTB
    BSF PORTB,3
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN    
    
SETA1
    BANKSEL PORTB
    BSF PORTB,4
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN   
    
SETAS1
    BANKSEL PORTB
    BSF PORTB,5
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN    
   
SETB1
    BANKSEL PORTB
    BSF PORTB,6
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN  
    
SETC2
    BANKSEL PORTB
    BSF PORTB,7
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN   
    
SETCS2
    BANKSEL PORTA
    BSF PORTA,0
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN    
    
SETD2
    BANKSEL PORTA
    BSF PORTA,1
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN  
    
SETDS2
    BANKSEL PORTA
    BSF PORTA,2
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN       
    
SETE2
    BANKSEL PORTA
    BSF PORTA,3
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN   
    
SETF2
    BANKSEL PORTA
    BSF PORTA,4
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN  
    
SETFS2
    BANKSEL PORTA
    BSF PORTA,5
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN  
    
SETG2
    BANKSEL PORTA
    BSF PORTA,6
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN       
    
SETGS2
    BANKSEL PORTA
    BSF PORTA,7
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN       
    
SETA2
    BANKSEL PORTD
    BSF PORTD,0
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN
    
SETAS2
    BANKSEL PORTD
    BSF PORTD,1
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN  
    
SETB2
    BANKSEL PORTD
    BSF PORTD,2
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN  
     
    
SETC3
    BANKSEL PORTD
    BSF PORTD,3
    CLRF PITCH
    CLRF BUFFER
    GOTO MAIN       
    
INTER
    BANKSEL INTCON
    CLRF INTCON		    ; CLEAR INTERRUPTS
    CALL PUSHIN		    ; SAFE STATUS
    BANKSEL PIR1
    BTFSC PIR1,SSP1IF	    ; CHECK MSSP INTERRUPT FLAG
    CALL RECIEVE	
    BANKSEL SSP1STAT
    BTFSC SSP1STAT,P	    ; CHECK FOR STOP CONDITION
    CALL STOP
    BANKSEL INTCON
    BSF INTCON,GIE	    ; RE-ENABLE INTERRUPTS
    BSF INTCON,PEIE
    CALL POPOUT		    ; RETURN STATUS'S
    RETFIE
    
RECIEVE
    BANKSEL PIR1
    CLRF PIR1		; CLEAR FLAG
    BANKSEL SSP1BUF 
    MOVFW SSP1BUF	; READ RECIEVED DATA
    BANKSEL PORTB
    MOVWF TEMP		; MOVE TO TEMP REGISTER
    BANKSEL SSP1STAT
    BTFSS SSP1STAT,5	; CHECK IF LAST WAS DATA
    GOTO SKIP		; DO NOT WRITE IF THIS IS ADDRESS
    BANKSEL PORTB
    MOVFW TEMP		; MOVE FROM TEMP
    MOVWF PITCH		; MOVE INTO GPR
    BSF BUFFER,0	; SET FLAG
SKIP
    BANKSEL SSP1CON1	
    BSF SSP1CON1,CKP	; RELEASE CLOCK LINE
    RETURN

END