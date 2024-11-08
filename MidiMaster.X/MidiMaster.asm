;***************************************************************************
;
;	    Filename: MidiMaster.asm
;	    Date: 11/05/2024
;	    File Version: 1
;	    Author: Owen Fujii
;	    Company: Idaho State University
;	    Description: The Program for the Master controller for the 
;			    midi bass guitar
;**************************************************************************
	
;*************************************************************************
; 
;	    Revision History:
;   
;	    Modified as listed
;	    Started 
;
;*************************************************************************
;  The Master will interpret the MIDI signal from UART and will 
;   then break up the info and then send this to the correseponding slave
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
;		P = The pitch index from 0-127, min is E1//28, max is D#4//63
;		M = Mute control boolean based on upper control, 0 = Mute
;		    Pitch of E string = E1 to C3
;		    Pitch of A string = A2 to F3
;		    Pitch of D string = D2 to A#3
;		    Pitch of G string = G2 to D#4
;
;	Pluck Slaves: <Velocity>, <String>
;	    xVVV VVVV,Fxxx  SSSS 
;		V = How Aggresive to attack string
;		F = select finger or pick, 0 = finger
;		S = which string to pluck,E = bit0,A = bit1,D = bit2,G = bit3
;*************************************************************************    
    ; PIC16F1788 Configuration Bit Settings

; Assembly source line config statements
    
	#INCLUDE "p16f1788.inc"
	#INCLUDE <MidiMasterSetup.inc>
	#INCLUDE <MidiMasterEEWRITE.inc>
	#INCLUDE <MidiMasterEEREAD.inc>
	#INCLUDE <MidiMasterPOPout.inc>
	#INCLUDE <MidiMasterPUSHin.inc>
	#INCLUDE <MidiMasterI2CWRITE.inc>
	

; CONFIG1
; __config 0xE9A4
 __CONFIG _CONFIG1, _FOSC_INTOSC & _WDTE_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _CPD_OFF & _BOREN_OFF & _CLKOUTEN_OFF & _IESO_OFF & _FCMEN_ON
; CONFIG2
; __config 0xDFFF
 __CONFIG _CONFIG2, _WRT_OFF & _VCAPEN_OFF & _PLLEN_ON & _STVREN_ON & _BORV_LO & _LPBOR_OFF & _LVP_OFF

 
 ;*********************
 ;Define Constants
 ;*********************
	; RESERVED ADDRESSES
	; H'20' WORKING SAVE
	; H'21' STATUS SAVE
	; H'30' ADDRESS FOR I2C SLAVE
	; H'31' BYTE 1 FOR I2C TRANSMIT
	; H'32' BYTE 2 FOR I2C TRANSMIT
	; H'33' FLAG FOR TWO BYTE TRANSMIT 
 
	; NOTE SLAVE ADDRESSES
	    ESLAVE	    EQU H'022' ; SLAVE IS ADDRESSED // 0X01
	    ASLAVE	    EQU H'023' ; SLAVE IS ADDRESSED // 0X02
	    DSLAVE	    EQU H'024' ; SLAVE IS ADDRESSED // 0X04
	    GSLAVE	    EQU H'025' ; SLAVE IS ADDRESSED // 0X08
	; PLUCKING/PICK SLAVE ADDRESSES
	    PLUCKSLAVE	    EQU H'026' ; SLAVE IS ADDRESSED // OX10
	; I2C REGISTERS
	    ADDRESS	    EQU H'030'
	    I2CBYTE	    EQU H'031'
	    I2CBYTE2	    EQU H'032'
	    FLAG	    EQU H'033'
	; ADDITIONAL GPR REGISTERS
	    CTLBYTE	    EQU H'034'
	    PBYTE	    EQU H'035'
	    VBYTE	    EQU H'036'
	    BUFFER	    EQU H'037'
	    TEMP	    EQU H'038'
	    MIDIADD	    EQU H'039'
	    
	    
 

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
    CLRF OSCCON
    MOVLW H'070'	    ; SET OSCILLATOR FOR 8MHZ AND LOOK AT CONFIG BITS
    MOVWF OSCCON
    BSF OSCCON,SPLLEN	    ; ENABLE 4X PLL FOR 32MHZ CLOCK
    BANKSEL OSCSTAT
    BTFSC OSCSTAT,OSTS	    ; WAIT FOR OSSCILATOR TO BE READY
    GOTO $-1
    CALL START		    ; CALL SETUP INCLUDE
    ; EUART SETUP HERE
    BANKSEL BAUD1CON
    CLRF BAUD1CON	    ; CLEAR BAUD RATE CTL FOR 8-BIT ASYNC
    BANKSEL SP1BRGL
    CLRF SP1BRGL
    MOVLW H'00F'	    ; SET BAUD FOR ASYNC 31.25K
    MOVWF SP1BRGL
    BANKSEL SPBRGH	    ; CLEAR UPPER REGISTER // PRECAUSION
    CLRF SPBRGH
    BANKSEL TXSTA
    CLRF TXSTA		    ; CLEAR TRANSMIT REGISTER
    BANKSEL RCREG
    CLRF RCREG
    BANKSEL RCSTA
    CLRF RCSTA	
    MOVLW H'0B0'	    ; SET FOR CONTINUOUS RECIEVE
    MOVWF RCSTA
    BANKSEL PIE1
    BSF PIE1,RCIE	    ; ENABLE RECIEVE INTERRUPT FOR UART
    ; PIN ASSIGNMENTS
    BANKSEL APFCON1
    CLRF APFCON1	    ; SET PINS
    BANKSEL APFCON2
    CLRF APFCON2	    ; SET PINS 
    ; I2C SETUP HERE
    BANKSEL SSP1CON1
    MOVLW H'028'	    ; SET 7 BIT MASTER WITH ADJUSTABLE CLOCK
    MOVWF SSP1CON1
    BANKSEL SSP1ADD
    MOVLW H'013'	    ; SET 400K I2C CLOCK
    MOVWF SSP1ADD
    BANKSEL SSP1CON2
    CLRF SSP1CON2	    ; CLEAR REGISTER
    BANKSEL SSP1CON3
    CLRF SSP1CON3	    ; CLEAR REGISTER MOST FEATURES FOR SLAVES
   ; BANKSEL PIE1
    ; SET ADDRESSES FOR SLAVES
    BANKSEL PORTB
    MOVLW H'002'
    MOVWF ESLAVE	    ; SET ADDRESS OF 0X01 AND WRITE
    MOVLW H'004'
    MOVWF ASLAVE	    ; SET ADDRESS OF 0X02 AND WRITE
    MOVLW H'008'
    MOVWF DSLAVE	    ; SET ADDRESS OF 0X04 AND WRITE
    MOVLW H'010'
    MOVWF GSLAVE	    ; SET ADDRESS OF 0X08 AND WRITE
    MOVLW H'020'
    MOVWF PLUCKSLAVE	    ; SET ADDRESS OF 0X10 AND WRITE
    ; FINAL SETUP
    CLRF CTLBYTE	    ; CLEAR STORAGE AND FLAG REGISTERS
    CLRF PBYTE
    CLRF VBYTE
    CLRF BUFFER
    ; SET MIDI DEVICE ADDRESS
    MOVLW H'01'
    MOVWF MIDIADD	    ; SET MIDI DEVICE ADDRESS
    BSF INTCON,GIE	    ; ENABLE INTERRUPTS
    BSF INTCON,PEIE 
    GOTO MAIN
    
MAIN
    BANKSEL PORTB
    BCF PORTB,1
    BTFSS BUFFER,2
    GOTO MAIN
    ; SEND TO PITCH SLAVE(S)
    BSF BUFFER,4	    ; SET CURRENT DATA 
    BSF PORTB,1
    MOVF ESLAVE,0
    MOVWF ADDRESS	    ; SET THE ADDRESS OF THE SLAVE
    BSF PBYTE,7		    ; SET NOTE TO BE PLAYED
    MOVF PBYTE,0	    ; MOVE TO WORKING
    MOVWF I2CBYTE	    ; MOVE TO BYTE
    CLRF FLAG		    ; CLEAR FLAG FOR SINGLE TRANSMISSION
    CALL I2CWRITE	    ; CALL WRITE
    ; SEND TO PLUCK SLAVE
    MOVF PLUCKSLAVE,0
    MOVWF ADDRESS	    ; MOVE PLUCK SLAVE ADDRESS TO TRANSMIT
    MOVF VBYTE,0	    
    MOVWF I2CBYTE
    MOVLW H'01'		    ; SET FOR FINGER STYLE AND E STRING
    MOVWF I2CBYTE2
    BSF FLAG,0		    ; SET FLAG FOR TWO BYTE
    CALL I2CWRITE
    CLRF BUFFER
    BCF PORTB,1
    GOTO MAIN
    
    
    
INTER
    BANKSEL INTCON 
    CLRF INTCON
    CALL PUSHIN
    BTFSC PIR1,RCIF	    ; CHECK EUART RECIEVE FLAG
    CALL RECIEVE    
    BANKSEL INTCON
  ;  CLRF PORTB
    CLRF PIR1
    BSF INTCON,GIE	    ; REENABLE INTERRUPTS
    BSF INTCON,PEIE
    CALL POPOUT
    RETFIE
    
RECIEVE
    BANKSEL RCREG
    MOVF RCREG,0
    BANKSEL PORTB
    BSF PORTB,1
    MOVWF TEMP
    BTFSC BUFFER,4	    
    RETURN
    BTFSC BUFFER,1
    GOTO BYTE2
    BTFSC BUFFER,0
    GOTO BYTE1
    MOVWF CTLBYTE	    ; VERIFY MIDI ADDRESS
    BCF CTLBYTE,4	    ; IGNORE COMMAND NIBBLE
    BCF CTLBYTE,5
    BCF CTLBYTE,6
    BCF CTLBYTE,7
    MOVF CTLBYTE,0
    BCF STATUS,Z
    SUBWF MIDIADD,0
    BTFSS STATUS,Z
    RETURN		    ; RETURN IF NOT VALID ADDRESS
    MOVF TEMP,0
    MOVWF CTLBYTE
    BSF BUFFER,0
    RETURN
    
BYTE1
    MOVF TEMP,0
    MOVWF PBYTE
    BSF BUFFER,1
    RETURN
    
BYTE2
    MOVF TEMP,0
    MOVWF VBYTE
    BSF BUFFER,2
    RETURN
 
END
