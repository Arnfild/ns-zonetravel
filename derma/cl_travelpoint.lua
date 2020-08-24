local PLUGIN = PLUGIN
local PANEL = {}
local toZone_uid
local toZone_name
local toTravelPoint

function PANEL:Init()
	self:SetTitle("")
	self:SetSize(600, 400)
	self:Center()
	self:MakePopup()
	self:ShowCloseButton(false)

	local questionText = self:Add("DLabel")
	questionText:Dock(TOP)
	questionText:DockMargin(0, 75, 0, 0)
	questionText:SetTextColor(color_white)
	questionText:SetExpensiveShadow(1, color_black)
	questionText:SetContentAlignment(8)
	questionText:SetFont("nutChatFont")
	questionText:SizeToContents()
	questionText:SetText(L("zoneTravel_travelOffer") .. " " .. toZone_name .. "?")

	local refuseButton = self:Add("DButton")
	refuseButton:SetText( "Нет" )
	refuseButton:SetFont("nutChatFont")
	refuseButton:SetTextColor( Color(255,255,255) )
	refuseButton:Dock(BOTTOM)
	refuseButton:DockMargin(0, 0, 0, 50)
	refuseButton:SetSize( 100, 45 )
	refuseButton.DoClick = function()
		self:Remove()
	end

	local acceptButton = self:Add("DButton")
	acceptButton:SetText( "Да" )
	acceptButton:SetFont("nutChatFont")
	acceptButton:SetTextColor( Color(255,255,255) )
	acceptButton:Dock(BOTTOM)
	acceptButton:DockMargin(0, 0, 0, 10)
	acceptButton:SetSize( 100, 45 )
	acceptButton.DoClick = function()
		netstream.Start("nutTravelPoint_onTravel", toZone_uid, toTravelPoint_uid)
		self:Remove()
	end
end

vgui.Register("nutTravelPoint", PANEL, "DFrame")

netstream.Hook("nutTravelPoint_onEnter", function(zone_uid, zone_name, travelPoint_uid)
	toZone_uid = zone_uid
	toZone_name = zone_name
	toTravelPoint_uid = travelPoint_uid
	travelPoint = vgui.Create("nutTravelPoint")
end)
