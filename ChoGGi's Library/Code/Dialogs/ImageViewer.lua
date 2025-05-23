-- See LICENSE for terms

-- Displays images

local ChoGGi_Funcs = ChoGGi_Funcs
local MeasureImage = UIL.MeasureImage
local T = T
local PopupToggle = ChoGGi_Funcs.Common.PopupToggle
local Random = ChoGGi_Funcs.Common.Random
local RetParamsParents = ChoGGi_Funcs.Common.RetParamsParents
local Translate = ChoGGi_Funcs.Common.Translate

local blacklist, g_env = ChoGGi.blacklist
function OnMsg.ChoGGi_UpdateBlacklistFuncs(env)
	blacklist = false
	g_env = env
end

local GetParentOfKind = ChoGGi_Funcs.Common.GetParentOfKind
local function GetRootDialog(dlg)
	return dlg.parent_dialog or GetParentOfKind(dlg, "ChoGGi_DlgImageViewer")
end
DefineClass.ChoGGi_DlgImageViewer = {
	__parents = {"ChoGGi_XWindow"},

	dialog_width = 700.0,
	dialog_height = 700.0,
	-- Index list of images
	images = false,
	-- Index list of popup menu items
	image_menu_popup = false,
	-- viewed image path
	image_path = false,
	-- Id for togglepopup
	idImageMenu = false,
}

function ChoGGi_DlgImageViewer:Init(parent, context)
	local g_Classes = g_Classes

	self.images = context.obj
	if type(self.images) ~= "table" then
		self.images = {
			{
				name = self.images,
				path = self.images,
			},
		}
	end

	self.idImageMenu = Random()
	self.title = T(302535920001469--[[Image Viewer]])
	self.prefix = self.title

	-- By the Power of Grayskull!
	self:AddElements(parent, context)

	self.idButtonContainer = g_Classes.ChoGGi_XDialogSection:new({
		Id = "idButtonContainer",
		Dock = "top",
		-- dark gray
		Background = -13158858,
	}, self.idDialog)

	self:BuildImageMenuPopup()
	self.idImages = g_Classes.ChoGGi_XComboButton:new({
		Id = "idImages",
		Text = T(3794--[[Image]]),
		OnMouseButtonDown = self.idImages_OnMouseButtonDown,
		Dock = "left",
	}, self.idButtonContainer)

	self.idImageSize = g_Classes.ChoGGi_XText:new({
		Id = "idImageSize",
		Dock = "left",
		VAlign = "center",
	}, self.idButtonContainer)

	-- checkered bg
	self.idImageFrame = g_Classes.XFrame:new({
		Id = "idImageFrame",
		TileFrame = true,
		Image = "CommonAssets/UI/checker-pattern-40.tga",
	}, self.idDialog)

	self.idImage = g_Classes.XFrame:new({
		Id = "idImage",
	}, self.idImageFrame)

	-- first up
	local wh = self:SetImageFile(self.images[1])

	-- only one image and it's not a valid image so close dlg
	if wh == 0 and #self.images == 1 then
		print(Translate(302535920000109--[[Invalid Image]]))
		ChoGGi_Funcs.Common.MsgPopup(
			T(302535920000109--[[Invalid Image]]),
			self.title
		)
		self:Close()
	end

	self:PostInit(context.parent)
end

function ChoGGi_DlgImageViewer:ExportImage()
	if ChoGGi.blacklist then
		ChoGGi_Funcs.Common.BlacklistMsg("ChoGGi_DlgImageViewer:ExportImage()")
		return
	end

	-- need to reverse string so it finds the last /, since find looks ltr
	local slash = self.image_path:reverse():find("/")
	if slash then
		local name = self.image_path:sub(-slash + 1)
		local dest_path = "AppData/" .. name
		-- If error (devs swapped all? the images from .tga to .dds, but ref them as .tga)
		if g_env.AsyncCopyFile(self.image_path, dest_path) then
			g_env.AsyncCopyFile(self.image_path:gsub(".tga", ".dds"), dest_path)
		end
		local msg = ConvertToOSPath(dest_path)
		print(msg)
		ChoGGi_Funcs.Common.MsgPopup(
			msg,
			T(302535920001449--[[Export]])
		)
	end
end

function ChoGGi_DlgImageViewer:BuildImageMenuPopup()
	local images = {}
	for i = 1, #self.images do
		local image = self.images[i]
		images[i] = {
			name = image.path,
			mouseover = function()
				self:SetImageFile(image)
			end,
		}
	end
	images[#images+1] = {is_spacer = true}
	images[#images+1] = {
		name = T(302535920001449--[[Export]]),
		hint = T{302535920000219--[["Export viewed image to <color ChoGGi_green><path></color>."]],
			path = ConvertToOSPath("AppData"),
		},
		clicked = function()
			self:ExportImage()
		end,
	}
	self.image_menu_popup = images
end

function ChoGGi_DlgImageViewer:SetImageFile(image)
	self = GetRootDialog(self)
	self.idImage:SetImage(image.path)
	self.image_path = image.path
	self.idCaption:SetTitle(self, image.path)

	local w, h = MeasureImage(image.path)

	if image.name and image.name ~= "" then
		self.idImageSize:SetText(w .. "x" .. h .. " (" .. image.name .. ")")
	else
		self.idImageSize:SetText(w .. "x" .. h)
	end
	return w+h
end

function ChoGGi_DlgImageViewer:idImages_OnMouseButtonDown()
	local dlg = GetRootDialog(self)
	PopupToggle(self, dlg.idImageMenu, dlg.image_menu_popup, "left")
end

-- Use to open a dialog
function ChoGGi_Funcs.Common.OpenInImageViewerDlg(obj, parent, ...)
	if not obj then
		return
	end

	local params, parent_type
	params, parent, parent_type = RetParamsParents(parent, params, ...)

	if not IsKindOf(parent, "XWindow") then
		parent = nil
	end

	params.obj = obj
	params.parent = parent

	return ChoGGi_DlgImageViewer:new({}, terminal.desktop, params)
end
-- used for console rules, so they don't spam the log
local OpenInImageViewerDlg = ChoGGi_Funcs.Common.OpenInImageViewerDlg
function OpenImageViewer(...)
	OpenInImageViewerDlg(...)
end

