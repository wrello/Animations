type PrivateClientServerSharedType = {
	_initialized: boolean,
	_initializedAssertion: () -> (),
}

type PrivateAnimationsClientType = PrivateClientServerSharedType & AnimationsClientType
type PrivateAnimationsServerType = PrivateClientServerSharedType & AnimationsServerType

export type AnimationsServerType = {
	AwaitLoaded: (self: PrivateAnimationsServerType, player_or_model: Player | Model) -> (),

	AreTracksLoaded: (self: PrivateAnimationsServerType, player_or_model: Player | Model) -> boolean,

	LoadTracks: (self: PrivateAnimationsServerType, player_or_model: Player | Model, rigType: string) -> (),

	GetTrack: (self: PrivateAnimationsServerType, player_or_model: Player | Model, path: any) -> AnimationTrack?,

	PlayTrack: (self: PrivateAnimationsServerType, player_or_model: Player | Model, path: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,

	StopTrack: (self: PrivateAnimationsServerType, player_or_model: Player | Model, path: any, fadeTime: number?) -> AnimationTrack,

	GetTrackFromAlias: (self: PrivateAnimationsServerType, player_or_model: Player | Model, alias: any) -> AnimationTrack?,

	PlayTrackFromAlias: (self: PrivateAnimationsServerType, player_or_model: Player | Model, alias: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,

	StopTrackFromAlias: (self: PrivateAnimationsServerType, player_or_model: Player | Model, alias: any, fadeTime: number?) -> AnimationTrack,

	SetTrackAlias: (self: PrivateAnimationsServerType, player_or_model: Player | Model, alias: any, path: any) -> (),

	RemoveTrackAlias: (self: PrivateAnimationsServerType, player_or_model: Player | Model, alias: any) -> (),
	
	ApplyCustomRBXAnimationIds: (self: PrivateAnimationsServerType, player: Player, customRBXAnimationIds: CustomRBXAnimationIdsType) -> (),
	
	Init: (self: PrivateAnimationsServerType, initOptions: AnimationsServerInitOptionsType?) -> ()	
} & AnimationsServerInitOptionsType

export type AnimationsClientType = {
	AwaitLoaded: (self: PrivateAnimationsClientType) -> (),
	AwaitRigLoaded: (self: PrivateAnimationsClientType, rig: Model) -> (),

	AreTracksLoaded: (self: PrivateAnimationsClientType) -> boolean,
	AreRigTracksLoaded: (self: PrivateAnimationsClientType, rig: Model) -> boolean,

	LoadTracks: (self: PrivateAnimationsClientType) -> (),
	LoadRigTracks: (self: PrivateAnimationsClientType, rig: Model, rigType: string) -> (),

	GetTrack: (self: PrivateAnimationsClientType, path: any) -> AnimationTrack?,
	GetRigTrack: (self: PrivateAnimationsClientType, rig: Model, path: any) -> AnimationTrack?,

	PlayTrack: (self: PrivateAnimationsClientType, path: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,
	PlayRigTrack: (self: PrivateAnimationsClientType, rig: Model, path: any, fadeTime: number?) -> AnimationTrack,

	StopTrack: (self: PrivateAnimationsClientType, path: any, fadeTime: number?) -> AnimationTrack,
	StopRigTrack: (self: PrivateAnimationsClientType, rig: Model, path: any, fadeTime: number?) -> AnimationTrack,

	GetTrackFromAlias: (self: PrivateAnimationsClientType, alias: any) -> AnimationTrack?,
	GetRigTrackFromAlias: (self: PrivateAnimationsClientType, rig: Model, alias: any) -> AnimationTrack?,

	PlayTrackFromAlias: (self: PrivateAnimationsClientType, alias: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,
	PlayRigTrackFromAlias: (self: PrivateAnimationsClientType, rig: Model, alias: any, fadeTime: number?) -> AnimationTrack,

	StopTrackFromAlias: (self: PrivateAnimationsClientType, alias: any, fadeTime: number?) -> AnimationTrack,
	StopRigTrackFromAlias: (self: PrivateAnimationsClientType, rig: Model, alias: any, fadeTime: number?) -> AnimationTrack,

	SetTrackAlias: (self: PrivateAnimationsClientType, alias: any, path: any) -> (),
	SetRigTrackAlias: (self: PrivateAnimationsClientType, rig: Model, alias: any, path: any) -> (),

	RemoveTrackAlias: (self: PrivateAnimationsClientType, alias: any) -> (),
	RemoveRigTrackAlias: (self: PrivateAnimationsClientType, rig: Model, alias: any) -> (),

	Init: (self: PrivateAnimationsClientType, initOptions: AnimationsClientInitOptionsType?) -> ()	
} & AnimationsClientInitOptionsType

export type CustomRBXAnimationIdsType = {
	[EnumItem]: {
		run: number?,
		walk: number?,
		jump: number?,
		idle: {Animation1: number?, Animation2: number?}?,
		fall: number?,
		swim: number?,
		swimIdle: number?,
		climb: number?
	}?
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
	AutoLoadPlayerTracks: boolean,
	TimeToLoadPrints: boolean,
}

export type AnimationsServerInitOptionsType = {
	EnableAutoCustomRBXAnimationIds: boolean
} & AnimationsClientInitOptionsType

return {}