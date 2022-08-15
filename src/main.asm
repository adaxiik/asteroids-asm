bits 64
    global    main
    %include 'externs.asm'
    %include 'utils.asm'
    

section .bss
    window: resq 1
    renderer: resq 1
    asteroids_texture: resq 1
    ship_texture: resq 1

section .data
    title: db "asteroids-asm", 0 
    asteroids_texture_path: db "assets/asteroids.png", 0
    ship_texture_path: db "assets/ship.png", 0
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

    call SDL_RenderClear
    
    call render_bg

    ;call render_animation

    mov rdi, 20 ;x
    mov rsi, 20 ;y
    mov rdx , __float64__(45.0) ;rotation
    mov rcx, 1 ;thrust
    call render_spaceship


    ;render frame
    ;SDL_RenderPresent(renderer)
    mov rdi, [renderer]
    call SDL_RenderPresent

    jmp .main_loop ; jump to main loop

    .quit:
    call cleanup
    
    mov rax, 0
    leave
    ret          

; x, y, angle, thrust
render_spaceship:
    enter 80, 0
    ; -16 spaceship rect
    ; -32 thrust rect
    ; -48 dest rect
    ; -52 x;     (int)
    ; -56 y;     (int)
    ; -64 angle  (double)
    ; -65 thrust (bool)

    mov [rbp - 52], edi
    mov [rbp - 56], esi
    mov [rbp - 64], rdx
    mov [rbp - 65], ecx

    lea rdi, [rbp - 16]
    xor rsi, rsi
    xor rdx, rdx
    mov rcx, 256
    mov r8, 256
    call create_rect ;spaceship rect = {0, 0, 256, 256}

    lea rdi, [rbp - 32]
    mov rsi, 256
    xor rdx, rdx
    mov rcx, 256
    mov r8, 256
    call create_rect ;thrust rect = {256, 0, 256, 256}

    lea rdi, [rbp - 48]
    mov rsi, [rbp - 52]
    mov rdx, [rbp - 56]
    mov rcx, SPACESHIP_SIZE
    mov r8, SPACESHIP_SIZE
    call create_rect ;dest rect = {x, y, SPACESHIP_SIZE, SPACESHIP_SIZE}

    
    mov rdi, qword [renderer]
    mov rsi, qword [ship_texture]
    lea rdx, [rbp - 16]
    lea rcx, [rbp - 48]
    ;mov r8d, dword[rbp - 64]  ;angle
    movq xmm0, [rbp - 64] ;angle
    xor r8, r8          ; center - if null rotation will be done around dstrect.w / 2, dstrect.h / 2 https://wiki.libsdl.org/SDL_RenderCopyEx
    xor r9, r9
    call SDL_RenderCopyEx ;render spaceship


    cmp byte [rbp - 65], 0
    je .skip_thrust
    mov rdi, [renderer]
    mov rsi, [ship_texture]
    lea rdx, [rbp - 32]
    lea rcx, [rbp - 48]
    movq xmm0, [rbp - 64] ;angle
    xor r8, r8          ; center - if null rotation will be done around dstrect.w / 2, dstrect.h / 2 https://wiki.libsdl.org/SDL_RenderCopyEx
    xor r9, r9
    call SDL_RenderCopyEx ;render thrust
    .skip_thrust:

    leave 
    ret

render_animation:
    enter 48,0
    ;-16 src_rect
    ;-32 dst_rect
    ;-36 sprite id

    
    ; (time/ms_per_frame)%frames
    call SDL_GetTicks ; get current time in ms
    xor rdx, rdx
    mov r8, 40        ; ms per frame
    div r8

    xor rdx, rdx
    mov r8, 23
    div r8
    mov [rbp - 36], rdx ; time%frames (frames = 23)


    ;rcx = sprite_id * 75
    mov r8, 75
    xor rdx, rdx
    mov rax, [rbp - 36]
    mul r8
    mov rsi, rax

    lea rdi, [rbp - 16]
    ;mov rsi, 0
    mov rdx, 75
    mov rcx, 75
    mov r8, 75
    call create_rect

    lea rdi, [rbp - 32]
    xor rsi, rsi
    xor rdx, rdx
    mov rcx, 400
    mov r8, 400
    call create_rect

    ; render sprite
    mov rdi, [renderer]
    mov rsi, [asteroids_texture]
    lea rdx, [rbp - 16]
    lea rcx, [rbp - 32]
    call SDL_RenderCopy
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
    mov rcx, 1024
    mov r8, 768
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

    ; Load ship texture
    mov rdi, ship_texture_path
    call IMG_Load
    cmp rax, 0
    je error_msg

    mov [rbp - 8], rax ;save surface pointer for cleanup
    mov rdi, [renderer]
    mov rsi, rax
    call SDL_CreateTextureFromSurface
    mov [ship_texture], rax

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

