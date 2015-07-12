;
;interrupt handlers & executive module
; copyright 1976 d. kruglinski
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; system linkages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
estrt	equ	300h	;load address
tadr	equ	42h	;address of # tasks
;			 followed by dispatch table
kinta	equ	10h	;kbrd int addr
cinta	equ	18h	;rtc int addr
kintc	equ	0ffc0h	;kbrd int conrol addr
kdcod	equ	44h	;keyboard decoder addr
time	equ	3fh
	org	kinta	;keyboard interrupt
	jmp	kbent	;handler addr
	org	cinta	;rtc interrupt
	jmp	cent	;clock handler
	org	time
	db	0
	org	kdcod
	dw	kbdum	;dummy kb decoder
	org	estrt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; handler for real-time clock or 'exec' command
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
cent:	push	psw
	push	b
	push	d
	push	h	;save all regs
	lxi	h,time
	inr	m	;increment time
	ei		;enable interrupt
	call	exec	;call executive
	pop	h	;restore regs
	pop	d
	pop	b
	pop	psw
	ret		;return to graphics
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; handler for keyboard
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
kbent:	push	psw
	push	b
	push	d
	push	h
	lda	kintc	;read char/clear
	ei
	lxi	h,hrtn
	push	h	;save return addr
	lhld	kdcod	;keyboard decoder
	pchl		;simulated 'call'
hrtn:	pop	h
	pop	d
	pop	b
	pop	psw
	ret		;rtn to interrupted pgm
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; executive -- scans dispatch table, dispatches
;  program with object block when times match
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
exec:	mov	b,m	;save time in b
	lhld	tadr	;# of tasks
	mov	c,m
	inx	h	;top of dispatch table
	lxi	d,5
eloop:	mov	a,m
	ana	b	;mask time for task
	inx	h
	cmp	m	;compare object time
	jnz	noteq	;dispatch if equal
	push	b	;save bc (time & #)
	inx	h
	mov	c,m
	inx	h
	mov	b,m	;object block addr in bc
	inx	h
	mov	e,m
	inx	h
	mov	d,m	;program addr in de
	inx	h
	push	h	;save hl (pointer in list)
	lxi	h,ertn
	push	h	;save return address
	xchg		;program address in hl
	pchl		;jump to progra (call)
ertn:	pop	h	;restore pointer
	pop	b	;restore bc
	lxi	d,5
	jmp	endl	;continue scanning table
noteq:	dad	d	;hl=hl+5
endl:	dcr	c	;decrement task cnt
	jnz	eloop	;test next task
	ret		;return to handler
;
kbdum:	ret		;dummy kb decoder
	end
