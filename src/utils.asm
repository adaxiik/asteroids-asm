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

;find addres of the first asteroid with active==0, or return 0
;*asteroid_pool
;single asteroid:  [x,y,dy,dy,active(bool),type(uchar/byte)] .. 34 aligned to 40
get_asteroid:
    enter 0,0

    xor rcx, rcx ; counter

    .get_asteroid_start:
        ;rcx*asteroid_size
        mov rax, ASTEROID_SIZE
        mul rcx

        mov dl, byte [rdi + rax + 33] ; asteroid_pool + index * ASTEROID_SIZE + 33(offset of active)
        cmp dl, 0
        je .get_asteroid_end ; if active == 0, return index

        inc rcx ; index++
        cmp rcx, ASTEROID_POOL_SIZE ; if index == ASTEROID_POOL_SIZE, return 0
        jne .get_asteroid_start
            xor rax, rax
            leave
            ret
        
    .get_asteroid_end:

    add rax, rdi

    leave
    ret


;find addres of the first explosion with active==0, or return 0
;*explosion_pool
;single explosion:  [x,y,rotation,spawn_time,active(bool),] .. 33 aligned to 40
get_explosion:
    enter 0,0
    xor rcx, rcx ; counter

    .get_explosion_start:
        mov rax, EXPLOSION_SIZE
        mul rcx

        mov dl, byte [rdi + rax + 33] ; explosion_pool + index * EXPLOSION_SIZE + 33(offset of active)
        cmp dl, 0
        je .get_explosion_end ; if active == 0, return index

        inc rcx ; index++
        cmp rcx, EXPLOSION_POOL_SIZE ; if index == EXPLOSION_POOL_SIZE, return 0
        jne .get_explosion_start
            xor rax, rax
            leave
            ret
        
    .get_explosion_end:

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

;double abs(double x)
;{
;    if (x < 0)
;        return -x;
;    return x;
;}

; x in rdi
; return in rax
abs_f:
    enter 0,0

    mov rcx, __float64__(0.0)
    movq xmm0, rcx
    movq xmm1, rdi
    comisd xmm0, xmm1
    jb .fabs_end
        mov rcx, __float64__(-1.0)
        movq xmm0, rcx
        mulsd xmm1, xmm0
    .fabs_end:
        movq rax, xmm1
    leave
    ret