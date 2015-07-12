;
; numerals module
; copyright 1976 d. kruglinski
;
nstrt	equ	400h	; load address
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; graphics macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mbeam	macro	x,y
	db	0
	db	x
	db	y
	endm
;
mdisp	macro	x,y
	db	2
	db	x
	db	y
	endm
;
lvec	macro	x,y
	db	4
	db	x
	db	y
	endm
;
svec	macro
	db	6
	endm
sv	macro	len,dir
	db	dir | (len << 4)
	endm
svf	macro	len,dir
	db	dir | (len << 4) | 8h
	endm
sve	macro	len,dir
	db	dir | (len << 4) | 80h
	endm
svef	macro	len,dir
	db	dir | (len << 4) | 88h
	endm;
;
param	macro	scl,orn
	db	8
	db	orn | (scl << 4)
	endm
;
jump	macro	addr
	db	0ah
	dw	addr
	endm
;
jumps	macro	addr
	db	0ch
	dw	addr
	endm
;
rets	macro
	db	0eh
	endm
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; system linkages
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	org	46h
	dw	zero
	dw	one
	dw	two
	dw	three
	dw	four
	dw	five
	dw	six
	dw	seven
	dw	eight
	dw	nine
	org	nstrt
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; numerals 0-9
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
zero:	svec
	sv	6,0
	sv	4,2
	sv	6,4
	sv	4,6
	svef	6,2
	rets
one:	svec
	svf	4,2
	sv	6,0
	svf	6,4
	svef	2,2
	rets
two:	svec
	svf	6,0
	sv	4,2
	sv	3,4
	sv	4,6
	sv	3,4
	sv	4,2
	svef	2,2
	rets
three:	svec
	sv	4,2
	sv	6,0
	sv	4,6
	svf	3,4
	sv	4,2
	svf	3,4
	svef	2,2
	rets
four:	svec
	svf	4,2
	svf	3,0
	sv	4,6
	sv	3,0
	svf	4,2
	sv	6,4
	svef	2,2
	rets
five:	svec
	sv	4,2
	sv	3,0
	sv	4,6
	sv	3,0
	sv	4,2
	svf	6,4
	svef	2,2
	rets
six:	svec
	svf	3,0
	sv	4,2
	sv	3,4
	sv	4,6
	sv	6,0
	sv	4,2
	svf	6,4
	svef	2,2
	rets
seven:	svec
	svf	6,0
	sv	4,2
	sv	6,4
	svef	2,2
	rets
eight:	svec
	sv	6,0
	sv	4,2
	sv	6,4
	sv	4,6
	svf	3,0
	sv	4,2
	svf	3,4
	svef	2,2
	rets
nine:	svec
	svf	4,2
	sv	6,0
	sv	4,6
	sv	3,4
	sv	4,2
	svf	3,4
	svef	2,2
	rets
	end
