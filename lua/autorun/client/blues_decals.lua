BluesDecals = {}

--[[-------------------------------------------------------------------------
This part will cache, load or save materials from the web
---------------------------------------------------------------------------]]
BluesDecals.ImageLoader = {}
BluesDecals.ImageLoader.CachedMaterials = {}
BluesDecals.UI = {}
BluesDecals.UI.Elements = {}
BluesDecals.UI.Materials = {
	refresh = Material("error"),
	loading = Material("error")
}

BluesDecals.UI.CopiedData = nil

surface.CreateFont( "BluesDecals_SmallReg", {
	font = "Roboto",
	extended = false,
	size = 16,
	weight = 200,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

surface.CreateFont( "BluesDecals_SmallBold", {
	font = "Roboto",
	extended = false,
	size = 25,
	weight = 800,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = false,
	additive = false,
	outline = false,
} )

--This allows you to get a material based on an ID (should be the imgur URL ID)
--Make sure directory exists
file.CreateDir("bluesdecals")

--There is a callback in-case the image is not loaded or isnt finished. The first argument of the callback
--is the material object for that texture, it will return an error texture if the material is not loaded
function BluesDecals.ImageLoader.GetMaterial(id, callback)
	--First check if the ID is cached
	if BluesDecals.ImageLoader.CachedMaterials[id] ~= nil then
		print("Image already loaded, returning material")
		callback(BluesDecals.ImageLoader.CachedMaterials[id])
	else
		--Now check if we have that material file, if so load it as a material and return it
		if file.Exists("bluesdecals/"..id..".png", "DATA") then
			print("File found, loading material then returning")
			--It does exists, so we create the material
			BluesDecals.ImageLoader.CachedMaterials[id] = Material("data/bluesdecals/"..id..".png", "noclamp smooth")
			callback(BluesDecals.ImageLoader.CachedMaterials[id])
		else
			print("Failed to find image, attempting to load from imgur")
			--So the file does not exist, so we need to load it, cache it then return the callback
			http.Fetch("https://i.imgur.com/"..id..".png",function(body)
				print("Loaded Imgur Image : "..id..",png")
				file.Write("bluesdecals/"..id..".png", body)
				BluesDecals.ImageLoader.CachedMaterials[id] = Material("data/bluesdecals/"..id..".png", "noclamp smooth")
				callback(BluesDecals.ImageLoader.CachedMaterials[id])
			end, function()
				callback(false)
			end)
		end
	end
end

--Load the default materials from imgur
BluesDecals.ImageLoader.GetMaterial("Bq1tnt1", function(mat)
	if isbool(mat) then return end
	BluesDecals.UI.Materials.loading = mat
end)

BluesDecals.ImageLoader.GetMaterial("wpUNPRi", function(mat)
	if isbool(mat) then return end
	BluesDecals.UI.Materials.refresh = mat
end)

--[[-------------------------------------------------------------------------
Some UI elements
---------------------------------------------------------------------------]]
function BluesDecals.UI.Elements.CreateSlider(color, minValue, maxValue, parent, onValueChanged)
	local function drawCircle( x, y, radius, seg ) --Credit to wiki
		local cir = {}

		table.insert( cir, { x = x, y = y, u = 0.5, v = 0.5 } )
		for i = 0, seg do
			local a = math.rad( ( i / seg ) * -360 )
			table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
		end

		local a = math.rad( 0 ) -- This is needed for non absolute segment counts
		table.insert( cir, { x = x + math.sin( a ) * radius, y = y + math.cos( a ) * radius, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )

		surface.DrawPoly( cir )
	end 

	local p = vgui.Create("DPanel", parent)
	--p:NoClipping(true)
	p.slideAmount = 100 --This is between 0 and 100, regardless of the min and max value as there mapped to it
	p.Paint = function(s, w, h)
		local slideAmountPixel = math.Clamp(w/100 * (s.slideAmount) - h/2, h/2, w - (h/2))

		--Draw background and rounded edges
		draw.RoundedBox(0,h/2,2, w - h, h - 4,Color(40, 40, 45))
		draw.NoTexture()
		surface.SetDrawColor(Color(40, 40, 45))
		drawCircle(w - (h/2), h/2, (h/2) - 2, 16)
		
		--Draw the color section
		draw.RoundedBox(0,h/2,2, slideAmountPixel - (h/2), h - 4,color)
		draw.NoTexture()
		surface.SetDrawColor(color)
		drawCircle((h/2), h/2, (h/2) - 2, 16)

		--Slider end
		surface.SetDrawColor(Color(40, 40, 45))
		drawCircle(slideAmountPixel, h/2, (h/2) + 2, 16)
		surface.SetDrawColor(color)
		drawCircle(slideAmountPixel, h/2, (h/2) - 1, 16)
	end

	p.PerformLayout = function(s, w, h)
		s.sliderButton:SetSize(w, h)
	end

	--Create the slider end button
	local sliderButton = vgui.Create("DButton",p)
	sliderButton:SetText("")
	sliderButton.skipFrames = 0 --Skip frames are used becuase gui uses cached results
	sliderButton.Paint = function() end --Hide button
	sliderButton.OnMousePressed = function(s, keycode)
		if keycode == MOUSE_LEFT then
			s.sliding = true
			s.skipFrames = 1
		end
	end
	sliderButton.Think = function(s)
		if s.skipFrames > 0 then
			s.skipFrames = s.skipFrames - 1
		else
			if not input.IsMouseDown(MOUSE_LEFT) and s.sliding then
				s.sliding = false
				
			end
		end
			
		if s.sliding then
			
			--Work out new slider position
			local x, y = s:ScreenToLocal(gui.MouseX(), gui.MouseY())
			local newSlidePos = (100 / s:GetWide()) * math.Clamp(x + (p:GetTall()/2), 0, p:GetWide()) 

			p.slideAmount = newSlidePos
			onValueChanged(p.slideAmount/100 * maxValue)
		end
	end

	p.sliderButton = sliderButton

	return p
end

function BluesDecals.UI.Elements.CreateImgurEntry(ghostText, parent, onRefresh)

	shouldMakeSmaller = false
	hasCloseButton = true

	local p = vgui.Create("DTextEntry", parent)
	p:SetPaintBackground(false)
	p.lerpValue = 0
	p.canEdit = true
	p.Paint = function(s, w, h)
		if not shouldMakeSmaller then
			s.lerpValue = 1
		end

		local lerpPixelValue = (1 - s.lerpValue) * 125

		draw.RoundedBox(4,lerpPixelValue,0,w - lerpPixelValue,h,Color(40,40,45,255))

		--Draw ghost text
		if s:GetText() == "" and not s:IsEditing() then
			if s.canEdit then
				draw.SimpleText(ghostText, "BluesDecals_SmallReg", lerpPixelValue + 5, (h/2) - 2 , Color(149, 152, 154),  0, 1)
			else
				draw.SimpleText(ghostText, "BluesDecals_SmallReg", lerpPixelValue + 5, (h/2) - 2 , Color(149 * 0.5, 152 * 0.5, 154 * 0.5),  0, 1)
			end
		end

		if s.canEdit then
			s:DrawTextEntryText(Color(149, 152, 154), Color(255, 152, 154), Color(255, 255, 255))
		else
			s:DrawTextEntryText(Color(149 * 0.5, 152 * 0.5, 154 * 0.5), Color(255, 152, 154), Color(255, 255, 255))
		end

		if s:IsHovered() or s:IsEditing() or s:GetText() ~= "" then
			s.lerpValue = Lerp(15 * FrameTime(), s.lerpValue, 1)
		else
			s.lerpValue = Lerp(15 * FrameTime(), s.lerpValue, 0)
		end

	end

	p.Think = function(self)
		if string.len(self:GetText()) == 7 then
			if self.refreshed ~= true then
				onRefresh(self:GetText())
			end
			self.refreshed = true
		else
			self.refreshed = false
		end
		
	end

	p.AllowInput = function( self, stringValue )
		return not self.canEdit
	end
	
	function p:PerformLayout()
	
	end

	function p:PerformLayout(width, height)
		if hasCloseButton then
			self.b:SetPos(width - height, 0)
			self.b:SetSize(height, height)
		end
		self:SetFontInternal("BluesDecals_SmallReg")
	end

	if hasCloseButton then

		--Now create the clear button
		local b = vgui.Create("DButton", p)
		b:SetText("")
		b.DoClick = function() 
			if p.canEdit then
				onRefresh(p:GetText()) 
			end
		end
		b.Paint = function(s ,  w , h)
			if p.canEdit then
				surface.SetDrawColor(Color(149,152,154))
			else
				surface.SetDrawColor(Color(149 * 0.5,152 * 0.5,154 * 0.5))
			end
			surface.SetMaterial(BluesDecals.UI.Materials.refresh)
			surface.DrawTexturedRect(7,7,w - 14,h - 14)
		end

		p.b = b

	end

	return p
end

function BluesDecals.UI.Elements.CreateStandardButton(text, parent, onClick)
	local p = vgui.Create("DButton", parent)
	p:SetText("")
	p.Paint = function(s, w, h)
		if not s:IsHovered() then
			draw.RoundedBox(4,0,0,w,h,Color(39, 121, 189,255))
		else
			draw.RoundedBox(4,0,0,w,h,Color(39 * 1.1, 121 * 1.1, 189 * 1.1,255))
		end
		--Draw text
		draw.SimpleText(text, "BluesDecals_SmallBold", w/2, h/2, Color(255, 255, 255),  1, 1)
	end
	p.DoClick = onClick

	return p
end

--[[-------------------------------------------------------------------------
This part handles the UI for editing a decal
---------------------------------------------------------------------------]]
function BluesDecals.OpenMenu(entity, customEntityData)
	entity.clientOverride = true
	entity.clientOverrideScale = entity:GetImageScale()
	entity.clientOverrideColor = entity:GetImageColor()
	entity.clientOverrideAlpha = entity:GetImageAlpha()

	local entityData = {
		id = entity:GetImgurID(),
		scale = entity:GetImageScale(),
		color = entity:GetImageColor(),
		alpha = entity:GetImageAlpha()
	}

	if customEntityData ~= nil then
		entityData = customEntityData

		entity.clientOverrideScale = entityData.scale
		entity.clientOverrideColor = entityData.color
		entity.clientOverrideAlpha = entityData.alpha
	

		entity:RefreshMaterial(entityData.id)
	end

	--Create the menu
	local frame = vgui.Create("DFrame")
	frame:SetSize(300, 480 + 50 + 10)
	frame:Center()
	frame:ShowCloseButton(false)
	frame:SetTitle("")
	frame.Paint = function(s , w , h)
		draw.RoundedBox(8,0, 0, w, h, Color(27,27, 30, 255))
		draw.SimpleText("Blue's Decal Editor", "BluesDecals_SmallReg", w/2, 15, Color(90, 90, 90, 255), 1, 1)

		draw.SimpleText("Imgur ID", "BluesDecals_SmallBold", w/2, 50, Color(200, 200, 200, 255), 1, 1)

		draw.SimpleText("Image Color", "BluesDecals_SmallBold", w/2, 140, Color(200, 200, 200, 255), 1, 1)

		draw.SimpleText("Image Scale", "BluesDecals_SmallBold", w/2, 140 + 30 + 23 + 23 + 23 + 23 + 10, Color(200, 200, 200, 255), 1, 1)
	end
	frame.Close = function(s)
		entity.clientOverride = false
		s:Remove()
	end
	frame:MakePopup()

	--Imgur ID entry
	local idEntry = BluesDecals.UI.Elements.CreateImgurEntry("Imgur ID", frame, function(id)
		entity:RefreshMaterial(id)
		entityData.id = id
	end)
	idEntry:SetPos(10, 70)
	idEntry:SetSize(300 - 20, 40)


	--Color stuff
	local rSlider = BluesDecals.UI.Elements.CreateSlider(Color(204,31,26), 0, 255, frame, function(val)
		entity.clientOverrideColor.x = val
		entityData.color.r = val
	end)
	rSlider.slideAmount = (100 / 255) * entityData.color.x
	rSlider:NoClipping(true)
	rSlider:SetPos(10, 160)
	rSlider:SetSize(300 - 20, 14)

	local gSlider = BluesDecals.UI.Elements.CreateSlider(Color(31,157,85), 0, 255, frame, function(val)
		entity.clientOverrideColor.y = val
		entityData.color.g = val
	end)
	gSlider.slideAmount = (100 / 255) * entityData.color.y
	gSlider:NoClipping(true)
	gSlider:SetPos(10, 160 + 23)
	gSlider:SetSize(300 - 20, 14)

	local bSlider = BluesDecals.UI.Elements.CreateSlider(Color(39, 121, 189), 0, 255, frame, function(val)
		entity.clientOverrideColor.z = val
		entityData.color.b = val
	end)
	bSlider.slideAmount = (100 / 255) * entityData.color.b
	bSlider:NoClipping(true)
	bSlider:SetPos(10, 160 + 23 + 23)
	bSlider:SetSize(300 - 20, 14)

	local aSlider = BluesDecals.UI.Elements.CreateSlider(Color(200, 200, 200), 0, 255, frame, function(val)
		entity.clientOverrideAlpha = val
		entityData.alpha = val
	end)
	aSlider.slideAmount = (100 / 255) * entityData.alpha
	aSlider:NoClipping(true)
	aSlider:SetPos(10, 160 + 23 + 23 + 23)
	aSlider:SetSize(300 - 20, 14)

	--Scale stuff
	local xSlider = BluesDecals.UI.Elements.CreateSlider(Color(200, 200, 200), 0, 8000, frame, function(val)
		entity.clientOverrideScale.x = val
		entityData.scale.x = val
	end)
	xSlider.slideAmount = (100 / 8000) * entity.clientOverrideScale.x
	xSlider:NoClipping(true)
	xSlider:SetPos(10, 160 + 23 + 23 + 90)
	xSlider:SetSize(300 - 20, 14)

	local ySlider = BluesDecals.UI.Elements.CreateSlider(Color(200, 200, 200), 0, 8000, frame, function(val)
		entity.clientOverrideScale.y = val
		entityData.scale.y = val
	end)
	ySlider.slideAmount = (100 / 8000) * entity.clientOverrideScale.y
	ySlider:NoClipping(true)
	ySlider:SetPos(10, 160 + 23 + 23 + 23 + 90)
	ySlider:SetSize(300 - 20, 14)

	--Update/Close buttons
	local updateButton = BluesDecals.UI.Elements.CreateStandardButton("Update", frame, function()
		net.Start("BLUESDECALS:UpdateEntityData")
		net.WriteEntity(entity)
		net.WriteTable(entityData)
		net.SendToServer()

		notification.AddLegacy("[DECALS] Updated Decal!", NOTIFY_UNDO, 3)
	end)
	updateButton:SetPos(10, 160 + 23 + 23 + 23 + 100 + 30)
	updateButton:SetSize(300 - 20, 50)

	local copyButton = BluesDecals.UI.Elements.CreateStandardButton("Copy", frame, function()
		--entityData
		BluesDecals.UI.CopiedData = entityData
		notification.AddLegacy("[DECALS] Copied Preset!", NOTIFY_CLEANUP, 3)
	end)
	copyButton:SetPos(10, 160 + 23 + 23 + 23 + 100 + 30 + 60)
	copyButton:SetSize(300/2 - 10 - 5, 50)

	local pasteButton = BluesDecals.UI.Elements.CreateStandardButton("Paste", frame, function()
		if BluesDecals.UI.CopiedData ~= nil then
			entityData = BluesDecals.UI.CopiedData
			--idEntry:SetText(entityData.id)
			--entity:RefreshMaterial(entityData.id)
			frame:Close()
			BluesDecals.OpenMenu(entity, entityData)

			notification.AddLegacy("[DECALS] Pasted Preset!", NOTIFY_UNDO, 3)
		else
			notification.AddLegacy("[DECALS] No preset is copied.", NOTIFY_ERROR, 3)
		end
	end)
	pasteButton:SetPos(10 + (300/2) - 5, 160 + 23 + 23 + 23 + 100 + 30 + 60)
	pasteButton:SetSize(300/2 - 10 - 5, 50)

	local closeButton = BluesDecals.UI.Elements.CreateStandardButton("Close", frame, function()
		frame:Close()
	end)
	closeButton:SetPos(10, 160 + 23 + 23 + 23 + 100 + 30 + 60 + 50 + 10)
	closeButton:SetSize(300 - 20, 50)

end


--[[-------------------------------------------------------------------------
Networking
---------------------------------------------------------------------------]]

net.Receive("BLUESDECALS:OpenMenu", function()
	local e = net.ReadEntity()
	BluesDecals.OpenMenu(e)
end)