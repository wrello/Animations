--!strict

export type AnimationsServerType = {
	Init: (self: AnimationsServerType, initOptions: AnimationsServerInitOptionsType?) -> (),
	
	AwaitLoaded: (self: AnimationsServerType, player_or_model: Player | Model) -> (),

	AreTracksLoaded: (self: AnimationsServerType, player_or_model: Player | Model) -> boolean,

	LoadTracks: (self: AnimationsServerType, player_or_model: Player | Model, rigType: string?) -> (),

	GetTrack: (self: AnimationsServerType, player_or_model: Player | Model, path: {any} | string) -> AnimationTrack?,

	PlayTrack: (self: AnimationsServerType, player_or_model: Player | Model, path: {any} | string, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,

	StopTrack: (self: AnimationsServerType, player_or_model: Player | Model, path: {any} | string, fadeTime: number?) -> AnimationTrack,

	StopAllTracks: (self: AnimationsServerType, player_or_model: Player | Model, fadeTime: number?) -> {AnimationTrack?},

	StopTracksOfPriority: (self: AnimationsServerType, player_or_model: Player | Model, animationPriority: Enum.AnimationPriority, fadeTime: number?) -> {AnimationTrack?},

	GetTrackFromAlias: (self: AnimationsServerType, player_or_model: Player | Model, alias: any) -> AnimationTrack?,

	PlayTrackFromAlias: (self: AnimationsServerType, player_or_model: Player | Model, alias: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,

	StopTrackFromAlias: (self: AnimationsServerType, player_or_model: Player | Model, alias: any, fadeTime: number?) -> AnimationTrack,

	SetTrackAlias: (self: AnimationsServerType, player_or_model: Player | Model, alias: any, path: {any} | string) -> (),

	RemoveTrackAlias: (self: AnimationsServerType, player_or_model: Player | Model, alias: any) -> (),

	AttachAnimatedObject: (self: AnimationsServerType, player_or_model: Player | Model, animatedObjectPath: {any} | string) -> (),
	
	DetachAnimatedObject: (self: AnimationsServerType, player_or_model: Player | Model, animatedObjectPath: {any} | string) -> (),

	ApplyCustomRBXAnimationIds: (self: AnimationsServerType, player_or_rig: Player | Model, humanoidRigTypeCustomRBXAnimationIds: HumanoidRigTypeToCustomRBXAnimationIdsType) -> (),

	GetAnimationProfile: (self: AnimationsServerType, animationProfileName: string) -> HumanoidRigTypeToCustomRBXAnimationIdsType?,

	ApplyAnimationProfile: (self: AnimationsServerType, player_or_rig: Player | Model, animationProfileName: string) -> ()
} & AnimationsServerInitOptionsType

export type AnimationsClientType = {
	Init: (self: AnimationsClientType, initOptions: AnimationsClientInitOptionsType?) -> (),
	
	AwaitLoaded: (self: AnimationsClientType) -> (),
	AwaitRigLoaded: (self: AnimationsClientType, rig: Model) -> (),

	AreTracksLoaded: (self: AnimationsClientType) -> boolean,
	AreRigTracksLoaded: (self: AnimationsClientType, rig: Model) -> boolean,

	LoadTracks: (self: AnimationsClientType) -> (),
	LoadRigTracks: (self: AnimationsClientType, rig: Model, rigType: string) -> (),

	GetTrack: (self: AnimationsClientType, path: {any} | string) -> AnimationTrack?,
	GetRigTrack: (self: AnimationsClientType, rig: Model, path: {any} | string) -> AnimationTrack?,

	PlayTrack: (self: AnimationsClientType, path: {any} | string, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,
	PlayRigTrack: (self: AnimationsClientType, rig: Model, path: {any} | string,  fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,

	StopTrack: (self: AnimationsClientType, path: {any} | string, fadeTime: number?) -> AnimationTrack,
	StopRigTrack: (self: AnimationsClientType, rig: Model, path: {any} | string, fadeTime: number?) -> AnimationTrack,

	StopAllTracks: (self: AnimationsClientType, fadeTime: number?) -> {AnimationTrack?},
	StopRigAllTracks: (self: AnimationsClientType, rig: Model, fadeTime: number?) -> {AnimationTrack?},

	StopTracksOfPriority: (self: AnimationsClientType, animationPriority: Enum.AnimationPriority, fadeTime: number?) -> {AnimationTrack?},
	StopRigTracksOfPriority: (self: AnimationsClientType, rig: Model, animationPriority: Enum.AnimationPriority, fadeTime: number?) -> {AnimationTrack?},

	GetTrackFromAlias: (self: AnimationsClientType, alias: any) -> AnimationTrack?,
	GetRigTrackFromAlias: (self: AnimationsClientType, rig: Model, alias: any) -> AnimationTrack?,

	PlayTrackFromAlias: (self: AnimationsClientType, alias: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,
	PlayRigTrackFromAlias: (self: AnimationsClientType, rig: Model, alias: any,  fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,

	StopTrackFromAlias: (self: AnimationsClientType, alias: any, fadeTime: number?) -> AnimationTrack,
	StopRigTrackFromAlias: (self: AnimationsClientType, rig: Model, alias: any, fadeTime: number?) -> AnimationTrack,

	SetTrackAlias: (self: AnimationsClientType, alias: any, path: {any} | string) -> (),
	SetRigTrackAlias: (self: AnimationsClientType, rig: Model, alias: any, path: {any} | string) -> (),

	RemoveTrackAlias: (self: AnimationsClientType, alias: any) -> (),
	RemoveRigTrackAlias: (self: AnimationsClientType, rig: Model, alias: any) -> (),

	AttachAnimatedObject: (self: AnimationsClientType, animatedObjectPath: {any} | string) -> (),
	AttachRigAnimatedObject: (self: AnimationsClientType, rig: Model, animatedObjectPath: {any} | string) -> (),
	
	DetachAnimatedObject: (self: AnimationsClientType, animatedObjectPath: {any} | string) -> (),
	DetachRigAnimatedObject: (self: AnimationsClientType, rig: Model, animatedObjectPath: {any} | string) -> (),

	ApplyCustomRBXAnimationIds: (self: AnimationsClientType, humanoidRigTypeCustomRBXAnimationIds: HumanoidRigTypeToCustomRBXAnimationIdsType) -> (),
	ApplyRigCustomRBXAnimationIds: (self: AnimationsClientType, rig: Model, humanoidRigTypeCustomRBXAnimationIds: HumanoidRigTypeToCustomRBXAnimationIdsType) -> (),

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

export type AnimationsClientInitOptionsType = {
	AutoLoadPlayerTracks: boolean?,
	TimeToLoadPrints: boolean?,
	AnimatedObjectsDebugMode: boolean?
}

export type AnimationsServerInitOptionsType = {
	EnableAutoCustomRBXAnimationIds: boolean?
} & AnimationsClientInitOptionsType

return {}