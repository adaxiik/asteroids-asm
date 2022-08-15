    extern puts
    extern exit

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

    %define SDL_INIT_VIDEO 32
    %define SDL_WINDOWPOS_CENTERED 805240832
    %define SDL_WINDOW_SHOWN 4
    %define SDL_RENDERER_PRESENTVSYNC 4
    %define SDL_RENDERER_ACCELERATED 2
    %define SDL_QUIT 256
    %define IMG_INIT_PNG 2
    %define SPACESHIP_SIZE 128
    
    extern IMG_Init
    extern IMG_Load
    extern IMG_Quit