    extern puts
    extern exit
    extern memset
    extern printf
    extern rand
    extern srand
    extern time

    extern cos
    extern sin

    extern SDL_Init
    extern SDL_Quit
    extern SDL_CreateWindow
    extern SDL_CreateRenderer
    extern SDL_DestroyWindow
    extern SDL_DestroyRenderer
    extern SDL_RenderClear
    extern SDL_RenderPresent
    extern SDL_RenderCopy
    extern SDL_RenderCopyEx
    extern SDL_SetRenderDrawColor
    extern SDL_PollEvent
    extern SDL_FreeSurface
    extern SDL_CreateTextureFromSurface
    extern SDL_DestroyTexture
    extern SDL_GetTicks
    extern SDL_GetKeyboardState

    %define SDL_INIT_VIDEO 32
    %define SDL_WINDOWPOS_CENTERED 805240832
    %define SDL_WINDOW_SHOWN 4
    %define SDL_RENDERER_PRESENTVSYNC 4
    %define SDL_RENDERER_ACCELERATED 2
    %define SDL_QUIT 256
    %define IMG_INIT_PNG 2


    %define SDL_SCANCODE_A 4
    %define SDL_SCANCODE_B 5
    %define SDL_SCANCODE_C 6
    %define SDL_SCANCODE_D 7
    %define SDL_SCANCODE_E 8
    %define SDL_SCANCODE_F 9
    %define SDL_SCANCODE_G 10
    %define SDL_SCANCODE_H 11
    %define SDL_SCANCODE_I 12
    %define SDL_SCANCODE_J 13
    %define SDL_SCANCODE_K 14
    %define SDL_SCANCODE_L 15
    %define SDL_SCANCODE_M 16
    %define SDL_SCANCODE_N 17
    %define SDL_SCANCODE_O 18
    %define SDL_SCANCODE_P 19
    %define SDL_SCANCODE_Q 20
    %define SDL_SCANCODE_R 21
    %define SDL_SCANCODE_S 22
    %define SDL_SCANCODE_T 23
    %define SDL_SCANCODE_U 24
    %define SDL_SCANCODE_V 25
    %define SDL_SCANCODE_W 26
    %define SDL_SCANCODE_X 27
    %define SDL_SCANCODE_Y 28
    %define SDL_SCANCODE_Z 29
    %define SDL_SCANCODE_SPACE 44
    
    extern IMG_Init
    extern IMG_Load
    extern IMG_Quit