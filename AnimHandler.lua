local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Handler = {}
Handler.__index = Handler

local Playing = nil
local Last = nil

function Handler:Humanoid(Character)
    Character = Character or (LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait())
    return Character:FindFirstChildOfClass("Humanoid")
end

local function getPriority(p)
    if typeof(p) == "string" then
        return Enum.AnimationPriority[p] or Enum.AnimationPriority.Action
    elseif typeof(p) == "number" then
        return p
    end
    return Enum.AnimationPriority.Action
end

function Handler:Stop(Character: Model)
    local Hum = self:Humanoid(Character)
    if not Hum then return end

    for _, Track in pairs(Hum:GetPlayingAnimationTracks()) do
        Track:Stop()
    end
end

function Handler:AnimPlay(Data)
    if typeof(Data) ~= "table" or not Data.Id then return end

    local Hum = self:Humanoid(LocalPlayer)
    if not Hum or not Hum.Parent then return end

    local ID = tostring(Data.Id)

    -- stop same anim if already playing
    for _, Track in pairs(Hum:GetPlayingAnimationTracks()) do
        if Track.Animation and Track.Animation.AnimationId:match("rbxassetid://" .. ID) then
            Track:Stop()
        end
    end

    -- stop current
    if Data.StopCurrent and Playing then
        pcall(function()
            Playing:Stop()
            Playing:Destroy()
        end)
        Playing = nil
    end

    -- save last
    if Data.ReturnCurrent and Playing then
        Last = Playing
    end

    local Animation = Instance.new("Animation")
    Animation.AnimationId = "rbxassetid://" .. ID

    local Track = Hum:LoadAnimation(Animation)

    Track.Priority = getPriority(Data.Priority)

    Track:Play(Data.Smoothing or 0)

    Track:AdjustSpeed(Data.PlaySpeed or 1)

    if Data.Time then
        Track.TimePosition = Data.Time
    end

    Playing = Track

    Animation:Destroy()

    return Track
end

function Handler:AnimStop(ID: string, Speed: number?)
    local Hum = self:Humanoid(LocalPlayer)
    if not Hum or not Hum.Parent then return end

    for _, Track in pairs(Hum:GetPlayingAnimationTracks()) do
        if Track.Animation and Track.Animation.AnimationId:match("rbxassetid://" .. ID) then
            Track:Stop(Speed or 0)
        end
    end
end

function Handler:IsAnimPlaying(ID: string): boolean
    local Hum = self:Humanoid(LocalPlayer)
    if not Hum or not Hum.Parent then return false end

    for _, Track in pairs(Hum:GetPlayingAnimationTracks()) do
        if Track.Animation 
        and Track.Animation.AnimationId:match("rbxassetid://" .. ID) 
        and Track.IsPlaying then
            return true
        end
    end

    return false
end

function Handler:ReturnLast()
    if Last then
        Last:Play()
    end
end

-- re-exec safety
if _G.AnimHandler then
    pcall(function()
        _G.AnimHandler:Stop()
    end)
end

_G.AnimHandler = Handler

return Handler
