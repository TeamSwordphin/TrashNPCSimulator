export type EntityModel = {
	PrimaryPart: BasePart,
	Head: BasePart,
	Humanoid: Humanoid,
	Name: string,
	GetDescendants: (self: EntityModel) -> { Instance },
	PivotTo: (self: EntityModel, cframe: CFrame) -> (),
	HasTag: (self: EntityModel, tag: string) -> (),
	AddTag: (self: EntityModel, tag: string) -> (),
}

export type MaterialCost = {
	[string]: number,
}

export type AgentParameter = {
	AgentRadius: number,
	AgentHeight: number,
	AgentCanJump: boolean,
	AgentCanClimb: boolean,
	WaypointSpacing: number,
	Costs: MaterialCost,
}

export type Entity = {
	Look: string?,
	Target: Model?,
	Model: EntityModel,
	Path: Path,
	Lane: any,
	State: string,
	WalkSpeed: number,
	LaneTraversed: boolean,
	CurrentNode: number,
	MaxNodes: number,
	Direction: number,
	StateChanged: any,
	Destroyed: any,
	LooksChanged: any,
	FirstSpawned: boolean,
	SetState: (self: Entity, newState: string) -> (),
	SetLaneProperties: (self: Entity, lane: any) -> (),
	Destroy: (self: Entity) -> (),
}

return {}
