local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/XxInsaneX1/ClapperUILibrary/refs/heads/main/GlobedUILibraries.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local KSHit = ReplicatedStorage:WaitForChild("KSHit")

local MaxLowYLevel = -17
local SafePos = Vector3.new(-9, -5.1, -0.1399)

local KillFireDelay = 0.75
local KillTimeout = 30
local KillTeleportBelowAmount = 1
local KillInProgress = false

local VoidGroundThresholdY = -9
local VoidFallingVelocityThreshold = -2

local Window = UI:CreateWindow({
	Name = "SlapBattlesHub",
	Title = "SLAP BATTLES",
	Subtitle = "Hub Loaded",
	ToggleText = "SB",
	Width = 300,
	Height = 300,
	AutoOpen = true,
})

Window:Notify("Slap Battles Fuck Hub", "Loaded successfully.", 3)

local SlapAuraEnabled = false

local function StartSlapAura()
	if SlapAuraEnabled then
		Window:Notify("Slap Aura", "Already activated.", 3)
		return
	end

	SlapAuraEnabled = true

	Window:Notify("Slap Aura", "Activated.", 3)
	loadstring(game:HttpGet("https://raw.githubusercontent.com/XxInsaneX1/ClapperUILibrary/refs/heads/main/SlapAura.lua"))()
end

local function findPlayer(input)
	input = tostring(input or ""):lower()

	if input == "" then
		return nil
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == input then
			return player
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.DisplayName:lower() == input then
			return player
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower():sub(1, #input) == input then
			return player
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		if player.DisplayName:lower():sub(1, #input) == input then
			return player
		end
	end

	return nil
end

local function getTargetPart(player)
	if not player then
		return nil
	end

	local character = player.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")
		or character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("LowerTorso")
end

local function getLocalRoot()
	local character = LocalPlayer.Character

	if not character then
		return nil
	end

	return character:FindFirstChild("HumanoidRootPart")
		or character:FindFirstChild("Torso")
		or character:FindFirstChild("UpperTorso")
end

local function teleportLocalTo(position)
	local character = LocalPlayer.Character
	local root = getLocalRoot()

	if not character or not root then
		return false
	end

	pcall(function()
		root.AssemblyLinearVelocity = Vector3.zero
		root.AssemblyAngularVelocity = Vector3.zero
	end)

	pcall(function()
		character:PivotTo(CFrame.new(position))
	end)

	return true
end

local function teleportBackSafe()
	return teleportLocalTo(SafePos)
end

local function isTargetBelowLimit(target)
	local part = getTargetPart(target)

	if not part then
		return true
	end

	return part.Position.Y <= MaxLowYLevel
end

local function isPartOverVoidWhileFalling(target, part)
	if not part then
		return true
	end

	local currentY = part.Position.Y

	if currentY <= MaxLowYLevel then
		return true
	end

	local velocityY = part.AssemblyLinearVelocity.Y

	if velocityY > VoidFallingVelocityThreshold then
		return false
	end

	if currentY <= VoidGroundThresholdY then
		return true
	end

	local rayDistance = currentY - VoidGroundThresholdY

	if rayDistance <= 0 then
		return true
	end

	local ignoreList = {}

	if LocalPlayer.Character then
		table.insert(ignoreList, LocalPlayer.Character)
	end

	if target and target.Character then
		table.insert(ignoreList, target.Character)
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = ignoreList
	params.IgnoreWater = true

	pcall(function()
		params.RespectCanCollide = true
	end)

	local result = Workspace:Raycast(
		part.Position,
		Vector3.new(0, -rayDistance, 0),
		params
	)

	return result == nil
end

local function getHiddenPositionUnderTarget(part)
	local targetPos = part.Position

	local hiddenY = MaxLowYLevel - KillTeleportBelowAmount

	return Vector3.new(
		targetPos.X,
		hiddenY,
		targetPos.Z
	)
end

local function killPlayerByName(username)
	if KillInProgress then
		Window:Notify("Kill Player", "Another kill attempt is already running.", 4)
		return
	end

	local target = findPlayer(username)

	if not target then
		Window:Notify("Kill Player", "Player not found.", 4)
		return
	end

	if target == LocalPlayer then
		Window:Notify("Kill Player", "You cannot target yourself.", 4)
		return
	end

	local part = getTargetPart(target)

	if not part then
		Window:Notify("Kill Player", "Target character part not found.", 4)
		return
	end

	if not getLocalRoot() then
		Window:Notify("Kill Player", "Your character root was not found.", 4)
		return
	end

	KillInProgress = true

	Window:Notify("Kill Player", "Starting on " .. target.Name .. ".", 3)

	task.spawn(function()
		local startedAt = os.clock()
		local success = false
		local lastError = nil
		local lastFire = 0

		while KillInProgress do
			if not target.Parent then
				lastError = "Target left the game."
				break
			end

			part = getTargetPart(target)

			if not part then
				lastError = "Target character disappeared."
				break
			end

			if isTargetBelowLimit(target) then
				success = true
				break
			end

			if isPartOverVoidWhileFalling(target, part) then
				success = true
				break
			end

			if os.clock() - startedAt >= KillTimeout then
				lastError = "Timed out."
				break
			end

			local hiddenPos = getHiddenPositionUnderTarget(part)

			teleportLocalTo(hiddenPos)

			if isPartOverVoidWhileFalling(target, part) then
				success = true
				break
			end

			if os.clock() - lastFire >= KillFireDelay then
				lastFire = os.clock()

				local ok, err = pcall(function()
					KSHit:FireServer(part)
				end)

				if not ok then
					lastError = tostring(err)
				end
			end

			task.wait()
		end

		teleportBackSafe()

		KillInProgress = false

		if success then
			Window:Notify("Kill Player", target.Name .. " is over void/falling below Y " .. tostring(MaxLowYLevel) .. ".", 4)
		else
			Window:Notify("Kill Player", "Stopped: " .. tostring(lastError or "Unknown error"), 5)
		end
	end)
end

----------------------------------------------------------------------
-- Small username prompt modal
----------------------------------------------------------------------

local function create(className, props)
	local inst = Instance.new(className)

	for prop, value in pairs(props or {}) do
		inst[prop] = value
	end

	return inst
end

local function openKillPrompt()
	local gui = Window.Gui

	if not gui then
		return
	end

	local existing = gui:FindFirstChild("KillPrompt")

	if existing then
		existing:Destroy()
	end

	local holder = create("CanvasGroup", {
		Name = "KillPrompt",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(280, 150),
		BackgroundColor3 = Color3.fromRGB(14, 14, 16),
		BorderSizePixel = 0,
		GroupTransparency = 1,
		ZIndex = 50,
	})

	create("UICorner", {
		Parent = holder,
		CornerRadius = UDim.new(0, 14),
	})

	create("UIStroke", {
		Parent = holder,
		Color = Color3.fromRGB(38, 38, 43),
		Thickness = 1,
	})

	create("TextLabel", {
		Parent = holder,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 12),
		Size = UDim2.new(1, -32, 0, 18),
		Font = Enum.Font.GothamBold,
		Text = "KILL PLAYER (Killstreak only for now)",
		TextColor3 = Color3.fromRGB(235, 235, 238),
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 51,
	})

	create("TextLabel", {
		Parent = holder,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 32),
		Size = UDim2.new(1, -32, 0, 16),
		Font = Enum.Font.Gotham,
		Text = "Enter username or display name",
		TextColor3 = Color3.fromRGB(140, 140, 148),
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 51,
	})

	local input = create("TextBox", {
		Parent = holder,
		Position = UDim2.fromOffset(16, 58),
		Size = UDim2.new(1, -32, 0, 34),
		BackgroundColor3 = Color3.fromRGB(26, 26, 30),
		BorderSizePixel = 0,
		Font = Enum.Font.GothamMedium,
		Text = "",
		PlaceholderText = "username here...",
		PlaceholderColor3 = Color3.fromRGB(120, 120, 128),
		TextColor3 = Color3.fromRGB(235, 235, 238),
		TextSize = 12,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Center,
		ZIndex = 51,
	})

	create("UICorner", {
		Parent = input,
		CornerRadius = UDim.new(0, 8),
	})

	create("UIStroke", {
		Parent = input,
		Color = Color3.fromRGB(38, 38, 43),
		Thickness = 1,
	})

	local killButton = create("TextButton", {
		Parent = holder,
		Position = UDim2.fromOffset(16, 104),
		Size = UDim2.new(0.5, -21, 0, 30),
		BackgroundColor3 = Color3.fromRGB(26, 26, 30),
		BorderSizePixel = 0,
		Text = "KILL",
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(235, 235, 238),
		TextSize = 11,
		AutoButtonColor = false,
		ZIndex = 51,
	})

	create("UICorner", {
		Parent = killButton,
		CornerRadius = UDim.new(0, 8),
	})

	create("UIStroke", {
		Parent = killButton,
		Color = Color3.fromRGB(38, 38, 43),
		Thickness = 1,
	})

	local cancelButton = create("TextButton", {
		Parent = holder,
		Position = UDim2.new(0.5, 5, 0, 104),
		Size = UDim2.new(0.5, -21, 0, 30),
		BackgroundColor3 = Color3.fromRGB(26, 26, 30),
		BorderSizePixel = 0,
		Text = "CANCEL",
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.fromRGB(140, 140, 148),
		TextSize = 11,
		AutoButtonColor = false,
		ZIndex = 51,
	})

	create("UICorner", {
		Parent = cancelButton,
		CornerRadius = UDim.new(0, 8),
	})

	create("UIStroke", {
		Parent = cancelButton,
		Color = Color3.fromRGB(38, 38, 43),
		Thickness = 1,
	})

	TweenService:Create(holder, TweenInfo.new(0.16), {
		GroupTransparency = 0,
	}):Play()

	local function closePrompt()
		if not holder or not holder.Parent then
			return
		end

		local fade = TweenService:Create(holder, TweenInfo.new(0.14), {
			GroupTransparency = 1,
		})

		fade:Play()

		local conn
		conn = fade.Completed:Connect(function()
			conn:Disconnect()

			if holder and holder.Parent then
				holder:Destroy()
			end
		end)
	end

	killButton.MouseButton1Click:Connect(function()
		local username = input.Text

		closePrompt()
		killPlayerByName(username)
	end)

	cancelButton.MouseButton1Click:Connect(function()
		closePrompt()
	end)

	input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local username = input.Text

			closePrompt()
			killPlayerByName(username)
		end
	end)

	task.defer(function()
		input:CaptureFocus()
	end)
end

----------------------------------------------------------------------
-- UI Buttons
----------------------------------------------------------------------

Window:AddButton({
	Title = "SLAP AURA",
	Callback = function()
		StartSlapAura()
	end,
})

Window:AddButton({
	Title = "KILL PLAYER",
	Callback = function()
		openKillPrompt()
	end,
})

Window:AddButton({
	Title = "CANCEL KILL",
	Callback = function()
		if KillInProgress then
			KillInProgress = false
			teleportBackSafe()
			Window:Notify("Kill Player", "Cancelled and returned to safe position.", 4)
		else
			Window:Notify("Kill Player", "No kill attempt is running.", 3)
		end
	end,
})

Window:AddSeparator()

Window:AddLabel({
	Text = "Status: Ready",
	Bold = false,
})

Window:Notify("Info", "Click SB to open/close the hub.", 4)
Window:Notify("WARNING", "This hub has not been fully anticheat tested!", 9999)
