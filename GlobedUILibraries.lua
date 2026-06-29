----------------------------------------------------------------------
-- Global UI Library for "specialized localscript" developers like me :D
-- COPYRIGHT 2026 NO SKIDDING YOU LITTLE FUCKERS
----------------------------------------------------------------------

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local global = if getgenv then getgenv() else _G

local Library = {}

Library.Version = "1.0.0"
Library.Windows = {}

----------------------------------------------------------------------
-- Theme
----------------------------------------------------------------------

Library.Theme = {
	BG      = Color3.fromRGB(14, 14, 16),
	Panel   = Color3.fromRGB(18, 18, 21),
	Field   = Color3.fromRGB(26, 26, 30),
	Border  = Color3.fromRGB(38, 38, 43),
	Text    = Color3.fromRGB(235, 235, 238),
	Subtext = Color3.fromRGB(140, 140, 148),
	Accent  = Color3.fromRGB(255, 255, 255),
	Red     = Color3.fromRGB(255, 90, 90),
	Green   = Color3.fromRGB(120, 255, 150),
}

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------

local function create(className, props)
	local inst = Instance.new(className)

	for prop, value in pairs(props or {}) do
		inst[prop] = value
	end

	return inst
end

local function tween(inst, info, props)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

local function safeDisconnect(conn)
	if conn then
		pcall(function()
			conn:Disconnect()
		end)
	end
end

local function sanitizeNumber(value, minVal, maxVal)
	value = tonumber(value)

	if not value then
		return nil
	end

	if minVal then
		value = math.max(value, minVal)
	end

	if maxVal then
		value = math.min(value, maxVal)
	end

	return value
end

local function flash(stroke, color)
	if not stroke then return end

	local original = stroke.Color
	stroke.Color = color or Library.Theme.Accent

	tween(stroke, TweenInfo.new(0.35), {
		Color = original
	})
end

----------------------------------------------------------------------
-- Toggle primitive
----------------------------------------------------------------------

local function createToggle(parent, initial, callback)
	local Theme = Library.Theme

	local track = create("Frame", {
		Parent = parent,
		Size = UDim2.fromOffset(38, 20),
		BackgroundColor3 = Theme.Field,
		BorderSizePixel = 0,
	})

	create("UICorner", {
		Parent = track,
		CornerRadius = UDim.new(1, 0),
	})

	create("UIStroke", {
		Parent = track,
		Color = Theme.Border,
		Thickness = 1,
	})

	local knob = create("Frame", {
		Parent = track,
		Size = UDim2.fromOffset(16, 16),
		Position = initial and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8),
		BackgroundColor3 = initial and Theme.Accent or Theme.Subtext,
		BorderSizePixel = 0,
	})

	create("UICorner", {
		Parent = knob,
		CornerRadius = UDim.new(1, 0),
	})

	local hitbox = create("TextButton", {
		Parent = track,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
	})

	local state = initial == true

	local function setState(nextState, skipCallback)
		state = nextState == true

		local pos = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)

		tween(knob, TweenInfo.new(0.15), {
			Position = pos,
			BackgroundColor3 = state and Theme.Accent or Theme.Subtext,
		})

		if not skipCallback and callback then
			task.spawn(callback, state)
		end
	end

	hitbox.MouseButton1Click:Connect(function()
		setState(not state, false)
	end)

	return {
		Instance = track,

		Set = function(_, nextState, skipCallback)
			setState(nextState, skipCallback)
		end,

		Get = function()
			return state
		end,
	}
end

----------------------------------------------------------------------
-- Library Window
----------------------------------------------------------------------

function Library:CreateWindow(options)
	options = options or {}

	local Theme = Library.Theme

	local title = options.Title or "SCRIPT HUB"
	local subtitle = options.Subtitle or "Ready"
	local width = options.Width or 300
	local height = options.Height or 486
	local toggleText = options.ToggleText or "UI"
	local resetOnSpawn = options.ResetOnSpawn == true

	local window = {}
	window.Connections = {}
	window.Controls = {}
	window.Open = false
	window.Destroyed = false

	------------------------------------------------------------------
	-- ScreenGui
	------------------------------------------------------------------

	local gui = create("ScreenGui", {
		Name = options.Name or "SleekBlackUI",
		ResetOnSpawn = resetOnSpawn,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui,
	})

	window.Gui = gui

	------------------------------------------------------------------
	-- Notifications
	------------------------------------------------------------------

	local notificationStack = create("Frame", {
		Name = "Notifications",
		Parent = gui,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -18, 0, 18),
		Size = UDim2.fromOffset(250, 320),
		BackgroundTransparency = 1,
	})

	create("UIListLayout", {
		Parent = notificationStack,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Top,
	})

	local notificationCount = 0

	function window:Notify(titleText, bodyText, duration)
		if window.Destroyed then return end

		notificationCount += 1

		local toast = create("CanvasGroup", {
			Name = "Toast",
			Parent = notificationStack,
			LayoutOrder = -notificationCount,
			Size = UDim2.fromOffset(250, 68),
			BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0,
			GroupTransparency = 1,
		})

		create("UICorner", {
			Parent = toast,
			CornerRadius = UDim.new(0, 12),
		})

		create("UIStroke", {
			Parent = toast,
			Color = Theme.Border,
			Thickness = 1,
		})

		create("TextLabel", {
			Parent = toast,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 10),
			Size = UDim2.new(1, -28, 0, 16),
			Font = Enum.Font.GothamBold,
			Text = tostring(titleText or "Notification"),
			TextColor3 = Theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		create("TextLabel", {
			Parent = toast,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(14, 30),
			Size = UDim2.new(1, -28, 0, 28),
			Font = Enum.Font.Gotham,
			Text = tostring(bodyText or ""),
			TextColor3 = Theme.Subtext,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		})

		tween(toast, TweenInfo.new(0.18), {
			GroupTransparency = 0,
		})

		task.delay(duration or 3, function()
			if not toast.Parent then return end

			local fade = tween(toast, TweenInfo.new(0.16), {
				GroupTransparency = 1,
			})

			local conn
			conn = fade.Completed:Connect(function()
				safeDisconnect(conn)

				if toast.Parent then
					toast:Destroy()
				end
			end)
		end)
	end

	------------------------------------------------------------------
	-- Toggle button
	------------------------------------------------------------------

	local toggleButton = create("TextButton", {
		Name = "ToggleButton",
		Parent = gui,
		Size = UDim2.fromOffset(46, 46),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = options.TogglePosition or UDim2.new(0, 16, 0.5, 0),
		BackgroundColor3 = Theme.Panel,
		Text = toggleText,
		Font = Enum.Font.GothamBold,
		TextSize = 14,
		TextColor3 = Theme.Text,
		AutoButtonColor = false,
		BorderSizePixel = 0,
	})

	create("UICorner", {
		Parent = toggleButton,
		CornerRadius = UDim.new(1, 0),
	})

	create("UIStroke", {
		Parent = toggleButton,
		Color = Theme.Border,
		Thickness = 1,
	})

	table.insert(window.Connections, toggleButton.MouseEnter:Connect(function()
		tween(toggleButton, TweenInfo.new(0.12), {
			BackgroundColor3 = Theme.Field,
		})
	end))

	table.insert(window.Connections, toggleButton.MouseLeave:Connect(function()
		tween(toggleButton, TweenInfo.new(0.12), {
			BackgroundColor3 = Theme.Panel,
		})
	end))

	------------------------------------------------------------------
	-- Main panel
	------------------------------------------------------------------

	local panel = create("CanvasGroup", {
		Name = "Panel",
		Parent = gui,
		Size = UDim2.fromOffset(width, height),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = options.Position or UDim2.new(0, 72, 0.5, 0),
		BackgroundColor3 = Theme.BG,
		BorderSizePixel = 0,
		Visible = false,
		GroupTransparency = 1,
	})

	window.Panel = panel

	create("UICorner", {
		Parent = panel,
		CornerRadius = UDim.new(0, 14),
	})

	create("UIStroke", {
		Parent = panel,
		Color = Theme.Border,
		Thickness = 1,
	})

	local header = create("Frame", {
		Name = "Header",
		Parent = panel,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Active = true,
	})

	local titleLabel = create("TextLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 6),
		Size = UDim2.new(1, -70, 0, 16),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	local subtitleLabel = create("TextLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 23),
		Size = UDim2.new(1, -70, 0, 14),
		Font = Enum.Font.Gotham,
		Text = subtitle,
		TextColor3 = Theme.Subtext,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})

	create("Frame", {
		Parent = panel,
		Position = UDim2.fromOffset(16, 44),
		Size = UDim2.new(1, -32, 0, 1),
		BackgroundColor3 = Theme.Border,
		BorderSizePixel = 0,
	})

	function window:SetTitle(text)
		titleLabel.Text = tostring(text)
	end

	function window:SetSubtitle(text, active)
		subtitleLabel.Text = tostring(text)
		subtitleLabel.TextColor3 = active and Theme.Text or Theme.Subtext
	end

	------------------------------------------------------------------
	-- Loader
	------------------------------------------------------------------

	local body = create("Frame", {
		Parent = panel,
		Position = UDim2.fromOffset(0, 53),
		Size = UDim2.new(1, 0, 1, -53),
		BackgroundTransparency = 1,
	})

	local loaderContainer = create("Frame", {
		Name = "Loader",
		Parent = body,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = false,
	})

	local ring = create("Frame", {
		Name = "Ring",
		Parent = loaderContainer,
		Size = UDim2.fromOffset(34, 34),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1,
	})

	create("UICorner", {
		Parent = ring,
		CornerRadius = UDim.new(1, 0),
	})

	local ringStroke = create("UIStroke", {
		Parent = ring,
		Color = Theme.Text,
		Thickness = 3,
	})

	create("UIGradient", {
		Parent = ringStroke,
		Color = ColorSequence.new(Theme.Text),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.85, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		}),
	})

	local spinTween

	local function startSpin()
		if spinTween then
			spinTween:Cancel()
		end

		ring.Rotation = 0

		spinTween = TweenService:Create(
			ring,
			TweenInfo.new(0.9, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, false),
			{
				Rotation = 360,
			}
		)

		spinTween:Play()
	end

	local function stopSpin()
		if spinTween then
			spinTween:Cancel()
			spinTween = nil
		end
	end

	------------------------------------------------------------------
	-- Content
	------------------------------------------------------------------

	local contentContainer = create("ScrollingFrame", {
		Name = "Content",
		Parent = body,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Border,
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		Visible = false,
	})

	create("UIPadding", {
		Parent = contentContainer,
		PaddingLeft = UDim.new(0, 16),
		PaddingRight = UDim.new(0, 16),
		PaddingTop = UDim.new(0, 14),
		PaddingBottom = UDim.new(0, 14),
	})

	local list = create("UIListLayout", {
		Parent = contentContainer,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 10),
	})

	window.Content = contentContainer

	local loaderToken = 0

	local function showLoaderThenContent()
		loaderToken += 1
		local thisToken = loaderToken

		loaderContainer.Visible = true
		contentContainer.Visible = false

		startSpin()

		task.delay(options.LoaderTime or 0.45, function()
			if thisToken ~= loaderToken then return end

			stopSpin()

			loaderContainer.Visible = false
			contentContainer.Visible = true
		end)
	end

	------------------------------------------------------------------
	-- Open / Close
	------------------------------------------------------------------

	function window:OpenWindow()
		if window.Destroyed then return end

		panel.Visible = true
		panel.GroupTransparency = 1

		tween(panel, TweenInfo.new(0.18), {
			GroupTransparency = 0,
		})

		showLoaderThenContent()

		window.Open = true
	end

	function window:CloseWindow()
		if window.Destroyed then return end

		loaderToken += 1
		stopSpin()

		local fade = tween(panel, TweenInfo.new(0.15), {
			GroupTransparency = 1,
		})

		local conn
		conn = fade.Completed:Connect(function()
			safeDisconnect(conn)

			if not window.Open then
				panel.Visible = false
			end
		end)

		window.Open = false
	end

	function window:ToggleWindow()
		if window.Open then
			window:CloseWindow()
		else
			window:OpenWindow()
		end
	end

	table.insert(window.Connections, toggleButton.MouseButton1Click:Connect(function()
		window:ToggleWindow()
	end))

	------------------------------------------------------------------
	-- Dragging
	------------------------------------------------------------------

	local dragging = false
	local dragStart
	local startPos

	table.insert(window.Connections, header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPos = panel.Position

			local changedConn
			changedConn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					safeDisconnect(changedConn)
				end
			end)
		end
	end))

	table.insert(window.Connections, UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		local delta = input.Position - dragStart

		panel.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end))

	------------------------------------------------------------------
	-- Row: Toggle
	------------------------------------------------------------------

	function window:AddToggle(options)
		options = options or {}

		local row = create("Frame", {
			Parent = contentContainer,
			Size = UDim2.new(1, 0, 0, 38),
			BackgroundTransparency = 1,
			LayoutOrder = options.Order or #window.Controls + 1,
		})

		local titleText = create("TextLabel", {
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 1),
			Size = UDim2.new(1, -54, 0, 16),
			Font = Enum.Font.GothamBold,
			Text = options.Title or "Toggle",
			TextColor3 = Theme.Text,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local statusText = create("TextLabel", {
			Parent = row,
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, 20),
			Size = UDim2.new(1, -54, 0, 14),
			Font = Enum.Font.Gotham,
			Text = options.Subtitle or "Off",
			TextColor3 = Theme.Subtext,
			TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local toggle = createToggle(row, options.Default == true, function(state)
			if options.Callback then
				options.Callback(state)
			end
		end)

		toggle.Instance.AnchorPoint = Vector2.new(1, 0.5)
		toggle.Instance.Position = UDim2.new(1, 0, 0.5, 0)

		local control = {
			Type = "Toggle",
			Row = row,
			Toggle = toggle,

			Set = function(_, state, skipCallback)
				toggle:Set(state, skipCallback)
			end,

			Get = function()
				return toggle:Get()
			end,

			SetTitle = function(_, text)
				titleText.Text = tostring(text)
			end,

			SetStatus = function(_, text, active)
				statusText.Text = tostring(text)
				statusText.TextColor3 = active and Theme.Text or Theme.Subtext
			end,

			Destroy = function()
				row:Destroy()
			end,
		}

		table.insert(window.Controls, control)
		return control
	end

	------------------------------------------------------------------
	-- Row: Textbox / Number input
	------------------------------------------------------------------

	function window:AddTextbox(options)
		options = options or {}

		local row = create("Frame", {
			Parent = contentContainer,
			Size = UDim2.new(1, 0, 0, 34),
			BackgroundTransparency = 1,
			LayoutOrder = options.Order or #window.Controls + 1,
		})

		local label = create("TextLabel", {
			Parent = row,
			BackgroundTransparency = 1,
			Size = UDim2.new(0.58, 0, 1, 0),
			Font = Enum.Font.Gotham,
			Text = options.Title or "Input",
			TextColor3 = Theme.Subtext,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})

		local field = create("TextBox", {
			Parent = row,
			Position = UDim2.new(0.58, 8, 0, 0),
			Size = UDim2.new(0.42, -8, 1, 0),
			BackgroundColor3 = Theme.Field,
			BorderSizePixel = 0,
			Font = Enum.Font.GothamMedium,
			Text = tostring(options.Default or ""),
			TextColor3 = Theme.Text,
			TextSize = 12,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center,
			PlaceholderText = options.Placeholder or "",
			PlaceholderColor3 = Theme.Subtext,
		})

		create("UICorner", {
			Parent = field,
			CornerRadius = UDim.new(0, 8),
		})

		local stroke = create("UIStroke", {
			Parent = field,
			Color = Theme.Border,
			Thickness = 1,
		})

		local value = options.Default

		field.FocusLost:Connect(function()
			local finalValue = field.Text

			if options.Numeric then
				local number = sanitizeNumber(field.Text, options.Min, options.Max)

				if number == nil then
					field.Text = tostring(value or options.Default or "")
					return
				end

				finalValue = number
				field.Text = tostring(number)
			end

			value = finalValue
			flash(stroke, Theme.Accent)

			if options.Callback then
				task.spawn(options.Callback, finalValue)
			end
		end)

		local control = {
			Type = "Textbox",
			Row = row,
			Field = field,

			Set = function(_, newValue, skipCallback)
				value = newValue
				field.Text = tostring(newValue)

				if not skipCallback and options.Callback then
					task.spawn(options.Callback, newValue)
				end
			end,

			Get = function()
				return value
			end,

			SetTitle = function(_, text)
				label.Text = tostring(text)
			end,

			Destroy = function()
				row:Destroy()
			end,
		}

		table.insert(window.Controls, control)
		return control
	end

	function window:AddNumberInput(options)
		options = options or {}
		options.Numeric = true
		return window:AddTextbox(options)
	end

	------------------------------------------------------------------
	-- Row: Button
	------------------------------------------------------------------

	function window:AddButton(options)
		options = options or {}

		local button = create("TextButton", {
			Parent = contentContainer,
			Size = UDim2.new(1, 0, 0, options.Height or 32),
			BackgroundColor3 = Theme.Field,
			BorderSizePixel = 0,
			Text = options.Title or "BUTTON",
			Font = Enum.Font.GothamBold,
			TextSize = 11,
			TextColor3 = options.TextColor or Theme.Subtext,
			AutoButtonColor = false,
			LayoutOrder = options.Order or #window.Controls + 1,
		})

		create("UICorner", {
			Parent = button,
			CornerRadius = UDim.new(0, 8),
		})

		local stroke = create("UIStroke", {
			Parent = button,
			Color = Theme.Border,
			Thickness = 1,
		})

		local enter = button.MouseEnter:Connect(function()
			tween(button, TweenInfo.new(0.12), {
				BackgroundColor3 = Color3.fromRGB(31, 31, 36),
				TextColor3 = Theme.Text,
			})
		end)

		local leave = button.MouseLeave:Connect(function()
			tween(button, TweenInfo.new(0.12), {
				BackgroundColor3 = Theme.Field,
				TextColor3 = options.TextColor or Theme.Subtext,
			})
		end)

		local click = button.MouseButton1Click:Connect(function()
			flash(stroke, Theme.Accent)

			if options.Callback then
				task.spawn(options.Callback)
			end
		end)

		local control = {
			Type = "Button",
			Button = button,

			SetTitle = function(_, text)
				button.Text = tostring(text)
			end,

			Destroy = function()
				safeDisconnect(enter)
				safeDisconnect(leave)
				safeDisconnect(click)
				button:Destroy()
			end,
		}

		table.insert(window.Controls, control)
		return control
	end

	------------------------------------------------------------------
	-- Row: Label
	------------------------------------------------------------------

	function window:AddLabel(options)
		options = options or {}

		local label = create("TextLabel", {
			Parent = contentContainer,
			Size = UDim2.new(1, 0, 0, options.Height or 24),
			BackgroundTransparency = 1,
			Font = options.Bold and Enum.Font.GothamBold or Enum.Font.Gotham,
			Text = options.Text or "Label",
			TextColor3 = options.Color or Theme.Subtext,
			TextSize = options.TextSize or 12,
			TextXAlignment = options.Align or Enum.TextXAlignment.Left,
			TextWrapped = true,
			LayoutOrder = options.Order or #window.Controls + 1,
		})

		local control = {
			Type = "Label",
			Label = label,

			Set = function(_, text)
				label.Text = tostring(text)
			end,

			Destroy = function()
				label:Destroy()
			end,
		}

		table.insert(window.Controls, control)
		return control
	end

	------------------------------------------------------------------
	-- Row: Separator
	------------------------------------------------------------------

	function window:AddSeparator()
		local line = create("Frame", {
			Parent = contentContainer,
			Size = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = Theme.Border,
			BorderSizePixel = 0,
			LayoutOrder = #window.Controls + 1,
		})

		local control = {
			Type = "Separator",
			Line = line,

			Destroy = function()
				line:Destroy()
			end,
		}

		table.insert(window.Controls, control)
		return control
	end

	------------------------------------------------------------------
	-- Destroy
	------------------------------------------------------------------

	function window:Destroy()
		if window.Destroyed then return end
		window.Destroyed = true

		for _, conn in ipairs(window.Connections) do
			safeDisconnect(conn)
		end

		table.clear(window.Connections)

		for _, control in ipairs(window.Controls) do
			if control.Destroy then
				pcall(control.Destroy, control)
			end
		end

		table.clear(window.Controls)

		stopSpin()

		if gui and gui.Parent then
			gui:Destroy()
		end
	end

	table.insert(Library.Windows, window)

	if options.AutoOpen then
		task.defer(function()
			window:OpenWindow()
		end)
	end

	return window
end

----------------------------------------------------------------------
-- Global library functions
----------------------------------------------------------------------

function Library:NotifyAll(title, body, duration)
	for _, window in ipairs(self.Windows) do
		if window and not window.Destroyed and window.Notify then
			window:Notify(title, body, duration)
		end
	end
end

function Library:DestroyAll()
	for _, window in ipairs(self.Windows) do
		if window and window.Destroy then
			pcall(function()
				window:Destroy()
			end)
		end
	end

	table.clear(self.Windows)
end

global.__SleekBlackUILibrary = Library

return Library
