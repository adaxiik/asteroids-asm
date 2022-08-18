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
