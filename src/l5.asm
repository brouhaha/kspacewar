;
;space war applications module
; copyright 1976 d. kruglinski
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; imporant constants
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
astrt	equ	500h	;load address
badr1	equ	0fffeh	;button read address
sun	equ	7	;collision rad of sun
intvl	equ	18h	;duration of explosion
eplsn	equ	8h	;collsiion rad of torpedos
acon	equ	8	;acceleration constant
rmax	equ	12	;torpedo timeout
vcon	equ	300h	;torpedo relative velocity
hdly	equ	20h	;hyperspace exit delay
limit	equ	7ah	;screen edge
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; graphics macros
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
exec	macro
	db	10h
	endm
;
; entry macro for dispatch table
entry	macro	mask,time,obj,prog
	db	mask
	db	time
	dw	obj
	dw	prog
	endm
;
; system call macro
scall	macro	modn
	rst	7
	db	modn
	endm
;
; macro to create 12-byte coordinate blk
coord	macro	xn,xm,xac,yn,ym,yac
	dw	xn
	dw	xm
	dw	xac
	dw	yn
	dw	ym
	dw	yac
	endm
;
; macro to load reg indexed (bc=bsae)
;  destroys hl
loadx	macro	reg,ofset
	lxi	h,ofset
	dad	b
	mov	reg,m
	endm
;
; macro to store reg indexed (bc=base)
;  destroys hl
storx	macro	reg,ofset
	lxi	h,ofset
	dad	b
	mov	m,reg
	endm
;
; macro to load 2 bytes from ofset
; into hl (bc=base addr)
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
;
; macro to store 2 bytes in ofset
; from hl (bc=base addr)
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
;
;macro to take absolute value of a
abs	macro
	cpi	0
	jp	pos	;jump if a pos
	cma		;complement a
pos:
	endm
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; linkage between system and application
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
tick	equ	3fh
nums	equ	46h
	org	40h
	dw	start	;display file
	org	42h
	dw	ntsk	;# tasks + list
	org	44h
	dw	kbdcd	;keyboard decode
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; dispatch table + number of objects
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	org	astrt
ntsk:	db	14	;# tasks
; dispatch table
ient1:	entry	0,0,sh1,init
ient2:	entry	0,0,sh2,init
pent1:	entry	0,1,sh1,sstrt
pent2:	entry	0,1,sh2,sstrt
	entry	0,0,sh1,sfly
	entry	0,0,sh2,sfly
	entry	0,0,bu1,bfly
	entry	0,0,bu2,bfly
gent1:	entry	0,1,sh1,fire
gent2:	entry	0,1,sh2,fire
	entry	0fh,0,sc1,score
	entry	0fh,8,sc2,score
	entry	7h,2,sh1,rot
	entry	7h,6,sh2,rot
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; object blocks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;   ship object blocks
sh1:	coord	0,0,0,0,0,0	;dynamic coords
	dw	ppos1	;pntr to mbeam instr
;  start postn
	coord	-6f00h,-7000h,0,6000h,6000h,0
	dw	bu1	;pntr to torpedo
	dw	pexh1+1	;call exhaust/zero
	dw	ship1	;ship sub
	dw	psub1+1	;call ship/explo
	dw	pdir1+1	;ship orent
	dw	pent1	;back pointer
	dw	gent1	;fire entry
	dw	sc1	;score
	db	01h	;acc button mask
	db	02h	;fire mask
	db	04h	;cw mask
	db	08h	;ccw mask
	db	0	;inhibit fire
	db	0	;orientation
	dw	badr1	;button address
	db	0ch	;hyperspace mask
	db	0	;hyperspace flag
	db	0	;initial orientation
	dw	ient1	;back pntr to init pgm
sh2:	coord	0,0,0,0,0,0
	dw	ppos2
	coord	6f00h,7000h,0,-6000h,-6000h,0
	dw	bu2
	dw	pexh2+1
	dw	ship2
	dw	psub2+1
	dw	pdir2+1
	dw	pent2
	dw	gent2
	dw	sc2
	db	10h
	db	20h
	db	40h
	db	80h
	db	0
	db	0
	dw	badr1
	db	0c0h
	db	0
	db	4
	dw	ient2
;   torpedo object blocks
bu1:	coord	0,0,0,0,0	;dyn coords
	dw	bpos1	;pntr to mdisp instr
	dw	bu2	;pntr to next torpedo
	db	0	;countdown since firing
bu2:	coord	0,0,0,0,0
	dw	bpos2
	dw	0
	db	0
;   score object blocks
sc1:	db	0	;binary score val
	dw	sc11+1	;1st digit
	dw	sc12+1	;2nd digit
sc2:	db	0
	dw	sc21+1
	dw	sc22+1
; working storage location
orsav:	dw	0
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; display file
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
start:	exec
	mbeam	80h,80h	;sun
	param	0,0
	jumps	sunsb
ppos1:	mbeam	0,0e0h
pdir1:	param	1,0
pexh1:	jumps	null
psub1:	jumps	ship1
ppos2:	mbeam	0,0c0h
pdir2:	param	1,0
pexh2:	jumps	null
psub2:	jumps	ship2
bpos1:	mbeam	0,0
bpos2:	mbeam	0,0
	param	1,0
	mbeam	1,1
sc11:	jumps	null
sc12:	jumps	null
	mbeam	0d0h,1
sc21:	jumps	null
sc22:	jumps	null
	jump	start
;
sunsb:	svec
	svf	6,0
	sv	3,2
	sv	3,3
	sv	6,4
	sv	3,5
	sv	6,6
	sv	3,7
	sv	6,0
	sv	3,1
	sve	3,2
	rets
;
ship1:	svec
	svf	3,0
	sv	2,6
	sv	4,4
	sv	2,2
	svf	2,6
	svf	4,0
	svf	2,1
	sv	2,3
	sv	4,4
	sve	2,6
	rets
ship2:	svec
	sv	3,0
	sv	2,5
	sv	4,4
	sv	2,2
	svf	2,6
	svf	4,0
	svf	2,1
	sv	2,3
	sv	4,4
	sve	2,6
	rets
explo:	param	2,0
	svec
	svf	3,0
	sv	6,4
	svf	3,2
	sv	6,7
	svf	3,4
	sv	6,2
	svf	3,0
	sve	6,5
	rets
null:	rets
exhst:	svec
	sv	7,4
	svef	7,0
	rets
;
; *********** programs *************
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   initialization program
;  scheduled at start & by ctl c
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
scpnt	set	28h
iepnt	set	35h
pepnt	set	24h
init:	ldblx	scpnt	;get score addr
	mvi	m,0	;zero score
	ldblx	pepnt	;get addr of ship st
	inx	h	;time
	mvi	m,0	;sched ship start
	ldblx	iepnt	;addr of init entry
	inx	h
	mvi	m,1	;desched self
	ret
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   ship start program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
dc	set	0
stcrd	set	03h
fbpnt	set	1ah
expnt	set	1ch
plpnt	set	1eh
pcpnt	set	20h
pdpnt	set	22h
orent	set	2fh
hflag	set	33h	;hyperspace flag
iornt	set	34h	;initial orientation
; select according to hflag
sstrt:	loadx	a,hflag
	cpi	0
	jnz	hypr
;  case--h=0--normal start--not hyperspace
	call	strt	;ship inst. desched
	call	begin	;orent=0,start pos
	ret
hypr:	jm	hdest
;  case--h=1--hyperspace return--no destroy
	call	strt
	call	hcord	;random coodinates
	ret
;  case--h=-1--hyperspace return--destroy
hdest:	call	dstry
	call	hcord	;rand coords
	ret
; endselect
;
strt:	ldblx	plpnt	;normal start
	xchg		;ship sub addr in de
	ldblx	pcpnt	;call addr in hl
	mov	m,e	;ship sub -> call
	inx	h
	mov	m,d
	ldblx	pepnt	;entry addr
	mvi	m,0	;mask
	inx	h
	mvi	m,1	;desched self
	ret
;
begin:	loadx	a,iornt	;set orientation
	storx	a,orent
	lxi	h,stcrd	;start coord
	dad	b	;  addr in hl
	mvi	d,12	;12 bytes to move
pxlop:	mov	a,m	; from start coords
	stax	b	; to dyn coords
	inx	h
	inx	b
	dcr	b
	jnz	pxlop
	ret
;
hcord:	scall	2	;random byte in a
	storx	a,xn+1	;h.o. x coord
	storx	a,xnm+1
	scall	2
	storx	a,yn+1	;h.o. y coord
	storx	a,ynm+1
	scall	2
	storx	a,xn	;l.o. x (velocity)
	scall	2
	storx	a,xnm
	scall	2
	storx	a,yn	;l.o. y
	scall	2
	storx	a,ynm
	mvi	a,0	;zero hyperspace flag
	storx	a,hflag
	ret
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   ship fly program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
xn	set	0h
yn	set	6h
xnm	set	2h
ynm	set	8h
xacc	set	04h
yacc	set	0ah
inpnt	set	0ch
nbpnt	set	0eh
rcnt	set	10h	;torpedo timeout
fipnt	set	26h
accm	set	2ah
firem	set	2bh
cwm	set	2ch
ccwm	set	2dh
hypm	set	32h	;hyperspace mask
finh	set	2eh
bapnt	set	30h
acon1	equ	(5*acon)/7
sfly:	scall	0	;move ship/explo
	scall	1	;accelerate
; test buttons only if not in hyperspace
	loadx	a,hflag
	cpi	0
	rnz
;  check if acc button on
	ldblx	bapnt	;button addr
	mov	d,m	;button word
	loadx	a,accm	;acc mask
	ana	d
	lxi	d,null	;no exhaust
	jz	xhst	;no acceleration
	mvi	d,0
	loadx	e,orent
	lxi	h,xatab
	dad	d
	dad	d	;x acc addr for orent
	mov	e,m	;xacc l.o.
	inx	h
	mov	d,m	;xacc h.o.
	ldblx	xacc	;add to original
	dad	d
	sdblx	xacc
;  same logic for yacc
	mvi	d,0
	loadx	e,orent
	lxi	h,yatab
	dad	d
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	ldblx	yacc
	dad	d
	sdblx	yacc
	lxi	d,exhst	;exhaust
xhst:	ldblx	expnt	;insert exhaust/zero
	mov	m,e	;in display file
	inx	h
	mov	m,d
;  test if x near edge
etst:	loadx	a,xn+1
	abs
	cpi	limit
	cp	swapx	;yes
;  test if y near edge
	loadx	a,yn+1
	abs
	cpi	limit
	cp	swapy	;yes
;  ship hit sun?
	loadx	a,xn+1
	abs
	cpi	sun	;h.o. x < sun radius
	jp	btst
	loadx	a,yn+1
	abs
	cpi	sun	;h.o. y < sun radius
	jp	btst
	call	dstry
	ret
;  test for close torpedos
btst:	loadx	d,dc+1	;ho x pos of ship
	loadx	e,dc+7	;ho y pos of ship
	push	b	;save ship blk pntr
	lxi	h,bu1	;first torpedo blk pntr
floop:	mov	b,h	;hl ->bc
	mov	c,l
	loadx	a,rcnt	;torpedo claimed?
	cpi	0	;test for zero
	jz	nxbul	;next torpedo
nrtst:	loadx	a,dc+1	;ho x pos of torpedo
	sub	d
	abs
	cpi	eplsn
	jp	nxbul	;not close enough
	loadx	a,dc+7	;ho y pos of torpedo
	sub	e	;subt ship pos
	abs
	cpi	eplsn
	jm	hit	;both close enough
nxbul:	ldblx	nbpnt	;next torpedo pntr
	sub	a	;zer a
	cmp	h	;check of h 0
	jnz	floop	;no
	cmp	l
	jnz	floop	;l not 0
	pop	b	;sane stack
	ret		;both h&l zero
hit:	ldblx	inpnt	;torpedo position
	mvi	m,0	;mbeam instr (blank)
	mvi	a,0	;release torpedo
	storx	a,rcnt
	pop	b	;restore ship blk
	call	dstry
	ret
;  subroutine to increment score. sched
;  ship start and replace ship with explosion
;  also used in hyperspace processing
dstry:	ldblx	scpnt	;restore score addr
	mov	a,m	;increment score
	inr	a
	daa
	mov	m,a
;  sched ship start
	ldblx	pepnt	;ship entry addr
	mvi	m,-1	;mask = -1
	lda	tick
	adi	intvl
	inx	h
	mov	m,a	;time+intval to pl st
;  replace ship with explosion
	lxi	d,explo	;explo sub
	ldblx	pcpnt	;sub call
	mov	m,e
	inx	h
	mov	m,d
	ret
;
swapx:	ldblx	xn	;swap x coords
	xchg
	ldblx	xnm
	sdblx	xn
	xchg
	sdblx	xnm
	ret
;
swapy:	ldblx	yn	;swap y coords
	xchg
	ldblx	ynm
	sdblx	yn
	xchg
	sdblx	ynm
	ret
;
;  acceleration table
xatab:	dw	0
	dw	acon1
yatab:	dw	acon
	dw	acon1
	dw	0
	dw	-acon1
	dw	-acon
	dw	-acon1
	dw	0
	dw	acon1
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; torpedo fly program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
bfly:	scall	1	;acceleration lookup
	scall	0	;move torpedo
;  test if x near screen edge
	loadx	a,dc+1	;ho x pos of torpedo
	abs		;abs value of x
	cpi	limit	;subtrct limit
	jp	blank	;near edge if + or 0
;  test if y near edge
	loadx	a,dc+7	;ho y pos of torpedo
	abs
	cpi	limit
	jp	blank	;not near edge
;  torpedo hit sun
	loadx	a,xn+1
	abs
	cpi	sun
	rp		;retn if not
	loadx	a,yn+1
	abs
	cpi	sun
	rp	;return if not
blank:	ldblx	inpnt	;mbeam/mdisp inst
	mvi	m,0	;mbeam
	mvi	a,0
	storx	a,rcnt	;release torpedo
	ret
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; torpedo fire program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gepnt	set	26h
rcon	equ	eplsn*140h
vcon1	equ	(5*vcon)/7
fire:	ldblx	gepnt	;dispatch table entry for ship
	inx	h
	mvi	m,1	;deschedule self
	loadx	a,orent
	add	a	;double orientation
	mov	l,a	;save for later
	mvi	h,0
	shld	orsav
	ldblx	fbpnt	;pntr to 1st torpedo ->hl
	push	b	;save ship block base
;  find free torpedo
	mov	b,h	;hl -> bc
	mov	c,l
	loadx	a,rcnt	;test for claimed torpedo
	cpi	0
	jz	shoot	;not claimed
	pop	b	;sane stack
	ret		;no free torpedos
;  shoot a torpedo
shoot:	 ldblx	inpnt	;unblank torpedo
	 mvi	m,2	; 'mdisp'
	 mvi	a,rmax	;set timeout counter
	 storx	a,rcnt	; to claim torpedo
	 pop	h	;ship obj blk in hl
	 mvi	d,10	;10 bytes to move
xloop:	 mov	a,m	;byte from ship coords
	 stax	b	;  into torpedo coords
	 inx	h	;next byte
	 inx	b
	 dcr	d	;decrement cntr
	 jnz	xloop
	 lxi	h,-10
	 dad	b	;restore torpedo blk
	 mov	b,h
	 mov	c,l
;  compute initial torpedo coordinates
;  x(n-1) & y(n-1) are ship's + collision rad
;  x(n) & y(n) are ship's + velocity + coll rad
	lhld	orsav
	lxi	d,xvtab	;x velocity table
	dad	d
	mov	e,m	;xvel in de
	inx	h
	mov	d,m
	ldblx	xn
	dad	d	;add vel+coll to x(n)
	sdblx	xn
;
	lhld	orsav
	lxi	d,xrtab	;coll rad table
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	ldblx	xnm
	dad	d	;add coll to x(n-1)
	sdblx	xnm
;
	lhld	orsav
	lxi	d,yvtab
	dad	d
	mov	e,m	;xvel in de
	inx	h
	mov	d,m
	ldblx	yn
	dad	d	;add vel+coll to y(n)
	sdblx	yn
;
	lhld	orsav
	lxi	d,yrtab
	dad	d
	mov	e,m
	inx	h
	mov	d,m
	ldblx	ynm
	dad	d	;add coll to y(n-1)
	sdblx	ynm
	ret
;  collision radius tables
xrtab:	dw	0
	dw	rcon
yrtab:	dw	rcon
	dw	rcon
	dw	0
	dw	-rcon
	dw	-rcon
	dw	-rcon
	dw	0
	dw	rcon
;  h.o. velocity + coll rad tables
xvtab:	dw	0
	dw	vcon1+rcon
yvtab:	dw	vcon+rcon
	dw	vcon1+rcon
	dw	0
	dw	-vcon1-rcon
	dw	-vcon-rcon
	dw	-vcon1-rcon
	dw	0
	dw	vcon1+rcon
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   score program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
scre	set	0
sdig1	set	1
sdig2	set	3
score:	loadx	a,scre	;score value
	ani	0fh	;right digit
	rlc		;*2
	adi	nums	;index of subr in hl
	mvi	h,0
	mov	l,a
	mov	e,m	;subr addr in de
	inx	h
	mov	d,m
	ldblx	sdig2	;pntr to digit
	mov	m,e	;subr addr in displ file
	inx	h
	mov	m,d
	loadx	a,scre	;score value
	ani	0f0h	;left digit
	rrc		;justify & *2
	rrc
	rrc
	adi	nums
	mvi	h,0
	mov	l,a
	mov	e,m
	inx	h
	mov	d,m
	ldblx	sdig1
	mov	m,e
	inx	h
	mov	m,d	;left dig in displ file
	ret		; return
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   program to rotate ships, initiate torpedo fire,
;   do hyperspace processing & check
;   for spent torpedos
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; don't check buttons if already in hyperspace
rot:	loadx	a,hflag
	cpi	0
	jnz	spnck	;check for spent bullets anyway
	ldblx	bapnt
	mov	d,m	;button word
;  check for both cw and ccw,
;  indicating hyperspace
	loadx	a,hypm	;mask for hyperspace
	mov	e,a
	ana	d
	xra	e
	jnz	cwck	;no - check for cw
;  blank ship
	lxi	d,null	;null graphics sub
	ldblx	pcpnt	;pntr to call
	mov	m,e
	inx	h
	mov	m,d	;insert
;  schedule ship start after hdly
	ldblx	pepnt	;ship start entry
	mvi	m,-1
	lda	tick
	adi	hdly
	inx	h
	mov	m,a
;  see if we need to destroy ship later
	mvi	d,1
	scall	2	;random # in a
	cpi	0	;> zero
	jp	nodst	;yes--don't destry
	mvi	d,-1	;no--destry
nodst:	storx	d,hflag	;indicate to sship start pgm
	jmp	spnck
;  end of hyperspace processing
;  check for cw (clockwise) rotation
cwck:	loadx	a,cwm	;mask for cw
	ana	d
	jz	ccwck	;check for ccw
	loadx	a,orent	;old orientation
	inr	a	;up by 1
	ani	7
	storx	a,orent
;  check for ccw (counterclockwise)
ccwck:	loadx	a,ccwm	;mask for ccw
	ana	d
	jz	dins
	loadx	a,orent
	dcr	a	;down by 1
	ani	7
	storx	a,orent	;insert orent in display file
dins:	loadx	d,orent
	ldblx	pdpnt	;orientation in display
	mov	a,m
	ani	0f8h	;strip old orent bits
	ora	d	;insert new
	mov	m,a
;  check if fire button on
firck:	ldblx	bapnt	;button addr
	mov	d,m	;button word
	loadx	a,firem	;fire mask
	ana	d
	jnz	inchk	;see if inhibit
	mvi	a,0	;no fire -- clear inh
	storx	a,finh
	jmp	spnck
inchk:	loadx	a,finh	;check inhibit flg
	cpi	0
	jnz	spnck	;set
	mvi	a,1	;not set -- set it
	storx	a,finh
	ldblx	fipnt	;schedule torpedo fire
	inx	h
	mvi	m,0
;  check for spent torpedos
spnck:	ldblx	fbpnt	; torpedo pointer
;  find claimed torpedo with timeout
;  for this ship
	mov	b,h	;hl -> bc
	mov	c,l
	loadx	a,rcnt
	cpi	0	;test for claimed
	rz		;not claimed
	dcr	a	;decrement timer
	storx	a,rcnt	;restore in block
	rnz		;not zero yet
	ldblx	inpnt
	mvi	m,0	;blank torpedo
	ret
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   keyboard decode program
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ctlc	equ	'C'
kbdcd:	mov	c,a	;save   char
	cpi	ctlc	;"C"?
	rnz		;return if not
	lxi	h,ient1+1	;sched init1
	mvi	m,0
	lxi	h,ient2+1	;sched init2
	mvi	m,0
	ret

	end
