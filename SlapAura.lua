-- Don't skid it you stupid fuckers i made it myself

local function IsGlove()
    local Player = game.Players.LocalPlayer
    local Backpack = Player.Backpack
    local Character = Player.Character
    local Lobby = workspace.Lobby:GetChildren()

    for _, glove in ipairs(Lobby) do
        if Backpack:FindFirstChild(glove.Name) then
            return true
        end

        if Character and Character:FindFirstChild(glove.Name) then
            return true
        end
    end

    return false
end

local function FindEventToFire()
    local StoredPlayerVal = game.Players.LocalPlayer

    if IsGlove() then
        local Glove = StoredPlayerVal.Backpack:FindFirstChildOfClass("Tool")
            or (StoredPlayerVal.Character and StoredPlayerVal.Character:FindFirstChildOfClass("Tool"))

        if Glove then
            local nameOfGlove = Glove.Name
        if nameOfGlove == "Default" then return game.ReplicatedStorage.b end
        if nameOfGlove == "Killstreak" then return game.ReplicatedStorage.KSHit end
        if nameOfGlove == "Speedrun" then return game.ReplicatedStorage.Speedrunhit end
            for _, event in ipairs(game:GetService("ReplicatedStorage"):GetChildren()) do
                if event.Name:find(nameOfGlove) and event.Name:find("Hit") and event:IsA("RemoteEvent") then
                    return event 
                end
            end
        end
    end

    return nil
end

local CooldownPerPerson = 0.75
local AuraDebounceHitPpl = {}

local ok, err = pcall(function()

    local AuraRange = 20 -- STUDS

    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local AuraPart -- track current aura part

    local function SetupAura(character)
        local hrp = character:WaitForChild("HumanoidRootPart")
        character:WaitForChild("Humanoid")

        -- Destroy old aura part if it exists
        if AuraPart and AuraPart.Parent then
            AuraPart:Destroy()
        end

        AuraPart = Instance.new("Part")
        AuraPart.Parent = workspace
        AuraPart.CanTouch = true
        AuraPart.CanCollide = false
        AuraPart.Massless = true
        AuraPart.Transparency = 0.4
        AuraPart.Size = Vector3.new(AuraRange, AuraRange, AuraRange)
        AuraPart.CFrame = hrp.CFrame

        local weld = Instance.new("WeldConstraint")
        weld.Parent = AuraPart
        weld.Part0 = AuraPart
        weld.Part1 = hrp

    
        AuraPart.Touched:Connect(function(PartThatHit)
        
            if PartThatHit:IsDescendantOf(character) then
                return
            end

            if not IsGlove() then
                return
            end

            local Victim = PartThatHit.Parent
            local VictimHum = Victim and Victim:FindFirstChild("Humanoid")

            if not VictimHum then
                return
            end

            if AuraDebounceHitPpl[VictimHum] then
                return
            end

            AuraDebounceHitPpl[VictimHum] = true
            local eventToFire = FindEventToFire()
            if eventToFire then
                 eventToFire:FireServer(PartThatHit)
            end

            task.delay(CooldownPerPerson, function()
                AuraDebounceHitPpl[VictimHum] = nil
            end)
        end)
    end

 
    if player.Character then
        SetupAura(player.Character)
    end

 
    player.CharacterAdded:Connect(SetupAura)

end)

if ok then
    print("Slap Aura attempt execution successful!")
else
    print("Your script is heavily retarded! " .. tostring(err))
end
