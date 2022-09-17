bits 64
    global    main
    %define MAX_LEVEL 16

    ; spaceship position is set at center
    %define SPACESHIP_SIZE 80       ;in px
    %define SPACESHIP_RADIUS 20.0 ;used for collision detection
    %define SPACESHIP_SIZE_HALF SPACESHIP_SIZE/2
    %define ROTATION_SPEED 5.0
    %define ACCELERATION_SPEED 0.4
    %define FRICTION 0.98
    
    ; bullet position is set at center
    %define SHOOT_DELAY 200
    %define BULLET_SIZE 48          ;in bytes.. [x,y,dx,dy,time,active] = 41 aligned to 48
    %define BULLET_POOL_SIZE 32     ;max bullets
    %define BULLET_SRC_WH 20        ;width and height of bullet texture
    %define BULLET_WH 16            ;width and height of rendered bullet
    %define BULLET_WH_HALF BULLET_WH/2
    %define BULLET_SPEED 15.0
    %define BULLET_LIFETIME 5000    ;in ms

    ; asteroid position is set at center of asteroid
    %define ASTEROID_SIZE 40 ;in bytes.. [x,y,dy,dy,active(bool),type(uchar/byte)] .. 34 aligned to 40
    %define ASTEROID_POOL_SIZE MAX_LEVEL
    %define ASTEROID_SPEED_MAX  5.0
    %define ASTEROID_SPEED_MIN  1.0
    %define ASTEROID_SRC_WH 75
    %define ASTEROID_WH 128 ;width and height 
    %define ASTEROID_WH_HALF ASTEROID_WH/2
    %define ASTEROID_RADIUS 30.0
    %define ASTEROID_ANIMATION_FPS 20
    %define ASTEROID_FRAME_MS 1000/ASTEROID_ANIMATION_FPS
    %define ASTEROID_ANIMATION_FRAMES 23 ;number of frames in animation

    %define SPACESHIP_PLUS_ASTEROID_RADIUS 50.0
    %define BULLET_PLUS_ASTEROID_RADIUS 40.0    ; see `check_collisions`

    %define DEG2RAD 0.0174532925
    %define WIDTH 1024
    %define HEIGHT 768
    %define CENTER_X 512.0
    %define CENTER_Y 384.0

    %include 'externs.asm'
    %include 'utils.asm'

section .bss
    window: resq 1
    renderer: resq 1
    asteroids_texture: resq 1
    asteroid_pool: resb ASTEROID_POOL_SIZE*ASTEROID_SIZE
    ship_texture: resq 1
    bullet_texture: resq 1
    bullet_pool: resb BULLET_POOL_SIZE*BULLET_SIZE
    last_time_shoot: resq 1


section .data
    title: db "asteroids-asm", 0 
    asteroids_texture_path: db "assets/asteroids.png", 0
    ship_texture_path: db "assets/ship.png", 0
    bullet_texture_path: db "assets/bullet.png", 0
    error_text : db "ERROR", 0
    print_long : db "%ld",10, 0
    print_double: db "%lf",10, 0
    collision_text: db "COLLISION", 0

; RDI, RSI, RDX, RCX, R8, R9
section   .text
main:
    enter 112, 0
    
    call setup_window_and_renderer
    call load_textures

    xor rdi, rdi
    call time
    mov rdi, rax
    call srand

    ;-56    : SDL_PollEvent e
    ;-64    : angle (double)
    ;-72    : x (double)
    ;-80    : y (double)
    ;-88    : dx (double)
    ;-96    : dy (double)
    ;-97    : thrust (bool)
    ;-98    ; shoot (bool)
    ;-104   ; alive asteroids (long)
    ;-112   ; level (long)

    ; setup init values x,y
    mov rax, __float64__(CENTER_X)
    mov qword [rbp-72], rax
    mov rax, __float64__(CENTER_Y)
    mov qword [rbp-80], rax

    ; setup init values dx,dy
    mov rax, __float64__(0.0)
    mov qword [rbp-88], rax
    mov qword [rbp-96], rax

    ; zero init values for bullets, even though it should be zero inicialized
    mov rdi, bullet_pool
    xor rsi, rsi
    mov rdx, BULLET_POOL_SIZE*BULLET_SIZE
    call memset

    ; zero init values for asteroids
    mov rdi, asteroid_pool
    xor rsi, rsi
    mov rdx, ASTEROID_POOL_SIZE*ASTEROID_SIZE
    call memset


    mov qword [rbp-104], 0    ; current alive asteroids
    mov qword [rbp-112], 0    ; current level
    lea rdi, [rbp - 104]
    call spawn_asteroids


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

    ; mov rdi, __float64__(-69.0)
    ; call abs_f
    ; mov rdi, print_double
    ; movq xmm0, rax
    ; mov rax, 1
    ; call printf


    ; spawn new asteroids 
    cmp qword [rbp - 104], 0 ;alive asteroids
    jne .skip_spawn
        lea rdi, [rbp - 104]
        call spawn_asteroids
    .skip_spawn:


    ;update spaceship
    lea rdi, [rbp - 97]
    lea rsi, [rbp - 64]
    call update_spaceship

    ;update asteroids
    call update_asteroids

    ;update bullets
    call update_bullets

    ;check collisions
    lea rdi, [rbp - 72] ; *[x,y]
    lea rsi, [rbp - 104] ; *alive asteroids
    call check_collisions
    
    call render_bg

    ;render bullets
    call render_bullets

    ;call render_animation

    call render_asteroids

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

spawn_random_asteroid:
    enter 16,0
    ; -8 : side
    ; -16 asteroid address


    ; spawn random asteroid at side
    ; side = rand() % 4
    ; if side == 0: x = 0, y = rand() % HEIGHT
    ; if side == 1: x = rand() % WIDTH, y = 0
    ; if side == 2: x = WIDTH, y = rand() % HEIGHT
    ; if side == 3: x = rand() % WIDTH, y = HEIGHT

    call rand
    xor rdx, rdx
    mov rcx, 4
    div rcx
    mov [rbp-8], rdx

    mov rdi, asteroid_pool
    call get_asteroid ; returns rax = asteroid address, or 0 if no free asteroids
    cmp rax, 0
    jne .free_asteroid_found
        call error_msg
    .free_asteroid_found:
    mov [rbp-16], rax
    ; set asteroid on adress [rbp-16] to alive
    mov byte [rax + 33], 1

    ;temp
    jmp .side_0


    cmp qword [rbp-8], 0
    je .side_0
    cmp qword [rbp-8], 1
    je .side_1
    cmp qword [rbp-8], 2
    je .side_2
    cmp qword [rbp-8], 3
    je .side_3
    jmp .side_end

    .side_0:
        ; x = 0, y = rand() % HEIGHT
        mov rdi, __float64__(0.0)
        mov rsi, HEIGHT
        cvtsi2sd xmm0, rsi
        movq rsi, xmm0
        call get_random_double ; returns rax = random double

        mov rdi, [rbp-16]
        mov rcx, __float64__(0.0)
        mov qword [rdi + 8 * 0], rcx
        mov qword [rdi + 8 * 1], rax

        jmp .side_end
    .side_1:
        jmp .side_end
    .side_2:
        jmp .side_end
    .side_3:
        ;jmp .side_end

    .side_end:

    ; set dx,dy to random value between -5 and 5
    mov rdi, __float64__(-5.0)
    mov rsi, __float64__(5.0)
    call get_random_double 
    mov rdi, [rbp-16]
    mov qword [rdi + 8 * 2], rax ; dx

    mov rdi, __float64__(-5.0)
    mov rsi, __float64__(5.0)
    call get_random_double 
    mov rdi, [rbp-16]
    mov qword [rdi + 8 * 3], rax ; dy

    ;set 

    
    leave
    ret

; *[alive_asteroids, level]
spawn_asteroids:
    enter 16,0
    ; -8 : alive_asteroids ptr
    mov [rbp - 8], rdi 

    ; check if max level reached
    mov r8, [rdi - 8] ; level
    cmp r8, MAX_LEVEL
    jb .max_level_not_reached
        ; max level reached
        call error_msg  ;temporaly
    .max_level_not_reached:

    mov r8, [rbp - 8]
    inc qword [r8 - 8] ; level++

    ; randomly spawn [level] asteroids
    .spawn_asteroid_loop:
        call spawn_random_asteroid
        mov r8, [rbp - 8]
        inc qword [r8]
        mov r9 , [r8 - 8] ; level
        cmp [r8], r9 ; while alive_asteroids != level        
    jne .spawn_asteroid_loop

   
    

    ; level print
    mov rdi, print_long
    mov rsi, [r8 - 8]
    xor rax, rax
    call printf

    leave
    ret

; *[x,y,dx,dy] (double), *[asteroids_alive, level]
check_collisions:
    enter 48,0
    ; -8 asteroid counter
    ; -16 spaceship pointer
    ; -24 bullet counter
    ; -32 current asteroid offset
    ; -40 *[asteroids_alive, level] ptr
    
    mov qword [rbp - 8], 0
    mov qword [rbp - 16], rdi
    ;mov qword [rbp - 24], 0
    mov qword [rbp-40], rsi
    ; for each asteroid
    .check:      
        xor rdx, rdx
        mov rax, ASTEROID_SIZE  ; in bytes
        mul qword [rbp - 8]
        mov qword [rbp - 32], rax   ; save offset for bullet loop
        cmp byte [asteroid_pool + rax + 33], 0 ;active offset
        je .skip_check
            ;check collision with spaceship
            ; if distance < ASTEROID_RADIUS + SHIP_RADIUS
            ; distance = sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2))
            ; if (x1-x2)*(x1-x2) + (y1-y2)*(y1-y2) < (ASTEROID_RADIUS + SHIP_RADIUS)*(ASTEROID_RADIUS + SHIP_RADIUS)
            movsd xmm0, [asteroid_pool + rax + 8 * 0] ;x1
            movsd xmm1, [asteroid_pool + rax + 8 * 1] ;y1
            movsd xmm4, xmm0 ; copy x1 for bullet check
            movsd xmm5, xmm1
            mov rdx, [rbp - 16] ; [x,y]
            movsd xmm2, [rdx - 8 * 0] ;x2
            movsd xmm3, [rdx - 8 * 1] ;y2

            subsd xmm0, xmm2 ;x1-x2
            subsd xmm1, xmm3 ;y1-y2
            mulsd xmm0, xmm0 ;(x1-x2)*(x1-x2)
            mulsd xmm1, xmm1 ;(y1-y2)*(y1-y2)
            addsd xmm0, xmm1 ;(x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)

            mov r8, __float64__(SPACESHIP_PLUS_ASTEROID_RADIUS)
            movq xmm1, r8
            mulsd xmm1, xmm1 ;(ASTEROID_RADIUS + SHIP_RADIUS)*(ASTEROID_RADIUS + SHIP_RADIUS)

            comisd xmm0, xmm1
            ja .not_collide_ship
                ;collision detected
                ; mov rdi, collision_text
                ; call puts
            .not_collide_ship:

            ;check collision with bullets
            ; for each bullet
            mov qword [rbp - 24], 0
            .check_bullet:
                xor rdx, rdx
                mov rax, BULLET_SIZE
                mul qword [rbp - 24]
                cmp byte [bullet_pool + rax + 41], 0 ;active offset
                je .skip_bullet
                    ; if distance < ASTEROID_RADIUS + BULLET_RADIUS
                    ; asteroid x1,y1 is already in xmm4, xmm5
                    movq xmm0, xmm4
                    movq xmm1, xmm5
                    movq xmm2, [bullet_pool + rax + 8 * 0] ;x2
                    movq xmm3, [bullet_pool + rax + 8 * 1] ;y2
                    subsd xmm0, xmm2 ;x1-x2
                    subsd xmm1, xmm3 ;y1-y2
                    mulsd xmm0, xmm0 ;(x1-x2)*(x1-x2)
                    mulsd xmm1, xmm1 ;(y1-y2)*(y1-y2)
                    addsd xmm0, xmm1 ;(x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)

                    mov r8, __float64__(BULLET_PLUS_ASTEROID_RADIUS)
                    movq xmm1, r8
                    mulsd xmm1, xmm1 ;(ASTEROID_RADIUS + BULLET_RADIUS)*(ASTEROID_RADIUS + BULLET_RADIUS)

                    ;xmm0 = distance^2
                    ;xmm1 = (ASTEROID_RADIUS + BULLET_RADIUS)^2
                    
                    comisd xmm0, xmm1
                    ja .not_collide_bullet
                        ;collision detected
                        ;deactivate bullet and asteroid
                        mov byte [bullet_pool + rax + 41], 0
                        mov rax, qword [rbp - 32]
                        mov byte [asteroid_pool + rax + 33], 0
                        mov rax, qword [rbp - 40]; [asteroids_alive, level]
                        dec qword [rax] ;asteroids_alive--
                        
                    .not_collide_bullet:
                .skip_bullet:
            
                inc qword [rbp - 24]
                cmp qword [rbp - 24], BULLET_POOL_SIZE
                jne .check_bullet
                
        .skip_check:
        inc qword [rbp - 8]
        cmp qword [rbp - 8], ASTEROID_POOL_SIZE
        jne .check
    leave
    ret

render_asteroids:
    enter 48,0
    ; -16 asteroid rect
    ; -32 dest rect
    ; -40 counter
    ; -48 sprite id
    mov qword [rbp - 40], 0

    ; (time/ms_per_frame)%frames
    call SDL_GetTicks64
    xor rdx, rdx
    mov r8, ASTEROID_FRAME_MS
    div r8

    xor rdx, rdx
    mov r8, ASTEROID_ANIMATION_FRAMES
    div r8
    mov qword [rbp - 48], rdx

    xor rdx, rdx
    mov rax, ASTEROID_SRC_WH
    mul qword [rbp - 48]
    mov qword [rbp - 48], rax    ; -48 == sprite id
    
    .render_asteroid:
        xor rdx, rdx
        mov rax, ASTEROID_SIZE
        mul qword [rbp - 40] ; calc index offset
        mov r9, rax ;addr offset

        cmp byte [asteroid_pool + r9 + 33], 0 ; if active
        je .skip_rendering
        ;render asteroid
        
            ; set asteroid type (y axis in sprites)
            xor rdx, rdx
            xor rax, rax
            mov al, byte[asteroid_pool + r9 + 34] ; type
            mov r8, ASTEROID_SRC_WH
            mul r8
            mov rdx, rax

            ;calc src rect
            lea rdi, [rbp - 16]
            ;xor rsi, rsi 
            mov rsi, qword [rbp - 48]
            ;xor rdx, rdx
            mov rcx, ASTEROID_SRC_WH
            mov r8, ASTEROID_SRC_WH
            call create_rect    ; texture rect

            mov rax, r9 ;move addr offset back

            ;convert x,y to long
            movsd xmm0, [asteroid_pool + rax + 8 * 0]
            movsd xmm1, [asteroid_pool + rax + 8 * 1]

            ;=====================
            ; to render asteroid at center
            mov r8, ASTEROID_WH_HALF
            pxor xmm2, xmm2
            cvtsi2sd xmm2, r8
            subsd xmm0, xmm2
            subsd xmm1, xmm2
            ;=====================


            cvtsd2si rsi, xmm0
            cvtsd2si rdx, xmm1

            lea rdi, [rbp - 32]
            mov rcx, ASTEROID_WH
            mov r8, ASTEROID_WH
            call create_rect    ; dest rect

            ; render asteroid
            mov rdi, [renderer]
            mov rsi, [asteroids_texture]
            lea rdx, [rbp - 16]
            lea rcx, [rbp - 32]
            call SDL_RenderCopy


        .skip_rendering:
        inc qword [rbp - 40]
        cmp qword [rbp - 40], ASTEROID_POOL_SIZE
        jne .render_asteroid 
 

    leave
    ret

update_asteroids:
    enter 16,0
    ; -8  : counter
    ; -16 : asteroid array offset
    mov qword [rbp - 8], 0

    .update:
        xor rdx, rdx
        mov rax, ASTEROID_SIZE
        mul qword [rbp - 8]
        mov [rbp - 16], rax
        cmp byte [asteroid_pool + rax + 33], 0 ;active offset
        je .skip_update
        ;update asteroid
            ;update asteroid position
            movsd xmm0, [asteroid_pool + rax + 8 * 0] ;x
            movsd xmm1, [asteroid_pool + rax + 8 * 1] ;y
            movsd xmm2, [asteroid_pool + rax + 8 * 2] ;dx
            movsd xmm3, [asteroid_pool + rax + 8 * 3] ;dy
            addsd xmm0, xmm2
            addsd xmm1, xmm3
            movsd [asteroid_pool + rax + 8 * 0], xmm0
            movsd [asteroid_pool + rax + 8 * 1], xmm1

            ;d *-1 if out of screen
            mov r8, __float64__(0.0)
            movq xmm4, r8
        
            mov r8, __float64__(ASTEROID_RADIUS)
            movq xmm5, r8
            addsd xmm4, xmm5
            
            mov r8, __float64__(-1.0)
            movq xmm5, r8

            ; if x < 0
            comisd xmm0, xmm4
            ja .x_greater_0
                ; mulsd xmm2, xmm5
                ; movsd [asteroid_pool + rax + 8 * 2], xmm2 ; *-1
                movq rdi, xmm2
                call abs_f                                  ; USES XMM0 and XMM1 registers !!!!
                mov rdi, [rbp - 16]
                mov qword [asteroid_pool + rdi + 8 * 2], rax 
            .x_greater_0:

            mov rax, [rbp - 16]
            ;movsd xmm0, [asteroid_pool + rax + 8 * 0] ;x
            movsd xmm1, [asteroid_pool + rax + 8 * 1] ;y

            ; if y < 0
            comisd xmm1, xmm4
            ja .y_greater_0
                ; mulsd xmm3, xmm5
                ; movsd [asteroid_pool + rax + 8 * 3], xmm3 ; *-1
                movq rdi, xmm3
                call abs_f
                mov rdi, [rbp - 16]
                mov qword [asteroid_pool + rdi + 8 * 3], rax
            .y_greater_0:

            mov rax, [rbp - 16]
            movsd xmm0, [asteroid_pool + rax + 8 * 0] ;x
            ;movsd xmm1, [asteroid_pool + rax + 8 * 1] ;y


            mov r8, WIDTH
            mov r9, HEIGHT
            pxor xmm6, xmm6
            pxor xmm7, xmm7
            cvtsi2sd xmm6, r8
            cvtsi2sd xmm7, r9

            mov r8, __float64__(ASTEROID_RADIUS)
            movq xmm4, r8
            subsd xmm6, xmm4
            subsd xmm7, xmm4

            ; if x > WIDTH
            comisd xmm0, xmm6
            jb .x_less_width
                ; mulsd xmm2, xmm5
                ; movsd [asteroid_pool + rax + 8 * 2], xmm2 ; dx
                movq rdi, xmm2
                call abs_f
                movq xmm2, rax
                mulsd xmm2, xmm5
                mov rdi, [rbp - 16]
                movsd [asteroid_pool + rdi + 8 * 2], xmm2
            .x_less_width:

            mov rax, [rbp - 16]
            ;movsd xmm0, [asteroid_pool + rax + 8 * 0] ;x
            movsd xmm1, [asteroid_pool + rax + 8 * 1] ;y

            ; if y > HEIGHT
            comisd xmm1, xmm7
            jb .y_less_height
                ; mulsd xmm3, xmm5
                ; movsd [asteroid_pool + rax + 8 * 3], xmm3 ; dy
                movq rdi, xmm3
                call abs_f
                movq xmm3, rax
                mulsd xmm3, xmm5
                mov rdi, [rbp - 16]
                movsd [asteroid_pool + rdi + 8 * 3], xmm3
            .y_less_height:

        .skip_update:
        inc qword [rbp - 8]
        cmp qword [rbp - 8], ASTEROID_POOL_SIZE
        jne .update

    leave
    ret     

update_bullets:
    enter 16,0
    ; -8 counter
    ; -16 current time
    mov qword [rbp - 8], 0
    call SDL_GetTicks64
    mov qword [rbp - 16], rax ;current time

    .update:
        xor rdx, rdx
        mov rax, BULLET_SIZE
        mul qword [rbp - 8]
        cmp byte [bullet_pool + rax + 41], 0  ;bullet_pool + bullet_offset + 41 == active ?
        je .skip_update
            ;if active == 1
            ;position += velocity
            movsd xmm0, [bullet_pool + rax + 8*0] ;x
            movsd xmm1, [bullet_pool + rax + 8*1] ;y
            movsd xmm2, [bullet_pool + rax + 8*2] ;dx
            movsd xmm3, [bullet_pool + rax + 8*3] ;dy

            addsd xmm0, xmm2
            subsd xmm1, xmm3
            movsd [bullet_pool + rax + 8*0], xmm0
            movsd [bullet_pool + rax + 8*1], xmm1

            ;check bullet lifetime and deactivate if expired
            mov rdx, [rbp - 16]
            sub rdx, [bullet_pool + rax + 8*4] ;time
            cmp rdx, BULLET_LIFETIME
            jb .should_live
                mov byte [bullet_pool + rax + 41], 0
            .should_live:
        .skip_update:
    inc qword [rbp -8] ; counter++
    cmp qword [rbp - 8], BULLET_POOL_SIZE
    jne .update


    leave
    ret

; *[angle,x,y,dx,dy] (double)
shoot:
    enter 16,0
    ; -8 address of angle
    ; -16 address of bullet
    mov [rbp - 8], rdi

    ;check if SHOOT_DELAY has passed
    call SDL_GetTicks64
    mov rcx, rax
    mov rdx, [last_time_shoot]
    sub rax, rdx
    cmp rax, SHOOT_DELAY
    jle .wait_till_can_shoot
        mov [last_time_shoot], rcx
        mov rdi, bullet_pool
        call get_bullet    ;get bullet addr from pool with active == 0, or null if none available
        mov [rbp - 16], rax ; save bullet addr
        cmp rax, 0
        je .out_of_bullets
            ;shoot
            mov byte [rax+41], 1 ;active = 1

            mov rcx, qword [rbp - 8] ;load angle ptr

            mov rdx, qword [rcx - 8 * 1]     ;deref x
            mov r8, qword [rcx - 8 * 2]      ;deref y     

            movq xmm1, rdx
            movq xmm2, r8
            ; spawn bullet at center of ship

            mov rax, qword [rbp - 16]     ;load bullet addr
            movsd [rax + 8 * 0], xmm1
            movsd [rax + 8 * 1], xmm2

            call SDL_GetTicks64
            mov rdx, [rbp - 16] ;load bullet addr
            mov qword [rdx + 8 * 4], rax ;time

            ;==============================================
            ;calculate dx and dy
            ;dx = cos(angle*DEG2RAD) * BULLET_SPEED
            mov rcx, qword [rbp - 8] ;load angle ptr

            movq xmm0, [rcx - 8 * 0]     ;deref angle     
            mov r8, __float64__(DEG2RAD) ;DEG2RAD
            movq xmm1, r8
            mulsd xmm0, xmm1          ;angle * DEG2RAD
            
            call sin

            mov r8, __float64__(BULLET_SPEED)
            movq xmm1, r8
            mulsd xmm0, xmm1
            mov rax, [rbp - 16]
            movq [rax + 8 * 2], xmm0 ;dx

            ; ;dy = sin(angle*DEG2RAD) * BULLET_SPEED
            mov rcx, qword [rbp - 8]
            movq xmm0, [rcx - 8 * 0]     ;deref angle
            mov r8, __float64__(DEG2RAD) ;DEG2RAD
            movq xmm1, r8
            mulsd xmm0, xmm1          ;angle * DEG2RAD

            call cos

            mov r8, __float64__(BULLET_SPEED)
            movq xmm1, r8
            mulsd xmm0, xmm1
            mov rax, [rbp - 16]
            movq [rax + 8 * 3], xmm0 ;dy


            ;==============================================

        .out_of_bullets:
        ; do nothing
        ; mov rdi, print_long
        ; mov rsi, [rbp - 16]
        ; xor rax, rax
        ; call printf
    .wait_till_can_shoot:

    leave
    ret

render_bullets:
    enter 48,0
    ; -16 bullet rect
    ; -32 dest rect
    ; -40 counter

    mov qword [rbp - 40], 0

    .render_bullet:
        mov rax, BULLET_SIZE
        xor rdx, rdx
        mul qword [rbp - 40]  ; addr offset of bullet in rax
        cmp byte [bullet_pool + rax + 41], 0 ; active == 0 ? (41 is offset of active bool)
        je .skip_rendering ; skip bullet rendering if not active

        lea rdi, [rbp - 16]
        xor rsi, rsi
        xor rdx, rdx
        mov rcx, BULLET_SRC_WH
        mov r8, BULLET_SRC_WH
        call create_rect       ;create texture pos rect

        ;convert x,y to long
        movsd xmm0, [bullet_pool + rax + 8 * 0] ;x
        movsd xmm1, [bullet_pool + rax + 8 * 1] ;y
        
        ;===================================================
        ; to render bullet at center

        mov r9, BULLET_WH_HALF
        pxor xmm2, xmm2
        cvtsi2sd xmm2, r9 ;xmm2 = BULLET_WH_HALF
        subsd xmm0, xmm2 ;xmm0 = x - BULLET_WH_HALF
        subsd xmm1, xmm2 ;xmm1 = y - BULLET_WH_HALF

        ;===================================================
        cvtsd2si rsi, xmm0
        cvtsd2si rdx, xmm1

        lea rdi, [rbp - 32]
        mov rcx, BULLET_WH
        mov r8, BULLET_WH
        call create_rect       ;create dest rect

        mov rdi, [renderer]
        mov rsi, [bullet_texture]
        lea rdx, [rbp - 16]
        lea rcx, [rbp - 32]
        call SDL_RenderCopy

        .skip_rendering:
        inc qword [rbp - 40]
        cmp qword [rbp - 40], BULLET_POOL_SIZE
        
    jne .render_bullet


    leave
    ret

;*[thrust, shoot], *[angle, x, y, dx, dy] (double)
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
    mov cl, byte [rax + SDL_SCANCODE_SPACE]
    ; mov r8, [rbp - 16]
    ; mov byte [r8 - 1], cl ; &thrust+1 = &shoot
    cmp cl, 1
    jne .skip_shoot
        mov rdi, [rbp - 24]
        call shoot
    .skip_shoot:

    mov rax, [rbp - 8] ;return keystates ptr back to rax
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

    movsd xmm0, [rdi - 8 * 0] ; x
    movsd xmm1, [rdi - 8 * 1] ; y


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


    movsd [rdi - 8 * 0], xmm0
    movsd [rdi - 8 * 1], xmm1

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

    mov rax, SPACESHIP_SIZE_HALF
    pxor xmm1, xmm1
    cvtsi2sd xmm1, rax

    ; convert x to int
    movq xmm0, [rdi - 8 * 1] ;x
    subsd xmm0, xmm1 ; to render from center
    cvtsd2si eax, xmm0
    mov dword [rbp - 60], eax

    ; convert y to int
    movsd xmm0, [rdi - 8 * 2] ;y
    subsd xmm0, xmm1 ; to render from center
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

    ; Destory spaceship texture
    mov rdi, [ship_texture]
    call SDL_DestroyTexture

    ; Destroy bullet texture
    mov rdi, [bullet_texture]
    call SDL_DestroyTexture

    ; Quit SDL_image
    call IMG_Quit
    ; Quit SDL
    call SDL_Quit

    leave
    ret


load_textures:
    enter 16,0

    ;------------------------------------------------------------
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


    ;------------------------------------------------------------
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

    
    ;------------------------------------------------------------
    ; Load bullet texture
    mov rdi, bullet_texture_path
    call IMG_Load
    cmp rax, 0
    je error_msg

    mov [rbp - 8], rax ;save surface pointer for cleanup
    mov rdi, [renderer]
    mov rsi, rax
    call SDL_CreateTextureFromSurface
    mov [bullet_texture], rax

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

