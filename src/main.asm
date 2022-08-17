bits 64
    global    main
    %include 'externs.asm'
    %include 'utils.asm'
    %define SPACESHIP_SIZE 80
    %define SPACESHIP_RADIUS 20.0 ;used for collision detection
    %define SPACESHIP_SIZE_HALF SPACESHIP_SIZE/2
    %define ROTATION_SPEED 4.0
    %define ACCELERATION_SPEED 0.4
    %define FRICTION 0.98
    %define MAX_SPEED 1.0

    %define DEG2RAD 0.0174532925
    %define WIDTH 1024
    %define HEIGHT 768
    %define CENTER_X 512.0
    %define CENTER_Y 384.0
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

; RDI, RSI, RDX, RCX, R8, R9
section   .text
main:
    enter 112, 0
    
    call setup_window_and_renderer
    call load_textures

    ;-56 : SDL_PollEvent e
    ;-64 : angle (double)
    ;-72 : x (double)
    ;-80 : y (double)
    ;-88 : dx (double)
    ;-96 : dy (double)
    ;-97 : thrust (bool)
    ;-98 ; shoot (bool)

    mov rax, __float64__(512.0)
    mov qword [rbp-72], rax
    mov rax, __float64__(384.0)
    mov qword [rbp-80], rax

    mov rax, __float64__(0.0)
    mov qword [rbp-88], rax
    mov qword [rbp-96], rax


    ; Main loop
    .main_loop:

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
        je .quit

    jmp .event_loop
    .event_loop_end:


    call SDL_RenderClear
    
    call render_bg

    call render_animation

    ;update spaceship
    lea rdi, [rbp - 97]
    lea rsi, [rbp - 64]
    call update_spaceship

    ;render spaceship

    lea rdi, [rbp - 64] ; *[angle,x,y]
    mov rsi, [rbp - 97] ; thrust
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

;*thrust (bool) [thrust, shoot], *angle (double) [angle, x, y, dx, dy]
update_spaceship:
    enter 32,0
    ; -8 keystates
    ; -16 address of trust bool
    ; -24 address of angle

    mov [rbp - 16], rdi
    mov [rbp - 24], rsi


    xor rdi, rdi
    call SDL_GetKeyboardState
    mov [rbp - 8], rax

    ;-----------------------------------

    ; thurst ?
    movsx rcx, byte[rax + SDL_SCANCODE_W]
    mov r8, [rbp - 16]
    mov [r8], cl

    ; Update dx and dy
    cmp rcx, 1
    jne .dont_thrust

    ;dx += sin(angle*DEG2RAD) * ACCELERATION_SPEED
    ;cos(angle*DEG2RAD)
    mov r9, [rbp - 24]
    movsd xmm0, [r9]
    mov r9, __float64__(DEG2RAD)
    movq xmm1, r9
    mulsd xmm0, xmm1
    call sin ;return in xmm0

    ; *ACCELERATION_SPEED
    mov r9, __float64__(ACCELERATION_SPEED)
    movq xmm1, r9
    mulsd xmm0, xmm1
    ; dx+ = xmm0
    mov r9, [rbp - 24]
    movsd xmm1, [r9 - 8*3] ; dx
    addsd xmm0, xmm1
    movsd [r9 - 8*3], xmm0


    ;dy += cos(angle*DEG2RAD) * ACCELERATION_SPEED
    mov r9, [rbp - 24]
    movsd xmm0, [r9]
    mov r9, __float64__(DEG2RAD)
    movq xmm1, r9
    mulsd xmm0, xmm1 ;angle*DEG2RAD
    call cos ;return in xmm0

    ; *ACCELERATION_SPEED
    mov r9, __float64__(ACCELERATION_SPEED)
    movq xmm1, r9
    mulsd xmm0, xmm1
    ; dy+ = xmm0
    mov r9, [rbp - 24]
    movsd xmm1, [r9 - 8*4] ; dy
    addsd xmm0, xmm1
    movsd [r9 - 8*4], xmm0

    .dont_thrust:

    ; dxy*=FRICTION
    mov r9, [rbp - 24]
    movsd xmm0, [r9 - 8*3] ; dx
    movsd xmm1, [r9 - 8*4] ; dy
    mov r8, __float64__(FRICTION)
    movq xmm2, r8
    mulsd xmm0, xmm2
    mulsd xmm1, xmm2
    movsd [r9 - 8*3], xmm0
    movsd [r9 - 8*4], xmm1


    ; x += dx
    mov r9, [rbp - 24]
    movsd xmm0, [r9 - 8*1] ; x
    movsd xmm1, [r9 - 8*3] ; dx
    addsd xmm0, xmm1
    movsd [r9 - 8*1], xmm0

    ; y += dy
    mov r9, [rbp - 24]
    movsd xmm0, [r9 - 8*2] ; y
    movsd xmm1, [r9 - 8*4] ; dy
    subsd xmm0, xmm1
    movsd [r9 - 8*2], xmm0

    ; check borders
    mov rdi, [rbp - 24]
    add rdi, -8*1 ;x
    call check_borders
    
    mov rax, [rbp - 8] ;return keystates ptr back to rax
    
    ;shoot ?
    ; movsx r9, byte [rax + SDL_SCANCODE_SPACE]
    ; mov r8, [rbp - 16]
    ; mov [r8 + 1], r9 ; &thrust+1 = &shoot

    ;angle+ (right)
    movsx r9, byte[rax + SDL_SCANCODE_D]          ;bool
    cmp r9, 1
    jne .dont_rotate_right

    mov rdx, __float64__(ROTATION_SPEED)    ; load rotate speed
    movq xmm1, rdx 

    mov r8, [rbp - 24]              ; ptr to angle
    movsd xmm0, [r8]                 ; load angle
    
    addsd xmm0, xmm1    ; add rotate speed to angle
    movsd [r8], xmm0     ; store angle back

    .dont_rotate_right:

    ;angle- (left)
    movsx r9, byte [rax + SDL_SCANCODE_A]          ;bool
    cmp r9, 1
    jne .dont_rotate_left

    mov rdx, __float64__(ROTATION_SPEED)    ; load rotate speed
    movq xmm1, rdx

    mov r8, [rbp - 24]              ; ptr to angle
    movsd xmm0, [r8]                 ; load angle

    subsd xmm0, xmm1    ; sub rotate speed to angle
    movsd [r8], xmm0     ; store angle back
    .dont_rotate_left:

    leave
    ret

;*x (double) [x, y, dx, dy]
check_borders:
    enter 16,0
    mov [rbp - 8], rdi

    movsd xmm0, [rdi] ; x
    movsd xmm1, [rdi - 8*1] ; y
    mov r8, 40
    pxor xmm2, xmm2
    cvtsi2sd xmm2, r8 ; half size

    addsd xmm0, xmm2 ; center x
    addsd xmm1, xmm2 ; center y


    mov r8, __float64__(0.0)
    movq xmm3, r8
    mov r8, __float64__(SPACESHIP_RADIUS)
    movq xmm4, r8
    addsd xmm3, xmm4 ; bound + spaceship radius

    comisd xmm0, xmm3 ; 
    ;if x < 0.0, x = 0.0
    ja .x_greater_0
    movsd xmm0, xmm3
    mov qword [rdi - 8 * 2], __float64__(0.0) ; dx = 0.0
    .x_greater_0:

    comisd xmm1, xmm3 ;
    ;if y < 0.0, y = 0.0
    ja .y_greater_0
    movsd xmm1, xmm3
    mov qword [rdi - 8 * 3], __float64__(0.0) ; dy = 0.0
    .y_greater_0:

    mov r8, WIDTH
    mov r9, HEIGHT
    pxor xmm3, xmm3
    pxor xmm4, xmm4
    cvtsi2sd xmm3, r8 ; width
    cvtsi2sd xmm4, r9 ; height
    mov r8, __float64__(SPACESHIP_RADIUS)
    movq xmm5, r8

    subsd xmm3, xmm5 ; width - spaceship radius
    subsd xmm4, xmm5 ; height - spaceship radius
    
    comisd xmm0, xmm3
    ;if x > width, x = width
    jb .x_less_width
    movsd xmm0, xmm3
    mov qword [rdi - 8 * 2], __float64__(0.0) ; dx = 0
    .x_less_width:

    comisd xmm1, xmm4
    ;if y > height, y = height
    jb .y_less_height
    movsd xmm1, xmm4
    mov qword [rdi - 8 * 3], __float64__(0.0) ; dy = 0
    .y_less_height:

    ; offset center back
    subsd xmm0, xmm2
    subsd xmm1, xmm2
    movsd [rdi], xmm0
    movsd [rdi - 8*1], xmm1

    leave 
    ret

; *[angle, x, y](doubles), thrust(bool)
render_spaceship:
    enter 80, 0
    ; -16 spaceship rect
    ; -32 thrust rect
    ; -48 dest rect
    ; -56 *[angle, x, y](doubles)
    ; -60 x int
    ; -64 y int
    ; -65 thrust (bool)

    ;save params
    mov qword  [rbp - 56], rdi
    mov byte [rbp - 65], sil

    ; convert x to int
    movq xmm0, [rdi - 8 * 1] ;x
    cvtsd2si eax, xmm0
    mov dword [rbp - 60], eax

    ; convert y to int
    movsd xmm0, [rdi - 8 * 2] ;y
    cvtsd2si eax, xmm0
    mov dword [rbp - 64], eax




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
    mov rsi, [rbp - 60]
    mov rdx, [rbp - 64]
    mov rcx, SPACESHIP_SIZE
    mov r8, SPACESHIP_SIZE
    call create_rect ;dest rect = {x, y, SPACESHIP_SIZE, SPACESHIP_SIZE}

    
    mov rdi, qword [renderer]
    mov rsi, qword [ship_texture]
    lea rdx, [rbp - 16]
    lea rcx, [rbp - 48]
    ;mov r8d, dword[rbp - 64]  ;angle
    mov r8, [rbp - 56]  ;deref angle
    movq xmm0, [r8] ;angle
    xor r8, r8          ; center - if null rotation will be done around dstrect.w / 2, dstrect.h / 2 https://wiki.libsdl.org/SDL_RenderCopyEx
    xor r9, r9
    call SDL_RenderCopyEx ;render spaceship


    cmp byte [rbp - 65], 1
    jne .skip_thrust
    mov rdi, [renderer]
    mov rsi, [ship_texture]
    lea rdx, [rbp - 32]
    lea rcx, [rbp - 48]
    mov r8, [rbp - 56]  ;deref angle
    movq xmm0, [r8] ;angle
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
    mov rsi, 300
    mov rdx, 300
    mov rcx, 100
    mov r8, 100
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

