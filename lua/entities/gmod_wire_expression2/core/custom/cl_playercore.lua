E2Helper.Descriptions["plyGetMass"] = "Returns the mass of the player."
E2Helper.Descriptions["plyGetJumpPower"] = "Returns the jump power of the player."
E2Helper.Descriptions["plyGetGravity"] = "Returns the gravity of the player."
E2Helper.Descriptions["plyGetSpeed"] = "Returns the walk speed of the player."
E2Helper.Descriptions["plySetPos"] = "Sets the position of the player."
E2Helper.Descriptions["plySetAng"] = "Sets the angle of the player's camera."
E2Helper.Descriptions["plySetHealth"] = "Sets the health of the player."
E2Helper.Descriptions["plySetArmor"] = "Sets the armor of the player."
E2Helper.Descriptions["plySetMass"] = "Sets the mass of the player. default 85."
E2Helper.Descriptions["plySetJumpPower"] = "Sets the jump power, eg. the velocity the player will applied to when he jumps. default 200"
E2Helper.Descriptions["plySetGravity"] = "Sets the gravity of the player. default 600"
E2Helper.Descriptions["plySetSpeed"] = "Sets the walk and run speed of the player. (run speed is double of the walk speed) default 200"
E2Helper.Descriptions["plySetRunSpeed"] = "Sets the run speed of the player. default 400"
E2Helper.Descriptions["plySetWalkSpeed"] = "Sets the walk speed of the player. default 200"
E2Helper.Descriptions["plyResetSettings"] = "Resets the settings of the player."

E2Helper.Descriptions["plyApplyForce"] = "Sets the velocity of the player."
E2Helper.Descriptions["plyNoclip"] = "Enable or disable the player's noclip."
E2Helper.Descriptions["plyDisableNoclip"] = "Disables the noclip of the player."
E2Helper.Descriptions["plyEnterVehicle"] = "Force the player to enter a vehicle."
E2Helper.Descriptions["plyExitVehicle"] = "Force the player to exit the vehicle he is in."
E2Helper.Descriptions["plySpawn"] = "Respawns the player."
E2Helper.Descriptions["plyFreeze"] = "Freezes the player."
E2Helper.Descriptions["plyIsFrozen"] = "Returns 1 if the player is frozen, 0 otherwise."
E2Helper.Descriptions["plyGod"] = "Enables of disables the godmode of the player."
E2Helper.Descriptions["plyHasGod"] = "Returns 1 if the player has godmode, 0 otherwise."
E2Helper.Descriptions["plyIgnite"] = "Ignites the player for a specific time. (in seconds)"
E2Helper.Descriptions["plyIgnite"] = "Returns 1 if the player is ignited, 0 otherwise."
E2Helper.Descriptions["plyExtinguish"] = "Extinguishes the player."

E2Helper.Descriptions["sendMessage"] = "Sends a message to every player."
E2Helper.Descriptions["sendMessageCenter"] = "Sends a message to every player in the center of the screen."
E2Helper.Descriptions["sendMessage"] = "Sends a message to the player."
E2Helper.Descriptions["sendMessageCenter"] = "Sends a message to the player in the center of the screen."
E2Helper.Descriptions["sendMessage"] = "Sends a message to a list of players."
E2Helper.Descriptions["sendMessageCenter"] = "Sends a message to a list of players in the center of the screen."
E2Helper.Descriptions["sendMessageColor"] = "Sends a colored message to every player."
E2Helper.Descriptions["sendMessageColor"] = "Sends a colored message to every player."
E2Helper.Descriptions["sendMessageColor"] = "Sends a colored message to a player."
E2Helper.Descriptions["sendMessageColor"] = "Sends a colored message to a player."
E2Helper.Descriptions["sendMessageColor"] = "Sends a colored message to a list of players."
E2Helper.Descriptions["sendMessageColor"] = "Sends a colored message to a list of players."

E2Helper.Descriptions["ip"] = "Returns the ip of the player. (only if the player is admin)"

local plys = {}


net.Receive("wire_expression2_playercore_sendmessage", function( len, ply )
	local ply = net.ReadEntity()
	if ply and not plys[ply] then
		plys[ply] = true
		-- printColorDriver is used for the first time on us by this chip
		WireLib.AddNotify(msg1, NOTIFY_GENERIC, 7, NOTIFYSOUND_DRIP3)
		WireLib.AddNotify(msg2, NOTIFY_GENERIC, 7)
		chat.AddText(Color(255, 50, 50),"After this message, ", ply, " can send you a 100% realistically fake people talking, including admins.")
		chat.AddText(Color(255, 50, 50),"Look the console to see if the message is form an expression2")
	end

	LocalPlayer():PrintMessage(HUD_PRINTCONSOLE, "[E2] " .. ply:Name() .. ": ")
	chat.AddText(Color(255, 50, 50), "> ", Color(151, 211, 255), unpack(net.ReadTable()))
end)

hook.Add("PlayerNoClip", "PlyCore", function(ply, state)
	if not state then return end

	if ply:GetNWBool("PlyCore_DisableNoclip", false) then
		return false
	end
end)

CreateClientConVar( "wire_expression2_playercore_message_max", 15, true, true )
CreateClientConVar( "wire_expression2_playercore_message_delay", 0.3, true, true )
CreateClientConVar( "wire_expression2_playercore_message_max_length", 1000, true, true )