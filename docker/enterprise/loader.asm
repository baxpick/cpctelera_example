; Original author: Geco

vidpage         equ     83h           ;1 video page on 0c000h
;vidpage         equ     80h           ;1 video page on 00000h
bias            equ     31
border          equ     0
reset           equ     00a0h
lptstrt         equ     8000h

file2load equ 4000h ; GENERATED !!!
file2length equ 7888  ; GENERATED !!!
file2start equ 4649h ; GENERATED !!!

        macro exos n
                rst 30h
                db n
        endm
		
        org     00f0h

        db      00h,05h
        dw	fillen
        defs	0ch
startpr
        di
        ld      sp,0100h                ;set stack to 0100h
        ld      hl,reset1               ;copy soft reset routine to 00a0h
        ld      de,reset
        ld      bc,resetln
        push    de
        ldir
        pop     hl
        ld      (0bff8h),hl             ;set soft reset routine address to EXOS

        ld      bc,100h+28              ;set bias d
        ld      d,bias*8
        exos    16

        ld      bc,100h+27              ;set border d
        ld      d,border
        exos    16

        ld      hl,0000h                ;delete allocated RAM segments table
delvar
        ld      (hl),h
        inc     l
        bit     3,l
        jr      z,delvar
vid     
        ld      hl,tmp_mem              ;get all available RAM to temporary space
reqpage 
        exos    24
        ld      (hl),c
        inc     hl
        jr      z,reqpage
        inc     c
        jp      nz,reset                ;if shared segment is not FF
        dec     l                       ;now we are at last position where available RAM segments are stored it is FF
        ld      a,l
        cp      03h                     ;if EP64, it is 2, and reset computer
        jp      c,reset
        ld      d,00h                   ;owerwrite FF with 00
        ld      (hl),d
        dec     l                       ;get a video segment, and store it's place in memora
        ld      a,(hl)                  ;get next available segment for video page (in our case now for only page3)
        ld      (hl),d
        cp      0fch
        jp      c,reset
        push    af                      ;store video page
        ld      e,vidpage and 03h       ;(this specify that only page3 will be used as video segment)
        ld      (de),a
        ld      hl,tmp_mem              ;allocate other RAM's, max 8x16KB is allocated
        in      a,(0b0h)
        ld      c,a
        ld      e,d
chknxtp
        ld      a,(de)                  ;if video memory is not specified for page0, then page0 will contain pos0 in RAM config
        or      a
        jr      z,storpg0
        inc     e                       ;if video memory is specified for page0 or 1, then active page0 goes to pos1 or 2 in RAM config
        bit     3,e
        jr      nz,endramc
        jr      chknxtp
storpg0
        ld      a,c
        ld      (de),a
        inc     e
        ld      c,(hl)
        inc     l
        bit     3,e
        jr      z,chknxtp
endramc
givebck
        dec     hl                      ;give back free RAM's which are not used by us
        ld      c,(hl)
        exos    25
        jr      z,givebck

        ld      de,0ce0h                ;setEXOSboundary , tell the user boundary on system segment to EXOS (we put the LPT into system segment)
        exos    23
        jp      nz,reset                ;if there is not enough free space on system segment, perform a soft reset
        pop     af                      ;restore video page into AF
        rrca                            ;calculate NICK address of video segment
        rrca
        and     0c0h
        ld      (vlpb+5),a              ;video address into LPT source
        ld      c,a                     ;get difference of address 0c000h and Nick address of video segment, it is needed for calculation of CPC addressing in LPT
        ld      a,0c0h
        sub     c
        ld      (difc000+2),a
        ld      a,0ffh
        out     (0b2h),a
        ld      hl,0000h                ;check if our 1st allocated RAM is the same with page0 RAM
        in      a,(0b0h)
        cp      (hl)
        jr      z,page0ok               ;if yes, skip next block, if not then tell it to EXOS, and copy the content of page0 RAM to our 1st allocated RAM
        di
        ld      a,(hl)
        ld      (0bffch),a              ;store new page0 at page0 system variable
        out     (0b1h),a
        ld      hl,0000h
        ld      de,4000h
        ld      b,d
        ld      c,e
        ldir
        out     (0b0h),a                ;activate new page0
        ei
page0ok
        ld      hl,vlpb                 ;create LPT base
        ld      de,lptstrt
        ld      bc,0010h
        push    de
        ldir                            ;copy 1 LPB (line parameter block) into LPT
        pop     hl
        ld      bc,0c70h		
        ldir                            ;create next 199 LPB (CPC screen is 200 line)
        ld      hl,vsync	
        ld      bc,vsyncln
        ldir                            ;copy VSYNC LPB's
        ld      hl,lptstrt+0c00h+1
        ld      b,08h                   ;put video interrupt flags into LPT (it 
        ld      de,0010h
setvint
        set     7,(hl)                  ;set video int place
        add     hl,de
        djnz    setvint

        ld      bc,0c850h               ;200 (0c8h) row 40 (50h/2) ( line/character )

vidaddr
        ld      iy,lptstrt		;address of LPT , it is paged now to page2, 8000h-800fh-n status line
vlpb4   
        ld      hl,(vlpb+4)
vidcikl
        push    bc			;calculate memory address of LPB's
        ld      (iy+4),l		;Store low Nick address of screen line into LPB
        ld      (iy+5),h		;Store high Nick address of screen line into LPB
difc000
        ld      de,4000h		;difference between CPC screen address, and Nick address
        add     hl,de			;get CPC address
        call    vidadd			;calculate the address
        xor     a
        sbc     hl,de			;get Nick address
        ld      de,0010h
        add     iy,de			;next LPB line
        pop     bc
        djnz    vidcikl

        ld      a,(0001h)               ;set up base CPC memory config
        out     (0b1h),a
        ld      a,(0002h)
        out     (0b2h),a
        ld      a,(0003h)
        out     (0b3h),a
        ld      hl,4000h                ;clear screen memory
        ld      de,4001h
        ld      (hl),l
        ld      bc,0bfffh
        ldir

        ld      sp,0c000h

        xor     a                       ;tell the LPT address to Nick
        out     (82h),a
        ld      a,0cch
        out     (83h),a
		
        di

        xor     a                       ;open file, file2 contains the file name
        ld      de,file2
        exos    1
        jp      nz,reset
        ld      hl, loading             ;copy load routine to 0bf00h to be able to use 0100h-0bf00h by the program
        ld      de, 0bf00h
        ld      bc, loading_end - loading
        push    de
        ldir
        ret                             ;continue at 0bf00h (loading)
loading
	ld      bc,file2length          ;file length (this has to be updated or checked after each compile)
	ld      de,file2load            ;load address (this has to be updated)
	exos	6
	xor		a
	exos	3
	
	jp      file2start              ;start address (this has to be updated or checked after each compile)
loading_end

file2:  db      12,"osmobito.bin"       ;file name to be loaded

vidadd	ld      a,h                     ;Create CPC screen addressing into LPT
        add     a,8                     ; 1. char row: 0c000h, 0c800h, 0d000h, 0d800h, 0e000h, 0e8000h, 0f000h, 0f8000h 
        ld      h,a                     ; 2. char row: 0c050h, 0c850h, 0d050h, 0d850h, 0e050h, 0e8050h, 0f050h, 0f8050h 
        ret     nc                      ; 3. char row: 0c0a0h, 0c8a0h, 0d0a0h, 0d8a0h, 0e0a0h, 0e80a0h, 0f0a0h, 0f80a0h 
        sub     40h                     ;etc
        ld      h,a
        ld      a,l
        add     a,c
        ld      l,a
        ret     nc
        inc     h
        ret

reset1  ld      sp,0100h                ;soft reset routine
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

;VLPB is definition of 1 pixel line, it will be copied 200 times into the beginning to LPT to create CPC screen
;   we need 200x1 pixel line definition, because CPC screen addressing is emulated by LPT
;vsync is the video synchron signal definition after the 200 pixel line definition

vlpb    
        db 0ffh,032h,0bh,33h,000h,00h,0,0     ;video lpb        200
        db 00h,01h,02h,03h,00h,00h,00h,00h
vsync   
        db 0d4h,2,3fh,0,0,0,0,0               ;sync              44
        db 00,00,00,00,00,00,00,00
        db 0fdh,0,3fh,0,0,0,0,0		      ;		          3
        db 00,00,00,00,00,00,00,00
        db 0feh,0,6,3fh,0,0,0,0		      ;		          2
        db 00,00,00,00,00,00,00,00
        db 0ffh,0,3fh,20h,0,0,0,0	      ;		          1
        db 00,00,00,00,00,00,00,00
        db 0f0h,2,6,3fh,6,0,0,0               ;c3-->f3           18
        db 00,00,00,00,00,00,00,00
        db 0d4h,3,3fh,0,0,0,0,0               ;f7-->c7           44
        db 00,00,00,00,00,00,00,00
		
vsyncln equ	$-vsync
tmp_mem equ     ((high $) + 1) * 100h
fillen  equ     $-startpr
