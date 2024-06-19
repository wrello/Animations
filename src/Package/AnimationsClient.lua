--!strict
-- made by wrello

assert(game:GetService("RunService"):IsClient(), "Attempt to require AnimationsClient on the server")

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Types = require(script.Parent.Util.Types)
local Signal = require(script.Parent.Util.Signal)
local AnimationsClass = require(script.Parent.Util.AnimationsClass)

local player = Players.LocalPlayer

--[=[
	@interface initOptions
	@within AnimationsClient
	.AutoLoadPlayerTracks false
	.TimeToLoadPrints true
	.AnimatedObjectsDebugMode false

	Gets applied to [`Properties`](#properties).
]=]
type AnimationsClientInitOptionsType = Types.AnimationsClientInitOptionsType

--[=[
	@type path {any} | string
	@within AnimationsClient
	
	```lua
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)
	
	
	-- These are all valid options for retrieving an animation track
	local animationPath = "Jump" -- A single key (any type)
	
	local animationPath = {"Dodge", Vector3.xAxis} -- An array path (values of any type)

	local animationPath = "Climb.Right" -- A path seperated by "." (string)


	local animationTrack = Animations:GetTrack(animationPath)
	```
]=]
local Animations = AnimationsClass.new()

--[=[
	@class AnimationsClient
	@client
	
	:::note
	Roblox model path: `Animations.Package.AnimationsClient`
	:::
	
	:::info
	Any reference to "client animation tracks" is referring to animation ids found under [`rigType`](/api/AnimationIds#rigType) of **"Player"** in the [`AnimationIds`](/api/AnimationIds) module
	:::
]=]
local AnimationsClient = Animations

--[=[
	@prop AutoLoadPlayerTracks false
	@within AnimationsClient

	If set to true, client animation tracks will be loaded each time the client spawns.
	
	:::warning
	Must have animation ids under [`rigType`](/api/AnimationIds#rigType) of **"Player"** in the [`AnimationIds`](/api/AnimationIds) module.
	:::
]=]
AnimationsClient.AutoLoadPlayerTracks = false

--[=[
	@prop TimeToLoadPrints true
	@within AnimationsClient

	If set to true, prints will be made on each call to [`AnimationsClient:LoadTracks()`](#LoadTracks) to indicate the start, stop and elapsed time of pre-loading the client animation tracks.

	:::caution
	It is suggested to keep this as true because a lot of client animation tracks results in a significant yield time which is difficult to debug if forgotten.
	:::
]=]
AnimationsClient.TimeToLoadPrints = true

--[=[
	@prop AnimatedObjectsDebugMode false
	@within AnimationsClient

	If set to true, prints will be made to help debug attaching and detaching animated objects.
]=]
AnimationsClient.AnimatedObjectsDebugMode = false

--[=[
	@yields
	@param initOptions initOptions?

	Initializes `AnimationsClient`. Yields if [`AnimationsClient.AutoLoadTracks`](#AutoLoadTracks) is set to true and the player's character already exists.

	:::info
	Should be called once before any other method.
	:::
]=]
function AnimationsClient:Init(initOptions: AnimationsClientInitOptionsType?)
	if self._initialized then
		warn("AnimationsClient:Init() only needs to be called once")
		return
	end

	if initOptions then
		if initOptions.AutoLoadPlayerTracks ~= nil then
			self.AutoLoadPlayerTracks = initOptions.AutoLoadPlayerTracks
		end

		if initOptions.TimeToLoadPrints ~= nil then
			self.TimeToLoadPrints = initOptions.TimeToLoadPrints
		end

		if initOptions.AnimatedObjectsDebugMode ~= nil then
			self.AnimatedObjectsDebugMode = initOptions.AnimatedObjectsDebugMode
		end
	end

	local function initRigMethods()
		for k: string, v in pairs(AnimationsClass) do
			if type(v) == "function" and not k:match("^_") then
				local clientMethodName = k
				local rigMethodName = clientMethodName:gsub("^(%L[^%L]+)(%L[^%L]+)", "%1Rig%2")

				if clientMethodName == "LoadTracks" then
					self[clientMethodName] = function(self, ...)
						return v(self, player, "Player", ...)
					end

					self[rigMethodName] = function(self, rig, rigType, ...)
						return v(self, rig, rigType, ...)
					end
				else
					self[clientMethodName] = function(self, ...)
						return v(self, player, ...)
					end

					self[rigMethodName] = function(self, rig, ...)
						return v(self, rig, ...)
					end
				end
			end
		end
	end
	
	local function initAutoLoadPlayerTracks()
		if self.AutoLoadPlayerTracks then
			if player.Character then
				self:LoadTracks()
			end
		end

		-- TODO: Move this inside of the check above?
		player.CharacterAdded:Connect(function(char)
			if self.AutoLoadPlayerTracks then
				self:LoadTracks()
			end
		end)
	end
	
	local function initCustomRBXAnimationIdsSignal()
		local function applyCustomRBXAnimationIds()
			RunService.Stepped:Wait() -- Without a task.wait() or a RunService.Stepped:Wait(), the running animation bugs if they are moving when this function is called.
			player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Landed) -- Hack to force apply the new animations.
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

	destroyAnimationsServer()
	initCustomRBXAnimationIdsSignal()
	initRigMethods()
	
	self._initialized = true -- Need to initialize before using self:LoadTracks() in the function below
	
	initAutoLoadPlayerTracks()
end

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
	
	:::info
	Roblox applies the `"walk"` animation id for `R6` characters and the `"run"` animation id for `R15` characters (instead of both).
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
	@method ApplyCustomRBXAnimationIds
	@within AnimationsClient
	@yields
	@param humanoidRigTypeToCustomRBXAnimationIds humanoidRigTypeToCustomRBXAnimationIds
	
	Applies the animation ids specified in the [`humanoidRigTypeToCustomRBXAnimationIds`](#humanoidRigTypeToCustomRBXAnimationIds) table on the client's character. Yields if the client's character, humanoid, animator, or animate script aren't immediately available.

	```lua
	local Animations = require(game.ReplicatedStorage.Animations.Package.AnimationsClient)

	Animations:Init()

	task.wait(5)

	print("Applying r15 ninja jump & idle animations")

	-- These animations will only work if your character is R15
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
]=]

--[=[
	@method ApplyAnimationProfile
	@within AnimationsClient
	@yields
	@param animationProfileName string
	
	Applies the animation ids found in the animation profile on the client's character. Yields if the client's character, humanoid, animator, or animate script aren't immediately available.
	
	:::info
	For more information on setting up animated objects check out [animation profiles tutorial](/docs/animation-profiles).
	:::
]=]

--[=[
	@method AwaitLoaded
	@yields
	@within AnimationsClient
	
	Yields until the client animation tracks have loaded.
]=]
--[=[
	@method AwaitRigLoaded
	@yields
	@within AnimationsClient
	@param rig Model
	
	Yields until the `rig` animation tracks have loaded.
]=]

--[=[
	@method AreTracksLoaded
	@within AnimationsClient
	@return boolean
	
	Returns if the client has had its animation tracks loaded.
]=]
--[=[
	@method AreRigTracksLoaded
	@within AnimationsClient
	@param rig Model
	@return boolean
	
	Returns if the `rig` has had its animation tracks loaded.
]=]

--[=[
	@method LoadTracks
	@within AnimationsClient
	@yields
	
	Yields while client animation tracks load.

	:::tip
	Automatically gives the `rig` (the player's character) an attribute `"AnimationsRigType"` set to the [`rigType`](/api/AnimationIds#rigType) (which is "Player" in this case).
	:::
]=]
--[=[
	@method LoadRigTracks
	@within AnimationsClient
	@yields
	@param rig Model
	@param rigType string
	
	Yields while the `rig` animation tracks load.

	:::tip
	Automatically gives the `rig` an attribute `"AnimationsRigType"` set to the [`rigType`](/api/AnimationIds#rigType).
	:::
]=]

--[=[
	@method GetTrack
	@within AnimationsClient
	@param path path
	@return AnimationTrack?
	
	Returns a client animation track or nil.
]=]
--[=[
	@method GetRigTrack
	@within AnimationsClient
	@param rig Model
	@param path path
	@return AnimationTrack?
	
	Returns a `rig` animation track or nil.
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
]=]
--[=[
	@method PlayRigTrack
	@within AnimationsClient
	@param rig Model
	@param path path
	@param fadeTime number?
	@param weight number?
	@param speed number?
	@return AnimationTrack

	Returns a playing `rig` animation track.
]=]

--[=[
	@method StopTrack
	@within AnimationsClient
	@param path path
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped client animation track.
]=]
--[=[
	@method StopRigTrack
	@within AnimationsClient
	@param rig Model
	@param path path
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped `rig` animation track.
]=]

--[=[
	@method StopTracksOfPriority
	@within AnimationsClient
	@param animationPriority Enum.AnimationPriority
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped client animation tracks.
]=]
--[=[
	@method StopRigTracksOfPriority
	@within AnimationsClient
	@param rig Model
	@param animationPriority Enum.AnimationPriority
	@param fadeTime number?
	@return {AnimationTrack?}

	Returns the stopped `rig` animation tracks.
]=]

--[=[
	@method GetTrackFromAlias
	@within AnimationsClient
	@param alias any
	@return AnimationTrack?

	Returns a client animation track or nil.
]=]
--[=[
	@method GetRigTrackFromAlias
	@within AnimationsClient
	@param rig Model
	@param alias any
	@return AnimationTrack?

	Returns a `rig` animation track or nil.
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
]=]
--[=[
	@method PlayRigTrackFromAlias
	@within AnimationsClient
	@param rig Model
	@param alias any
	@param fadeTime number?
	@param weight number?
	@param speed number?
	@return AnimationTrack

	Returns a playing `rig` animation track.
]=]

--[=[
	@method StopTrackFromAlias
	@within AnimationsClient
	@param alias any
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped client animation track.
]=]
--[=[
	@method StopRigTrackFromAlias
	@within AnimationsClient
	@param rig Model
	@param alias any
	@param fadeTime number?
	@return AnimationTrack

	Returns a stopped `rig` animation track.
]=]

--[=[
	@method SetTrackAlias
	@within AnimationsClient
	@param alias any
	@param path path

	Sets an alias to be the equivalent of the path for a client animation track.

	:::tip
	You can use the alias as the last key in the path. Useful for a table of animations. Example:

	```lua
	-- In ReplicatedStorage.Animations.Deps.AnimationIds
	local animationIds = {
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
	```

	```lua
	-- In a LocalScript

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
	@method SetRigTrackAlias
	@within AnimationsClient
	@param rig Model
	@param alias any
	@param path path

	Sets an alias to be the equivalent of the path for a `rig` animation track.

	:::tip
	Same tip for [`Animations:SetTrackAlias()`](#SetTrackAlias) applies here.
	:::
]=]

--[=[
	@method RemoveTrackAlias
	@within AnimationsClient
	@param alias any

	Removes the alias for a client animation track.
]=]
--[=[
	@method RemoveRigTrackAlias
	@within AnimationsClient
	@param rig Model
	@param alias any

	Removes the alias for a `rig` animation track.
]=]

--[=[
	@tag Beta
	@method AttachAnimatedObject
	@within AnimationsClient
	@param animatedObjectSourcePath_or_animationTrack_or_animatedObject path | AnimationTrack | Instance

	Attaches the animated object to the client's character.

	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
]=]
--[=[
	@tag Beta
	@method AttachRigAnimatedObject
	@within AnimationsClient
	@param rig Model
	@param animatedObjectSourcePath_or_animationTrack_or_animatedObject path | AnimationTrack | Instance

	Attaches the animated object to the `rig`.

	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
]=]

--[=[
	@tag Beta
	@method DetachAnimatedObject
	@within AnimationsClient
	@param animatedObjectSourcePath_or_animationTrack_or_animatedObject path | AnimationTrack | Instance

	Detaches the animated object from the client's character.

	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
]=]
--[=[
	@tag Beta
	@method DetachRigAnimatedObject
	@within AnimationsClient
	@param rig Model
	@param animatedObjectSourcePath_or_animationTrack_or_animatedObject path | AnimationTrack | Instance

	Detaches the animated object from the `rig`.

	:::info
	For more information on setting up animated objects check out [animated objects tutorial](/docs/animated-objects).
	:::
]=]

return AnimationsClient :: Types.AnimationsClientType