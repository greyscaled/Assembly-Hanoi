; Greg Barkans
; SE 2XA3 Final Project
; McMaster Universty
; Departments: Computing and Software, Engineering
; Sources
	;General Information:
	;www.eecg.toronto.edu/~amza/www.mindsec.com/files/x86regs.html
	;http://www.drpaulcarter.com/pcasm/    <--asm_io.inc found here
	
	;LEVEL_LOOP and TOW_LOOP adapted from:
	;http://www.cas.mcmaster.ca/~franek/courses/se2xa3/slides/progs/loop3.asm

	;Recursive Solution for Hanoi Towers adapted from:
	;https://github.com/patrickrbc/tower-of-hanoi/blob/master/hanoi.s

	;Other resources:
	;Dr Franek's course notes 
	;http://www.cas.mcmaster.ca/~franek/courses/se2xa3/slides/slides.html
	;Dr Franek's labs/lab solutions (cannot provide link, need login)

%include "asm_io.inc" ;External package authored by Paul Carter

;;;;;;;;;;;;;;;;;Initialized Variables;;;;;;;;;;;;;;;;;;;;;;;

SECTION .data

;The three towers, as arrays
tow1 dd 0,0,0,0,0,0,0,0,9 ;First Tower
tow2 dd 0,0,0,0,0,0,0,0,9 ;Second Tower
tow3 dd 0,0,0,0,0,0,0,0,9 ;Third Tower

;printing related variabls
spce db " ",0
tow_len dd 36             ;Initialzed to the length of the arrays (36)
spaces dd 9               ;for spacing of +'s  
tab db "    ",0           ;for space between towers

;error messages
emsg1 db "Argument out of range",0
emsg2 db "Did not supply an arg",0
emsg3 db "Too many arguments",0

;Message upon successful completion:
donemsg db "			       DONE",0

;The Idea: To make a printing loop and just use these arrays
;as a representation of what to print


;;;;;;;;;;;;;;;;;NON-initialized Variables;;;;;;;;;;;;;;;;;;;
SECTION .bss
tow resd 1       ;which tower are we on?
towslot resd 1   ;What's currently in this spot of the array?
version resd 1   ;argument supplied by user (ie ./hantow 3)


;;;;;;;;;;;;;;;;;;;;;;;PROGRAM;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
SECTION .text
	global asm_main     ;This will run upon execution

;;;;;;;;;;;;;;;;;;FUNCTIONS AND PROCEDURES;;;;;;;;;;;;;;;;;;;

;;Level_LOOP: iterates each line (spans all towers)
;;TOW_LOOP: prints a line of each tower
;;printbases: exits LEVEL_LOOP by printing the bases

LEVEL_LOOP:
  mov [tow], dword 1          ;set to iterate all 3 towers

   TOW_LOOP: 
    mov edx, [towslot]
    mov ebx, [tow1 + edx]     ;ebx contains tow_[i]
    cmp ebx, 9
    je printbases             ;prints X's and |'s for all
   
    mov ecx, [spaces]         ;spaces := 9 (.data sec)
    sub ecx, ebx              ;9 - tow_[i] = # spaces
    
    call printspaces          ;prints # of spaces in ecx
    mov ebx, [tow1 + edx]     ;ebx contains tow_[i]
    call printelem            ;print # of pluses in tow_[i]
    mov eax, '|'              ;make the pole
    call print_char             
    
    mov ebx, [tow1 + edx]     ;
    call printelem            ;print the other side
    
    mov ebx, [tow1 + edx]     ;
    mov ecx, [spaces]         ;print spaces on other side
    sub ecx, ebx              ;
    call printspaces          ;

    mov eax, tab              ;prints separation
    call print_string         ;between the towers

    mov eax, [towslot]        ;
    add eax, [tow_len]        ;increment tow_[*this*]
    mov [towslot], eax        ;
   
    mov eax, [tow]            ;  
    inc eax                   ;move to next tower
    mov [tow], eax            ;until reach last one
    cmp eax, 4                ;
    jl TOW_LOOP               ;

    call print_nl             ;New Level!
    mov eax, [towslot]        ;108 = 36 x 3
    add eax, -108             ;get original i
    add eax, 4                ;add 4
    mov [towslot], eax        ;now tow1[i+4]

    jmp LEVEL_LOOP            ;Back to the start until we hit 9

      
printelem:
  cmp ebx, 0                  ;
  je printelem_DONE           ;takes tow_[i]
  mov al, byte '+'            ;prints # of +'s
  call print_char             ;according to i
  add ebx, -1                 ;
  jmp printelem               ;

  printelem_DONE:
    ret

printbases:
  call cleanreg
print_bases:
  mov al, byte 'X'
  call print_char
  add edx, 1
  cmp edx, 9
  jl print_bases
  
  mov al, byte '|'            ;insert the pole
  call print_char

  print_bases2:               ;print other side
    mov al, byte 'X'
    call print_char
    add ebx, 1
    cmp ebx, 9
    jl print_bases2

  mov eax, tab                ;tab between towers
  call print_string
  inc ecx
  mov edx, 0
  mov ebx, 0
  cmp ecx, 3
  jl print_bases
  ret                         ;this takes us back from
                              ;original LEVEL_LOOP call
printspaces:
  mov eax, spce
  call print_string
  add ecx, -1         ;ecx currently holds 9-number
  cmp ecx, 0          ;once it is zero, we're done
  jg printspaces
  ret

cleanreg:
mov eax, 0
mov ebx, 0
mov ecx, 0
mov edx, 0
ret

;;Stack argument functions
grabstack:
  mov eax, [ebp+8]
  cmp eax, 2
  jl _noarg
  ja _toomanyarg
  mov eax, dword [ebp+12]
  add eax, 4
  mov ebx, dword [eax]    ;ebx contains first arg
  mov ecx, 0
  mov cl, byte [ebx]      ;ecx contains first digit
  sub ecx, '0'            ;string to int
  cmp ecx, 2              ;check if arg in range (2,8)
  jl ERROR
  cmp ecx, 8
  jg ERROR
  mov [version], ecx      ;version:= # of disks user input
  call cleanreg

;;Initializing Functions
initialsetup:
  mov eax, [version]
  mov ebx, 4           ;need to figure out where to
  mul ebx              ;put top disk in tow1
  add eax, 4           ;tow1[36 - version*4 +4]
  mov ebx, 36          ;ex hantow 8
  sub ebx, eax         ;8x4 +4 = 36
  mov eax, 1           ;therefore tow1[0]

  initloop:
    mov [tow1 + ebx], eax ;add 1, 2, 3,...
    add eax, 1            ;until you reach last
    add ebx, 4            ;slot reserved
    cmp ebx, 32           ;for the base (tow1[8])
    jl initloop           ;
    jmp start

;;;;;;;;;;;;;;;;;;RECURSIVE SOLUTION;;;;;;;;;;;;;;;;;;;;;;;;
_hanoi:
  push ebp
  mov ebp, esp

  mov eax, [ebp+8]      
  cmp eax, 0
  jle _donehanoi

  push dword [ebp+16]     
  push dword [ebp+20]     
  push dword [ebp+12]     
  dec eax
  push dword eax          
  call _hanoi              
  add esp, 12

  push dword [ebp+16]
  push dword [ebp+12]
  push dword [ebp+8]
  call _print
  add esp, 12

  push dword [ebp+12]
  push dword [ebp+16]
  push dword [ebp+20]
  mov eax, [ebp+8]
  dec eax
  push dword eax
  call _hanoi
  add esp, 12

_donehanoi:
  mov esp, ebp
  pop ebp
  ret

_print:
  call read_char
  mov ebx, dword [ebp+8]   ;contains disk 
  mov eax, dword [ebp+12]  ;tower disk is in
  call movefrom
  mov eax, dword [ebp+16]  ;tower disk moves to
  call moveto
  call update
  ret

movefrom:
  dec eax                 ; (tow#-1)*36
  mul dword [tow_len]     ; ex. tow2 = 36

  _find:
    add eax, 4            ;look ahead 1 index
    mov ecx, [tow1 + eax] ;if tow2, tow1 + 36
    cmp ecx, ebx
    jle _find
    add eax, -4           ;we've gone 1 index too far, move back
    mov [tow1 + eax], dword 0
    ret

moveto:
  dec eax
  mul dword [tow_len]

  _find2:
    add eax, 4
    mov ecx, [tow1 + eax]
    cmp ecx, ebx
    jle _find2
    add eax, -4
    mov [tow1 + eax], ebx ;this time fill in disk #
    ret

update:
  mov [towslot], dword 0
  call LEVEL_LOOP
  call print_nl
  ret
  
;;;;;;;;;;;;;;;;;;MAIN (Start of Execution);;;;;;;;;;;;;;;;;;

asm_main:
	enter 0,0
	pusha
	
	jmp grabstack
start:
	mov [towslot], dword 0
        call LEVEL_LOOP
	call print_nl
	
	push dword 3
	push dword 2
	push dword 1
	mov eax, dword [version]
	push eax

	call _hanoi

	pop eax
	pop eax
	pop eax
	pop eax
	jmp DONE

ERROR:
	mov eax, emsg1
	call print_string
	call print_nl
	jmp _done

_noarg:
	mov eax, emsg2
	call print_string
	call print_nl
	jmp _done

_toomanyarg:
	mov eax, emsg3
	call print_string
	call print_nl
	jmp _done

DONE:
	call print_nl
	mov eax, donemsg
	call print_string
_done:
	call print_nl
	popa
	mov eax, 0
	leave
	ret          
