# Space Shooter 2000

![Screenshot](screenshot.png)

This is a [QB64-PE](https://github.com/QB64-Phoenix-Edition/QB64pe) source port of the Space Shooter 2000 [Visual Basic 6](https://winworldpc.com/product/microsoft-visual-bas/60) game that came with Microsoft's [DirectX 7 SDK](https://github.com/oxiKKK/dx7sdk/tree/main/dx7sdk-700.1/samples/multimedia/vbsamples/dxmisc/src/spaceshooter).

The original [Visual Basic 6](https://winworldpc.com/product/microsoft-visual-bas/60) sources can be found [here](https://github.com/oxiKKK/dx7sdk/tree/main/dx7sdk-700.1/samples/multimedia/vbsamples/dxmisc/src/spaceshooter) and [here](https://github.com/orbitersim/orbiter/tree/main/Extern/mssdk_dx7/samples/Multimedia/VBSamples/DXMisc/src/SpaceShooter).

This conversion has multiple changes and improvements over the Visual Basic 6 version. These are:

- Works on Windows, Linux & macOS
- There is no DirectX 7 dependency
- The game now uses native [QB64-PE](https://github.com/QB64-Phoenix-Edition/QB64pe) graphics and sound functions
- The game now runs in 32bpp graphics mode
- Color key transparency is done on the BASIC side
- MIDI playback is handled using MIDI support in [QB64-PE v3.2.0+](https://github.com/QB64-Phoenix-Edition/QB64pe/releases)
- Alt+Enter puts the game in window mode
- Joystick / game controller support is WIP

The source port still has some rough edges and bugs. You can see these under the "TODO" section in the source code. I will gradually work through these as and when I get time.

Icon by [Everaldo / Yellowicon](https://iconarchive.com/artist/everaldo.html)

There is a [YouTube Playthrough](https://www.youtube.com/watch?v=LnUwmS-mYPA) that helped me a lot while doing the source port. Shoutout to [David Coleman](https://www.youtube.com/user/TheFieryDreamer) for posting the video.

## Original Credits

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
