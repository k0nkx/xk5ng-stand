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

function Handler:AnimPlay(Data)
    if typeof(Data) ~= "table" or not Data.Id then return end

    local Hum = self:Humanoid(LocalPlayer)
    if not Hum or not Hum.Parent then return end

    local ID = tostring(Data.Id)

    -- remove same anim if already playing
    for _, Track in pairs(Hum:GetPlayingAnimationTracks()) do
        if Track.Animation and Track.Animation.AnimationId:match("rbxassetid://" .. ID) then
            Track:Stop(0)
        end
    end

    -- switching logic
    if Playing then
        if Data.SmoothSwitch then
            -- smooth fade out old
            pcall(function()
                Playing:Stop(Data.SwitchFade or 0.25)
            end)
        else
            -- instant stop
            pcall(function()
                Playing:Stop(0)
                Playing:Destroy()
            end)
        end
    end

    -- save last
    if Data.ReturnCurrent and Playing then
        Last = Playing
    end

    local Animation = Instance.new("Animation")
    Animation.AnimationId = "rbxassetid://" .. ID

    local Track = Hum:LoadAnimation(Animation)

    Track.Priority = getPriority(Data.Priority)

    -- smooth fade in if enabled
    local fadeIn = Data.SmoothSwitch and (Data.SwitchFade or 0.25) or 0

    Track:Play(fadeIn)

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

function Handler:StopAll()
    local Hum = self:Humanoid(LocalPlayer)
    if not Hum then return end

    for _, Track in pairs(Hum:GetPlayingAnimationTracks()) do
        Track:Stop(0)
    end

    Playing = nil
end

function Handler:ReturnLast()
    if Last then
        Last:Play()
    end
end

-- re-exec safety
if _G.AnimHandler then
    pcall(function()
        _G.AnimHandler:StopAll()
    end)
end

_G.AnimHandler = Handler

return Handler
