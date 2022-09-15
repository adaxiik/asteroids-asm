section   .text
;create_rect(&rect, x,y,w,h)
create_rect:
    enter 0,0
    mov [rdi + 4 * 0], esi
    mov [rdi + 4 * 1], edx
    mov [rdi + 4 * 2], ecx
    mov [rdi + 4 * 3], r8d

    leave
    ret

;find addres of the first bullet with active==0, or return 0
;*bullet_pool
;single bullet:  [x,y,dx,dy,time,active(bool)]
get_bullet:
    enter 0,0
    
    xor rcx, rcx ; counter 

    .get_bullet_start:
        ;rcx*bullet_size
        mov rax, BULLET_SIZE
        mul rcx

        mov dl, byte [rdi + rax + 41] ; bullet_pool + index * BULLET_SIZE + 41(offset of active)
        cmp dl, 0
        je .get_bullet_end ; if active == 0, return index

        inc rcx ; index++
        cmp rcx, BULLET_POOL_SIZE ; if index == BULLET_POOL_SIZE, return 0
        jne .get_bullet_start
            xor rax, rax
            leave
            ret
            
    .get_bullet_end:
    
    add rax, rdi
    
    leave
    ret

; double fRand(double fMin, double fMax)
; {
;     double f = (double)rand() / RAND_MAX;
;     return fMin + f * (fMax - fMin);
; }
%define	RAND_MAX 2147483647
; min, max
; return in rax
get_random_double:
    enter 0,0

    movq xmm0, rdi  ; min
    movq xmm1, rsi  ; max
    
    call rand

    cvtsi2sd xmm2, rax
    mov rax, RAND_MAX
    cvtsi2sd xmm3, rax
    divsd xmm2, xmm3    ; xmm2 = (double)rand() / RAND_MAX

    subsd xmm1, xmm0    ; xmm1 = max - min
    mulsd xmm2, xmm1    ; xmm2 = f * (fMax - fMin)
    addsd xmm2, xmm0    ; xmm2 = fMin + f * (fMax - fMin)

    movq rax, xmm2

    leave
    ret