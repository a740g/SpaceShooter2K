'-----------------------------------------------------------------------------------------------------------------------
' SPACE SHOOTER 2000!
' Copyright (c) 2024 Samuel Gomes
' Copyright (c) 2000 Adam "Gollum" Lonnberg
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' TODOs
'-----------------------------------------------------------------------------------------------------------------------
'   IMPROVEMENT: Remove usage of typeRect types wherever not really required
'   IMPROVEMENT: The main loop is duplicated in multiple places like FireMissile. This is not a good design and should to be refactored
'   IMPROVEMENT: String and numeric literals are littered all over the place. These should be consolidated into constants
'   IMPROVEMENT: Game controller support is missing and should be added back using AXIS, BUTTON, BUTTONCHANGE, STICK, STRIG etc.
'   IMPROVEMENT: Add mouse support using MOUSEINPUT, MOUSEMOVEMENTX, MOUSEMOVEMENTY, MOUSEBUTTON etc.
'   IMPROVEMENT: Alignment of the HUD items at the top of the screen is bad and should be corrected
'   IMPROVEMENT: FadeScreen is not used for all screen transitions and should be checked
'   IMPROVEMENT: There are some extra sprite sheets that are not used - shiptransform, shiptransform2. Use these for cool effects / upgrades?
'   IMPROVEMENT: Remove unnecessary overusage of Time_GetTicks
'   OTHER: Check any comment labeled with 'TODO'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' METACOMMANDS
'-----------------------------------------------------------------------------------------------------------------------
$ASSERTS
$VERSIONINFO:ProductName='Space Shooter 2000'
$VERSIONINFO:CompanyName='Samuel Gomes'
$VERSIONINFO:LegalCopyright='Conversion / port copyright (c) 2024 Samuel Gomes'
$VERSIONINFO:LegalTrademarks='All trademarks are property of their respective owners'
$VERSIONINFO:Web='https://github.com/a740g'
$VERSIONINFO:Comments='https://github.com/a740g'
$VERSIONINFO:InternalName='SpaceShooter2k'
$VERSIONINFO:OriginalFilename='SpaceShooter2k.exe'
$VERSIONINFO:FileDescription='Space Shooter 2000 executable'
$VERSIONINFO:FILEVERSION#=2,1,4,0
$VERSIONINFO:PRODUCTVERSION#=2,1,4,0
$EXEICON:'./SpaceShooter2k.ico'
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/TimeOps.bi'
'$INCLUDE:'include/Math/Math.bi'
'$INCLUDE:'include/GraphicOps.bi'
$IF WINDOWS THEN
    '$INCLUDE:'include/File.bi'
    '$INCLUDE:'include/WinMIDIPlayer.bi'
$END IF
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' CONSTANTS
'-----------------------------------------------------------------------------------------------------------------------
' Game constants
CONST APP_NAME = "Space Shooter 2000"

CONST SCREEN_WIDTH& = 640& ' width for the display mode
CONST SCREEN_HEIGHT& = 480& ' height for the display mode
CONST TRANSPARENT_COLOR~& = _RGB32(208, 2, 178) ' transparent color used in all GIF images assets
CONST UPDATES_PER_SECOND& = 52& ' this is the desired game FPS
CONST FADE_FPS& = UPDATES_PER_SECOND * 2& ' how fast do we want our sceen fades

' Powerup stuff
CONST SHIELD = &H0 'Constant for the shield powerup
CONST WEAPON = &H20 'Constant for the weapon powerup
CONST BOMB = &H40 'Constant for the bomb powerup
CONST INVULNERABILITY = &H60 'Constant for the invulenrability powerup

CONST SHIPWIDTH = 35 'Width of the players ship
CONST SHIPHEIGHT = 60 'Height of the players ship
CONST LASERSPEED = 9.5 'Speed of the laser fire
CONST LASER1WIDTH = 4 'Width of the stage 1 laser fire
CONST LASER1HEIGHT = 8 'Height of the stage 1 laser fire
CONST LASER2WIDTH = 8 'Width of the stage 2 laser fire
CONST LASER2HEIGHT = 8 'Height of the stage 2 laser fire
CONST LASER3HEIGHT = 5 'Height of the stage 3 laser fire
CONST LASER3WIDTH = 17 'Width of the stage 3 laser fire
CONST BOMB_WIDTH = 20 ' Width of each bomb frame
CONST BOMB_HEIGHT = 20 ' Height of each bomb frame
CONST BOMB_FRAMES = 10 ' Total frames in the bomb spritesheet
CONST ENEMY_FIRE_WIDTH = 5 ' Width of enemy fire frame
CONST ENEMY_FIRE_HEIGHT = 5 ' Height of enemy fire frame
CONST ENEMY_FIRE_FRAMES = 4 ' Number of screen frames we will show each sprite frame
CONST NUMOBSTACLES = 150 'The maximum number of second-layer objects that can appear
CONST POWERUPHEIGHT = 17 'Height of the powerups
CONST POWERUPWIDTH = 16 'Width of the powerups
CONST NUMENEMIES = 100 'How many enemies can appear on the screen at one time
CONST XMAXVELOCITY = 3 'Maximum X velocity of the ship
CONST YMAXVELOCITY = 3 'Maximum Y velocity of the ship
CONST DISPLACEMENT = 0.7 'Rate at which the velocity changes
CONST FRICTION = 0.18 'The amount of friction applied in the universe
CONST MAXMISSILEVELOCITY = 3.1 'The maximum rate a missile can go
CONST MISSILEDIMENSIONS = 4 'The width and height of the missile
CONST TARGETEDFIRE = 1 'The object aims at the player
CONST NONTARGETEDFIRE = 0 'The object just shoots straight
CONST CHASEOFF = 0 'The object doesn't follow the players' X coordinates
CONST CHASESLOW = 1 'The object does follow the players' X coordinates, but slowly
CONST CHASEFAST = 2 'The object does follow the players' X coordinates, but fast
CONST EXTRALIFETARGET = 250000 'If the player exceeds this value he gets an extra life
CONST SHIELD_MAX = 100 ' Maximum shield value
CONST BOMBS_MAX& = 4& ' Maximum number of bombs
CONST LIVES_DEFAULT = 3 ' Number lives we start with

' High score stuff
CONST HIGH_SCORE_FILENAME = "highscore.csv" ' High score file
CONST NUM_HIGH_SCORES = 10 ' Number of high scores
CONST HIGH_SCORE_TEXT_LEN = 14 ' The max length of the name in a high score
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' USER DEFINED TYPES
'-----------------------------------------------------------------------------------------------------------------------
TYPE typeRect
    left AS LONG
    top AS LONG
    right AS LONG
    bottom AS LONG
END TYPE

TYPE typeWeaponDesc 'UDT to define the weapon object
    X AS SINGLE 'X position of the weapon
    Y AS SINGLE 'Y position of the weapon
    XVelocity AS SINGLE 'The X velocity of the weapon
    YVelocity AS SINGLE 'The Y velocity of the weapon
    Damage AS _UNSIGNED _BYTE 'How many points of damage this weapon does
    StillColliding AS _BYTE 'Flag that is set when the weapon has entered a target, and is still within it
    W AS LONG 'Width of the weapon beam in pixels
    H AS LONG 'Height of the weapon beam in pixels
    Exists AS _BYTE 'Set to true if the weapon exists on screen
    TargetIndex AS _UNSIGNED _BYTE 'For guided weapons, sets the enemy target index
    TargetSet AS _BYTE 'Flag that is set once a target has been selected for the guided weapon
END TYPE

TYPE typeBackGroundDesc 'UDT to define any small background objects (stars, enemies, other objects)
    FileName AS STRING 'Name of the file
    X AS SINGLE 'X position of the B.G. object
    Y AS SINGLE 'Y position of the B.G. object
    XVelocity AS SINGLE 'X velocity of the enemy ship
    Speed AS SINGLE 'The speed the object scrolls
    ChaseValue AS _UNSIGNED _BYTE 'Flag that is set to CHASEOFF, CHASESLOW, or CHASEFAST. If the flag isn't CHASEOFF, then it sets whether or not the enemy "follows" the players movement, and if the chase rate is fast or slow
    Exists AS _BYTE 'Determines if the object exists
    HasDeadIndex AS _BYTE 'Toggles whether or not this object has a bitmap that will be displayed when it is destroyed
    DeadIndex AS LONG 'Index of picture to display when this object has been destroyed
    ExplosionIndex AS _UNSIGNED _BYTE 'The index of which explosion gets played back when this enemy is destroyed
    TimesHit AS _UNSIGNED _BYTE 'Number of times this enemy has been hit
    TimesDies AS _UNSIGNED _BYTE 'Max number of hits when enemy dies
    CollisionDamage AS _UNSIGNED _BYTE 'If the player collides with this enemy, the amount of damage it does
    Score AS LONG 'The score added to the player when this is destroyed
    Index AS _UNSIGNED LONG 'Index of the container for this bitmap -or- How many frames the bitmap has existed
    Frame AS _UNSIGNED _BYTE 'The current frame number
    NumFrames AS _UNSIGNED _BYTE 'The number of frames the bitmap contains/How many frames the bitmap should exist
    FrameDelay AS _UNSIGNED _BYTE 'Used to delay the incrementing of frames to slow down frame animation, if needed
    FrameDelayCount AS _UNSIGNED _BYTE 'Used to store the current frame delay number count
    W AS LONG 'the width of one frame
    H AS LONG 'the height of one frame
    DoesFire AS _BYTE 'Does this object fire a weapon?
    FireType AS _UNSIGNED _BYTE 'The style of fire the object uses (targeted or non-targeted)
    HasFired AS _BYTE 'Has this enemy fired its' weapon
    Invulnerable AS _BYTE 'Can this object be hit with weapon fire?
    XFire AS SINGLE 'X position of the weapon fire
    YFire AS SINGLE 'Y position of the weapon fire
    FireFrame AS _UNSIGNED _BYTE 'Frame of the weapon fire
    FireFrameCount AS _UNSIGNED _BYTE 'Used to indicate when it is time to change the animation frame of the enemy fire
    TargetX AS SINGLE 'X vector of the weapon fire direction
    TargetY AS SINGLE 'Y vector of the weapon fire direction
    Solid AS _BYTE 'Toggles whether this item needs to be blitted transparent or not
END TYPE

TYPE typeShipDesc 'UDT to define the players' ship bitmap
    PowerUpState AS _UNSIGNED _BYTE 'Determines how many levels of power-ups the player has
    Invulnerable AS _BYTE 'Determines whether or not the player is invulnerable
    InvulnerableTime AS _INTEGER64 'Used to keep track of the amount of time the player has left when invulnerable
    X AS SINGLE 'X of the ship
    Y AS SINGLE 'Y of the ship
    XOffset AS LONG 'X Offset of the animation frame
    YOffset AS LONG 'Y Offset of the animation frame
    XVelocity AS SINGLE 'X velocity of the ship
    YVelocity AS SINGLE 'Y velocity of the ship
    NumBombs AS LONG 'the number of super bombs the player has
    AlarmActive AS _BYTE 'Determines if the alarm sound is being played so it can be turned off temporarily when the game is paused
    FiringMissile AS _BYTE 'Toggles whether the ship is currently firing a missile
END TYPE

TYPE typeBackgroundObject 'UDT to define background pictures
    FileName AS STRING 'Path to the bitmap of the background object
    X AS SINGLE 'X position of the object
    Y AS SINGLE 'Y position of the object
    W AS LONG 'Width of the B.G. object
    H AS LONG 'Height of the B.G. object
END TYPE

TYPE typeHighScore
    text AS STRING
    score AS LONG
END TYPE
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' GLOBAL VARIABLES
'-----------------------------------------------------------------------------------------------------------------------
'Array to define the section information for each level.
'Each section contains 125 slots. The value of each slot refers to the index of the object contained in that slot. -1 means no object is in this slot.
DIM SHARED SectionInfo(0 TO 999, 0 TO 125) AS _UNSIGNED _BYTE 'There are 1000 sections to a level
DIM SHARED ObstacleInfo(0 TO 999, 0 TO 125) AS _UNSIGNED _BYTE 'There are 1000 obstacle sections to a level

' Game bitmaps
DIM SHARED ddsShip AS LONG 'Ship bitmap
DIM SHARED ddsLaser AS LONG 'Laser 1 laser surface
DIM SHARED ddsLaser2R AS LONG 'Right diagonal laser
DIM SHARED ddsLaser2L AS LONG 'Left diagonal laser
DIM SHARED ddsLaser3 AS LONG 'Laser 3 laser surface
DIM SHARED ddsGuidedMissile AS LONG 'Guided Missile
DIM SHARED ddsEnemyFire AS LONG 'Enemy laser fire
DIM SHARED ddsPowerUp AS LONG 'Power Up dd surface
DIM SHARED ddsTitle AS LONG 'Title Screen surface
DIM SHARED ddsHit AS LONG 'Direct draw surface for small explosions
DIM SHARED ddsBackgroundObject(0 TO 7) AS LONG 'Background objects
DIM SHARED ddsEnemyContainer(0 TO 13) AS LONG 'Enemy surface container
DIM SHARED ddsExplosion(0 TO 1) AS LONG 'Explosion surfaces
DIM SHARED ddsObstacle(0 TO 40) AS LONG 'Obstacle direct draw surfaces
DIM SHARED ddsDisplayBomb AS LONG 'Bomb direct draw surface
DIM SHARED ddsInvulnerable AS LONG 'Invulnerable bitmap surface

'Sound Section
DIM SHARED dsLaser2 AS LONG 'stage 2 laser fire buffer
DIM SHARED dsLaser AS LONG 'stage 1 laser fire
DIM SHARED dsExplosion AS LONG 'explosion sound effect
DIM SHARED dsPowerUp AS LONG 'power up sound effect buffer
DIM SHARED dsMissile AS LONG 'missile sound effect buffer
DIM SHARED dsEnergize AS LONG 'sound effect for when the player materializes
DIM SHARED dsAlarm AS LONG 'low shield alarm
DIM SHARED dsEnemyFire AS LONG 'enemy fire direct sound buffer
DIM SHARED dsNoHit AS LONG 'player hits an object that isn't destroyed
DIM SHARED dsPulseCannon AS LONG 'sound for the pulse cannon
DIM SHARED dsPlayerDies AS LONG 'sound for when the player dies
DIM SHARED dsInvulnerability AS LONG 'sound for when the player is invulnerable
DIM SHARED dsInvPowerDown AS LONG 'sound for when the invulnerability wears off
DIM SHARED dsExtraLife AS LONG 'sound for when the player gets an extra life

$IF LINUX OR MACOSX THEN
        DIM SHARED MIDIHandle AS LONG ' MIDI music handle
$END IF

'Variables to handle graphics
DIM SHARED boolBackgroundExists AS _BYTE 'Boolean to determine if a background object exists
DIM SHARED sngBackgroundX AS SINGLE 'X coordinate of the background image
DIM SHARED sngBackgroundY AS SINGLE 'Y coordinate of the background image
DIM SHARED intObjectIndex AS LONG 'The index number of the object
DIM SHARED intShipFrameCount AS LONG 'The frame number of the players ship
DIM SHARED Ship AS typeShipDesc 'Set up the players ship
DIM SHARED LaserDesc(0 TO 14) AS typeWeaponDesc 'Set up an array for 15 laser blasts
DIM SHARED Laser2RDesc(0 TO 6) AS typeWeaponDesc 'Set up an array for 7 right diagonal laser blasts
DIM SHARED Laser2LDesc(0 TO 6) AS typeWeaponDesc 'Set up an array for 7 left diagonal laser blasts
DIM SHARED Laser3Desc(0 TO 2) AS typeWeaponDesc 'Set up an array for 3 laser 3 blasts
DIM SHARED GuidedMissile(0 TO 2) AS typeWeaponDesc 'Set up an array for 3 guided missiles
DIM SHARED StarDesc(0 TO 49) AS typeBackGroundDesc 'Set up an array for 50 stars
DIM SHARED EnemyDesc(0 TO NUMENEMIES) AS typeBackGroundDesc 'Set up an array for all enemies
DIM SHARED EnemyContainerDesc(0 TO 13) AS typeBackGroundDesc 'Set up an array for the enemy containers descriptions
DIM SHARED ObstacleContainerInfo(0 TO 40) AS typeBackGroundDesc
'Background objects container
DIM SHARED ObstacleDesc(0 TO NUMOBSTACLES) AS typeBackGroundDesc
'Background objects
DIM SHARED BackgroundObject(0 TO 7) AS typeBackgroundObject 'Set up an array for 8 large background pictures
DIM SHARED PowerUp(0 TO 3) AS typeBackGroundDesc 'Set up an array for the power ups
DIM SHARED HitDesc(0 TO 19) AS typeBackGroundDesc 'Set an array for small explosions when an object is hit
DIM SHARED ExplosionDesc(0 TO 80) AS typeBackGroundDesc 'Array for explosions

'Input stuff
'Dim Shared IsJ As Byte 'Flag that is set if a joystick is present
'Dim Shared IsFF As Byte 'Flag that is set if force feedback is present

'Player Info
DIM SHARED byteLives AS _UNSIGNED _BYTE 'Number of lives the player has left
DIM SHARED intShields AS LONG 'The amount of shields the player has left
DIM SHARED intEnemiesKilled AS LONG 'The number of enemies the player has destroyed. For every 30 enemies destroyed, a powerup will appear
DIM SHARED lngScore AS LONG 'Players score
DIM SHARED lngNextExtraLifeScore AS LONG 'The next score the player gets an extra life at
DIM SHARED lngNumEnemiesKilled AS LONG 'The number of enemies killed
DIM SHARED lngTotalNumEnemies AS LONG 'The total number of enemies on the level
DIM SHARED byteLevel AS _UNSIGNED _BYTE 'Players level
DIM SHARED strName AS STRING 'Players name when they get a high score

'The rest are miscellaneous variables
DIM SHARED SectionCount AS LONG 'Keeps track of what section the player is on
DIM SHARED FrameCount AS LONG 'keeps track of the number of accumulated frames. When it reaches 20, a new section is added
DIM SHARED boolStarted AS _BYTE 'Determines whether a game is running or not
DIM SHARED HighScore(0 TO NUM_HIGH_SCORES - 1) AS typeHighScore 'Keeps track of high scores
DIM SHARED byteNewHighScore AS _UNSIGNED _BYTE 'index of a new high score to paint the name color differently
DIM SHARED strBuffer AS STRING 'Buffer to pass keypresses
DIM SHARED boolEnterPressed AS _BYTE 'Flag to determine if the enter key was pressed
DIM SHARED boolGettingInput AS _BYTE 'Flag to see if we are getting input from the player
DIM SHARED boolFrameRate AS _BYTE 'Flag to toggle frame rate display on and off
DIM SHARED strLevelText AS STRING 'Stores the associated startup text for the level
DIM SHARED blnJoystickEnabled AS _BYTE 'Toggles joystick on or off
DIM SHARED blnMIDIEnabled AS _BYTE 'Toggles Midi music on or off
DIM SHARED boolMaxFrameRate AS _BYTE 'Removes all frame rate limits
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' PROGRAM ENTRY POINT - This is the entry point for the game. From here everything branches out to all the
' subs that handle collisions, enemies, player, weapon fire, sounds, level updating, etc.
'-----------------------------------------------------------------------------------------------------------------------
InitializeStartup 'Do the startup routines
LoadHighScores 'Call the sub to load the high scores
lngNextExtraLifeScore = EXTRALIFETARGET 'Initialize the extra life score to 100,000
SLEEP 1 ' Wait for a second
Graphics_FadeScreen _FALSE, FADE_FPS, 100 ' Fade out the loading screen
ClearInput ' Clear any cached input

DO 'The main loop of the game.
    GetInput 'call sub that checks for player input
    CLS 'fill the back buffer with black
    UpdateBackground 'Update the background bitmaps
    UpdateStars 'Update the stars
    IF boolStarted AND NOT boolGettingInput THEN 'If the game has started, and we are not getting high score input from the player
        FrameCount = FrameCount + 1 'Keep track of the frame increment
        IF FrameCount >= 20 THEN 'When 20 frames elapsed
            SectionCount = SectionCount - 1 'Reduce the section the player is on
            UpdateLevels 'Update the section
            FrameCount = 0 'Reset the frame count
        END IF
        UpdateObstacles 'Update the back layer of objects
        UpdateEnemys 'Move and draw the enemys
        UpdatePowerUps _FALSE 'Move and draw the power ups
        UpdateHits _FALSE, 0, 0 'Update the small explosions
        UpdateWeapons 'Move and draw the weapons
        UpdateExplosions 'Update any large explosions
        UpdateShip 'Move and draw the ship
        IF Ship.Invulnerable THEN UpdateInvulnerability 'if the player is invulnerable, then update the invulnerability effect
        CheckForCollisions 'Branch to collision checking subs
        UpdateShields 'Branch to sub that paints shields
        UpdateBombs
        DrawString "Score:" + STR$(lngScore), 30, 10, BGRA_PALEGREEN
        'Display the score
        DrawString "Lives:" + STR$(byteLives), 175, 10, BGRA_PALEGREEN 'Display lives left.
        DrawString "Level:" + STR$(byteLevel), 560, 10, BGRA_PALEGREEN 'Display the current level
        CheckScore
    ELSEIF NOT boolStarted AND NOT boolGettingInput THEN 'If we haven't started, and we aren't getting high score input from the player
        ShowTitle 'Show the title screen with high scores and directions
    ELSEIF boolGettingInput THEN 'If we are getting input from the player, then
        CheckHighScore 'call the high score subroutine
    END IF

    IF boolFrameRate THEN DrawString "FPS:" + STR$(Time_GetHertz), 30, 30, BGRA_WHITE 'display the frame rate

    IF boolMaxFrameRate THEN
        DrawString "Uncapped FPS enabled", 30, 45, BGRA_WHITE 'Let the player know there is no frame rate limitation
    ELSE
        _LIMIT UPDATES_PER_SECOND ' Make sure the game doesn't get out of control
    END IF

    _DISPLAY 'Flip the front buffer with the back

    IF boolStarted AND _KEYDOWN(_KEY_ESC) THEN 'If the game has started, and the player presses escape
        'TODO: If IsFF = True Then ef(2).Unload                            'unload the laser force feedback effect
        ResetGame 'call the sub to reset the game variables
    END IF 'If the escape key is preseed, reset the game and go back to the title screen
LOOP 'keep looping endlessly

END 1 ' It should not come here
'---------------------------------------------------------------------------------------------------------

'---------------------------------------------------------------------------------------------------------
' FUNCTIONS & SUBROUTINES
'---------------------------------------------------------------------------------------------------------
'This sub resets all the variables in the game that need to be reset when the game is started over.
SUB ResetGame
    DIM intCount AS LONG 'variable for looping

    FOR intCount = 0 TO UBOUND(EnemyDesc) 'loop through all the enemies and
        EnemyDesc(intCount).Exists = _FALSE 'the enemies no longer exist
        EnemyDesc(intCount).HasFired = _FALSE 'the enemies' wepaons no longer exist
    NEXT
    FOR intCount = 0 TO UBOUND(GuidedMissile) 'loop through all the players guided missiles
        GuidedMissile(intCount).Exists = _FALSE 'they no longer exist
    NEXT
    FOR intCount = 0 TO UBOUND(ObstacleDesc) 'make all the obstacles non-existent
        ObstacleDesc(intCount).Exists = _FALSE
        ObstacleDesc(intCount).HasFired = _FALSE
    NEXT
    FOR intCount = 0 TO UBOUND(ExplosionDesc) 'Make sure that no explosions get left over
        ExplosionDesc(intCount).Exists = _FALSE
    NEXT
    FOR intCount = 0 TO UBOUND(PowerUp)
        PowerUp(intCount).Exists = _FALSE 'if there are any power ups currently on screen, get rid of them
    NEXT

    Graphics_FadeScreen _FALSE, FADE_FPS, 100 'Fade the screen to black

    intShields = SHIELD_MAX 'shields are at 100%

    Ship.X = 300 'center the ships' X
    Ship.Y = 300 'and Y
    Ship.PowerUpState = 0 'the player is back to no powerups
    Ship.PowerUpState = 0 'no powerups
    Ship.NumBombs = 0 'the player has no bombs
    Ship.Invulnerable = _FALSE 'the player is no longer invulnerable if he was
    Ship.AlarmActive = _FALSE 'the low shield alarm no longer needs to be flagged
    Ship.FiringMissile = _FALSE 'the ship is not firing a missile

    _SNDSTOP dsInvulnerability 'make sure the invulnerability sound effect is not playing
    _SNDSTOP dsAlarm 'make sure the alarm sound effect is not playing
    boolStarted = _FALSE 'the game hasn't been started
    SectionCount = 999 'start at the beginning of the level
    byteLevel = 1 'player is at level 1 again
    byteLives = LIVES_DEFAULT 'the player has 3 lives left
    boolBackgroundExists = _FALSE 'there is no background picture
    CheckHighScore 'call the sub to see if the player got a high score
END SUB


'This sub initializes all neccessary objects, classes, variables, and user-defined types
SUB InitializeStartup
    Math_SetRandomSeed TIMER ' Seed randomizer

    $RESIZE:SMOOTH
    SCREEN _NEWIMAGE(SCREEN_WIDTH, SCREEN_HEIGHT, 32) ' Initialize graphics
    _FULLSCREEN _SQUAREPIXELS , _SMOOTH ' Set to fullscreen. We can also go to windowed mode using Alt+Enter
    _PRINTMODE _KEEPBACKGROUND ' We want transparent text rendering

    _TITLE APP_NAME ' Set the Window title

    _DISPLAY ' We want the framebuffer to be updated when we want

    _MOUSEHIDE 'don't show the cursor while DX is active
    blnMIDIEnabled = _TRUE 'turn on the midi by default
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
    EnemyContainerDesc(0).DoesFire = _TRUE 'This enemy fires a weapon
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
    EnemyContainerDesc(1).DoesFire = _TRUE
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
    EnemyContainerDesc(2).DoesFire = _TRUE
    EnemyContainerDesc(2).CollisionDamage = 5

    EnemyContainerDesc(3).FileName = "enemy4.gif"
    EnemyContainerDesc(3).H = 90
    EnemyContainerDesc(3).W = 38
    EnemyContainerDesc(3).NumFrames = 60
    EnemyContainerDesc(3).TimesDies = 1
    EnemyContainerDesc(3).ExplosionIndex = 1
    EnemyContainerDesc(3).Score = 300
    EnemyContainerDesc(3).Speed = 4
    EnemyContainerDesc(3).DoesFire = _TRUE
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
    EnemyContainerDesc(9).DoesFire = _TRUE
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
    EnemyContainerDesc(10).DoesFire = _TRUE
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
    EnemyContainerDesc(13).DoesFire = _TRUE
    EnemyContainerDesc(13).FireType = TARGETEDFIRE

    ObstacleContainerInfo(0).FileName = "plate1.gif"
    ObstacleContainerInfo(0).H = 80
    ObstacleContainerInfo(0).W = 80
    ObstacleContainerInfo(0).Invulnerable = _TRUE
    ObstacleContainerInfo(0).Speed = 1

    ObstacleContainerInfo(1).FileName = "movingplate.gif"
    ObstacleContainerInfo(1).H = 40
    ObstacleContainerInfo(1).W = 40
    ObstacleContainerInfo(1).HasDeadIndex = _TRUE
    ObstacleContainerInfo(1).DeadIndex = 40
    ObstacleContainerInfo(1).DoesFire = _TRUE
    ObstacleContainerInfo(1).FireType = NONTARGETEDFIRE
    ObstacleContainerInfo(1).TimesDies = 5
    ObstacleContainerInfo(1).ExplosionIndex = 0
    ObstacleContainerInfo(1).Score = 600
    ObstacleContainerInfo(1).Speed = 1
    ObstacleContainerInfo(1).Solid = _TRUE
    ObstacleContainerInfo(1).NumFrames = 39

    ObstacleContainerInfo(2).FileName = "plate3.gif"
    ObstacleContainerInfo(2).H = 40
    ObstacleContainerInfo(2).W = 40
    ObstacleContainerInfo(2).CollisionDamage = 100
    ObstacleContainerInfo(2).Speed = 1
    ObstacleContainerInfo(2).Solid = _TRUE
    ObstacleContainerInfo(2).HasDeadIndex = _TRUE
    ObstacleContainerInfo(2).DeadIndex = 40
    ObstacleContainerInfo(2).TimesDies = 3
    ObstacleContainerInfo(2).ExplosionIndex = 1
    ObstacleContainerInfo(2).Score = 400

    ObstacleContainerInfo(3).FileName = "plate4.gif"
    ObstacleContainerInfo(3).H = 40
    ObstacleContainerInfo(3).W = 40
    ObstacleContainerInfo(3).Invulnerable = _TRUE
    ObstacleContainerInfo(3).Speed = 1
    ObstacleContainerInfo(3).Solid = _TRUE

    ObstacleContainerInfo(4).FileName = "plate5.gif"
    ObstacleContainerInfo(4).H = 40
    ObstacleContainerInfo(4).W = 40
    ObstacleContainerInfo(4).HasDeadIndex = _TRUE
    ObstacleContainerInfo(4).DeadIndex = 40
    ObstacleContainerInfo(4).TimesDies = 3
    ObstacleContainerInfo(4).ExplosionIndex = 0
    ObstacleContainerInfo(4).Speed = 1
    ObstacleContainerInfo(4).Solid = _TRUE
    ObstacleContainerInfo(4).Score = 400

    ObstacleContainerInfo(5).FileName = "plate6.gif"
    ObstacleContainerInfo(5).H = 40
    ObstacleContainerInfo(5).W = 40
    ObstacleContainerInfo(5).Invulnerable = _TRUE
    ObstacleContainerInfo(5).Speed = 1

    ObstacleContainerInfo(6).FileName = "plate7.gif"
    ObstacleContainerInfo(6).H = 40
    ObstacleContainerInfo(6).W = 40
    ObstacleContainerInfo(6).Invulnerable = _TRUE
    ObstacleContainerInfo(6).Speed = 1

    ObstacleContainerInfo(7).FileName = "plate8.gif"
    ObstacleContainerInfo(7).H = 40
    ObstacleContainerInfo(7).W = 40
    ObstacleContainerInfo(7).Invulnerable = _TRUE
    ObstacleContainerInfo(7).Speed = 1

    ObstacleContainerInfo(8).FileName = "plate9.gif"
    ObstacleContainerInfo(8).H = 40
    ObstacleContainerInfo(8).W = 40
    ObstacleContainerInfo(8).Invulnerable = _TRUE
    ObstacleContainerInfo(8).Speed = 1

    ObstacleContainerInfo(9).FileName = "plate10.gif"
    ObstacleContainerInfo(9).H = 40
    ObstacleContainerInfo(9).W = 40
    ObstacleContainerInfo(9).Invulnerable = _TRUE
    ObstacleContainerInfo(9).Speed = 1

    ObstacleContainerInfo(10).FileName = "plate11.gif"
    ObstacleContainerInfo(10).H = 40
    ObstacleContainerInfo(10).W = 40
    ObstacleContainerInfo(10).Invulnerable = _TRUE
    ObstacleContainerInfo(10).Speed = 1

    ObstacleContainerInfo(11).FileName = "plate12.gif"
    ObstacleContainerInfo(11).H = 40
    ObstacleContainerInfo(11).W = 40
    ObstacleContainerInfo(11).Invulnerable = _TRUE
    ObstacleContainerInfo(11).Speed = 1

    ObstacleContainerInfo(12).FileName = "plate13.gif"
    ObstacleContainerInfo(12).H = 40
    ObstacleContainerInfo(12).W = 40
    ObstacleContainerInfo(12).Invulnerable = _TRUE
    ObstacleContainerInfo(12).Speed = 1

    ObstacleContainerInfo(13).FileName = "plate2.gif"
    ObstacleContainerInfo(13).H = 40
    ObstacleContainerInfo(13).W = 40
    ObstacleContainerInfo(13).HasDeadIndex = _TRUE
    ObstacleContainerInfo(13).DeadIndex = 40
    ObstacleContainerInfo(13).Speed = 1
    ObstacleContainerInfo(13).Solid = _TRUE
    ObstacleContainerInfo(13).TimesDies = 3
    ObstacleContainerInfo(13).ExplosionIndex = 1
    ObstacleContainerInfo(13).Score = 450

    ObstacleContainerInfo(14).FileName = "plate14.gif"
    ObstacleContainerInfo(14).H = 40
    ObstacleContainerInfo(14).W = 40
    ObstacleContainerInfo(14).HasDeadIndex = _TRUE
    ObstacleContainerInfo(14).DeadIndex = 40
    ObstacleContainerInfo(14).Speed = 1
    ObstacleContainerInfo(14).Solid = _TRUE
    ObstacleContainerInfo(14).TimesDies = 3
    ObstacleContainerInfo(14).ExplosionIndex = 0
    ObstacleContainerInfo(14).Score = 350

    ObstacleContainerInfo(15).FileName = "plate15.gif"
    ObstacleContainerInfo(15).H = 40
    ObstacleContainerInfo(15).W = 40
    ObstacleContainerInfo(15).HasDeadIndex = _TRUE
    ObstacleContainerInfo(15).DeadIndex = 40
    ObstacleContainerInfo(15).Speed = 1
    ObstacleContainerInfo(15).Solid = _TRUE
    ObstacleContainerInfo(15).TimesDies = 3
    ObstacleContainerInfo(15).ExplosionIndex = 1
    ObstacleContainerInfo(15).Score = 450

    ObstacleContainerInfo(40).FileName = "deadplate.gif"
    ObstacleContainerInfo(40).H = 40
    ObstacleContainerInfo(40).W = 40
    ObstacleContainerInfo(40).Invulnerable = _TRUE
    ObstacleContainerInfo(40).Speed = 1
    ObstacleContainerInfo(40).NumFrames = 23
    ObstacleContainerInfo(40).DeadIndex = 40
    ObstacleContainerInfo(40).Solid = _TRUE

    'Setup the data for all the background bitmaps

    BackgroundObject(0).FileName = "nebulae1.gif"
    BackgroundObject(0).W = 600
    BackgroundObject(0).H = 400

    BackgroundObject(1).FileName = "asteroid field.gif"
    BackgroundObject(1).W = 600
    BackgroundObject(1).H = 400

    BackgroundObject(2).FileName = "red giant.gif"
    BackgroundObject(2).W = 600
    BackgroundObject(2).H = 400

    BackgroundObject(3).FileName = "nebulae2.gif"
    BackgroundObject(3).W = 600
    BackgroundObject(3).H = 400

    BackgroundObject(4).FileName = "cometary.gif"
    BackgroundObject(4).W = 600
    BackgroundObject(4).H = 460

    BackgroundObject(5).FileName = "nebulae5.gif"
    BackgroundObject(5).W = 600
    BackgroundObject(5).H = 400

    BackgroundObject(6).FileName = "nebulae3.gif"
    BackgroundObject(6).W = 600
    BackgroundObject(6).H = 400

    BackgroundObject(7).FileName = "nebulae4.gif"
    BackgroundObject(7).W = 600
    BackgroundObject(7).H = 400
END SUB


' Loads the high score file from disk
' If a high score file cannot be found or cannot be read, a default list of high-score entries is created
SUB LoadHighScores
    IF _FILEEXISTS(HIGH_SCORE_FILENAME) THEN
        DIM i AS INTEGER
        DIM hsFile AS LONG

        ' Open the highscore file
        hsFile = FREEFILE
        OPEN HIGH_SCORE_FILENAME FOR INPUT AS hsFile

        ' Read the name and the scores
        FOR i = 0 TO NUM_HIGH_SCORES - 1
            INPUT #hsFile, HighScore(i).text, HighScore(i).score
            HighScore(i).text = _TRIM$(HighScore(i).text) 'trim the highscorename variable of all spaces and assign it to the name array
        NEXT

        ' Close file
        CLOSE hsFile
    ELSE
        ' Load default highscores if there is no highscore file

        HighScore(0).text = "Major Stryker"
        HighScore(0).score = 70000

        HighScore(1).text = "Sam Stone"
        HighScore(1).score = 60000

        HighScore(2).text = "Commander Keen"
        HighScore(2).score = 55000

        HighScore(3).text = "Gordon Freeman"
        HighScore(3).score = 50000

        HighScore(4).text = "Max Payne"
        HighScore(4).score = 40000

        HighScore(5).text = "Lara Croft"
        HighScore(5).score = 35000

        HighScore(6).text = "Duke Nukem"
        HighScore(6).score = 30000

        HighScore(7).text = "Master Chief"
        HighScore(7).score = 20000

        HighScore(8).text = "Marcus Fenix"
        HighScore(8).score = 15000

        HighScore(9).text = "John Blade"
        HighScore(9).score = 10000
    END IF
END SUB


' Writes the HighScore array out to the high score file
SUB SaveHighScores
    DIM i AS INTEGER
    DIM hsFile AS LONG

    ' Open the file for writing
    hsFile = FREEFILE
    OPEN HIGH_SCORE_FILENAME FOR OUTPUT AS hsFile

    FOR i = 0 TO NUM_HIGH_SCORES - 1
        HighScore(i).text = _TRIM$(HighScore(i).text) 'trim the highscorename variable of all spaces and assign it to the name array
        WRITE #hsFile, HighScore(i).text, HighScore(i).score
    NEXT

    CLOSE hsFile
END SUB


'This routine checks the current score, and determines if it has gone past the extra life threshold.
'If it has, then display that the player has gained an extra life, and give the player an extra life
SUB CheckScore
    STATIC blnExtraLifeDisplay AS _BYTE 'Flag that is set if an extra life message needs to be displayed
    STATIC lngTargetTime AS _INTEGER64 'Variable used to hold the targeted time

    IF lngScore > lngNextExtraLifeScore THEN 'If the current score is larger than the score needed to get an extra life
        lngNextExtraLifeScore = lngNextExtraLifeScore + EXTRALIFETARGET 'Increase the extra life target score
        _SNDSETPOS dsExtraLife, 0 'Set the extra life wave position to the beginning
        _SNDPLAY dsExtraLife 'Play the extra life wave file
        blnExtraLifeDisplay = _TRUE 'Toggle the extra life display flag to on
        lngTargetTime = Time_GetTicks + 3000 'Set the end time for displaying the extra life message
        byteLives = byteLives + 1 'increase the players life by 1
    END IF

    IF lngTargetTime > Time_GetTicks AND blnExtraLifeDisplay THEN 'As long as the target time is larger than the current time, and the extra life display flag is set
        DrawStringCenter "EXTRA LIFE!", 250, BGRA_TOMATO 'Display the extra life message
    ELSE
        blnExtraLifeDisplay = _FALSE 'Otherwise, if we have gone past the display duration, turn the display flag off
    END IF
END SUB


'This sub displays the title screen, and rotates one of the palette indexes from blue to black
SUB ShowTitle
    STATIC colorDirection AS _BYTE
    DIM AS _UNSIGNED LONG i, c

    IF colorDirection = 0 THEN colorDirection = 5 ' kickstart the palette animation

    _PUTIMAGE (200, 42), ddsTitle 'blit the entire title screen bitmap to the backbuffer

    ' See the comment on ddsTitle = LoadImage(..., 257)
    ' Again here index 8 is from trial-and-error. However, it was easy to find because those pixels are at top (beginning)
    c = _PALETTECOLOR(8, ddsTitle)
    _PALETTECOLOR 8, _RGB32(_RED(c), _GREEN(c), _BLUE(c) + colorDirection), ddsTitle

    IF _BLUE(c) > 245 THEN colorDirection = -5
    IF _BLUE(c) < 5 THEN colorDirection = 5

    DrawStringCenter STRING$(9, 205) + " HIGH SCORES " + STRING$(9, 205), 250, BGRA_PEACHPUFF 'Display the high scores message

    FOR i = 0 TO NUM_HIGH_SCORES - 1 'loop through the 10 high scores
        IF i = byteNewHighScore THEN
            DrawStringCenter RIGHT$(" " + STR$(i + 1), 2) + ". " + LEFT$(HighScore(i).text + SPACE$(HIGH_SCORE_TEXT_LEN), HIGH_SCORE_TEXT_LEN) + "  " + RIGHT$(SPACE$(10) + STR$(HighScore(i).score), 11), 265 + i * 16, BGRA_YELLOW
        ELSE
            DrawStringCenter RIGHT$(" " + STR$(i + 1), 2) + ". " + LEFT$(HighScore(i).text + SPACE$(HIGH_SCORE_TEXT_LEN), HIGH_SCORE_TEXT_LEN) + "  " + RIGHT$(SPACE$(10) + STR$(HighScore(i).score), 11), 265 + i * 16, BGRA_ROYALBLUE
        END IF
    NEXT

    IF blnMIDIEnabled THEN 'if midi is enabled
        DrawStringCenter "Press M to toggle music. Music: Enabled", 435, BGRA_FORESTGREEN 'display this message
    ELSE 'otherwise
        DrawStringCenter "Press M to toggle music. Music: Disabled", 435, BGRA_DARKGREEN 'display this message
    END IF

    IF blnJoystickEnabled THEN 'if the joystick is enabled display this message
        DrawStringCenter "Press J to toggle joystick. Joystick: Enabled", 450, BGRA_FORESTGREEN 'display this message
    ELSE 'otherwise
        DrawStringCenter "Press J to toggle joystick. Joystick: Disabled", 450, BGRA_DARKGREEN 'display this message
    END IF
END SUB


'This sub initializes Direct Draw and loads up all the surfaces
SUB InitializeDD
    DIM ddsSplash AS LONG ' dim a direct draw surface

    ddsSplash = Graphics_LoadImage("./dat/gfx/splash.gif", _FALSE, _FALSE, _STR_EMPTY, -1) 'create the splash screen surface
    _ASSERT ddsSplash < -1

    _PUTIMAGE , ddsSplash ' blit the splash screen to the back buffer
    DrawString _OS$, 0, _HEIGHT - _UFONTHEIGHT, BGRA_WHITE ' overlay the OS string on the bottom left side

    _FREEIMAGE ddsSplash ' release the splash screen, since we don't need it anymore

    Graphics_FadeScreen _TRUE, FADE_FPS, 100 ' flip the front buffer so the splash screen bitmap on the backbuffer is displayed
    PlayMIDIFile "./dat/sfx/mus/title.mid" ' Start playing the title song

    ddsTitle = Graphics_LoadImage("./dat/gfx/title.gif", _TRUE, _FALSE, "ADAPTIVE", -1) ' Load the title screen bitmap in 8bpp mode for palette tricks
    _ASSERT ddsTitle < -1
    ' Due to the way the internal QB64-PE 256 color conversion works, the first pixel color is stored at index 0
    ' How do I know this? Well, I wrote it! :)
    _CLEARCOLOR 0, ddsTitle

    ddsShip = Graphics_LoadImage("./dat/gfx/ship.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR) 'Load the ship bitmap and make it into a direct draw surface
    _ASSERT ddsShip < -1

    ddsPowerUp = Graphics_LoadImage("./dat/gfx/powerups.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR) 'Load the shield indicator bitmap and put in a direct draw surface
    _ASSERT ddsPowerUp < -1

    ddsExplosion(0) = Graphics_LoadImage("./dat/gfx/explosion.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR) 'Load the first explosion bitmap
    _ASSERT ddsExplosion(0) < -1

    ddsExplosion(1) = Graphics_LoadImage("./dat/gfx/explosion2.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR) 'Load the second explosion bitmap
    _ASSERT ddsExplosion(1) < -1

    ddsInvulnerable = Graphics_LoadImage("./dat/gfx/invulnerable.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR) 'Load the invulnerable bitmap
    _ASSERT ddsInvulnerable < -1

    DIM intCount AS LONG 'count variable

    'The rest of the sub just describes the various attributes of the enemies, obstacles, and background bitmaps, and
    'loads the neccessary objets into direct draw surfaces
    FOR intCount = 0 TO UBOUND(ExplosionDesc)
        ExplosionDesc(intCount).NumFrames = 19
        ExplosionDesc(intCount).W = 120
        ExplosionDesc(intCount).H = 120
    NEXT

    ddsHit = Graphics_LoadImage("./dat/gfx/hit.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR)
    _ASSERT ddsHit < -1

    FOR intCount = 0 TO UBOUND(HitDesc)
        HitDesc(intCount).NumFrames = 5
        HitDesc(intCount).H = 8
        HitDesc(intCount).W = 8
    NEXT

    ddsLaser = Graphics_LoadImage("./dat/gfx/laser.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR)
    _ASSERT ddsLaser < -1

    FOR intCount = 0 TO UBOUND(LaserDesc)
        LaserDesc(intCount).Exists = _FALSE
        LaserDesc(intCount).W = LASER1WIDTH
        LaserDesc(intCount).H = LASER1HEIGHT
    NEXT

    ddsLaser2R = Graphics_LoadImage("./dat/gfx/laser2.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR)
    _ASSERT ddsLaser2R < -1

    FOR intCount = 0 TO UBOUND(Laser2RDesc)
        Laser2RDesc(intCount).Exists = _FALSE
        Laser2RDesc(intCount).W = LASER2WIDTH
        Laser2RDesc(intCount).H = LASER2HEIGHT
    NEXT

    ddsLaser2L = Graphics_LoadImage("./dat/gfx/laser2.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR)
    _ASSERT ddsLaser2L < -1

    FOR intCount = 0 TO UBOUND(Laser2LDesc)
        Laser2LDesc(intCount).Exists = _FALSE
        Laser2LDesc(intCount).W = LASER2WIDTH
        Laser2LDesc(intCount).H = LASER2HEIGHT
    NEXT

    ddsLaser3 = Graphics_LoadImage("./dat/gfx/laser3.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR)
    _ASSERT ddsLaser3 < -1

    FOR intCount = 0 TO UBOUND(Laser3Desc)
        Laser3Desc(intCount).Exists = _FALSE
        Laser3Desc(intCount).W = LASER3WIDTH
        Laser3Desc(intCount).H = LASER3HEIGHT
    NEXT

    ddsEnemyFire = Graphics_LoadImage("./dat/gfx/enemyfire1.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR)
    _ASSERT ddsEnemyFire < -1

    ddsGuidedMissile = Graphics_LoadImage("./dat/gfx/guidedmissile.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR)
    _ASSERT ddsGuidedMissile < -1

    ddsDisplayBomb = Graphics_LoadImage("./dat/gfx/displaybomb.gif", _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR)
    _ASSERT ddsDisplayBomb < -1

    ddsObstacle(40) = Graphics_LoadImage("./dat/gfx/deadplate.gif", _FALSE, _FALSE, _STR_EMPTY, -1)
    _ASSERT ddsObstacle(40) < -1
END SUB


'This sub initializes all of the sound effects used by SS2k
SUB InitializeDS
    'The next lines load up all of the wave files using the default capabilites
    dsPowerUp = _SNDOPEN("./dat/sfx/snd/powerup.wav")
    _ASSERT dsPowerUp > 0

    dsEnergize = _SNDOPEN("./dat/sfx/snd/energize.wav")
    _ASSERT dsEnergize > 0

    dsAlarm = _SNDOPEN("./dat/sfx/snd/alarm.wav")
    _ASSERT dsAlarm > 0

    dsLaser = _SNDOPEN("./dat/sfx/snd/laser.wav")
    _ASSERT dsLaser > 0

    dsExplosion = _SNDOPEN("./dat/sfx/snd/explosion.wav")
    _ASSERT dsExplosion > 0

    dsMissile = _SNDOPEN("./dat/sfx/snd/missile.wav")
    _ASSERT dsMissile > 0

    dsNoHit = _SNDOPEN("./dat/sfx/snd/nohit.wav")
    _ASSERT dsNoHit > 0

    dsEnemyFire = _SNDOPEN("./dat/sfx/snd/enemyfire.wav")
    _ASSERT dsEnemyFire > 0

    dsLaser2 = _SNDOPEN("./dat/sfx/snd/laser2.wav")
    _ASSERT dsLaser2 > 0

    dsPulseCannon = _SNDOPEN("./dat/sfx/snd/pulse.wav")
    _ASSERT dsPulseCannon > 0

    dsPlayerDies = _SNDOPEN("./dat/sfx/snd/playerdies.wav")
    _ASSERT dsPlayerDies > 0

    dsInvulnerability = _SNDOPEN("./dat/sfx/snd/invulnerability.wav")
    _ASSERT dsInvulnerability > 0

    dsInvPowerDown = _SNDOPEN("./dat/sfx/snd/invpowerdown.wav")
    _ASSERT dsInvPowerDown > 0

    dsExtraLife = _SNDOPEN("./dat/sfx/snd/extralife.wav")
    _ASSERT dsExtraLife > 0
END SUB


' Centers a string on the screen
' The function calculates the correct starting column position to center the string on the screen and then draws the actual text
SUB DrawStringCenter (s AS STRING, y AS LONG, c AS _UNSIGNED LONG)
    $CHECKING:OFF
    COLOR c
    _PRINTSTRING ((SCREEN_WIDTH \ 2) - (_UPRINTWIDTH(s) \ 2), y), s
    $CHECKING:ON
END SUB


'This sub draws text to the back buffer
SUB DrawString (s AS STRING, x AS LONG, y AS LONG, c AS _UNSIGNED LONG)
    $CHECKING:OFF
    COLOR c 'Set the color of the text to the color passed to the sub
    _PRINTSTRING (x, y), s 'Draw the text on to the screen, in the coordinates specified
    $CHECKING:ON
END SUB


'This sub releases all Direct X objects
SUB EndGame
    DIM intCount AS LONG 'standard count variable

    _MOUSESHOW 'turn the cursor back on
    _AUTODISPLAY

    'Release direct input objects
    _KEYCLEAR 'unaquire the keyboard
    'TODO: If Not diJoystick Is Nothing Then                       'if the joystick device exists,
    '    diJoystick.Unacquire                                'unacquire it
    '    Set diJoystick = Nothing                            'set the joystick instance to nothing
    'End If

    'Release direct sound objects
    _SNDCLOSE dsExplosion 'set the explosion ds buffer to nothing
    dsExplosion = NULL
    _SNDCLOSE dsEnergize 'set the ds enemrgize buffer to nothing
    dsEnergize = NULL
    _SNDCLOSE dsAlarm 'set the alarm ds buffer to nothing
    dsAlarm = NULL
    _SNDCLOSE dsEnemyFire 'set the enemy fire ds buffer to nothing
    dsEnemyFire = NULL
    _SNDCLOSE dsNoHit 'set the no hit ds buffer to nothing
    dsNoHit = NULL
    _SNDCLOSE dsLaser2 'set the level2 ds buffer to nothing
    dsLaser2 = NULL
    _SNDCLOSE dsLaser 'set the ds laser buffer to nothing
    dsLaser = NULL
    _SNDCLOSE dsPulseCannon
    dsPulseCannon = NULL
    _SNDCLOSE dsPlayerDies
    dsPlayerDies = NULL
    _SNDCLOSE dsPowerUp 'set the power up ds buffer to nothing
    dsPowerUp = NULL
    _SNDCLOSE dsMissile 'set the ds missile buffer to nothing
    dsMissile = NULL
    _SNDCLOSE dsInvulnerability 'set the ds invulnerable to nothing
    dsInvulnerability = NULL
    _SNDCLOSE dsInvPowerDown 'set the power down sound to nothing
    dsInvPowerDown = NULL
    _SNDCLOSE dsExtraLife 'set the extra life sound to nothing
    dsExtraLife = NULL

    'Direct Draw
    IF ddsHit < -1 THEN _FREEIMAGE ddsHit 'set the hit direct draw surface to nothing
    ddsHit = NULL
    IF ddsLaser < -1 THEN _FREEIMAGE ddsLaser 'set the laser dds to nothing
    ddsLaser = NULL
    IF ddsLaser2R < -1 THEN _FREEIMAGE ddsLaser2R 'laser2 right side dds to nothing
    ddsLaser2R = NULL
    IF ddsLaser2L < -1 THEN _FREEIMAGE ddsLaser2L 'laser2 left side dds to nothing
    ddsLaser2L = NULL
    IF ddsLaser3 < -1 THEN _FREEIMAGE ddsLaser3 'laser3 surface to nothing
    ddsLaser3 = NULL
    IF ddsEnemyFire < -1 THEN _FREEIMAGE ddsEnemyFire 'enemy fire to nothing
    ddsEnemyFire = NULL
    IF ddsGuidedMissile < -1 THEN _FREEIMAGE ddsGuidedMissile 'guided missiles to nothing
    ddsGuidedMissile = NULL
    IF ddsTitle < -1 THEN _FREEIMAGE ddsTitle 'title to nothing
    ddsTitle = NULL
    IF ddsPowerUp < -1 THEN _FREEIMAGE ddsPowerUp 'power up to nothing
    ddsPowerUp = NULL
    IF ddsShip < -1 THEN _FREEIMAGE ddsShip 'ship to nothing
    ddsShip = NULL
    IF ddsExplosion(0) < -1 THEN _FREEIMAGE ddsExplosion(0) 'explosion to nothing
    ddsExplosion(0) = NULL
    IF ddsExplosion(1) < -1 THEN _FREEIMAGE ddsExplosion(1) 'explosion to nothing
    ddsExplosion(1) = NULL
    IF ddsDisplayBomb < -1 THEN _FREEIMAGE ddsDisplayBomb 'set the bomb surface to nothing
    ddsDisplayBomb = NULL
    IF ddsInvulnerable < -1 THEN _FREEIMAGE ddsInvulnerable 'invulnerable surface to nothing
    ddsInvulnerable = NULL

    'The following lines loop through the arrays
    'and set their surfaces to nothing
    FOR intCount = 0 TO UBOUND(ddsBackgroundObject)
        IF ddsBackgroundObject(intCount) < -1 THEN _FREEIMAGE ddsBackgroundObject(intCount)
        ddsBackgroundObject(intCount) = NULL
    NEXT
    FOR intCount = 0 TO UBOUND(ddsEnemyContainer)
        IF ddsEnemyContainer(intCount) < -1 THEN _FREEIMAGE ddsEnemyContainer(intCount)
        ddsEnemyContainer(intCount) = NULL
    NEXT
    FOR intCount = 0 TO UBOUND(ddsObstacle)
        IF ddsObstacle(intCount) < -1 THEN _FREEIMAGE ddsObstacle(intCount)
        ddsObstacle(intCount) = NULL
    NEXT

    CLS 'restore the display

    'Is there a Segment playing?
    'Stop playing any midi's currently playing
    PlayMIDIFile _STR_EMPTY
END SUB


'This sub checks the current high scores, and updates it with a new high score
'if the players score is larger than one of the current high scores, then saves
'it to disk
SUB CheckHighScore
    STATIC lngCount AS LONG 'standard count variable
    DIM intCount AS LONG 'another counting variable
    DIM intCount2 AS LONG 'a second counter variable

    IF NOT boolGettingInput THEN 'if the player isn't entering a name then
        ClearInput
        boolEnterPressed = _FALSE 'the enter key hasn't been pressed
        lngCount = 0 'reset the count
        DO WHILE lngScore < HighScore(lngCount).score 'loop until we reach the end of the high scores
            lngCount = lngCount + 1 'increment the counter
            IF lngCount >= NUM_HIGH_SCORES THEN 'if we reach the end of the high scores
                lngScore = 0 'reset the players score
                PlayMIDIFile "./dat/sfx/mus/title.mid" 'play the title midi
                byteNewHighScore = 255 'set the new high score to no new high score
                EXIT SUB 'get out of here
            END IF
        LOOP
        HighScore(NUM_HIGH_SCORES - 1).score = lngScore 'if the player does have a high score, assign it to the last place
        boolGettingInput = _TRUE 'we are now getting keyboard input
        strName = _STR_EMPTY 'clear the string
        PlayMIDIFile "./dat/sfx/mus/inbtween.mid" 'play the inbetween levels & title screen midi
    END IF

    IF boolGettingInput AND NOT boolEnterPressed THEN 'as long as we are getting input, and the player hasn't pressed enter
        IF LEN(strName) < HIGH_SCORE_TEXT_LEN AND LEN(strBuffer) > NULL THEN 'if we haven't reached the limit of characters for the name, and the buffer isn't empty then
            strName = strName + strBuffer 'if the buffer contains a letter or a space, add it to the buffer
        END IF
        DrawStringCenter "NEW HIGH SCORE:" + STR$(HighScore(NUM_HIGH_SCORES - 1).score), 200, BGRA_WHITE 'Display the new high score message
        DrawStringCenter "Enter your name: " + strName + CHR$(179), 220, BGRA_YELLOW 'Give the player a cursor, and display the buffer
    ELSEIF boolGettingInput AND boolEnterPressed THEN 'If we are getting input, and the player presses then enter key then
        HighScore(NUM_HIGH_SCORES - 1).text = strName 'assign the new high score name the string contained in the buffer
        FOR intCount = 0 TO 9 'loop through the high scores and re-arrange them
            FOR intCount2 = 0 TO 8 'so that the highest scores are on top, and the lowest
                IF HighScore(intCount2 + 1).score > HighScore(intCount2).score THEN 'are on the bottom
                    SWAP HighScore(intCount2), HighScore(intCount2 + 1)
                END IF
            NEXT
        NEXT

        FOR intCount = 0 TO NUM_HIGH_SCORES - 1 'loop through all the high scores
            IF HighScore(intCount).score = lngScore THEN byteNewHighScore = intCount 'find the new high score from the list and store it's index
        NEXT

        lngScore = 0 'reset the score
        SaveHighScores
        boolGettingInput = _FALSE 'we are no longer getting input
        PlayMIDIFile "./dat/sfx/mus/title.mid" 'Start the title midi again
    END IF

    strBuffer = _STR_EMPTY 'clear the buffer
    boolEnterPressed = _FALSE 'clear the enter toggle
END SUB


'This sub checks to see if there is a power-up on the screen, updates it
'if there is, or see if it is time to create a new power-up.
'If there is a power-up on screen, it paints it, and advances the animation
'frames as needed for the existing power-up
SUB UpdatePowerUps (CreatePowerup AS _BYTE) ' Optional CreatePowerup As Boolean
    STATIC byteAdvanceFrameOffset AS _UNSIGNED _BYTE 'counter to advance the animation frames
    STATIC byteFrameCount AS _UNSIGNED _BYTE 'holds which animation frame we are on
    DIM intRandomNumber AS LONG 'variable to hold a random number
    DIM byteFrameOffset AS _UNSIGNED _BYTE 'offset for animation frames
    DIM intCount AS LONG 'standard count integer

    IF CreatePowerup THEN 'If there it is time to create a power-up
        intCount = 0 'reset the count variable
        DO WHILE PowerUp(intCount).Exists 'find an empty power up index
            intCount = intCount + 1 'increment the count
        LOOP
        IF intCount < UBOUND(PowerUp) THEN 'if there was an empty spot found
            intRandomNumber = Math_GetRandomBetween(0, 899) 'Create a random number to see which power up
            IF intRandomNumber <= 400 THEN 'see what value the random number is
                PowerUp(intCount).Index = SHIELD 'make it a shield powerup
            ELSEIF intRandomNumber > 400 AND intRandomNumber < 600 THEN
                PowerUp(intCount).Index = WEAPON 'make it a weapon powerup
            ELSEIF intRandomNumber >= 600 AND intRandomNumber < 800 THEN
                PowerUp(intCount).Index = BOMB 'make it a bomb powerup
            ELSEIF intRandomNumber >= 800 AND intRandomNumber < 900 THEN
                PowerUp(intCount).Index = INVULNERABILITY 'Make it an invulnerability powerup
            END IF
            PowerUp(intCount).X = Math_GetRandomBetween(0, SCREEN_WIDTH - POWERUPWIDTH - 1) 'Create the power-up, and set a random X position
            PowerUp(intCount).Y = 0 'Make the power-up start at the top of the screen
            PowerUp(intCount).Exists = _TRUE 'The power up now exists
        END IF
    END IF

    FOR intCount = 0 TO UBOUND(PowerUp) 'loop through all power ups
        IF PowerUp(intCount).Exists THEN 'if a power up exists
            IF byteAdvanceFrameOffset > 3 THEN 'if it is time to increment the animation frame
                IF byteFrameCount = 0 THEN 'if it is frame 0
                    byteFrameCount = 1 'switch to frame 1
                ELSE 'otherwise
                    byteFrameCount = 0 'switch to frame 0
                END IF
                byteAdvanceFrameOffset = 0 'reset the frame advance count to 0
            ELSE
                byteAdvanceFrameOffset = byteAdvanceFrameOffset + 1 'otherwise, increment the advance frame counter by 1
            END IF

            byteFrameOffset = (POWERUPWIDTH * byteFrameCount) + PowerUp(intCount).Index 'determine the offset for the surfces rectangle

            IF PowerUp(intCount).Y >= SCREEN_HEIGHT THEN 'If the power-up goes off screen,
                PowerUp(intCount).Exists = _FALSE 'destroy it
            ELSEIF PowerUp(intCount).Y + POWERUPHEIGHT > 0 THEN ' Only render if onscreen
                _PUTIMAGE (PowerUp(intCount).X, PowerUp(intCount).Y), ddsPowerUp, , (byteFrameOffset, 0)-(byteFrameOffset + POWERUPWIDTH - 1, POWERUPHEIGHT - 1) 'otherwise, blit it to the back buffer,
            END IF

            PowerUp(intCount).Y = PowerUp(intCount).Y + 1.25 'and increment its' Y position
        END IF
    NEXT
END SUB


'This sub creates the explosions that appear when a player destroys an object. The index controls which
'explosion bitmap to play. Player explosion is a flag so the player doesn't get credit for blowing himself up.
'It also adds to the number of enemies the player has killed to be displayed upon level completion.
SUB CreateExplosion (Coordinates AS typeRect, ExplosionIndex AS _UNSIGNED _BYTE, NoCredit AS _BYTE) ' Optional NoCredit As Boolean = False
    DIM lngCount AS LONG 'Standard count variable

    IF NOT NoCredit THEN 'If the NoCredit flag is not set
        intEnemiesKilled = intEnemiesKilled + 1 'The number of enemies the player has killed that count toward a powerup being triggered is incremented
        lngNumEnemiesKilled = lngNumEnemiesKilled + 1 'The total number of enemies the player has killed is incremented
        IF intEnemiesKilled = 25 THEN 'If the number of enemies the player has killed exceeds 25, then
            intEnemiesKilled = 0 'Reset the enemies killed power up trigger count to 0
            UpdatePowerUps _TRUE 'Trigger a powerup
        END IF
    END IF

    FOR lngCount = 0 TO UBOUND(ExplosionDesc) 'loop through the whole explosion array
        IF NOT ExplosionDesc(lngCount).Exists THEN 'if we find an empty array element
            ExplosionDesc(lngCount).ExplosionIndex = ExplosionIndex 'Set the explosion type to the enemys'
            ExplosionDesc(lngCount).Exists = _TRUE 'this array element now exists
            ExplosionDesc(lngCount).Frame = 0 'set its' frame to the first one
            ExplosionDesc(lngCount).X = (((Coordinates.right - Coordinates.left) \ 2) + Coordinates.left) - (ExplosionDesc(lngCount).W \ 2) 'assign it the center of the object, at the edge
            ExplosionDesc(lngCount).Y = (((Coordinates.bottom - Coordinates.top) \ 2) + Coordinates.top) - (ExplosionDesc(lngCount).H \ 2) 'assign it the center of the object, along the edge
            EXIT SUB
        END IF
    NEXT
END SUB


'This subroutine updates the animation for the large explosions
SUB UpdateExplosions
    DIM lngCount AS LONG 'count variable
    DIM XOffset AS LONG 'X offset of the animation frame
    DIM YOffset AS LONG 'Y offset of the animation frame

    FOR lngCount = 0 TO UBOUND(ExplosionDesc) 'Loop through all explosions
        IF ExplosionDesc(lngCount).Exists THEN 'If this explosion exists then

            XOffset = (ExplosionDesc(lngCount).Frame MOD 4) * ExplosionDesc(lngCount).W 'Calculate the left of the rectangle
            YOffset = (ExplosionDesc(lngCount).Frame \ 4) * ExplosionDesc(lngCount).H 'Calculate the top of the rectangle

            _PUTIMAGE (ExplosionDesc(lngCount).X, ExplosionDesc(lngCount).Y), ddsExplosion(ExplosionDesc(lngCount).ExplosionIndex), , (XOffset, YOffset)-(XOffset + ExplosionDesc(lngCount).W - 1, YOffset + ExplosionDesc(lngCount).H - 1) 'Blit the explosion frame to the screen

            ExplosionDesc(lngCount).Frame = ExplosionDesc(lngCount).Frame + 1 'Increment the frame the explosion is on
            IF ExplosionDesc(lngCount).Frame > ExplosionDesc(lngCount).NumFrames THEN 'If the animation frame goes beyond the number of frames the that the explosion has
                ExplosionDesc(lngCount).Frame = 0 'Reset the frame to the first one
                ExplosionDesc(lngCount).Exists = _FALSE 'The explosion no longer exists
            END IF
        END IF
    NEXT
END SUB


'This sub displays all levels, and displays where the player is located with a flashing orange box
SUB ShowMapLocation (OutlineLocation AS _BYTE) ' Optional OutlineLocation As Boolean
    DIM DestRect AS typeRect 'Destination rectangle
    DIM CurrentLevelRect AS typeRect 'Rectangle for the current level
    DIM intCount AS LONG 'Count variable
    DIM XOffset AS LONG 'Offset of the X line
    DIM YOffset AS LONG 'Offset of the Y line
    DIM XLocation(0 TO 8) AS LONG 'Location X lines
    DIM YLocation(0 TO 8) AS LONG 'Location Y lines

    YOffset = 380 'Beginning offset where the rectangles will be drawn

    FOR intCount = 0 TO UBOUND(ddsBackgroundObject) 'loop through all background bitmaps
        IF intCount MOD 2 = 0 THEN 'if this is an even numbered index
            XOffset = 50 'this location's rectangle left is 50
            XLocation(intCount) = 110 'this location's line X is 110
        ELSE
            XOffset = 510 'this location's rectangle left is 510
            XLocation(intCount) = XOffset 'this location's line X is the same as the xoffset
        END IF

        'set up this rectangle using the above coordinate values
        DestRect.top = YOffset
        DestRect.bottom = DestRect.top + 60
        DestRect.left = XOffset
        DestRect.right = DestRect.left + 60

        IF intCount = (byteLevel - 1) THEN CurrentLevelRect = DestRect 'if the level is equal to the count we are on, store this rectangle for use
        YLocation(intCount) = DestRect.bottom - ((DestRect.bottom - DestRect.top) \ 2) 'calculate the line that will be drawn between the rectangles' Y position
        _PUTIMAGE (DestRect.left, DestRect.top)-(DestRect.right, DestRect.bottom), ddsBackgroundObject(intCount) 'blit the background to the screen
        Graphics_DrawRectangle DestRect.left, DestRect.top, DestRect.right, DestRect.bottom, BGRA_DIMGRAY 'draw a box around the bitmap
        YOffset = YOffset - 45 'decrement the Y offset
    NEXT

    IF byteLevel > 1 THEN 'if the level is larger than level 1
        FOR intCount = 1 TO (byteLevel - 1) 'loop until we reach the current level
            Graphics_DrawLine XLocation(intCount - 1), YLocation(intCount - 1), XLocation(intCount), YLocation(intCount), BGRA_WHITE 'draw a line connecting the last level's index with this level's index
        NEXT
    END IF

    IF OutlineLocation THEN 'if the sub is called with the OutlineLocation flag set then
        Graphics_DrawRectangle CurrentLevelRect.left, CurrentLevelRect.top, CurrentLevelRect.right, CurrentLevelRect.bottom, BGRA_ORANGERED 'draw the orange rectangle around the current level bitmap
    END IF
END SUB


'This subroutine displays the introductory text
SUB StartIntro
    DIM strDialog(0 TO 25) AS STRING 'store 25 strings
    DIM lngCount AS LONG 'count variable
    DIM YPosition AS LONG 'y position for the string location
    DIM ddsSplash AS LONG 'direct draw surface to hold the background bitmap

    'These lines store the text to be displayed
    strDialog(0) = "As you may know, the unknown alien species has been attacking the Earth for an"
    strDialog(1) = "untold number of years. You have been assigned to the only ship that humankind"
    strDialog(2) = "has been able to build capable of our defense. Reasoning with the aliens"
    strDialog(3) = "has met with silence on their part, and their assault has not stopped."
    strDialog(4) = "Now is the time for all inhabitants of the Earth to put their trust in you."
    strDialog(5) = "You must not let us down."
    strDialog(6) = _STR_EMPTY
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
    strDialog(17) = _STR_EMPTY
    strDialog(18) = "We will warp you to the first entry point of the alien galaxy, and you will"
    strDialog(19) = "journey on a course that leads you through each part of their system,"
    strDialog(20) = "destroying as much of their weaponry and resources as possible along the way."
    strDialog(21) = "At the end of each stage, we have set up warp-jumps that will transport you to"
    strDialog(22) = "the next critical sector. Go now, soldier, and fight so that we may avert the"
    strDialog(23) = "annihilation of the human race."
    strDialog(24) = _STR_EMPTY
    strDialog(25) = "(Press ENTER to continue)"

    CLS 'fill the backbuffer with black
    YPosition = 50 'initialize the Y coordinate of the text to 50

    ddsSplash = Graphics_LoadImage("./dat/gfx/nebulae4.gif", _FALSE, _FALSE, _STR_EMPTY, -1) 'create a surface
    _ASSERT ddsSplash < -1

    _PUTIMAGE , ddsSplash 'blit the surface to the screen

    _FREEIMAGE ddsSplash 'release all resources for the background bitmap

    DO UNTIL lngCount > UBOUND(strDialog) 'loop through all string arrays
        DrawStringCenter strDialog(lngCount), YPosition, BGRA_DARKGRAY
        'draw the text to the screen
        YPosition = YPosition + 15 'increment the Y position of the text
        lngCount = lngCount + 1 'increment the count
    LOOP

    Graphics_FadeScreen _TRUE, FADE_FPS, 100 'fade the screen in

    ClearInput

    DO
        SLEEP 'don't hog the processor
    LOOP UNTIL _KEYHIT = _KEY_ENTER 'if the enter key is pressed, exit the loop

    ClearInput

    Graphics_FadeScreen _FALSE, FADE_FPS, 100 'fade the screen out
END SUB


'This sub loads a level and dynamically initializes direct draw objects needed for the level. It also
'shows the statistics of the previous level if there are any.
SUB LoadLevel (level AS LONG)
    DIM FileFree AS LONG 'holds an available file handle
    DIM intCount AS LONG 'standard count variable
    DIM intCount2 AS LONG 'another count variable
    DIM LoadingString AS STRING * 30 'string loaded from the binary level file
    DIM strStats AS STRING 'string to hold statistics
    DIM strNumEnemiesKilled AS STRING 'string to hold the number of enemies killed
    DIM strTotalNumEnemies AS STRING 'string to hold the total number of enemies on the level
    DIM strPercent AS STRING 'string to hold the percentage of the enemies killed
    DIM strBonus AS STRING 'string to display the bonus amount

    CLS 'fill the backbuffer with black
    PlayMIDIFile "./dat/sfx/mus/inbtween.mid" 'play the midi that goes inbetween the title screen and the levels

    IF ddsBackgroundObject(byteLevel - 1) < -1 THEN
        _FREEIMAGE ddsBackgroundObject(byteLevel - 1) 'set the current background object to nothing
        ddsBackgroundObject(byteLevel - 1) = NULL
    END IF

    FOR intCount = 0 TO UBOUND(ddsBackgroundObject) 'loop through all the background objects
        ddsBackgroundObject(intCount) = Graphics_LoadImage("./dat/gfx/" + BackgroundObject(intCount).FileName, _FALSE, _FALSE, _STR_EMPTY, -1) 'Load one of the background bitmaps
        _ASSERT ddsBackgroundObject(intCount) < -1
    NEXT

    FOR intCount = 0 TO UBOUND(ddsEnemyContainer) 'Loop through all the enemy surfaces
        IF ddsEnemyContainer(intCount) < -1 THEN
            _FREEIMAGE ddsEnemyContainer(intCount) 'release them if they exist
            ddsEnemyContainer(intCount) = NULL
        END IF
    NEXT

    FOR intCount = 0 TO 30 'Loop through all the obstacle surfaces, except the last ten (which are static, not dynamic)
        IF ddsObstacle(intCount) < -1 THEN
            _FREEIMAGE ddsObstacle(intCount) 'release those also
            ddsObstacle(intCount) = NULL
        END IF
    NEXT

    _ASSERT _FILEEXISTS("./dat/map/level" + _TRIM$(STR$(level)) + ".bin")

    FileFree = FREEFILE 'get a handle to the next available free file
    OPEN "./dat/map/level" + _TRIM$(STR$(level)) + ".bin" FOR BINARY ACCESS READ AS FileFree 'open the level file for reading

    GET FileFree, , LoadingString 'load the loading string into the LoadingString variable

    FOR intCount = 0 TO 999 'loop through all elements of the sectioncount array
        FOR intCount2 = 0 TO 125
            GET FileFree, , SectionInfo(intCount, intCount2) 'get the SectionInfo information from this record, and put it in the array
        NEXT
    NEXT

    FOR intCount = 0 TO 999 'loop through all elements of the ObstacleInfo array
        FOR intCount2 = 0 TO 125
            GET FileFree, , ObstacleInfo(intCount, intCount2) 'get the ObstacleInfo information from this record, and put it in the array
        NEXT
    NEXT

    CLOSE FileFree 'close the file

    FOR intCount = 0 TO 999 'loop through the entire SectionInfo array for the level
        FOR intCount2 = 0 TO 125 'there are 126 slots in each section, loop through all of those
            IF SectionInfo(intCount, intCount2) < 255 THEN 'if the slot value is less than 255, an object exists there
                IF ddsEnemyContainer(SectionInfo(intCount, intCount2)) > -2 THEN ' if this object hasn't been loaded then (QB64 valid image handles are < -1)
                    ddsEnemyContainer(SectionInfo(intCount, intCount2)) = Graphics_LoadImage("./dat/gfx/" + EnemyContainerDesc(SectionInfo(intCount, intCount2)).FileName, _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR) 'create this object
                    _ASSERT ddsEnemyContainer(SectionInfo(intCount, intCount2)) < -1
                END IF
            END IF
        NEXT
    NEXT
    'We do the exact same thing for the obstacle array
    FOR intCount = 0 TO 999
        FOR intCount2 = 0 TO 125
            IF ObstacleInfo(intCount, intCount2) < 255 THEN
                IF ddsObstacle(ObstacleInfo(intCount, intCount2)) > -2 THEN
                    ddsObstacle(ObstacleInfo(intCount, intCount2)) = Graphics_LoadImage("./dat/gfx/" + ObstacleContainerInfo(ObstacleInfo(intCount, intCount2)).FileName, _FALSE, _FALSE, _STR_EMPTY, TRANSPARENT_COLOR)
                    _ASSERT ddsObstacle(ObstacleInfo(intCount, intCount2)) < -1
                END IF
            END IF
        NEXT
    NEXT

    FOR intCount = 1 TO 500 'loop this 500 times
        Graphics_DrawPixel Math_GetRandomBetween(0, SCREEN_WIDTH - 1), Math_GetRandomBetween(0, SCREEN_HEIGHT - 1), _RGB32(Math_GetRandomBetween(192, 255), Math_GetRandomBetween(192, 255), Math_GetRandomBetween(192, 255))
    NEXT

    intCount = 1 'set the count variable to 1
    DO WHILE intCount < LEN(LoadingString) 'loop until we reach the end of the string
        IF MID$(LoadingString, intCount, 1) = CHR$(0) THEN MID$(LoadingString, intCount, 1) = " "
        'set any null characters in the string to spaces
        intCount = intCount + 1 'increment the count
    LOOP

    ShowMapLocation _FALSE 'call the sub that shows the location of the player in the enemies galaxy
    strLevelText = LoadingString 'pass the loading string to the strLevelText variable
    strLevelText = _TRIM$(strLevelText) 'Trim any spaces from the loading string

    IF byteLevel > 1 THEN 'If the player is has passed level 1 then show statistics for the completed level
        strStats = "LAST LEVEL STATISTICS" 'Display a message
        strNumEnemiesKilled = "Number of enemies destroyed:" + STR$(lngNumEnemiesKilled) 'set the string with the number of enemies killed
        strTotalNumEnemies = "Total number of enemies in level:" + STR$(lngTotalNumEnemies) 'set the string with the total number of enemies on the level
        IF lngNumEnemiesKilled > 2 THEN 'if the player killed more than 1 enemy then
            strPercent = "Percentage of enemies destroyed:" + STR$(CLNG(lngNumEnemiesKilled / lngTotalNumEnemies * 100)) + "%" 'set the string with  the percentage of enemies killed
            strBonus = "Bonus: 10,000 X" + STR$(CLNG(lngNumEnemiesKilled / lngTotalNumEnemies * 100)) + "%" + " =" + STR$(CLNG(10000 * (lngNumEnemiesKilled / lngTotalNumEnemies))) 'set the string with any bonus awarded
            lngScore = lngScore + CLNG(10000 * (lngNumEnemiesKilled / lngTotalNumEnemies)) 'add the bonus to the players score
        END IF
    END IF

    Graphics_FadeScreen _TRUE, FADE_FPS, 100 'fade the screen in

    intCount = 0 'set the count variable to 0
    DO
        intCount = intCount + 1 'begin incrementing the count
        IF intCount > 10 AND intCount <= 20 THEN 'if the count is currently greater than 10 and less than 20
            ShowMapLocation _TRUE 'show the map location, with the current position outlined
        ELSEIF intCount <= 10 THEN 'if it is less than 10
            ShowMapLocation _FALSE 'show the map location with no outline
        END IF
        IF intCount > 20 THEN intCount = 0 'if the count is larger than 20, set it to 0
        IF byteLevel > 1 THEN 'if the player has passed level 1 then
            DrawStringCenter strStats, 80, BGRA_FORESTGREEN 'display the statistics
            DrawStringCenter strNumEnemiesKilled, 100, BGRA_FORESTGREEN 'display the number of enemies killed
            DrawStringCenter strTotalNumEnemies, 120, BGRA_FORESTGREEN 'display the total number of enemies on the level
            IF lngNumEnemiesKilled > 0 THEN 'if any enemies have been killed then
                DrawStringCenter strPercent, 140, BGRA_FORESTGREEN 'display the percentage of enemies killed
                DrawStringCenter strBonus, 160, BGRA_FORESTGREEN 'display the bonus awarded
            END IF
        END IF
        DrawStringCenter "Next level:  Level" + STR$(byteLevel), 200, BGRA_LIGHTSTEELBLUE 'display the next level number
        DrawStringCenter strLevelText, 220, BGRA_LIGHTSTEELBLUE 'display the level text
        DrawStringCenter "(Press ENTER to continue)", 450, BGRA_LIGHTSTEELBLUE 'display the string with this message

        _DISPLAY 'flip the direct draw front buffer to display the info

        _LIMIT UPDATES_PER_SECOND 'don't hog the processor
    LOOP UNTIL _KEYDOWN(_KEY_ENTER) 'if the enter key is pressed

    ClearInput

    lngNumEnemiesKilled = 0 'reset the number of enemies killed
    lngTotalNumEnemies = 0 'reset the total number of enemies on the level
    Graphics_FadeScreen _FALSE, FADE_FPS, 100 'fade the screen to black

    intObjectIndex = byteLevel - 1 'set the background index to the current level number
    IF intObjectIndex > UBOUND(BackgroundObject) THEN 'if we go beyond the boundaries of how many objects we have allocated
        boolBackgroundExists = _FALSE 'then the background object doesn't exist
        intObjectIndex = 0 'set the index to 0
    ELSE
        boolBackgroundExists = _TRUE 'reset background
        sngBackgroundX = (SCREEN_WIDTH \ 2) - (BackgroundObject(intObjectIndex).W \ 2) 'set the coorindates of the background object to be centered
        sngBackgroundY = -100 - BackgroundObject(intObjectIndex).H
        'set the starting Y position of the object off the screen
    END IF
    FOR intCount = 0 TO UBOUND(PowerUp)
        PowerUp(intCount).Exists = _FALSE 'reset powerups
    NEXT
    FOR intCount = 0 TO UBOUND(EnemyDesc) 'reset enemy lasers
        EnemyDesc(intCount).HasFired = _FALSE
    NEXT
    FOR intCount = 0 TO UBOUND(GuidedMissile) 'reset guided missiles
        GuidedMissile(intCount).Exists = _FALSE
    NEXT
    FOR intCount = 0 TO UBOUND(LaserDesc) 'reset lasers
        LaserDesc(intCount).Exists = _FALSE
    NEXT
    FOR intCount = 0 TO UBOUND(Laser2LDesc) 'reset level2 lasers
        Laser2LDesc(intCount).Exists = _FALSE
        Laser2RDesc(intCount).Exists = _FALSE
    NEXT
    FOR intCount = 0 TO UBOUND(Laser3Desc) 'reset level3 lasers
        Laser3Desc(intCount).Exists = _FALSE
    NEXT
    FOR intCount = 0 TO UBOUND(ExplosionDesc) 'reset explosions
        ExplosionDesc(intCount).Exists = _FALSE
    NEXT

    FOR intCount = 0 TO UBOUND(ddsBackgroundObject) 'loop through all the backgrounds and
        IF ddsBackgroundObject(intCount) < -1 THEN
            _FREEIMAGE ddsBackgroundObject(intCount) 'set all the backgrounds displayed in the level display screen to nothing to free up some memory
            ddsBackgroundObject(intCount) = NULL
        END IF
    NEXT

    ddsBackgroundObject(byteLevel - 1) = Graphics_LoadImage("./dat/gfx/" + BackgroundObject(byteLevel - 1).FileName, _FALSE, _FALSE, _STR_EMPTY, -1) 'Now we load only the necessary background object
    _ASSERT ddsBackgroundObject(byteLevel - 1) < -1

    'Reset the ships' position and velocity
    Ship.X = 300 'Set X coordinates for ship
    Ship.Y = 300 'Set Y coordinates for ship
    Ship.XVelocity = 0 'the ship has no velocity in the X direction
    Ship.YVelocity = 0 'the ship has no velocity in the Y direction

    _SNDSETPOS dsEnergize, 0 'Set the position of the energize wav to the beginning
    _SNDPLAY dsEnergize 'and then play it
END SUB


'This sub checks to see if the end of the game has been reached, increments the levels if the end of a level is
'reached, and also initializes new enemies and obstacles as they appear in the level
SUB UpdateLevels
    STATIC NumberEmptySections AS LONG 'Stores the number of empty sections counted
    DIM intCount AS LONG 'Count variable
    DIM intCount2 AS LONG 'Another count variable
    DIM EnemySectionNotEmpty AS _BYTE 'Flag to set if there are no enemies in the section
    DIM ObstacleSectionNotEmpty AS _BYTE 'Flag to set if there are no obstacles in the section
    DIM lngStartTime AS _INTEGER64 'The beginning time
    DIM TempInfo AS typeBackGroundDesc 'Temporary description variable
    DIM blnTempInfo AS _BYTE 'Temporary flag
    DIM SrcRect AS typeRect 'Source rectangle
    DIM byteIndex AS _UNSIGNED _BYTE 'Index count variable

    IF SectionCount < 0 THEN 'If the end of the level is reached
        byteLevel = byteLevel + 1 'Increment the level the player is on
        IF byteLevel = 9 THEN 'If all levels have been beat
            PlayMIDIFile _STR_EMPTY 'Stop playing any midi
            _SNDSTOP dsAlarm 'Turn off any alarm
            _SNDSTOP dsInvulnerability 'Stop any invulnerability sound effect

            lngStartTime = Time_GetTicks 'grab the current time

            DO WHILE lngStartTime + 8000 > Time_GetTicks 'loop this routine for 8 seconds
                CLS 'fill the back buffer with black

                IF INT(75 * RND) < 25 THEN 'if we get a number that is between 1-25 then
                    'Enter the rectangle values
                    SrcRect.top = INT((SCREEN_HEIGHT - 1) * RND) 'get a random Y coordinate
                    SrcRect.bottom = SrcRect.top + 10
                    SrcRect.left = INT((SCREEN_WIDTH - 1) * RND) 'get a random X coordinate
                    SrcRect.right = SrcRect.left + 10
                    IF INT((20 * RND) + 1) > 10 THEN 'if we get a random number that is greater than ten
                        byteIndex = 1 'set the explosion index to the second explosion
                    ELSE 'otherwise
                        byteIndex = 0 'set it to the first
                    END IF

                    CreateExplosion SrcRect, byteIndex, _TRUE 'create the explosion, and we don't give the player any credit for killing an enemy since there are none
                    _SNDPLAYCOPY dsExplosion 'play the explosion sound
                END IF

                UpdateExplosions 'update the explosions

                _DISPLAY 'Flip the front buffer with the back

                _LIMIT UPDATES_PER_SECOND
            LOOP

            Graphics_FadeScreen _FALSE, FADE_FPS, 100 'fade the screen to black

            FOR intCount = 0 TO UBOUND(ExplosionDesc) 'loop through all explosions
                ExplosionDesc(intCount).Exists = _FALSE 'they all no longer exist
            NEXT
            CLS 'fill the back buffer with black

            'The next lines all display the winning text
            DrawStringCenter "YOU WIN!", 150, BGRA_DARKGOLDENROD
            DrawStringCenter "After emerging victorious through 8 different alien galaxies, the enemy has", 165, BGRA_DARKGOLDENROD
            DrawStringCenter "been driven to the point of near-extinction. Congratulations on a victory", 180, BGRA_DARKGOLDENROD
            DrawStringCenter "well deserved! You return to Earth, triumphant.", 195, BGRA_DARKGOLDENROD
            DrawStringCenter "As the peoples of the Earth revel in celebration,", 210, BGRA_DARKGOLDENROD
            DrawStringCenter "and the world rejoices from relief of the threat of annihalation, you can't", 225, BGRA_DARKGOLDENROD
            DrawStringCenter "help but ponder... were all of the aliens really destroyed?", 240, BGRA_DARKGOLDENROD
            DrawStringCenter "THE END", 270, BGRA_DARKGOLDENROD

            Graphics_FadeScreen _TRUE, FADE_FPS, 100 'fade the screen in
            SLEEP 20 ' Display the winning message for 20 seconds
            Graphics_FadeScreen _FALSE, FADE_FPS, 100 'fade the screen to black again
            intShields = SHIELD_MAX 'shields are at 100%
            Ship.X = 300 'reset the players X
            Ship.Y = 300 'and Y coordinates
            Ship.PowerUpState = 0 'no powerups
            Ship.NumBombs = 0 'no bombs
            Ship.Invulnerable = _FALSE 'no longer invulnerable
            Ship.AlarmActive = _FALSE 'make sure the low shield alarm is off
            boolStarted = _FALSE 'the game hasn't been started
            byteLives = LIVES_DEFAULT 'the player has 3 lives left
            byteLevel = 1 'reset to level 1
            SectionCount = 999 'start at the first section
            NumberEmptySections = 0 'all the sections are filled again
            boolBackgroundExists = _FALSE 'a background bitmap no longer exists
            CheckHighScore 'call the sub to see if the player got a high score
            EXIT SUB 'exit the sub
        ELSE 'Otherwise, load a new level
            _SNDSTOP dsAlarm 'Stop playing the low shield alarm
            _SNDSTOP dsInvulnerability 'Stop playing the invulnerability alarm
            LoadLevel byteLevel 'Load the new level
            SectionCount = 999 'The section count starts at the beginning
            PlayMIDIFile "./dat/sfx/mus/level" + _TRIM$(STR$(byteLevel)) + ".mid" 'Play the new midi
        END IF
    END IF

    FOR intCount = 0 TO 125 'Loop through all the slots of this section
        IF SectionInfo(SectionCount, intCount) < 255 THEN
            'If there is something in the this slot
            DO UNTIL intCount2 > UBOUND(EnemyDesc) 'Loop through all the enemies
                IF NOT EnemyDesc(intCount2).Exists THEN 'If this index is open
                    IF EnemyDesc(intCount2).HasFired THEN 'If the old enemy has a weapon that had fired still on the screen
                        blnTempInfo = _TRUE 'flag that we need to pass some information to the new enemy
                        TempInfo = EnemyDesc(intCount2) 'store the information on this enemy temporarily
                    ELSE 'otherwise
                        blnTempInfo = _FALSE 'we don't need to give any info to this enemy
                    END IF
                    EnemyDesc(intCount2) = EnemyContainerDesc(SectionInfo(SectionCount, intCount))
                    'create the enemy using the enemy template
                    'fill in all the enemy parameters
                    EnemyDesc(intCount2).Index = SectionInfo(SectionCount, intCount)
                    'the enemies index is equal to the value of the slot
                    EnemyDesc(intCount2).Exists = _TRUE 'the enemy exists
                    EnemyDesc(intCount2).Y = 0 - EnemyDesc(intCount2).H
                    'set the enemy off the screen using its' height as the offset
                    EnemyDesc(intCount2).X = intCount * 5 'offset the X by the slot we are on
                    EnemyDesc(intCount2).TimesHit = 0 'the enemy has never been hit
                    IF blnTempInfo THEN 'if the old enemy has fired, pass the info to this enemy
                        EnemyDesc(intCount2).HasFired = _TRUE 'this enemy has fired
                        EnemyDesc(intCount2).TargetX = TempInfo.TargetX 'give the enemy the target info of the last one
                        EnemyDesc(intCount2).TargetY = TempInfo.TargetY 'give the enemy the target info of the last one
                        EnemyDesc(intCount2).XFire = TempInfo.XFire 'give the enemy the target info of the last one
                        EnemyDesc(intCount2).YFire = TempInfo.YFire 'give the enemy the target info of the last one
                    END IF
                    IF NOT EnemyDesc(intCount2).Invulnerable THEN lngTotalNumEnemies = lngTotalNumEnemies + 1
                    'if this enemy is not invulnerable, increment the total number of enemies the level has
                    EXIT DO 'exit the loop
                END IF
                intCount2 = intCount2 + 1 'increment the search index
            LOOP
            intCount2 = 0 'reset the search index
            EnemySectionNotEmpty = _TRUE 'this section is not an empty one
        END IF
        intCount2 = 0 'start the count variable at zero
        IF ObstacleInfo(SectionCount, intCount) < 255 THEN
            'if the obstacle section has something in it
            DO UNTIL intCount2 > UBOUND(ObstacleDesc) 'loop through all obsctacles
                IF NOT ObstacleDesc(intCount2).Exists THEN
                    'if there is an open slot begin filling in the info for this obstacle
                    IF ObstacleDesc(intCount2).HasFired THEN
                        'if the obstacle has fired
                        blnTempInfo = _TRUE 'flag that we have info to pass to the new obstacle
                        TempInfo = ObstacleDesc(intCount2) 'store the information about this obstacle
                    ELSE 'otherwise
                        blnTempInfo = _FALSE 'we don't have info to pass on
                    END IF
                    ObstacleDesc(intCount2) = ObstacleContainerInfo(ObstacleInfo(SectionCount, intCount))
                    'fill in the info on the new obstacle using the obstacle's template
                    'fill in the dynamic values
                    ObstacleDesc(intCount2).Index = ObstacleInfo(SectionCount, intCount)
                    'the index of this obsacle is stored in the slot value
                    ObstacleDesc(intCount2).Exists = _TRUE 'the obstacle exists
                    ObstacleDesc(intCount2).Y = -80 'set the obstacle off the top of the screen by 80 pixels
                    ObstacleDesc(intCount2).X = intCount * 5 'set the offset of the X position of the obstacle
                    IF blnTempInfo THEN 'if there is info to pass to the new obstacle
                        ObstacleDesc(intCount2).HasFired = _TRUE 'then the obstacle has fired
                        ObstacleDesc(intCount2).TargetX = TempInfo.TargetX 'fill in the fire information
                        ObstacleDesc(intCount2).TargetY = TempInfo.TargetY 'fill in the fire information
                        ObstacleDesc(intCount2).XFire = TempInfo.XFire 'fill in the fire information
                        ObstacleDesc(intCount2).YFire = TempInfo.YFire 'fill in the fire information
                    END IF
                    IF NOT ObstacleDesc(intCount2).Invulnerable THEN lngTotalNumEnemies = lngTotalNumEnemies + 1
                    'if this obstacle is not invulnerable, increment the total number of enemies on this level
                    EXIT DO 'exit the loop
                END IF
                intCount2 = intCount2 + 1 'increment the count index
            LOOP
            intCount2 = 0 'reset the count variable
            ObstacleSectionNotEmpty = _TRUE 'the obstacle section isn't empty
        END IF
    NEXT

    IF NOT ObstacleSectionNotEmpty AND NOT EnemySectionNotEmpty THEN
        'if the both sections are empty then
        NumberEmptySections = NumberEmptySections + 1 'increment the number of empty sections
        IF NumberEmptySections = 40 THEN 'if 40 empty sections are reached
            SectionCount = 0 'set the section count to 0
            NumberEmptySections = 0 'set the number of empty sections to 0
        END IF
    ELSE
        NumberEmptySections = 0 'otherwise, reset the number of empty sections to 0
    END IF
END SUB


'This sub fires the players weapons, and plays the associated wavefile
SUB FireWeapon
    STATIC byteLaserCounter AS _UNSIGNED _BYTE 'variable to hold the number of times this sub has been called to determine if it is time to let another laser be created
    STATIC byteGuidedMissileCounter AS _UNSIGNED _BYTE 'variable to hold the number of times this sub has been called to determine if it is time to let another guided missile be created
    STATIC byteLaser2Counter AS _UNSIGNED _BYTE 'variable to hold the number of times this sub has been called to determine if it is time to let another level2 laser (left side) be created
    STATIC byteLaser3Counter AS _UNSIGNED _BYTE 'variable to hold the number of times this sub has been called to determine if it is time to let another level2 laser (right side) be created
    DIM intCount AS LONG 'Standard count variable for loops

    'Stage 1 laser
    intCount = 0 'reset the count loop variable
    byteLaserCounter = byteLaserCounter + 1 'increment the number of lasers by 1
    IF byteLaserCounter = 5 THEN 'if we have looped through the sub 5 times
        DO UNTIL intCount > UBOUND(LaserDesc) ' TODO: Why was this 7? - loop through all the lasers
            IF NOT LaserDesc(intCount).Exists THEN 'and see if there is an empty slot, and if there is
                'create a new laser description
                LaserDesc(intCount).Exists = _TRUE 'the laser exists
                LaserDesc(intCount).X = Ship.X + SHIPWIDTH \ 2 - LASER1WIDTH \ 2
                'center the laser fire
                LaserDesc(intCount).Y = Ship.Y 'the laser starts at the same Y as the ship
                LaserDesc(intCount).Damage = 1 'the amount of damage this laser does

                _SNDSETPOS dsLaser, 0 'set the position of the buffer to 0
                _SNDBAL dsLaser, (2 * (Ship.X + SHIPWIDTH / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'pan the sound according to the ships location
                _SNDPLAY dsLaser 'play the laser sound

                EXIT DO 'exit the do loop
            END IF
            intCount = intCount + 1 'incrementing the count
        LOOP 'loop until we find an empty slot
        byteLaserCounter = 0 'reset the counter to 0
    END IF

    IF Ship.PowerUpState > 0 THEN 'Guided missiles
        intCount = 0 'reset the count variable
        byteGuidedMissileCounter = byteGuidedMissileCounter + 1 'increment the counter
        IF byteGuidedMissileCounter = 20 THEN 'if we called the sub 20 times, then
            DO UNTIL intCount > UBOUND(GuidedMissile) 'loop through all the guided missile types
                IF NOT GuidedMissile(intCount).Exists THEN 'if we find an empty slot
                    'create a new guided missile
                    GuidedMissile(intCount).Exists = _TRUE 'the guided missile exists
                    GuidedMissile(intCount).X = Ship.X + SHIPWIDTH \ 2 - MISSILEDIMENSIONS \ 2 'center the x coordinate
                    GuidedMissile(intCount).Y = Ship.Y + SHIPHEIGHT \ 2 - MISSILEDIMENSIONS \ 2 'center the y coordinate
                    GuidedMissile(intCount).XVelocity = 0 'set the velocity to 0
                    GuidedMissile(intCount).YVelocity = -4.5 'set the y velocity to 4.5 pixels every frame
                    GuidedMissile(intCount).Damage = 3 'the guided missile does 3 points of damage
                    EXIT DO 'exit the do loop
                END IF
                intCount = intCount + 1 'increment the count
            LOOP
            byteGuidedMissileCounter = 0 'reset the guided missile counter
        END IF
    END IF

    'The rest of the weapons are handled in just about the same manner as these were. You should be able to find
    'the similarities and figure out what is going on from there.

    IF Ship.PowerUpState > 1 THEN 'Stage 2 lasers, this weapon shoots lasers diagonally from the ship
        intCount = 0
        byteLaser2Counter = byteLaser2Counter + 1
        IF byteLaser2Counter > 15 THEN
            byteLaser2Counter = 0
            DO UNTIL intCount > UBOUND(Laser2RDesc)
                IF NOT Laser2RDesc(intCount).Exists THEN
                    Laser2RDesc(intCount).Exists = _TRUE
                    Laser2RDesc(intCount).X = (Ship.X + SHIPWIDTH) - 15
                    Laser2RDesc(intCount).Y = Ship.Y + 14
                    Laser2RDesc(intCount).XVelocity = 0 + (LASERSPEED - 4)
                    Laser2RDesc(intCount).YVelocity = 0 - LASERSPEED
                    Laser2RDesc(intCount).Damage = 1

                    _SNDPLAYCOPY dsLaser2, , (2 * (Ship.X + SHIPWIDTH / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)

                    EXIT DO
                END IF
                intCount = intCount + 1
            LOOP

            DO UNTIL intCount > UBOUND(Laser2LDesc)
                IF NOT Laser2LDesc(intCount).Exists THEN
                    Laser2LDesc(intCount).Exists = _TRUE
                    Laser2LDesc(intCount).X = Ship.X + 5
                    Laser2LDesc(intCount).Y = Ship.Y + 14
                    Laser2LDesc(intCount).XVelocity = 0 - (LASERSPEED - 4)
                    Laser2LDesc(intCount).YVelocity = 0 - LASERSPEED
                    Laser2LDesc(intCount).Damage = 1

                    _SNDPLAYCOPY dsLaser2, , (2 * (Ship.X + SHIPWIDTH / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)

                    EXIT DO
                END IF
                intCount = intCount + 1
            LOOP
        END IF
    END IF

    IF Ship.PowerUpState > 2 THEN 'Plasma pulse cannon, this is the only weapon that is not stopped by objects
        intCount = 0
        byteLaser3Counter = byteLaser3Counter + 1
        IF byteLaser3Counter = 35 THEN
            DO UNTIL intCount > UBOUND(Laser3Desc)
                IF NOT Laser3Desc(intCount).Exists THEN
                    Laser3Desc(intCount).Exists = _TRUE
                    Laser3Desc(intCount).X = Ship.X + ((SHIPWIDTH \ 2) - (Laser3Desc(intCount).W \ 2))
                    Laser3Desc(intCount).Y = Ship.Y
                    Laser3Desc(intCount).YVelocity = (LASERSPEED + 1.5)
                    Laser3Desc(intCount).Damage = 2

                    _SNDSETPOS dsPulseCannon, 0
                    _SNDBAL dsPulseCannon, (2 * (Ship.X + SHIPWIDTH / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1)
                    _SNDPLAY dsPulseCannon

                    EXIT DO
                END IF
                intCount = intCount + 1
            LOOP
            byteLaser3Counter = 0
        END IF
    END IF
END SUB


'This function takes two rectangles and determines if they overlap each other
FUNCTION DetectCollision%% (r1 AS typeRect, r2 AS typeRect)
    DetectCollision = NOT (r1.left > r2.right OR r2.left > r1.right OR r1.top > r2.bottom OR r2.top > r1.bottom)
END FUNCTION


'This sub creates, destroys, and updates small explosions for when the player hits an object or is hit
'It also plays a small "no hit" sound effect
SUB UpdateHits (NewHit AS _BYTE, x AS LONG, y AS LONG) ' Optional NewHit As Boolean = False, Optional x As Long, Optional y As Long
    DIM intCount AS LONG 'Count variable

    IF NewHit THEN 'If this is a new hit
        FOR intCount = 0 TO UBOUND(HitDesc) 'Loop through the hit array
            IF NOT HitDesc(intCount).Exists THEN 'If we find a spot that is free
                'Add in the coordinates of the new hit
                HitDesc(intCount).Exists = _TRUE 'This hit now exists
                HitDesc(intCount).X = x - 2 'Center the x if the hit
                HitDesc(intCount).Y = y 'The Y of the hit

                _SNDPLAYCOPY dsNoHit, , (2 * (HitDesc(intCount).X + 1) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'Play the sound effect

                EXIT FOR
            END IF
        NEXT
    ELSE 'Otherwise, if this is updating an existing hit
        FOR intCount = 0 TO UBOUND(HitDesc) 'Loop through the hit array
            IF HitDesc(intCount).Exists THEN 'If this hit exists
                IF HitDesc(intCount).Index > HitDesc(intCount).NumFrames THEN
                    'If the current frame is larger than the number of frames the hit animation has
                    HitDesc(intCount).Exists = _FALSE 'The hit no longer exists
                    HitDesc(intCount).Index = 0 'Set the frame of the hit to 0
                ELSE 'Otherwise, the hit animation frame needs to be displayed
                    IF HitDesc(intCount).X > 0 AND HitDesc(intCount).X < (SCREEN_WIDTH - HitDesc(intCount).W) AND HitDesc(intCount).Y > 0 AND HitDesc(intCount).Y < (SCREEN_HEIGHT - HitDesc(intCount).H) THEN
                        'If the hit is on screen
                        _PUTIMAGE (HitDesc(intCount).X, HitDesc(intCount).Y), ddsHit 'blit the hit to the screen
                    END IF
                    HitDesc(intCount).Index = HitDesc(intCount).Index + 1 'increment the animation
                END IF
            END IF
        NEXT
    END IF
END SUB


'This sub checks all objects on the screen to see if they are colliding,
'increments points, and plays sounds effects.
'This also is the largest sub in the program, since it has to increment through
'everything on the screen
SUB CheckForCollisions
    DIM SrcRect AS typeRect 'rect structure
    DIM SrcRect2 AS typeRect 'another rect structure
    DIM intCount AS LONG 'counter for loops
    DIM intCount2 AS LONG 'second loop counter
    DIM ShipRect AS typeRect 'holds the position of the player
    'TODO: Dim ddTempBltFx As DDBLTFX                                                      'used to hold info about the special effects for flashing the screen when something is hit
    DIM TempDesc AS typeBackGroundDesc
    DIM blnTempDesc AS _BYTE
    DIM TempTime AS _INTEGER64

    'TODO: ddTempBltFx.lFill = 143 ' Index 143 in the palette is bright red used to fill the screen with red when the player is hit.

    'define the rectangle for the player
    ShipRect.top = Ship.Y 'get the Y coordinate of the player
    ShipRect.bottom = ShipRect.top + (SHIPHEIGHT - 15) 'make sure not to include the flames from the bottom of the ship
    ShipRect.left = Ship.X + 10 'make sure to not include the orbiting elements
    ShipRect.right = ShipRect.left + (SHIPWIDTH - 10) 'same thing, but on the right

    FOR intCount = 0 TO UBOUND(PowerUp)
        'define the coordinates for the powerups
        SrcRect.top = PowerUp(intCount).Y
        SrcRect.bottom = SrcRect.top + POWERUPHEIGHT
        SrcRect.left = PowerUp(intCount).X
        SrcRect.right = SrcRect.left + POWERUPWIDTH

        IF PowerUp(intCount).Exists AND DetectCollision(ShipRect, SrcRect) THEN 'if the power up exists, and the player has collided with it
            IF PowerUp(intCount).Index = SHIELD THEN 'if it is a shield powerup
                intShields = intShields + 20 'increase the shields by 20
                lngScore = lngScore + 100 'player gets a 100 points for this
                IF intShields > SHIELD_MAX THEN intShields = SHIELD_MAX 'if the shields are already maxed out, make sure it doesn't go beyond max
                PowerUp(intCount).Exists = _FALSE 'the power up no longer exists
                _SNDSETPOS dsPowerUp, 0 'set the playback buffer position to 0
                _SNDPLAY dsPowerUp 'play the wav
                EXIT SUB
            ELSEIF PowerUp(intCount).Index = WEAPON THEN 'if the powerup is a weapon powerup
                IF Ship.PowerUpState < 3 THEN Ship.PowerUpState = Ship.PowerUpState + 1
                'if the powerups reach 3, make sure it doesn't go any higher than that
                lngScore = lngScore + 200 'player gets 200 points for this
                PowerUp(intCount).Exists = _FALSE 'the power up no longer exists
                _SNDSETPOS dsPowerUp, 0 'set the playback buffer position to 0
                _SNDPLAY dsPowerUp 'play the wav
                EXIT SUB
            ELSEIF PowerUp(intCount).Index = BOMB THEN 'the power up is a bomb powerup
                lngScore = lngScore + 200 'give the player a score increase, even if the bombs are at max
                PowerUp(intCount).Exists = _FALSE 'the power up no longer exists
                _SNDSETPOS dsPowerUp, 0 'set the playback buffer position to 0
                _SNDPLAY dsPowerUp 'play the wav
                Ship.NumBombs = Ship.NumBombs + 1 ' increase the number of bombs the player has
                IF Ship.NumBombs > BOMBS_MAX THEN FireMissile ' instant use extra bomb if we are at capacity
                EXIT SUB 'exit the sub
            ELSEIF PowerUp(intCount).Index = INVULNERABILITY THEN 'the power up is an invulnerability power up
                IF Ship.Invulnerable THEN TempTime = Ship.InvulnerableTime - Time_GetTicks ' capture the current time so the player doesn't lose the amount of time he has left to be invulnerable
                Ship.Invulnerable = _TRUE 'set the ships' invulnerable flag
                Ship.InvulnerableTime = Time_GetTicks + 15000 + TempTime 'set the duration of the invulnerability
                lngScore = lngScore + 500
                PowerUp(intCount).Exists = _FALSE
                _SNDSETPOS dsPowerUp, 0 'set the playback buffer position to 0
                _SNDPLAY dsPowerUp 'play the wav
                _SNDSETPOS dsInvulnerability, 0 'set the playback buffer position to 0
                _SNDLOOP dsInvulnerability 'play the wav
            END IF
        END IF
    NEXT

    FOR intCount = 0 TO UBOUND(EnemyDesc) 'loop through the entire enemy array
        IF EnemyDesc(intCount).Exists = _TRUE THEN 'if the enemy exists
            'define the rectangle coordinates of the enemy
            SrcRect.top = EnemyDesc(intCount).Y
            SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
            SrcRect.left = EnemyDesc(intCount).X
            SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

            IF DetectCollision(SrcRect, ShipRect) THEN 'if the enemy ship collides with the player

                _SNDPLAYCOPY dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                'TODO: If IsFF = True Then ef(1).start 1, 0                                'If force feedback is enabled, start the effect

                IF NOT EnemyDesc(intCount).Invulnerable THEN EnemyDesc(intCount).Exists = _FALSE
                'if the enemy isn't invulnerable the enemy is destroyed
                CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, _FALSE 'Call the create explosion sub with the rect coordinates, and the index of the explosion type
                IF NOT Ship.Invulnerable THEN 'If the ship is not invulnerable then
                    intShields = intShields - EnemyDesc(intCount).CollisionDamage 'take points off the shields for colliding with the enemy
                    IF Ship.PowerUpState > 0 THEN 'reduce a powerup level if the player has one
                        Ship.PowerUpState = Ship.PowerUpState - 1
                    END IF
                END IF
                lngScore = lngScore + EnemyDesc(intCount).Score 'add the score value of this enemy to the players score
                EXIT SUB
            END IF
        END IF
        IF EnemyDesc(intCount).HasFired THEN 'Determine if the enemy laser fire hit player
            'define coordinates of enemy weapon fire
            SrcRect.top = EnemyDesc(intCount).YFire
            SrcRect.bottom = SrcRect.top + 5
            SrcRect.left = EnemyDesc(intCount).XFire
            SrcRect.right = SrcRect.left + 5

            IF DetectCollision(SrcRect, ShipRect) THEN 'if the enemy weapon fire hits the player then
                EnemyDesc(intCount).HasFired = _FALSE 'the enemy weapon fire is destroyed
                IF NOT Ship.Invulnerable THEN
                    intShields = intShields - 5 'subtract 5 from the playres shields
                    IF Ship.PowerUpState > 0 THEN 'if the player has a power up,
                        Ship.PowerUpState = Ship.PowerUpState - 1 'knock it down a level
                    END IF
                END IF
                UpdateHits _TRUE, EnemyDesc(intCount).XFire, EnemyDesc(intCount).YFire 'Call the sub that displays a small explosion bitmap where the player was hit
                'TODO: If IsFF Then ef(1).start 1, 0                                'If force feeback is enabled, start the effect
                EXIT SUB
            END IF
        END IF
    NEXT

    FOR intCount = 0 TO UBOUND(ObstacleDesc)
        IF ObstacleDesc(intCount).HasFired THEN 'Determine if the obstacle laser fire hit player
            ' Define coordinates of obstacle weapon fire
            SrcRect.top = ObstacleDesc(intCount).YFire
            SrcRect.bottom = SrcRect.top + 5
            SrcRect.left = ObstacleDesc(intCount).XFire
            SrcRect.right = SrcRect.left + 5

            IF DetectCollision(SrcRect, ShipRect) THEN 'if the obstacle weapon fire hits the player then
                ObstacleDesc(intCount).HasFired = _FALSE 'the obstacle weapon fire is destroyed
                IF NOT Ship.Invulnerable THEN 'If the player isn't invulnerable then
                    intShields = intShields - 5 'subtract 5 from the playres shields
                    IF Ship.PowerUpState > 0 THEN 'if the player has a power up,
                        Ship.PowerUpState = Ship.PowerUpState - 1 'knock it down a level
                    END IF
                END IF
                UpdateHits _TRUE, ObstacleDesc(intCount).XFire, ObstacleDesc(intCount).YFire 'Small explosion sub
                EXIT SUB
            END IF
        END IF
    NEXT

    FOR intCount2 = 0 TO UBOUND(LaserDesc) 'Collision detection for stage 1 laser
        IF LaserDesc(intCount2).Exists THEN 'If this index of the laser is on screen
            'Define the coordinates of the rectangle
            SrcRect2.top = LaserDesc(intCount2).Y
            SrcRect2.bottom = SrcRect2.top + LaserDesc(intCount2).H
            SrcRect2.left = LaserDesc(intCount2).X
            SrcRect2.right = SrcRect2.left + LaserDesc(intCount2).W

            FOR intCount = 0 TO UBOUND(EnemyDesc) 'Loop through all the enemies
                IF EnemyDesc(intCount).Exists THEN 'If this enemy is on the screen then
                    'Define this enemies coordinates
                    SrcRect.top = EnemyDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
                    SrcRect.left = EnemyDesc(intCount).X
                    SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

                    IF DetectCollision(SrcRect, SrcRect2) THEN 'If this enemy is struck by the weapon
                        EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + LaserDesc(intCount2).Damage
                        'Subtract the amount of damage the weapon does from the enemy
                        IF EnemyDesc(intCount).TimesHit > EnemyDesc(intCount).TimesDies AND NOT EnemyDesc(intCount).Invulnerable THEN
                            'If the number of times the enemy has been hit is greater than
                            'the amount of times the enemy can be hit, then
                            lngScore = lngScore + EnemyDesc(intCount).Score 'add the score value of this enemy to the players score

                            _SNDPLAYCOPY dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            EnemyDesc(intCount).Exists = _FALSE 'This enemy no longer exists
                            LaserDesc(intCount2).Exists = _FALSE 'The players weapon fire no longer exists
                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, _FALSE
                            EXIT SUB
                        ELSE 'If the enemy is still alive, then
                            UpdateHits _TRUE, SrcRect2.left, SrcRect2.top
                            LaserDesc(intCount2).Exists = _FALSE 'The players weapon fire no longer exists
                            EXIT SUB
                        END IF
                    END IF
                END IF
            NEXT

            FOR intCount = 0 TO UBOUND(ObstacleDesc) 'Loop through all the obstacles
                IF ObstacleDesc(intCount).Exists AND NOT ObstacleDesc(intCount).Invulnerable THEN
                    'If this obstacle is on the screen then
                    'Define this enemies coordinates
                    SrcRect.top = ObstacleDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + ObstacleDesc(intCount).H
                    SrcRect.left = ObstacleDesc(intCount).X
                    SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                    IF DetectCollision(SrcRect, SrcRect2) THEN 'If this obstacle is struck by the weapon
                        ObstacleDesc(intCount).TimesHit = ObstacleDesc(intCount).TimesHit + LaserDesc(intCount2).Damage
                        'Subtract the amount of damage the weapon does from the obstacle
                        IF ObstacleDesc(intCount).TimesHit > ObstacleDesc(intCount).TimesDies THEN
                            'If the number of times the obstacle has been hit is greater than
                            'the amount of times the obstacle can be hit, then
                            lngScore = lngScore + ObstacleDesc(intCount).Score 'add the score value of this obstacle to the players score

                            _SNDPLAYCOPY dsExplosion, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            IF ObstacleDesc(intCount).HasFired THEN
                                TempDesc = ObstacleDesc(intCount)
                                blnTempDesc = _TRUE
                            ELSE
                                blnTempDesc = _FALSE
                            END IF
                            IF ObstacleDesc(intCount).HasDeadIndex THEN
                                ObstacleDesc(intCount) = ObstacleContainerInfo(ObstacleDesc(intCount).DeadIndex)
                                ObstacleDesc(intCount).Exists = _TRUE
                                ObstacleDesc(intCount).X = SrcRect.left
                                ObstacleDesc(intCount).Y = SrcRect.top
                                ObstacleDesc(intCount).Index = ObstacleDesc(intCount).DeadIndex
                                IF blnTempDesc THEN
                                    ObstacleDesc(intCount).XFire = TempDesc.XFire
                                    ObstacleDesc(intCount).YFire = TempDesc.YFire
                                    ObstacleDesc(intCount).TargetX = TempDesc.TargetX
                                    ObstacleDesc(intCount).TargetY = TempDesc.TargetY
                                END IF
                            ELSE
                                ObstacleDesc(intCount).Exists = _FALSE
                            END IF
                            LaserDesc(intCount2).Exists = _FALSE 'The players weapon fire no longer exists
                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, _FALSE
                            EXIT SUB
                        ELSE 'If the obstacle is still alive, then
                            UpdateHits _TRUE, SrcRect2.left, SrcRect2.top
                            LaserDesc(intCount2).Exists = _FALSE 'The players weapon fire no longer exists
                            EXIT SUB
                        END IF
                    END IF
                END IF
            NEXT
        END IF
    NEXT

    'The rest of the collision detection is pretty much the same. Loop through whatever it is
    'that needs to be checked, set up the source rectangle, set up the 2nd source, check if they
    'collide, and handle it appropriately. With the above comments, you should be able to figure out
    'what the rest is doing.

    FOR intCount2 = 0 TO UBOUND(Laser2RDesc)
        IF Laser2RDesc(intCount2).Exists THEN

            SrcRect2.top = Laser2RDesc(intCount2).Y
            SrcRect2.bottom = SrcRect2.top + LASER2HEIGHT
            SrcRect2.left = Laser2RDesc(intCount2).X
            SrcRect2.right = SrcRect2.left + LASER2WIDTH

            FOR intCount = 0 TO UBOUND(EnemyDesc)
                IF EnemyDesc(intCount).Exists THEN

                    SrcRect.top = EnemyDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
                    SrcRect.left = EnemyDesc(intCount).X
                    SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

                    IF DetectCollision(SrcRect, SrcRect2) THEN
                        EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + Laser2RDesc(intCount2).Damage
                        IF EnemyDesc(intCount).TimesHit > EnemyDesc(intCount).TimesDies AND NOT EnemyDesc(intCount).Invulnerable THEN
                            lngScore = lngScore + EnemyDesc(intCount).Score

                            _SNDPLAYCOPY dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            EnemyDesc(intCount).Exists = _FALSE
                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, _FALSE
                            Laser2RDesc(intCount2).Exists = _FALSE
                            EXIT SUB
                        ELSE
                            Laser2RDesc(intCount2).Exists = _FALSE
                            UpdateHits _TRUE, SrcRect2.left, SrcRect.top
                            EXIT SUB
                        END IF
                    END IF
                END IF
            NEXT

            FOR intCount = 0 TO UBOUND(ObstacleDesc)
                IF ObstacleDesc(intCount).Exists AND NOT ObstacleDesc(intCount).Invulnerable THEN

                    SrcRect.top = ObstacleDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + ObstacleDesc(intCount).H
                    SrcRect.left = ObstacleDesc(intCount).X
                    SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                    IF DetectCollision(SrcRect, SrcRect2) THEN
                        ObstacleDesc(intCount).TimesHit = ObstacleDesc(intCount).TimesHit + Laser2RDesc(intCount2).Damage
                        IF ObstacleDesc(intCount).TimesHit > ObstacleDesc(intCount).TimesDies THEN
                            lngScore = lngScore + ObstacleDesc(intCount).Score

                            _SNDPLAYCOPY dsExplosion, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            IF ObstacleDesc(intCount).HasFired THEN
                                TempDesc = ObstacleDesc(intCount)
                                blnTempDesc = _TRUE
                            ELSE
                                blnTempDesc = _FALSE
                            END IF
                            IF ObstacleDesc(intCount).HasDeadIndex THEN
                                ObstacleDesc(intCount) = ObstacleContainerInfo(ObstacleDesc(intCount).DeadIndex)
                                ObstacleDesc(intCount).Exists = _TRUE
                                ObstacleDesc(intCount).X = SrcRect.left
                                ObstacleDesc(intCount).Y = SrcRect.top
                                ObstacleDesc(intCount).Index = ObstacleDesc(intCount).DeadIndex
                                IF blnTempDesc THEN
                                    ObstacleDesc(intCount).XFire = TempDesc.XFire
                                    ObstacleDesc(intCount).YFire = TempDesc.YFire
                                    ObstacleDesc(intCount).TargetX = TempDesc.TargetX
                                    ObstacleDesc(intCount).TargetY = TempDesc.TargetY
                                END IF
                            ELSE
                                ObstacleDesc(intCount).Exists = _FALSE
                            END IF
                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, _FALSE
                            Laser2RDesc(intCount2).Exists = _FALSE
                            EXIT SUB
                        ELSE
                            Laser2RDesc(intCount2).Exists = _FALSE
                            UpdateHits _TRUE, SrcRect2.left, SrcRect.top
                            EXIT SUB
                        END IF
                    END IF
                END IF
            NEXT
        END IF
    NEXT

    FOR intCount2 = 0 TO UBOUND(Laser2LDesc)
        IF Laser2LDesc(intCount2).Exists THEN

            SrcRect2.top = Laser2LDesc(intCount2).Y
            SrcRect2.bottom = SrcRect2.top + LASER2HEIGHT
            SrcRect2.left = Laser2LDesc(intCount2).X
            SrcRect2.right = SrcRect2.left + LASER2WIDTH

            FOR intCount = 0 TO UBOUND(EnemyDesc)
                IF EnemyDesc(intCount).Exists THEN

                    SrcRect.top = EnemyDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
                    SrcRect.left = EnemyDesc(intCount).X
                    SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

                    IF DetectCollision(SrcRect, SrcRect2) THEN
                        EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + Laser2LDesc(intCount2).Damage
                        IF EnemyDesc(intCount).TimesHit > EnemyDesc(intCount).TimesDies AND NOT EnemyDesc(intCount).Invulnerable THEN
                            lngScore = lngScore + EnemyDesc(intCount).Score

                            _SNDPLAYCOPY dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            EnemyDesc(intCount).Exists = _FALSE
                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, _FALSE
                            Laser2LDesc(intCount2).Exists = _FALSE
                            EXIT SUB
                        ELSE
                            Laser2LDesc(intCount2).Exists = _FALSE
                            UpdateHits _TRUE, SrcRect2.left, SrcRect.top
                            EXIT SUB
                        END IF
                    END IF
                END IF
            NEXT

            FOR intCount = 0 TO UBOUND(ObstacleDesc)
                IF ObstacleDesc(intCount).Exists AND NOT ObstacleDesc(intCount).Invulnerable THEN

                    SrcRect.top = ObstacleDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + ObstacleDesc(intCount).H
                    SrcRect.left = ObstacleDesc(intCount).X
                    SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                    IF DetectCollision(SrcRect, SrcRect2) THEN
                        ObstacleDesc(intCount).TimesHit = ObstacleDesc(intCount).TimesHit + Laser2LDesc(intCount2).Damage
                        IF ObstacleDesc(intCount).TimesHit > ObstacleDesc(intCount).TimesDies THEN
                            lngScore = lngScore + ObstacleDesc(intCount).Score

                            _SNDPLAYCOPY dsExplosion, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            IF ObstacleDesc(intCount).HasFired THEN
                                TempDesc = ObstacleDesc(intCount)
                                blnTempDesc = _TRUE
                            ELSE
                                blnTempDesc = _FALSE
                            END IF
                            IF ObstacleDesc(intCount).HasDeadIndex THEN
                                ObstacleDesc(intCount) = ObstacleContainerInfo(ObstacleDesc(intCount).DeadIndex)
                                ObstacleDesc(intCount).Exists = _TRUE
                                ObstacleDesc(intCount).X = SrcRect.left
                                ObstacleDesc(intCount).Y = SrcRect.top
                                ObstacleDesc(intCount).Index = ObstacleDesc(intCount).DeadIndex
                                IF blnTempDesc THEN
                                    ObstacleDesc(intCount).XFire = TempDesc.XFire
                                    ObstacleDesc(intCount).YFire = TempDesc.YFire
                                    ObstacleDesc(intCount).TargetX = TempDesc.TargetX
                                    ObstacleDesc(intCount).TargetY = TempDesc.TargetY
                                END IF
                            ELSE
                                ObstacleDesc(intCount).Exists = _FALSE
                            END IF
                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, _FALSE
                            Laser2LDesc(intCount2).Exists = _FALSE
                            EXIT SUB
                        ELSE
                            Laser2LDesc(intCount2).Exists = _FALSE
                            UpdateHits _TRUE, SrcRect2.left, SrcRect.top
                            EXIT SUB
                        END IF
                    END IF
                END IF
            NEXT
        END IF
    NEXT

    FOR intCount2 = 0 TO UBOUND(Laser3Desc)
        IF Laser3Desc(intCount2).Exists THEN

            SrcRect2.top = Laser3Desc(intCount2).Y
            SrcRect2.bottom = SrcRect2.top + Laser3Desc(intCount2).H
            SrcRect2.left = Laser3Desc(intCount2).X
            SrcRect2.right = SrcRect2.left + Laser3Desc(intCount2).W

            FOR intCount = 0 TO UBOUND(EnemyDesc)
                IF EnemyDesc(intCount).Exists THEN

                    SrcRect.top = EnemyDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
                    SrcRect.left = EnemyDesc(intCount).X
                    SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

                    IF DetectCollision(SrcRect, SrcRect2) AND NOT Laser3Desc(intCount2).StillColliding THEN
                        Laser3Desc(intCount2).StillColliding = _TRUE
                        EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + Laser3Desc(intCount2).Damage
                        IF EnemyDesc(intCount).TimesHit > EnemyDesc(intCount).TimesDies AND NOT EnemyDesc(intCount).Invulnerable THEN
                            lngScore = lngScore + EnemyDesc(intCount).Score

                            _SNDPLAYCOPY dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, _FALSE
                            EnemyDesc(intCount).Exists = _FALSE
                            EXIT SUB
                        ELSE
                            UpdateHits _TRUE, SrcRect2.left, SrcRect2.top
                            EXIT SUB
                        END IF
                    ELSEIF NOT DetectCollision(SrcRect, SrcRect2) AND Laser3Desc(intCount2).StillColliding THEN
                        Laser3Desc(intCount2).StillColliding = _FALSE
                    END IF
                END IF
            NEXT

            FOR intCount = 0 TO UBOUND(ObstacleDesc)
                IF ObstacleDesc(intCount).Exists AND NOT ObstacleDesc(intCount).Invulnerable THEN

                    SrcRect.top = ObstacleDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + ObstacleDesc(intCount).H
                    SrcRect.left = ObstacleDesc(intCount).X
                    SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                    IF DetectCollision(SrcRect, SrcRect2) AND NOT Laser3Desc(intCount2).StillColliding THEN
                        Laser3Desc(intCount2).StillColliding = _TRUE
                        ObstacleDesc(intCount).TimesHit = ObstacleDesc(intCount).TimesHit + Laser3Desc(intCount2).Damage
                        IF ObstacleDesc(intCount).TimesHit > ObstacleDesc(intCount).TimesDies THEN
                            lngScore = lngScore + ObstacleDesc(intCount).Score

                            _SNDPLAYCOPY dsExplosion, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, _FALSE
                            IF ObstacleDesc(intCount).HasFired THEN
                                TempDesc = ObstacleDesc(intCount)
                                blnTempDesc = _TRUE
                            ELSE
                                blnTempDesc = _FALSE
                            END IF
                            IF ObstacleDesc(intCount).HasDeadIndex THEN
                                ObstacleDesc(intCount) = ObstacleContainerInfo(ObstacleDesc(intCount).DeadIndex)
                                ObstacleDesc(intCount).Exists = _TRUE
                                ObstacleDesc(intCount).X = SrcRect.left
                                ObstacleDesc(intCount).Index = ObstacleDesc(intCount).DeadIndex
                                ObstacleDesc(intCount).Y = SrcRect.top
                                IF blnTempDesc THEN
                                    ObstacleDesc(intCount).XFire = TempDesc.XFire
                                    ObstacleDesc(intCount).YFire = TempDesc.YFire
                                    ObstacleDesc(intCount).TargetX = TempDesc.TargetX
                                    ObstacleDesc(intCount).TargetY = TempDesc.TargetY
                                END IF
                            ELSE
                                ObstacleDesc(intCount).Exists = _FALSE
                            END IF

                            EXIT SUB
                        ELSE
                            UpdateHits _TRUE, SrcRect2.left, SrcRect2.top
                            EXIT SUB
                        END IF
                    ELSEIF NOT DetectCollision(SrcRect, SrcRect2) AND Laser3Desc(intCount2).StillColliding THEN
                        Laser3Desc(intCount2).StillColliding = _FALSE
                    END IF
                END IF
            NEXT
        END IF
    NEXT

    FOR intCount2 = 0 TO UBOUND(GuidedMissile)
        IF GuidedMissile(intCount2).Exists THEN

            SrcRect2.top = GuidedMissile(intCount2).Y
            SrcRect2.bottom = SrcRect2.top + MISSILEDIMENSIONS
            SrcRect2.left = GuidedMissile(intCount2).X
            SrcRect2.right = SrcRect2.left + MISSILEDIMENSIONS

            FOR intCount = 0 TO UBOUND(EnemyDesc)
                IF EnemyDesc(intCount).Exists THEN

                    SrcRect.top = EnemyDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + EnemyDesc(intCount).H
                    SrcRect.left = EnemyDesc(intCount).X
                    SrcRect.right = SrcRect.left + EnemyDesc(intCount).W

                    IF DetectCollision(SrcRect, SrcRect2) THEN
                        EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + 10

                        _SNDPLAYCOPY dsExplosion, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                        IF EnemyDesc(intCount).TimesHit > EnemyDesc(intCount).TimesDies AND NOT EnemyDesc(intCount).Invulnerable THEN
                            EnemyDesc(intCount).Exists = _FALSE
                            lngScore = lngScore + EnemyDesc(intCount).Score
                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, _FALSE
                        ELSE
                            CreateExplosion SrcRect, EnemyDesc(intCount).ExplosionIndex, _TRUE
                        END IF
                        GuidedMissile(intCount2).Exists = _FALSE
                        GuidedMissile(intCount2).TargetSet = _FALSE
                        EXIT SUB
                    END IF
                END IF
            NEXT

            FOR intCount = 0 TO UBOUND(ObstacleDesc)
                IF ObstacleDesc(intCount).Exists AND NOT ObstacleDesc(intCount).Invulnerable THEN

                    SrcRect.top = ObstacleDesc(intCount).Y
                    SrcRect.bottom = SrcRect.top + ObstacleDesc(intCount).H
                    SrcRect.left = ObstacleDesc(intCount).X
                    SrcRect.right = SrcRect.left + ObstacleDesc(intCount).W

                    IF DetectCollision(SrcRect, SrcRect2) THEN
                        ObstacleDesc(intCount).TimesHit = ObstacleDesc(intCount).TimesHit + 10

                        _SNDPLAYCOPY dsExplosion, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the explosion sound

                        IF ObstacleDesc(intCount).TimesHit > ObstacleDesc(intCount).TimesDies THEN
                            lngScore = lngScore + ObstacleDesc(intCount).Score
                            IF ObstacleDesc(intCount).HasFired THEN
                                TempDesc = ObstacleDesc(intCount)
                                blnTempDesc = _TRUE
                            ELSE
                                blnTempDesc = _FALSE
                            END IF
                            IF ObstacleDesc(intCount).HasDeadIndex THEN
                                ObstacleDesc(intCount) = ObstacleContainerInfo(ObstacleDesc(intCount).DeadIndex)
                                ObstacleDesc(intCount).Exists = _TRUE
                                ObstacleDesc(intCount).X = SrcRect.left
                                ObstacleDesc(intCount).Y = SrcRect.top
                                ObstacleDesc(intCount).Index = ObstacleDesc(intCount).DeadIndex
                                IF blnTempDesc THEN
                                    ObstacleDesc(intCount).XFire = TempDesc.XFire
                                    ObstacleDesc(intCount).YFire = TempDesc.YFire
                                    ObstacleDesc(intCount).TargetX = TempDesc.TargetX
                                    ObstacleDesc(intCount).TargetY = TempDesc.TargetY
                                END IF
                            ELSE
                                ObstacleDesc(intCount).Exists = _FALSE
                            END IF
                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, _FALSE
                        ELSE
                            CreateExplosion SrcRect, ObstacleDesc(intCount).ExplosionIndex, _TRUE
                        END IF
                        GuidedMissile(intCount2).Exists = _FALSE
                        GuidedMissile(intCount2).TargetSet = _FALSE
                        EXIT SUB
                    END IF
                END IF
            NEXT
        END IF
    NEXT
END SUB


'This sub updates the large slow scrolling bitmap in the background of the level
SUB UpdateBackground
    IF boolBackgroundExists THEN 'If there is a background bitmap
        sngBackgroundY = sngBackgroundY + 0.1 'increment the Y position of the bitmap

        IF sngBackgroundY >= SCREEN_HEIGHT THEN 'if the bitmap has moved below the screen
            boolBackgroundExists = _FALSE 'the bitmap no longer exists, since it has left the screen
        ELSEIF sngBackgroundY + BackgroundObject(intObjectIndex).H > 0 THEN ' Only render if onscreen
            _PUTIMAGE (sngBackgroundX, sngBackgroundY), ddsBackgroundObject(intObjectIndex) 'blit the background object to the backbuffer, using a source color key
        END IF
    END IF
END SUB


'This sub creates as well as updates stars
SUB UpdateStars
    DIM intCount AS LONG 'count variable

    FOR intCount = 0 TO UBOUND(StarDesc) 'loop through all the stars
        IF NOT StarDesc(intCount).Exists THEN 'if this star doesn't exist then
            IF (INT((3500 - 1) * RND) + 1) <= 25 THEN 'if a number between 3500 and 1 is less than 25 then
                'begin creating a new star
                StarDesc(intCount).Exists = _TRUE 'the star exists
                StarDesc(intCount).X = Math_GetRandomBetween(0, SCREEN_WIDTH - 1)
                'set a random X coordinate
                StarDesc(intCount).Y = 0 'start at the top of the screen
                StarDesc(intCount).Index = _RGB32(Math_GetRandomBetween(192, 255), Math_GetRandomBetween(192, 255), Math_GetRandomBetween(192, 255)) 'set a random number for a color
                StarDesc(intCount).Speed = ((2 - 0.4) * RND) + 0.4 'set a random number for the speed of the star
            END IF
        ELSE
            StarDesc(intCount).Y = StarDesc(intCount).Y + StarDesc(intCount).Speed
            'increment the stars position by its' speed
            IF StarDesc(intCount).Y >= SCREEN_HEIGHT THEN
                'if the star goes off the screen
                StarDesc(intCount).Y = 0 'set the stars Y position to 0
                StarDesc(intCount).Exists = _FALSE 'the star no longer exists
            ELSEIF StarDesc(intCount).Y >= 0 THEN ' Only render if it is oncreen
                Graphics_DrawPixel StarDesc(intCount).X, StarDesc(intCount).Y, StarDesc(intCount).Index 'blit the star to the screen
            END IF
        END IF
    NEXT
END SUB


'This sub updates all the obstacles on the screen, and animates them if there are any animations for the obstacle
SUB UpdateObstacles
    DIM intCount AS LONG 'count variable
    DIM XOffset AS LONG 'offset for the right of the rectangle
    DIM YOffset AS LONG 'offset for the bottom of the rectangle

    FOR intCount = 0 TO UBOUND(ObstacleDesc) 'loop through all obstacles
        IF ObstacleDesc(intCount).Exists THEN 'if this obstacle exists
            ObstacleDesc(intCount).Y = ObstacleDesc(intCount).Y + ObstacleDesc(intCount).Speed 'increment the obstacle by its' speed

            IF ObstacleDesc(intCount).Y >= SCREEN_HEIGHT THEN 'if the obstacle goes completely off the screen
                ObstacleDesc(intCount).Exists = _FALSE 'the obstacle no longer exists
            ELSEIF ObstacleDesc(intCount).Y + ObstacleDesc(intCount).H > 0 THEN ' Only render if onscreen
                IF ObstacleDesc(intCount).NumFrames > 0 THEN 'if this obstacle has an animation
                    ObstacleDesc(intCount).Frame = ObstacleDesc(intCount).Frame + 1 'increment the frame the animation is on
                    IF ObstacleDesc(intCount).Frame > ObstacleDesc(intCount).NumFrames THEN ObstacleDesc(intCount).Frame = 0 'if the animation goes beyond the number of frames it has, reset it to the start
                ELSE
                    ObstacleDesc(intCount).Frame = 0 ' Else we always stick to the first frame
                END IF

                XOffset = (ObstacleDesc(intCount).Frame MOD 4) * ObstacleDesc(intCount).W 'Calculate the left of the rectangle
                YOffset = (ObstacleDesc(intCount).Frame \ 4) * ObstacleDesc(intCount).H 'Calculate the top of the rectangle

                _PUTIMAGE (ObstacleDesc(intCount).X, ObstacleDesc(intCount).Y), ddsObstacle(ObstacleDesc(intCount).Index), , (XOffset, YOffset)-(XOffset + ObstacleDesc(intCount).W - 1, YOffset + ObstacleDesc(intCount).H - 1) 'otherwise blit it with a color key
            END IF
        END IF
    NEXT
END SUB


'This sub updates all the enemies that are being displayed on the screen
SUB UpdateEnemys
    DIM intCount AS LONG 'count variable
    DIM sngChaseSpeed AS SINGLE 'chase speed of the enemy
    DIM XOffset AS LONG 'X offset of the animation frame
    DIM YOffset AS LONG 'Y offset of the animation frame

    FOR intCount = 0 TO UBOUND(EnemyDesc) 'loop through all the enemies
        IF EnemyDesc(intCount).Exists THEN 'if the enemy exists
            EnemyDesc(intCount).Y = EnemyDesc(intCount).Y + EnemyDesc(intCount).Speed 'increment the enemies Y position by its' speed

            IF EnemyDesc(intCount).Y < SCREEN_HEIGHT THEN 'if the enemy is on the screen then
                IF Ship.Y > EnemyDesc(intCount).Y THEN 'if the the enemyies Y coorindate is larger than the players ship
                    IF EnemyDesc(intCount).ChaseValue > 0 THEN 'if the enemy has a chase value
                        IF EnemyDesc(intCount).ChaseValue = CHASEFAST THEN sngChaseSpeed = 0.2 'if the enemy is supposed to rapidly follow the players X coordinate, set it to a large increment
                        IF EnemyDesc(intCount).ChaseValue = CHASESLOW THEN sngChaseSpeed = 0.05 'if the enemy is supposed to slowly follow the players X coordinate, set it to a smaller increment

                        IF (Ship.X + (SHIPWIDTH \ 2)) < (EnemyDesc(intCount).X + (EnemyDesc(intCount).W \ 2)) THEN 'if the player is to the left of the enemy
                            EnemyDesc(intCount).XVelocity = EnemyDesc(intCount).XVelocity - sngChaseSpeed 'make the enemy move to the left
                            'if the enemies velocity is greater than the maximum velocity, reverse the direction of the enemy
                            IF ABS(EnemyDesc(intCount).XVelocity) > XMAXVELOCITY THEN EnemyDesc(intCount).XVelocity = XMAXVELOCITY - XMAXVELOCITY - XMAXVELOCITY
                        ELSEIF (Ship.X + (SHIPWIDTH \ 2)) > (EnemyDesc(intCount).X + (EnemyDesc(intCount).W \ 2)) THEN 'if the player is to the right of the enemy
                            EnemyDesc(intCount).XVelocity = EnemyDesc(intCount).XVelocity + sngChaseSpeed 'make the enemy move to the right
                            'if the enemies velocity is greater than the maximum velocity, reverse the direction of the enemy
                            IF ABS(EnemyDesc(intCount).XVelocity) > XMAXVELOCITY THEN EnemyDesc(intCount).XVelocity = XMAXVELOCITY
                        END IF
                    END IF
                END IF

                EnemyDesc(intCount).X = EnemyDesc(intCount).X + EnemyDesc(intCount).XVelocity 'increment the X position of the enemy by its' velocity

                IF EnemyDesc(intCount).FrameDelay > 0 THEN
                    'if the frame delay count of this enemy is greater than zero,
                    'it means this enemy should have a delay in the number of frames
                    'that are displayed
                    EnemyDesc(intCount).FrameDelayCount = EnemyDesc(intCount).FrameDelayCount + 1 'increment it by one
                    IF EnemyDesc(intCount).FrameDelayCount > EnemyDesc(intCount).FrameDelay THEN 'if the delay count is larger than the frame delay
                        EnemyDesc(intCount).FrameDelayCount = 0 'reset the count
                        EnemyDesc(intCount).Frame = EnemyDesc(intCount).Frame + 1 'increment the animation frame by one
                    END IF
                ELSE 'otherwise,
                    EnemyDesc(intCount).Frame = EnemyDesc(intCount).Frame + 1 'increment the frame displayed
                END IF

                ' If the frame number goes over the number of frames this enemy has, reset the animation frame to the beginning
                IF EnemyDesc(intCount).Frame > EnemyDesc(intCount).NumFrames THEN EnemyDesc(intCount).Frame = 0

                XOffset = (EnemyDesc(intCount).Frame MOD 4) * EnemyDesc(intCount).W 'set the X offset of the animation frame
                YOffset = (EnemyDesc(intCount).Frame \ 4) * EnemyDesc(intCount).H 'set the Y offset of the animation frame

                IF EnemyDesc(intCount).X + EnemyDesc(intCount).W > 0 AND EnemyDesc(intCount).X < SCREEN_WIDTH AND EnemyDesc(intCount).Y + EnemyDesc(intCount).H > 0 THEN 'make sure that the enemy is within the bounds for blitting
                    ' Blit the enemy with a transparent key
                    _PUTIMAGE (EnemyDesc(intCount).X, EnemyDesc(intCount).Y), ddsEnemyContainer(EnemyDesc(intCount).Index), , (XOffset, YOffset)-(XOffset + EnemyDesc(intCount).W - 1, YOffset + EnemyDesc(intCount).H - 1)
                END IF
            ELSE
                EnemyDesc(intCount).Exists = _FALSE 'otherwise, this enemy no longer exists
            END IF
        END IF

        IF NOT EnemyDesc(intCount).HasFired AND EnemyDesc(intCount).Exists AND EnemyDesc(intCount).DoesFire AND EnemyDesc(intCount).Y > 0 AND (EnemyDesc(intCount).Y + EnemyDesc(intCount).H) < SCREEN_HEIGHT AND EnemyDesc(intCount).X > 0 AND (EnemyDesc(intCount).X + EnemyDesc(intCount).W) < SCREEN_WIDTH THEN
            'This incredibly long line has a very important job. It makes sure that the enemy hasn't fired, that it exists, and that it is visible on the screen
            IF INT((1500 - 1) * RND + 1) < 20 THEN 'if the random number is less than 20, make the enemy fire

                _SNDPLAYCOPY dsEnemyFire, , (2 * (EnemyDesc(intCount).X + EnemyDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the duplicate sound buffer

                IF EnemyDesc(intCount).X < Ship.X THEN 'if the players X coordinate is less than the enemies
                    EnemyDesc(intCount).TargetX = 3 'set the X fire direction to +3 pixels every frame
                ELSE 'otherwise
                    EnemyDesc(intCount).TargetX = -3 'set it to -3 pixels every frame
                END IF

                IF EnemyDesc(intCount).Y < Ship.Y THEN 'if the enemy ship's Y coordinate is less than the ships then
                    EnemyDesc(intCount).TargetY = 3 'set the enemy fire to move +3 pixels every frame
                ELSE 'otherwise
                    EnemyDesc(intCount).TargetY = -3 'set the enemy fire to move -3 pixels every frame
                END IF
                EnemyDesc(intCount).XFire = EnemyDesc(intCount).X + EnemyDesc(intCount).W \ 2 - ENEMY_FIRE_WIDTH \ 2 'center the enemies X fire
                EnemyDesc(intCount).YFire = EnemyDesc(intCount).Y + EnemyDesc(intCount).H \ 2 - ENEMY_FIRE_HEIGHT \ 2 'center the eneies Y fire
                EnemyDesc(intCount).HasFired = _TRUE 'the enemy has fired
            END IF
        ELSEIF EnemyDesc(intCount).HasFired THEN 'otherwise, if the enemy has fired
            IF EnemyDesc(intCount).FireType = TARGETEDFIRE THEN
                'if the type of fire that the enemy uses aims in the general direction of the player then
                EnemyDesc(intCount).XFire = EnemyDesc(intCount).XFire + EnemyDesc(intCount).TargetX
                'increment the enemy X fire in the direction specified
                EnemyDesc(intCount).YFire = EnemyDesc(intCount).YFire + EnemyDesc(intCount).TargetY
                'increment the enemy Y fire in the direction specified
            ELSE 'otherwise
                EnemyDesc(intCount).YFire = EnemyDesc(intCount).YFire + 5 'increment the Y fire only, by 5 pixels
            END IF

            IF EnemyDesc(intCount).FireFrameCount >= ENEMY_FIRE_FRAMES THEN 'if we have reached the end of the number of frames to wait until it is time to change the fire animation frame then
                EnemyDesc(intCount).FireFrameCount = 0 'reset the counter

                EnemyDesc(intCount).FireFrame = ENEMY_FIRE_WIDTH - EnemyDesc(intCount).FireFrame ' bounce between frames
            ELSE 'otherwise
                EnemyDesc(intCount).FireFrameCount = EnemyDesc(intCount).FireFrameCount + 1
                'increment the wait time
            END IF

            IF EnemyDesc(intCount).XFire >= SCREEN_WIDTH OR EnemyDesc(intCount).XFire + ENEMY_FIRE_WIDTH <= 0 OR EnemyDesc(intCount).YFire >= SCREEN_HEIGHT OR EnemyDesc(intCount).YFire + ENEMY_FIRE_HEIGHT <= 0 THEN
                'if the enemy fire is off the visible screen
                EnemyDesc(intCount).HasFired = _FALSE 'the enemy hasn't fired
            ELSE 'otherwise
                _PUTIMAGE (EnemyDesc(intCount).XFire, EnemyDesc(intCount).YFire), ddsEnemyFire, , (EnemyDesc(intCount).FireFrame, 0)-(EnemyDesc(intCount).FireFrame + ENEMY_FIRE_WIDTH - 1, ENEMY_FIRE_HEIGHT - 1) 'blit the enemy fire
            END IF
        END IF
    NEXT

    'The rest of the sub does the exact same thing that the code above does when firing an enemy weapon,
    'except it does it for any of the obstacles that have the ability to fire

    FOR intCount = 0 TO UBOUND(ObstacleDesc)
        IF NOT ObstacleDesc(intCount).HasFired AND ObstacleDesc(intCount).Exists AND ObstacleDesc(intCount).DoesFire THEN
            IF INT((3000 - 1) * RND + 1) < 20 THEN

                _SNDPLAYCOPY dsEnemyFire, , (2 * (ObstacleDesc(intCount).X + ObstacleDesc(intCount).W / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'play the duplicate sound buffer

                IF ObstacleDesc(intCount).X < Ship.X THEN
                    ObstacleDesc(intCount).TargetX = 3
                ELSE
                    ObstacleDesc(intCount).TargetX = -3
                END IF
                IF ObstacleDesc(intCount).Y < Ship.Y THEN
                    ObstacleDesc(intCount).TargetY = 3
                ELSE
                    ObstacleDesc(intCount).TargetY = -3
                END IF
                ObstacleDesc(intCount).XFire = ObstacleDesc(intCount).X + ObstacleDesc(intCount).W \ 2 - ENEMY_FIRE_WIDTH \ 2
                ObstacleDesc(intCount).YFire = ObstacleDesc(intCount).Y + ObstacleDesc(intCount).H \ 2 - ENEMY_FIRE_HEIGHT \ 2
                ObstacleDesc(intCount).HasFired = _TRUE
            END IF
        ELSEIF ObstacleDesc(intCount).HasFired THEN
            ObstacleDesc(intCount).XFire = ObstacleDesc(intCount).XFire + ObstacleDesc(intCount).TargetX
            ObstacleDesc(intCount).YFire = ObstacleDesc(intCount).YFire + ObstacleDesc(intCount).TargetY

            IF ObstacleDesc(intCount).FireFrameCount >= ENEMY_FIRE_FRAMES THEN
                ObstacleDesc(intCount).FireFrameCount = 0

                ObstacleDesc(intCount).FireFrame = ENEMY_FIRE_WIDTH - ObstacleDesc(intCount).FireFrame
            ELSE
                ObstacleDesc(intCount).FireFrameCount = ObstacleDesc(intCount).FireFrameCount + 1
            END IF

            IF ObstacleDesc(intCount).XFire >= SCREEN_WIDTH OR ObstacleDesc(intCount).XFire + ENEMY_FIRE_WIDTH <= 0 OR ObstacleDesc(intCount).YFire >= SCREEN_HEIGHT OR ObstacleDesc(intCount).YFire + ENEMY_FIRE_HEIGHT <= 0 THEN
                ObstacleDesc(intCount).HasFired = _FALSE
            ELSE
                _PUTIMAGE (ObstacleDesc(intCount).XFire, ObstacleDesc(intCount).YFire), ddsEnemyFire, , (ObstacleDesc(intCount).FireFrame, 0)-(ObstacleDesc(intCount).FireFrame + ENEMY_FIRE_WIDTH - 1, ENEMY_FIRE_HEIGHT - 1)
            END IF
        END IF
    NEXT
END SUB


'This sub updates all of the players weapon fire
SUB UpdateWeapons
    DIM intCount AS LONG 'count variable
    DIM intCounter AS LONG 'another count variable
    DIM SrcRect AS typeRect 'source rectuangle

    DO UNTIL intCount > UBOUND(LaserDesc) 'Loop through all the level 1 lasers
        IF LaserDesc(intCount).Exists THEN 'if the laser exists
            LaserDesc(intCount).Y = LaserDesc(intCount).Y - LASERSPEED
            'increment the Y position by the speed of the laser
            IF LaserDesc(intCount).Y < 0 THEN 'if the laser goes off the screen
                LaserDesc(intCount).Exists = _FALSE 'the laser no longer exists
                LaserDesc(intCount).Y = 0 'reset the Y position
                LaserDesc(intCount).X = 0 'reset the X position
            ELSE 'otherwise
                _PUTIMAGE (LaserDesc(intCount).X, LaserDesc(intCount).Y), ddsLaser 'blit the laser to the screen
            END IF
        END IF
        intCount = intCount + 1 'increment the count
    LOOP

    'set the coordinates of the level 2 laser
    SrcRect.top = 0
    SrcRect.bottom = SrcRect.top + 8
    SrcRect.left = 0
    SrcRect.right = SrcRect.left + 8

    intCount = 0 'reset the count variable
    DO UNTIL intCount > UBOUND(Laser2RDesc) 'loop through all the level 2 lasers on the right side
        IF Laser2RDesc(intCount).Exists THEN 'if the laser exists
            Laser2RDesc(intCount).Y = Laser2RDesc(intCount).Y + Laser2RDesc(intCount).YVelocity
            'increment the Y by the Y velocity
            Laser2RDesc(intCount).X = Laser2RDesc(intCount).X + Laser2RDesc(intCount).XVelocity
            'increment the X by the X velocity
            'fill in the source rectangle values
            SrcRect.left = LASER2WIDTH
            SrcRect.right = SrcRect.left + LASER2WIDTH
            SrcRect.top = 0
            SrcRect.bottom = LASER2HEIGHT

            IF Laser2RDesc(intCount).X < 0 OR Laser2RDesc(intCount).X > (SCREEN_WIDTH - LASER2WIDTH) OR Laser2RDesc(intCount).Y < 0 OR Laser2RDesc(intCount).Y > (SCREEN_HEIGHT - LASER2HEIGHT) THEN
                'if the laser goes off the screen then
                Laser2RDesc(intCount).Exists = _FALSE 'the laser no longer exists
            ELSE 'otherwise
                _PUTIMAGE (Laser2RDesc(intCount).X, Laser2RDesc(intCount).Y), ddsLaser2R, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'blit the laser to the screen
            END IF
        END IF
        intCount = intCount + 1 'increment the count
    LOOP

    'The next part does the same thing as the above code.
    'but for the left side of the laser
    intCount = 0
    DO UNTIL intCount > UBOUND(Laser2LDesc)
        IF Laser2LDesc(intCount).Exists THEN
            Laser2LDesc(intCount).Y = Laser2LDesc(intCount).Y + Laser2LDesc(intCount).YVelocity
            Laser2LDesc(intCount).X = Laser2LDesc(intCount).X + Laser2LDesc(intCount).XVelocity

            SrcRect.left = 0
            SrcRect.right = SrcRect.left + LASER2WIDTH
            SrcRect.top = 0
            SrcRect.bottom = LASER2HEIGHT

            IF Laser2LDesc(intCount).X < 0 OR Laser2LDesc(intCount).X > (SCREEN_WIDTH - LASER2WIDTH) OR Laser2LDesc(intCount).Y < 0 OR Laser2LDesc(intCount).Y > (SCREEN_HEIGHT - LASER2HEIGHT) THEN
                Laser2LDesc(intCount).Exists = _FALSE
            ELSE
                _PUTIMAGE (Laser2LDesc(intCount).X, Laser2LDesc(intCount).Y), ddsLaser2L, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom)
            END IF
        END IF
        intCount = intCount + 1
    LOOP

    intCount = 0
    DO UNTIL intCount > UBOUND(Laser3Desc)
        IF Laser3Desc(intCount).Exists THEN
            Laser3Desc(intCount).Y = Laser3Desc(intCount).Y - Laser3Desc(intCount).YVelocity
            IF Laser3Desc(intCount).Y < 0 THEN
                Laser3Desc(intCount).Exists = _FALSE
                Laser3Desc(intCount).Y = 0
                Laser3Desc(intCount).X = 0
            ELSE
                _PUTIMAGE (Laser3Desc(intCount).X, Laser3Desc(intCount).Y), ddsLaser3
            END IF
        END IF
        intCount = intCount + 1
    LOOP

    intCount = 0 'reset the count variable
    DO UNTIL intCount > UBOUND(GuidedMissile) 'loop through all the guided missle indexes
        IF GuidedMissile(intCount).Exists THEN 'if the missil exists
            IF NOT GuidedMissile(intCount).TargetSet THEN
                'and the target for it has not been set
                FOR intCounter = 0 TO UBOUND(EnemyDesc) 'loop through all the enemies
                    IF EnemyDesc(intCounter).Exists THEN 'if the first enemy encountered exists
                        GuidedMissile(intCount).TargetIndex = intCounter
                        'set the index of the target to the index of the enemy
                        GuidedMissile(intCount).TargetSet = _TRUE
                        'the target has now been set
                        EXIT FOR 'exit the loop
                    END IF
                NEXT
            ELSE 'otherwise, the target has already been set for this missle
                IF EnemyDesc(GuidedMissile(intCount).TargetIndex).Exists THEN
                    'if the target enemy still exists
                    IF (EnemyDesc(GuidedMissile(intCount).TargetIndex).X + (EnemyDesc(GuidedMissile(intCount).TargetIndex).W / 2)) > GuidedMissile(intCount).X THEN
                        'check if the missile has gone past the enemy
                        GuidedMissile(intCount).XVelocity = GuidedMissile(intCount).XVelocity + 0.05
                        'compensate if it has
                        IF GuidedMissile(intCount).XVelocity > MAXMISSILEVELOCITY THEN GuidedMissile(intCount).XVelocity = MAXMISSILEVELOCITY
                        'make sure that the missiles velocity doesn't go past the maximum
                    ELSEIF (EnemyDesc(GuidedMissile(intCount).TargetIndex).X + (EnemyDesc(GuidedMissile(intCount).TargetIndex).W / 2)) < GuidedMissile(intCount).X THEN
                        'check if the missile has gone past the enemy
                        GuidedMissile(intCount).XVelocity = GuidedMissile(intCount).XVelocity - 0.05
                        'compensate if it has
                        IF ABS(GuidedMissile(intCount).XVelocity) > MAXMISSILEVELOCITY THEN GuidedMissile(intCount).XVelocity = MAXMISSILEVELOCITY - MAXMISSILEVELOCITY - MAXMISSILEVELOCITY
                        'make sure that the missiles velocity doesn't go past the maximum
                    END IF
                    IF (EnemyDesc(GuidedMissile(intCount).TargetIndex).Y + (EnemyDesc(GuidedMissile(intCount).TargetIndex).H / 2)) > GuidedMissile(intCount).Y THEN
                        'check if the missile has gone past the enemy
                        GuidedMissile(intCount).YVelocity = GuidedMissile(intCount).YVelocity + 0.05
                        'compensate if it has
                        IF GuidedMissile(intCount).YVelocity > MAXMISSILEVELOCITY THEN GuidedMissile(intCount).YVelocity = MAXMISSILEVELOCITY
                        'make sure that the missiles velocity doesn't go past the maximum
                    ELSEIF (EnemyDesc(GuidedMissile(intCount).TargetIndex).Y + (EnemyDesc(GuidedMissile(intCount).TargetIndex).H / 2)) < GuidedMissile(intCount).Y THEN
                        'check if the missile has gone past the enemy
                        GuidedMissile(intCount).YVelocity = GuidedMissile(intCount).YVelocity - 0.05
                        'compensate if it has
                        IF ABS(GuidedMissile(intCount).YVelocity) > MAXMISSILEVELOCITY THEN GuidedMissile(intCount).YVelocity = MAXMISSILEVELOCITY - MAXMISSILEVELOCITY - MAXMISSILEVELOCITY
                        'make sure that the missiles velocity doesn't go past the maximum
                    END IF
                ELSE
                    GuidedMissile(intCount).TargetSet = _FALSE
                    'if the enemy does not exist, the target has no longer been set
                END IF
            END IF

            GuidedMissile(intCount).X = GuidedMissile(intCount).X + GuidedMissile(intCount).XVelocity
            'increment the missile X by the velocity of the missile
            GuidedMissile(intCount).Y = GuidedMissile(intCount).Y + GuidedMissile(intCount).YVelocity
            'increment the missile X by the velocity of the missile
            IF GuidedMissile(intCount).X < 0 OR (GuidedMissile(intCount).X + MISSILEDIMENSIONS) > SCREEN_WIDTH OR GuidedMissile(intCount).Y < 0 OR (GuidedMissile(intCount).Y + MISSILEDIMENSIONS) > SCREEN_HEIGHT THEN
                'if the missile goes off the screen
                GuidedMissile(intCount).Exists = _FALSE 'the guided missile no longer exists
                GuidedMissile(intCount).TargetSet = _FALSE 'the guided missile has no target
            ELSE 'otherwise
                _PUTIMAGE (GuidedMissile(intCount).X, GuidedMissile(intCount).Y), ddsGuidedMissile
                'blit the missile to the screen
            END IF
        END IF
        intCount = intCount + 1 'increment the count
    LOOP
END SUB


'This sub updates the player's ship, and animates it
SUB UpdateShip
    DIM SrcRect AS typeRect 'source rectangle
    DIM TempX AS LONG 'X poistion of the animation
    DIM TempY AS LONG 'Y position of the animation
    STATIC isFrameDirectionReverse AS _BYTE 'keep track of the direction the animation is moving

    ' If the end of the animation is reached in either direction
    IF (intShipFrameCount > 29 AND NOT isFrameDirectionReverse) OR (intShipFrameCount < 1 AND isFrameDirectionReverse) THEN
        isFrameDirectionReverse = NOT isFrameDirectionReverse 'reverse the direction
    END IF

    IF isFrameDirectionReverse THEN 'if the animation is headed backwards
        intShipFrameCount = intShipFrameCount - 1 'reduce the frame the animation is on
    ELSE 'otherwise
        intShipFrameCount = intShipFrameCount + 1 'increment the animation frame
    END IF

    TempY = intShipFrameCount \ 4 'find the left of the animation
    TempX = intShipFrameCount - (TempY * 4) 'find the top of the animation
    Ship.XOffset = TempX * SHIPWIDTH 'set the X offset of the animation frame
    Ship.YOffset = TempY * SHIPHEIGHT 'set the Y offset of the animation frame

    'fill in the values of the animation frame
    SrcRect.top = Ship.YOffset
    SrcRect.bottom = SrcRect.top + SHIPHEIGHT
    SrcRect.left = Ship.XOffset
    SrcRect.right = SrcRect.left + SHIPWIDTH

    IF ABS(Ship.XVelocity) > XMAXVELOCITY THEN 'if the ship reaches the maximum velocity in this direction then
        IF Ship.XVelocity < 0 THEN 'if the ship is headed to the left of the screen
            Ship.XVelocity = XMAXVELOCITY - XMAXVELOCITY - XMAXVELOCITY
            'set the velocity to equal the maximum velocity in this direction
        ELSE 'otherwise
            Ship.XVelocity = XMAXVELOCITY 'set the velocity to equal the maximum velocity in this direction
        END IF
    END IF
    IF ABS(Ship.YVelocity) > YMAXVELOCITY THEN 'if the ship reaches the maximum velocity in this direction then
        IF Ship.YVelocity < 0 THEN 'if the ship is headed to the top of the screen
            Ship.YVelocity = YMAXVELOCITY - YMAXVELOCITY - YMAXVELOCITY
            'set the velocity to equal the maximum velocity in this direction
        ELSE 'otherwise
            Ship.YVelocity = YMAXVELOCITY 'set the velocity to equal the maximum velocity in this direction
        END IF
    END IF

    IF Ship.XVelocity > 0 THEN 'if the ship's velocity is positive
        Ship.XVelocity = Ship.XVelocity - FRICTION 'subtract some of the velocity using friction
        IF Ship.XVelocity < 0 THEN Ship.XVelocity = 0 'if the ship goes under zero velocity, the ship has no velocity anymore
    ELSEIF Ship.XVelocity < 0 THEN 'otherwise, if the ship has negative velocity
        Ship.XVelocity = Ship.XVelocity + FRICTION 'add some friction to the negative value
        IF Ship.XVelocity > 0 THEN Ship.XVelocity = 0 'if the ship goes above 0, the ship no longer has velocity
    END IF
    IF Ship.YVelocity > 0 THEN 'if the ships Y velocity is positive
        Ship.YVelocity = Ship.YVelocity - FRICTION 'subtract some of the velocity using friction
        IF Ship.YVelocity < 0 THEN Ship.YVelocity = 0 'if the ship goes under zero velocity, the ship has no velocity anymore
    ELSEIF Ship.YVelocity < 0 THEN 'otherwise, if the ship has negative velocity
        Ship.YVelocity = Ship.YVelocity + FRICTION 'add some friction to the negative value
        IF Ship.YVelocity > 0 THEN Ship.YVelocity = 0 'if the ship goes above 0, the ship no longer has velocity
    END IF

    Ship.X = Ship.X + Ship.XVelocity 'increment the ship's X position by the amount of velocity
    Ship.Y = Ship.Y + Ship.YVelocity 'increment the ship's Y position by the amount of velocity

    IF Ship.X < 0 THEN Ship.X = 0 'if the ship hits the left of the screen, set the X to 0
    IF Ship.Y < 0 THEN Ship.Y = 0 'if the ship hits the bottom of the screen, set the Y to 0
    IF Ship.X >= SCREEN_WIDTH - SHIPWIDTH THEN Ship.X = SCREEN_WIDTH - SHIPWIDTH
    'if the ship hits the right of the screen, set it to the right edge
    IF Ship.Y >= SCREEN_HEIGHT - SHIPHEIGHT THEN Ship.Y = SCREEN_HEIGHT - SHIPHEIGHT
    'if the ship hits the bottom of the screen, set it to the bottom edge

    _PUTIMAGE (Ship.X, Ship.Y), ddsShip, , (SrcRect.left, SrcRect.top)-(SrcRect.right, SrcRect.bottom) 'blit the ship to the screen
END SUB


'This sub updates the invulnerability animation, and starts and stops the sound that goes with it
SUB UpdateInvulnerability
    STATIC intInvFrameCount AS LONG 'Keep track of what animation frame the animation is on
    STATIC blnInvWarning AS _BYTE 'Flag that is set if it is time to warn the player that the invulnerability is running out
    STATIC intWarningCount AS LONG 'Keep track of how many times the player has been warned
    DIM XOffset AS LONG 'Offset of the rectangle
    DIM YOffset AS LONG 'Offset of the rectangle
    DIM timeLeft AS _INTEGER64

    IF Time_GetTicks > Ship.InvulnerableTime THEN 'If the amount of invulenrability exceeds the time alloted to the player
        Ship.Invulnerable = _FALSE 'The ship is no longer invulnerable
        intInvFrameCount = 0 'The animation is reset to the starting frame

        _SNDSTOP dsInvulnerability 'Stop playing the invulnerable sound effect
        _SNDPLAY dsInvPowerDown 'Play the power down sound effect

        blnInvWarning = _FALSE 'No longer warning the player
        intWarningCount = 0 'Reset the warning count
    ELSE 'Otherwise, the ship is invulnerable
        timeLeft = Ship.InvulnerableTime - Time_GetTicks
        blnInvWarning = timeLeft < 3000 'If there are only three seconds left, then toggle the warning flag to on

        IF blnInvWarning THEN 'If the player is being warned
            DrawStringCenter LTRIM$(STR$(timeLeft \ 1000~&&)), SCREEN_HEIGHT - 16, BGRA_ORANGERED

            intWarningCount = intWarningCount + 1 'Increment the warning count

            IF intWarningCount > 30 THEN intWarningCount = 0 'If the warning count goes through 30 frames, reset it

            IF intWarningCount < 15 THEN 'If the warning count is less than 30 frames
                _SNDLOOP dsInvulnerability 'Play the invulnerability sound effect

                IF intInvFrameCount > 49 THEN intInvFrameCount = 0 'If the animation goes past the maximum number of frames, reset it

                intInvFrameCount = intInvFrameCount + 1 'Increment the frame count

                XOffset = (intInvFrameCount MOD 4) * SHIPWIDTH 'set the X offset of the animation frame
                YOffset = (intInvFrameCount \ 4) * SHIPHEIGHT 'set the Y offset of the animation frame

                _PUTIMAGE (Ship.X, Ship.Y), ddsInvulnerable, , (XOffset, YOffset)-(XOffset + SHIPWIDTH - 1, YOffset + SHIPHEIGHT - 1) 'Blit the animation frame
            ELSE
                _SNDSTOP dsInvulnerability 'If we are above 15 frames of animation, stop playing the invulnerability sound effect
            END IF
        ELSE 'Otherwise, the player is not in warning mode
            DrawStringCenter LTRIM$(STR$(timeLeft \ 1000~&&)), SCREEN_HEIGHT - 16, BGRA_WHITE

            IF intInvFrameCount > 49 THEN intInvFrameCount = 0 'If the animation goes past the maximum number of frames, reset it

            intInvFrameCount = intInvFrameCount + 1 'Increment the frame count

            XOffset = (intInvFrameCount MOD 4) * SHIPWIDTH 'set the X offset of the animation frame
            YOffset = (intInvFrameCount \ 4) * SHIPHEIGHT 'set the Y offset of the animation frame

            _PUTIMAGE (Ship.X, Ship.Y), ddsInvulnerable, , (XOffset, YOffset)-(XOffset + SHIPWIDTH - 1, YOffset + SHIPHEIGHT - 1) 'Blit the animation frame
        END IF

        _SNDBAL dsInvulnerability, (2 * (Ship.X + SHIPWIDTH / 2) - SCREEN_WIDTH + 1) / (SCREEN_WIDTH - 1) 'If we are above 15 frames of animation, stop playing the invulnerability sound effect
    END IF
END SUB


'This sub updates the shield display and also checks whether or not there are any shields left, as well as
'updating the players lives. If there are no lives left, it will reset the game.
SUB UpdateShields
    DIM lngTime AS _INTEGER64 'variable to store the current tick count
    DIM intCount AS LONG 'standard loop variable
    DIM SrcRect AS typeRect

    IF intShields > 0 THEN 'if there is more than 0% shields left
        Graphics_DrawRectangle 449, 6, 551, 28, BGRA_WHITE 'draw a box for the shield indicator and set the border to white
        Graphics_DrawFilledRectangle 450, 7, 450 + intShields, 27, _RGB32(255 - (255 * intShields / SHIELD_MAX), 0, 255 * intShields / SHIELD_MAX) 'intShields is the right hand side of the rectangle, which will grow smaller as the player takes more damage

        'blt the indicator rectangle to the screen
        DrawString "Shields:", 380, 10, BGRA_PALEGREEN 'display some text
        IF intShields < 25 THEN 'if the shields are less than 25% then
            _SNDLOOP dsAlarm 'play the alarm sound effect, and loop it
            Ship.AlarmActive = _TRUE 'set the alarm flag to on
        ELSE 'otherwise
            _SNDSTOP dsAlarm 'make sure the alarm sound effect is off
            Ship.AlarmActive = _FALSE 'the flag is set to off
        END IF
    ELSE 'The player has died
        _SNDSETPOS dsPlayerDies, 0 'set the dies wave to the beginning
        _SNDPLAY dsPlayerDies 'play the explosion sound
        'TODO: If IsFF Then ef(3).start 1, 0                'if force feedback is enabled then start the death effect
        'TODO: If IsFF Then ef(2).Unload                    'disable the trigger force feedback effect
        _SNDSTOP dsAlarm 'stop playing the alarm sound effect
        'setup a rectangle structure for the explosion
        SrcRect.top = Ship.Y
        SrcRect.bottom = SrcRect.top + SHIPHEIGHT
        SrcRect.left = Ship.X
        SrcRect.right = SrcRect.left + SHIPWIDTH

        CreateExplosion SrcRect, 0, _TRUE 'create an explosion where the player was
        lngTime = Time_GetTicks 'get the current tick count
        FOR intCount = 0 TO UBOUND(EnemyDesc) 'loop through all the enemies and
            EnemyDesc(intCount).Exists = _FALSE 'the enemies no longer exist
            EnemyDesc(intCount).HasFired = _FALSE 'the enemies' weapons no longer exist
        NEXT
        FOR intCount = 0 TO UBOUND(GuidedMissile) 'loop through all the players guided missiles
            GuidedMissile(intCount).Exists = _FALSE 'they no longer exist
        NEXT
        FOR intCount = 0 TO UBOUND(ObstacleDesc) 'make all the obstacles non-existent
            ObstacleDesc(intCount).Exists = _FALSE 'the obstacle doesn't exist
            ObstacleDesc(intCount).HasFired = _FALSE 'the obstacle hasn't fired
        NEXT
        FOR intCount = 0 TO UBOUND(PowerUp)
            PowerUp(intCount).Exists = _FALSE 'if there is a power up currently on screen, get rid of it
        NEXT
        byteLives = byteLives - 1 'the player loses a life
        intShields = SHIELD_MAX 'shields are at full again

        Ship.X = 300 'center the ships' X
        Ship.Y = 300 'and Y
        Ship.PowerUpState = 0 'the player is back to no powerups
        Ship.AlarmActive = _FALSE 'the alarm flag is set to off
        Ship.FiringMissile = _FALSE 'the firing missle flag is set to off

        SectionCount = SectionCount + 30 'Set the player back a bit
        IF SectionCount > 999 THEN SectionCount = 999 'Make sure we don't go over the limit
        IF byteLives > 0 THEN 'If the player still has lives left then
            DO UNTIL Time_GetTicks > lngTime + 2000 'Loop this for two seconds
                CLS 'fill the back buffer with black

                UpdateBackground 'you seen this before
                UpdateStars 'this too
                UpdateExplosions 'same here
                UpdateWeapons 'as well as this
                DrawString "Lives left:" + STR$(byteLives), 275, 200, BGRA_WHITE 'display a message letting the player know how many ships are left

                _LIMIT UPDATES_PER_SECOND ' Make sure the game doesn't get out of control

                _DISPLAY 'flip the front buffer with the back
            LOOP 'keep looping until two seconds pass
            _SNDSETPOS dsEnergize, 0 'set the energize sound effect to the beginning
            _SNDPLAY dsEnergize 'play the energize sound effect
            'TODO: If IsFF Then ef(2).Download              'start the trigger force feedback again
        ELSE 'If the player has no lives left
            DO UNTIL Time_GetTicks > lngTime + 3000 'Loop for three seconds
                CLS 'fill the back buffer with black

                UpdateStars 'these lines are the same as above
                UpdateBackground
                UpdateExplosions
                UpdateWeapons
                DrawStringCenter "G A M E    O V E R", 200, BGRA_WHITE 'display that the game is now over

                _LIMIT UPDATES_PER_SECOND ' Make sure the game doesn't get out of control

                _DISPLAY 'flip the front and back surfaces
            LOOP 'continues looping for three seconds
            Graphics_FadeScreen _FALSE, FADE_FPS, 100 'Fade the screen to black
            intShields = SHIELD_MAX 'shields are at 100%
            Ship.X = 300 'reset the players X
            Ship.Y = 300 'and Y coordinates
            Ship.PowerUpState = 0 'no powerups
            Ship.NumBombs = 0 'the player has no bombs
            SectionCount = 999 'start at the beginning
            byteLevel = 1 'level 1 starts over
            byteLives = LIVES_DEFAULT 'the player has 3 lives left
            boolBackgroundExists = _FALSE 'there is no background picture
            CheckHighScore 'call the sub to see if the player got a high score
            boolStarted = _FALSE 'the game hasn't been started
        END IF
    END IF
END SUB


'This sub updates the animated bombs that appear at the top of the screen when the player gets one
SUB UpdateBombs
    STATIC BombFrame AS LONG 'Keeps track of which animation frame the bombs are one
    STATIC BombFrameCount AS LONG 'The number of game frames that elapse before advancing the animation frame
    DIM XOffset AS LONG 'Offset for the X coordinate
    DIM YOffset AS LONG 'Offset for the Y coordinate
    DIM intCount AS LONG 'Count variable

    IF Ship.NumBombs > 0 THEN 'if the player does have a bomb
        BombFrameCount = BombFrameCount + 1 'increment the bomb frame count

        IF BombFrameCount = 2 THEN 'if we go through 2 game frames
            BombFrameCount = 0 'reset the bomb frame count
            BombFrame = BombFrame + 1 'increment the bomb frame
            IF BombFrame >= BOMB_FRAMES THEN BombFrame = 0 'there are 10 frames of animation for the bomb, if the count reaches the end of the number of frames, reset it to the first frame
        END IF

        XOffset = (BombFrame MOD 4) * BOMB_WIDTH 'Calculate the left of the rectangle
        YOffset = (BombFrame \ 4) * BOMB_HEIGHT 'Calculate the top of the rectangle

        FOR intCount = 1 TO Ship.NumBombs 'loop through the number of bombs the player has
            _PUTIMAGE (250 + (intCount * BOMB_WIDTH), 5), ddsDisplayBomb, , (XOffset, YOffset)-(XOffset + BOMB_WIDTH - 1, YOffset + BOMB_HEIGHT - 1) 'draw as many bombs as the player has
        NEXT
    END IF
END SUB


'This routine fires a missle if the player has one in his possesion
SUB FireMissile
    DIM intCount AS LONG 'standard count variable
    DIM ExplosionRect AS typeRect 'rect structure that defines the position of an enemy ship
    DIM AS LONG w, h

    ' Screen x & y max
    w = _WIDTH - 1
    h = _HEIGHT - 1

    IF Ship.NumBombs = 0 THEN EXIT SUB 'if there aren't any missiles, exit the sub
    Ship.NumBombs = Ship.NumBombs - 1 'otherwise, decrement the number of bombs the player has
    FOR intCount = 0 TO 255 STEP 20 'cycle through the palette
        FrameCount = FrameCount + 1 'Keep track of the frame increment
        IF FrameCount >= 20 THEN 'When 20 frames elapsed
            SectionCount = SectionCount - 1 'Reduce the section the player is on
            UpdateLevels 'Update the section
            FrameCount = 0 'Reset the frame count
        END IF

        'Since this sub will be looping until we finish manipulating the palette, we will need to call all of the normal
        'main functions from here to maintain gameplay while we are busy with this sub

        GetInput 'Get input from the player
        CheckForCollisions 'Check to see if there are any collisions
        CLS 'Fill the back buffer with black
        UpdateBackground 'Update the background bitmap, using a transparent blit
        UpdateStars 'Update the stars
        UpdateObstacles 'Update all obstacles
        UpdateEnemys 'Update the enemies
        UpdatePowerUps _FALSE 'Update the powerups
        UpdateWeapons 'Update the weapon fire
        UpdateExplosions 'Update the explosions
        UpdateShip 'Update the players ship
        IF Ship.Invulnerable THEN UpdateInvulnerability 'If the player is invulnerable, update the invulenerability animation
        UpdateShields 'Update the shield indicator
        UpdateBombs 'Update the missile animation
        DrawString "Score:" + STR$(lngScore), 30, 10, BGRA_PALEGREEN 'Display the score
        DrawString "Lives:" + STR$(byteLives), 175, 10, BGRA_PALEGREEN 'Display lives left
        DrawString "Level:" + STR$(byteLevel), 560, 10, BGRA_PALEGREEN 'Display the current level


        Graphics_DrawFilledRectangle 0, 0, w, h, _RGBA(255, 255, 255, intCount) 'Set the palette to our new palette entry values

        IF boolMaxFrameRate THEN
            DrawString "Uncapped FPS enabled", 30, 45, BGRA_WHITE 'Let the player know there is no frame rate limitation
        ELSE
            _LIMIT UPDATES_PER_SECOND ' Make sure the game doesn't get out of control
        END IF

        _DISPLAY 'Flip the front buffer with the back buffer
    NEXT

    _SNDSETPOS dsMissile, 0 'set the missile wav buffer position to 0
    _SNDPLAY dsMissile 'play the missile wav
    'TODO: If IsFF Then ef(0).start 1, 0                        'if force feedback exists, start the missile effect
    FOR intCount = 0 TO UBOUND(EnemyDesc) 'loop through all the enemies
        IF EnemyDesc(intCount).Exists AND NOT EnemyDesc(intCount).Invulnerable THEN
            'if the enemy exists on screen, and is not invulnerable
            'set the explosion rectangle coordinates
            ExplosionRect.top = EnemyDesc(intCount).Y
            ExplosionRect.bottom = ExplosionRect.top + EnemyDesc(intCount).H
            ExplosionRect.left = EnemyDesc(intCount).X
            ExplosionRect.right = ExplosionRect.left + EnemyDesc(intCount).W

            CreateExplosion ExplosionRect, EnemyDesc(intCount).ExplosionIndex, _FALSE
            'call the sub that creates large explosions and plays the explosion sound

            EnemyDesc(intCount).HasFired = _FALSE 'erase any existing enemy fire
            EnemyDesc(intCount).TimesHit = EnemyDesc(intCount).TimesHit + 30 'the missile does 30x the normal laser 1 damage, add this value to the number of times the enemy has been hit

            IF EnemyDesc(intCount).TimesHit >= EnemyDesc(intCount).TimesDies THEN
                'check to see if the enemy has been hit more times than it takes for it to die, if it has
                'reset the enemy
                EnemyDesc(intCount).Exists = _FALSE 'the enemy no longer exists
                EnemyDesc(intCount).TargetX = 0 'it has no x target
                EnemyDesc(intCount).TargetY = 0 'it has no y target
                EnemyDesc(intCount).TimesHit = 0 'it has never been hit
                EnemyDesc(intCount).XVelocity = 0 'there is no velocity
            END IF
        END IF
    NEXT

    'The rest of the sub takes the red index, and increments it back to black, while mainting normal gameplay procedures

    FOR intCount = 255 TO 0 STEP -5
        FrameCount = FrameCount + 1
        IF FrameCount >= 20 THEN
            SectionCount = SectionCount - 1
            UpdateLevels
            FrameCount = 0
        END IF
        GetInput
        CheckForCollisions
        CLS
        UpdateBackground
        UpdateStars
        UpdateObstacles
        UpdateEnemys
        UpdatePowerUps _FALSE
        UpdateWeapons
        UpdateExplosions
        UpdateShip
        IF Ship.Invulnerable THEN UpdateInvulnerability
        UpdateShields
        UpdateBombs
        DrawString "Score:" + STR$(lngScore), 30, 10, BGRA_PALEGREEN 'Display the score
        DrawString "Lives:" + STR$(byteLives), 175, 10, BGRA_PALEGREEN 'Display lives left
        DrawString "Level:" + STR$(byteLevel), 560, 10, BGRA_PALEGREEN 'Display the current level

        Graphics_DrawFilledRectangle 0, 0, w, h, _RGBA(255, 0, 0, intCount)

        IF boolMaxFrameRate THEN
            DrawString "Uncapped FPS enabled", 30, 45, BGRA_WHITE 'Let the player know there is no frame rate limitation
        ELSE
            _LIMIT UPDATES_PER_SECOND ' Make sure the game doesn't get out of control
        END IF

        _DISPLAY
    NEXT

    'TODO: Do we need this? dd.WaitForVerticalBlank DDWAITVB_BLOCKBEGIN, 0

    Ship.FiringMissile = _FALSE 'The ship is no longer firing a missle
END SUB


'This routine displays the ending credits, fading in and out
SUB DoCredits
    DIM ddsEndCredits AS LONG 'holds the end credit direct draw surface

    CLS 'fill the back buffer with black

    ddsEndCredits = Graphics_LoadImage("./dat/gfx/endcredits.gif", _FALSE, _FALSE, _STR_EMPTY, -1) 'create the end credits direct draw surface
    _ASSERT ddsEndCredits < -1

    _PUTIMAGE (0, 100), ddsEndCredits 'blt the end credits to the back buffer

    _FREEIMAGE ddsEndCredits 'release our direct draw surface

    DrawString "Samuel Gomes - QB64-PE source port", 32, 290, BGRA_YELLOW ' shameless plug XD

    Graphics_FadeScreen _TRUE, FADE_FPS, 100 'Fade the screen in
    SLEEP 2 ' Wait for 2 seconds

    Graphics_FadeScreen _FALSE, FADE_FPS, 100 'Fade the screen out
    SLEEP 1 ' Wait for a second
END SUB


'This subroutine gets input from the player using Direct Input. The boolean flag is so that the missile fire routine doesn't
'loop when a missile is fired
SUB GetInput
    'TODO: Dim JoystickState As DIJOYSTATE                             'joystick state type
    DIM TempTime AS _INTEGER64

    ' TODO: Game controller
    'If Not diJoystick Is Nothing And blnJoystickEnabled Then    'if the joystick object has been set, and the joystick is enabled
    '    diJoystick.Acquire                                      'acquire the joystick
    '    diJoystick.Poll                                         'poll the joystick
    '    diJoystick.GetDeviceState Len(JoystickState), JoystickState  'get the current state of the joystick
    'End If

    IF boolStarted AND NOT boolGettingInput THEN 'if the game has started and we aren't getting input for high scores from the regular form key press events

        'Keyboard
        IF _KEYDOWN(_KEY_UP) THEN 'if the up arrow is down
            Ship.YVelocity = Ship.YVelocity - DISPLACEMENT 'the constant displacement is subtracted from the ships Y velocity
        END IF
        IF _KEYDOWN(_KEY_DOWN) THEN 'if the down arrow is pressed down
            Ship.YVelocity = Ship.YVelocity + DISPLACEMENT 'the constant displacement is added to the ships Y velocity
        END IF
        IF _KEYDOWN(_KEY_LEFT) THEN 'if the left arrow is pressed down
            Ship.XVelocity = Ship.XVelocity - DISPLACEMENT 'the constant displacement is subtracted from the ships X velocity
        END IF
        IF _KEYDOWN(_KEY_RIGHT) THEN 'if the right arrow is down
            Ship.XVelocity = Ship.XVelocity + DISPLACEMENT 'the constant displacement is added to the ships X velocity
        END IF
        IF _KEYDOWN(KEY_SPACE) THEN 'if the space bar is down
            FireWeapon 'call the sub to fire the weapon
        END IF
        IF _KEYDOWN(_KEY_RCTRL) AND NOT Ship.FiringMissile AND Ship.NumBombs > 0 THEN
            Ship.FiringMissile = _TRUE 'if the control key is pressed
            FireMissile 'fire the missile
        END IF
        IF _KEYDOWN(_KEY_LCTRL) AND NOT Ship.FiringMissile AND Ship.NumBombs > 0 THEN
            Ship.FiringMissile = _TRUE 'if the control key is pressed
            FireMissile 'fire the missile
        END IF

        'TODO: Joystick
        'If Not diJoystick Is Nothing And blnJoystickEnabled Then 'if the joystick object exists, and the joystick is enabled

        '    Ship.XVelocity = Ship.XVelocity + (JoystickState.x - JOYSTICKCENTERED) * 0.00002136 'increment the players x velocity by the offset from the joysticks center times the offset factor
        '    Ship.YVelocity = Ship.YVelocity + (JoystickState.y - JOYSTICKCENTERED) * 0.00002136 'increment the players x velocity by the offset from the joysticks center times the offset factor
        '    If JoystickState.buttons(0) And &H80 Then           'if button 0 is pressed
        '         FireWeapon                                 'fire the weapon
        '    End If
        '    If JoystickState.buttons(1) And &H80 And Not Ship.FiringMissile And Ship.NumBombs > 0 Then 'if button 1 is pressed, and the ship isn't firing a missile and the player has missile to fire then
        '        Ship.FiringMissile = True                       'the ship is now firing a missile
        '         FireMissile                                'fire the missile
        '    End If
        'End If

        IF _KEYDOWN(_KEY_BACKSPACE) THEN 'if the backspace key is pressed
            IF Ship.Invulnerable THEN 'if the ship is invulnerable
                _SNDSTOP dsInvulnerability 'stop playing the invulnerability sound
                TempTime = Ship.InvulnerableTime - Time_GetTicks 'capture the current time so the player doesn't lose the amount of time he has left to be invulnerable
            END IF
            IF Ship.AlarmActive THEN _SNDSTOP dsAlarm 'if the low shield alarm is playing, stop that
            ' pause music
            PauseMIDI _TRUE

            DrawStringCenter "(Paused - Press ENTER to resume)", 200, BGRA_ORANGERED 'display the pause text
            _DISPLAY 'flip the surfaces to show the back buffer

            'Check the keyboard for keypresses
            DO
                SLEEP ' don't hog the CPU
            LOOP UNTIL _KEYDOWN(_KEY_ENTER)

            ' resume music
            PauseMIDI _FALSE

            IF Ship.Invulnerable THEN 'if the ship was invulnerable
                _SNDLOOP dsInvulnerability 'start the invulenrability wave again
                Ship.InvulnerableTime = TempTime + Time_GetTicks 'the amount of time the player had left is restored
            END IF
            IF Ship.AlarmActive THEN 'if the low shield alarm was playing
                _SNDLOOP dsAlarm 'start it again
            END IF
        END IF
    ELSE 'The game has not started yet
        DIM keyCode AS LONG: keyCode = _KEYHIT

        IF boolGettingInput THEN 'If the game is getting high score input then
            IF (keyCode >= 0 AND keyCode <= 127 AND String_IsAlphaNumeric(keyCode)) OR keyCode = KEY_SPACE THEN 'if the keys are alpha keys then
                strBuffer = CHR$(keyCode) 'add this key to the buffer
            ELSEIF keyCode = _KEY_ENTER AND LEN(_TRIM$(strName)) > NULL THEN 'if enter has been pressed
                boolEnterPressed = _TRUE 'toggle the enter pressed flag to on
            ELSEIF keyCode = _KEY_BACKSPACE THEN 'if backspace was pressed
                IF LEN(strName) > 0 THEN strName = LEFT$(strName, LEN(strName) - 1) 'make the buffer is not empty, and delete any existing character
            END IF
        ELSEIF keyCode = _KEY_ENTER THEN
            'if the enter key is pressed then
            boolStarted = _TRUE 'the game has started
            'TODO: If Not ef(2) Is Nothing And IsFF Then ef(2).Download
            'download the force feedback effect for firing lasers
            Graphics_FadeScreen _FALSE, FADE_FPS, 100 'fade the current screen
            StartIntro 'show the intro text
            byteLives = LIVES_DEFAULT 'Set lives
            intShields = SHIELD_MAX 'Set shields
            byteLevel = 1 'level 1 to start with
            SectionCount = 999 'start at the first section and count down
            LoadLevel byteLevel 'load level 1
            PlayMIDIFile "./dat/sfx/mus/level1.mid" 'start the level 1 midi
            ' Stars were reset here before. This is not needed
            ' Stars can be recycled and beginning a new level does not feel jarring
        ELSEIF keyCode = _KEY_ESC THEN 'if the escape key is pressed,
            DoCredits 'Show the credits
            EndGame 'Call sub to reset all variables
            SYSTEM 'Exit the application
        ELSEIF keyCode = KEY_LOWER_F OR keyCode = KEY_UPPER_F THEN 'if the F key is pressed
            IF boolFrameRate THEN 'if the frame rate display is toggled
                boolFrameRate = _FALSE 'turn it off
            ELSE 'otherwise
                boolFrameRate = _TRUE 'turn it on
            END IF
        ELSEIF keyCode = KEY_LOWER_J OR keyCode = KEY_UPPER_J THEN 'if the J key is pressed
            IF blnJoystickEnabled THEN 'if the joystick is enabled
                blnJoystickEnabled = _FALSE 'turn it off
            ELSE 'otherwise
                blnJoystickEnabled = _TRUE 'turn it on
            END IF
        ELSEIF (keyCode = KEY_LOWER_M OR keyCode = KEY_UPPER_M) AND NOT boolStarted THEN
            'if the M key is pressed, and the game has not started
            IF blnMIDIEnabled THEN 'if midi is enabled
                PlayMIDIFile _STR_EMPTY 'stop playing any midi
                blnMIDIEnabled = _FALSE 'toggle it off
            ELSE 'otherwise
                blnMIDIEnabled = _TRUE 'turn the midi on
                PlayMIDIFile "./dat/sfx/mus/title.mid" 'play the title midi
            END IF
        ELSEIF keyCode = KEY_LOWER_X OR keyCode = KEY_UPPER_X THEN 'if the X key has been pressed
            IF boolMaxFrameRate THEN 'if the maximum frame rate is toggled
                boolMaxFrameRate = _FALSE 'toggle it off
            ELSE 'otherwise
                boolMaxFrameRate = _TRUE 'toggle it on
            END IF
        END IF
    END IF
END SUB


' Loads and plays a MIDI file (loops it too)
SUB PlayMIDIFile (fileName AS STRING)
    IF blnMIDIEnabled THEN
        $IF WINDOWS THEN
            IF _FILEEXISTS(fileName) THEN
                MIDI_PlayFromFile fileName
                MIDI_Loop _TRUE
            ELSE
                MIDI_Stop
            END IF
        $ELSE
            ' Unload if there is anything previously loaded
            IF MIDIHandle > 0 THEN
                _SNDSTOP MIDIHandle
                _SNDCLOSE MIDIHandle
                MIDIHandle = 0
            END IF

            ' Check if the file exists
            IF _FILEEXISTS(fileName) THEN
                MIDIHandle = _SNDOPEN(fileName, "stream")
                _ASSERT MIDIHandle > 0

                ' Loop the MIDI file
                IF MIDIHandle > 0 THEN _SNDLOOP MIDIHandle
            END IF
        $END IF
    END IF
END SUB


' Pauses / unpauses MIDI playback
SUB PauseMIDI (pause AS _BYTE)
    IF blnMIDIEnabled THEN
        $IF WINDOWS THEN
            MIDI_Pause pause
        $ELSE
            IF pause THEN _SNDPAUSE MIDIHandle ELSE _SNDLOOP MIDIHandle
        $END IF
    END IF
END SUB


' Chear mouse and keyboard events
' TODO: Game controller?
SUB ClearInput
    WHILE _MOUSEINPUT
    WEND
    _KEYCLEAR
END SUB
'-----------------------------------------------------------------------------------------------------------------------

'-----------------------------------------------------------------------------------------------------------------------
' HEADER FILES
'-----------------------------------------------------------------------------------------------------------------------
'$INCLUDE:'include/GraphicOps.bas'
$IF WINDOWS THEN
    '$INCLUDE:'include/File.bas'
    '$INCLUDE:'include/WinMIDIPlayer.bas'
$END IF
'-----------------------------------------------------------------------------------------------------------------------
'-----------------------------------------------------------------------------------------------------------------------
