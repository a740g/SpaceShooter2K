# SPACE SHOOTER 2000

This is a [QB64-PE](https://github.com/QB64-Phoenix-Edition/QB64pe) source port of the Space Shooter 2000 [Visual Basic 6](https://winworldpc.com/product/microsoft-visual-bas/60) game that came with Microsoft's [DirectX 7 SDK](https://github.com/oxiKKK/dx7sdk).

![Screenshot](screenshots/screenshot1.png)
![Screenshot](screenshots/screenshot2.png)
![Screenshot](screenshots/screenshot3.png)
![Screenshot](screenshots/screenshot4.png)

The original [Visual Basic 6](https://winworldpc.com/product/microsoft-visual-bas/60) sources can be found [here](https://github.com/oxiKKK/dx7sdk/tree/main/dx7sdk-700.1/samples/multimedia/vbsamples/dxmisc/src/spaceshooter) and [here](https://github.com/orbitersim/orbiter/tree/main/Extern/mssdk_dx7/samples/Multimedia/VBSamples/DXMisc/src/SpaceShooter).

## FEATURES

- Works natively on Windows, Linux & macOS
- No [DirectX](https://en.wikipedia.org/wiki/DirectX) dependencies
- Uses native [QB64-PE](https://github.com/QB64-Phoenix-Edition/QB64pe) graphics and sound functions
- Runs in 32bpp graphics mode unlike the original code that ran in 8bpp graphics mode
- Color key transparency is done on the BASIC side
- MIDI playback is handled using MIDI support in [QB64-PE](https://github.com/QB64-Phoenix-Edition/QB64pe)
- No sound buffer copy limit unlike the original code
- Alt + Enter puts the game in window mode

## USAGE

- Clone the repository to a directory of your choice
- Open Terminal and change to the directory using an appropriate OS command
- Run `git submodule update --init --recursive` to initialize, fetch and checkout git submodules
- Open *SpaceShooter2k.bas* in the QB64-PE IDE and press `F5` to compile and run

## NOTES

- This requires the latest version of [QB64-PE](https://github.com/QB64-Phoenix-Edition/QB64pe/releases)
- When you clone a repository that contains submodules, the submodules are not automatically cloned by default
- You will need to use the `git submodule update --init --recursive` to initialize, fetch and checkout git submodules
- The source port still has some rough edges and bugs. You can see these under the [TODO](https://github.com/a740g/SpaceShooter2K/blob/master/SpaceShooter2k.bas#L7) section in the source code
- Joystick / game controller support is WIP. I will gradually work through these as and when I get time

## ASSETS

Icon by [Everaldo / Yellowicon](https://iconarchive.com/artist/everaldo.html)

## CREDITS

There is a [YouTube Playthrough](https://www.youtube.com/watch?v=LnUwmS-mYPA) that helped me a lot while doing the source port. Shoutout to [David Coleman](https://www.youtube.com/user/TheFieryDreamer) for posting the video.

## ORIGINAL CREDITS

Main programming, graphics, and MIDI music are by Adam "Gollum" Lonnberg.

Force Feedback implementation and conversion to DirectX 7 by Dominic "DirectX" Riccetti.

The following graphics are by Robert Barry:

- Enemy1.gif
- Enemy2.gif
- Enemy3.gif
- Enemy4.gif
- Ship.gif
- Blocker.gif

All sound effects created by Gordon Duclos.

Many thanks go out to the both of them.
