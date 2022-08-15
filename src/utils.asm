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