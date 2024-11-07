;***************************************************************************
;
;	    Filename: PluckSlave.ASM
;	    Date: 11/06/2024
;	    File Version: 1
;	    Author: Owen Fujii
;	    Company: Idaho State University
;	    Description: A Program for a slave I2C device that plucks the strings
;			    of a bass guitar
;**************************************************************************
	
;*************************************************************************
; 
;	    Revision History:
;   
;	    Modified as listed
;	    Started 11/06/2024
;
;*************************************************************************
    
    ; PIC16F1788 Configuration Bit Settings

; Assembly source line config statements

	#include "p16f1789.inc"
	#INCLUDE <PluckSetup.inc>
	#INCLUDE <PluckPOPout.inc>
	#INCLUDE <PluckPUSHin.inc>

; CONFIG1
; __config 0xE9A4
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_ON
; CONFIG2
; __config 0xDFFF
 __CONFIG _CONFIG2, _WRT_OFF & _VCAPEN_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_OFF

 
 ;*********************
 ;Define Constants
 ;*********************
 
    ANSELECT EQU H'031'
    TEMP     EQU H'032'
 

    ORG H'000'					
    GOTO SETUP					;RESET CONDITION GOTO SETUP
    ORG H'004'
    GOTO INTER
    
    
    
SETUP
    BANKSEL OSCCON
    MOVLW H'06A'	    ; SET 4MHZ INTERNAL OSSCILATOR
    MOVWF OSCCON
    BANKSEL OSCSTAT
    BTFSC OSCSTAT,OSTS	    ; WAIT FOR OSSCILATOR TO BE READY
    GOTO $-1
    CALL START		    ; CALL SETUP INCLUDE
    BANKSEL SSP1CON1
    MOVLW H'036'	    ; SET 7 BIT SLAVE I2C
    MOVWF SSP1CON1
    BANKSEL SSP1ADD
    MOVLW H'020'	    ; SET SLAVE ADDRESS A 0X10
    MOVWF SSP1ADD
    BANKSEL SSP1CON2
    BSF SSP1CON2,SEN	    ; ENABLE CLOCK STRETCH
    BANKSEL SSP1CON3
    CLRF SSP1CON3
    BSF SSP1CON3,AHEN	    ; ENABLE CLOCK STRETCH FOR ADDRESS AND DATA
    BSF SSP1CON3,DHEN
    BSF INTCON,GIE	    ; ENABLE INTERRUPTS
    BSF INTCON,PEIE
    GOTO MAIN

MAIN
    NOP
    GOTO MAIN
    
INTER
    BANKSEL INTCON
    CLRF INTCON
    CALL PUSHIN
    BCF PORTB,2
    BANKSEL PIR1
    BTFSC PIR1,SSP1IF	    ; CHECK MSSP INTERRUPT FLAG
    CALL RECIEVE	
    BANKSEL INTCON
    BSF INTCON,GIE
    BSF INTCON,PEIE
    CALL POPOUT
    RETFIE
    
RECIEVE
    BANKSEL PIR1
    CLRF PIR1		; CLEAR FLAG
    BCF PORTB,2
    BANKSEL SSP1BUF 
    MOVF SSP1BUF,0	; READ RECIEVED DATA
    BANKSEL PORTB
    BTFSC TEMP,0	; CHECK IF THIS IS DATA OR ADDRESS
    MOVWF ANSELECT
    BSF TEMP,0
    BANKSEL SSP1CON1	
    BSF SSP1CON1,CKP	; RELEASE CLOCK LINE
    RETURN
    
    

END





