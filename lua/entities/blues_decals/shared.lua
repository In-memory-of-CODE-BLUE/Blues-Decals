ENT.Type = "anim"
ENT.Base = "base_gmodentity"
ENT.PrintName = "Blue's Decals"
ENT.Author = "<CODE BLUE>"
ENT.Contact = "Via Steam"
ENT.Spawnable = true
ENT.Category = "Blue's Decals"
ENT.AdminSpawnable = true

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "ImgurID" )
	self:NetworkVar( "Vector", 0, "ImageColor" )
	self:NetworkVar( "Vector", 1, "ImageScale" )
	self:NetworkVar( "Int", 0, "ImageAlpha")

	if SERVER then
		self:SetImageScale(Vector(1000, 1000, 0))
		self:SetImageAlpha(255)
		self:SetImageColor(Vector(255,255,255))
	end
end