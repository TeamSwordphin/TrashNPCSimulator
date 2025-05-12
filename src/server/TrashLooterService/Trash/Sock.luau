--!strict

local SPEED = 100
local MAX_DISTANCE = 500
local GRAVITY = Vector3.new(0, -workspace.Gravity * 0.1, 0)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")

local Entity = require(ServerStorage.EntityServer.Entity)
local PlayerDataService = require(ServerScriptService.Server.PlayerDataService)
local TrashItemData = require(ReplicatedStorage.Modules.TrashItemData)
local NPCLooterService = require(ServerScriptService.Server.NPCLooterService)
local FlashCast = require(ReplicatedStorage.Libraries.FlashCast)
local PlayerLooterService = require(ServerScriptService.Server.PlayerLooterService)

local Item = {}

function Item:Create(player: Player, tool: Tool)
	local profileExport: PlayerDataService.ProfileExport? = PlayerDataService:GetProfile(player)
	local uses = 0

	tool.Activated:Connect(function()
		if profileExport then
			-- Spawn the sock in the overworld!
			local handle: Part = tool.PrimaryPart :: Part

			local sock: Part = handle:Clone()
			local trail: Trail = sock:FindFirstChild("Trail") :: Trail
			trail.Enabled = true

			sock.CFrame = handle.CFrame
			sock.Anchored = true
			sock.CanCollide = false
			sock.Parent = workspace

			local smelly: ParticleEmitter = sock:FindFirstChild("Smelly") :: ParticleEmitter

			local function onHit(hit)
				local entity = Entity:GetEntityFromModel(hit.Parent :: Instance)

				if entity then
					entity:SetState("Run")
					NPCLooterService:DropLoot(player, entity)
				else
					local targetPlayer: Player? = Players:GetPlayerFromCharacter(hit.Parent)

					if not targetPlayer then
						return
					end

					PlayerLooterService:DropLoot(player, targetPlayer)
				end

				local smellyParticle = smelly:Clone()
				smellyParticle.Parent = hit
				task.delay(2, smellyParticle.Destroy, smellyParticle)
			end

			local function gravity(bullet: FlashCast.Bullet, deltaTime: number)
				local parallelComponent = bullet.direction:Dot(GRAVITY.Unit) * GRAVITY.Unit
				local perpendicularComponent = bullet.direction - parallelComponent
				local newDirection = perpendicularComponent + (parallelComponent + GRAVITY * deltaTime)

				bullet.direction = newDirection.Unit * bullet.direction.Magnitude
				sock.Position = bullet.position

				if bullet.touched then
					bullet:stop()
					sock:Destroy()
					onHit(bullet.touched.Instance)
				end
			end

			local function MaxDistance(bullet: FlashCast.Bullet)
				if bullet.distanceTraveled > MAX_DISTANCE then
					bullet:stop()
					sock:Destroy()
				end
			end

			local rootPart = (player.Character :: Model).PrimaryPart :: BasePart
			local direction = rootPart.CFrame.LookVector.Unit :: Vector3
			local projectile = FlashCast.new()
			local bullet = projectile:spawnBullet(
				FlashCast.createBehavior():setDesiredFramerate(50):beforeStep(MaxDistance):afterStep(gravity),
				rootPart.Position,
				direction * SPEED
			)

			local params = RaycastParams.new()
			params.FilterDescendantsInstances = { tool.Parent :: Instance }
			bullet.raycastParams = params

			uses += 1

			if uses >= 2 then
				local inventory = profileExport:Get("Inventory")

				for inventoryIndex, itemIndex in inventory do
					local itemInformation: TrashItemData.ItemData? = TrashItemData:Get(itemIndex)

					if itemInformation and itemInformation.Name == tool.Name then
						table.remove(inventory, inventoryIndex)
						break
					end
				end

				profileExport:Set("Inventory", inventory)

				tool:Destroy()
			end
		end
	end)
end

return Item
