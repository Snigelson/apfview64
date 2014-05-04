;
; APF Viewer
; https://github.com/snigelson/apfview
;
; Main file
;
		processor 6502

; Handy macros for branching
	MAC BGE
		BCS {1}
	ENDM

	MAC BLO
		BCC {1}
	ENDM

; Do not execute following byte
	MAC SKIP_1
		.BYTE $24
	ENDM

; Do not execute following two bytes
	MAC SKIP_2
		.BYTE $2c
	ENDM

; Wait for key, any key. Returned in A.
	MAC GETKEY_BLOCK
.GETK	JSR $ffe4
		BEQ .GETK
	ENDM


; TEMP VARS USED WHEN PLOTTING - May be reused elsewhere
buf		EQU $7a ;graphics buffer
bw		EQU	$f7 ;bits left to write in byte during plot
curlin	EQU $f8 ;current line
curcol	EQU $f9 ;bytes left to write on line
bp		EQU $fc ;points to current byte to write during plotting
sn		EQU	$fe ;interlacing offset
mode	EQU $ff ;mode. To shift in ones or zeros

; TEMP VARS USED ELSEWHERE - Take care about which subs uses what
pc_tmp	EQU $fa ;putchar temp
		   ;$fb
cp		EQU $fc ;USED IN CHARACTER POSITION CALC
		   ;$fd
temp	EQU $fe	;USED IN BITMAP CLEARER
           ;$ff ;AND CHARACTER PUTTER

intbuf	EQU $f9 ;integer read
chrnum	EQU $f9 ;number of characters read
opno	EQU $f8 ;Option number, in menu read

; GLOBALS! USE THESE ADDRESSES FOR ONLY ONE PURPOSE
sk		EQU $02 ;line skip offset
fileend	EQU $03 ;End of loaded files
		   ;$04
foff	EQU $05 ;Next file byte to read
		   ;$06

		ORG $0801

line1:
		.word line2,1
		.byte $8f,$20,"APERTURE PICTURE FORMAT VIEWER",0
line2:
		.word line3,2
		.byte $8f,$20,"(C) APERTURE LABORATORIES 1985",0
line3:
		.word basicend,3
		.byte $9e,$20,"2136",0
basicend:
	    .word 0

;ASSEMBLY CODE STARTS HERE

		; Load charset, for ultimate ASCII compatibility
		JSR load_charset

		; Empty screen
		JSR clr_bmscr

		; Enable bitmap display
		JSR bitmap_enable
next_slide:
		; Print "Loading" in the center of the screen
		JSR print_text_loading

		; Load picture file
		JSR load_apf
		; If error, ABORT
		BCS the_erroneous_end

		; Plot the loaded image
		JSR plot_image

		; Load menu file
		JSR load_amf
		; If error, ABORT
		BCS the_erroneous_end

		; Show the menu
		JSR show_menu
		; Read in (a correct) choice
		JSR get_choice
		; If carry is set, an "EXIT" option was selected.
		BCC next_slide
		BCS the_chosen_end

the_erroneous_end:
		GETKEY_BLOCK
the_chosen_end:
		; Reset machine.
		JMP ($FFFC)

		INCLUDE "file.s"
		INCLUDE "text.s"
		INCLUDE "bitmap.s"
		INCLUDE "menu.s"
