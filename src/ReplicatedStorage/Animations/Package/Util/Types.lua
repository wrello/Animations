--!strict

type EventType<T> = {
	Wait: (self: EventType<T>) -> (...any),
	Connect: (self: EventType<T>, handler: T) -> RBXScriptConnection,
	Once: (self: EventType<T>, handler: T) -> RBXScriptConnection,
}

export type RanFullMethodType = boolean -- Will be false if the method returned instantly

export type AnimationsServerType = {
	PreloadAsyncProgressed: EventType<(n: number, total: number, loadedAnimInstance: Animation) -> ()>,

	Init: (self: AnimationsServerType, initOptions: AnimationsServerInitOptionsType?) -> (),

	AwaitPreloadAsyncFinished: (self: AnimationsServerType) -> {Animation?} | RanFullMethodType,

	GetTrackStartSpeed: (self: AnimationsServerType, player_or_rig: Player | Model, path: {any} | string) -> number?,

	LoadTracksAt: (self: AnimationsServerType, player_or_rig: Player | Model, path: {any} | string) -> RanFullMethodType,
	LoadAllTracks: (self: AnimationsServerType, player_or_rig: Player | Model) -> RanFullMethodType,

	AreTracksLoadedAt: (self: AnimationsServerType, player_or_rig: Player | Model, path: {any} | string) -> boolean,
	AreAllTracksLoaded: (self: AnimationsServerType, player_or_rig: Player | Model) -> boolean,

	AwaitTracksLoadedAt: (self: AnimationsServerType, player_or_rig: Player | Model, path: {any} | string) -> RanFullMethodType,
	AwaitAllTracksLoaded: (self: AnimationsServerType, player_or_rig: Player | Model) -> RanFullMethodType,

	Register: (self: AnimationsServerType, player_or_rig: Player | Model, rigType: string) -> (),
	AwaitRegistered: (self: AnimationsServerType, player_or_rig: Player | Model) -> RanFullMethodType,
	IsRegistered: (self: AnimationsServerType, player_or_rig: Player | Model) -> boolean,

	GetTrack: (self: AnimationsServerType, player_or_rig: Player | Model, path: {any} | string) -> AnimationTrack?,
	PlayTrack: (self: AnimationsServerType, player_or_rig: Player | Model, path: {any} | string, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,
	StopTrack: (self: AnimationsServerType, player_or_rig: Player | Model, path: {any} | string, fadeTime: number?) -> AnimationTrack,

	FindFirstRigPlayingTrack: (self: AnimationsServerType, rig: Model, path: {any} | string) -> AnimationTrack?,
	WaitForRigPlayingTrack: (self: AnimationsServerType, rig: Model, path: {any} | string, timeout: number?) -> AnimationTrack?,

	GetTimeOfMarker: (self: AnimationsServerType, animTrack_or_IdString: AnimationTrack | string, markerName: string) -> number?,
	GetAnimationIdString: (self: AnimationsServerType, rigType: string, path: {any} | string) -> string,

	StopPlayingTracks: (self: AnimationsServerType, player_or_rig: Player | Model, fadeTime: number?) -> {AnimationTrack?},
	GetPlayingTracks: (self: AnimationsServerType, player_or_rig: Player | Model) -> {AnimationTrack?},
	StopTracksOfPriority: (self: AnimationsServerType, player_or_rig: Player | Model, animationPriority: Enum.AnimationPriority, fadeTime: number?) -> {AnimationTrack?},

	GetTrackFromAlias: (self: AnimationsServerType, player_or_rig: Player | Model, alias: any) -> AnimationTrack?,
	PlayTrackFromAlias: (self: AnimationsServerType, player_or_rig: Player | Model, alias: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,
	StopTrackFromAlias: (self: AnimationsServerType, player_or_rig: Player | Model, alias: any, fadeTime: number?) -> AnimationTrack,
	
	SetTrackAlias: (self: AnimationsServerType, player_or_rig: Player | Model, alias: any, path: {any} | string) -> (),
	RemoveTrackAlias: (self: AnimationsServerType, player_or_rig: Player | Model, alias: any) -> (),

	AttachWithMotor6d: (self: AnimationsServerType, player_or_rig: Player | Model, model: Model | Tool, motor6dToClone: Motor6D?) -> (),

	SetRightGripWeldEnabled: (self: AnimationsServerType, player_or_rig: Player | Model, isEnabled: boolean) -> (),
	WaitForRightGripWeld: (self: AnimationsServerType, player_or_rig: Player | Model) -> Weld,
	FindRightGripWeld: (self: AnimationsServerType, player_or_rig: Player | Model) -> Weld?,

	ApplyCustomRBXAnimationIds: (self: AnimationsServerType, player_or_rig: Player | Model, humanoidRigTypeToCustomRBXAnimationIds: HumanoidRigTypeToCustomRBXAnimationIdsType) -> (),

	GetAppliedProfileName: (self: AnimationsServerType, player_or_rig: Player | Model) -> string?,
	GetAnimationProfile: (self: AnimationsServerType, animationProfileName: string) -> HumanoidRigTypeToCustomRBXAnimationIdsType?,
	ApplyAnimationProfile: (self: AnimationsServerType, player_or_rig: Player | Model, animationProfileName: string) -> ()
} & AnimationsServerInitOptionsType
export type AnimationsClientType = {
	PreloadAsyncProgressed: EventType<(n: number, total: number, loadedAnimInstance: Animation) -> ()>,

	Init: (self: AnimationsClientType, initOptions: AnimationsClientInitOptionsType?) -> (),

	AwaitPreloadAsyncFinished: (self: AnimationsClientType) -> {Animation?} | RanFullMethodType,

	GetTrackStartSpeed: (self: AnimationsClientType, path: {any} | string) -> number?,
	GetRigTrackStartSpeed: (self: AnimationsClientType, rig: Model, path: {any} | string) -> number?,

	AreTracksLoadedAt: (self: AnimationsClientType, path: {any} | string) -> boolean,
	AreRigTracksLoadedAt: (self: AnimationsClientType, rig: Model, path: {any} | string) -> boolean,
	
	AreAllTracksLoaded: (self: AnimationsClientType) -> boolean,
	AreAllRigTracksLoaded: (self: AnimationsClientType, rig: Model) -> boolean,

	LoadTracksAt: (self: AnimationsClientType, path: {any} | string) -> RanFullMethodType,
	LoadRigTracksAt: (self: AnimationsClientType, rig: Model, path: {any} | string) -> RanFullMethodType,

	LoadAllTracks: (self: AnimationsClientType) -> RanFullMethodType,
	LoadAllRigTracks: (self: AnimationsClientType, rig: Model) -> RanFullMethodType,

	AwaitTracksLoadedAt: (self: AnimationsClientType, path: {any} | string) -> RanFullMethodType,
	AwaitRigTracksLoadedAt: (self: AnimationsClientType, rig: Model, path: {any} | string) -> RanFullMethodType,

	AwaitAllTracksLoaded: (self: AnimationsClientType) -> RanFullMethodType,
	AwaitAllRigTracksLoaded: (self: AnimationsClientType, rig: Model) -> RanFullMethodType,

	Register: (self: AnimationsClientType) -> (),
	RegisterRig: (self: AnimationsClientType, rig: Model, rigType: string) -> (),
	
	AwaitRegistered: (self: AnimationsClientType) -> RanFullMethodType,
	AwaitRigRegistered: (self: AnimationsClientType, rig: Model) -> RanFullMethodType,

	IsRegistered: (self: AnimationsClientType) -> boolean,
	IsRigRegistered: (self: AnimationsClientType, rig: Model) -> boolean,

	GetTrack: (self: AnimationsClientType, path: {any} | string) -> AnimationTrack?,
	GetRigTrack: (self: AnimationsClientType, rig: Model, path: {any} | string) -> AnimationTrack?,

	PlayTrack: (self: AnimationsClientType, path: {any} | string, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,
	PlayRigTrack: (self: AnimationsClientType, rig: Model, path: {any} | string, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,

	StopTrack: (self: AnimationsClientType, path: {any} | string, fadeTime: number?) -> AnimationTrack,
	StopRigTrack: (self: AnimationsClientType, rig: Model, path: {any} | string, fadeTime: number?) -> AnimationTrack,

	StopPlayingTracks: (self: AnimationsClientType, fadeTime: number?) -> {AnimationTrack?},
	StopRigPlayingTracks: (self: AnimationsClientType, rig: Model, fadeTime: number?) -> {AnimationTrack?},

	FindFirstRigPlayingTrack: (self: AnimationsClientType, rig: Model, path: {any} | string) -> AnimationTrack?,
	WaitForRigPlayingTrack: (self: AnimationsClientType, rig: Model, path: {any} | string, timeout: number?) -> AnimationTrack?,

	GetPlayingTracks: (self: AnimationsClientType) -> {AnimationTrack?},
	GetRigPlayingTracks: (self: AnimationsClientType, rig: Model) -> {AnimationTrack?},

	StopTracksOfPriority: (self: AnimationsClientType, animationPriority: Enum.AnimationPriority, fadeTime: number?) -> {AnimationTrack?},
	StopRigTracksOfPriority: (self: AnimationsClientType, rig: Model, animationPriority: Enum.AnimationPriority, fadeTime: number?) -> {AnimationTrack?},

	GetTrackFromAlias: (self: AnimationsClientType, alias: any) -> AnimationTrack?,
	GetRigTrackFromAlias: (self: AnimationsClientType, rig: Model, alias: any) -> AnimationTrack?,

	PlayTrackFromAlias: (self: AnimationsClientType, alias: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,
	PlayRigTrackFromAlias: (self: AnimationsClientType, rig: Model, alias: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,

	GetTimeOfMarker: (self: AnimationsClientType, animTrack_or_IdString: AnimationTrack | string, markerName: string) -> number?,
	GetAnimationIdString: (self: AnimationsClientType, rigType: string, path: {any} | string) -> string,

	StopTrackFromAlias: (self: AnimationsClientType, alias: any, fadeTime: number?) -> AnimationTrack,
	StopRigTrackFromAlias: (self: AnimationsClientType, rig: Model, alias: any, fadeTime: number?) -> AnimationTrack,

	SetTrackAlias: (self: AnimationsClientType, alias: any, path: {any} | string) -> (),
	SetRigTrackAlias: (self: AnimationsClientType, rig: Model, alias: any, path: {any} | string) -> (),

	RemoveTrackAlias: (self: AnimationsClientType, alias: any) -> (),
	RemoveRigTrackAlias: (self: AnimationsClientType, rig: Model, alias: any) -> (),

	AttachWithMotor6d: (self: AnimationsClientType, model: Model | Tool, motor6dToClone: Motor6D?) -> (),
	AttachToRigWithMotor6d: (self: AnimationsClientType, rig: Model, model: Model | Tool, motor6dToClone: Motor6D?) -> (),

	SetRightGripWeldEnabled: (self: AnimationsClientType, isEnabled: boolean) -> (),
	WaitForRightGripWeld: (self: AnimationsClientType) -> Weld,
	FindRightGripWeld: (self: AnimationsClientType) -> Weld?,

	SetRigRightGripWeldEnabled: (self: AnimationsClientType, rig: Model, isEnabled: boolean) -> (),
	WaitForRigRightGripWeld: (self: AnimationsClientType, rig: Model) -> Weld,
	FindRigRightGripWeld: (self: AnimationsClientType, rig: Model) -> Weld?,

	ApplyCustomRBXAnimationIds: (self: AnimationsClientType, humanoidRigTypeToCustomRBXAnimationIds: HumanoidRigTypeToCustomRBXAnimationIdsType) -> (),
	ApplyRigCustomRBXAnimationIds: (self: AnimationsClientType, rig: Model, humanoidRigTypeToCustomRBXAnimationIds: HumanoidRigTypeToCustomRBXAnimationIdsType) -> (),

	GetAppliedProfileName: (self: AnimationsClientType) -> string?,
	GetRigAppliedProfileName: (self: AnimationsClientType, rig: Model) -> string?,

	GetAnimationProfile: (self: AnimationsClientType, animationProfileName: string) -> HumanoidRigTypeToCustomRBXAnimationIdsType?,

	ApplyAnimationProfile: (self: AnimationsClientType, animationProfileName: string) -> (),
	ApplyRigAnimationProfile: (self: AnimationsClientType, rig: Model, animationProfileName: string) -> (),
} & AnimationsClientInitOptionsType

export type CustomRBXAnimationIdsType = {
	run: number?,
	walk: number?,
	jump: number?,
	idle: {Animation1: number?, Animation2: number?}?,
	fall: number?,
	swim: number?,
	swimIdle: number?,
	climb: number?
}

export type HumanoidRigTypeToCustomRBXAnimationIdsType = {
	[Enum.HumanoidRigType]: CustomRBXAnimationIdsType?
}

type rigType = string
type animationId = number
type idTable = {
	[any]: idTable | animationId
}

export type AnimationIdsType = {
	[rigType]: idTable
}

type AnimationsSharedInitOptionsType = {
	BootstrapDepsFolder: Folder?,
	AutoLoadAllPlayerTracks: boolean?,
	TimeToLoadPrints: boolean?,
}
export type AnimationsClientInitOptionsType = {
	AutoRegisterPlayer: boolean?
} & AnimationsSharedInitOptionsType
export type AnimationsServerInitOptionsType = {
	AutoRegisterPlayers: boolean?
} & AnimationsSharedInitOptionsType

return {}