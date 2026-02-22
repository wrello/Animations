--!strict
-- made by wrello
-- GitHub: https://github.com/wrello/Animations

assert(game:GetService("RunService"):IsClient(), "Attempt to require AnimationsClient on the server")

local Players = game:GetService("Players")

local Types = require(script.Parent.Util.Types)
local Signal = require(script.Parent.Util.Signal)
local AnimationsClass = require(script.Parent.Util.AnimationsClass)
local ChildFromPath = require(script.Parent.Util.ChildFromPath)

local player = Players.LocalPlayer

--[=[
	@interface initOptions
	@within AnimationsClient
	.AutoLoadAllPlayerTracks false
	.AutoRegisterPlayer true
	.BootstrapDepsFolder Folder?
	.TimeToLoadPrints true

	For more info, see [`Properties`](/api/AnimationsClient/#properties).
]=]
type AnimationsClientInitOptionsType = Types.AnimationsClientInitOptionsType

--[=[
	@type path {any} | string
	@within AnimationsClient

	These are all valid forms of paths to animation tracks you have defined in the [`AnimationIds`](/api/AnimationIds) module:

	```lua
	local path = "Jump" -- A single key (any type)

	local path = {"Dodge", Vector3.xAxis} -- An array path (values of any type)

	local path = "Climb.Right" -- A string path separated by "."

	Animations:PlayTrack(path)
	```
]=]
local Animations = AnimationsClass.new(script.Name)

--[=[
	@class AnimationsClient
	@client

	:::note
	Roblox model path: `Animations\Package\AnimationsClient`
	:::
]=]
local AnimationsClient = Animations

--[=[
	@prop AutoLoadAllPlayerTracks false
	@within AnimationsClient

	If set to true, client animation tracks will be loaded each time the client spawns.
]=]
AnimationsClient.AutoLoadAllPlayerTracks = false

--[=[
	@prop AutoRegisterPlayer true
	@within AnimationsClient

	If set to true, the client will be auto registered with [`rigType`](/api/AnimationIds#rigType) of `"Player"` each time they spawn.
]=]
AnimationsClient.AutoRegisterPlayer = true

--[=[
	@prop BootstrapDepsFolder Folder?
	@within AnimationsClient

	Set this to the dependencies folder if you have moved it from its original location inside of the root `Animations` folder.
]=]
AnimationsClient.BootstrapDepsFolder = nil

--[=[
	@prop TimeToLoadPrints true
	@within AnimationsClient

	If set to true, makes helpful prints about the time it takes to pre-load and load animations.
]=]
AnimationsClient.TimeToLoadPrints = true

--[=[
	@yields
	@param initOptions initOptions?

	Initializes `AnimationsClient`.

	Yields when...
	- ...server has not initialized.
	- ...animations are being pre-loaded with `ContentProvider:PreloadAsync()` (could take a while).

	:::caution important
	Must be called once before any other method.
	:::
]=]
function AnimationsClient:Init(initOptions: AnimationsClientInitOptionsType?)
	if self._initialized then
		warn("AnimationsClient:Init() only needs to be called once")
		return
	end

	local function bootstrapDepsFolder()
		local depsFolder

		if self.BootstrapDepsFolder then
			depsFolder = self.BootstrapDepsFolder
		else
			depsFolder = script.Parent.Parent.Deps
		end

		self:_bootstrapDepsFolder(depsFolder)
	end

	local function awaitServerInitialized()
		local serverInitialized = script.Parent.AnimationsServer:GetAttribute("InitializedForClients")
		if not serverInitialized then
			task.delay(3, function()
				if not serverInitialized then
					warn("Infinite yield possible waiting for AnimationsServer:Init()")
				end
			end)

			script.Parent.AnimationsServer:GetAttributeChangedSignal("InitializedForClients"):Wait()

			serverInitialized = true
		end
	end

	local function initInitOptions()
		if initOptions then
			for k, v in pairs(initOptions) do
				self[k] = v
			end
		end
	end

	local function initMethods()
		local manualRigMethodNames = {
			["AreAllTracksLoaded"] = "AreAllRigTracksLoaded",
			["LoadAllTracks"] = "LoadAllRigTracks",
			["AwaitAllTracksLoaded"] = "AwaitAllRigTracksLoaded",
			["AttachWithMotor6d"] = "AttachToRigWithMotor6d",
			["WaitForRightGripWeld"] = "WaitForRigRightGripWeld"
		}

		local noAlternative = {"GetAnimationProfile", "AwaitPreloadAsyncFinished", "FindFirstRigPlayingTrack", "WaitForRigPlayingTrack", "GetTimeOfMarker", "GetAnimationIdString"}

		for k: string, v in pairs(AnimationsClass) do
			if type(v) == "function" and not k:match("^_") and not table.find(noAlternative, k) then
				local clientMethodName = k
				local rigMethodName = manualRigMethodNames[clientMethodName] or clientMethodName:gsub("^(%L[^%L]+)(%L?[^%L]*)", "%1Rig%2")

				self[clientMethodName] = function(self, ...)
					return v(self, player, ...)
				end

				self[rigMethodName] = function(self, rig, ...)
					return v(self, rig, ...)
				end
			end
		end
	end

	local function initOnPlayerSpawn()
		local function onCharacterAdded(char)
			if self.AutoRegisterPlayer then
				print("registering")
				self:Register("Player")
			end

			if self.AutoLoadAllPlayerTracks then
				self:LoadAllTracks()
			end
		end

		if player.Character then
			onCharacterAdded(player.Character)
		end

		player.CharacterAdded:Connect(onCharacterAdded)
	end

	local function initCustomRBXAnimationIdsSignal()
		local function applyCustomRBXAnimationIds(humRigTypeCustomRBXAnimationIds)
			local hum = nil

			if humRigTypeCustomRBXAnimationIds then
				local char = player.Character or player.CharacterAdded:Wait()
				local animator = char:WaitForChild("Humanoid"):WaitForChild("Animator")
				local animateScript = char:WaitForChild("Animate")

				self:_editAnimateScriptValues(animator, animateScript, humRigTypeCustomRBXAnimationIds)
			end

			local char = player.Character
			hum = char:FindFirstChild("Humanoid")

			if hum then
				-- Here we have to hack the state system to force apply the new
				-- animation ids if we don't want to modify the 'Animate' script
				if hum:GetState() == Enum.HumanoidStateType.Freefall then -- Can't change to 'Landed' mid-air because it will freeze the character
					hum:ChangeState(Enum.HumanoidStateType.Running)
				else
					hum:ChangeState(Enum.HumanoidStateType.Landed)
				end
			end
		end

		self.ApplyCustomRBXAnimationIdsSignal = Signal.new()

		local signals = {self.ApplyCustomRBXAnimationIdsSignal, script.Parent:WaitForChild("ApplyCustomRBXAnimationIds").OnClientEvent}

		for _, signal in ipairs(signals) do
			signal:Connect(applyCustomRBXAnimationIds)
		end
	end

	local function destroyAnimationsServer()
		script.Parent.AnimationsServer:Destroy()
	end

	awaitServerInitialized()
	initInitOptions()
	bootstrapDepsFolder()
	self:_animationIdsToInstances()
	destroyAnimationsServer()
	initCustomRBXAnimationIdsSignal()
	initMethods()
	self._initialized = true -- Need to initialize before using methods in the function below
	initOnPlayerSpawn()
end

--[=[
	@method GetTrackStartSpeed
	@within AnimationsClient
	@param path path
	@return number?

	If set with [`HasProperties`](/api/AnimationIds#HasProperties), returns the animation track's `StartSpeed`.

	*Rig version - `:GetRigTrackStartSpeed()`*
]=]

--[=[
	@method GetTimeOfMarker
	@within AnimationsClient
	@param animTrack_or_IdString AnimationTrack | string
	@param markerName string
	@return number?

	This method can yield if the
	initialization process that caches all of the marker
	times is still going on when this method is called. If
	after 3 seconds the initialization process has still not
	finished, this method will return `nil`.
	
	:::warning
	This method only works on animations which you give
	the [`MarkerTimes`](api/AnimationIds#propertiesSettings) property to.
	:::

	```lua
	local attackAnim = Animations:PlayTrack("Attack")
	local timeOfHitStart = Animations:GetTimeOfMarker(attackAnim, "HitStart")

	print("Time of hit start:", timeOfHitStart)

	-- or

	local animIdStr = Animations:GetAnimationIdString("Player", "Attack")
	local timeOfHitStart = Animations:GetTimeOfMarker(animIdStr, "HitStart")

	print("Time of hit start:", timeOfHitStart)
	```
]=]
--[=[
	@method GetAnimationIdString
	@within AnimationsClient
	@param rigType rigType
	@param path path
	@return string

	Returns the animation id string under `rigType` at `path` in the [`AnimationIds`](/api/AnimationIds) module.

	```lua
	local animIdStr = Animations:GetAnimationIdString("Player", "Run")
	print(animIdStr) --> "rbxassetid://89327320"
	```
]=]

--[=[
	@method FindFirstRigPlayingTrack 
	@within AnimationsClient 
	@param rig Model
	@param path path
	@return AnimationTrack?

	Returns a playing animation track found in
	`rig.Humanoid.Animator:GetPlayingAnimationTracks()`
	matching the animation id found at `path` in the
	[`AnimationIds`](/api/AnimationIds) module or `nil`.

	:::warning
	For this to work, `rig` needs to be registered.
	:::

	```lua
	local isBlocking = Animations:FindFirstRigPlayingTrack(rig, "Blocking")

	if isBlocking then
		warn("We can't hit the enemy, they're blocking!")
	end
	```
]=]
--[=[
	@yields
	@method WaitForRigPlayingTrack
	@within AnimationsClient
	@param rig Model
	@param path path
	@param timeout number?
	@return AnimationTrack?

	Yields until a playing animation track is found in
	`rig.Humanoid.Animator:GetPlayingAnimationTracks()`
	matching the animation id found at `path` in the
	[`AnimationIds`](/api/AnimationIds) module then returns it or returns `nil` after
	`timeout` seconds if provided.

	Especially useful if the animation needs time to replicate from server to client and you want to specify a maximum time to wait until it replicates.

	:::warning
	For this to work, `rig` needs to be registered.
	:::

	```lua
	local isBlocking = Animations:WaitForRigPlayingTrack(rig, "Blocking", 1)

	if isBlocking then
		warn("We can't hit the enemy, they're blocking!")
	end
	```
]=]

--[=[
	@method GetAppliedProfileName
	@within AnimationsClient
	@return string?

	Returns the client's currently applied animation profile name or `nil`.

	*Rig version - `:GetRigAppliedProfileName()`*
]=]

--[=[
	@method AwaitPreloadAsyncFinished
	@yields
	@within AnimationsClient
	@return {Animation?}

	Yields until `ContentProvider:PreloadAsync()` finishes pre-loading all animation instances.

	```lua
	local loadedAnimInstances = Animations:AwaitPreloadAsyncFinished()
		
	print("ContentProvider:PreloadAsync() finished pre-loading all animations:", loadedAnimInstances)
	```
]=]
--[=[
	@prop PreloadAsyncProgressed RBXScriptSignal
	@within AnimationsClient

	Fires when `ContentProvider:PreloadAsync()` finishes pre-loading one animation instance.

	```lua
	Animations.PreloadAsyncProgressed:Connect(function(n, total, loadedAnimInstance)
		print("ContentProvider:PreloadAsync() finished pre-loading one animation:", n, total, loadedAnimInstance)
	end)
	```
]=]

--[=[
	@interface customRBXAnimationIds
	@within AnimationsClient
	.run number?
	.walk number?
	.jump number?
	.idle {Animation1: number?, Animation2: number?}?
	.fall number?
	.swim number?
	.swimIdle number?
	.climb number?

	A table of animation ids to replace the default roblox animation ids.

	:::note
	The `"walk"` animation is used for both walking and running on `R6` characters.
	:::
]=]

--[=[
	@interface humanoidRigTypeToCustomRBXAnimationIds
	@within AnimationsClient
	.[Enum.HumanoidRigType.R6] customRBXAnimationIds?
	.[Enum.HumanoidRigType.R15] customRBXAnimationIds?

	A table mapping a `Enum.HumanoidRigType` to its supported animation ids that will replace the default roblox animation ids.
]=]

--[=[
	@method Register
	@within AnimationsClient

	Registers the client's character so that methods using animation tracks can be called.

	:::note rig version
	`:RegisterRig()`
	:::tip
	Automatically calls `rig:SetAttribute("AnimationsRigType", rigType)` which is useful for determining rig types.
	:::
]=]

--[=[
	@method AwaitRegistered
	@yields
	@within AnimationsClient

	Yields until the client gets registered.

	*Rig version - `:AwaitRigRegistered()`*
]=]

--[=[
	@method IsRegistered
	@within AnimationsClient
	@return boolean

	Returns `true` if the client is registered.

	*Rig version - `:IsRigRegistered()`*
]=]

--[=[
	@method ApplyCustomRBXAnimationIds
	@within AnimationsClient
	@yields
	@param humanoidRigTypeToCustomRBXAnimationIds humanoidRigTypeToCustomRBXAnimationIds

	Applies the animation ids specified in the [`humanoidRigTypeToCustomRBXAnimationIds`](#humanoidRigTypeToCustomRBXAnimationIds) table on the client's character.

	Yields when...
	- ...the client's character, humanoid, animator, or animate script aren't immediately available.

	```lua
	Animations:ApplyCustomRBXAnimationIds({
		[Enum.HumanoidRigType.R15] = {
			jump = 656117878,
			idle = {
				Animation1 = 656117400,
				Animation2 = 656118341
			}
		}
	})
	```

	:::note rig version
	`:ApplyRigCustomRBXAnimationIds()`
	:::warning
	Only works for `R6`/`R15` rigs that are local to the client or network-owned by the client and have a client-side `"Animate"` script in their model.
	:::
]=]

--[=[
	@method GetAnimationProfile
	@within AnimationsClient
	@param animationProfileName string
	@return animationProfile humanoidRigTypeToCustomRBXAnimationIds?

	Returns the [`humanoidRigTypeToCustomRBXAnimationIds`](#humanoidRigTypeToCustomRBXAnimationIds) table from the animation profile module or `nil`.

	:::info
	For more info, see [animation profiles](/docs/animation-profiles).
	:::
]=]

--[=[
	@method ApplyAnimationProfile
	@within AnimationsClient
	@yields
	@param animationProfileName string

	Applies the animation ids found in the animation profile on the client's character.

	Yields when...
	- ...the client's character, humanoid, animator, or animate script aren't immediately available.

	:::info
	For more info, see [animation profiles](/docs/animation-profiles).
	:::

	:::note rig version
	`:ApplyRigAnimationProfile()`
	:::warning
	Only works for `R6`/`R15` rigs that are local to the client or network-owned by the client and have a client-side `"Animate"` script in their model.
	:::
]=]

--[=[
	@method AwaitAllTracksLoaded
	@yields
	@within AnimationsClient

	Yields until the client has been registered and then until all animation tracks have loaded.

	*Rig version - `:AwaitAllRigTracksLoaded()`*
]=]

--[=[
	@method AwaitTracksLoadedAt
	@yields
	@within AnimationsClient
	@param path path

	Yields until the client has been registered and then until all animation tracks have loaded at `path`.

	*Rig version - `:AwaitRigTracksLoadedAt()`*
]=]

--[=[
	@method AreAllTracksLoaded
	@within AnimationsClient
	@return boolean

	Returns `true` if the client has had all its animation tracks loaded.

	*Rig version - `:AreAllRigTracksLoaded()`*
]=]

--[=[
	@method AreTracksLoadedAt
	@within AnimationsClient
	@param path path
	@return boolean

	Returns `true` if the client has had its animation tracks loaded at `path`.

	*Rig version - `:AreRigTracksLoadedAt()`*
]=]

--[=[
	@yields
	@method LoadAllTracks
	@within AnimationsClient

	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the client.

	Yields when...
	- ...client's animator is not a descendant of `game`.

	*Rig version - `:LoadAllRigTracks()`*
]=]

--[=[
	@yields
	@method LoadTracksAt
	@within AnimationsClient
	@param path path

	Creates animation tracks from all animation ids in [`AnimationIds`](/api/AnimationIds) for the client at `path`.

	Yields when...
	- ...client's animator is not a descendant of `game`.

	*Rig version - `:LoadRigTracksAt()`*
]=]

--[=[
	@method GetTrack
	@within AnimationsClient
	@param path path
	@return AnimationTrack?

	Returns a client animation track or `nil`.

	*Rig version - `:GetRigTrack()`*
]=]

--[=[
	@method PlayTrack
	@within AnimationsClient
	@param path path
	@param fadeTime number?
	@param weight number?
	@param speed number?
	@return AnimationTrack

	Returns a playing client animation track.

	:::note rig version
	`:PlayRigTrack()`

	```lua
	Animations:RegisterRig(rig, "Monster") -- In order to use "Monster" animations (in AnimationIds) on this rig
	
	Animations:LoadAllRigTracks(rig)
	Animations:PlayRigTrack(rig, "Run")
	```
	:::
]=]

--[=[
	@method StopTrack
	@within AnimationsClient
	@param path path
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped client animation track.

	*Rig version - `:StopRigTrack()`*
]=]

--[=[
	@method StopPlayingTracks
	@within AnimationsClient
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped client animation tracks.

	*Rig version - `:StopRigPlayingTracks()`*
]=]

--[=[
	@method GetPlayingTracks
	@within AnimationsClient
	@return {AnimationTrack?}

	Returns the playing client animation tracks.

	*Rig version - `:GetRigPlayingTracks()`*
]=]

--[=[
	@method StopTracksOfPriority
	@within AnimationsClient
	@param animationPriority Enum.AnimationPriority
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped client animation tracks.

	*Rig version - `:StopRigTracksOfPriority()`*
]=]

--[=[
	@method GetTrackFromAlias
	@within AnimationsClient
	@param alias any
	@return AnimationTrack?

	Returns a client animation track or `nil`.

	*Rig version - `:GetRigTrackFromAlias()`*
]=]

--[=[
	@method PlayTrackFromAlias
	@within AnimationsClient
	@param alias any
	@param fadeTime number?
	@param weight number?
	@param speed number?
	@return AnimationTrack

	Returns a playing client animation track.

	*Rig version - `:PlayRigTrackFromAlias()`*
]=]

--[=[
	@method StopTrackFromAlias
	@within AnimationsClient
	@param alias any
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped client animation track.
	
	*Rig version - `:StopRigTrackFromAlias()`*
]=]

--[=[
	@method SetTrackAlias
	@within AnimationsClient
	@param alias any
	@param path path

	Sets an alias to be the equivalent of the path for a client animation track.

	*Rig version - `:SetRigTrackAlias()`*

	:::tip
	You can use the alias as the last key in the path. Useful for a table of animations. Example:

	```lua
	local AnimationIds = {
		Player = {
			FistsCombat = {
				-- Fists 3 hit combo
				Combo = {
					[1] = 1234567,
					[2] = 1234567,
					[3] = 1234567
				},

				-- Fists heavy attack
				HeavyAttack = 1234567
			},

			SwordCombat = {
				-- Sword 3 hit combo
				Combo = {
					[1] = 1234567,
					[2] = 1234567,
					[3] = 1234567
				},

				-- Sword heavy attack
				HeavyAttack = 1234567
			}
		}
	}

	return AnimationIds
	```

	```lua
	-- After the client's animation tracks are loaded...

	local heavyAttackAlias = "HeavyAttack" -- We want this alias in order to call Animations:PlayTrackFromAlias(heavyAttackAlias) regardless what weapon is equipped

	local currentEquippedWeapon

	local function updateHeavyAttackAliasPath()
		local alias = heavyAttackAlias
		local path = currentEquippedWeapon .. "Combat"

		Animations:SetTrackAlias(alias, path) -- Running this will search first "path.alias" and then search "path" if it didn't find "path.alias"
	end

	local function equipNewWeapon(weaponName)
		currentEquippedWeapon = weaponName

		updateHeavyAttackAliasPath()
	end

	equipNewWeapon("Fists")

	Animations:PlayTrackFromAlias(heavyAttackAlias) -- Plays "FistsCombat.HeavyAttack" on the client's character

	equipNewWeapon("Sword")

	Animations:PlayTrackFromAlias(heavyAttackAlias) -- Plays "SwordCombat.HeavyAttack" on the client's character
	```
	:::
]=]

--[=[
	@method RemoveTrackAlias
	@within AnimationsClient
	@param alias any

	Removes the alias for a client animation track.

	*Rig version - `:RemoveRigTrackAlias()`*
]=]

--[=[
	@method AttachWithMotor6d
	@within AnimationsClient
	@param model Model | Tool
	@param motor6dToClone Motor6D?

	Attaches the `model` to the client's character using the `motor6dToClone` or the first `motor6d` found as a child of the `model` in order to animate it.

	In either case, the `motor6d` used must have the following attributes set:
	- `"Part0Name"` - the name of the `Part0` of the `motor6d` during the animation.
	- `"Part1Name"` - the name of the `Part1` of the `motor6d` during the animation.

	*Rig version - `:AttachToRigWithMotor6d()`*
]=]

--[=[
	@method SetRightGripWeldEnabled
	@within AnimationsClient
	@param isEnabled boolean

	Enables/disables the `RightGrip` weld that is automatically added to a character's right hand when a tool is equipped.

	*Rig version - `:SetRigRightGripWeldEnabled()`*
]=]

--[=[
	@method FindRightGripWeld
	@within AnimationsClient
	@return Weld?

	Returns the `RightGrip` weld that is automatically added to a character's right hand when a tool is equipped or `nil`.

	*Rig version - `:FindRigRightGripWeld()`*
]=]

--[=[
	@yields
	@method WaitForRightGripWeld
	@within AnimationsClient
	@return Weld

	Yields until the `RightGrip` weld that is automatically added to a character's right hand when a tool is equipped is found and then returns it.

	*Rig version - `:WaitForRigRightGripWeld()`*
]=]

return AnimationsClient :: Types.AnimationsClientType