    global    main
    %include 'externs.asm'
    %define SDL_INIT_VIDEO 32
    %define SDL_WINDOWPOS_CENTERED 805240832
    %define SDL_WINDOW_SHOWN 4
    %define SDL_RENDERER_PRESENTVSYNC 4
    %define SDL_RENDERER_ACCELERATED 2
    %define SDL_QUIT 256
    %define IMG_INIT_PNG 2

section .bss
    window: resq 1
    renderer: resq 1
    asteroids_texture: resq 1

section .data
    title: db "asteroids-asm", 0 
    asteroids_texture_path: db "assets/asteroids.png", 0
    error_text : db "ERROR", 0

; RDI, RSI, RDX, RCX, R8 a R9
section   .text
main:
    enter 64, 0
    
    call setup_window_and_renderer
    call load_textures

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
    ; errror if is not 0
    cmp rax, 0
    jne error_msg

    ; Create window
    mov rdi, title
    mov rsi, SDL_WINDOWPOS_CENTERED
    mov rdx, SDL_WINDOWPOS_CENTERED
    mov rcx, 800
    mov r8, 600
    mov r9, SDL_WINDOW_SHOWN
    call SDL_CreateWindow
    cmp rax, 0
    je error_msg
    mov [window], rax

    ; Create renderer
    mov rdi, [window]
    mov rsi, -1
    xor rdx, rdx
    or rdx, SDL_RENDERER_ACCELERATED
    or rdx, SDL_RENDERER_PRESENTVSYNC
    call SDL_CreateRenderer
    cmp rax, 0
    je error_msg
    mov [renderer], rax

    ; Initialize PNG loader
    mov rdi, IMG_INIT_PNG
    call IMG_Init


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

    ; Destroy texture
    mov rdi, [asteroids_texture]
    call SDL_DestroyTexture


    ; Quit SDL_image
    call IMG_Quit
    ; Quit SDL
    call SDL_Quit

    leave
    ret


load_textures:
    enter 16,0

    ; Load asteroid texture
    mov rdi, asteroids_texture_path
    call IMG_Load

    ; check if surface is NULL
    cmp rax, 0
    je error_msg

    mov [rbp - 8], rax ;save surface pointer for cleanup

    mov rdi, [renderer]
    mov rsi, rax
    call SDL_CreateTextureFromSurface
    mov [asteroids_texture], rax

    ; check if converted texture is NULL
    cmp rax, 0
    je error_msg

    ; Free surface
    mov rdi, [rbp - 8]
    call SDL_FreeSurface
    
    leave
    ret

error_msg:
    enter 0,0
    mov rdi, error_text
    call puts
    ;call cleanup
    mov rdi, 1
    call exit
    leave
    ret

