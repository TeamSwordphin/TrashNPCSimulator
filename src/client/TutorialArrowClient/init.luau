local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Janitor = require(ReplicatedStorage.Libraries.Janitor).new()

local TutorialArrowClient = {}

function TutorialArrowClient:Render(part0: BasePart, part1: BasePart)
	assert(part0, "Part0 must not be nil!")
	assert(part1, "Part1 must not be nil!")

	Janitor:Cleanup()

	local primaryAttachment: Attachment = Janitor:Add(Instance.new("Attachment"), "Destroy")
	primaryAttachment.Parent = part0

	local secondaryAttachment: Attachment = Janitor:Add(Instance.new("Attachment"), "Destroy")
	secondaryAttachment.Parent = part1

	local beam: Beam = Janitor:Add(ReplicatedStorage.Assets.Effects.Beams.ArrowBeam:Clone(), "Destroy")
	beam.Attachment1 = primaryAttachment
	beam.Attachment0 = secondaryAttachment
	beam.Enabled = true
	beam.Parent = part0

	return Janitor
end

return TutorialArrowClient
