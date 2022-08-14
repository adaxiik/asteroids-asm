    global    main
    %include 'externs.asm'
    %define SDL_INIT_VIDEO 32
    %define SDL_WINDOWPOS_CENTERED 805240832
    %define SDL_WINDOW_SHOWN 4
    %define SDL_RENDERER_PRESENTVSYNC 4
    %define SDL_RENDERER_ACCELERATED 2
    %define SDL_QUIT 256

section .bss
    window: resq 1
    renderer: resq 1

section .data
    title: db "asteroids-asm", 0 


; RDI, RSI, RDX, RCX, R8 a R9
section   .text
main:
    enter 0, 0
    
    call setup_window_and_renderer

    sub rsp, 64
    ;-56 : SDL_PollEvent e
    mov byte [rbp - 57], 0 ; quit

    ; Main loop
    .main_loop:
    cmp byte [rbp - 57], 1 ;while quit == 0
    je .quit

    ;event loop
    .event_loop:
        lea rdi, [rbp - 56]
        call SDL_PollEvent
        cmp rax, 0
        je .event_loop_end
        
        ;SDL_EVENT.type == SDL_QUIT
        xor rax, rax
        mov rbx, 1
        cmp dword [rbp - 56], SDL_QUIT
        cmove rax, rbx
        mov byte [rbp - 57], al

    jmp .event_loop
    .event_loop_end:
    
    call render_bg

    jmp .main_loop ; jump to main loop

    .quit:
    call cleanup
    
    mov rax, 0
    leave
    ret             


render_bg:
    enter 0, 0
     ;fill bg
    ;SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255)
    mov rdi, [renderer]
    mov rsi, 18
    mov rdx, 18
    mov rcx, 18
    mov r8, 255
    call SDL_SetRenderDrawColor

    ;SDL_RenderClear(renderer)
    mov rdi, [renderer]
    call SDL_RenderClear

    ;render frame
    ;SDL_RenderPresent(renderer)
    mov rdi, [renderer]
    call SDL_RenderPresent
    leave
    ret

setup_window_and_renderer:
    enter 0,0
     ; Initialize SDL
    mov rdi, SDL_INIT_VIDEO
    call SDL_Init

    ; Create window
    mov rdi, title
    mov rsi, SDL_WINDOWPOS_CENTERED
    mov rdx, SDL_WINDOWPOS_CENTERED
    mov rcx, 800
    mov r8, 600
    mov r9, SDL_WINDOW_SHOWN
    call SDL_CreateWindow
    mov [window], rax

    ; Create renderer
    mov rdi, [window]
    mov rsi, -1
    xor rdx, rdx
    or rdx, SDL_RENDERER_ACCELERATED
    or rdx, SDL_RENDERER_PRESENTVSYNC
    call SDL_CreateRenderer
    mov [renderer], rax
    leave
    ret

cleanup:
    enter 0, 0
     ; Destroy renderer
    mov rdi, [renderer]
    call SDL_DestroyRenderer

    ; Destroy window
    mov rdi, [window]
    call SDL_DestroyWindow

    ; Quit SDL
    mov rdi, 0
    call SDL_Quit
    leave
    ret
