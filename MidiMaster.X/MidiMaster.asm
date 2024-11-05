;***************************************************************************
;
;	    Filename: MidiMaster.asm
;	    Date: 11/05/2024
;	    File Version: 1
;	    Author: Owen Fujii
;	    Company: Idaho State University
;	    Description: The Program for the Master controller for the midi bass guitar
;			
;**************************************************************************
	
;*************************************************************************
; 
;	    Revision History:
;   
;	    Modified as listed
;	    Started 
;
;*************************************************************************
;  The Master will interpret the MIDI signal from UART and will then break up the info
;   and then send this to the correseponding slave
;    
;	MIDI: <Control>, <Pitch>, <Velocity>    
;	    Upper Nibble: Control Byte
;	    Lower Nibble: Instrument Address = Default for testing 0x01
;	    Basic Control <upper> Bytes: 0x90 = Note ON
;				 0x80 = Note OFF
;				 0xF0 = Special function
;			  <Pitch> = xPPP PPPP // Note 0-127
;			  <Velocity> = xVVV VVVV // Attack 0-127
;    
;	Note Slaves: <Pitch>
;	    MPPP PPPP 
;		P = The pitch index from 0-127, min is E1 // 28, max is D#4 // 63
;		M = Mute control boolean based on upper control, 0 = Mute
;
;	Pluck Slaves: <Velocity>, <String>
;	    xVVV VVVV,Fxxx  SSSS 
;		V = How Aggresive to attack string
;		F = select finger or pick, 0 = finger
;		S = which string to pluck, E = bit0, A = bit1, D = bit2, G = bit3
;*************************************************************************    
    ; PIC16F1788 Configuration Bit Settings

; Assembly source line config statements
    
	#INCLUDE "p16f1788.inc"
	#INCLUDE <MidiMasterSetup.inc>
	#INCLUDE <MidiMasterEEWRITE.inc>
	#INCLUDE <MidiMasterEEREAD.inc>
	#INCLUDE <MidiMasterPOPout.inc>
	#INCLUDE <MidiMasterPUSHin.inc>
	

; CONFIG1
; __config 0xE9A4
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_ON
; CONFIG2
; __config 0xDFFF
 __CONFIG _CONFIG2, _WRT_OFF & _VCAPEN_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_OFF

 
 ;*********************
 ;Define Constants
 ;*********************
 
    ; NOTE SLAVE ADDRESSES
	    ESLAVE	    EQU H'022' ; SLAVE IS ADDRESSED // 0X01
	    ASLAVE	    EQU H'023' ; SLAVE IS ADDRESSED // 0X02
	    DSLAVE	    EQU H'024' ; SLAVE IS ADDRESSED // 0X04
	    GSLAVE	    EQU H'025' ; SLAVE IS ADDRESSED // 0X08
    ; PLUCKING/PICK SLAVE ADDRESSES
	    PLUCKSLAVE	    EQU H'026' ; SLAVE IS ADDRESSED // OX10
	    
 

    ORG H'000'					
    GOTO SETUP					;RESET CONDITION GOTO SETUP
    ORG H'004'
    GOTO INTER
 
    
SETUP
    ; BASIC SETUP HERE
    BANKSEL OSCSTAT
    BTFSC OSCSTAT,PLLR	    ; WAIT FOR PLL TO BE UP AND RUNNING
    GOTO $-1
    BANKSEL OSCCON
    MOVLW H'0FA'	    ; SET 32MHZ INTERNAL OSSCILATOR
    MOVWF OSCCON
    BANKSEL OSCSTAT
    BTFSC OSCSTAT,OSTS	    ; WAIT FOR OSSCILATOR TO BE READY
    GOTO $-1
    CALL START		    ; CALL SETUP INCLUDE
    ; EUART SETUP HERE
    BANKSEL BAUDCON
    CLRF BAUDCON	    ; CLEAR BAUD RATE CTL FOR 8-BIT ASYNC
    BANKSEL TXSTA
    CLRF TXSTA		    ; CLEAR TRANSMIT REGISTER
    BANKSEL RCSTA
    CLRF RCSTA	
    MOVLW H'0-AMB0'		    ; SET FOR CONTINUOUS RECIEVE
    MOVWF RCSTA
    BANKSEL SPBRGL
    CLRF SPBRGL
    MOVLW H'011'	    ; SET BAUD FOR ASYNC 31.25K
    MOVWF SPBRGL
    BANKSEL SPBRGH	    ; CLEAR UPPER REGISTER // PRECAUSION
    CLRF SPBRGH
    ; PIN ASSIGNMENTS
    BANKSEL APFCON1
    CLRF APFCON1	    ; SET PINS
    BANKSEL APFCON2
    CLRF APFCON2	    ; SET PINS 
    ; I2C SETUP HERE
    BANKSEL SSP1CON1
    MOVLW H'038'	    ; SET 7 BIT MASTER WITH ADJUSTABLE CLOCK
    MOVWF SSP1CON1
    BANKSEL SSP1ADD
    MOVLW H'013'	    ; SET 400K I2C CLOCK
    MOVWF SSP1ADD
    BANKSEL SSP1CON2
    CLRF SSP1CON2	    ; CLEAR REGISTER
    BANKSEL SSP1CON3
    CLRF SSP1CON3	    ; CLEAR REGISTER MOST FEATURES FOR SLAVES
    ; SET ADDRESSES FOR SLAVES
    
    
    
    
    
    
INTER
 
END