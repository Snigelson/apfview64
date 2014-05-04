chrcol	EQU $d3
chrlin	EQU $d6

; Charset location
chr_loc	EQU $C000

; Charset file name
chr_name:
		.BYTE "CHARSET"
chr_len	EQU 7

load_charset:
		;SETNAM
		LDA #chr_len
		LDX <#chr_name
		LDY >#chr_name
		JSR $ffbd
		
		;SETLFS
		LDA #$01
		LDX #$08
		LDY #$00
		JSR $ffba
		
		;LOAD
		LDA #0
		LDX #<chr_loc
		LDY #>chr_loc
		JSR	$ffd5
		BCS charset_load_error
		RTS

; We end up here if load fail.
charset_load_error: subroutine
;Print error message
		LDX #24
.print:
		LDA charset_err_text,x
		JSR $FFD2
		DEX
		BPL .print
; Pull return address then exit to system.
		PLA
		PLA
		RTS
charset_err_text:
; I uh... don't remember what I was thinking.
;		.BYTE "?CHARSET NOT FOUND  ERROR"
		.BYTE "RORRE  DNUOF TON TESRAHC?"


print_text_loading:
;PRINT LOADING TEXT
		LDA #<text_loading
		STA pc_tmp
		LDA #>text_loading
		STA pc_tmp+1
		LDA #15
		STA chrcol
		LDA #12
		STA chrlin
		JSR puts
		RTS

text_loading:
		.byte "Loading...",0

print_text_load_err:
;PRINT LOADING ERROR TEXT
		LDA #<text_load_err
		STA pc_tmp
		LDA #>text_load_err
		STA pc_tmp+1
		LDA #6
		STA chrcol
		LDA #12
		STA chrlin
		JSR puts
		RTS

text_load_err:
		.byte "LOAD ERROR (FILE NOT FOUND?)",0


; Prints string pointed to by pc_tmp.
puts:	subroutine puts
		LDY #0
.loop:
		LDA (pc_tmp),y
		BEQ .end
		JSR putc
		INY
		BNE .loop
.end:
		RTS



; A contains character to put. Y is unchanged.
; Exits with carry set. Important somewhere.
putc:
		TAX
		TYA
		PHA

; (uint_16)cp += (chrlin*2) * 160+ chrcol*8 + 0x2000

; set temp to charcter to copy (0xc000+(A<<3) = charset base + character * 8)
putc_ccopy subroutine
		LDY #0
		STY temp+1
		TXA
; 16 bit mult. by 8, saved at temp
		ASL
		ROL temp+1
		ASL
		ROL temp+1
		ASL
		STA temp
		LDA temp+1
		ROL
; Add high byte of chrbase. This is correct.
		ADC #>chr_loc
		STA temp+1

; Calculate position to put at
chrpos subroutine

; (uint_16)cp = (chrlin*8) * 40 + chrcol*8 + 0x2000
;               (chrlin*2) * 160+ chrcol*8 + 0x2000

; cp=0
		STY cp
		STY cp+1

; (uint_16)cp = (chrlin*2) * 160
		LDA chrlin
		BEQ .skipit

		ASL
		TAY
		LDA #0
		TAX
.mul_loop:
		CLC
		ADC #160
		BCC .16skip
		INX
.16skip:
		DEY
		BNE .mul_loop

		STA cp

; (uint_16)cp += chrcol*8

.skipit:
		LDA chrcol
		ASL
		ASL
		ASL
		BCC .nomoreplease
		CLC
		INX
.nomoreplease:
		ADC cp
		STA cp
		TXA
; (uint_16)cp += 0x2000
		ADC #$20
		STA	cp+1

		LDY #7
chr_copy:
		LDA (temp),y
		STA (cp),y
		DEY
		BPL chr_copy

		INC chrcol

		PLA
		TAY
		RTS
