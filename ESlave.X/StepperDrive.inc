;***************************************************************************
;
;	    Filename: StepperDrive.ASM
;	    Date: 11/21/2024
;	    File Version: 1
;	    Author: Owen Fujii
;	    Company: Idaho State University
;	    Description: An include file for stepping an output at a 50% duty
;			    cycle based on a set time delay. works for 4 byte 
;			    timing
;**************************************************************************
	
;*************************************************************************
; 
;	    Revision History:
;   
;	    Modified as listed
;	    Started 11/21/2024
;
;*************************************************************************
    
; GPR Reservations  
	STEPBYTE1	EQU	H'060'
	STEPBYTE2	EQU	H'O61'
	STEPBYTE3	EQU	H'063'
	STEPBYTE4	EQU	H'064'
	NULL		EQU	H'065'
	
DRIVE_CODE CODE
 
DRIVE
	BANKSEL PORTB
	MOVLW H'000'
	SUBWF STEPBYTE4,0	; SKIP BYTE IF IT IS 0
	BTFSC STATUS,Z
	GOTO EVALBYTE3
	; 
UPPERLOOP2
	
	DECFSZ STEPBYTE,1
	GOTO UPPERLOOP2
	
 
EVALBYTE3
	
	
	
STEP
	BSF PORTB,3
	CALL DELAY
	BTFSS PIR1,TMR1IF   ; POLL COMPLETION OF TMR1
	GOTO $-1
	BCF PORTB,3
	CALL DELAY
	RETURN

	
DELAY
	BANKSEL TMR1H
	MOVLW H'0D6'
	MOVWF TMR1H
	BANKSEL TMR1L
	MOVLW H'0D8'
	MOVWF TMR1L	    ; LOAD TMR REGISTERS TO PRODUCE A 25K COUNT
	BANKSEL T1CON
	MOVLW H'034'    ; 1:8 PRESCALE WITH INSTRUCTION CLK AS SOURCE 
	MOVWF T1CON
	BSF T1CON,0	    ; ENABLE TIMER 1
	BCF PIR1,TMR1IF
	RETURN
	
	
    
    