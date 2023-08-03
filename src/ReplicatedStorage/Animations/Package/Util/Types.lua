type sharedProperties = {
	AutoLoadTracks: boolean,
	TimeToLoadPrints: boolean
}

export type AnimationsClientType = {
	AwaitLoaded: (self: AnimationsClientType) -> (),
	AwaitRigLoaded: (self: AnimationsClientType, rig: Model) -> (),

	AreTracksLoaded: (self: AnimationsClientType) -> boolean,
	AreRigTracksLoaded: (self: AnimationsClientType, rig: Model) -> boolean,

	LoadTracks: (self: AnimationsClientType) -> (),
	LoadRigTracks: (self: AnimationsClientType, rig: Model, rigType: string) -> (),

	GetTrack: (self: AnimationsClientType, path: any) -> AnimationTrack?,
	GetRigTrack: (self: AnimationsClientType, rig: Model, path: any) -> AnimationTrack?,

	PlayTrack: (self: AnimationsClientType, path: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,
	PlayRigTrack: (self: AnimationsClientType, rig: Model, path: any, fadeTime: number?) -> AnimationTrack,

	StopTrack: (self: AnimationsClientType, path: any, fadeTime: number?) -> AnimationTrack,
	StopRigTrack: (self: AnimationsClientType, rig: Model, path: any, fadeTime: number?) -> AnimationTrack,

	GetTrackFromAlias: (self: AnimationsClientType, alias: any) -> AnimationTrack?,
	GetRigTrackFromAlias: (self: AnimationsClientType, rig: Model, alias: any) -> AnimationTrack?,

	PlayTrackFromAlias: (self: AnimationsClientType, alias: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,
	PlayRigTrackFromAlias: (self: AnimationsClientType, rig: Model, alias: any, fadeTime: number?) -> AnimationTrack,

	StopTrackFromAlias: (self: AnimationsClientType, alias: any, fadeTime: number?) -> AnimationTrack,
	StopRigTrackFromAlias: (self: AnimationsClientType, rig: Model, alias: any, fadeTime: number?) -> AnimationTrack,

	SetTrackAlias: (self: AnimationsClientType, alias: any, path: any) -> (),
	SetRigTrackAlias: (self: AnimationsClientType, rig: Model, alias: any, path: any) -> (),

	RemoveTrackAlias: (self: AnimationsClientType, alias: any) -> (),
	RemoveRigTrackAlias: (self: AnimationsClientType, rig: Model, alias: any) -> (),

	Init: (self: AnimationsClientType) -> ()
} & sharedProperties

export type AnimationsServerType = {
	EnableAutoCustomRBXAnimationIds: boolean,
	
	ApplyCustomRBXAnimationIds: (self: AnimationsServerType, player: Player, customRBXAnimationIds: CustomRBXAnimationIdsType) -> (),
	
	AwaitLoaded: (self: AnimationsServerType, player_or_model: Player | Model) -> (),

	AreTracksLoaded: (self: AnimationsServerType, player_or_model: Player | Model) -> boolean,

	LoadTracks: (self: AnimationsServerType, player_or_model: Player | Model, rigType: string) -> (),

	GetTrack: (self: AnimationsServerType, player_or_model: Player | Model, path: any) -> AnimationTrack?,

	PlayTrack: (self: AnimationsServerType, player_or_model: Player | Model, path: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,

	StopTrack: (self: AnimationsServerType, player_or_model: Player | Model, path: any, fadeTime: number?) -> AnimationTrack,

	GetTrackFromAlias: (self: AnimationsServerType, player_or_model: Player | Model, alias: any) -> AnimationTrack?,

	PlayTrackFromAlias: (self: AnimationsServerType, player_or_model: Player | Model, alias: any, fadeTime: number?, weight: number?, speed: number?) -> AnimationTrack,

	StopTrackFromAlias: (self: AnimationsServerType, player_or_model: Player | Model, alias: any, fadeTime: number?) -> AnimationTrack,

	SetTrackAlias: (self: AnimationsServerType, player_or_model: Player | Model, alias: any, path: any) -> (),

	RemoveTrackAlias: (self: AnimationsServerType, player_or_model: Player | Model, alias: any) -> (),

	Init: (self: AnimationsServerType) -> ()
} & sharedProperties

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

return {}