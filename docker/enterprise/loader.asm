;vidpage     equ     80h           ;1 video page on 00000h
;vidpage     equ     81h           ;1 video page on 04000h
;vidpage     equ     82h           ;1 video page on 08000h
vidpage     equ     83h           ;1 video page on 0c000h
;vidpage     equ     01h           ;2 video pages on 00000h and 04000h
;vidpage     equ     02h           ;2 video pages on 00000h and 08000h
;vidpage     equ     03h           ;2 video pages on 00000h and 0c000h
;vidpage     equ     12h           ;2 video pages on 04000h and 08000h
;vidpage     equ     13h           ;2 video pages on 04000h and 0c000h
;vidpage     equ     23h           ;2 video pages on 08000h and 0c000h
bias        equ     31
border      equ     0
screen_y    equ     25*8
screen_x    equ     40
;scrload     equ     0c000h          ;load address of screen file , if it is 0 then screen is not loaded
scrload     equ     00000h          ;load address of screen file , if it is 0 then screen is not loaded
scrlength   equ     4000h           ;load length of screen file , name of file has to be set at filescr:
file1load   equ     0h              ;load address of file1 , if it is 0 then file1 is not loaded        (ex intro)
file1length equ     0h              ;load length of file1 , name of file has to be set at file1:
file1start  equ     0h              ;start address of 1st file, after end it will return to loader

;load address of file2 (main program)
file2load equ 4000h ; GENERATED !!!

;load length of file2 , name of file has to be set at file2:
file2length equ 13209 ; GENERATED !!!

;start address of 2nd file, it will not return to loader
file2start equ 4000h ; GENERATED !!!

reset	equ		00a0h
lptstrt equ		8000h
		macro   exos n
		rst		30h
		db		n
		endm
		
		org		00f0h
		db		00h,05h
		dw		fillen
		defs	0ch
startpr	di
		ld		sp,0100h
        call    initialize

        ld      a,(0001h)
        out     (0b1h),a
        ld      a,(0002h)
        out     (0b2h),a
        ld      a,(0003h)
        out     (0b3h),a
        ld      hl,4000h
        ld      de,4001h
        ld      (hl),l
        ld      bc,0bfffh
        ldir

        ld      sp,0c000h

    if scrload > 0
        ld      de,filescr      ;file name
        ld      hl,scrload      ;file target
        ld      bc,scrlength    ;file length
        call    loadfile
    endif
		xor		a
		out		(82h),a
		ld		a,0cch
		out		(83h),a

;        call    load_map        ;load map
    if file1load > 0
		ld		de,file1
		ld		bc,file1length  ;file length (this has to be updated or checked after each compile)
		ld		hl,file1load    ;load address (this has to be updated)
		call    loadfile
        call    file1start      ;intro start
    endif

		xor     a
		ld      de,file2
		exos    1
		jp      nz,reset
		ld      hl, loading
		ld      de, 0bf00h
		ld      bc, loading_end - loading
        push    de
		ldir
		ret
loading
		ld      bc,file2length  ;file length (this has to be updated or checked after each compile)
		ld      de,file2load    ;load address (this has to be updated)
		exos    6
		xor     a
		exos    3
		jp      file2start      ;start address (this has to be updated or checked after each compile)
loading_end

    if scrload > 0
filescr:
        dbl     "test.scr"    ;file name to be loaded
    endif
    if file1load > 0
;file1:  dbl     "test.pr1"    ;file name to be loaded
file1:  db      8,"test1.pr1"
    endif

;file2:  dbl     "test.pr2"    ;file name to be loaded
file2:  db      8,"game.bin"       ; GENERATED

loadfile
		xor		a
        push    bc
        push    hl
		exos	1
        jp      nz,reset
        pop     de
        pop     bc
        exos    6
        xor     a
        exos    3
        ret

vidadd	ld      a,h				;Create CPC screen addressing into LPT
        add     a,8				; 1. char row: 0c000h, 0c800h, 0d000h, 0d800h, 0e000h, 0e8000h, 0f000h, 0f8000h 
        ld      h,a				; 2. char row: 0c050h, 0c850h, 0d050h, 0d850h, 0e050h, 0e8050h, 0f050h, 0f8050h 
        ret     nc				; 3. char row: 0c0a0h, 0c8a0h, 0d0a0h, 0d8a0h, 0e0a0h, 0e80a0h, 0f0a0h, 0f80a0h 
        sub     40h				;etc
        ld      h,a
        ld      a,l
        add     a,c
        ld      l,a
        ret     nc
        inc     h
        ret

disable_scr_bottom
        or      a
        ret     z
        ret     m
        ld      b,a
        ld      a,0c8h
        sub     b
        ld      l,a
        ld      h,00h
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl
        ld      de,lptstrt+02h  ;left margin
        add     hl,de           ;LPT address of first line to be excluded
        ld      de,0010h
setlineoff
        ld      (hl),03fh       ;set left margin to the maximum value
        add     hl,de
        djnz    setlineoff
        ret

;load_map
;        xor     a               ;channel 0
;        ld      de,filemap      ;file name
;        exos    1               ;open file to channel 0
;        ld      de,0c5a0h       ;load address 50592 (decimal values also can be used in the code, i do not like them :) )
;        ld      hl,0230h        ;load length 560 bytes
;        ld      b,05h           ;5x560 bytes are going to be loaded
;        call    load_parts
;        ld      de,0ed50h       ;load address 60752
;        ld      hl,0280h        ;load length 640 bytes
;        ld      b,03h           ;3x640 bytes are going to be loaded
;        call    load_parts
;        xor     a
;        exos    3               ;close file (close channel 0)
;        ret

;load_parts
;        ld      (loadlng+1),hl
;load_part
;        push    bc
;        push    de
;        xor     a               ;channel 0
;loadlng ld      bc,0000h        ;load length
;        exos    6               ;load 230h bytes to 0c5a0h on channel 0
;        pop     de
;        pop     bc
;        ld      a,d
;        add     a,08h
;        ld      d,a             ;next load address calculated
;        djnz    load_part
;        ret
;filemap db      9,"teopl.map"   ;file name and it's lenght to be updated

reset1  ld      sp,0100h
        ld      a,0ffh
        out     (0b2h),a
        ld      hl,reset
        ld      (0bff8h),hl
        ld      c,40h
        exos    0
        ld      a,01h
        out     (0b3h), a
        ld      a,06h
        jp      0c00dh
resetln equ     $-reset1

initialize
        ld      a,0ffh
        out     (0b2h),a
		ld      hl,reset1
        ld      de,reset
        ld      bc,resetln
        push    de
        ldir
        pop     hl
        ld      (0bff8h),hl

        ld      bc,100h+28      ;set bias d
        ld      d,bias*8
        exos    16

        ld      bc,100h+27      ;set border d
        ld      d,border
        exos    16

        ld      hl,0000h
delvar  ld      (hl),h
        inc     l
        bit     3,l
        jr      z,delvar
vid     ld      hl,tmp_mem
reqpage exos    24
        ld      (hl),c
        inc     hl
        jr      z,reqpage
        inc     c
        jp      nz,reset        ;if shared segment is not FF
        dec     l
        ld      a,l
        cp      03h             ;if EP64, it is 2, and reset computer
        jp      c,reset
        ld      d,00h
        ld      (hl),d
    if vidpage < 80h            ;get 1st video segment, if 2 was specified
        dec     l
        ld      a,(hl)
        ld      (hl),d
        ld      e,vidpage / 10h
        ld      (de),a
    endif
        dec     l               ;get a video segment, and store it's place in memora
        ld      a,(hl)
        ld      (hl),d
        cp      0fch
        jp      c,reset
        push    af              ;store video page
        ld      e,vidpage and 03h
        ld      (de),a
        ld      hl,tmp_mem      ;allocate other RAM's, max 8x16KB is allocated
        in      a,(0b0h)
        ld      c,a
        ld      e,d
chknxtp ld      a,(de)          ;if video memory is not specified for page0, then page0 will contain pos0 in RAM config
        or      a
        jr      z,storpg0
        inc     e               ;if video memory is specified for page0 or 1, then active page0 goes to pos1 or 2 in RAM config
        bit     3,e
        jr      nz,endramc
        jr      chknxtp
storpg0 ld      a,c
        ld      (de),a
        inc     e
        ld      c,(hl)
        inc     l
        bit     3,e
        jr      z,chknxtp
endramc 
givebck dec     hl
        ld      c,(hl)
        exos    25
        jr      z,givebck

        ld      de,0ce0h        ;setEXOSboundary
        exos    23
        jp      nz,reset

        pop     af              ;restore video page into AF
        rrca
        rrca
        and     0c0h
        ld      (vlpb+5),a		;video address into LPT source
		ld		c,a
		ld		a,0c0h
		sub     c
		ld		(difc000+2),a

        ld      hl,0000h
        in      a,(0b0h)
        cp      (hl)
        jr      z,page0ok
        di
        ld      a,(hl)
        ld      (0bffch),a      ;store new page0 at page0 system variable
        out     (0b1h),a
        ld      hl,0000h
        ld      de,4000h
        ld      b,d
        ld      c,e
        ldir
        out     (0b0h),a        ;activate new page0
        ei
page0ok
        ld      b,screen_x/2
        ld      a,1fh
        sub     b
        ld      (vlpb+2),a      ;left margin
        add     a,b
        add     a,b
        ld      (vlpb+3),a      ;right margin

        ld      hl,vlpb
        ld      de,lptstrt
        ld      bc,0010h
        push    de
        ldir					;copy 1 LPB (line parameter block) into LPT
        pop     hl
        ld      bc,0c70h		
        ldir					;create next 199 LPB (CPC screen is 200 line)
        ld      hl,vsync	
        ld      bc,vsyncln
        ldir					;copy VSYNC LPB's
        ld      hl,0000h        ;store memory segments
        ld      de,lptstrt+0cd8h
        ld      bc,0008
        ldir
        ld      hl,(0bff4h)     ;get address of LPT
        ld      de,0006h
        add     hl,de
        ld      d,(hl)          ;get address of char map
        inc     l
        ld      e,(hl)
        xor     a
        srl     e
        rr      d
        rra
        ld      e,a
        res     7,d
        res     6,d
        ld      (lptstrt+16h),de
        ld      hl,screen_x+(screen_y*100h)/2
        ld      (lptstrt+06h),hl

        ld      hl,lptstrt+0c00h+1
        ld      b,08h
        ld      de,0010h
setvint set     7,(hl)          ;set video int place
        add     hl,de
        djnz    setvint

        ld      a,25*8-screen_y ;number of lines to be deactivated on bottom of the screen
        call    disable_scr_bottom
        
        ld      bc,0c8h*100h+screen_x*2 ;200 (0c8h) row 40 (50h/2) ( line/character )

vidaddr	ld      iy,lptstrt		;address of LPT , it is paged now to page2, 8000h-800fh-n status line
vlpb4   ld      hl,(vlpb+4)
vidcikl	push    bc				;calculate memory address of LPB's
        ld      (iy+4),l		;Store low Nick address of screen line into LPB
        ld      (iy+5),h		;Store high Nick address of screen line into LPB
difc000 ld      de,4000h		;difference between CPC screen address, and Nick address
        add     hl,de			;get CPC address
        call    vidadd			;calculate the address
        xor     a
        sbc     hl,de			;get Nick address
        ld      de,0010h
        add     iy,de			;next LPB line
        pop     bc
        djnz    vidcikl
        ret

vlpb    db 0ffh,052h,0bh,33h,000h,00h,0,0       ;video lpb			200
        db 00h,00h,00h,00h,00h,00h,00h,00h
vsync   db 0d4h,2,3fh,0,0,0,0,0                 ;sync               44
        db 00,00,00,00,00,00,00,00
        db 0fdh,0,3fh,0,0,0,0,0                 ;                   3
        db 00,00,00,00,00,00,00,00
        db 0feh,0,6,3fh,0,0,0,0                 ;                   2
        db 00,00,00,00,00,00,00,00
        db 0ffh,0,3fh,20h,0,0,0,0               ;                   1
        db 00,00,00,00,00,00,00,00
        db 0f0h,2,6,3fh,6,0,0,0                 ;c3-->f3            18
        db 00,00,00,00,00,00,00,00
        db 0d4h,3,3fh,0,0,0,0,0                 ;f7-->c7            44
        db 00,00,00,00,00,00,00,00
vsyncln equ		$-vsync
tmp_mem equ     ((high $) + 1) * 100h
fillen  equ     $-startpr
