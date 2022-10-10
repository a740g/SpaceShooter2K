'---------------------------------------------------------------------------------------------------------
' SPACE SHOOTER 2000!
' Copyright (c) 2022 Samuel Gomes
' Copyright (c) 2000 Adam "Gollum" Lonnberg
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' TODOs
'---------------------------------------------------------------------------------------------------------
'   Check any comment labeled with 'TODO'
'   Change all 'Tick' & 'Time' variables to Integer64
'   Remove GetTicks() dependency ?
'   Check all Byte variables to see if we need to make those unsigned (VBA 'Byte' is always unsigned)
'   Add 'Asserts' after file loads
'   Map and check all instances of 'ddsBack.BltFast' from the original code
'   Check all 'PutImage' calls
'   Fix spritesheet rendering bug - random white lines on bottom and right - probably copying extra pixels from right and bottom
'   Remove usage of Rectangle2D types whereever not really required
'   Attempt using hardware images (33)
'   Guard all FreeImage calls to avoid error events
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' METACOMMANDS
'---------------------------------------------------------------------------------------------------------
$NoPrefix
DefLng A-Z
Option Explicit
Option ExplicitArray
'$Static
Option Base 1
$Asserts
$Color:32
$Resize:Smooth
$Unstable:Midi
$MidiSoundFont:Default
$ExeIcon:'./SpaceShooter2k.ico'
$VersionInfo:ProductName='Space Shooter 2000'
$VersionInfo:CompanyName='Samuel Gomes'
$VersionInfo:LegalCopyright='Conversion / port copyright (c) 2022 Samuel Gomes'
$VersionInfo:LegalTrademarks='All trademarks are property of their respective owners'
$VersionInfo:Web='https://github.com/a740g'
$VersionInfo:Comments='https://github.com/a740g'
$VersionInfo:InternalName='SpaceShooter2k'
$VersionInfo:OriginalFilename='SpaceShooter2k.exe'
$VersionInfo:FileDescription='Space Shooter 2000 executable'
$VersionInfo:FILEVERSION#=2,0,1,0
$VersionInfo:PRODUCTVERSION#=2,0,0,0
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' CONSTANTS
'---------------------------------------------------------------------------------------------------------
Const FALSE = 0, TRUE = Not FALSE
Const NULL = 0
Const NULLSTRING = ""

' Game constants
Const APP_NAME = "Space Shooter 2000"

' Keyboard key codes
Const DIK_UP = 18432
Const DIK_DOWN = 20480
Const DIK_LEFT = 19200
Const DIK_RIGHT = 19712
Const DIK_SPACE = 32
Const DIK_RCONTROL = 100305
Const DIK_LCONTROL = 100306
Const DIK_BACK = 8
Const DIK_RETURN = 13
Const DIK_ESCAPE = 27

Const SCREEN_WIDTH = 640 'Width for the display mode
Const SCREEN_HEIGHT = 480 'Height for the display mode
Const TRANSPARENT_COLOR_RED = 208
Const TRANSPARENT_COLOR_GREEN = 2
Const TRANSPARENT_COLOR_BLUE = 178
Const JOYSTICKCENTERED = 32768 'Center value of the joystick

Const SHIELD = &H0 'Constant for the shield powerup
Const WEAPON = &H20 'Constant for the weapon powerup
Const BOMB = &H40 'Constant for the bomb powerup
Const INVULNERABILITY = &H60 'Constant for the invulenrability powerup

Const SHIPWIDTH = 35 'Width of the players ship
Const SHIPHEIGHT = 60 'Height of the players ship
Const LASERSPEED = 9.5 'Speed of the laser fire
Const LASER1WIDTH = 4 'Width of the stage 1 laser fire
Const LASER1HEIGHT = 8 'Height of the stage 1 laser fire
Const LASER2WIDTH = 8 'Width of the stage 2 laser fire
Const LASER2HEIGHT = 8 'Height of the stage 2 laser fire
Const LASER3HEIGHT = 5 'Height of the stage 3 laser fire
Const LASER3WIDTH = 17 'Width of the stage 3 laser fire
Const NUMOBSTACLES = 150 'The maximum number of second-layer objects that can appear
Const POWERUPHEIGHT = 17 'Height of the powerups
Const POWERUPWIDTH = 16 'Width of the powerups
Const NUMENEMIES = 100 'How many enemies can appear on the screen at one time
Const XMAXVELOCITY = 3 'Maximum X velocity of the ship
Const YMAXVELOCITY = 3 'Maximum Y velocity of the ship
Const DISPLACEMENT = 0.7 'Rate at which the velocity changes
Const FRICTION = 0.18 'The amount of friction applied in the universe
Const MAXMISSILEVELOCITY = 3.1 'The maximum rate a missile can go
Const MISSILEDIMENSIONS = 4 'The width and height of the missile
Const TARGETEDFIRE = 1 'The object aims at the player
Const NONTARGETEDFIRE = 0 'The object just shoots straight
Const CHASEOFF = 0 'The object doesn't follow the players' X coordinates
Const CHASESLOW = 1 'The object does follow the players' X coordinates, but slowly
Const CHASEFAST = 2 'The object does follow the players' X coordinates, but fast
Const EXTRALIFETARGET = 250000 'If the player exceeds this value he gets an extra life

' High score stuff
Const HIGH_SCORE_FILENAME = "highscore.csv" ' High score file
Const NUM_HIGH_SCORES = 10 ' Number of high scores
Const HIGH_SCORE_TEXT_LEN = 20 ' The max length of the name in a high score
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' USER DEFINED TYPES
'---------------------------------------------------------------------------------------------------------
Type Rectangle2D
    left As Long
    top As Long
    right As Long
    bottom As Long
End Type

Type typeWeaponDesc 'UDT to define the weapon object
    X As Single 'X position of the weapon
    Y As Single 'Y position of the weapon
    XVelocity As Single 'The X velocity of the weapon
    YVelocity As Single 'The Y velocity of the weapon
    Damage As Unsigned Byte 'How many points of damage this weapon does
    StillColliding As Byte 'Flag that is set when the weapon has entered a target, and is still within it
    W As Long 'Width of the weapon beam in pixels
    H As Long 'Height of the weapon beam in pixels
    Exists As Byte 'Set to true if the weapon exists on screen
    TargetIndex As Unsigned Byte 'For guided weapons, sets the enemy target index
    TargetSet As Byte 'Flag that is set once a target has been selected for the guided weapon
End Type

Type typeBackGroundDesc 'UDT to define any small background objects (stars, enemies, other objects)
    FileName As String 'Name of the file
    X As Single 'X position of the B.G. object
    Y As Single 'Y position of the B.G. object
    XVelocity As Single 'X velocity of the enemy ship
    Speed As Single 'The speed the object scrolls
    ChaseValue As Unsigned Byte 'Flag that is set to CHASEOFF, CHASESLOW, or CHASEFAST. If the flag isn't CHASEOFF, then it sets whether or not the enemy "follows" the players movement, and if the chase rate is fast or slow
    Exists As Byte 'Determines if the object exists
    HasDeadIndex As Byte 'Toggles whether or not this object has a bitmap that will be displayed when it is destroyed
    DeadIndex As Long 'Index of picture to display when this object has been destroyed
    ExplosionIndex As Unsigned Byte 'The index of which explosion gets played back when this enemy is destroyed
    TimesHit As Unsigned Byte 'Number of times this enemy has been hit
    TimesDies As Unsigned Byte 'Max number of hits when enemy dies
    CollisionDamage As Unsigned Byte 'If the player collides with this enemy, the amount of damage it does
    Score As Long 'The score added to the player when this is destroyed
    Index As Unsigned Byte 'Index of the container for this bitmap -or- How many frames the bitmap has existed
    Frame As Unsigned Byte 'The current frame number
    NumFrames As Unsigned Byte 'The number of frames the bitmap contains/How many frames the bitmap should exist
    FrameDelay As Unsigned Byte 'Used to delay the incrementing of frames to slow down frame animation, if needed
    FrameDelayCount As Unsigned Byte 'Used to store the current frame delay number count
    W As Long 'the width of one frame
    H As Long 'the height of one frame
    DoesFire As Byte 'Does this object fire a weapon?
    FireType As Unsigned Byte 'The style of fire the object uses (targeted or non-targeted)
    HasFired As Byte 'Has this enemy fired its' weapon
    Invulnerable As Byte 'Can this object be hit with weapon fire?
    XFire As Single 'X position of the weapon fire
    YFire As Single 'Y position of the weapon fire
    FireFrame As Unsigned Byte 'Frame of the weapon fire
    FireFrameCount As Unsigned Byte 'Used to indicate when it is time to change the animation frame of the enemy fire
    TargetX As Single 'X vector of the weapon fire direction
    TargetY As Single 'Y vector of the weapon fire direction
    Solid As Byte 'Toggles whether this item needs to be blitted transparent or not
End Type

Type typeShipDesc 'UDT to define the players' ship bitmap
    PowerUpState As Unsigned Byte 'Determines how many levels of power-ups the player has
    Invulnerable As Byte 'Determines whether or not the player is invulnerable
    InvulnerableTime As Long 'Used to keep track of the amount of time the player has left when invulnerable
    X As Single 'X of the ship
    Y As Single 'Y of the ship
    XOffset As Long 'X Offset of the animation frame
    YOffset As Long 'Y Offset of the animation frame
    XVelocity As Single 'X velocity of the ship
    YVelocity As Single 'Y velocity of the ship
    NumBombs As Long 'the number of super bombs the player has
    AlarmActive As Byte 'Determines if the alarm sound is being played so it can be turned off temporarily when the game is paused
    FiringMissile As Byte 'Toggles whether the ship is currently firing a missile
End Type

Type typeBackgroundObject 'UDT to define background pictures
    X As Single 'X position of the object
    Y As Single 'Y position of the object
    W As Long 'Width of the B.G. object
    H As Long 'Height of the B.G. object
    PathName As String 'Path to the bitmap of the background object
End Type
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' EXTERNAL LIBRARIES
'---------------------------------------------------------------------------------------------------------
Declare CustomType Library
    Function GetTicks&&
End Declare
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'---------------------------------------------------------------------------------------------------------
'Array to define the section information for each level.
'Each section contains 125 slots. The value of each slot refers to the index of the object contained in that slot. -1 means no object is in this slot.
Dim Shared SectionInfo(0 To 999, 0 To 125) As Unsigned Byte 'There are 1000 sections to a level
Dim Shared ObstacleInfo(0 To 999, 0 To 125) As Unsigned Byte 'There are 1000 obstacle sections to a level

' Game bitmaps
Dim Shared ddsShip As Long 'Ship bitmap
Dim Shared ddsLaser As Long 'Laser 1 laser surface
Dim Shared ddsLaser2R As Long 'Right diagonal laser
Dim Shared ddsLaser2L As Long 'Left diagonal laser
Dim Shared ddsLaser3 As Long 'Laser 3 laser surface
Dim Shared ddsGuidedMissile As Long 'Guided Missile
Dim Shared ddsStar As Long 'Star
Dim Shared ddsEnemyFire As Long 'Enemy laser fire
Dim Shared ddsPowerUp As Long 'Power Up dd surface
Dim Shared ddsShieldIndicator As Long 'Shield indicator bitmap
Dim Shared ddsTitle As Long 'Title Screen surface
Dim Shared ddsHit As Long 'Direct draw surface for small explosions
Dim Shared ddsBackgroundObject(0 To 7) As Long 'Background objects
Dim Shared ddsEnemyContainer(0 To 13) As Long 'Enemy surface container
Dim Shared ddsExplosion(0 To 1) As Long 'Explosion surfaces
Dim Shared ddsObstacle(0 To 40) As Long 'Obstacle direct draw surfaces
Dim Shared ddsDisplayBomb As Long 'Bomb direct draw surface
Dim Shared ddsInvulnerable As Long 'Invulnerable bitmap surface

'Sound Section
Dim Shared dsLaser2 As Long 'stage 2 laser fire buffer
Dim Shared dsLaser As Long 'stage 1 laser fire
Dim Shared dsExplosion As Long 'explosion sound effect
Dim Shared dsPowerUp As Long 'power up sound effect buffer
Dim Shared dsMissile As Long 'missile sound effect buffer
Dim Shared dsEnergize As Long 'sound effect for when the player materializes
Dim Shared dsAlarm As Long 'low shield alarm
Dim Shared dsEnemyFire As Long 'enemy fire direct sound buffer
Dim Shared dsNoHit As Long 'player hits an object that isn't destroyed
Dim Shared dsPulseCannon As Long 'sound for the pulse cannon
Dim Shared dsPlayerDies As Long 'sound for when the player dies
Dim Shared dsInvulnerability As Long 'sound for when the player is invulnerable
Dim Shared dsInvPowerDown As Long 'sound for when the invulnerability wears off
Dim Shared dsExtraLife As Long 'sound for when the player gets an extra life

Dim Shared MIDIHandle As Long ' MIDI music handle

'Variables to handle graphics
Dim Shared boolBackgroundExists As Byte 'Boolean to determine if a background object exists
Dim Shared sngBackgroundX As Single 'X coordinate of the background image
Dim Shared sngBackgroundY As Single 'Y coordinate of the background image
Dim Shared intObjectIndex As Long 'The index number of the object
Dim Shared intShipFrameCount As Long 'The frame number of the players ship
Dim Shared Ship As typeShipDesc 'Set up the players ship
Dim Shared LaserDesc(0 To 14) As typeWeaponDesc 'Set up an array for 15 laser blasts
Dim Shared Laser2RDesc(0 To 6) As typeWeaponDesc 'Set up an array for 7 right diagonal laser blasts
Dim Shared Laser2LDesc(0 To 6) As typeWeaponDesc 'Set up an array for 7 left diagonal laser blasts
Dim Shared Laser3Desc(0 To 2) As typeWeaponDesc 'Set up an array for 3 laser 3 blasts
Dim Shared GuidedMissile(0 To 2) As typeWeaponDesc 'Set up an array for 3 guided missiles
Dim Shared StarDesc(0 To 49) As typeBackGroundDesc 'Set up an array for 50 stars
Dim Shared EnemyDesc(0 To NUMENEMIES) As typeBackGroundDesc 'Set up an array for all enemies
Dim Shared EnemyContainerDesc(0 To 13) As typeBackGroundDesc 'Set up an array for the enemy containers descriptions
Dim Shared ObstacleContainerInfo(0 To 40) As typeBackGroundDesc
'Background objects container
Dim Shared ObstacleDesc(0 To NUMOBSTACLES) As typeBackGroundDesc
'Background objects
Dim Shared BackgroundObject(0 To 7) As typeBackgroundObject 'Set up an array for 8 large background pictures
Dim Shared PowerUp(0 To 3) As typeBackGroundDesc 'Set up an array for the power ups
Dim Shared HitDesc(0 To 19) As typeBackGroundDesc 'Set an array for small explosions when an object is hit
Dim Shared ExplosionDesc(0 To 80) As typeBackGroundDesc 'Array for explosions

'Input stuff
'Dim Shared IsJ As Byte 'Flag that is set if a joystick is present
'Dim Shared IsFF As Byte 'Flag that is set if force feedback is present

'Player Info
Dim Shared byteLives As Unsigned Byte 'Number of lives the player has left
Dim Shared intShields As Long 'The amount of shields the player has left
Dim Shared intEnemiesKilled As Long 'The number of enemies the player has destroyed. For every 30 enemies destroyed, a powerup will appear
Dim Shared lngScore As Long 'Players score
Dim Shared lngNextExtraLifeScore As Long 'The next score the player gets an extra life at
Dim Shared lngNumEnemiesKilled As Long 'The number of enemies killed
Dim Shared lngTotalNumEnemies As Long 'The total number of enemies on the level
Dim Shared byteLevel As Long 'TODO: Make this 'unsigned byte'? 'Players level
Dim Shared strName As String 'Players name when they get a high score

'The rest are miscellaneous variables
Dim Shared SectionCount As Long 'Keeps track of what section the player is on
Dim Shared FrameCount As Long 'keeps track of the number of accumulated frames. When it reaches 20, a new section is added
Dim Shared boolStarted As Byte 'Determines whether a game is running or not
Dim Shared lngHighScore(0 To NUM_HIGH_SCORES - 1) As Unsigned Long 'Keeps track of high scores
Dim Shared strHighScoreName(0 To NUM_HIGH_SCORES - 1) As String 'Keeps track of high score names
Dim Shared byteNewHighScore As Unsigned Byte 'index of a new high score to paint the name color differently
Dim Shared strBuffer As String 'Buffer to pass keypresses
Dim Shared boolEnterPressed As Byte 'Flag to determine if the enter key was pressed
Dim Shared boolGettingInput As Byte 'Flag to see if we are getting input from the player
Dim Shared boolFrameRate As Byte 'Flag to toggle frame rate display on and off
Dim Shared strLevelText As String 'Stores the associated startup text for the level
Dim Shared blnJoystickEnabled As Byte 'Toggles joystick on or off
Dim Shared blnMidiEnabled As Byte 'Toggles Midi music on or off
Dim Shared boolMaxFrameRate As Byte 'Removes all frame rate limits
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - This is the entry point for the game. From here everything branches out to all the
' subs that handle collisions, enemies, player, weapon fire, sounds, level updating, etc.
'---------------------------------------------------------------------------------------------------------
Dim lngTargetTick As Long 'Variable to store the targeted tick count time
Dim lngStartTime As Long 'stores the start time of a frame rate count
Dim lngCurrentTime As Long 'stores the current tick for frame rate count
Dim intFinalFrame As Long 'holds the total number of frames in a second
Dim intFrameCount As Long 'keeps track of how many frames have elapsed

InitializeStartup 'Do the startup routines
LoadHighScores 'Call the sub to load the high scores
lngNextExtraLifeScore = EXTRALIFETARGET 'Initialize the extra life score to 100,000
Sleep 5 ' Sleep for 5 extra seconds
FadeScreen FALSE ' Fade out the loading screen
ClearInput ' Clear any cached input

Do 'The main loop of the game.
    lngTargetTick = GetTicks 'Store the current time of the loop
    GetInput 'call sub that checks for player input
    Cls 'fill the back buffer with black
    UpdateBackground 'Update the background bitmaps
    UpdateStars 'Update the stars
    If boolStarted And boolGettingInput = FALSE Then 'If the game has started, and we are not getting high score input from the player
        FrameCount = FrameCount + 1 'Keep track of the frame increment
        If FrameCount >= 20 Then 'When 20 frames elapsed
            SectionCount = SectionCount - 1 'Reduce the section the player is on
            UpdateLevels 'Update the section
            FrameCount = 0 'Reset the frame count
        End If
        UpdateObstacles 'Update the back layer of objects
        UpdateEnemys 'Move and draw the enemys
        UpdatePowerUps FALSE 'Move and draw the power ups
        UpdateHits FALSE, 0, 0 'Update the small explosions
        UpdateWeapons 'Move and draw the weapons
        UpdateExplosions 'Update any large explosions
        UpdateShip 'Move and draw the ship
        If Ship.Invulnerable Then UpdateInvulnerability 'if the player is invulnerable, then update the invulnerability effect
        CheckForCollisions 'Branch to collision checking subs
        UpdateShields 'Branch to sub that paints shields
        UpdateBombs
        DrawString 30, 10, "Score:" + Str$(lngScore), RGB32(149, 248, 153)
        'Display the score
        DrawString 175, 10, "Lives:" + Str$(byteLives), RGB32(149, 248, 153) 'Display lives left.
        DrawString 560, 10, "Level:" + Str$(byteLevel), RGB32(149, 248, 153) 'Display the current level
        CheckScore
    ElseIf boolStarted = FALSE And boolGettingInput = FALSE Then 'If we haven't started, and we aren't getting high score input from the player
        ShowTitle 'Show the title screen with high scores and directions
    ElseIf boolGettingInput Then 'If we are getting input from the player, then
        CheckHighScore 'call the high score subroutine
    End If
    If boolFrameRate Then 'If the frame rate display is toggled
        intFrameCount = intFrameCount + 1 'increment the frame count
        lngCurrentTime = GetTicks 'get the current tick count
        If lngCurrentTime > lngStartTime + 1000 Then 'if one second has elapsed
            intFinalFrame = intFrameCount 'the total number of frames is stored in intFinalFrame
            intFrameCount = 0 'reset the frame count
            lngStartTime = GetTicks 'get a new start time
        End If
        DrawString 30, 30, "FPS:" + Str$(intFinalFrame), RGB32(255, 255, 255)
        'display the frame rate
    End If

    If Not boolMaxFrameRate Then
        Do Until GetTicks - lngTargetTick > 18 'Make sure the game doesn't get out of control
        Loop 'speed-wise by looping until we reach the targeted frame rate
    Else
        DrawString 30, 45, "Uncapped FPS enabled", RGB32(255, 255, 255) 'Let the player know there is no frame rate limitation
    End If
    Display 'Flip the front buffer with the back

    Delay 0.001 'Let the system process stuff
    If boolStarted And KeyDown(DIK_ESCAPE) Then 'If the game has started, and the player presses escape
        'TODO: If IsFF = True Then ef(2).Unload                            'unload the laser force feedback effect
        ResetGame 'call the sub to reset the game variables
    End If 'If the escape key is preseed, reset the game and go back to the title screen
Loop 'keep looping endlessly

End 1 ' It should not come here
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'---------------------------------------------------------------------------------------------------------
'This sub resets all the variables in the game that need to be reset when the game is started over.
Sub ResetGame
    Dim intCount As Long 'variable for looping

    For intCount = 0 To UBound(EnemyDesc) 'loop through all the enemies and
        EnemyDesc(intCount).Exists = FALSE 'the enemies no longer exist
        EnemyDesc(intCount).HasFired = FALSE 'the enemies' wepaons no longer exist
    Next
    For intCount = 0 To UBound(GuidedMissile) 'loop through all the players guided missiles
        GuidedMissile(intCount).Exists = FALSE 'they no longer exist
    Next
    For intCount = 0 To UBound(ObstacleDesc) 'make all the obstacles non-existent
        ObstacleDesc(intCount).Exists = FALSE
        ObstacleDesc(intCount).HasFired = FALSE
    Next
    For intCount = 0 To UBound(ExplosionDesc) 'Make sure that no explosions get left over
        ExplosionDesc(intCount).Exists = FALSE
    Next
    For intCount = 0 To UBound(PowerUp)
        PowerUp(intCount).Exists = FALSE 'if there are any power ups currently on screen, get rid of them
    Next
    intShields = 100 'shields are at full again

    FadeScreen FALSE 'Fade the screen to black
    intShields = 100 'shields are at 100%

    Ship.X = 300 'center the ships' X
    Ship.Y = 300 'and Y
    Ship.PowerUpState = 0 'the player is back to no powerups
    Ship.PowerUpState = 0 'no powerups
    Ship.NumBombs = 0 'the player has no bombs
    Ship.Invulnerable = FALSE 'the player is no longer invulnerable if he was
    Ship.AlarmActive = FALSE 'the low shield alarm no longer needs to be flagged
    Ship.FiringMissile = FALSE 'the ship is not firing a missile

    SndStop dsInvulnerability 'make sure the invulnerability sound effect is not playing
    SndStop dsAlarm 'make sure the alarm sound effect is not playing
    boolStarted = FALSE 'the game hasn't been started
    SectionCount = 999 'start at the beginning of the level
    byteLevel = 1 'player is at level 1 again
    byteLives = 3 'the player has 3 lives left
    boolBackgroundExists = FALSE 'there is no background picture
    CheckHighScore 'call the sub to see if the player got a high score
End Sub


'This sub initializes all neccessary objects, classes, variables, and user-defined types
Sub InitializeStartup
    Randomize Timer ' Seed randomizer
    Title APP_NAME ' Set the Window title
    Screen NewImage(SCREEN_WIDTH, SCREEN_HEIGHT, 32) ' Initialize graphics
    FullScreen SquarePixels , Smooth ' Set to fullscreen. We can also go to windowed mode using Alt+Enter
    PrintMode KeepBackground ' We want transparent text rendering

    Cls ' We want black screen
    Display ' We want the framebuffer to be updated when we want

    MouseHide 'don't show the cursor while DX is active
    blnMidiEnabled = TRUE 'turn on the midi by default
    Delay 0.001 'don't hog the processor while we are loading
    byteNewHighScore = 255 'set the new high score to no new high score
    InitializeDS
    InitializeDD 'call the sub that initialized direct draw

    'Initialize all the descriptions of all entities in the game

    'This UDT describes the enemy
    EnemyContainerDesc(0).FileName = "enemy1.gif" 'Name of the file
    EnemyContainerDesc(0).H = 50 'The bitmap is 30 pixels high
    EnemyContainerDesc(0).W = 40 '80 pixels wide
    EnemyContainerDesc(0).NumFrames = 60 '61 frames of animation (Zero based)
    EnemyContainerDesc(0).TimesDies = 1 'It takes one hit to destroy
    EnemyContainerDesc(0).ExplosionIndex = 0 'The enemy uses the first explosion type
    EnemyContainerDesc(0).Score = 150 'Player gets 150 points for destroying it
    EnemyContainerDesc(0).Speed = 3 'It moves 3 pixels every frame
    EnemyContainerDesc(0).ChaseValue = CHASEFAST 'This enemy chases the players' X coordinates, and does it fast
    EnemyContainerDesc(0).DoesFire = TRUE 'This enemy fires a weapon
    EnemyContainerDesc(0).FireType = NONTARGETEDFIRE 'It doesn't aim towards the player
    EnemyContainerDesc(0).CollisionDamage = 5 'It does 5 points of damage if the player collides with it

    'The rest of the entities are setup much the same way. Any differences from previous entities are noted.

    EnemyContainerDesc(1).FileName = "enemy2.gif"
    EnemyContainerDesc(1).H = 64
    EnemyContainerDesc(1).W = 64
    EnemyContainerDesc(1).NumFrames = 60
    EnemyContainerDesc(1).TimesDies = 3
    EnemyContainerDesc(1).ExplosionIndex = 1 'This enemy displays the second explosion type
    EnemyContainerDesc(1).Score = 250
    EnemyContainerDesc(1).Speed = 1.5
    EnemyContainerDesc(1).ChaseValue = CHASESLOW 'This enemy chases the players' X coordinates, but chases slowly
    EnemyContainerDesc(1).DoesFire = TRUE
    EnemyContainerDesc(1).FireType = NONTARGETEDFIRE
    EnemyContainerDesc(1).CollisionDamage = 10

    EnemyContainerDesc(2).FileName = "enemy3.gif"
    EnemyContainerDesc(2).H = 64
    EnemyContainerDesc(2).W = 64
    EnemyContainerDesc(2).NumFrames = 30
    EnemyContainerDesc(2).TimesDies = 4
    EnemyContainerDesc(2).ExplosionIndex = 0
    EnemyContainerDesc(2).Score = 350
    EnemyContainerDesc(2).Speed = 2
    EnemyContainerDesc(2).ChaseValue = CHASEOFF 'This enemy does not chase the players' X coordinates. This value doesn't need to be setm though, since its' value is 0. It can be set merely as a reminder of the enemies behavior.
    EnemyContainerDesc(2).FireType = TARGETEDFIRE 'This enemy does fire towards the player
    EnemyContainerDesc(2).DoesFire = TRUE
    EnemyContainerDesc(2).CollisionDamage = 5

    EnemyContainerDesc(3).FileName = "enemy4.gif"
    EnemyContainerDesc(3).H = 90
    EnemyContainerDesc(3).W = 38
    EnemyContainerDesc(3).NumFrames = 60
    EnemyContainerDesc(3).TimesDies = 1
    EnemyContainerDesc(3).ExplosionIndex = 1
    EnemyContainerDesc(3).Score = 300
    EnemyContainerDesc(3).Speed = 4
    EnemyContainerDesc(3).DoesFire = TRUE
    EnemyContainerDesc(3).FireType = TARGETEDFIRE
    EnemyContainerDesc(3).CollisionDamage = 10

    EnemyContainerDesc(4).FileName = "blocker.gif"
    EnemyContainerDesc(4).NumFrames = 120
    EnemyContainerDesc(4).H = 31
    EnemyContainerDesc(4).W = 31
    EnemyContainerDesc(4).Speed = 1
    EnemyContainerDesc(4).Score = 400
    EnemyContainerDesc(4).TimesDies = 40
    EnemyContainerDesc(4).ExplosionIndex = 0
    EnemyContainerDesc(4).CollisionDamage = 20

    EnemyContainerDesc(5).FileName = "asteroid1.gif"
    EnemyContainerDesc(5).NumFrames = 28
    EnemyContainerDesc(5).H = 75
    EnemyContainerDesc(5).W = 75
    EnemyContainerDesc(5).Speed = 1.75
    EnemyContainerDesc(5).Score = 600
    EnemyContainerDesc(5).TimesDies = 30
    EnemyContainerDesc(5).ExplosionIndex = 1
    EnemyContainerDesc(5).FrameDelay = 1 'Used to slow the animation down
    EnemyContainerDesc(5).CollisionDamage = 35

    EnemyContainerDesc(6).FileName = "asteroid2.gif"
    EnemyContainerDesc(6).NumFrames = 28
    EnemyContainerDesc(6).H = 70
    EnemyContainerDesc(6).W = 75
    EnemyContainerDesc(6).Speed = 2.5
    EnemyContainerDesc(6).FrameDelay = 1
    EnemyContainerDesc(6).Score = 600
    EnemyContainerDesc(6).TimesDies = 30
    EnemyContainerDesc(6).ExplosionIndex = 0
    EnemyContainerDesc(6).CollisionDamage = 35

    EnemyContainerDesc(7).FileName = "asteroid3.gif"
    EnemyContainerDesc(7).NumFrames = 28
    EnemyContainerDesc(7).H = 65
    EnemyContainerDesc(7).W = 75
    EnemyContainerDesc(7).Speed = 2
    EnemyContainerDesc(7).FrameDelay = 1
    EnemyContainerDesc(7).Score = 600
    EnemyContainerDesc(7).TimesDies = 30
    EnemyContainerDesc(7).ExplosionIndex = 1
    EnemyContainerDesc(7).CollisionDamage = 35

    EnemyContainerDesc(8).FileName = "asteroid4.gif"
    EnemyContainerDesc(8).NumFrames = 28
    EnemyContainerDesc(8).H = 65
    EnemyContainerDesc(8).W = 75
    EnemyContainerDesc(8).Speed = 3
    EnemyContainerDesc(8).Score = 600
    EnemyContainerDesc(8).TimesDies = 30
    EnemyContainerDesc(8).ExplosionIndex = 0
    EnemyContainerDesc(8).FrameDelay = 1
    EnemyContainerDesc(8).CollisionDamage = 35

    EnemyContainerDesc(9).FileName = "enemy5.gif"
    EnemyContainerDesc(9).NumFrames = 49
    EnemyContainerDesc(9).H = 70
    EnemyContainerDesc(9).W = 50
    EnemyContainerDesc(9).Speed = 2.5
    EnemyContainerDesc(9).Score = 600
    EnemyContainerDesc(9).TimesDies = 4
    EnemyContainerDesc(9).ExplosionIndex = 0
    EnemyContainerDesc(9).FrameDelay = 1
    EnemyContainerDesc(9).CollisionDamage = 10
    EnemyContainerDesc(9).DoesFire = TRUE
    EnemyContainerDesc(9).FireType = TARGETEDFIRE

    EnemyContainerDesc(10).FileName = "enemy6.gif"
    EnemyContainerDesc(10).NumFrames = 99
    EnemyContainerDesc(10).H = 60
    EnemyContainerDesc(10).W = 60
    EnemyContainerDesc(10).Speed = 4.5
    EnemyContainerDesc(10).Score = 800
    EnemyContainerDesc(10).TimesDies = 1
    EnemyContainerDesc(10).ExplosionIndex = 1
    EnemyContainerDesc(10).CollisionDamage = 5
    EnemyContainerDesc(10).DoesFire = TRUE
    EnemyContainerDesc(10).FireType = TARGETEDFIRE

    EnemyContainerDesc(11).FileName = "enemy7.gif"
    EnemyContainerDesc(11).NumFrames = 99
    EnemyContainerDesc(11).H = 100
    EnemyContainerDesc(11).W = 40
    EnemyContainerDesc(11).Speed = 3.5
    EnemyContainerDesc(11).Score = 1000
    EnemyContainerDesc(11).TimesDies = 10
    EnemyContainerDesc(11).ExplosionIndex = 0
    EnemyContainerDesc(11).CollisionDamage = 20

    EnemyContainerDesc(12).FileName = "enemy8.gif"
    EnemyContainerDesc(12).NumFrames = 99
    EnemyContainerDesc(12).H = 50
    EnemyContainerDesc(12).W = 50
    EnemyContainerDesc(12).Speed = 4
    EnemyContainerDesc(12).Score = 500
    EnemyContainerDesc(12).TimesDies = 1
    EnemyContainerDesc(12).ExplosionIndex = 1
    EnemyContainerDesc(12).CollisionDamage = 20

    EnemyContainerDesc(13).FileName = "enemy9.gif"
    EnemyContainerDesc(13).NumFrames = 99
    EnemyContainerDesc(13).H = 45
    EnemyContainerDesc(13).W = 65
    EnemyContainerDesc(13).Speed = 2
    EnemyContainerDesc(13).ChaseValue = CHASESLOW
    EnemyContainerDesc(13).Score = 1000
    EnemyContainerDesc(13).TimesDies = 6
    EnemyContainerDesc(13).ExplosionIndex = 0
    EnemyContainerDesc(13).CollisionDamage = 10
    EnemyContainerDesc(13).DoesFire = TRUE
    EnemyContainerDesc(13).FireType = TARGETEDFIRE

    ObstacleContainerInfo(0).FileName = "plate1.gif"
    ObstacleContainerInfo(0).H = 80
    ObstacleContainerInfo(0).W = 80
    ObstacleContainerInfo(0).Invulnerable = TRUE
    ObstacleContainerInfo(0).Speed = 1

    ObstacleContainerInfo(1).FileName = "movingplate.gif"
    ObstacleContainerInfo(1).H = 40
    ObstacleContainerInfo(1).W = 40
    ObstacleContainerInfo(1).HasDeadIndex = TRUE
    ObstacleContainerInfo(1).DeadIndex = 40
    ObstacleContainerInfo(1).DoesFire = TRUE
    ObstacleContainerInfo(1).FireType = NONTARGETEDFIRE
    ObstacleContainerInfo(1).TimesDies = 5
    ObstacleContainerInfo(1).ExplosionIndex = 0
    ObstacleContainerInfo(1).Score = 600
    ObstacleContainerInfo(1).Speed = 1
    ObstacleContainerInfo(1).Solid = TRUE
    ObstacleContainerInfo(1).NumFrames = 39

    ObstacleContainerInfo(2).FileName = "plate3.gif"
    ObstacleContainerInfo(2).H = 40
    ObstacleContainerInfo(2).W = 40
    ObstacleContainerInfo(2).CollisionDamage = 100
    ObstacleContainerInfo(2).Speed = 1
    ObstacleContainerInfo(2).Solid = TRUE
    ObstacleContainerInfo(2).HasDeadIndex = TRUE
    ObstacleContainerInfo(2).DeadIndex = 40
    ObstacleContainerInfo(2).TimesDies = 3
    ObstacleContainerInfo(2).ExplosionIndex = 1
    ObstacleContainerInfo(2).Score = 400

    ObstacleContainerInfo(3).FileName = "plate4.gif"
    ObstacleContainerInfo(3).H = 40
    ObstacleContainerInfo(3).W = 40
    ObstacleContainerInfo(3).Invulnerable = TRUE
    ObstacleContainerInfo(3).Speed = 1
    ObstacleContainerInfo(3).Solid = TRUE

    ObstacleContainerInfo(4).FileName = "plate5.gif"
    ObstacleContainerInfo(4).H = 40
    ObstacleContainerInfo(4).W = 40
    ObstacleContainerInfo(4).HasDeadIndex = TRUE
    ObstacleContainerInfo(4).DeadIndex = 40
    ObstacleContainerInfo(4).TimesDies = 3
    ObstacleContainerInfo(4).ExplosionIndex = 0
    ObstacleContainerInfo(4).Speed = 1
    ObstacleContainerInfo(4).Solid = TRUE
    ObstacleContainerInfo(4).Score = 400

    ObstacleContainerInfo(5).FileName = "plate6.gif"
    ObstacleContainerInfo(5).H = 40
    ObstacleContainerInfo(5).W = 40
    ObstacleContainerInfo(5).Invulnerable = TRUE
    ObstacleContainerInfo(5).Speed = 1

    ObstacleContainerInfo(6).FileName = "plate7.gif"
    ObstacleContainerInfo(6).H = 40
    ObstacleContainerInfo(6).W = 40
    ObstacleContainerInfo(6).Invulnerable = TRUE
    ObstacleContainerInfo(6).Speed = 1

    ObstacleContainerInfo(7).FileName = "plate8.gif"
    ObstacleContainerInfo(7).H = 40
    ObstacleContainerInfo(7).W = 40
    ObstacleContainerInfo(7).Invulnerable = TRUE
    ObstacleContainerInfo(7).Speed = 1

    ObstacleContainerInfo(8).FileName = "plate9.gif"
    ObstacleContainerInfo(8).H = 40
    ObstacleContainerInfo(8).W = 40
    ObstacleContainerInfo(8).Invulnerable = TRUE
    ObstacleContainerInfo(8).Speed = 1

    ObstacleContainerInfo(9).FileName = "plate10.gif"
    ObstacleContainerInfo(9).H = 40
    ObstacleContainerInfo(9).W = 40
    ObstacleContainerInfo(9).Invulnerable = TRUE
    ObstacleContainerInfo(9).Speed = 1

    ObstacleContainerInfo(10).FileName = "plate11.gif"
    ObstacleContainerInfo(10).H = 40
    ObstacleContainerInfo(10).W = 40
    ObstacleContainerInfo(10).Invulnerable = TRUE
    ObstacleContainerInfo(10).Speed = 1

    ObstacleContainerInfo(11).FileName = "plate12.gif"
    ObstacleContainerInfo(11).H = 40
    ObstacleContainerInfo(11).W = 40
    ObstacleContainerInfo(11).Invulnerable = TRUE
    ObstacleContainerInfo(11).Speed = 1

    ObstacleContainerInfo(12).FileName = "plate13.gif"
    ObstacleContainerInfo(12).H = 40
    ObstacleContainerInfo(12).W = 40
    ObstacleContainerInfo(12).Invulnerable = TRUE
    ObstacleContainerInfo(12).Speed = 1

    ObstacleContainerInfo(13).FileName = "plate2.gif"
    ObstacleContainerInfo(13).H = 40
    ObstacleContainerInfo(13).W = 40
    ObstacleContainerInfo(13).HasDeadIndex = TRUE
    ObstacleContainerInfo(13).DeadIndex = 40
    ObstacleContainerInfo(13).Speed = 1
    ObstacleContainerInfo(13).Solid = TRUE
    ObstacleContainerInfo(13).TimesDies = 3
    ObstacleContainerInfo(13).ExplosionIndex = 1
    ObstacleContainerInfo(13).Score = 450

    ObstacleContainerInfo(14).FileName = "plate14.gif"
    ObstacleContainerInfo(14).H = 40
    ObstacleContainerInfo(14).W = 40
    ObstacleContainerInfo(14).HasDeadIndex = TRUE
    ObstacleContainerInfo(14).DeadIndex = 40
    ObstacleContainerInfo(14).Speed = 1
    ObstacleContainerInfo(14).Solid = TRUE
    ObstacleContainerInfo(14).TimesDies = 3
    ObstacleContainerInfo(14).ExplosionIndex = 0
    ObstacleContainerInfo(14).Score = 350

    ObstacleContainerInfo(15).FileName = "plate15.gif"
    ObstacleContainerInfo(15).H = 40
    ObstacleContainerInfo(15).W = 40
    ObstacleContainerInfo(15).HasDeadIndex = TRUE
    ObstacleContainerInfo(15).DeadIndex = 40
    ObstacleContainerInfo(15).Speed = 1
    ObstacleContainerInfo(15).Solid = TRUE
    ObstacleContainerInfo(15).TimesDies = 3
    ObstacleContainerInfo(15).ExplosionIndex = 1
    ObstacleContainerInfo(15).Score = 450

    ObstacleContainerInfo(40).FileName = "deadplate.gif"
    ObstacleContainerInfo(40).H = 40
    ObstacleContainerInfo(40).W = 40
    ObstacleContainerInfo(40).Invulnerable = TRUE
    ObstacleContainerInfo(40).Speed = 1
    ObstacleContainerInfo(40).NumFrames = 23
    ObstacleContainerInfo(40).DeadIndex = 40
    ObstacleContainerInfo(40).Solid = TRUE

    'Setup the data for all the background bitmaps

    BackgroundObject(0).W = 600
    BackgroundObject(0).H = 400
    BackgroundObject(0).PathName = "nebulae1.gif"
    BackgroundObject(1).W = 600
    BackgroundObject(1).H = 400
    BackgroundObject(1).PathName = "asteroid field.gif"
    BackgroundObject(2).W = 600
    BackgroundObject(2).H = 400
    BackgroundObject(2).PathName = "red giant.gif"
    BackgroundObject(3).W = 600
    BackgroundObject(3).H = 400
    BackgroundObject(3).PathName = "nebulae2.gif"
    BackgroundObject(4).W = 600
    BackgroundObject(4).H = 460
    BackgroundObject(4).PathName = "cometary.gif"
    BackgroundObject(5).W = 600
    BackgroundObject(5).H = 400
    BackgroundObject(5).PathName = "nebulae5.gif"
    BackgroundObject(6).W = 600
    BackgroundObject(6).H = 400
    BackgroundObject(6).PathName = "nebulae3.gif"
    BackgroundObject(7).W = 600
    BackgroundObject(7).H = 400
    BackgroundObject(7).PathName = "nebulae4.gif"
End Sub


' Loads the high score file from disk
' If a high score file cannot be found or cannot be read, a default list of high-score entries is created
Sub LoadHighScores
    If FileExists(HIGH_SCORE_FILENAME) Then
        Dim i As Integer
        Dim hsFile As Long

        ' Open the highscore file
        hsFile = FreeFile
        Open HIGH_SCORE_FILENAME For Input As hsFile

        ' Read the name and the scores
        For i = 0 To NUM_HIGH_SCORES - 1
            Input #hsFile, strHighScoreName(i), lngHighScore(i)
            strHighScoreName(i) = Trim$(strHighScoreName(i)) 'trim the highscorename variable of all spaces and assign it to the name array
        Next

        ' Close file
        Close hsFile
    Else
        ' Load default highscores if there is no highscore file

        strHighScoreName(0) = "Major Stryker"
        lngHighScore(0) = 10000

        strHighScoreName(1) = "Sam Stone"
        lngHighScore(1) = 9000

        strHighScoreName(2) = "Commander Keen"
        lngHighScore(2) = 8000

        strHighScoreName(3) = "Gordon Freeman"
        lngHighScore(3) = 7000

        strHighScoreName(4) = "Max Payne"
        lngHighScore(4) = 6000

        strHighScoreName(5) = "Lara Croft"
        lngHighScore(5) = 5000

        strHighScoreName(6) = "Duke Nukem"
        lngHighScore(6) = 4000

        strHighScoreName(7) = "Master Chief"
        lngHighScore(7) = 3000

        strHighScoreName(8) = "Marcus Fenix"
        lngHighScore(8) = 2000

        strHighScoreName(9) = "John Blade"
        lngHighScore(9) = 1000
    End If
End Sub


' Writes the HighScore array out to the high score file
Sub SaveHighScores
    Dim i As Integer
    Dim hsFile As Long

    ' Open the file for writing
    hsFile = FreeFile

    Open HIGH_SCORE_FILENAME For Output As hsFile

    For i = 0 To NUM_HIGH_SCORES - 1
        strHighScoreName(i) = Trim$(strHighScoreName(i)) 'trim the highscorename variable of all spaces and assign it to the name array
        Write #hsFile, strHighScoreName(i), lngHighScore(i)
    Next

    Close hsFile
End Sub


'This routine checks the current score, and determines if it has gone past the extra life threshold.
'If it has, then display that the player has gained an extra life, and give the player an extra life
Sub CheckScore
    Static blnExtraLifeDisplay As Byte 'Flag that is set if an extra life message needs to be displayed
    Static lngTargetTime As Long 'Variable used to hold the targeted time

    If lngScore > lngNextExtraLifeScore Then 'If the current score is larger than the score needed to get an extra life
        lngNextExtraLifeScore = lngNextExtraLifeScore + EXTRALIFETARGET 'Increase the extra life target score
        SndSetPos dsExtraLife, 0 'Set the extra life wave position to the beginning
        SndPlay dsExtraLife 'Play the extra life wave file
        blnExtraLifeDisplay = TRUE 'Toggle the extra life display flag to on
        lngTargetTime = GetTicks + 3000 'Set the end time for displaying the extra life message
        byteLives = byteLives + 1 'increase the players life by 1
    End If

    If lngTargetTime > GetTicks And blnExtraLifeDisplay Then 'As long as the target time is larger than the current time, and the extra life display flag is set
        DrawStringCenter "Extra Life!!!", 250, RGB32(255, 50, 50)
        'Display the extra life message
    Else
        blnExtraLifeDisplay = FALSE 'Otherwise, if we have gone past the display duration, turn the display flag off
    End If
End Sub


'This sub displays the title screen, and rotates one of the palette indexes from blue to black
Sub ShowTitle
    Dim lngYCount As Long 'Y variable for counting
    Dim lngCount As Long 'x variable for counting

    PutImage (200, 50), ddsTitle 'blit the entire title screen bitmap to the backbuffer using the source color key as a mask
    DrawString 290, 250, "High Scores", RGB32(255, 200, 175) 'Display the high scores message
    lngYCount = 265 'Initialize the starting y coordinate for the high scores
    For lngCount = 0 To 9 'loop through the 10 high scores
        If lngCount = byteNewHighScore Then
            DrawString 265, lngYCount, Str$(lngHighScore(lngCount)) + "   " + strHighScoreName(lngCount), RGB32(254, 255, 102)
        Else
            DrawString 265, lngYCount, Str$(lngHighScore(lngCount)) + "   " + strHighScoreName(lngCount), RGB32(50, 100, 200)
        End If
        'display the high score information
        lngYCount = lngYCount + 15 'increment the Y coordinate for the next high score
    Next

    If blnMidiEnabled Then 'if midi is enabled
        DrawStringCenter "Press M to toggle Midi music. Midi: Enabled", 435, RGB32(58, 84, 26)
        'display this message
    Else 'otherwise
        DrawStringCenter "Press M to toggle Midi music. Midi: Disabled", 435, RGB32(58, 84, 26)
        'display this message
    End If

    If blnJoystickEnabled Then 'if the joystick is enabled display this message
        DrawStringCenter "Press J to toggle joystick. Joystick: Enabled", 450, RGB32(56, 78, 56)
    Else 'otherwise
        DrawStringCenter "Press J to toggle joystick. Joystick: Disabled", 450, RGB32(56, 78, 56)
        'display this message
    End If
End Sub


'This sub initializes Direct Draw and loads up all the surfaces
Sub InitializeDD
    Dim ddsSplash As Long 'dim a direct draw surface
    ddsSplash = LoadImage("./dat/gfx/splash.gif") 'create the splash screen surface
    PutImage (0, 0), ddsSplash 'blit the splash screen to the back buffer
    FreeImage ddsSplash 'release the splash screen, since we don't need it anymore
    FadeScreen TRUE 'flip the front buffer so the splash screen bitmap on the backbuffer is displayed
    PlayMIDIFile "./dat/sfx/mus/title.mid" 'Start playing the title song

    ddsTitle = LoadImageTransparent("./dat/gfx/title.gif") 'Load the title screen bitmap and put in a direct draw surface
    ddsShip = LoadImageTransparent("./dat/gfx/ship.gif") 'Load the ship bitmap and make it into a direct draw surface
    ddsShieldIndicator = LoadImage("./dat/gfx/shields.gif") 'Load the shield indicator bitmap and put in a direct draw surface
    ddsPowerUp = LoadImageTransparent("./dat/gfx/powerups.gif") 'Load the shield indicator bitmap and put in a direct draw surface
    ddsExplosion(0) = LoadImageTransparent("./dat/gfx/explosion.gif") 'Load the first explosion bitmap
    ddsExplosion(1) = LoadImageTransparent("./dat/gfx/explosion2.gif") 'Load the second explosion bitmap
    ddsInvulnerable = LoadImageTransparent("./dat/gfx/invulnerable.gif") 'Load the invulnerable bitmap

    Dim intCount As Long 'count variable

    'The rest of the sub just describes the various attributes of the enemies, obstacles, and background bitmaps, and
    'loads the neccessary objets into direct draw surfaces
    For intCount = 0 To UBound(ExplosionDesc)
        ExplosionDesc(intCount).NumFrames = 19
        ExplosionDesc(intCount).W = 120
        ExplosionDesc(intCount).H = 120
    Next

    ddsHit = LoadImageTransparent("./dat/gfx/hit.gif")
    For intCount = 0 To UBound(HitDesc)
        HitDesc(intCount).NumFrames = 5
        HitDesc(intCount).H = 8
        HitDesc(intCount).W = 8
    Next

    ddsLaser = LoadImageTransparent("./dat/gfx/laser.bmp")
    For intCount = 0 To UBound(LaserDesc)
        LaserDesc(intCount).Exists = FALSE
        LaserDesc(intCount).W = LASER1WIDTH
        LaserDesc(intCount).H = LASER1HEIGHT
    Next

    ddsLaser2R = LoadImageTransparent("./dat/gfx/laser2.gif")
    For intCount = 0 To UBound(Laser2RDesc)
        Laser2RDesc(intCount).Exists = FALSE
        Laser2RDesc(intCount).W = LASER2WIDTH
        Laser2RDesc(intCount).H = LASER2HEIGHT
    Next

    ddsLaser2L = LoadImageTransparent("./dat/gfx/laser2.gif")
    For intCount = 0 To UBound(Laser2LDesc)
        Laser2LDesc(intCount).Exists = FALSE
        Laser2LDesc(intCount).W = LASER2WIDTH
        Laser2LDesc(intCount).H = LASER2HEIGHT
    Next

    ddsLaser3 = LoadImageTransparent("./dat/gfx/laser3.gif")
    For intCount = 0 To UBound(Laser3Desc)
        Laser3Desc(intCount).Exists = FALSE
        Laser3Desc(intCount).W = LASER3WIDTH
        Laser3Desc(intCount).H = LASER3HEIGHT
    Next

    ddsEnemyFire = LoadImageTransparent("./dat/gfx/enemyfire1.gif")
    ddsStar = LoadImage("./dat/gfx/stars.gif")
    ddsGuidedMissile = LoadImageTransparent("./dat/gfx/guidedmissile.gif")
    ddsDisplayBomb = LoadImageTransparent("./dat/gfx/displaybomb.gif")
    ddsObstacle(40) = LoadImage("./dat/gfx/deadplate.gif")
End Sub


'This sub initializes all of the sound effects used by SS2k
Sub InitializeDS
    'The next lines load up all of the wave files using the default capabilites
    dsPowerUp = SndOpen("./dat/sfx/snd/powerup.wav")
    dsEnergize = SndOpen("./dat/sfx/snd/energize.wav")
    dsAlarm = SndOpen("./dat/sfx/snd/alarm.wav")
    dsLaser = SndOpen("./dat/sfx/snd/laser.wav")
    dsExplosion = SndOpen("./dat/sfx/snd/explosion.wav")
    dsMissile = SndOpen("./dat/sfx/snd/missile.wav")
    dsNoHit = SndOpen("./dat/sfx/snd/nohit.wav")
    dsEnemyFire = SndOpen("./dat/sfx/snd/enemyfire.wav")
    dsLaser2 = SndOpen("./dat/sfx/snd/laser2.wav")
    dsPulseCannon = SndOpen("./dat/sfx/snd/pulse.wav")
    dsPlayerDies = SndOpen("./dat/sfx/snd/playerdies.wav")
    dsInvulnerability = SndOpen("./dat/sfx/snd/invulnerability.wav")
    dsInvPowerDown = SndOpen("./dat/sfx/snd/invpowerdown.wav")
    dsExtraLife = SndOpen("./dat/sfx/snd/extralife.wav")
End Sub


' Fades the screen to / from black
Sub FadeScreen (bIn As Byte) ' Optional FadeIn As Boolean
    ' Copy the whole screen to a temporary image buffer
    Dim tmp As Long
    tmp = CopyImage(0)

    Dim i As Unsigned Byte
    Dim As Unsigned Long w, h

    w = Width(tmp) - 1
    h = Height(tmp) - 1

    For i = 0 To 255
        ' First bllit the image to the framebuffer
        PutImage (0, 0), tmp
        ' Now draw a black box over the image with changing alpha
        If bIn Then
            Line (0, 0)-(w, h), RGBA(0, 0, 0, 255 - i), BF
        Else
            Line (0, 0)-(w, h), RGBA(0, 0, 0, i), BF
        End If

        ' Flip the framebuffer
        Display
        ' Delay a bit
        Delay 0.002
    Next

    FreeImage tmp
End Sub


' Centers a string on the screen
' The function calculates the correct starting column position to center the string on the screen and then draws the actual text
Sub DrawStringCenter (s As String, y As Long, c As Unsigned Long)
    Color c
    PrintString ((SCREEN_WIDTH \ 2) - (PrintWidth(s) \ 2), y), s
End Sub


'This sub draws text to the back buffer
Sub DrawString (lngXPos As Long, lngYPos As Long, strText As String, lngColor As Unsigned Long)
    Color lngColor 'Set the color of the text to the color passed to the sub
    PrintString (lngXPos, lngYPos), strText 'Draw the text on to the screen, in the coordinates specified
End Sub


'This sub releases all Direct X objects
Sub EndGame
    Dim intCount As Long 'standard count variable

    MouseShow 'turn the cursor back on
    AutoDisplay

    'Release direct input objects
    KeyClear 'unaquire the keyboard
    'TODO: If Not diJoystick Is Nothing Then                       'if the joystick device exists,
    '    diJoystick.Unacquire                                'unacquire it
    '    Set diJoystick = Nothing                            'set the joystick instance to nothing
    'End If

    'Release direct sound objects
    SndClose dsExplosion 'set the explosion ds buffer to nothing
    dsExplosion = NULL
    SndClose dsEnergize 'set the ds enemrgize buffer to nothing
    dsEnergize = NULL
    SndClose dsAlarm 'set the alarm ds buffer to nothing
    dsAlarm = NULL
    SndClose dsEnemyFire 'set the enemy fire ds buffer to nothing
    dsEnemyFire = NULL
    SndClose dsNoHit 'set the no hit ds buffer to nothing
    dsNoHit = NULL
    SndClose dsLaser2 'set the level2 ds buffer to nothing
    dsLaser2 = NULL
    SndClose dsLaser 'set the ds laser buffer to nothing
    dsLaser = NULL
    SndClose dsPulseCannon
    dsPulseCannon = NULL
    SndClose dsPlayerDies
    dsPlayerDies = NULL
    SndClose dsPowerUp 'set the power up ds buffer to nothing
    dsPowerUp = NULL
    SndClose dsMissile 'set the ds missile buffer to nothing
    dsMissile = NULL
    SndClose dsInvulnerability 'set the ds invulnerable to nothing
    dsInvulnerability = NULL
    SndClose dsInvPowerDown 'set the power down sound to nothing
    dsInvPowerDown = NULL
    SndClose dsExtraLife 'set the extra life sound to nothing
    dsExtraLife = NULL

    'Direct Draw
    If ddsHit < -1 Then FreeImage ddsHit 'set the hit direct draw surface to nothing
    ddsHit = NULL
    If ddsLaser < -1 Then FreeImage ddsLaser 'set the laser dds to nothing
    ddsLaser = NULL
    If ddsLaser2R < -1 Then FreeImage ddsLaser2R 'laser2 right side dds to nothing
    ddsLaser2R = NULL
    If ddsLaser2L < -1 Then FreeImage ddsLaser2L 'laser2 left side dds to nothing
    ddsLaser2L = NULL
    If ddsLaser3 < -1 Then FreeImage ddsLaser3 'laser3 surface to nothing
    ddsLaser3 = NULL
    If ddsStar < -1 Then FreeImage ddsStar 'set the stars surface to nothing
    ddsStar = NULL
    If ddsEnemyFire < -1 Then FreeImage ddsEnemyFire 'enemy fire to nothing
    ddsEnemyFire = NULL
    If ddsGuidedMissile < -1 Then FreeImage ddsGuidedMissile 'guided missiles to nothing
    ddsGuidedMissile = NULL
    If ddsTitle < -1 Then FreeImage ddsTitle 'title to nothing
    ddsTitle = NULL
    If ddsPowerUp < -1 Then FreeImage ddsPowerUp 'power up to nothing
    ddsPowerUp = NULL
    If ddsShieldIndicator < -1 Then FreeImage ddsShieldIndicator 'shield indicator to nothing (getting tired of this yet?)
    ddsShieldIndicator = NULL
    If ddsShip < -1 Then FreeImage ddsShip 'ship to nothing
    ddsShip = NULL
    If ddsExplosion(0) < -1 Then FreeImage ddsExplosion(0) 'explosion to nothing
    ddsExplosion(0) = NULL
    If ddsExplosion(1) < -1 Then FreeImage ddsExplosion(1) 'explosion to nothing
    ddsExplosion(1) = NULL
    If ddsDisplayBomb < -1 Then FreeImage ddsDisplayBomb 'set the bomb surface to nothing
    ddsDisplayBomb = NULL
    If ddsInvulnerable < -1 Then FreeImage ddsInvulnerable 'invulnerable surface to nothing
    ddsInvulnerable = NULL

    'The following lines loop through the arrays
    'and set their surfaces to nothing
    For intCount = 0 To UBound(ddsBackgroundObject)
        If ddsBackgroundObject(intCount) < -1 Then FreeImage ddsBackgroundObject(intCount)
        ddsBackgroundObject(intCount) = NULL
    Next
    For intCount = 0 To UBound(ddsEnemyContainer)
        If ddsEnemyContainer(intCount) < -1 Then FreeImage ddsEnemyContainer(intCount)
        ddsEnemyContainer(intCount) = NULL
    Next
    For intCount = 0 To UBound(ddsObstacle)
        If ddsObstacle(intCount) < -1 Then FreeImage ddsObstacle(intCount)
        ddsObstacle(intCount) = NULL
    Next

    Cls 'restore the display

    'Is there a Segment playing?
    'Stop playing any midi's currently playing
    PlayMIDIFile NULLSTRING
End Sub


'This sub checks the current high scores, and updates it with a new high score
'if the players score is larger than one of the current high scores, then saves
'it to disk
Sub CheckHighScore
    Static lngCount As Long 'standard count variable
    Dim intCount As Long 'another counting variable
    Dim intCount2 As Long 'a second counter variable
    Dim lngTemp As Long 'a temporary variable for storage
    Dim strTemp As String 'temporary string variable for storage

    If boolGettingInput = FALSE Then 'if the player isn't entering a name then
        ClearInput
        boolEnterPressed = FALSE 'the enter key hasn't been pressed
        lngCount = 0 'reset the count
        Do While lngScore < lngHighScore(lngCount) 'loop until we reach the end of the high scores
            lngCount = lngCount + 1 'increment the counter
            If lngCount > 9 Then 'if we reach the end of the high scores
                lngScore = 0 'reset the players score
                PlayMIDIFile "./dat/sfx/mus/title.mid" 'play the title midi
                byteNewHighScore = 255 'set the new high score to no new high score
                Exit Sub 'get out of here
            End If
        Loop
        lngHighScore(9) = lngScore 'if the player does have a high score, assign it to the last place
        boolGettingInput = TRUE 'we are now getting keyboard input
        strName = NULLSTRING 'clear the string
        PlayMIDIFile "./dat/sfx/mus/inbtween.mid" 'play the inbetween levels & title screen midi
    End If

    If boolGettingInput And boolEnterPressed = FALSE Then 'as long as we are getting input, and the player hasn't pressed enter
        If Len(strName) < 14 And strBuffer <> NULLSTRING Then 'if we haven't reached the limit of characters for the name, and the buffer isn't empty then
            If Asc(strBuffer) > 65 Or strBuffer = Chr$(32) Then strName = strName + strBuffer 'if the buffer contains a letter or a space, add it to the buffer
        End If
        DrawStringCenter Str$(lngHighScore(9)) + "  New high score!!!", 200, RGB32(200, 200, 50) 'Display the new high score message
        DrawString 240, 220, "Enter your name: " + strName + Chr$(179), RGB32(200, 200, 50) 'Give the player a cursor, and display the buffer
    ElseIf boolGettingInput And boolEnterPressed Then 'If we are getting input, and the player presses then enter key then
        strHighScoreName(9) = strName 'assign the new high score name the string contained in the buffer
        For intCount = 0 To 9 'loop through the high scores and re-arrange them
            For intCount2 = 0 To 8 'so that the highest scores are on top, and the lowest
                If lngHighScore(intCount2 + 1) > lngHighScore(intCount2) Then 'are on the bottom
                    lngTemp = lngHighScore(intCount2)
                    strTemp = strHighScoreName(intCount2)
                    lngHighScore(intCount2) = lngHighScore(intCount2 + 1)
                    strHighScoreName(intCount2) = strHighScoreName(intCount2 + 1)
                    lngHighScore(intCount2 + 1) = lngTemp
                    strHighScoreName(intCount2 + 1) = strTemp
                End If
            Next
        Next

        For intCount = 0 To 9 'loop through all the high scores
            If lngHighScore(intCount) = lngScore Then byteNewHighScore = intCount 'find the new high score from the list and store it's index
        Next

        lngScore = 0 'reset the score
        SaveHighScores
        boolGettingInput = FALSE 'we are no longer getting input
        PlayMIDIFile "./dat/sfx/mus/title.mid" 'Start the title midi again
    End If

    strBuffer = NULLSTRING 'clear the buffer
    boolEnterPressed = FALSE 'clear the enter toggle
End Sub


'This sub checks to see if there is a power-up on the screen, updates it
'if there is, or see if it is time to create a new power-up.
'If there is a power-up on screen, it paints it, and advances the animation
'frames as needed for the existing power-up
Sub UpdatePowerUps (CreatePowerup As Byte) ' Optional CreatePowerup As Boolean
    Static byteAdvanceFrameOffset As Byte 'counter to advance the animation frames
    Static byteFrameCount As Byte 'holds which animation frame we are on
    Dim intRandomNumber As Long 'variable to hold a random number
    Dim byteFrameOffset As Byte 'offset for animation frames
    Dim intCount As Long 'standard count integer

    If CreatePowerup Then 'If there it is time to create a power-up
        intCount = 0 'reset the count variable
        Do Until PowerUp(intCount).Exists = FALSE 'find an empty power up index
            intCount = intCount + 1 'increment the count
        Loop
        If intCount < UBound(PowerUp) Then 'if there was an empty spot found
            intRandomNumber = Int((900 - 1) * Rnd) + 1 'Create a random number to see which power up
            If intRandomNumber <= 400 Then 'see what value the random number is
                PowerUp(intCount).Index = SHIELD 'make it a shield powerup
            ElseIf intRandomNumber > 400 And intRandomNumber < 600 Then
                PowerUp(intCount).Index = WEAPON 'make it a weapon powerup
            ElseIf intRandomNumber >= 600 And intRandomNumber < 800 Then
                PowerUp(intCount).Index = BOMB 'make it a bomb powerup
            ElseIf intRandomNumber >= 800 And intRandomNumber < 900 Then
                PowerUp(intCount).Index = INVULNERABILITY 'Make it an invulnerability powerup
            End If
            PowerUp(intCount).X = Int(((SCREEN_WIDTH - POWERUPWIDTH) - 1) * Rnd + 1) 'Create the power-up, and set a random X position
            PowerUp(intCount).Y = 0 'Make the power-up start at the top of the screen
            PowerUp(intCount).Exists = TRUE 'The power up now exists
        End If
    End If

    For intCount = 0 To UBound(PowerUp) 'loop through all power ups
        If PowerUp(intCount).Exists Then 'if a power up exists
            If byteAdvanceFrameOffset > 3 Then 'if it is time to increment the animation frame
                If byteFrameCount = 0 Then 'if it is frame 0
                    byteFrameCount = 1 'switch to frame 1
                Else 'otherwise
                    byteFrameCount = 0 'switch to frame 0
                End If
                byteAdvanceFrameOffset = 0 'reset the frame advance count to 0
            Else
                byteAdvanceFrameOffset = byteAdvanceFrameOffset + 1 'otherwise, increment the advance frame counter by 1
            End If

            byteFrameOffset = (POWERUPWIDTH * byteFrameCount) + PowerUp(intCount).Index 'determine the offset for the surfces rectangle

            If PowerUp(intCount).Y + POWERUPHEIGHT > SCREEN_HEIGHT Then 'If the power-up goes off screen,
                PowerUp(intCount).Exists = FALSE 'destroy it
            Else
                PutImage (PowerUp(intCount).X, PowerUp(intCount).Y), ddsPowerUp, , (byteFrameOffset, 0)-(byteFrameOffset + POWERUPWIDTH, POWERUPHEIGHT) 'otherwise, blit it to the back buffer,
            End If

            PowerUp(intCount).Y = PowerUp(intCount).Y + 1.25 'and increment its' Y position
        End If
    Next
End Sub


'This sub creates the explosions that appear when a player destroys an object. The index controls which
'explosion bitmap to play. Player explosion is a flag so the player doesn't get credit for blowing himself up.
'It also adds to the number of enemies the player has killed to be displayed upon level completion.
Sub CreateExplosion (Coordinates As Rectangle2D, ExplosionIndex As Byte, NoCredit As Byte) ' Optional NoCredit As Boolean = False
    Dim lngCount As Long 'Standard count variable

    If NoCredit = FALSE Then 'If the NoCredit flag is not set
        intEnemiesKilled = intEnemiesKilled + 1 'The number of enemies the player has killed that count toward a powerup being triggered is incremented
        lngNumEnemiesKilled = lngNumEnemiesKilled + 1 'The total number of enemies the player has killed is incremented
        If intEnemiesKilled = 25 Then 'If the number of enemies the player has killed exceeds 25, then
            intEnemiesKilled = 0 'Reset the enemies killed power up trigger count to 0
            UpdatePowerUps TRUE 'Trigger a powerup
        End If
    End If

    For lngCount = 0 To UBound(ExplosionDesc) 'loop through the whole explosion array
        If ExplosionDesc(lngCount).Exists = FALSE Then 'if we find an empty array element
            ExplosionDesc(lngCount).ExplosionIndex = ExplosionIndex 'Set the explosion type to the enemys'
            ExplosionDesc(lngCount).Exists = TRUE 'this array element now exists
            ExplosionDesc(lngCount).Frame = 0 'set its' frame to the first one
            ExplosionDesc(lngCount).X = (((Coordinates.right - Coordinates.left) \ 2) + Coordinates.left) - (ExplosionDesc(lngCount).W \ 2) 'assign it the center of the object, at the edge
            ExplosionDesc(lngCount).Y = (((Coordinates.bottom - Coordinates.top) \ 2) + Coordinates.top) - (ExplosionDesc(lngCount).H \ 2) 'assign it the center of the object, along the edge
            Exit Sub
        End If
    Next
End Sub


'This subroutine updates the animation for the large explosions
Sub UpdateExplosions
    Dim lngCount As Long 'count variable
    Dim SrcRect As Rectangle2D 'source rectangle
    Dim lngRightOffset As Long 'offset for the animation rectangle
    Dim lngLeftOffset As Long 'offset for the animation rectangle
    Dim lngTopOffset As Long 'offset for the animation rectangle
    Dim lngBottomOffset As Long 'offset for the animation rectangle
    Dim FinalX As Long 'Final X coordinate for the rectangle
    Dim FinalY As Long 'FInal Y coordinate for the rectangle
    Dim TempY As Long 'Temporary Y position
    Dim TempX As Long 'Temporary X position
    Dim XOffset As Long 'X offset of the animation frame
    Dim YOffset As Long 'Y offset of the animation frame

    For lngCount = 0 To UBound(ExplosionDesc) 'Loop through all explosions
        lngLeftOffset = 0 'Set all the variables to 0
        lngTopOffset = 0 'Set all the variables to 0
        lngBottomOffset = 0 'Set all the variables to 0
        TempX = 0 'Set all the variables to 0
        TempY = 0 'Set all the variables to 0
        XOffset = 0 'Set all the variables to 0
        YOffset = 0 'Set all the variables to 0
        'Set all the variables to 0
        SrcRect.bottom = 0
        SrcRect.top = 0
        SrcRect.left = 0
        SrcRect.right = 0
        If ExplosionDesc(lngCount).Exists = TRUE Then 'If this explosion exists then
            FinalX = ExplosionDesc(lngCount).X 'Start by getting the X coorindate of the explosion
            FinalY = ExplosionDesc(lngCount).Y 'Get the Y coordinate of the explosion
            If ExplosionDesc(lngCount).X + ExplosionDesc(lngCount).W > SCREEN_WIDTH Then
                'If the explosion hangs off the right edge of the screen
                lngRightOffset = (SCREEN_WIDTH - (ExplosionDesc(lngCount).X + ExplosionDesc(lngCount).W)) + ExplosionDesc(lngCount).W
                'Adjust the rectangle to compensate
            Else 'Otherwise
                lngRightOffset = ExplosionDesc(lngCount).W
                'The rectangle width is equal to the width of a single explosion frame
            End If
            If ExplosionDesc(lngCount).X < 0 Then 'If the explosion is off the left hand side of the screen
                lngLeftOffset = Abs(ExplosionDesc(lngCount).X)
                'Adjust the rectangle to compensate
                lngRightOffset = ExplosionDesc(lngCount).W + ExplosionDesc(lngCount).X
                'Adjust the width of the rectangle
                FinalX = 0 'The X coordinate is 0
            End If
            If ExplosionDesc(lngCount).Y + ExplosionDesc(lngCount).H > SCREEN_HEIGHT Then
                'If the bottom of the explosion hangs off the bottom of the screen
                lngBottomOffset = (SCREEN_HEIGHT - (ExplosionDesc(lngCount).Y + ExplosionDesc(lngCount).H)) + ExplosionDesc(lngCount).H
                'Adjust the rectangle to compensate
            Else 'Otherwise
                lngBottomOffset = ExplosionDesc(lngCount).H
                'The explosion rectangle is equal to the height of the explosion
            End If
            If ExplosionDesc(lngCount).Y < 0 Then 'If the explosion hangs off the top of the screen
                lngTopOffset = Abs(ExplosionDesc(lngCount).Y)
                'Adjust the top of the rectangle to compensate
                lngBottomOffset = ExplosionDesc(lngCount).H + ExplosionDesc(lngCount).Y
                'Adjust the height of the rectangle as well
                FinalY = 0 'The Y coordinate is set to 0
            End If

            If ExplosionDesc(lngCount).Frame > ExplosionDesc(lngCount).NumFrames Then
                'If the animation frame goes beyond the number of frames the that the explosion has
                ExplosionDesc(lngCount).Frame = 0 'Reset the frame to the first one
                ExplosionDesc(lngCount).Exists = FALSE 'The explosion no longer exists
                Exit Sub
            End If
            TempY = ExplosionDesc(lngCount).Frame \ 4 'Calculate the left of the rectangle
            TempX = ExplosionDesc(lngCount).Frame - (TempY * 4)
            'Calculate the top of the rectang;e
            XOffset = CLng(TempX * ExplosionDesc(lngCount).W)
            'Calculate the right of the rectangle
            YOffset = CLng(TempY * ExplosionDesc(lngCount).H)
            'Calculate the bottom of the rectangle
            'Place the above calculated values in the rectangle struct
            SrcRect.top = 0 + YOffset + lngTopOffset
            SrcRect.bottom = SrcRect.top + lngBottomOffset
            SrcRect.left = 0 + XOffset + lngLeftOffset
            SrcRect.right = SrcRect.left + lngRightOffset
            If SrcRect.top >= SrcRect.bottom Then Exit Sub
            If SrcRect.left >= SrcRect.right Then Exit Sub

            PutImage (FinalX, FinalY), ddsExplosion(ExplosionDesc(lngCount).ExplosionIndex), , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'Blit the explosion frame to the screen
            ExplosionDesc(lngCount).Frame = ExplosionDesc(lngCount).Frame + 1 'Increment the frame the explosion is on
        End If
    Next

End Sub


'This sub displays all levels, and displays where the player is located with a flashing orange box
Sub ShowMapLocation (OutlineLocation As Byte) ' Optional OutlineLocation As Boolean
    Dim DestRect As Rectangle2D 'Destination rectangle
    Dim CurrentLevelRect As Rectangle2D 'Rectangle for the current level
    Dim intCount As Long 'Count variable
    Dim XOffset As Long 'Offset of the X line
    Dim YOffset As Long 'Offset of the Y line
    Dim XLocation(0 To 8) As Long 'Location X lines
    Dim YLocation(0 To 8) As Long 'Location Y lines

    YOffset = 380 'Beginning offset where the rectangles will be drawn

    For intCount = 0 To UBound(ddsBackgroundObject) 'loop through all background bitmaps
        If intCount Mod 2 = 0 Then 'if this is an even numbered index
            XOffset = 50 'this location's rectangle left is 50
            XLocation(intCount) = 110 'this location's line X is 110
        Else
            XOffset = 510 'this location's rectangle left is 510
            XLocation(intCount) = XOffset 'this location's line X is the same as the xoffset
        End If

        'set up this rectangle using the above coordinate values
        DestRect.top = YOffset
        DestRect.bottom = DestRect.top + 60
        DestRect.left = XOffset
        DestRect.right = DestRect.left + 60

        If intCount = (byteLevel - 1) Then CurrentLevelRect = DestRect 'if the level is equal to the count we are on, store this rectangle for use
        YLocation(intCount) = DestRect.bottom - ((DestRect.bottom - DestRect.top) \ 2) 'calculate the line that will be drawn between the rectangles' Y position
        PutImage (DestRect.left, DestRect.top)-(DestRect.right, DestRect.bottom), ddsBackgroundObject(intCount) 'blit the background to the screen
        Line (DestRect.left, DestRect.top)-(DestRect.right, DestRect.bottom), RGB32(75, 75, 75), B 'draw a box around the bitmap
        YOffset = YOffset - 45 'decrement the Y offset
    Next

    If byteLevel > 1 Then 'if the level is larger than level 1
        For intCount = 1 To (byteLevel - 1) 'loop until we reach the current level
            Line (XLocation(intCount - 1), YLocation(intCount - 1))-(XLocation(intCount), YLocation(intCount)) 'draw a line connecting the last level's index with this level's index
        Next
    End If

    If OutlineLocation Then 'if the sub is called with the OutlineLocation flag set then
        Line (CurrentLevelRect.left, CurrentLevelRect.top)-(CurrentLevelRect.right, CurrentLevelRect.bottom), RGB32(200, 50, 0), B 'draw the orange rectangle around the current level bitmap
    End If
End Sub


'This subroutine displays the introductory text
Sub StartIntro
    Dim strDialog(0 To 25) As String 'store 25 strings
    Dim lngCount As Long 'count variable
    Dim YPosition As Long 'y position for the string location
    Dim ddsSplash As Long 'direct draw surface to hold the background bitmap

    'These lines store the text to be displayed
    strDialog(0) = "As you may know, the unknown alien species has been attacking the Earth for an"
    strDialog(1) = "untold number of years. You have been assigned to the only ship that humankind"
    strDialog(2) = "has been able to build capable of our defense. Reasoning with the aliens"
    strDialog(3) = "has met with silence on their part, and their assault has not stopped."
    strDialog(4) = "Now is the time for all inhabitants of the Earth to put their trust in you."
    strDialog(5) = "You must not let us down."
    strDialog(6) = NULLSTRING
    strDialog(7) = "You will receive the opportunity of grabbing a power-up for every twenty-five"
    strDialog(8) = "alien ships you destroy. We don't have the time to fit your ship with them now,"
    strDialog(9) = "as our outer perimeter space probes have detected a large armada of alien"
    strDialog(10) = "warcraft on a course for our solar system. The weapons have been manufactured"
    strDialog(11) = "to automatically retrofit to your ship. However, the weapons themselves are"
    strDialog(12) = "very sensitive pieces of equipment, and cannot withstand any direct hits that"
    strDialog(13) = "your craft may encounter. A direct hit will result in the last upgrade made to"
    strDialog(14) = "the ship to fail. With that in mind, it is imperative that you avoid getting"
    strDialog(15) = "hit, as the enemy forces are large, and every upgrade you get will make this"
    strDialog(16) = "difficult mission more attainable."
    strDialog(17) = NULLSTRING
    strDialog(18) = "We will warp you to the first entry point of the alien galaxy, and you will"
    strDialog(19) = "journey on a course that leads you through each part of their system,"
    strDialog(20) = "destroying as much of their weaponry and resources as possible along the way."
    strDialog(21) = "At the end of each stage, we have set up warp-jumps that will transport you to"
    strDialog(22) = "the next critical sector. Go now, soldier, and fight so that we may avert the"
    strDialog(23) = "annihilation of the human race."
    strDialog(24) = NULLSTRING
    strDialog(25) = "(Press enter to continue)"

    Cls 'fill the backbuffer with black
    YPosition = 50 'initialize the Y coordinate of the text to 50

    ddsSplash = LoadImage("./dat/gfx/nebulae4.gif") 'create a surface
    PutImage (0, 0)-(SCREEN_WIDTH - 1, SCREEN_HEIGHT - 1), ddsSplash 'blit the surface to the screen
    Do Until lngCount > UBound(strDialog) 'loop through all string arrays
        DrawStringCenter strDialog(lngCount), YPosition, RGB32(151, 150, 150)
        'draw the text to the screen
        YPosition = YPosition + 15 'increment the Y position of the text
        lngCount = lngCount + 1 'increment the count
    Loop

    FadeScreen TRUE 'fade the screen in

    ClearInput

    Do
        If KeyHit = DIK_RETURN Then Exit Do 'if the enter key is pressed, exit the loop
        Delay 0.001 'don't hog the processor
    Loop

    ClearInput

    FadeScreen FALSE 'fade the screen out

    FreeImage ddsSplash 'release all resources for the background bitmap
End Sub


'This sub loads a level and dynamically initializes direct draw objects needed for the level. I also
'shows the statistics of the previous level if there are any.
Sub LoadLevel (level As Long)
    Dim intLowerCount As Long 'lower range count variable
    Dim intUpperCount As Long 'upper range count variable
    Dim FileFree As Long 'holds an available file handle
    Dim intCount As Long 'standard count variable
    Dim intCount2 As Long 'another count variable
    Dim TempString As String 'temporary string variable
    Dim LoadingString As String * 30 'string loaded from the binary level file
    Dim SrcRect As Rectangle2D 'source rectangle structure
    Dim strStats As String 'string to hold statistics
    Dim strNumEnemiesKilled As String 'string to hold the number of enemies killed
    Dim strTotalNumEnemies As String 'string to hold the total number of enemies on the level
    Dim strPercent As String 'string to hold the percentage of the enemies killed
    Dim strBonus As String 'string to display the bonus amount

    Cls 'fill the backbuffer with black
    PlayMIDIFile "./dat/sfx/mus/inbtween.mid" 'play the midi that goes inbetween the title screen and the levels

    If ddsBackgroundObject(byteLevel - 1) < -1 Then
        FreeImage ddsBackgroundObject(byteLevel - 1) 'set the current background object to nothing
        ddsBackgroundObject(byteLevel - 1) = NULL
    End If

    For intCount = 0 To UBound(ddsBackgroundObject) 'loop through all the background objects
        ddsBackgroundObject(intCount) = LoadImage("./dat/gfx/" + BackgroundObject(intCount).PathName) 'Load one of the background bitmaps
        Assert ddsBackgroundObject(intCount) < -1
    Next

    For intCount = 0 To UBound(ddsEnemyContainer) 'Loop through all the enemy surfaces
        If ddsEnemyContainer(intCount) < -1 Then
            FreeImage ddsEnemyContainer(intCount) 'release them if they exist
            ddsEnemyContainer(intCount) = NULL
        End If
    Next

    For intCount = 0 To 30 'Loop through all the obstacle surfaces, except the last ten (which are static, not dynamic)
        If ddsObstacle(intCount) < -1 Then
            FreeImage ddsObstacle(intCount) 'release those also
            ddsObstacle(intCount) = NULL
        End If
    Next

    FileFree = FreeFile 'get a handle to the next available free file
    Open "./dat/map/level" + Trim$(Str$(level)) + ".bin" For Binary Access Read As FileFree 'open the level file for reading

    Get FileFree, , LoadingString 'load the loading string into the LoadingString variable

    For intCount = 0 To 999 'loop through all elements of the sectioncount array
        For intCount2 = 0 To 125
            Get FileFree, , SectionInfo(intCount, intCount2) 'get the SectionInfo information from this record, and put it in the array
        Next
    Next

    For intCount = 0 To 999 'loop through all elements of the ObstacleInfo array
        For intCount2 = 0 To 125
            Get FileFree, , ObstacleInfo(intCount, intCount2) 'get the ObstacleInfo information from this record, and put it in the array
        Next
    Next

    Close FileFree 'close the file

    For intCount = 0 To 999 'loop through the entire SectionInfo array for the level
        For intCount2 = 0 To 125 'there are 126 slots in each section, loop through all of those
            If SectionInfo(intCount, intCount2) < 255 Then 'if the slot value is less than 255, an object exists there
                If ddsEnemyContainer(SectionInfo(intCount, intCount2)) > -2 Then ' if this object hasn't been loaded then (QB64 valid image handles are < -1)
                    ddsEnemyContainer(SectionInfo(intCount, intCount2)) = LoadImageTransparent("./dat/gfx/" + EnemyContainerDesc(SectionInfo(intCount, intCount2)).FileName) 'create this object
                End If
            End If
        Next
    Next
    'We do the exact same thing for the obstacle array
    For intCount = 0 To 999
        For intCount2 = 0 To 125
            If ObstacleInfo(intCount, intCount2) < 255 Then
                If ddsObstacle(ObstacleInfo(intCount, intCount2)) > -2 Then
                    ddsObstacle(ObstacleInfo(intCount, intCount2)) = LoadImageTransparent("./dat/gfx/" + ObstacleContainerInfo(ObstacleInfo(intCount, intCount2)).FileName)
                End If
            End If
        Next
    Next

    'set the source rectangle for the star surface
    SrcRect.top = 0
    SrcRect.bottom = 1
    SrcRect.left = 4
    SrcRect.right = 5

    For intCount = 1 To 500 'loop this 500 times
        intLowerCount = Int((SCREEN_HEIGHT - 1) * Rnd) + 1 'find a random Y coordinate
        intUpperCount = Int((SCREEN_WIDTH - 1) * Rnd) + 1 'find a random X coordinate
        PutImage (intUpperCount, intLowerCount), ddsStar, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'blit a star in to the random coordinates
    Next

    intCount = 1 'set the count variable to 1
    Do While intCount < Len(LoadingString) 'loop until we reach the end of the string
        If Mid$(LoadingString, intCount, 1) = Chr$(0) Then Mid$(LoadingString, intCount, 1) = " "
        'set any null characters in the string to spaces
        intCount = intCount + 1 'increment the count
    Loop

    ShowMapLocation FALSE 'call the sub that shows the location of the player in the enemies galaxy
    strLevelText = LoadingString 'pass the loading string to the strLevelText variable
    strLevelText = Trim$(strLevelText) 'Trim any spaces from the loading string

    If byteLevel > 1 Then 'If the player is has passed level 1 then show statistics for the completed level
        strStats = "Last level statistics" 'Display a message
        strNumEnemiesKilled = "Number of enemies destroyed:" + Str$(lngNumEnemiesKilled)
        'set the string with the number of enemies killed
        strTotalNumEnemies = "Total number of enemies in level:" + Str$(lngTotalNumEnemies)
        'set the string with the total number of enemies on the level
        If lngNumEnemiesKilled > 2 Then 'if the player killed more than 1 enemy then
            strPercent = "Percentage of enemies destroyed:" + Str$(CInt(lngNumEnemiesKilled / lngTotalNumEnemies * 100)) + "%"
            'set the string with  the percentage of enemies killed
            strBonus = "Bonus: 10,000 X" + Str$(CLng(lngNumEnemiesKilled / lngTotalNumEnemies * 100)) + "%" + " =" + Str$(CLng(10000 * (lngNumEnemiesKilled / lngTotalNumEnemies)))
            'set the string with any bonus awarded
            lngScore = lngScore + CLng(10000 * (lngNumEnemiesKilled / lngTotalNumEnemies))
            'add the bonus to the players score
        End If
    End If

    FadeScreen TRUE 'fade the screen in

    intCount = 0 'set the count variable to 0
    Do
        intCount = intCount + 1 'begin incrementing the count
        If intCount > 10 And intCount <= 20 Then 'if the count is currently greater than 10 and less than 20
            ShowMapLocation TRUE 'show the map location, with the current position outlined
        ElseIf intCount <= 10 Then 'if it is less than 10
            ShowMapLocation FALSE 'show the map location with no outline
        End If
        If intCount > 20 Then intCount = 0 'if the count is larger than 20, set it to 0
        If byteLevel > 1 Then 'if the player has passed level 1 then
            DrawStringCenter strStats, 80, RGB32(51, 153, 1)
            'display the statistics
            DrawStringCenter strNumEnemiesKilled, 100, RGB32(51, 153, 1)
            'display the number of enemies killed
            DrawStringCenter strTotalNumEnemies, 120, RGB32(51, 153, 1)
            'display the total number of enemies on the level
            If lngNumEnemiesKilled > 0 Then 'if any enemies have been killed then
                DrawStringCenter strPercent, 140, RGB32(51, 153, 1)
                'display the percentage of enemies killed
                DrawStringCenter strBonus, 160, RGB32(51, 153, 1)
                'display the bonus awarded
            End If
        End If
        TempString = "Next level:  Level" + Str$(byteLevel) 'set the temp string with the next level number
        DrawStringCenter TempString, 200, RGB32(136, 143, 172) 'display the temp string
        DrawStringCenter strLevelText, 220, RGB32(136, 143, 172) 'display the level text
        TempString = "(Press enter to continue)" 'set the temp string with this message
        DrawStringCenter TempString, 450, RGB32(136, 143, 172) 'display the temp string
        If KeyHit = DIK_RETURN Then Exit Do 'if the enter key is pressed
        Delay 0.001 'don't hog the processor
        Display 'flip the direct draw front buffer to display the info
    Loop

    ClearInput

    lngNumEnemiesKilled = 0 'reset the number of enemies killed
    lngTotalNumEnemies = 0 'reset the total number of enemies on the level
    FadeScreen FALSE 'fade the screen to black

    intObjectIndex = byteLevel - 1 'set the background index to the current level number
    If intObjectIndex > UBound(BackgroundObject) Then 'if we go beyond the boundaries of how many objects we have allocated
        boolBackgroundExists = FALSE 'then the background object doesn't exist
        intObjectIndex = 0 'set the index to 0
    Else
        boolBackgroundExists = TRUE 'reset background
        sngBackgroundX = (SCREEN_WIDTH \ 2) - (BackgroundObject(intObjectIndex).W \ 2)
        'set the coorindates of the background object to be centered
        sngBackgroundY = -100 - BackgroundObject(intObjectIndex).H
        'set the starting Y position of the object off the screen
    End If
    For intCount = 0 To UBound(PowerUp)
        PowerUp(intCount).Exists = FALSE 'reset powerups
    Next
    For intCount = 0 To UBound(EnemyDesc) 'reset enemy lasers
        EnemyDesc(intCount).HasFired = FALSE
    Next
    For intCount = 0 To UBound(GuidedMissile) 'reset guided missiles
        GuidedMissile(intCount).Exists = FALSE
    Next
    For intCount = 0 To UBound(LaserDesc) 'reset lasers
        LaserDesc(intCount).Exists = FALSE
    Next
    For intCount = 0 To UBound(Laser2LDesc) 'reset level2 lasers
        Laser2LDesc(intCount).Exists = FALSE
        Laser2RDesc(intCount).Exists = FALSE
    Next
    For intCount = 0 To UBound(Laser3Desc) 'reset level3 lasers
        Laser3Desc(intCount).Exists = FALSE
    Next
    For intCount = 0 To UBound(ExplosionDesc) 'reset explosions
        ExplosionDesc(intCount).Exists = FALSE
    Next

    For intCount = 0 To UBound(ddsBackgroundObject) 'loop through all the backgrounds and
        If ddsBackgroundObject(intCount) < -1 Then
            FreeImage ddsBackgroundObject(intCount) 'set all the backgrounds displayed in the level display screen to nothing to free up some memory
            ddsBackgroundObject(intCount) = NULL
        End If
    Next

    ddsBackgroundObject(byteLevel - 1) = LoadImage("./dat/gfx/" + BackgroundObject(byteLevel - 1).PathName) 'Now we load only the necessary background object
    Assert ddsBackgroundObject(byteLevel - 1) < -1

    'Reset the ships' position and velocity
    Ship.X = 300 'Set X coordinates for ship
    Ship.Y = 300 'Set Y coordinates for ship
    Ship.XVelocity = 0 'the ship has no velocity in the X direction
    Ship.YVelocity = 0 'the ship has no velocity in the Y direction

    SndSetPos dsEnergize, 0 'Set the position of the energize wav to the beginning
    SndPlay dsEnergize 'and then play it
End Sub


'This sub checks to see if the end of the game has been reached, increments the levels if the end of a level is
'reached, and also initializes new enemies and obstacles as they appear in the level
Sub UpdateLevels
    Static NumberEmptySections As Long 'Stores the number of empty sections counted
    Dim intCount As Long 'Count variable
    Dim intCount2 As Long 'Another count variable
    Dim EnemySectionNotEmpty As Byte 'Flag to set if there are no enemies in the section
    Dim ObstacleSectionNotEmpty As Byte 'Flag to set if there are no obstacles in the section
    Dim lngStartTime As Unsigned Long 'The beginning time
    Dim TempInfo As typeBackGroundDesc 'Temporary description variable
    Dim blnTempInfo As Byte 'Temporary flag
    Dim SrcRect As Rectangle2D 'Source rectangle
    Dim lngDelayTime As Unsigned Long 'Stores the amount of delay
    Dim byteIndex As Byte 'Index count variable

    If SectionCount < 0 Then 'If the end of the level is reached
        byteLevel = byteLevel + 1 'Increment the level the player is on
        If byteLevel = 9 Then 'If all levels have been beat
            PlayMIDIFile NULLSTRING 'Stop playing any midi
            SndStop dsAlarm 'Turn off any alarm
            SndStop dsInvulnerability 'Stop any invulnerability sound effect
            Cls 'fill the back buffer with black
            lngStartTime = GetTicks 'grab the current time

            Do While lngStartTime + 8000 > GetTicks 'loop this routine for 8 seconds
                If Int((75 * Rnd) + 1) < 25 Then 'if we get a number that is between 1-25 then
                    intCount = Int((SCREEN_WIDTH * Rnd) + 1) 'get a random X coordinate
                    intCount2 = Int((SCREEN_HEIGHT * Rnd) + 1) 'get a random Y coordinate
                    'Enter the rectangle values
                    SrcRect.top = intCount2
                    SrcRect.bottom = SrcRect.top + 10
                    SrcRect.left = intCount
                    SrcRect.right = SrcRect.left + 10
                    If Int((20 * Rnd) + 1) > 10 Then 'if we get a random number that is greater than ten
                        byteIndex = 1 'set the explosion index to the second explosion
                    Else 'otherwise
                        byteIndex = 0 'set it to the first
                    End If
                    CreateExplosion SrcRect, byteIndex, TRUE 'create the explosion, and we don't give the player any credit for killing an enemy since there are none
                    lngDelayTime = GetTicks 'grab the current time
                    Do While lngDelayTime + 35 > GetTicks 'loop for 35 milliseconds
                        Delay 0.001 'don't hog the processor while looping
                    Loop
                    SndPlayCopy dsExplosion 'play the explosion sound
                End If
                Display 'Flip the front buffer with the back
                Cls 'fill the back buffer with black
                UpdateExplosions 'update the explosions
            Loop

            FadeScreen FALSE 'fade the screen to black

            For intCount = 0 To UBound(ExplosionDesc) 'loop through all explosions
                ExplosionDesc(intCount).Exists = FALSE 'they all no longer exist
            Next
            Cls 'fill the back buffer with black

            'The next lines all display the winning text
            DrawStringCenter "You win!!!", 150, RGB32(135, 119, 8)
            DrawStringCenter "After emerging victorious through 8 different alien galaxies, the enemy has been", 165, RGB32(135, 119, 8)
            DrawStringCenter "driven to the point of near-extinction. Congratulations on a victory well deserved!", 180, RGB32(135, 119, 8)
            DrawStringCenter "You return to Earth, triumphant.", 195, RGB32(135, 119, 8)
            DrawStringCenter "As the peoples of the Earth revel in celebration,", 210, RGB32(135, 119, 8)
            DrawStringCenter "and the world rejoices from relief of the threat of annihalation, you can't help", 225, RGB32(135, 119, 8)
            DrawStringCenter "but ponder... were all of the aliens really destroyed?", 240, RGB32(135, 119, 8)
            DrawStringCenter "The End", 270, RGB32(135, 119, 8)

            FadeScreen TRUE 'fade the screen in
            lngStartTime = GetTicks 'set the start time
            Do While lngStartTime + 20000 > GetTicks 'display the winning message for 20 seconds
                Delay 0.001 'don't hog the processor
            Loop
            FadeScreen FALSE 'fade the screen to black again
            intShields = 100 'shields are at 100%
            Ship.X = 300 'reset the players X
            Ship.Y = 300 'and Y coordinates
            Ship.PowerUpState = 0 'no powerups
            Ship.NumBombs = 0 'no bombs
            Ship.Invulnerable = FALSE 'no longer invulnerable
            Ship.AlarmActive = FALSE 'make sure the low shield alarm is off
            boolStarted = FALSE 'the game hasn't been started
            byteLives = 3 'the player has 3 lives left
            byteLevel = 1 'reset to level 1
            SectionCount = 999 'start at the first section
            NumberEmptySections = 0 'all the sections are filled again
            boolBackgroundExists = FALSE 'a background bitmap no longer exists
            CheckHighScore 'call the sub to see if the player got a high score
            Exit Sub 'exit the sub
        Else 'Otherwise, load a new level
            SndStop dsAlarm 'Stop playing the low shield alarm
            SndStop dsInvulnerability 'Stop playing the invulnerability alarm
            LoadLevel byteLevel 'Load the new level
            SectionCount = 999 'The section count starts at the beginning
            PlayMIDIFile "./dat/sfx/mus/level" + Trim$(Str$(byteLevel)) + ".mid" 'Play the new midi
        End If
    End If

    For intCount = 0 To 125 'Loop through all the slots of this section
        If SectionInfo(SectionCount, intCount) < 255 Then
            'If there is something in the this slot
            Do Until intCount2 > UBound(EnemyDesc) 'Loop through all the enemies
                If EnemyDesc(intCount2).Exists = FALSE Then 'If this index is open
                    If EnemyDesc(intCount2).HasFired Then 'If the old enemy has a weapon that had fired still on the screen
                        blnTempInfo = TRUE 'flag that we need to pass some information to the new enemy
                        TempInfo = EnemyDesc(intCount2) 'store the information on this enemy temporarily
                    Else 'otherwise
                        blnTempInfo = FALSE 'we don't need to give any info to this enemy
                    End If
                    EnemyDesc(intCount2) = EnemyContainerDesc(SectionInfo(SectionCount, intCount))
                    'create the enemy using the enemy template
                    'fill in all the enemy parameters
                    EnemyDesc(intCount2).Index = SectionInfo(SectionCount, intCount)
                    'the enemies index is equal to the value of the slot
                    EnemyDesc(intCount2).Exists = TRUE 'the enemy exists
                    EnemyDesc(intCount2).Y = 0 - EnemyDesc(intCount2).H
                    'set the enemy off the screen using its' height as the offset
                    EnemyDesc(intCount2).X = intCount * 5 'offset the X by the slot we are on
                    EnemyDesc(intCount2).TimesHit = 0 'the enemy has never been hit
                    If blnTempInfo Then 'if the old enemy has fired, pass the info to this enemy
                        EnemyDesc(intCount2).HasFired = TRUE 'this enemy has fired
                        EnemyDesc(intCount2).TargetX = TempInfo.TargetX 'give the enemy the target info of the last one
                        EnemyDesc(intCount2).TargetY = TempInfo.TargetY 'give the enemy the target info of the last one
                        EnemyDesc(intCount2).XFire = TempInfo.XFire 'give the enemy the target info of the last one
                        EnemyDesc(intCount2).YFire = TempInfo.YFire 'give the enemy the target info of the last one
                    End If
                    If Not EnemyDesc(intCount2).Invulnerable Then lngTotalNumEnemies = lngTotalNumEnemies + 1
                    'if this enemy is not invulnerable, increment the total number of enemies the level has
                    Exit Do 'exit the loop
                End If
                intCount2 = intCount2 + 1 'increment the search index
            Loop
            intCount2 = 0 'reset the search index
            EnemySectionNotEmpty = TRUE 'this section is not an empty one
        End If
        intCount2 = 0 'start the count variable at zero
        If ObstacleInfo(SectionCount, intCount) < 255 Then
            'if the obstacle section has something in it
            Do Until intCount2 > UBound(ObstacleDesc) 'loop through all obsctacles
                If ObstacleDesc(intCount2).Exists = FALSE Then
                    'if there is an open slot begin filling in the info for this obstacle
                    If ObstacleDesc(intCount2).HasFired Then
                        'if the obstacle has fired
                        blnTempInfo = TRUE 'flag that we have info to pass to the new obstacle
                        TempInfo = ObstacleDesc(intCount2) 'store the information about this obstacle
                    Else 'otherwise
                        blnTempInfo = FALSE 'we don't have info to pass on
                    End If
                    ObstacleDesc(intCount2) = ObstacleContainerInfo(ObstacleInfo(SectionCount, intCount))
                    'fill in the info on the new obstacle using the obstacle's template
                    'fill in the dynamic values
                    ObstacleDesc(intCount2).Index = ObstacleInfo(SectionCount, intCount)
                    'the index of this obsacle is stored in the slot value
                    ObstacleDesc(intCount2).Exists = TRUE 'the obstacle exists
                    ObstacleDesc(intCount2).Y = -80 'set the obstacle off the top of the screen by 80 pixels
                    ObstacleDesc(intCount2).X = intCount * 5 'set the offset of the X position of the obstacle
                    If blnTempInfo Then 'if there is info to pass to the new obstacle
                        ObstacleDesc(intCount2).HasFired = TRUE 'then the obstacle has fired
                        ObstacleDesc(intCount2).TargetX = TempInfo.TargetX 'fill in the fire information
                        ObstacleDesc(intCount2).TargetY = TempInfo.TargetY 'fill in the fire information
                        ObstacleDesc(intCount2).XFire = TempInfo.XFire 'fill in the fire information
                        ObstacleDesc(intCount2).YFire = TempInfo.YFire 'fill in the fire information
                    End If
                    If Not ObstacleDesc(intCount2).Invulnerable Then lngTotalNumEnemies = lngTotalNumEnemies + 1
                    'if this obstacle is not invulnerable, increment the total number of enemies on this level
                    Exit Do 'exit the loop
                End If
                intCount2 = intCount2 + 1 'increment the count index
            Loop
            intCount2 = 0 'reset the count variable
            ObstacleSectionNotEmpty = TRUE 'the obstacle section isn't empty
        End If
    Next

    If ObstacleSectionNotEmpty = FALSE And EnemySectionNotEmpty = FALSE Then
        'if the both sections are empty then
        NumberEmptySections = NumberEmptySections + 1 'increment the number of empty sections
        If NumberEmptySections = 40 Then 'if 40 empty sections are reached
            SectionCount = 0 'set the section count to 0
            NumberEmptySections = 0 'set the number of empty sections to 0
        End If
    Else
        NumberEmptySections = 0 'otherwise, reset the number of empty sections to 0
    End If
End Sub


'This sub fires the players weapons, and plays the associated wavefile
Sub FireWeapon
    Static byteLaserCounter As Byte 'variable to hold the number of times this sub has been called to determine if it is time to let another laser be created
    Static byteGuidedMissileCounter As Byte 'variable to hold the number of times this sub has been called to determine if it is time to let another guided missile be created
    Static byteLaser2Counter As Byte 'variable to hold the number of times this sub has been called to determine if it is time to let another level2 laser (left side) be created
    Static byteLaser3Counter As Byte 'variable to hold the number of times this sub has been called to determine if it is time to let another level2 laser (right side) be created
    Dim intCount As Long 'Standard count variable for loops

    'Stage 1 laser
    intCount = 0 'reset the count loop variable
    byteLaserCounter = byteLaserCounter + 1 'increment the number of lasers by 1
    If byteLaserCounter = 5 Then 'if we have looped through the sub 5 times
        Do Until intCount > UBound(LaserDesc) ' TODO: Why was this 7? - loop through all the lasers
            If LaserDesc(intCount).Exists = FALSE Then 'and see if there is an empty slot, and if there is
                'create a new laser description
                LaserDesc(intCount).Exists = TRUE 'the laser exists
                LaserDesc(intCount).X = Ship.X + ((SHIPWIDTH \ 2) - (LASER1WIDTH \ 2))
                'center the laser fire
                LaserDesc(intCount).Y = Ship.Y 'the laser starts at the same Y as the ship
                LaserDesc(intCount).Damage = 1 'the amount of damage this laser does

                SndSetPos dsLaser, 0 'set the position of the buffer to 0
                SndBal dsLaser, (2 * (Ship.X + SHIPWIDTH / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'pan the sound according to the ships location
                SndPlay dsLaser 'play the laser sound

                Exit Do 'exit the do loop
            End If
            intCount = intCount + 1 'incrementing the count
        Loop 'loop until we find an empty slot
        byteLaserCounter = 0 'reset the counter to 0
    End If

    If Ship.PowerUpState > 0 Then 'Guided missiles
        intCount = 0 'reset the count variable
        byteGuidedMissileCounter = byteGuidedMissileCounter + 1 'increment the counter
        If byteGuidedMissileCounter = 20 Then 'if we called the sub 20 times, then
            Do Until intCount > UBound(GuidedMissile) 'loop through all the guided missile types
                If GuidedMissile(intCount).Exists = FALSE Then 'if we find an empty slot
                    'create a new guided missile
                    GuidedMissile(intCount).Exists = TRUE 'the guided missile exists
                    GuidedMissile(intCount).X = Ship.X + (SHIPWIDTH / 2) 'center the x coordinate
                    GuidedMissile(intCount).Y = Ship.Y + (SHIPHEIGHT / 2) 'center the y coordinate
                    GuidedMissile(intCount).XVelocity = 0 'set the velocity to 0
                    GuidedMissile(intCount).YVelocity = -4.5 'set the y velocity to 4.5 pixels every frame
                    GuidedMissile(intCount).Damage = 3 'the guided missile does 3 points of damage
                    Exit Do 'exit the do loop
                End If
                intCount = intCount + 1 'increment the count
            Loop
            byteGuidedMissileCounter = 0 'reset the guided missile counter
        End If
    End If

    'The rest of the weapons are handled in just about the same manner as these were. You should be able to find
    'the similarities and figure out what is going on from there.

    If Ship.PowerUpState > 1 Then 'Stage 2 lasers, this weapon shoots lasers diagonally from the ship
        intCount = 0
        byteLaser2Counter = byteLaser2Counter + 1
        If byteLaser2Counter > 15 Then
            byteLaser2Counter = 0
            Do Until intCount > UBound(Laser2RDesc)
                If Laser2RDesc(intCount).Exists = FALSE Then
                    Laser2RDesc(intCount).Exists = TRUE
                    Laser2RDesc(intCount).X = (Ship.X + SHIPWIDTH) - 15
                    Laser2RDesc(intCount).Y = Ship.Y + 14
                    Laser2RDesc(intCount).XVelocity = 0 + (LASERSPEED - 4)
                    Laser2RDesc(intCount).YVelocity = 0 - LASERSPEED
                    Laser2RDesc(intCount).Damage = 1

                    SndPlayCopy dsLaser2, , (2 * (Ship.X + SHIPWIDTH / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)

                    Exit Do
                End If
                intCount = intCount + 1
            Loop

            Do Until intCount > UBound(Laser2LDesc)
                If Laser2LDesc(intCount).Exists = FALSE Then
                    Laser2LDesc(intCount).Exists = TRUE
                    Laser2LDesc(intCount).X = Ship.X + 5
                    Laser2LDesc(intCount).Y = Ship.Y + 14
                    Laser2LDesc(intCount).XVelocity = 0 - (LASERSPEED - 4)
                    Laser2LDesc(intCount).YVelocity = 0 - LASERSPEED
                    Laser2LDesc(intCount).Damage = 1

                    SndPlayCopy dsLaser2, , (2 * (Ship.X + SHIPWIDTH / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)

                    Exit Do
                End If
                intCount = intCount + 1
            Loop
        End If
    End If

    If Ship.PowerUpState > 2 Then 'Plasma pulse cannon, this is the only weapon that is not stopped by objects
        intCount = 0
        byteLaser3Counter = byteLaser3Counter + 1
        If byteLaser3Counter = 35 Then
            Do Until intCount > UBound(Laser3Desc)
                If Laser3Desc(intCount).Exists = FALSE Then
                    Laser3Desc(intCount).Exists = TRUE
                    Laser3Desc(intCount).X = Ship.X + ((SHIPWIDTH \ 2) - (Laser3Desc(intCount).W \ 2))
                    Laser3Desc(intCount).Y = Ship.Y
                    Laser3Desc(intCount).YVelocity = (LASERSPEED + 1.5)
                    Laser3Desc(intCount).Damage = 2

                    SndSetPos dsPulseCannon, 0
                    SndBal dsPulseCannon, (2 * (Ship.X + SHIPWIDTH / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)
                    SndPlay dsPulseCannon

                    Exit Do
                End If
                intCount = intCount + 1
            Loop
            byteLaser3Counter = 0
        End If
    End If
End Sub


'This function takes two rectangles and determines if they overlap each other
Function DetectCollision%% (r1 As Rectangle2D, r2 As Rectangle2D)
    DetectCollision = Not (r1.left > r2.right Or r2.left > r1.right Or r1.top > r2.bottom Or r2.top > r1.bottom)
End Function


'This sub creates, destroys, and updates small explosions for when the player hits an object or is hit
'It also plays a small "no hit" sound effect
Sub UpdateHits (NewHit As Byte, x As Long, y As Long) ' Optional NewHit As Boolean = False, Optional x As Long, Optional y As Long
    Dim intCount As Long 'Count variable

    If NewHit Then 'If this is a new hit
        For intCount = 0 To UBound(HitDesc) 'Loop through the hit array
            If HitDesc(intCount).Exists = FALSE Then 'If we find a spot that is free
                'Add in the coordinates of the new hit
                HitDesc(intCount).Exists = TRUE 'This hit now exists
                HitDesc(intCount).X = x - 2 'Center the x if the hit
                HitDesc(intCount).Y = y 'The Y of the hit

                SndPlayCopy dsNoHit, , (2 * (HitDesc(intCount).X + 1) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'Play the sound effect

                Exit For
            End If
        Next
    Else 'Otherwise, if this is updating an existing hit
        For intCount = 0 To UBound(HitDesc) 'Loop through the hit array
            If HitDesc(intCount).Exists Then 'If this hit exists
                If HitDesc(intCount).Index > HitDesc(intCount).NumFrames Then
                    'If the current frame is larger than the number of frames the hit animation has
                    HitDesc(intCount).Exists = FALSE 'The hit no longer exists
                    HitDesc(intCount).Index = 0 'Set the frame of the hit to 0
                Else 'Otherwise, the hit animation frame needs to be displayed
                    If HitDesc(intCount).X > 0 And HitDesc(intCount).X < (SCREEN_WIDTH - HitDesc(intCount).W) And HitDesc(intCount).Y > 0 And HitDesc(intCount).Y < (SCREEN_HEIGHT - HitDesc(intCount).H) Then
                        'If the hit is on screen
                        PutImage (HitDesc(intCount).X, HitDesc(intCount).Y), ddsHit 'blit the hit to the screen
                    End If
                    HitDesc(intCount).Index = HitDesc(intCount).Index + 1 'increment the animation
                End If
            End If
        Next
    End If
End Sub


'This sub checks all objects on the screen to see if they are colliding,
'increments points, and plays sounds effects.
'This also is the largest sub in the program, since it has to increment through
'everything on the screen
Sub CheckForCollisions
    Dim SrcRect As Rectangle2D 'rect structure
    Dim SrcRect2 As Rectangle2D 'another rect structure
    Dim intCount As Long 'counter for loops
    Dim intCount2 As Long 'second loop counter
    Dim ShipRect As Rectangle2D 'holds the position of the player
    'TODO: Dim ddTempBltFx As DDBLTFX                                                      'used to hold info about the special effects for flashing the screen when something is hit
    Dim TempDesc As typeBackGroundDesc
    Dim blnTempDesc As Byte

    'TODO: ddTempBltFx.lFill = 143 ' Index 143 in the palette is bright red used to fill the screen with red when the player is hit.

    'define the rectangle for the player
    ShipRect.top = Ship.Y 'get the Y coordinate of the player
    ShipRect.bottom = ShipRect.top + (SHIPHEIGHT - 15) 'make sure not to include the flames from the bottom of the ship
    ShipRect.left = Ship.X + 10 'make sure to not include the orbiting elements
    ShipRect.right = ShipRect.left + (SHIPWIDTH - 10) 'same thing, but on the right

    For intCount = 0 To UBound(PowerUp)
        'define the coordinates for the powerups
        SrcRect.top = PowerUp(intCount).Y
        SrcRect.bottom = SrcRect.top + POWERUPHEIGHT
        SrcRect.left = PowerUp(intCount).X
        SrcRect.right = SrcRect.left + POWERUPWIDTH

        If PowerUp(intCount).Exists And DetectCollision(ShipRect, SrcRect) Then 'if the power up exists, and the player has collided with it
            If PowerUp(intCount).Index = SHIELD Then 'if it is a shield powerup
                intShields = intShields + 20 'increase the shields by 20
                lngScore = lngScore + 100 'player gets a 100 points for this
                If intShields > 100 Then intShields = 100 'if the shields are already maxed out, make sure it doesn't go beyond max
                PowerUp(intCount).Exists = FALSE 'the power up no longer exists
                SndSetPos dsPowerUp, 0 'set the playback buffer position to 0
                SndPlay dsPowerUp 'play the wav
                Exit Sub
            ElseIf PowerUp(intCount).Index = WEAPON Then 'if the powerup is a weapon powerup
                If Ship.PowerUpState < 3 Then Ship.PowerUpState = Ship.PowerUpState + 1
                'if the powerups reach 3, make sure it doesn't go any higher than that
                lngScore = lngScore + 200 'player gets 200 points for this
                PowerUp(intCount).Exists = FALSE 'the power up no longer exists
                SndSetPos dsPowerUp, 0 'set the playback buffer position to 0
                SndPlay dsPowerUp 'play the wav
                Exit Sub
            ElseIf PowerUp(intCount).Index = BOMB Then 'the power up is a bomb powerup
                If Ship.NumBombs < 5 Then Ship.NumBombs = Ship.NumBombs + 1 'if we haven't reached the maxiumum number of bomb, increase the number of bombs the player has
                lngScore = lngScore + 200 'give the player a score increase, even if the bombs are at max
                PowerUp(intCount).Exists = FALSE 'the power up no longer exists
                SndSetPos dsPowerUp, 0 'set the playback buffer position to 0
                SndPlay dsPowerUp 'play the wav
                Exit Sub 'exit the sub
            ElseIf PowerUp(intCount).Index = INVULNERABILITY Then 'the power up is an invulnerability power up
                Ship.Invulnerable = TRUE 'set the ships' invulnerable flag
                Ship.InvulnerableTime = GetTicks + 15000 'set the duration of the invulnerability
                lngScore = lngScore + 500
                PowerUp(intCount).Exists = FALSE
                SndSetPos dsPowerUp, 0 'set the playback buffer position to 0
                SndPlay dsPowerUp 'play the wav
                SndSetPos dsInvulnerability, 0 'set the playback buffer position to 0
                SndLoop dsInvulnerability 'play the wav
            End If
        End If
    Next

    For intCount = 0 To UBound(EnemyDesc) 'loop through the entire enemy array
        If EnemyDesc(intCount).Exists = TRUE Then 'if the enemy exists
            'define the rectangle coordinates of the enemy
            SrcRect.top = EnemyDesc(intCount).Y
            SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
            SrcRect.left = EnemyDesc(intCount).X
            SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

            If DetectCollision(SrcRect, ShipRect) Then 'if the enemy ship collides with the player

                SndPlayCopy dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                'TODO: If IsFF = True Then ef(1).start 1, 0                                'If force feedback is enabled, start the effect

                If Not EnemyDesc(intCount).Invulnerable Then EnemyDesc(intCount).Exists = FALSE
                'if the enemy isn't invulnerable the enemy is destroyed
                CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, FALSE 'Call the create explosion sub with the rect coordinates, and the index of the explosion type
                If Not Ship.Invulnerable Then 'If the ship is not invulnerable then
                    intShields = intShields - EnemyDesc(intCount).CollisionDamage 'take points off the shields for colliding with the enemy
                    If Ship.PowerUpState > 0 Then 'reduce a powerup level if the player has one
                        Ship.PowerUpState = Ship.PowerUpState - 1
                    End If
                End If
                lngScore = lngScore + EnemyDesc(intCount).Score 'add the score value of this enemy to the players score
                Exit Sub
            End If
        End If
        If EnemyDesc(intCount).HasFired Then 'Determine if the enemy laser fire hit player
            'define coordinates of enemy weapon fire
            SrcRect.top = EnemyDesc(intCount).YFire
            SrcRect.bottom = SrcRect.top + 5
            SrcRect.left = EnemyDesc(intCount).XFire
            SrcRect.right = SrcRect.left + 5

            If DetectCollision(SrcRect, ShipRect) Then 'if the enemy weapon fire hits the player then
                EnemyDesc(intCount).HasFired = FALSE 'the enemy weapon fire is destroyed
                If Not Ship.Invulnerable Then
                    intShields = intShields - 5 'subtract 5 from the playres shields
                    If Ship.PowerUpState > 0 Then 'if the player has a power up,
                        Ship.PowerUpState = Ship.PowerUpState - 1 'knock it down a level
                    End If
                End If
                UpdateHits TRUE, CLng(EnemyDesc(intCount).XFire), CLng(EnemyDesc(intCount).YFire)
                'Call the sub that displays a small explosion bitmap where the player was hit
                'TODO: If IsFF = True Then ef(1).start 1, 0                                'If force feeback is enabled, start the effect
                Exit Sub
            End If
        End If
    Next

    For intCount = 0 To UBound(ObstacleDesc)
        If ObstacleDesc(intCount).HasFired Then 'Determine if the obstacle laser fire hit player
            ' Define coordinates of obstacle weapon fire
            SrcRect.top = ObstacleDesc(intCount).YFire
            SrcRect.bottom = SrcRect.top + 5
            SrcRect.left = ObstacleDesc(intCount).XFire
            SrcRect.right = SrcRect.left + 5

            If DetectCollision(SrcRect, ShipRect) Then 'if the obstacle weapon fire hits the player then
                ObstacleDesc(intCount).HasFired = FALSE 'the obstacle weapon fire is destroyed
                If Not Ship.Invulnerable Then 'If the player isn't invulnerable then
                    intShields = intShields - 5 'subtract 5 from the playres shields
                    If Ship.PowerUpState > 0 Then 'if the player has a power up,
                        Ship.PowerUpState = Ship.PowerUpState - 1 'knock it down a level
                    End If
                End If
                UpdateHits TRUE, CLng(ObstacleDesc(intCount).XFire), CLng(ObstacleDesc(intCount).YFire) 'Small explosion sub
                Exit Sub
            End If
        End If
    Next

    For intCount2 = 0 To UBound(LaserDesc) 'Collision detection for stage 1 laser
        If LaserDesc(intCount2).Exists Then 'If this index of the laser is on screen
            'Define the coordinates of the rectangle
            SrcRect2.top = LaserDesc(intCount2).Y
            SrcRect2.bottom = SrcRect2.top + LaserDesc(intCount2).H
            SrcRect2.left = LaserDesc(intCount2).X
            SrcRect2.right = SrcRect2.left + LaserDesc(intCount2).W

            For intCount = 0 To UBound(EnemyDesc) 'Loop through all the enemies
                If EnemyDesc(intCount).Exists Then 'If this enemy is on the screen then
                    'Define this enemies coordinates
                    SrcRect.top = EnemyDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
                    SrcRect.left = EnemyDesc(intCount).X
                    SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

                    If DetectCollision(SrcRect, SrcRect2) Then 'If this enemy is struck by the weapon
                        EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + LaserDesc(intCount2).Damage
                        'Subtract the amount of damage the weapon does from the enemy
                        If EnemyDesc(intCount).TimesHit > EnemyDesc(intCount).TimesDies And Not EnemyDesc(intCount).Invulnerable Then
                            'If the number of times the enemy has been hit is greater than
                            'the amount of times the enemy can be hit, then
                            lngScore = lngScore + EnemyDesc(intCount).Score 'add the score value of this enemy to the players score

                            SndPlayCopy dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            EnemyDesc(intCount).Exists = FALSE 'This enemy no longer exists
                            LaserDesc(intCount2).Exists = FALSE 'The players weapon fire no longer exists
                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, FALSE
                            Exit Sub
                        Else 'If the enemy is still alive, then
                            UpdateHits TRUE, SrcRect2.left, SrcRect2.top
                            LaserDesc(intCount2).Exists = FALSE 'The players weapon fire no longer exists
                            Exit Sub
                        End If
                    End If
                End If
            Next

            For intCount = 0 To UBound(ObstacleDesc) 'Loop through all the obstacles
                If ObstacleDesc(intCount).Exists And Not ObstacleDesc(intCount).Invulnerable Then
                    'If this obstacle is on the screen then
                    'Define this enemies coordinates
                    SrcRect.top = ObstacleDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + ObstacleDesc(intCount).H
                    SrcRect.left = ObstacleDesc(intCount).X
                    SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                    If DetectCollision(SrcRect, SrcRect2) Then 'If this obstacle is struck by the weapon
                        ObstacleDesc(intCount).TimesHit = ObstacleDesc(intCount).TimesHit + LaserDesc(intCount2).Damage
                        'Subtract the amount of damage the weapon does from the obstacle
                        If ObstacleDesc(intCount).TimesHit > ObstacleDesc(intCount).TimesDies Then
                            'If the number of times the obstacle has been hit is greater than
                            'the amount of times the obstacle can be hit, then
                            lngScore = lngScore + ObstacleDesc(intCount).Score 'add the score value of this obstacle to the players score

                            SndPlayCopy dsExplosion, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            If ObstacleDesc(intCount).HasFired Then
                                TempDesc = ObstacleDesc(intCount)
                                blnTempDesc = TRUE
                            Else
                                blnTempDesc = FALSE
                            End If
                            If ObstacleDesc(intCount).HasDeadIndex Then
                                ObstacleDesc(intCount) = ObstacleContainerInfo(ObstacleDesc(intCount).DeadIndex)
                                ObstacleDesc(intCount).Exists = TRUE
                                ObstacleDesc(intCount).X = SrcRect.left
                                ObstacleDesc(intCount).Y = SrcRect.top
                                ObstacleDesc(intCount).Index = ObstacleDesc(intCount).DeadIndex
                                If blnTempDesc Then
                                    ObstacleDesc(intCount).XFire = TempDesc.XFire
                                    ObstacleDesc(intCount).YFire = TempDesc.YFire
                                    ObstacleDesc(intCount).TargetX = TempDesc.TargetX
                                    ObstacleDesc(intCount).TargetY = TempDesc.TargetY
                                End If
                            Else
                                ObstacleDesc(intCount).Exists = FALSE
                            End If
                            LaserDesc(intCount2).Exists = FALSE 'The players weapon fire no longer exists
                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, FALSE
                            Exit Sub
                        Else 'If the obstacle is still alive, then
                            UpdateHits TRUE, SrcRect2.left, SrcRect2.top
                            LaserDesc(intCount2).Exists = FALSE 'The players weapon fire no longer exists
                            Exit Sub
                        End If
                    End If
                End If
            Next
        End If
    Next

    'The rest of the collision detection is pretty much the same. Loop through whatever it is
    'that needs to be checked, set up the source rectangle, set up the 2nd source, check if they
    'collide, and handle it appropriately. With the above comments, you should be able to figure out
    'what the rest is doing.

    For intCount2 = 0 To UBound(Laser2RDesc)
        If Laser2RDesc(intCount2).Exists Then

            SrcRect2.top = Laser2RDesc(intCount2).Y
            SrcRect2.bottom = SrcRect2.top + LASER2HEIGHT
            SrcRect2.left = Laser2RDesc(intCount2).X
            SrcRect2.right = SrcRect2.left + LASER2WIDTH

            For intCount = 0 To UBound(EnemyDesc)
                If EnemyDesc(intCount).Exists Then

                    SrcRect.top = EnemyDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
                    SrcRect.left = EnemyDesc(intCount).X
                    SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

                    If DetectCollision(SrcRect, SrcRect2) Then
                        EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + Laser2RDesc(intCount2).Damage
                        If EnemyDesc(intCount).TimesHit > EnemyDesc(intCount).TimesDies And Not EnemyDesc(intCount).Invulnerable Then
                            lngScore = lngScore + EnemyDesc(intCount).Score

                            SndPlayCopy dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            EnemyDesc(intCount).Exists = FALSE
                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, FALSE
                            Laser2RDesc(intCount2).Exists = FALSE
                            Exit Sub
                        Else
                            Laser2RDesc(intCount2).Exists = FALSE
                            UpdateHits TRUE, SrcRect2.left, SrcRect.top
                            Exit Sub
                        End If
                    End If
                End If
            Next

            For intCount = 0 To UBound(ObstacleDesc)
                If ObstacleDesc(intCount).Exists And Not ObstacleDesc(intCount).Invulnerable Then

                    SrcRect.top = ObstacleDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + ObstacleDesc(intCount).H
                    SrcRect.left = ObstacleDesc(intCount).X
                    SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                    If DetectCollision(SrcRect, SrcRect2) Then
                        ObstacleDesc(intCount).TimesHit = ObstacleDesc(intCount).TimesHit + Laser2RDesc(intCount2).Damage
                        If ObstacleDesc(intCount).TimesHit > ObstacleDesc(intCount).TimesDies Then
                            lngScore = lngScore + ObstacleDesc(intCount).Score

                            SndPlayCopy dsExplosion, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            If ObstacleDesc(intCount).HasFired Then
                                TempDesc = ObstacleDesc(intCount)
                                blnTempDesc = TRUE
                            Else
                                blnTempDesc = FALSE
                            End If
                            If ObstacleDesc(intCount).HasDeadIndex Then
                                ObstacleDesc(intCount) = ObstacleContainerInfo(ObstacleDesc(intCount).DeadIndex)
                                ObstacleDesc(intCount).Exists = TRUE
                                ObstacleDesc(intCount).X = SrcRect.left
                                ObstacleDesc(intCount).Y = SrcRect.top
                                ObstacleDesc(intCount).Index = ObstacleDesc(intCount).DeadIndex
                                If blnTempDesc Then
                                    ObstacleDesc(intCount).XFire = TempDesc.XFire
                                    ObstacleDesc(intCount).YFire = TempDesc.YFire
                                    ObstacleDesc(intCount).TargetX = TempDesc.TargetX
                                    ObstacleDesc(intCount).TargetY = TempDesc.TargetY
                                End If
                            Else
                                ObstacleDesc(intCount).Exists = FALSE
                            End If
                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, FALSE
                            Laser2RDesc(intCount2).Exists = FALSE
                            Exit Sub
                        Else
                            Laser2RDesc(intCount2).Exists = FALSE
                            UpdateHits TRUE, SrcRect2.left, SrcRect.top
                            Exit Sub
                        End If
                    End If
                End If
            Next
        End If
    Next

    For intCount2 = 0 To UBound(Laser2LDesc)
        If Laser2LDesc(intCount2).Exists Then

            SrcRect2.top = Laser2LDesc(intCount2).Y
            SrcRect2.bottom = SrcRect2.top + LASER2HEIGHT
            SrcRect2.left = Laser2LDesc(intCount2).X
            SrcRect2.right = SrcRect2.left + LASER2WIDTH

            For intCount = 0 To UBound(EnemyDesc)
                If EnemyDesc(intCount).Exists Then

                    SrcRect.top = EnemyDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
                    SrcRect.left = EnemyDesc(intCount).X
                    SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

                    If DetectCollision(SrcRect, SrcRect2) Then
                        EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + Laser2LDesc(intCount2).Damage
                        If EnemyDesc(intCount).TimesHit > EnemyDesc(intCount).TimesDies And Not EnemyDesc(intCount).Invulnerable Then
                            lngScore = lngScore + EnemyDesc(intCount).Score

                            SndPlayCopy dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            EnemyDesc(intCount).Exists = FALSE
                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, FALSE
                            Laser2LDesc(intCount2).Exists = FALSE
                            Exit Sub
                        Else
                            Laser2LDesc(intCount2).Exists = FALSE
                            UpdateHits TRUE, SrcRect2.left, SrcRect.top
                            Exit Sub
                        End If
                    End If
                End If
            Next

            For intCount = 0 To UBound(ObstacleDesc)
                If ObstacleDesc(intCount).Exists And Not ObstacleDesc(intCount).Invulnerable Then

                    SrcRect.top = ObstacleDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + ObstacleDesc(intCount).H
                    SrcRect.left = ObstacleDesc(intCount).X
                    SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                    If DetectCollision(SrcRect, SrcRect2) Then
                        ObstacleDesc(intCount).TimesHit = ObstacleDesc(intCount).TimesHit + Laser2LDesc(intCount2).Damage
                        If ObstacleDesc(intCount).TimesHit > ObstacleDesc(intCount).TimesDies Then
                            lngScore = lngScore + ObstacleDesc(intCount).Score

                            SndPlayCopy dsExplosion, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            If ObstacleDesc(intCount).HasFired Then
                                TempDesc = ObstacleDesc(intCount)
                                blnTempDesc = TRUE
                            Else
                                blnTempDesc = FALSE
                            End If
                            If ObstacleDesc(intCount).HasDeadIndex Then
                                ObstacleDesc(intCount) = ObstacleContainerInfo(ObstacleDesc(intCount).DeadIndex)
                                ObstacleDesc(intCount).Exists = TRUE
                                ObstacleDesc(intCount).X = SrcRect.left
                                ObstacleDesc(intCount).Y = SrcRect.top
                                ObstacleDesc(intCount).Index = ObstacleDesc(intCount).DeadIndex
                                If blnTempDesc Then
                                    ObstacleDesc(intCount).XFire = TempDesc.XFire
                                    ObstacleDesc(intCount).YFire = TempDesc.YFire
                                    ObstacleDesc(intCount).TargetX = TempDesc.TargetX
                                    ObstacleDesc(intCount).TargetY = TempDesc.TargetY
                                End If
                            Else
                                ObstacleDesc(intCount).Exists = FALSE
                            End If
                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, FALSE
                            Laser2LDesc(intCount2).Exists = FALSE
                            Exit Sub
                        Else
                            Laser2LDesc(intCount2).Exists = FALSE
                            UpdateHits TRUE, SrcRect2.left, SrcRect.top
                            Exit Sub
                        End If
                    End If
                End If
            Next
        End If
    Next

    For intCount2 = 0 To UBound(Laser3Desc)
        If Laser3Desc(intCount2).Exists Then

            SrcRect2.top = Laser3Desc(intCount2).Y
            SrcRect2.bottom = SrcRect2.top + Laser3Desc(intCount2).H
            SrcRect2.left = Laser3Desc(intCount2).X
            SrcRect2.right = SrcRect2.left + Laser3Desc(intCount2).W

            For intCount = 0 To UBound(EnemyDesc)
                If EnemyDesc(intCount).Exists Then

                    SrcRect.top = EnemyDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
                    SrcRect.left = EnemyDesc(intCount).X
                    SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

                    If DetectCollision(SrcRect, SrcRect2) And Laser3Desc(intCount2).StillColliding = FALSE Then
                        Laser3Desc(intCount2).StillColliding = TRUE
                        EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + Laser3Desc(intCount2).Damage
                        If EnemyDesc(intCount).TimesHit > EnemyDesc(intCount).TimesDies And Not EnemyDesc(intCount).Invulnerable Then
                            lngScore = lngScore + EnemyDesc(intCount).Score

                            SndPlayCopy dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, FALSE
                            EnemyDesc(intCount).Exists = FALSE
                            Exit Sub
                        Else
                            UpdateHits TRUE, SrcRect2.left, SrcRect2.top
                            Exit Sub
                        End If
                    ElseIf DetectCollision(SrcRect, SrcRect2) = FALSE And Laser3Desc(intCount2).StillColliding = TRUE Then
                        Laser3Desc(intCount2).StillColliding = FALSE
                    End If
                End If
            Next

            For intCount = 0 To UBound(ObstacleDesc)
                If ObstacleDesc(intCount).Exists And Not ObstacleDesc(intCount).Invulnerable Then

                    SrcRect.top = ObstacleDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + ObstacleDesc(intCount).H
                    SrcRect.left = ObstacleDesc(intCount).X
                    SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                    If DetectCollision(SrcRect, SrcRect2) And Laser3Desc(intCount2).StillColliding = FALSE Then
                        Laser3Desc(intCount2).StillColliding = TRUE
                        ObstacleDesc(intCount).TimesHit = ObstacleDesc(intCount).TimesHit + Laser3Desc(intCount2).Damage
                        If ObstacleDesc(intCount).TimesHit > ObstacleDesc(intCount).TimesDies Then
                            lngScore = lngScore + ObstacleDesc(intCount).Score

                            SndPlayCopy dsExplosion, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, FALSE
                            If ObstacleDesc(intCount).HasFired Then
                                TempDesc = ObstacleDesc(intCount)
                                blnTempDesc = TRUE
                            Else
                                blnTempDesc = FALSE
                            End If
                            If ObstacleDesc(intCount).HasDeadIndex Then
                                ObstacleDesc(intCount) = ObstacleContainerInfo(ObstacleDesc(intCount).DeadIndex)
                                ObstacleDesc(intCount).Exists = TRUE
                                ObstacleDesc(intCount).X = SrcRect.left
                                ObstacleDesc(intCount).Index = ObstacleDesc(intCount).DeadIndex
                                ObstacleDesc(intCount).Y = SrcRect.top
                                If blnTempDesc Then
                                    ObstacleDesc(intCount).XFire = TempDesc.XFire
                                    ObstacleDesc(intCount).YFire = TempDesc.YFire
                                    ObstacleDesc(intCount).TargetX = TempDesc.TargetX
                                    ObstacleDesc(intCount).TargetY = TempDesc.TargetY
                                End If
                            Else
                                ObstacleDesc(intCount).Exists = FALSE
                            End If

                            Exit Sub
                        Else
                            UpdateHits TRUE, SrcRect2.left, SrcRect2.top
                            Exit Sub
                        End If
                    ElseIf DetectCollision(SrcRect, SrcRect2) = FALSE And Laser3Desc(intCount2).StillColliding = TRUE Then
                        Laser3Desc(intCount2).StillColliding = FALSE
                    End If
                End If
            Next
        End If
    Next

    For intCount2 = 0 To UBound(GuidedMissile)
        If GuidedMissile(intCount2).Exists = TRUE Then

            SrcRect2.top = GuidedMissile(intCount2).Y
            SrcRect2.bottom = SrcRect2.top + MISSILEDIMENSIONS
            SrcRect2.left = GuidedMissile(intCount2).X
            SrcRect2.right = SrcRect2.left + MISSILEDIMENSIONS

            For intCount = 0 To UBound(EnemyDesc)
                If EnemyDesc(intCount).Exists Then

                    SrcRect.top = EnemyDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
                    SrcRect.left = EnemyDesc(intCount).X
                    SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

                    If DetectCollision(SrcRect, SrcRect2) Then
                        EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + 10

                        SndPlayCopy dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                        If EnemyDesc(intCount).TimesHit > EnemyDesc(intCount).TimesDies And Not EnemyDesc(intCount).Invulnerable Then
                            EnemyDesc(intCount).Exists = FALSE
                            lngScore = lngScore + EnemyDesc(intCount).Score
                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, FALSE
                        Else
                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, TRUE
                        End If
                        GuidedMissile(intCount2).Exists = FALSE
                        GuidedMissile(intCount2).TargetSet = FALSE
                        Exit Sub
                    End If
                End If
            Next

            For intCount = 0 To UBound(ObstacleDesc)
                If ObstacleDesc(intCount).Exists And Not ObstacleDesc(intCount).Invulnerable Then

                    SrcRect.top = ObstacleDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + ObstacleDesc(intCount).H
                    SrcRect.left = ObstacleDesc(intCount).X
                    SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                    If DetectCollision(SrcRect, SrcRect2) Then
                        ObstacleDesc(intCount).TimesHit = ObstacleDesc(intCount).TimesHit + 10

                        SndPlayCopy dsExplosion, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                        If ObstacleDesc(intCount).TimesHit > ObstacleDesc(intCount).TimesDies Then
                            lngScore = lngScore + ObstacleDesc(intCount).Score
                            If ObstacleDesc(intCount).HasFired Then
                                TempDesc = ObstacleDesc(intCount)
                                blnTempDesc = TRUE
                            Else
                                blnTempDesc = FALSE
                            End If
                            If ObstacleDesc(intCount).HasDeadIndex Then
                                ObstacleDesc(intCount) = ObstacleContainerInfo(ObstacleDesc(intCount).DeadIndex)
                                ObstacleDesc(intCount).Exists = TRUE
                                ObstacleDesc(intCount).X = SrcRect.left
                                ObstacleDesc(intCount).Y = SrcRect.top
                                ObstacleDesc(intCount).Index = ObstacleDesc(intCount).DeadIndex
                                If blnTempDesc Then
                                    ObstacleDesc(intCount).XFire = TempDesc.XFire
                                    ObstacleDesc(intCount).YFire = TempDesc.YFire
                                    ObstacleDesc(intCount).TargetX = TempDesc.TargetX
                                    ObstacleDesc(intCount).TargetY = TempDesc.TargetY
                                End If
                            Else
                                ObstacleDesc(intCount).Exists = FALSE
                            End If
                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, FALSE
                        Else
                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, TRUE
                        End If
                        GuidedMissile(intCount2).Exists = FALSE
                        GuidedMissile(intCount2).TargetSet = FALSE
                        Exit Sub
                    End If
                End If
            Next
        End If
    Next
End Sub


'This sub updates the large slow scrolling bitmap in the background of the level
Sub UpdateBackground
    Dim sngFinalY As Single 'the final Y position of the bitmap
    Dim OffsetTop As Long 'The offset of the top of the bitmap
    Dim OffsetBottom As Long 'The offset of the bottom of the bitmap
    Dim SrcRect As Rectangle2D 'Source rectangle of the bitmap

    If boolBackgroundExists = FALSE Then 'If there is no background bitmap,
        Exit Sub 'exit the sub
    Else 'otherwise
        sngBackgroundY = sngBackgroundY + 0.1 'increment the Y position of the bitmap
        If sngBackgroundY + BackgroundObject(intObjectIndex).H < 0 Then Exit Sub
        'if the y position is less than 0 exit the sub
        If sngBackgroundY >= SCREEN_HEIGHT - 1 Then 'if the bitmap is less that the height of the screen then
            boolBackgroundExists = FALSE 'the bitmap no longer exists, since it has left the screen
        Else 'otherwise
            If sngBackgroundY + BackgroundObject(intObjectIndex).H >= SCREEN_HEIGHT Then
                'if bitmap is partially on the bottom of the screen
                OffsetBottom = SCREEN_HEIGHT - (sngBackgroundY + BackgroundObject(intObjectIndex).H)
                'set the offset amount to adjust for this
            Else 'otherwise
                OffsetBottom = 0 'there is no offset
            End If
            If sngBackgroundY <= 0 Then 'if the bitmap Y coordinate is partially off the top of the screen
                OffsetTop = Not sngBackgroundY 'set the offset to reflect this
                If OffsetTop < 0 Then OffsetTop = 0 'if the offset is less than 0, set the offset to 0
                sngFinalY = 0 'the final Y coordinate is 0
            Else 'otherwise
                sngFinalY = sngBackgroundY 'the finaly Y coordinate is the same as the background Y coordinate
                OffsetTop = 0 'and there is no offset
            End If

            ' Define the source rectangle for the background bitmap
            SrcRect.top = OffsetTop 'the top is the topoffset variable
            SrcRect.bottom = BackgroundObject(intObjectIndex).H + OffsetBottom 'for the bottom of the rect, and the height of the object plus the offset
            SrcRect.left = 0 'left is always 0
            SrcRect.right = SrcRect.left + BackgroundObject(intObjectIndex).W 'right is set to the width of the bitmap

            PutImage (sngBackgroundX, sngFinalY), ddsBackgroundObject(intObjectIndex), , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'blit the background object to the backbuffer, using a source color key
        End If
    End If
End Sub


'This sub creates as well as updates stars
Sub UpdateStars
    Dim intCount As Long 'count variable
    Dim SrcRect As Rectangle2D 'source rectangle

    For intCount = 0 To UBound(StarDesc) 'loop through all the stars
        If StarDesc(intCount).Exists = FALSE Then 'if this star doesn't exist then
            If (Int((3500 - 1) * Rnd) + 1) <= 25 Then 'if a number between 3500 and 1 is less than 25 then
                'begin creating a new star
                StarDesc(intCount).Exists = TRUE 'the star exists
                StarDesc(intCount).X = Int((SCREEN_WIDTH - 1) * Rnd) + 1
                'set a random X coordinate
                StarDesc(intCount).Y = 0 'start at the top of the screen
                StarDesc(intCount).Index = Int((5 - 1) * Rnd) + 1 'set a random number for a color
                StarDesc(intCount).Speed = ((2 - 0.4) * Rnd) + 0.4 'set a random number for the speed of the star
            End If
        Else
            StarDesc(intCount).Y = StarDesc(intCount).Y + StarDesc(intCount).Speed
            'increment the stars position by its' speed
            If StarDesc(intCount).Y >= SCREEN_HEIGHT - 1 Then
                'if the star goes off the screen
                StarDesc(intCount).Y = 0 'set the stars Y position to 0
                StarDesc(intCount).Exists = FALSE 'the star no longer exists
            Else 'otherwise
                'set the stars rectangle coordinates
                SrcRect.top = 0
                SrcRect.bottom = SrcRect.top + 1
                SrcRect.left = StarDesc(intCount).Index
                SrcRect.right = SrcRect.left + 1

                PutImage (StarDesc(intCount).X, StarDesc(intCount).Y), ddsStar, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'blit the star to the screen
            End If
        End If
    Next
End Sub


'This sub updates all the obstacles on the screen, and animates them if there are any animations for the obstacle
Sub UpdateObstacles
    Dim intCount As Long 'count variable
    Dim TempX As Long 'variable for left of the rectangle
    Dim TempY As Long 'variable for top of the rectangle
    Dim XOffset As Long 'offset for the right of the rectangle
    Dim YOffset As Long 'offset for the bottom of the rectangle
    Dim OffsetTop As Long 'the top offset of the animation frame
    Dim OffsetBottom As Long 'the bottom offset of the animation frame
    Dim sngFinalY As Single 'the final Y position of the obstacle
    Dim SrcRect As Rectangle2D 'source rectangle

    For intCount = 0 To UBound(ObstacleDesc) 'loop through all obstacles
        If ObstacleDesc(intCount).Exists Then 'if this obstacle exists
            ObstacleDesc(intCount).Y = ObstacleDesc(intCount).Y + ObstacleDesc(intCount).Speed
            'increment the obstacle by its' speed
            If ObstacleDesc(intCount).Y >= SCREEN_HEIGHT Then 'if the obstacle goes completely off the screen
                ObstacleDesc(intCount).Exists = FALSE 'the obstacle no longer exists
            Else 'otherwise
                XOffset = 0 'reset the X offset
                YOffset = 0 'reset the Y offset
                If ObstacleDesc(intCount).NumFrames > 0 Then 'if this obstacle has an animation
                    ObstacleDesc(intCount).Frame = ObstacleDesc(intCount).Frame + 1 'increment the frame the animation is on
                    If ObstacleDesc(intCount).Frame > ObstacleDesc(intCount).NumFrames Then ObstacleDesc(intCount).Frame = 0 'if the animation goes beyond the number of frames it has, reset it to the start
                    TempY = ObstacleDesc(intCount).Frame \ 4 'TODO: X and Y reversed? calculate the left of the animation
                    TempX = ObstacleDesc(intCount).Frame - (TempY * 4) 'TODO: X and Y reversed? calculate the top of the animation
                    XOffset = CLng(TempX * ObstacleDesc(intCount).W) 'calculate the right of the animation
                    YOffset = CLng(TempY * ObstacleDesc(intCount).H) 'calculate the bottom of the animation
                End If
                If ObstacleDesc(intCount).Y < 0 Then 'if the obstacle is partially off the top of the screen
                    OffsetTop = (Not ObstacleDesc(intCount).Y) + 1 'adjust the rectangle
                    sngFinalY = 0 'the Y of the obstacle is 0
                Else 'otherwise
                    sngFinalY = ObstacleDesc(intCount).Y 'set the y position of the obstacle
                    OffsetTop = 0 'there is no top offset for the obstacle
                End If
                If ObstacleDesc(intCount).Y + ObstacleDesc(intCount).H >= SCREEN_HEIGHT Then 'if the obstacle is partially off the bottom of the screen
                    OffsetBottom = ObstacleDesc(intCount).H + (SCREEN_HEIGHT - (ObstacleDesc(intCount).Y + ObstacleDesc(intCount).H)) 'adjust the rectangle
                Else 'otherwise
                    OffsetBottom = ObstacleDesc(intCount).H 'the bottom is the entire height of the obstacle
                End If
                'enter in the values for the rectangle
                SrcRect.top = OffsetTop + YOffset
                SrcRect.bottom = OffsetBottom + YOffset
                SrcRect.left = XOffset
                SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                If SrcRect.top < SrcRect.bottom Then 'if the rectangle is valid then
                    'If ObstacleDesc(intCount).Solid Then 'if the obstacle is a solid obstacle
                    'PutImage (ObstacleDesc(intCount).X, sngFinalY), ddsObstacle(ObstacleDesc(intCount).Index), , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'blit the obstacle with no color key
                    'Else
                    PutImage (ObstacleDesc(intCount).X, sngFinalY), ddsObstacle(ObstacleDesc(intCount).Index), , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'otherwise blit it with a color key
                    'End If
                End If
            End If
        End If
    Next
End Sub


'This sub updates all the enemies that are being displayed on the screen
Sub UpdateEnemys
    Dim intCount As Long 'count variable
    Dim SrcRect As Rectangle2D 'source rectangle for the blit
    Dim intReturnResult As Long 'return holder
    Dim sngChaseSpeed As Single 'chase speed of the enemy
    Dim TempX As Long 'temporary X coordinate
    Dim TempY As Long 'temporary Y coordinate
    Dim XOffset As Long 'X offset of the animation frame
    Dim YOffset As Long 'Y offset of the animation frame
    Dim FinalY As Long 'Finaly Y position of the enemy
    Dim FinalX As Long 'Final X position of the enemy
    Dim lngTopOffset As Long 'Offset of the top of the rectangle
    Dim lngBottomOffset As Long 'Offset of the bottom of the rectangle
    Dim lngRightOffset As Long 'Offset of the right of the rectangle
    Dim lngLeftOffset As Long 'Offset of the left of the rectangle

    For intCount = 0 To UBound(EnemyDesc) 'loop through all the enemies
        'these next lines reset all the variables to zero
        lngTopOffset = 0
        lngBottomOffset = 0
        lngRightOffset = 0
        lngLeftOffset = 0
        XOffset = 0
        YOffset = 0
        If EnemyDesc(intCount).Exists Then 'if the enemy exists
            EnemyDesc(intCount).Y = EnemyDesc(intCount).Y + EnemyDesc(intCount).Speed
            'increment the enemies Y position by its' speed
            FinalY = EnemyDesc(intCount).Y 'start off with the final Y the same as the enemies Y
            If EnemyDesc(intCount).Y + EnemyDesc(intCount).H > SCREEN_HEIGHT Then 'if the enemy is partially off the bottom of the screen
                lngBottomOffset = (SCREEN_HEIGHT - (EnemyDesc(intCount).Y + EnemyDesc(intCount).H)) + EnemyDesc(intCount).H 'adjust the offset of the rectangle to compensate
            Else 'otherwise
                lngBottomOffset = EnemyDesc(intCount).H 'blit the whole enemy
            End If
            If EnemyDesc(intCount).Y < 0 Then 'if the enemy is partially off the top of the screen
                lngTopOffset = Abs(EnemyDesc(intCount).Y)
                'adjust the top offset of the rectangle to compensate
                lngBottomOffset = EnemyDesc(intCount).H + EnemyDesc(intCount).Y 'also adjust the bottom offset of the rectangle to compensate
                FinalY = 0 'the Y position of the rectangle will be zero
            End If
            If EnemyDesc(intCount).Y < SCREEN_HEIGHT Then
                'if the enemy is on the screen then
                If Ship.Y > EnemyDesc(intCount).Y Then 'if the the enemyies Y coorindate is larger than the players ship
                    If EnemyDesc(intCount).ChaseValue > 0 Then
                        'if the enemy has a chase value
                        If EnemyDesc(intCount).ChaseValue = CHASEFAST Then sngChaseSpeed = 0.2
                        'if the enemy is supposed to rapidly follow the players X coordinate, set it to a large increment
                        If EnemyDesc(intCount).ChaseValue = CHASESLOW Then sngChaseSpeed = 0.05
                        'if the enemy is supposed to slowly follow the players X coordinate, set it to a smaller increment

                        If (Ship.X + (SHIPWIDTH \ 2)) < (EnemyDesc(intCount).X + (EnemyDesc(intCount).W \ 2)) Then 'if the player is to the left of the enemy
                            EnemyDesc(intCount).XVelocity = EnemyDesc(intCount).XVelocity - sngChaseSpeed 'make the enemy move to the left
                            'if the enemies velocity is greater than the maximum velocity, reverse the direction of the enemy
                            If Abs(EnemyDesc(intCount).XVelocity) > XMAXVELOCITY Then EnemyDesc(intCount).XVelocity = XMAXVELOCITY - XMAXVELOCITY - XMAXVELOCITY
                        ElseIf (Ship.X + (SHIPWIDTH \ 2)) > (EnemyDesc(intCount).X + (EnemyDesc(intCount).W \ 2)) Then 'if the player is to the right of the enemy
                            EnemyDesc(intCount).XVelocity = EnemyDesc(intCount).XVelocity + sngChaseSpeed 'make the enemy move to the right
                            'if the enemies velocity is greater than the maximum velocity, reverse the direction of the enemy
                            If Abs(EnemyDesc(intCount).XVelocity) > XMAXVELOCITY Then EnemyDesc(intCount).XVelocity = XMAXVELOCITY
                        End If
                    End If
                End If

                EnemyDesc(intCount).X = EnemyDesc(intCount).X + EnemyDesc(intCount).XVelocity
                'increment the X position of the enemy by its' velocity
                FinalX = EnemyDesc(intCount).X 'the final X will be set to the enemies X coordinate
                If EnemyDesc(intCount).X + EnemyDesc(intCount).W > SCREEN_WIDTH Then
                    'if the enemy is partially off the screen to the right
                    lngRightOffset = (SCREEN_WIDTH - (EnemyDesc(intCount).X + EnemyDesc(intCount).W)) + EnemyDesc(intCount).W
                    'set the right offset of the animation rectangle to compensate
                Else 'otherwise
                    lngRightOffset = EnemyDesc(intCount).W
                    'the right offset is equal to the width of the animation frame
                End If
                If EnemyDesc(intCount).X < 0 Then 'if the enemy is partially off the screen to the left
                    lngLeftOffset = Abs(EnemyDesc(intCount).X)
                    'set the left offset to compensate
                    lngRightOffset = EnemyDesc(intCount).W + EnemyDesc(intCount).X
                    'set the right offset of the rectangle so the correct width will be displayed
                    FinalX = 0 'the X will be set to zero, since we can't pass a negative number
                End If

                If EnemyDesc(intCount).FrameDelay > 0 Then
                    'if the frame delay count of this enemy is greater than zero,
                    'it means this enemy should have a delay in the number of frames
                    'that are displayed
                    EnemyDesc(intCount).FrameDelayCount = EnemyDesc(intCount).FrameDelayCount + 1
                    'increment it by one
                    If EnemyDesc(intCount).FrameDelayCount > EnemyDesc(intCount).FrameDelay Then
                        'if the delay count is larger than the frame delay
                        EnemyDesc(intCount).FrameDelayCount = 0
                        'reset the count
                        EnemyDesc(intCount).Frame = EnemyDesc(intCount).Frame + 1
                        'increment the animation frame by one
                    End If
                Else 'otherwise,
                    EnemyDesc(intCount).Frame = EnemyDesc(intCount).Frame + 1
                    'increment the frame displayed
                End If

                If EnemyDesc(intCount).Frame > EnemyDesc(intCount).NumFrames Then EnemyDesc(intCount).Frame = 0
                'if the frame number goes over the number of frames this enemy
                'has, reset the animation frame to the beginning
                TempY = EnemyDesc(intCount).Frame \ 4 'set the starting Y position for this animation frame
                TempX = EnemyDesc(intCount).Frame - (TempY * 4)
                'set the starting X position for this animation frame
                XOffset = CLng(TempX * EnemyDesc(intCount).W)
                'set the X offset of the animation frame
                YOffset = CLng(TempY * EnemyDesc(intCount).H)
                'set the Y offset of the animation frame

                SrcRect.top = 0 + YOffset + lngTopOffset 'set the top of the rect
                SrcRect.bottom = SrcRect.top + lngBottomOffset 'the bottom is the top plus the bottom offset
                SrcRect.left = 0 + XOffset + lngLeftOffset 'set the left offset
                SrcRect.right = SrcRect.left + lngRightOffset 'the right is the left plus the right offset

                If (EnemyDesc(intCount).W + EnemyDesc(intCount).X) > 1 And EnemyDesc(intCount).X < SCREEN_WIDTH And SrcRect.right > SrcRect.left And SrcRect.bottom > SrcRect.top Then
                    'make sure that the enemy is within the bounds for blitting
                    PutImage (FinalX, FinalY), ddsEnemyContainer(EnemyDesc(intCount).Index), , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom)
                    'blit the enemy with a transparent key
                End If
            Else
                EnemyDesc(intCount).Exists = FALSE 'otherwise, this enemy no longer exists
            End If
        End If

        If EnemyDesc(intCount).HasFired = FALSE And EnemyDesc(intCount).Exists = TRUE And EnemyDesc(intCount).DoesFire And EnemyDesc(intCount).Y > 0 And (EnemyDesc(intCount).Y + EnemyDesc(intCount).H) < SCREEN_HEIGHT And EnemyDesc(intCount).X > 0 And (EnemyDesc(intCount).X + EnemyDesc(intCount).W) < SCREEN_WIDTH Then
            'This incredibly long line has a very important job. It makes sure that the enemy hasn't fired, that it exists, and that it is visible on the screen
            intReturnResult = Int((1500 - 1) * Rnd + 1) 'make a random number to to determine whether the enemy will fire
            If intReturnResult < 20 Then 'if the random number is less than 20, make the enemy fire

                SndPlayCopy dsEnemyFire, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the duplicate sound buffer

                If EnemyDesc(intCount).X < Ship.X Then 'if the players X coordinate is less than the enemies
                    EnemyDesc(intCount).TargetX = 3 'set the X fire direction to +3 pixels every frame
                Else 'otherwise
                    EnemyDesc(intCount).TargetX = -3 'set it to -3 pixels every frame
                End If

                If EnemyDesc(intCount).Y < Ship.Y Then 'if the enemy ship's Y coordinate is less than the ships then
                    EnemyDesc(intCount).TargetY = 3 'set the enemy fire to move +3 pixels every frame
                Else 'otherwise
                    EnemyDesc(intCount).TargetY = -3 'set the enemy fire to move -3 pixels every frame
                End If
                EnemyDesc(intCount).XFire = (EnemyDesc(intCount).W / 2) + EnemyDesc(intCount).X
                'center the enemies X fire
                EnemyDesc(intCount).YFire = (EnemyDesc(intCount).H / 2) + EnemyDesc(intCount).Y
                'center the eneies Y fire
                EnemyDesc(intCount).HasFired = TRUE 'the enemy has fired
            End If

        ElseIf EnemyDesc(intCount).HasFired = TRUE Then 'otherwise, if the enemy has fired
            If EnemyDesc(intCount).FireType = TARGETEDFIRE Then
                'if the type of fire that the enemy uses aims in the general direction of the player then
                EnemyDesc(intCount).XFire = EnemyDesc(intCount).XFire + EnemyDesc(intCount).TargetX
                'increment the enemy X fire in the direction specified
                EnemyDesc(intCount).YFire = EnemyDesc(intCount).YFire + EnemyDesc(intCount).TargetY
                'increment the enemy Y fire in the direction specified
            Else 'otherwise
                EnemyDesc(intCount).YFire = EnemyDesc(intCount).YFire + 5
                'increment the Y fire only, by 5 pixels
            End If
            If EnemyDesc(intCount).FireFrameCount > 3 Then
                'if we have reached the end of the number of frames to wait until it is time to change the fire animation frame then
                EnemyDesc(intCount).FireFrameCount = 0 'reset the counter
                If EnemyDesc(intCount).FireFrame = 5 Then
                    'if the enemy animation frame is on the second frame
                    EnemyDesc(intCount).FireFrame = 0 'reset the animation frame to the first one
                Else 'otherwise
                    EnemyDesc(intCount).FireFrame = 5 'change it to the second one
                End If
            Else 'otherwise
                EnemyDesc(intCount).FireFrameCount = EnemyDesc(intCount).FireFrameCount + 1
                'increment the wait time
            End If

            SrcRect.top = 0 'set the top of the enemy fire animation
            SrcRect.bottom = 5 'the animation is 5 pixels high
            SrcRect.left = EnemyDesc(intCount).FireFrame 'set the left to which frame we are on
            SrcRect.right = SrcRect.left + 5 'the width of the fire is 5 pixels

            If EnemyDesc(intCount).XFire > SCREEN_WIDTH - 5 Or EnemyDesc(intCount).XFire < 0 Or EnemyDesc(intCount).YFire > SCREEN_HEIGHT - 5 Or EnemyDesc(intCount).YFire < 0 Then
                'if the enemy fire is off the visible screen
                EnemyDesc(intCount).HasFired = FALSE 'the enemy hasn't fired
            Else 'otherwise
                PutImage (EnemyDesc(intCount).XFire, EnemyDesc(intCount).YFire), ddsEnemyFire, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'blit the enemy fire
            End If
        End If
    Next

    'The rest of the sub does the exact same thing that the code above does when firing an enemy weapon,
    'except it does it for any of the obstacles that have the ability to fire

    For intCount = 0 To UBound(ObstacleDesc)
        If ObstacleDesc(intCount).HasFired = FALSE And ObstacleDesc(intCount).Exists = TRUE And ObstacleDesc(intCount).DoesFire Then
            intReturnResult = Int((3000 - 1) * Rnd + 1)
            If intReturnResult < 20 Then

                SndPlayCopy dsEnemyFire, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the duplicate sound buffer

                If ObstacleDesc(intCount).X < Ship.X Then
                    ObstacleDesc(intCount).TargetX = 3
                Else
                    ObstacleDesc(intCount).TargetX = -3
                End If
                If ObstacleDesc(intCount).Y < Ship.Y Then
                    ObstacleDesc(intCount).TargetY = 3
                Else
                    ObstacleDesc(intCount).TargetY = -3
                End If
                ObstacleDesc(intCount).XFire = (ObstacleDesc(intCount).W / 2) + ObstacleDesc(intCount).X
                ObstacleDesc(intCount).YFire = (ObstacleDesc(intCount).H / 2) + ObstacleDesc(intCount).Y
                ObstacleDesc(intCount).HasFired = TRUE
            End If
        ElseIf ObstacleDesc(intCount).HasFired = TRUE Then
            ObstacleDesc(intCount).XFire = ObstacleDesc(intCount).XFire + ObstacleDesc(intCount).TargetX
            ObstacleDesc(intCount).YFire = ObstacleDesc(intCount).YFire + ObstacleDesc(intCount).TargetY
            If ObstacleDesc(intCount).FireFrameCount > 3 Then
                ObstacleDesc(intCount).FireFrameCount = 0
                If ObstacleDesc(intCount).FireFrame = 5 Then
                    ObstacleDesc(intCount).FireFrame = 0
                Else
                    ObstacleDesc(intCount).FireFrame = 5
                End If
            Else
                ObstacleDesc(intCount).FireFrameCount = ObstacleDesc(intCount).FireFrameCount + 1
            End If

            SrcRect.top = 0
            SrcRect.bottom = 5
            SrcRect.left = ObstacleDesc(intCount).FireFrame
            SrcRect.right = SrcRect.left + 5

            If ObstacleDesc(intCount).XFire > SCREEN_WIDTH - 5 Or ObstacleDesc(intCount).XFire < 0 Or ObstacleDesc(intCount).YFire > SCREEN_HEIGHT - 5 Or ObstacleDesc(intCount).YFire < 0 Then
                ObstacleDesc(intCount).HasFired = FALSE
            Else
                PutImage (ObstacleDesc(intCount).XFire, ObstacleDesc(intCount).YFire), ddsEnemyFire, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom)
            End If
        End If
    Next
End Sub


'This sub updates all of the players weapon fire
Sub UpdateWeapons
    Dim intCount As Long 'count variable
    Dim intCounter As Long 'another count variable
    Dim SrcRect As Rectangle2D 'source rectuangle

    Do Until intCount > UBound(LaserDesc) 'Loop through all the level 1 lasers
        If LaserDesc(intCount).Exists Then 'if the laser exists
            LaserDesc(intCount).Y = LaserDesc(intCount).Y - LASERSPEED
            'increment the Y position by the speed of the laser
            If LaserDesc(intCount).Y < 0 Then 'if the laser goes off the screen
                LaserDesc(intCount).Exists = FALSE 'the laser no longer exists
                LaserDesc(intCount).Y = 0 'reset the Y position
                LaserDesc(intCount).X = 0 'reset the X position
            Else 'otherwise
                PutImage (LaserDesc(intCount).X, LaserDesc(intCount).Y), ddsLaser 'blit the laser to the screen
            End If
        End If
        intCount = intCount + 1 'increment the count
    Loop

    'set the coordinates of the level 2 laser
    SrcRect.top = 0
    SrcRect.bottom = SrcRect.top + 8
    SrcRect.left = 0
    SrcRect.right = SrcRect.left + 8

    intCount = 0 'reset the count variable
    Do Until intCount > UBound(Laser2RDesc) 'loop through all the level 2 lasers on the right side
        If Laser2RDesc(intCount).Exists Then 'if the laser exists
            Laser2RDesc(intCount).Y = Laser2RDesc(intCount).Y + Laser2RDesc(intCount).YVelocity
            'increment the Y by the Y velocity
            Laser2RDesc(intCount).X = Laser2RDesc(intCount).X + Laser2RDesc(intCount).XVelocity
            'increment the X by the X velocity
            'fill in the source rectangle values
            SrcRect.left = LASER2WIDTH
            SrcRect.right = SrcRect.left + LASER2WIDTH
            SrcRect.top = 0
            SrcRect.bottom = LASER2HEIGHT

            If Laser2RDesc(intCount).X < 0 Or Laser2RDesc(intCount).X > (SCREEN_WIDTH - LASER2WIDTH) Or Laser2RDesc(intCount).Y < 0 Or Laser2RDesc(intCount).Y > (SCREEN_HEIGHT - LASER2HEIGHT) Then
                'if the laser goes off the screen then
                Laser2RDesc(intCount).Exists = FALSE 'the laser no longer exists
            Else 'otherwise
                PutImage (Laser2RDesc(intCount).X, Laser2RDesc(intCount).Y), ddsLaser2R, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'blit the laser to the screen
            End If
        End If
        intCount = intCount + 1 'increment the count
    Loop

    'The next part does the same thing as the above code.
    'but for the left side of the laser
    intCount = 0
    Do Until intCount > UBound(Laser2LDesc)
        If Laser2LDesc(intCount).Exists Then
            Laser2LDesc(intCount).Y = Laser2LDesc(intCount).Y + Laser2LDesc(intCount).YVelocity
            Laser2LDesc(intCount).X = Laser2LDesc(intCount).X + Laser2LDesc(intCount).XVelocity

            SrcRect.left = 0
            SrcRect.right = SrcRect.left + LASER2WIDTH
            SrcRect.top = 0
            SrcRect.bottom = LASER2HEIGHT

            If Laser2LDesc(intCount).X < 0 Or Laser2LDesc(intCount).X > (SCREEN_WIDTH - LASER2WIDTH) Or Laser2LDesc(intCount).Y < 0 Or Laser2LDesc(intCount).Y > (SCREEN_HEIGHT - LASER2HEIGHT) Then
                Laser2LDesc(intCount).Exists = FALSE
            Else
                PutImage (Laser2LDesc(intCount).X, Laser2LDesc(intCount).Y), ddsLaser2L, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom)
            End If
        End If
        intCount = intCount + 1
    Loop

    intCount = 0
    Do Until intCount > UBound(Laser3Desc)
        If Laser3Desc(intCount).Exists Then
            Laser3Desc(intCount).Y = Laser3Desc(intCount).Y - Laser3Desc(intCount).YVelocity
            If Laser3Desc(intCount).Y < 0 Then
                Laser3Desc(intCount).Exists = FALSE
                Laser3Desc(intCount).Y = 0
                Laser3Desc(intCount).X = 0
            Else
                PutImage (Laser3Desc(intCount).X, Laser3Desc(intCount).Y), ddsLaser3
            End If
        End If
        intCount = intCount + 1
    Loop

    intCount = 0 'reset the count variable
    Do Until intCount > UBound(GuidedMissile) 'loop through all the guided missle indexes
        If GuidedMissile(intCount).Exists Then 'if the missil exists
            If GuidedMissile(intCount).TargetSet = FALSE Then
                'and the target for it has not been set
                For intCounter = 0 To UBound(EnemyDesc) 'loop through all the enemies
                    If EnemyDesc(intCounter).Exists Then 'if the first enemy encountered exists
                        GuidedMissile(intCount).TargetIndex = intCounter
                        'set the index of the target to the index of the enemy
                        GuidedMissile(intCount).TargetSet = TRUE
                        'the target has now been set
                        Exit For 'exit the loop
                    End If
                Next
            Else 'otherwise, the target has already been set for this missle
                If EnemyDesc(GuidedMissile(intCount).TargetIndex).Exists Then
                    'if the target enemy still exists
                    If (EnemyDesc(GuidedMissile(intCount).TargetIndex).X + (EnemyDesc(GuidedMissile(intCount).TargetIndex).W / 2)) > GuidedMissile(intCount).X Then
                        'check if the missile has gone past the enemy
                        GuidedMissile(intCount).XVelocity = GuidedMissile(intCount).XVelocity + 0.05
                        'compensate if it has
                        If GuidedMissile(intCount).XVelocity > MAXMISSILEVELOCITY Then GuidedMissile(intCount).XVelocity = MAXMISSILEVELOCITY
                        'make sure that the missiles velocity doesn't go past the maximum
                    ElseIf (EnemyDesc(GuidedMissile(intCount).TargetIndex).X + (EnemyDesc(GuidedMissile(intCount).TargetIndex).W / 2)) < GuidedMissile(intCount).X Then
                        'check if the missile has gone past the enemy
                        GuidedMissile(intCount).XVelocity = GuidedMissile(intCount).XVelocity - 0.05
                        'compensate if it has
                        If Abs(GuidedMissile(intCount).XVelocity) > MAXMISSILEVELOCITY Then GuidedMissile(intCount).XVelocity = MAXMISSILEVELOCITY - MAXMISSILEVELOCITY - MAXMISSILEVELOCITY
                        'make sure that the missiles velocity doesn't go past the maximum
                    End If
                    If (EnemyDesc(GuidedMissile(intCount).TargetIndex).Y + (EnemyDesc(GuidedMissile(intCount).TargetIndex).H / 2)) > GuidedMissile(intCount).Y Then
                        'check if the missile has gone past the enemy
                        GuidedMissile(intCount).YVelocity = GuidedMissile(intCount).YVelocity + 0.05
                        'compensate if it has
                        If GuidedMissile(intCount).YVelocity > MAXMISSILEVELOCITY Then GuidedMissile(intCount).YVelocity = MAXMISSILEVELOCITY
                        'make sure that the missiles velocity doesn't go past the maximum
                    ElseIf (EnemyDesc(GuidedMissile(intCount).TargetIndex).Y + (EnemyDesc(GuidedMissile(intCount).TargetIndex).H / 2)) < GuidedMissile(intCount).Y Then
                        'check if the missile has gone past the enemy
                        GuidedMissile(intCount).YVelocity = GuidedMissile(intCount).YVelocity - 0.05
                        'compensate if it has
                        If Abs(GuidedMissile(intCount).YVelocity) > MAXMISSILEVELOCITY Then GuidedMissile(intCount).YVelocity = MAXMISSILEVELOCITY - MAXMISSILEVELOCITY - MAXMISSILEVELOCITY
                        'make sure that the missiles velocity doesn't go past the maximum
                    End If
                Else
                    GuidedMissile(intCount).TargetSet = FALSE
                    'if the enemy does not exist, the target has no longer been set
                End If
            End If

            GuidedMissile(intCount).X = GuidedMissile(intCount).X + GuidedMissile(intCount).XVelocity
            'increment the missile X by the velocity of the missile
            GuidedMissile(intCount).Y = GuidedMissile(intCount).Y + GuidedMissile(intCount).YVelocity
            'increment the missile X by the velocity of the missile
            If GuidedMissile(intCount).X < 0 Or (GuidedMissile(intCount).X + MISSILEDIMENSIONS) > SCREEN_WIDTH Or GuidedMissile(intCount).Y < 0 Or (GuidedMissile(intCount).Y + MISSILEDIMENSIONS) > SCREEN_HEIGHT Then
                'if the missile goes off the screen
                GuidedMissile(intCount).Exists = FALSE 'the guided missile no longer exists
                GuidedMissile(intCount).TargetSet = FALSE 'the guided missile has no target
            Else 'otherwise
                PutImage (GuidedMissile(intCount).X, GuidedMissile(intCount).Y), ddsGuidedMissile
                'blit the missile to the screen
            End If
        End If
        intCount = intCount + 1 'increment the count
    Loop
End Sub


'This sub updates the player's ship, and animates it
Sub UpdateShip
    Dim SrcRect As Rectangle2D 'source rectangle
    Dim TempX As Long 'X poistion of the animation
    Dim TempY As Long 'Y position of the animation
    Static byteFrameDirection As Byte 'keep track of the direction the animation is moving

    If intShipFrameCount > 29 And byteFrameDirection = 0 Then
        'if the end of the animation is reached
        byteFrameDirection = 1 'reverse the direction
    ElseIf intShipFrameCount < 1 And byteFrameDirection = 1 Then
        'if the end is reached the other direction
        byteFrameDirection = 0 'reverse the direction
    End If

    If byteFrameDirection = 1 Then 'if the animation is headed backwards
        intShipFrameCount = intShipFrameCount - 1 'reduce the frame the animation is on
    Else 'otherwise
        intShipFrameCount = intShipFrameCount + 1 'increment the animation frame
    End If

    TempY = intShipFrameCount \ 4 'find the left of the animation
    TempX = intShipFrameCount - (TempY * 4) 'find the top of the animation
    Ship.XOffset = CLng(TempX * SHIPWIDTH) 'set the X offset of the animation frame
    Ship.YOffset = CLng(TempY * SHIPHEIGHT) 'set the Y offset of the animation frame

    'fill in the values of the animation frame
    SrcRect.top = Ship.YOffset
    SrcRect.bottom = SrcRect.top + SHIPHEIGHT
    SrcRect.left = Ship.XOffset
    SrcRect.right = SrcRect.left + SHIPWIDTH

    If Abs(Ship.XVelocity) > XMAXVELOCITY Then 'if the ship reaches the maximum velocity in this direction then
        If Ship.XVelocity < 0 Then 'if the ship is headed to the left of the screen
            Ship.XVelocity = XMAXVELOCITY - XMAXVELOCITY - XMAXVELOCITY
            'set the velocity to equal the maximum velocity in this direction
        Else 'otherwise
            Ship.XVelocity = XMAXVELOCITY 'set the velocity to equal the maximum velocity in this direction
        End If
    End If
    If Abs(Ship.YVelocity) > YMAXVELOCITY Then 'if the ship reaches the maximum velocity in this direction then
        If Ship.YVelocity < 0 Then 'if the ship is headed to the top of the screen
            Ship.YVelocity = YMAXVELOCITY - YMAXVELOCITY - YMAXVELOCITY
            'set the velocity to equal the maximum velocity in this direction
        Else 'otherwise
            Ship.YVelocity = YMAXVELOCITY 'set the velocity to equal the maximum velocity in this direction
        End If
    End If

    If Ship.XVelocity > 0 Then 'if the ship's velocity is positive
        Ship.XVelocity = Ship.XVelocity - FRICTION 'subtract some of the velocity using friction
        If Ship.XVelocity < 0 Then Ship.XVelocity = 0 'if the ship goes under zero velocity, the ship has no velocity anymore
    ElseIf Ship.XVelocity < 0 Then 'otherwise, if the ship has negative velocity
        Ship.XVelocity = Ship.XVelocity + FRICTION 'add some friction to the negative value
        If Ship.XVelocity > 0 Then Ship.XVelocity = 0 'if the ship goes above 0, the ship no longer has velocity
    End If
    If Ship.YVelocity > 0 Then 'if the ships Y velocity is positive
        Ship.YVelocity = Ship.YVelocity - FRICTION 'subtract some of the velocity using friction
        If Ship.YVelocity < 0 Then Ship.YVelocity = 0 'if the ship goes under zero velocity, the ship has no velocity anymore
    ElseIf Ship.YVelocity < 0 Then 'otherwise, if the ship has negative velocity
        Ship.YVelocity = Ship.YVelocity + FRICTION 'add some friction to the negative value
        If Ship.YVelocity > 0 Then Ship.YVelocity = 0 'if the ship goes above 0, the ship no longer has velocity
    End If

    Ship.X = Ship.X + Ship.XVelocity 'increment the ship's X position by the amount of velocity
    Ship.Y = Ship.Y + Ship.YVelocity 'increment the ship's Y position by the amount of velocity

    If Ship.X < 0 Then Ship.X = 0 'if the ship hits the left of the screen, set the X to 0
    If Ship.Y < 0 Then Ship.Y = 0 'if the ship hits the bottom of the screen, set the Y to 0
    If Ship.X >= SCREEN_WIDTH - SHIPWIDTH Then Ship.X = SCREEN_WIDTH - SHIPWIDTH
    'if the ship hits the right of the screen, set it to the right edge
    If Ship.Y >= SCREEN_HEIGHT - SHIPHEIGHT Then Ship.Y = SCREEN_HEIGHT - SHIPHEIGHT
    'if the ship hits the bottom of the screen, set it to the bottom edge

    PutImage (Ship.X, Ship.Y), ddsShip, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'blit the ship to the screen
End Sub


'This sub updates the invulnerability animation, and starts and stops the sound that goes with it
Sub UpdateInvulnerability
    Dim TempX As Long 'Temporary X variable
    Dim TempY As Long 'Temporary Y variable
    Dim XOffset As Long 'Offset of the rectangle
    Dim YOffset As Long 'Offset of the rectangle
    Dim SrcRect As Rectangle2D 'Source rectangle
    Static intInvFrameCount As Long 'Keep track of what animation frame the animation is on
    Static blnInvWarning As Byte 'Flag that is set if it is time to warn the player that the invulnerability is running out
    Static intWarningCount As Long 'Keep track of how many times the player has been warned

    If GetTicks > Ship.InvulnerableTime Then 'If the amount of invulenrability exceeds the time alloted to the player
        Ship.Invulnerable = FALSE 'The ship is no longer invulnerable
        intInvFrameCount = 0 'The animation is reset to the starting frame
        SndStop dsInvulnerability 'Stop playing the invulnerable sound effect
        SndPlay dsInvPowerDown 'Play the power down sound effect
        blnInvWarning = FALSE 'No longer warning the player
        intWarningCount = 0 'Reset the warning count
    Else 'Otherwise, the ship is invulnerable
        If (Ship.InvulnerableTime - GetTicks) < 3000 Then 'If there are only three seconds left
            blnInvWarning = TRUE 'Toggle the warning flag to on
        End If

        If blnInvWarning Then 'If the player is being warned
            intWarningCount = intWarningCount + 1 'Increment the warning count
            If intWarningCount > 30 Then intWarningCount = 0 'If the warning count goes through 30 frames, reset it
            If intWarningCount < 15 Then 'If the warning count is less than 30 frames
                SndLoop dsInvulnerability 'Play the invulnerability sound effect
                If intInvFrameCount > 49 Then intInvFrameCount = 0 'If the animation goes past the maximum number of frames, reset it
                TempY = intInvFrameCount \ 4 'Calculate the left of the animation
                TempX = intInvFrameCount - (TempY * 4) 'Calculate the top of the animation
                XOffset = CLng(TempX * SHIPWIDTH) 'Calculate the right of the animation
                YOffset = CLng(TempY * SHIPHEIGHT) 'Calculate the bottom of the animation
                intInvFrameCount = intInvFrameCount + 1 'Increment the frame count
                'Input the rectangle values
                SrcRect.top = YOffset
                SrcRect.bottom = SrcRect.top + SHIPHEIGHT
                SrcRect.left = XOffset
                SrcRect.right = SrcRect.left + SHIPWIDTH

                PutImage (Ship.X, Ship.Y), ddsInvulnerable, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom)
                'Blit the animation frame
            Else
                SndStop dsInvulnerability 'If we are above 15 frames of animation, stop playing the invulnerability sound effect
            End If
        Else 'Otherwise, the player is not in warning mode
            If intInvFrameCount > 49 Then intInvFrameCount = 0 'If the animation goes past the maximum number of frames, reset it
            TempY = intInvFrameCount \ 4 'Calculate the left of the animation
            TempX = intInvFrameCount - (TempY * 4) 'Calculate the top of the animation
            XOffset = CLng(TempX * SHIPWIDTH) 'Calculate the right of the animation
            YOffset = CLng(TempY * SHIPHEIGHT) 'Calculate the bottom of the animation
            intInvFrameCount = intInvFrameCount + 1 'Increment the frame count
            'Input the rectangle values
            SrcRect.top = YOffset
            SrcRect.bottom = SrcRect.top + SHIPHEIGHT
            SrcRect.left = XOffset
            SrcRect.right = SrcRect.left + SHIPWIDTH

            PutImage (Ship.X, Ship.Y), ddsInvulnerable, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom)
            'Blit the animation frame
        End If
        SndBal dsInvulnerability, (2 * (Ship.X + SHIPWIDTH / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'If we are above 15 frames of animation, stop playing the invulnerability sound effect
    End If
End Sub


'This sub updates the shield display and also checks whether or not there are any shields left, as well as
'updating the players lives. If there are no lives left, it will reset the game.
Sub UpdateShields
    Dim SrcRect As Rectangle2D 'The source rectangle for the shield indicator
    Dim lngTime As Long 'variable to store the current tick count
    Dim lngTargetTick As Long 'variable to stabilize frame rate
    Dim intCount As Long 'standard loop variable

    If intShields > 0 Then 'if there is more than 0% shields left
        'define the shield indicator coordinates
        SrcRect.top = 0
        SrcRect.bottom = 20
        SrcRect.left = 0
        SrcRect.right = intShields 'intShields is the right hand side of the rectangle, which will grow smaller as the player takes more damage

        Line (449, 6)-(551, 28), RGB32(255, 255, 255), B 'draw a box for the shield indicator and set the fore color to white
        PutImage (450, 7), ddsShieldIndicator, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom)
        'blt the indicator rectangle to the screen
        DrawString 390, 10, "Shields:", RGB32(255, 200, 200) 'display some text
        If intShields < 25 Then 'if the shields are less than 25% then
            SndLoop dsAlarm 'play the alarm sound effect, and loop it
            Ship.AlarmActive = TRUE 'set the alarm flag to on
        Else 'otherwise
            SndStop dsAlarm 'make sure the alarm sound effect is off
            Ship.AlarmActive = FALSE 'the flag is set to off
        End If
    Else 'The player has died
        SndSetPos dsPlayerDies, 0 'set the dies wave to the beginning
        SndPlay dsPlayerDies 'play the explosion sound
        'TODO: If IsFF = True Then ef(3).start 1, 0                'if force feedback is enabled then start the death effect
        'TODO: If IsFF = True Then ef(2).Unload                    'disable the trigger force feedback effect
        SndStop dsAlarm 'stop playing the alarm sound effect
        'setup a rectangle structure for the explosion
        SrcRect.top = Ship.Y
        SrcRect.bottom = SrcRect.top + SHIPHEIGHT
        SrcRect.left = Ship.X
        SrcRect.right = SrcRect.left + SHIPWIDTH

        CreateExplosion SrcRect, 0, TRUE 'create an explosion where the player was
        lngTime = GetTicks 'get the current tick count
        For intCount = 0 To UBound(EnemyDesc) 'loop through all the enemies and
            EnemyDesc(intCount).Exists = FALSE 'the enemies no longer exist
            EnemyDesc(intCount).HasFired = FALSE 'the enemies' weapons no longer exist
        Next
        For intCount = 0 To UBound(GuidedMissile) 'loop through all the players guided missiles
            GuidedMissile(intCount).Exists = FALSE 'they no longer exist
        Next
        For intCount = 0 To UBound(ObstacleDesc) 'make all the obstacles non-existent
            ObstacleDesc(intCount).Exists = FALSE 'the obstacle doesn't exist
            ObstacleDesc(intCount).HasFired = FALSE 'the obstacle hasn't fired
        Next
        For intCount = 0 To UBound(PowerUp)
            PowerUp(intCount).Exists = FALSE 'if there is a power up currently on screen, get rid of it
        Next
        byteLives = byteLives - 1 'the player loses a life
        intShields = 100 'shields are at full again

        Ship.X = 300 'center the ships' X
        Ship.Y = 300 'and Y
        Ship.PowerUpState = 0 'the player is back to no powerups
        Ship.AlarmActive = FALSE 'the alarm flag is set to off
        Ship.FiringMissile = FALSE 'the firing missle flag is set to off

        SectionCount = SectionCount + 30 'Set the player back a bit
        If SectionCount > 999 Then SectionCount = 999 'Make sure we don't go over the limit
        If byteLives > 0 Then 'If the player still has lives left then
            Do Until GetTicks > lngTime + 2000 'Loop this for two seconds
                lngTargetTick = GetTicks 'get the current time
                Cls 'fill the back buffer with black
                UpdateBackground 'you seen this before
                UpdateStars 'this too
                UpdateExplosions 'same here
                UpdateWeapons 'as well as this
                DrawString 275, 200, "Lives left:" + Str$(byteLives), RGB32(255, 255, 255)
                'display a message letting the player know how many ships are left
                Display 'flip the front buffer with the back
                Do Until GetTicks - lngTargetTick > 18 'Make sure the game doesn't get out of control
                Loop 'speed-wise by looping until we reach the targeted frame rate
            Loop 'keep looping until two seconds pass
            SndSetPos dsEnergize, 0 'set the energize sound effect to the beginning
            SndPlay dsEnergize 'play the energize sound effect
            'TODO: If IsFF = True Then ef(2).Download              'start the trigger force feedback again
        Else 'If the player has no lives left
            Do Until GetTicks > lngTime + 3000 'Loop for three seconds
                lngTargetTick = GetTicks 'get the current time
                Cls 'fill the back buffer with black
                UpdateStars 'these lines are the same as above
                UpdateBackground
                UpdateExplosions
                UpdateWeapons
                DrawString 275, 200, "Game Over", RGB32(255, 255, 255)
                'display that the game is now over
                Display 'flip the front and back surfaces
                Delay 0.001 'don't hog the processor
                Do Until GetTicks - lngTargetTick > 18 'Make sure the game doesn't get out of control
                Loop
            Loop 'continues looping for three seconds
            FadeScreen FALSE 'Fade the screen to black
            intShields = 100 'shields are at 100%
            Ship.X = 300 'reset the players X
            Ship.Y = 300 'and Y coordinates
            Ship.PowerUpState = 0 'no powerups
            Ship.NumBombs = 0 'the player has no bombs
            SectionCount = 999 'start at the beginning
            byteLevel = 1 'level 1 starts over
            byteLives = 3 'the player has 3 lives left
            boolBackgroundExists = FALSE 'there is no background picture
            CheckHighScore 'call the sub to see if the player got a high score
            boolStarted = FALSE 'the game hasn't been started
        End If
    End If
End Sub


'This sub updates the animated bombs that appear at the top of the screen when the player gets one
Sub UpdateBombs
    Dim TempY As Long 'Temporary Y coordinate
    Dim TempX As Long 'Temporary X coordinate
    Dim SrcRect As Rectangle2D 'Source rectangle structure
    Dim XOffset As Long 'Offset for the X coordinate
    Dim YOffset As Long 'Offset for the Y coordinate
    Dim intCount As Long 'Count variable
    Static BombFrame As Long 'Keeps track of which animation frame the bombs are one
    Static BombCount As Long 'The number of game frames that elapse before advancing the animation frame

    If Ship.NumBombs > 0 Then 'if the player does have a bomb
        BombCount = BombCount + 1 'increment the bomb frame count
        If BombCount = 2 Then 'if we go through 2 game frames
            BombCount = 0 'reset the bomb frame count
            BombFrame = BombFrame + 1 'increment the bomb frame
            If BombFrame > 9 Then BombFrame = 0 'there are 10 frames of animation for the bomb, if the count reaches
            'the end of the number of frames, reset it to the first frame
        End If
        TempY = BombFrame \ 4 'get the temporary Y coordinate of the frame
        TempX = BombFrame - (TempY * 4) 'get the temporary X coordinate of the frame
        XOffset = CLng(TempX * 20) 'offset the rectangle by the X coordinate * the width of the frame
        YOffset = CLng(TempY * 20) 'offset the rectangle by the Y coordinate * the height of the frame
        'define the source rectangle of the bomb
        SrcRect.top = YOffset 'define the top coordinate of the rectangle
        SrcRect.bottom = SrcRect.top + 20 'the bottom is the top + the height of the bomb
        SrcRect.left = XOffset 'define the left coordinate of the bomb
        SrcRect.right = SrcRect.left + 20 'the right is the left + the width of the bomb

        For intCount = 1 To Ship.NumBombs 'loop through the number of bombs the player has
            PutImage (250 + (intCount * 22), 5), ddsDisplayBomb, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom)
            'draw as many bombs as the player has, adding a two pixel space
            'between them
        Next
    End If
End Sub


'This routine fires a missle if the player has one in his possesion
Sub FireMissile
    Dim intCount As Long 'standard count variable
    Dim lngTargetTick As Unsigned Long 'long value to hold the tick count
    Dim ExplosionRect As Rectangle2D 'rect structure that defines the position of an enemy ship
    Dim As Long w, h

    ' Screen x & y max
    w = Width - 1
    h = Height - 1

    If Ship.NumBombs = 0 Then Exit Sub 'if there aren't any missiles, exit the sub
    Ship.NumBombs = Ship.NumBombs - 1 'otherwise, decrement the number of bombs the player has
    For intCount = 0 To 255 Step 20 'cycle through the palette
        lngTargetTick = GetTicks 'get the current time and store it
        FrameCount = FrameCount + 1 'Keep track of the frame increment
        If FrameCount >= 20 Then 'When 20 frames elapsed
            SectionCount = SectionCount - 1 'Reduce the section the player is on
            UpdateLevels 'Update the section
            FrameCount = 0 'Reset the frame count
        End If

        'Since this sub will be looping until we finish manipulating the palette, we will need to call all of the normal
        'main functions from here to maintain gameplay while we are busy with this sub

        GetInput 'Get input from the player
        CheckForCollisions 'Check to see if there are any collisions
        Cls 'Fill the back buffer with black
        UpdateBackground 'Update the background bitmap, using a transparent blit
        UpdateStars 'Update the stars
        UpdateObstacles 'Update all obstacles
        UpdateEnemys 'Update the enemies
        UpdatePowerUps FALSE 'Update the powerups
        UpdateWeapons 'Update the weapon fire
        UpdateExplosions 'Update the explosions
        UpdateShip 'Update the players ship
        If Ship.Invulnerable Then UpdateInvulnerability 'If the player is invulnerable, update the invulenerability animation
        UpdateShields 'Update the shield indicator
        UpdateBombs 'Update the missile animation
        DrawString 30, 10, "Score:" + Str$(lngScore), RGB32(149, 248, 153) 'Display the score
        DrawString 175, 10, "Lives:" + Str$(byteLives), RGB32(149, 248, 153) 'Display lives left
        DrawString 560, 10, "Level:" + Str$(byteLevel), RGB32(149, 248, 153) 'Display the current level

        Line (0, 0)-(w, h), RGBA(255, 255, 255, intCount), BF 'Set the palette to our new palette entry values

        If Not boolMaxFrameRate Then
            Do Until GetTicks - lngTargetTick > 18 'Make sure the game doesn't get out of control
            Loop 'speed-wise by looping until we reach the targeted frame rate
        Else
            DrawString 30, 45, "Uncapped FPS enabled", RGB32(255, 255, 255)
            'Let the player know there is no frame rate limitation
        End If

        Display 'Flip the front buffer with the back buffer
    Next

    SndSetPos dsMissile, 0 'set the missile wav buffer position to 0
    SndPlay dsMissile 'play the missile wav
    'TODO: If IsFF = True Then ef(0).start 1, 0                        'if force feedback exists, start the missile effect
    For intCount = 0 To UBound(EnemyDesc) 'loop through all the enemies
        If EnemyDesc(intCount).Exists And Not EnemyDesc(intCount).Invulnerable Then
            'if the enemy exists on screen, and is not invulnerable
            'set the explosion rectangle coordinates
            ExplosionRect.top = EnemyDesc(intCount).Y
            ExplosionRect.bottom = ExplosionRect.top + EnemyDesc(intCount).H
            ExplosionRect.left = EnemyDesc(intCount).X
            ExplosionRect.right = ExplosionRect.left + EnemyDesc(intCount).W

            CreateExplosion ExplosionRect, EnemyDesc(intCount).ExplosionIndex, FALSE
            'call the sub that creates large explosions and plays the explosion sound

            EnemyDesc(intCount).HasFired = FALSE 'erase any existing enemy fire
            EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + 30 'the missile does 30x the normal laser 1 damage, add this value to the number of times the enemy has been hit

            If EnemyDesc(intCount).TimesHit >= EnemyDesc(intCount).TimesDies Then
                'check to see if the enemy has been hit more times than it takes for it to die, if it has
                'reset the enemy
                EnemyDesc(intCount).Exists = FALSE 'the enemy no longer exists
                EnemyDesc(intCount).TargetX = 0 'it has no x target
                EnemyDesc(intCount).TargetY = 0 'it has no y target
                EnemyDesc(intCount).TimesHit = 0 'it has never been hit
                EnemyDesc(intCount).XVelocity = 0 'there is no velocity
            End If
        End If
    Next

    'The rest of the sub takes the red index, and increments it back to black, while mainting normal gameplay procedures

    For intCount = 255 To 0 Step -5
        lngTargetTick = GetTicks
        FrameCount = FrameCount + 1
        If FrameCount >= 20 Then
            SectionCount = SectionCount - 1
            UpdateLevels
            FrameCount = 0
        End If
        GetInput
        CheckForCollisions
        Cls
        UpdateBackground
        UpdateStars
        UpdateObstacles
        UpdateEnemys
        UpdatePowerUps FALSE
        UpdateWeapons
        UpdateExplosions
        UpdateShip
        If Ship.Invulnerable Then UpdateInvulnerability
        UpdateShields
        UpdateBombs
        DrawString 30, 10, "Score:" + Str$(lngScore), RGB32(149, 248, 153)
        DrawString 175, 10, "Lives:" + Str$(byteLives), RGB32(149, 248, 153)
        DrawString 560, 10, "Level:" + Str$(byteLevel), RGB32(149, 248, 153)

        Line (0, 0)-(w, h), RGBA(255, 0, 0, intCount), BF

        If Not boolMaxFrameRate Then
            Do Until GetTicks - lngTargetTick > 18
            Loop
        Else
            DrawString 30, 45, "Uncapped FPS enabled", RGB32(255, 255, 255)
        End If
        Display
    Next

    'TODO: Do we need this? dd.WaitForVerticalBlank DDWAITVB_BLOCKBEGIN, 0

    Ship.FiringMissile = FALSE 'The ship is no longer firing a missle
End Sub


'This routine displays the ending credits, fading in and out
Sub DoCredits
    Dim lngTime As Long 'standard count
    Dim ddsEndCredits As Long 'holds the end credit direct draw surface

    ddsEndCredits = LoadImage("./dat/gfx/endcredits.gif") 'create the end credits direct draw surface
    Cls 'fill the back buffer with black
    PutImage (0, 100), ddsEndCredits 'blt the end credits to the back buffer
    FreeImage ddsEndCredits 'release our direct draw surface
    FadeScreen TRUE 'Fade the screen in
    lngTime = GetTicks 'get the current time
    Do Until GetTicks > lngTime + 1500 'loop until we have waited 1.5 seconds
        Delay 0.001 'get the current time
    Loop
    FadeScreen FALSE 'Fade the screen out

    lngTime = GetTicks 'get the current time
    Do Until GetTicks > lngTime + 500 'loop for .5 second
        Delay 0.001 'get the current time
    Loop
End Sub


'This subroutine gets input from the player using Direct Input. The boolean flag is so that the missile fire routine doesn't
'loop when a missile is fired
Sub GetInput
    Dim intCount As Long 'standard count variable
    'Dim KeyboardState(0 To 255) As Byte 'Byte array to hold the state of the keyboard
    'TODO: Dim JoystickState As DIJOYSTATE                             'joystick state type
    Dim lngTime As Long 'variable to hold the time
    Dim lngTargetTime As Long 'holds a targeted time
    Dim TempTime As Long

    ' TODO:
    'If Not diJoystick Is Nothing And blnJoystickEnabled Then    'if the joystick object has been set, and the joystick is enabled
    '    diJoystick.Acquire                                      'acquire the joystick
    '    diJoystick.Poll                                         'poll the joystick
    '    diJoystick.GetDeviceState Len(JoystickState), JoystickState  'get the current state of the joystick
    'End If

    If boolStarted And Not boolGettingInput Then 'if the game has started and we aren't getting input for high scores from the regular form key press events

        'Keyboard
        If KeyDown(DIK_UP) Then 'if the up arrow is down
            Ship.YVelocity = Ship.YVelocity - DISPLACEMENT 'the constant displacement is subtracted from the ships Y velocity
        End If
        If KeyDown(DIK_DOWN) Then 'if the down arrow is pressed down
            Ship.YVelocity = Ship.YVelocity + DISPLACEMENT 'the constant displacement is added to the ships Y velocity
        End If
        If KeyDown(DIK_LEFT) Then 'if the left arrow is pressed down
            Ship.XVelocity = Ship.XVelocity - DISPLACEMENT 'the constant displacement is subtracted from the ships X velocity
        End If
        If KeyDown(DIK_RIGHT) Then 'if the right arrow is down
            Ship.XVelocity = Ship.XVelocity + DISPLACEMENT 'the constant displacement is added to the ships X velocity
        End If
        If KeyDown(DIK_SPACE) Then 'if the space bar is down
            FireWeapon 'call the sub to fire the weapon
        End If
        If KeyDown(DIK_RCONTROL) And Ship.FiringMissile = FALSE And Ship.NumBombs > 0 Then
            Ship.FiringMissile = TRUE 'if the control key is pressed
            FireMissile 'fire the missile
        End If
        If KeyDown(DIK_LCONTROL) And Ship.FiringMissile = FALSE And Ship.NumBombs > 0 Then
            Ship.FiringMissile = TRUE 'if the control key is pressed
            FireMissile 'fire the missile
        End If

        'TODO: Joystick
        'If Not diJoystick Is Nothing And blnJoystickEnabled Then 'if the joystick object exists, and the joystick is enabled

        '    Ship.XVelocity = Ship.XVelocity + (JoystickState.x - JOYSTICKCENTERED) * 0.00002136 'increment the players x velocity by the offset from the joysticks center times the offset factor
        '    Ship.YVelocity = Ship.YVelocity + (JoystickState.y - JOYSTICKCENTERED) * 0.00002136 'increment the players x velocity by the offset from the joysticks center times the offset factor
        '    If JoystickState.buttons(0) And &H80 Then           'if button 0 is pressed
        '         FireWeapon                                 'fire the weapon
        '    End If
        '    If JoystickState.buttons(1) And &H80 And Ship.FiringMissile = False And Ship.NumBombs > 0 Then 'if button 1 is pressed, and the ship isn't firing a missile and the player has missile to fire then
        '        Ship.FiringMissile = True                       'the ship is now firing a missile
        '         FireMissile                                'fire the missile
        '    End If
        'End If

        If KeyDown(DIK_BACK) Then 'if the backspace key is pressed
            If Ship.Invulnerable Then 'if the ship is invulnerable
                SndStop dsInvulnerability 'stop playing the invulnerability sound
                TempTime = Ship.InvulnerableTime - GetTicks 'capture the current time so the player doesn't lose the amount of time he has left to be invulnerable
            End If
            If Ship.AlarmActive Then SndStop dsAlarm 'if the low shield alarm is playing, stop that
            ' pause music
            If MIDIHandle > 0 Then SndPause MIDIHandle

            DrawString 200, 200, "Paused...press Enter to start again", RGB32(255, 50, 100)
            'display the pause text
            Display 'flip the surfaces to show the back buffer
            'Check the keyboard for keypresses
            Do Until KeyDown(DIK_RETURN)
                'If the enter key is pressed, exit the loop
                Delay 0.001
            Loop
            Do Until lngTargetTime > (lngTime + 200) 'Loop for two hundred milliseconds
                lngTargetTime = GetTicks 'get the elapsed time
                Delay 0.001
            Loop
            ' resume music
            If MIDIHandle > 0 Then SndLoop MIDIHandle
            If Ship.Invulnerable Then 'if the ship was invulnerable
                SndLoop dsInvulnerability 'start the invulenrability wave again
                Ship.InvulnerableTime = TempTime + GetTicks 'the amount of time the player had left is restored
            End If
            If Ship.AlarmActive Then 'if the low shield alarm was playing
                SndLoop dsAlarm 'start it again
            End If
        End If
    Else 'The game has not started yet
        Dim KeyCode As Long

        KeyCode = KeyHit

        If boolGettingInput Then 'If the game is getting high score input then
            If KeyCode > 64 And KeyCode < 123 Then 'if the keys are alpha keys then
                strBuffer = Chr$(KeyCode) 'add this key to the buffer
            ElseIf KeyCode = 32 Then 'if a space has been entered
                strBuffer = Chr$(KeyCode) 'add it to the buffer
            ElseIf KeyCode = 13 Then 'if enter has been pressed
                boolEnterPressed = TRUE 'toggle the enter pressed flag to on
            ElseIf KeyCode = 8 Then 'if backspace was pressed
                If Len(strName) > 0 Then strName = Left$(strName, Len(strName) - 1) 'make the buffer is not empty, and delete any existing character
            End If
        ElseIf KeyCode = DIK_RETURN Then
            'if the enter key is pressed then
            boolStarted = TRUE 'the game has started
            'TODO: If Not ef(2) Is Nothing And IsFF = True Then ef(2).Download
            'download the force feedback effect for firing lasers
            FadeScreen FALSE 'fade the current screen
            StartIntro 'show the intro text
            byteLives = 3 'Set lives
            intShields = 100 'Set shields
            byteLevel = 1 'level 1 to start with
            SectionCount = 999 'start at the first section and count down
            LoadLevel byteLevel 'load level 1
            PlayMIDIFile "./dat/sfx/mus/level1.mid" 'start the level 1 midi
            For intCount = 0 To UBound(StarDesc) 'reset all the stars
                StarDesc(intCount).Exists = FALSE 'they no longer exist
            Next
        ElseIf KeyCode = DIK_ESCAPE Then 'if the escape key is pressed,
            DoCredits 'Show the credits
            EndGame 'Call sub to reset all variables
            System 'Exit the application
        ElseIf KeyCode = 102 Or KeyCode = 70 Then 'if the F key is pressed
            If boolFrameRate Then 'if the frame rate display is toggled
                boolFrameRate = FALSE 'turn it off
            Else 'otherwise
                boolFrameRate = TRUE 'turn it on
            End If
        ElseIf KeyCode = 106 Or KeyCode = 74 Then 'if the J key is pressed
            If blnJoystickEnabled Then 'if the joystick is enabled
                blnJoystickEnabled = FALSE 'turn it off
            Else 'otherwise
                blnJoystickEnabled = TRUE 'turn it on
            End If
        ElseIf (KeyCode = 109 Or KeyCode = 77) And Not boolStarted Then
            'if the M key is pressed, and the game has not started
            If blnMidiEnabled Then 'if midi is enabled
                blnMidiEnabled = FALSE 'toggle it off
                PlayMIDIFile NULLSTRING 'stop playing any midi
            Else 'otherwise
                blnMidiEnabled = TRUE 'turn the midi on
                PlayMIDIFile "./dat/sfx/mus/title.mid" 'play the title midi
            End If
        ElseIf KeyCode = 120 Or KeyCode = 88 Then 'if the X key has been pressed
            If boolMaxFrameRate Then 'if the maximum frame rate is toggled
                boolMaxFrameRate = FALSE 'toggle it off
            Else 'otherwise
                boolMaxFrameRate = TRUE 'toggle it on
            End If
        ElseIf KeyCode = 9 Then ' Wha....?
            EndGame
        End If
    End If
End Sub


' This loads an image and then make the pixel with the 'color key' transparent
Function LoadImageTransparent& (fileName As String)
    Dim handle As Long

    handle = LoadImage(fileName)
    If handle < -1 Then ClearColor RGB32(TRANSPARENT_COLOR_RED, TRANSPARENT_COLOR_GREEN, TRANSPARENT_COLOR_BLUE), handle

    LoadImageTransparent = handle
End Function


' Loads and plays a MIDI file (loops it too)
Sub PlayMIDIFile (fileName As String)
    ' Unload if there is anything previously loaded
    If MIDIHandle > 0 Then
        SndStop MIDIHandle
        SndClose MIDIHandle
        MIDIHandle = 0
    End If

    ' Check if the file exists
    If fileName <> NULLSTRING And FileExists(fileName) Then
        MIDIHandle = SndOpen(fileName, "stream")
        Assert MIDIHandle > 0
        ' Loop the MIDI file
        If MIDIHandle > 0 Then SndLoop MIDIHandle
    End If
End Sub

' Chear mouse and keyboard events
Sub ClearInput
    While MouseInput
    Wend
    KeyClear
End Sub
'---------------------------------------------------------------------------------------------------------

