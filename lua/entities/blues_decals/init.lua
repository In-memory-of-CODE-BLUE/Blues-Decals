AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

AddCSLuaFile("blues_decal_config.lua")
include("blues_decal_config.lua")

util.AddNetworkString("BLUESDECALS:OpenMenu")
util.AddNetworkString("BLUESDECALS:RefreshMaterial")
util.AddNetworkString("BLUESDECALS:UpdateEntityData")
util.AddNetworkString("BLUESDECALS:SetupDecals")

function ENT:Initialize()
	self:SetModel("models/hunter/plates/plate1x1.mdl")
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )

	self:SetUseType(SIMPLE_USE)
	self:SetRenderMode(RENDERMODE_TRANSALPHA)

	self:SetCollisionGroup(COLLISION_GROUP_DEBRIS)

	local phys = self:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake() 
	end

	self:SetColor(Color(255,255,255,0))
end

function ENT:Use(act, call)
	if table.HasValue(BLUES_DECAL_CONFIG.AllowedRanks, call:GetUserGroup()) then
		net.Start("BLUESDECALS:OpenMenu")
		net.WriteEntity(self)
		net.Send(call)
	else
		call:ChatPrint("[BLUE'S DECALS] You do not have permission to edit this decal!")
	end
end

--Networking stuff
net.Receive("BLUESDECALS:UpdateEntityData", function(len, ply)
	if table.HasValue(BLUES_DECAL_CONFIG.AllowedRanks, ply:GetUserGroup()) then
		local e = net.ReadEntity()
		local data = net.ReadTable()
		if IsValid(e) and e:GetClass() == "blues_decals" then
			--Update the info to the table info
			e:SetImgurID(data.id)
			e:SetImageScale(data.scale)
			e:SetImageColor(data.color)
			e:SetImageAlpha(data.alpha)

			--Wait until next frame to ensure the users have updated decals
			timer.Simple(1, function()
				net.Start("BLUESDECALS:RefreshMaterial")
				net.WriteEntity(e)
				net.Broadcast()
			end)

			ply:ChatPrint("[BLUE'S DECALS] Updated decal!")
		end
	else
		ply:ChatPrint("[BLUE'S DECALS] You do not have permission to edit this decal!")
	end
end)

--Saving and loading of decals
local function SaveDecals()
	local data = {}

	for k ,v in pairs(ents.FindByClass("blues_decals")) do
		table.insert(data, {pos = v:GetPos(), ang = v:GetAngles(), id = v:GetImgurID(), color = v:GetImageColor(), alpha = v:GetImageAlpha(), scale = v:GetImageScale()})
	end
	if not file.Exists("bluesdecals" , "DATA") then
		file.CreateDir("bluesdecals")
	end

	file.Write("bluesdecals/"..game.GetMap()..".txt", util.TableToJSON(data))
end

local function LoadDecals()
	if file.Exists("bluesdecals/"..game.GetMap()..".txt" , "DATA") then
		local data = file.Read("bluesdecals/"..game.GetMap()..".txt", "DATA")
		data = util.JSONToTable(data) 
		for k, v in pairs(data) do



			local decal = ents.Create("blues_decals")
			decal:Spawn()
			decal:SetPos(v.pos)
			decal:SetAngles(v.ang)
			decal:GetPhysicsObject():EnableMotion(false)

			decal:SetImgurID(v.id)
			decal:SetImageColor(v.color)
			decal:SetImageAlpha(v.alpha)
			decal:SetImageScale(v.scale)
		end
		print("[BLUES DECALS] Finished loading decals.")
	else
		print("[BLUES DECALS] No map data found for decals. Please place some and do !savedecals to create the data.")
	end
end

hook.Add("InitPostEntity", "BLUEDECALS:LoadDecals", function()
	LoadDecals()
end)

hook.Add("PostCleanupMap", "BLUEDECALS:ReloadDecals", function()
	LoadDecals()
end)

--Handle saving and loading of slots
hook.Add("PlayerSay", "BLUESDECALS:HandleSavingDecals" , function(ply, text)
	if string.sub(string.lower(text), 1, 11) == "!savedecals" then
		if table.HasValue(BLUES_DECAL_CONFIG.AllowedRanks, ply:GetUserGroup()) then
			SaveDecals()
			ply:ChatPrint("[BLUES DECALS] Decals have been saved for the map "..game.GetMap().."!")
		else
			ply:ChatPrint("[BLUES DECALS] You do not have permission to perform this action.")
		end
	end
end)