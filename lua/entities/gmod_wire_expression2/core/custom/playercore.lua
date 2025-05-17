
E2Lib.RegisterExtension("playercore", true)

local sbox_E2_PlyCore = CreateConVar("sbox_E2_PlyCore", "2", FCVAR_ARCHIVE)

local function ValidPly(ply)
	if not IsValid(ply) or not ply:IsPlayer() then
		return false
	end

	return true
end


local function hasAccess(ply, target, command)
	local valid = hook.Call("PlyCoreCommand", GAMEMODE, ply, target, command)

	if valid ~= nil then
		return valid
	end

	if sbox_E2_PlyCore:GetInt() == 1 then
		return true
	elseif sbox_E2_PlyCore:GetInt() == 2 then
		if not target then return true end
		if target:IsBot() then return true end
		if ply == target then return true end
		if ply:IsAdmin() then return true end

		if CPPI then
			for k, v in pairs(target:CPPIGetFriends())  do
				if v == ply then
					return true
				end
			end
		end

		return false
	elseif sbox_E2_PlyCore:GetInt() == 3 then
		if not ply:IsAdmin() then return false end

		return true
	else
		return false
	end

end

local function check(v)
	return	-math.huge < v[1] and v[1] < math.huge and
			-math.huge < v[2] and v[2] < math.huge and
			-math.huge < v[3] and v[3] < math.huge
end


--[[******************************************************************************]]
-- Stolen from Wire :)

-- default delay for printing messages, adds one "charge" after this delay
local defaultPrintDelay = {
	["message"] = 0.3,
}

-- the amount of "charges" a player has by default
local defaultMaxPrints = {
	["message"] = 15,
}

-- default max print length
local defaultMaxLength = game.SinglePlayer() and 10000 or 1000

-- Contains the amount of "charges" a player has, i.e. the amount of print-statements can be executed before
-- the messages being omitted. The defaultPrintDelay is the time required to add one additional charge to the
-- player's account. The defaultMaxPrints variable are the charges the player starts with.
local printDelays = {}

-- Returns the table containing the player's charges or creatis if it it does not yet exist
-- @param ply           player to get the table from, not validated
-- @param target        target to get the table from, not validated
-- @param type          type of the table to get, not validated
-- @param maxCharges    amount of charges to set it the table has to be created
-- @param chargesDelay  delay until a new charge is given, set it the table has to be created
local function getDelaysOrCreate(ply, target, type, maxCharges, chargesDelay)
	printDelays[type] = printDelays[type] or {}
	printDelays[type][ply] = printDelays[type][ply] or {}
	local printDelay = printDelays[type][ply][target]

	if not printDelay then
		-- if the player does not have an entry yet, add it
		printDelay = { numCharges = maxCharges, lastTime = CurTime() }
		printDelays[type][ply][target] = printDelay
	end

	return printDelay
end

-- Returns whether or not a player has "charges" for printing a message
-- Additionally adds all new charges the player might have
-- @param ply  player to check, not validated
-- @param target  target to check, not validated
local function canPrint(ply, target, type)
	-- update the console variables just in case
	local maxCharges = ply:GetInfoNum("wire_expression2_playercore_" .. type .. "_max", defaultMaxPrints[type])
	local chargesDelay = ply:GetInfoNum("wire_expression2_playercore_" .. type .. "_delay", defaultPrintDelay[type])

	local printDelay = getDelaysOrCreate(ply, target, type, maxCharges, chargesDelay)

	local currentTime = CurTime()
	if printDelay.numCharges < maxCharges then
		-- check if the player "deserves" new charges
		local timePassed = (currentTime - printDelay.lastTime)
		if timePassed > chargesDelay then
			if chargesDelay == 0 then
				printDelay.lastTime = currentTime
				printDelay.numCharges = maxCharges
			else
				local chargesToAdd = math.floor(timePassed / chargesDelay)
				printDelay.lastTime = (currentTime - (timePassed % chargesDelay))
				-- add "semi" charges the player might already have
				printDelay.numCharges = printDelay.numCharges + chargesToAdd
			end
		end
	end
	-- we should clamp his charges for safety
	if printDelay.numCharges > maxCharges then
		printDelay.numCharges = maxCharges
		-- remove the "semi" charges, otherwise the player has too many
		printDelay.lastTime = currentTime
	end

	return printDelay and printDelay.numCharges > 0
end

-- Returns whether or not a player can currently print a message or if it will be omitted by the antispam
-- Additionally removes one charge from the player's account
-- @param ply  player to check, is not validated
-- @param target  target to check, is not validated
local function checkDelay(ply, target, type)
	if canPrint(ply, target, type) then
		local maxCharges = ply:GetInfoNum("wire_expression2_playercore_" .. type .. "_max", defaultMaxPrints[type])
		local chargesDelay = ply:GetInfoNum("wire_expression2_playercore_" .. type .. "_delay", defaultPrintDelay[type])
		local printDelay = getDelaysOrCreate(ply, target, type, maxCharges, chargesDelay)
		printDelay.numCharges = printDelay.numCharges - 1
		return true
	end
	return false
end

local e2PcLastEnterVehicle = {}
local e2PcLastSpawn = {}
registerCallback("destruct",function(self)
	e2PcLastEnterVehicle[self] = nil
	e2PcLastSpawn[self] = nil
end)

hook.Add("PlayerDisconnected", "e2_print_delays_player_dc", function(ply)
	for _, typePrintDelays in pairs(printDelays) do
		typePrintDelays[ply] = nil
		
		for _, playerPrintDelays in pairs(typePrintDelays) do
			if playerPrintDelays[ply] then
				playerPrintDelays[ply] = nil
			end
		end
	end

	for _, plyList in pairs(e2PcLastEnterVehicle) do
		plyList[ply] = nil
	end

	for _, plyList in pairs(e2PcLastSpawn) do
		plyList[ply] = nil
	end
end)

--[[******************************************************************************]]

-------------------------------------------------------------------------------------------------------------------------------

--- Sets the velocity of the player.
e2function void entity:plyApplyForce(vector force)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "applyforce") then self:throw("You do not have access", nil) end

	if check(force) then
		this:SetVelocity(Vector(force[1],force[2],force[3]))
	end
end

--- Sets the position of the player.
e2function void entity:plySetPos(vector pos)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "setpos") then self:throw("You do not have access", nil) end

	this:SetPos(Vector(math.Clamp(pos[1],-16000,16000), math.Clamp(pos[2],-16000,16000), math.Clamp(pos[3],-16000,16000)))
end

--- Sets the angle of the player's camera.
e2function void entity:plySetAng(angle ang)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "setang") then self:throw("You do not have access", nil) end

	local normalizedAng = Angle(ang[1], ang[2], ang[3])
	normalizedAng:Normalize()
	this:SetEyeAngles(normalizedAng)
end

--- Enable or disable the player's noclip.
e2function void entity:plyNoclip(number activate)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "noclip") then self:throw("You do not have access", nil) end

	if activate > 0 then
		this:SetMoveType(MOVETYPE_NOCLIP)
	else
		this:SetMoveType(MOVETYPE_WALK)
	end
end

--- Sets the health of the player.
e2function void entity:plySetHealth(number health)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "sethealth") then self:throw("You do not have access", nil) end

	this:SetHealth(math.Clamp(health, 0, 2^32/2-1))
end

--- Sets the armor of the player.
e2function void entity:plySetArmor(number armor)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "setarmor") then self:throw("You do not have access", nil) end

	this:SetArmor(math.Clamp(armor, 0, 2^32/2-1))
end

--- Sets the mass of the player. default 85
e2function void entity:plySetMass(number mass)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "setmass") then self:throw("You do not have access", nil) end

	this:GetPhysicsObject():SetMass(math.Clamp(mass, 1, 50000))
end

--- Returns the mass of the player.
e2function number entity:plyGetMass()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end

	return this:GetPhysicsObject():GetMass()
end

--- Sets the jump power, eg. the velocity the player will applied to when he jumps. default 200 
e2function void entity:plySetJumpPower(number jumpPower)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "setjumppower") then self:throw("You do not have access", nil) end

	this:SetJumpPower(math.Clamp(jumpPower, 0, 2^32/2-1))
end

--- Returns the jump power of the player.
e2function number entity:plyGetJumpPower()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end

	return this:GetJumpPower()
end

--- Sets the gravity of the player. default 600
e2function void entity:plySetGravity(number gravity)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "setgravity") then self:throw("You do not have access", nil) end

	if gravity == 0 then gravity = 1/10^10 end
	this:SetGravity(gravity/600)
end

--- Returns the gravity of the player.
e2function number entity:plyGetGravity()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end

	return this:GetGravity()*600
end

--- Sets the walk and run speed of the player. (run speed is double of the walk speed) default 200
e2function void entity:plySetSpeed(number speed)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "setspeed") then self:throw("You do not have access", nil) end


	this:SetWalkSpeed(math.Clamp(speed, 1, 10000))
	this:SetRunSpeed(math.Clamp(speed*2, 1, 10000))
end

--- Sets the run speed of the player. default 400
e2function void entity:plySetRunSpeed(number speed)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "setrunspeed") then self:throw("You do not have access", nil) end

	this:SetRunSpeed(math.Clamp(speed*2, 1, 10000))
end

--- Sets the walk speed of the player. default 200
e2function void entity:plySetWalkSpeed(number speed)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "setwalkspeed") then self:throw("You do not have access", nil) end

	this:SetWalkSpeed(math.Clamp(speed, 1, 10000))
end

--- Returns the max speed of the player.
e2function number entity:plyGetSpeed()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end

	return this:GetWalkSpeed()
end

--- Resets the settings of the player.
e2function void entity:plyResetSettings()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "resetsettings") then self:throw("You do not have access", nil) end

	this:Health(100)
	this:GetPhysicsObject():SetMass(85)
	this:SetJumpPower(200)
	this:SetGravity(1)
	this:SetWalkSpeed(200)
	this:SetRunSpeed(400)
	this:Armor(0)
end

--- Force the player to enter a vehicle.
e2function void entity:plyEnterVehicle(entity vehicle)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "entervehicle") then self:throw("You do not have access", nil) end
	if not vehicle or not vehicle:IsValid() or not vehicle:IsVehicle() then return nil end

	e2PcLastEnterVehicle[self] = e2PcLastEnterVehicle[self] or {}
	e2PcLastEnterVehicle[self][this] = e2PcLastEnterVehicle[self][this] or 0
	if (CurTime() - e2PcLastEnterVehicle[self][this]) < 1 then return nil end
	e2PcLastEnterVehicle[self][this] = CurTime()


	if this:InVehicle() then this:ExitVehicle() end

	this:EnterVehicle(vehicle)
end

--- Force the player to exit the vehicle he is in.
e2function void entity:plyExitVehicle()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "exitvehicle") then self:throw("You do not have access", nil) end
	if not this:InVehicle() then return nil end

	this:ExitVehicle()
end

--- Respawns the player.
e2function void entity:plySpawn()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "spawn") then self:throw("You do not have access", nil) end
	
	e2PcLastSpawn[self] = e2PcLastSpawn[self] or {}
	e2PcLastSpawn[self][this] = e2PcLastSpawn[self][this] or 0
	if (CurTime() - e2PcLastSpawn[self][this]) < 1 then return nil end
	e2PcLastSpawn[self][this] = CurTime()

	this:Spawn()
end

-- Freeze

registerCallback("destruct",function(self)
	for _, ply in pairs(player.GetAll()) do
		if ply.plycore_freezeby == self then
			ply:Freeze(false)
		end

		if ply.plycore_noclipdiabledby == self then
			ply:SetNWBool("PlyCore_DisableNoclip", false)
		end
	end
end)

--- Freezes the player.
e2function void entity:plyFreeze(number freeze)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "freeze") then self:throw("You do not have access", nil) end

	this.plycore_freezeby = self
	this:Freeze(freeze == 1)
end

--- Returns 1 if the player is frozen, 0 otherwise.
e2function number entity:plyIsFrozen()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end

	return this:IsFlagSet(FL_FROZEN)
end

--- Disables the noclip of the player.
e2function void entity:plyDisableNoclip(number act)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "disablenoclip") then self:throw("You do not have access", nil) end

	this.plycore_noclipdiabledby = self
	this:SetNWBool("PlyCore_DisableNoclip", act == 1)
end

hook.Add("PlayerNoClip", "PlyCore", function(ply, state)
	if not state then return end

	if ply:GetNWBool("PlyCore_DisableNoclip", false) then
		return false
	end
end)

--- Enables of disables the godmode of the player.
e2function void entity:plyGod(number active)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "god") then self:throw("You do not have access", nil) end
	if not active == 1 then active = 0 end

	if active == 1 then
		this:GodEnable()
	else
		this:GodDisable()
	end
end

--- Returns 1 if the player has godmode, 0 otherwise.
e2function number entity:plyHasGod()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end

	return this:HasGodMode() and 1 or 0
end

--- Ignites the player for a specific time. (in seconds)
e2function void entity:plyIgnite(time)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "ignite") then self:throw("You do not have access", nil) end

	this:Ignite(math.Clamp(time, 1, 3600))
end

--- Returns 1 if the player is ignited, 0 otherwise.
e2function void entity:plyIgnite()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "ignite") then self:throw("You do not have access", nil) end

	this:Ignite(60)
end

--- Extinguishes the player.
e2function void entity:plyExtinguish()
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "extinguish") then self:throw("You do not have access", nil) end

	this:Extinguish()
end

--- Returns the ip of the player. (only if the player is admin)
e2function string entity:ip()
	if not ValidPly(this) or this:IsBot() then return "" end
	local valid = hook.Call("PlyCoreCommand", GAMEMODE, self.player, nil, "getip")

	if valid == nil then
		valid = self.player:IsAdmin()
	end

	if valid then
		return this:IPAddress()
	end

	return ""
end

-- Message


--- Sends a message to every player.
e2function void sendMessage(string text)
	if not hasAccess(self.player, nil, "globalmessage") then self:throw("You do not have access", nil) end
	
	for _, ply in pairs(player.GetAll()) do
		if not ValidPly(ply) then return nil end
		if not hasAccess(self.player, ply, "message") then self:throw("You do not have access", nil) end
	end

	for _, ply in pairs(player.GetAll()) do
		if not checkDelay(self.player, ply, "message") then continue end

		ply:PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
		ply:PrintMessage(HUD_PRINTTALK, text)
	end
end

--- Sends a message to every player in the center of the screen.
e2function void sendMessageCenter(string text)
	if not hasAccess(self.player, nil, "globalmessagecenter") then self:throw("You do not have access", nil) end
	
	for _, ply in pairs(player.GetAll()) do
		if not ValidPly(ply) then return nil end
		if not hasAccess(self.player, ply, "messagecenter") then self:throw("You do not have access", nil) end
	end

	for _, ply in pairs(player.GetAll()) do
		if not checkDelay(self.player, ply, "message") then continue end

		ply:PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
		ply:PrintMessage(HUD_PRINTCENTER, text)
	end
end

--

--- Sends a message to the player.
e2function void entity:sendMessage(string text)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "message") then self:throw("You do not have access", nil) end
	if not checkDelay(self.player, this, "message") then return end

	this:PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
	this:PrintMessage(HUD_PRINTTALK, text)
end

--- Sends a message to the player in the center of the screen.
e2function void entity:sendMessageCenter(string text)
	if not ValidPly(this) then return self:throw("Invalid player", nil) end
	if not hasAccess(self.player, this, "messagecenter") then self:throw("You do not have access", nil) end
	if not checkDelay(self.player, this, "message") then return end

	this:PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
	this:PrintMessage(HUD_PRINTCENTER, text)
end

--

--- Sends a message to a list of players.
e2function void array:sendMessage(string text)
	for _, ply in pairs(this) do
		if not ValidPly(ply) then return nil end
		if not hasAccess(self.player, ply, "message") then self:throw("You do not have access", nil) end
	end

	for _, ply in pairs(this) do
		if not checkDelay(self.player, this, "message") then continue end

		ply:PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
		ply:PrintMessage(HUD_PRINTTALK, text)
	end
end

--- Sends a message to a list of players in the center of the screen.
e2function void array:sendMessageCenter(string text)
	for _, ply in pairs(this) do
		if not ValidPly(ply) then return nil end
		if not hasAccess(self.player, ply, "messagecenter") then self:throw("You do not have access", nil) end
	end

	for _, ply in pairs(this) do
		if not checkDelay(self.player, this, "message") then continue end
		
		ply:PrintMessage(HUD_PRINTCONSOLE, self.player:Name() .. " send you the next message by an expression 2.")
		ply:PrintMessage(HUD_PRINTCENTER, text)
	end
end


util.AddNetworkString("wire_expression2_playercore_sendmessage")

local printColor_typeids = {
	n = tostring,
	s = tostring,
	v = function(v) return Color(v[1],v[2],v[3]) end,
	xv4 = function(v) return Color(v[1],v[2],v[3],v[4]) end,
	e = function(e) return IsValid(e) and e:IsPlayer() and e or "" end,
}

local printColor_types = {
	number = tostring,
	string = tostring,
	Vector = function(v) return Color(v[1],v[2],v[3]) end,
	table = function(tbl)
		for i,v in pairs(tbl) do
			if !isnumber(i) then return "" end
			if !isnumber(v) then return "" end
			if i < 1 or i > 4 then return "" end
		end
		return Color(tbl[1] or 0, tbl[2] or 0,tbl[3] or 0,tbl[4])
	end,
	Player = function(e) return IsValid(e) and e:IsPlayer() and e or "" end,
}

local function fromColorArgs(args, typeids)
	local send_array = args

	for i,tp in ipairs(typeids) do
		if printColor_typeids[tp] then
			send_array[i] = printColor_typeids[tp](send_array[i])
		else
			send_array[i] = ""
		end
	end

	return send_array
end

local function fromColorArray(arr)
	local send_array = arr

	for i,tp in ipairs_map(arr,type) do
		if printColor_types[tp] then
			send_array[i] = printColor_types[tp](arr[i])
		else
			send_array[i] = ""
		end
	end

	return send_array
end


local function printColor(ply, targets, send_array)
	targets = isentity(targets) and {targets} or targets
	targets = targets or player.GetAll()

	local plys = {}
	for _, target in pairs(targets) do
		if ValidPly(target) and checkDelay(ply, target, "messagecolor") then
			table.insert(plys, target)
		end
	end

	for _, target in pairs(plys) do
		local targetMaxLength = target:GetInfoNum("wire_expression2_playercore_message_max_length", defaultMaxLength)
		local cumulatedLength = 0

		local array_to_send = {}

		for i, v in ipairs(send_array) do
			if type(v) == "string" then
				if string.len(v) + cumulatedLength > targetMaxLength then
					array_to_send[i] = E2Lib.limitString(v, targetMaxLength - cumulatedLength)
					break
				end
				
				cumulatedLength = cumulatedLength + string.len(v)
			elseif type(v) == "Player" then
				if string.len(v:GetName()) + cumulatedLength > targetMaxLength then
					array_to_send[i] = v
					array_to_send[i + 1] = E2Lib.limitString(" ", 0)
					break
				end
				
				cumulatedLength = cumulatedLength + string.len(v:GetName())
			end

			array_to_send[i] = v
		end

		net.Start("wire_expression2_playercore_sendmessage")
			net.WriteEntity(ply)
			net.WriteTable(array_to_send)
		net.Send(target)
	end
end

local printColor_types = {
	number = tostring,
	string = tostring,
	Vector = function(v) return Color(v[1],v[2],v[3]) end,
	table = function(tbl)
		for i,v in pairs(tbl) do
			if !isnumber(i) then return "" end
			if !isnumber(v) then return "" end
			if i < 1 or i > 4 then return "" end
		end
		return Color(tbl[1] or 0, tbl[2] or 0,tbl[3] or 0,tbl[4])
	end,
	Player = function(e) return IsValid(e) and e:IsPlayer() and e or "" end,
}

--- Sends a colored message to every player.
e2function void sendMessageColor(array arr)
	-- if not ValidPly(this) then return end
	if not hasAccess(self.player, nil, "globalmessagecolor") then self:throw("You do not have access", nil) end

	printColor(self.player, player.GetAll(), fromColorArray(arr))
end

--- Sends a colored message to every player.
e2function void sendMessageColor(...args)
	-- if not ValidPly(this) then return end
	if not hasAccess(self.player, nil, "globalmessagecolor") then self:throw("You do not have access", nil) end

	printColor(self.player, player.GetAll(), fromColorArgs(args, typeids))
end

--- Sends a colored message to a player.
e2function void entity:sendMessageColor(array arr)
	if not ValidPly(this) then return end
	if not hasAccess(self.player, this, "messagecolor") then self:throw("You do not have access", nil) end

	printColor(self.player, this, fromColorArray(arr))
end

--- Sends a colored message to a player.
e2function void entity:sendMessageColor(...args)
	if not ValidPly(this) then return end
	if not hasAccess(self.player, this, "messagecolor") then self:throw("You do not have access", nil) end

	printColor(self.player, this, fromColorArgs(args, typeids))
end

--- Sends a colored message to a list of players.
e2function void array:sendMessageColor(array arr)
	local plys = {}

	for _, ply in pairs(this) do
		if not ValidPly(ply) then continue end
		if not hasAccess(self.player, ply, "messagecolor") then self:throw("You do not have access", nil) end
	end

	for _, ply in pairs(this) do
		table.insert(plys, ply)
	end

	printColor(self.player, plys, fromColorArray(arr))
end

--- Sends a colored message to a list of players.
e2function void array:sendMessageColor(...args)
	local plys = {}

	for _, ply in pairs(this) do
		if not ValidPly(ply) then continue end
		if not hasAccess(self.player, ply, "messagecolor") then self:throw("You do not have access", nil) end
	end
	
	for _, ply in pairs(this) do
		table.insert(plys, ply)
	end

	printColor(self.player, plys, fromColorArgs(args, typeids))
end


--[[############################################]]

-- Death functions cannot be removed because of the `lastDeath` method is not implemented in the E2 core.

local registered_e2s_death = {}
local playerdeathinfo = {[1]=NULL, [2]=NULL, [3]=NULL}
local deathrun = 0

registerCallback("destruct",function(self)
		registered_e2s_death[self.entity] = nil
end)

hook.Add("PlayerDeath","Expresion2_PlayerDeath", function(victim, inflictor, attacker)
	local ents = {}

	for entity,_ in pairs(registered_e2s_death) do
		if entity:IsValid() then table.insert(ents, entity) end
	end

	deathrun = 1
	playerdeathinfo = { victim, inflictor, attacker}
	for _,entity in ipairs(ents) do
		entity:Execute()
	end
	deathrun = 0
end)

[deprecated = "Use the playerDeath event instead"]
e2function void runOnDeath(activate)
	if activate ~= 0 then
		registered_e2s_death[self.entity] = true
	else
		registered_e2s_death[self.entity] = nil
	end
end

[deprecated = "Use the playerDeath event instead"]
e2function number deathClk()
	return deathrun
end

[nodiscard, deprecated = "Use the playerDeath event instead"]
e2function entity lastDeath()
	return playerdeathinfo[1]
end

[nodiscard, deprecated = "Use the playerDeath event instead"]
e2function entity lastDeathInflictor()
	return playerdeathinfo[2]
end

[nodiscard, deprecated = "Use the playerDeath event instead"]
e2function entity lastDeathAttacker()
	return playerdeathinfo[3]
end

--[[############################################]]

-- Connect functions cannot be removed because there name does not match the E2 core.

local registered_e2s_connect = {}
local lastconnectedplayer = NULL
local connectrun = 0

registerCallback("destruct",function(self)
		registered_e2s_connect[self.entity] = nil
end)

hook.Add("PlayerInitialSpawn","Expresion2_PlayerInitialSpawn", function(ply)
	connectrun = 1
	lastconnectedplayer = ply

	for entity,_ in pairs(registered_e2s_connect) do
		if entity:IsValid() then
			entity:Execute()
		end
	end

	connectrun = 0
end)

[deprecated = "Use the playerConnected event instead"]
e2function void runOnConnect(activate)
	if activate ~= 0 then
		registered_e2s_connect[self.entity] = true
	else
		registered_e2s_connect[self.entity] = nil
	end
end

[nodiscard, deprecated = "Use the playerConnected event instead"]
e2function number connectClk()
	return connectrun
end

[nodiscard, deprecated = "Use the playerConnected event instead"]
e2function entity lastConnectedPlayer()
	return lastconnectedplayer
end

--[[############################################]]

-- Disconnect functions cannot be removed because there name does not match the E2 core.

local registered_e2s_disconnect = {}
local lastdisconnectedplayer = NULL
local disconnectrun = 0

registerCallback("destruct",function(self)
		registered_e2s_disconnect[self.entity] = nil
end)

hook.Add("PlayerDisconnected","Expresion2_PlayerDisconnected", function(ply)
	disconnectrun = 1
	lastdisconnectedplayer = ply

	for entity,_ in pairs(registered_e2s_disconnect) do
		if entity:IsValid() then
			entity:Execute()
		end
	end

	disconnectrun = 0
end)

[nodiscard, deprecated = "Use the playerDisconnected event instead"]
e2function void runOnDisconnect(activate)
	if activate ~= 0 then
		registered_e2s_disconnect[self.entity] = true
	else
		registered_e2s_disconnect[self.entity] = nil
	end
end

[nodiscard, deprecated = "Use the playerDisconnected event instead"]
e2function number disconnectClk()
	return disconnectrun
end

[nodiscard, deprecated = "Use the playerDisconnected event instead"]
e2function entity lastDisconnectedPlayer()
	return lastdisconnectedplayer
end
