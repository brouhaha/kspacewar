;
; system functions module
; copyright 1976 d. kruglinski
; system call, move, acceleration, random
;
mstrt	equ	0c00h	;load address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; complement hl
comhl	macro
	mov	a,h
	cma
	mov	h,a
	mov	a,l
	cma
	mov	l,a
	inx	h
	endm
; load hl indexed (bc=base)
ldblx	macro	ofset
	push	d
	lxi	h,ofset
	dad	b
	mov	e,m
	inx	h
	mov	d,m
	xchg
	pop	d
	endm
; store hl indexed (bc=base)
sdblx	macro	ofset
	push	d
	xchg
	lxi	h,ofset
	dad	b
	mov	m,e
	inx	h
	mov	m,d
	pop	d
	endm
; load reg indexed (bc=base)
;  hl destroyed
loadx	macro	reg,ofset
	lxi	h,ofset
	dad	b
	mov	reg,m
	endm
; store reg indexed (bc=base)
;  hl destroyed
storx	macro	reg,ofset
	lxi	h,ofset
	dad	b
	mov	m,reg
	endm
;
	org	38h	;rst 7 address
	jmp	syscl
	org	mstrt	;load address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; system call function
;       entered on rst 7 followed by function #
;      destroys hl only
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
syscl:	pop	h	;get call # addr
	inx	h
	push	h	;return address
	dcx	h	;call # address
	push	de	;save de
	mov	e,m
	mvi	d,0	;call # in de
	lxi	h,caltb	;call table base
	dad	d
	dad	d	;add #
	mov	e,m
	inx	h
	mov	d,m
	xchg		;addr in hl
	pop	d	;restore de
	pchl		;jump to subroutine
caltb:	dw	move
	dw	accel
	dw	rand
	dw	0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; general purpose move function
; assumes first object block locations as follows:
;	0	x(n)
;	1
;	2	x(n-1)
;	3
;	4	x acceleration
;	5
;	6	y(n)
;	7
;	8	y(n-1)
;	9
;	a	y acceleration
;	b
;	c	pointer to 'mbeam' instr
;	d
; call: scall 0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
move:	push	b	;save bc
	call	mov1	;update x
	call	mov1	;update y
	ldax	b	;inst pntr in de
	mov	e,a
	inx	b
	ldax	b
	mov	d,a
	inx	d	;x coord address
	pop	b	;orig bc (top of list)
	loadx	a,1	;x(n) h.o.
	adi	80h	;zero at screen center
	stax	d	;x coord
	inx	d	;y coord addr
	loadx	a,7	;y(n) h.o.
	adi	80h	;zero at screen center
	stax	d	;y coord
	ret
; update either x or y
mov1:	push	b	;save bc for x(n)
	ldax	b	;x(n) to de
	mov	e,a
	inx	b
	ldax	b
	mov	d,a
	inx	b	;-x(n-1) to hl
	ldax	b	; and de to new x(n-1)
	cma
	mov	l,a
	mov	a,e
	stax	b
	inx	b
	ldax	b
	cma
	mov	h,a
	mov	a,d
	stax	b
	inx	h
	dad	d	;hl+de+de to hl
	dad	d
	inx	b	;xacc to de
	ldax	b
	mov	e,a
	inx	b
	ldax	b
	mov	d,a
	dad	d	;hl+xacc to hl
	pop	d	;bc for x(n)
	mov	a,l	;hl to new x(n)
	stax	d
	inx	d
	mov	a,h
	stax	d
	inx	b	;setup for next byte
	ret
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; orbital acceleration lookup function
;	1024-value version (2 bytes/value)
;	call:	scall	1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
atab	equ	0e00h	;location of acc table
xn	set	0
xacc	set	4
yn	set	6
yacc	set	0ah
;   adjust x & y for table lookup & set shift count
accel:	mvi	a,3
	sta	shcnt	;set shift count (6 shifts)
	ldblx	xn	;x value
	mov	a,h
	sta	hoxn	;save h.o. x
	cpi	0
	jp	posx	;abs value x
	comhl
posx:	xchg		;in de
	ldblx	yn	;y value
	mov	a,h
	sta	hoyn	;save h.o. y
	cpi	0
	jp	posy	;abs value of y
	comhl
posy:	mov	a,h	;in hl
	ora	d	;combine h.o. x & y
	cpi	40h
	jp	getad	;jump if > or = 40h
	dad	h	;double y in hl
	xchg
	dad	h	;double x in de
	xchg
	lda	shcnt
	dcr	a
	sta	shcnt	;decrement shift count
	jnz	posy	;loop if > 0
;   compute xacc table offset from x & y (in de)
getad:	mov	a,d    ;h.o. x
	rrc
	rrc
	rrc
	rrc		;rotate right 4
	mov	e,a
	ani	7h
	mov	d,a	;h.o. table offset
	mov	a,e
	ani	0c0h
	mov	e,a
	mov	a,h	;h.o. y
	rrc
	ani	3eh
	ora	e
	mov	e,a	;l.o. table offset
	push	d	;save offset for later
	call	retrv	;get acc value
;   make xacc sign agree with -x coord
	lda	hoxn	;h.o. x value
	cpi	0	;test sign
	jm	xmins
	comhl		;pos - comp xacc
xmins:	sdblx	xacc	;store in obj blk
;   compute yacc table offset from xacc offset
	pop	h	;xacc offset in hl
	mov	a,l
	rrc
	rrc
	rrc
	mov	e,a
	ani	7h
	mov	d,a	;h.o. table offset
	mov	a,e
	ani	0c0h
	mov	e,a
	mov	a,l
	ani	0c0h
	ora	h
	rlc
	rlc
	rlc
	ora	e
	mov	e,a	;l.o. offset
	call	retrv	;get yacc value
;   make yacc sign agree with -y coord
	lda	hoyn
	cpi	0
	jm	ymins
	comhl
ymins:	sdblx	yacc	;store yacc in obj blk
	ret		;return to calling program
;
; subroutine to restore acc value from table to hl
;  and adjust acc by shift count
;  input: offset in de
retrv:	lxi	h,atab	;table base
	dad	d	;add offset
	mov	e,m
	inx	h
	mov	d,m	;data in de
	push	b
	lda	shcnt	;save shift count in b
	mov	b,a
	cpi	0
	jz	exit	;shift count=0
;   shift de right 2 (de < 1000)
	mov	a,d
	rrc
	rrc
	mov	d,a
	mov	a,e
	rrc
	rrc
	push	psw	;save carry for rounding
	ani	3fh
	ora	d
	mov	e,a
	mvi	d,0
;   decrement & test shift count
loop:	dcr	b
	jz	round	;done shifting
;   shift e right 2 (d=0)
	pop	psw	;sane stack
	mov	a,e
	rrc
	rrc
	push	psw	;save carry
	ani	3fh
	mov	e,a
	jmp	loop
round:	pop	psw	;restore carry from last set
	mov	a,e	;l.o. acc
	aci	0	;round
	mov	e,a	;restore e
exit:	xchg		;acc in hl
	pop	b	;restore index reg
	ret
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; random number function
;   generates a new random number in a and 'rnd'
;   call:	scall 2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
rand:	lxi	h,rnd
	mov	a,m
	ani	8eh	;feedback mask, clear carry
	jpe	clear	;xor feedback bits
	cmc		;set carry if xor true
clear:	mov	a,m	;restore rnd
	ral		;shift in carry
	mov	m,a	;in memory
	ret
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; working storage
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rnd:	db	23h	;random number
hoxn:	db	0	;h.o. x value
hoyn:	db	0	;h.o. y value
shcnt:	db	0	;acc shift count
	end
