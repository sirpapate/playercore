[comment]: <> (## For more information, go to the [GitHub Page][GitHub Page])
[comment]: <> (To convert this file in Steam format, use this website: https://steamdown.vercel.app/)

# PlayerCore

It's the PlyCore, an extension for the Expression 2 that add functions to manipulate players. All functions can be called on yourself or on other players if you have their prop protection rights.

## Workshop Installation

The PlayerCore is available on the Steam Workshop! Go to the [PlayerCore Workshop Page][PlayerCore Workshop Page] and press `Subscribe`. For can go to the [Expression 2 Core Collection][Expression 2 Core Collection] for more extensions.

## Manual Installation

Clone this repository into your `steamapps\common\GarrysMod\garrysmod\addons` folder using this command if you are using git:

    git clone https://github.com/sirpapate/playercore.git

## Documentation

### Console Commands
`sbox_e2_plycore`
* "1" - Everyone can use the functions on Everyone.
* "2" - People can use the functions only on their friends.
* "3" - Only admins can use functions.
* "4" - The functions of players setting are disabled.

### Lua
__Hook__
`PlyCoreCommand(ply, target, command)`

Called when a player use a command of PlyCore.

__Arguments__
* "Player" - originator
* "Player" - target
* "string" - command

__Return__
"boolean" - Return true to block the command.

## Functions
The following functions are protected by Protection Prop. To use them on another player, you must have their rights. Look the command "sbox_e2_plycore".

### Basic Getters and Setters
| Function                          | Return | Description                                                                                    |
|-----------------------------------|:------:|------------------------------------------------------------------------------------------------|
| E:plyGetMass()                    | N      | Returns the mass of the player.                                                                |
| E:plyGetJumpPower()               | N      | Returns the jump power of the player.                                                          |
| E:plyGetGravity()                 | N      | Returns the gravity of the player.                                                             |
| E:plyGetSpeed()                   | N      | Returns the walk speed of the player.                                                          |
| E:plySetPos(vector pos)           |        | Sets the position of the player.                                                               |
| E:plySetAng(angle ang)            |        | Sets the angle of the player's camera.                                                         |
| E:plySetHealth(N)                 |        | Sets the health of the player.                                                                 |
| E:plySetArmor(N)                  |        | Sets the armor of the player.                                                                  |
| E:plySetMass(N)                   |        | Sets the mass of the player. default 85                                                        |
| E:plySetJumpPower(N)              |        | Sets the jump power, eg. the velocity the player will applied to when he jumps. default 200    |
| E:plySetGravity(N)                |        | Sets the gravity of the player. default 600                                                    |
| E:plySetSpeed(N)                  |        | Sets the walk and run speed of the player. (run speed is double of the walk speed) default 200 |
| E:plySetRunSpeed(N)               |        | Sets the run speed of the player. default 400                                                  |
| E:plySetWalkSpeed(N)              |        | Sets the walk speed of the player. default 200                                                 |
| E:plyResetSettings()              |        | Resets the settings of the player.                                                             |

### Actions
| Function                          | Return | Description                                                                                    |
|-----------------------------------|:------:|------------------------------------------------------------------------------------------------|
| E:plyApplyForce(vector force)     |        | Sets the velocity of the player.                                                               |
| E:plyNoclip(N)                    |        | Enable or disable the player's noclip.                                                         |
| E:plyDisableNoclip(N)             |        | Disables the noclip of the player.                                                             |
| E:plyEnterVehicle(entity vehicle) |        | Force the player to enter a vehicle.                                                           |
| E:plyExitVehicle()                |        | Force the player to exit the vehicle he is in.                                                 |
| E:plySpawn()                      |        | Respawns the player.                                                                           |
| E:plyFreeze(N)                    |        | Freezes the player.                                                                            |
| E:plyIsFrozen()                   | N      | Returns 1 if the player is frozen, 0 otherwise.                                                |
| E:plyGod(N)                       |        | Enables of disables the godmode of the player.                                                 |
| E:plyHasGod()                     | N      | Returns 1 if the player has godmode, 0 otherwise.                                              |
| E:plyIgnite(N)                    |        | Ignites the player for a specific time. (in seconds)                                           |
| E:plyIgnite()                     |        | Returns 1 if the player is ignited, 0 otherwise.                                               |
| E:plyExtinguish()                 |        | Extinguishes the player.                                                                       |

### Message Functions
| Function                          | Return | Description                                                                                    |
|-----------------------------------|:------:|------------------------------------------------------------------------------------------------|
| sendMessage(S)                    |        | Sends a message to every player.                                                               |
| sendMessageCenter(S)              |        | Sends a message to every player in the center of the screen.                                   |
| E:sendMessage(S)                  |        | Sends a message to the player.                                                                 |
| E:sendMessageCenter(S)            |        | Sends a message to the player in the center of the screen.                                     |
| R:sendMessage(S)                  |        | Sends a message to a list of players.                                                          |
| R:sendMessageCenter(S)            |        | Sends a message to a list of players in the center of the screen.                              |
| sendMessageColor(R)               |        | Sends a colored message to every player.                                                       |
| sendMessageColor(...)             |        | Sends a colored message to every player.                                                       |
| E:sendMessageColor(R)             |        | Sends a colored message to a player.                                                           |
| E:sendMessageColor(...)           |        | Sends a colored message to a player.                                                           |
| R:sendMessageColor(R)             |        | Sends a colored message to a list of players.                                                  |
| R:sendMessageColor(...)           |        | Sends a colored message to a list of players.                                                  |

### Other Functions
| Function                          | Return | Description                                                                                    |
|-----------------------------------|:------:|------------------------------------------------------------------------------------------------|
| E:ip()                            | S      | Returns the ip of the player. (only if the player is admin)                                    |

[PlayerCore Workshop Page]: <https://steamcommunity.com/sharedfiles/filedetails/?id=216044582>
[Expression 2 Core Collection]: <https://steamcommunity.com/workshop/filedetails/?id=726399057>
[GitHub Page]: <https://github.com/sirpapate/playercore>