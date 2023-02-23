# asteroids-asm
Asteroids game written in x86 nasm assembly

## Example
![example](examples/asm_example.gif)

## Current state
- Spaceship movement and rendering
- Bullet shooting and rendering (from bullet pool)
- Asteroid rendering and movement
- Asteroids generation
- Asteroid explosion effect

## Future plans
- Collision detection (with ship)
- Maybe some simple ui

## Dependencies
- nasm
- sdl2 + sdl2_image

## Build
```sh
$ ./build.sh
```
- or manually, build with nasm and link math lib, SDL2 and SDL2_image

## Controls
| Key | Action |
| --- | --- |
| W | Move forward |
| A | Rotate left |
| D | Rotate right |
| Space | Shoot |

## Assets
- [asteroids](https://opengameart.org/content/asteroids-pack-2d-diffuse-normal-seamless-animations)
- [spaceship](https://opengameart.org/content/2d-spaceship-sprites-with-engines)
- [bullet](https://opengameart.org/content/bullet-collection-1-m484)
- [explosion](https://opengameart.org/content/2d-explosion-animations-2-frame-by-frame)

## Resources
- https://poli.cs.vsb.cz/edu/apps/soj/down/soj-syllabus.pdf
- https://godbolt.org/

## Note
- Game should run at 60 fps.. or game speed may vary.. (messing with delta time didn't work well :c )
