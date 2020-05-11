include("shared.lua")

include("blues_decal_config.lua")

local registeredEnts = {}

function ENT:Initialize()
	self.clientOverride = false
	self.clientOverrideScale = Vector(1000,1000,0)
	self.clientOverrideColor = Vector(255,255,255)
	self.clientOverrideAlpha = 255

	registeredEnts[self:EntIndex()] = self

	if self:GetImgurID() ~= nil and self:GetImgurID() ~= "" then
		timer.Simple(1, function()
			self:RefreshMaterial()
		end)
	end
end

function ENT:OnRemove()
	registeredEnts[self:EntIndex()] = nil
end

--Calling this will re-cache the material and load what ever the new ID is
function ENT:RefreshMaterial(customID)
	self.mat = nil
	if customID then
		BluesDecals.ImageLoader.GetMaterial(customID, function(mat)
			self.mat = mat
		end)
	else
		BluesDecals.ImageLoader.GetMaterial(self:GetImgurID(), function(mat)
			self.mat = mat
		end)
	end
end

--Draw nothing
function ENT:Draw()

end

function ENT:DrawImage()
	if LocalPlayer():GetPos():Distance(self:GetPos()) > BLUES_DECAL_CONFIG.RenderDistance then return end

	local scale = self:GetImageScale()
	local color = self:GetImageColor()
	local alpha = self:GetImageAlpha()

	if self.clientOverride then
		scale = self.clientOverrideScale
		color = Color(self.clientOverrideColor.r, self.clientOverrideColor.g, self.clientOverrideColor.b, self.clientOverrideAlpha)
	else
		color = Color(color.r, color.g, color.b, alpha)
	end

	local ang = self:GetAngles()
	ang:RotateAroundAxis(self:GetAngles():Up(),90)

	cam.Start3D2D( self:GetPos() + (self:GetAngles():Up() * -1.7), ang, 0.05 )
		if self.mat ~= nil and self.mat ~= false then
			surface.SetDrawColor(color)
			surface.SetMaterial(self.mat)
			surface.DrawTexturedRectRotated(0, 0, scale.x, scale.y, 0)
		else
			if self.mat ~= false then
				surface.SetDrawColor(Color(255,255,255,255))
				surface.SetMaterial(BluesDecals.UI.Materials.loading)
				surface.DrawTexturedRectRotated(0,0, 1000, 1000, (CurTime() * -250) % 360)
			end
		end
	cam.End3D2D()
end

--Handles refreshing the material
net.Receive("BLUESDECALS:RefreshMaterial", function()
	local e = net.ReadEntity()

	if IsValid(e) then
		e:RefreshMaterial()
	end
end)

hook.Add( "PostDrawTranslucentRenderables", "BLUESDECALS:DrawCam3D2D", function()
	for k, v in pairs(ents.FindByClass("blues_decals")) do
		v:DrawImage()
	end
end)











