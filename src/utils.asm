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

;xmm0 = x0, xmm1 = y0, xmm2 = x1, xmm3 = x1
;returns distance between x0,y0 and x1,y1 in xmm0
distance:
    enter 0,0

    leave
    ret