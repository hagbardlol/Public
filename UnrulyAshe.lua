--[[
    First Release By Thorn @ 20.Sept.2020    
]]

if Player.CharName ~= "Ashe" then return end

module("Unruly Ashe", package.seeall, log.setup)
clean.module("Unruly Ashe", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyAshe.lua", "1.0.3")

local clock = os.clock
local insert = table.insert

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local Spell = _G.Libs.Spell

local _Q = Spell.Active({
    Slot = Enums.SpellSlots.Q,
    Delay = 0,
    Speed = 2500
})
local _W = Spell.Skillshot({
    Slot = Enums.SpellSlots.W,
    Range = 1300,
    Delay = 0.25,
    Speed = 1500,
    Radius = 20,
    Type = "Cone",
    Collisions = {Heroes=true, Minions=true, WindWall=true},
    UseHitbox = true
})
local _E = Spell.Skillshot({
    Slot = Enums.SpellSlots.E,
    Range = math.huge,
    Delay = 0.25,
    Speed = 1600,
    Radius = 500,
    Type = "Linear",
})
local _R = Spell.Skillshot({
    Slot = Enums.SpellSlots.R,
    Range = math.huge,
    Delay = 0.25,
    Speed = 1600,
    Radius = 130,
    Type = "Linear",
    Collisions = {Heroes=true, WindWall=true},
    UseHitbox = true
})

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Ashe = {}

local function CountAlliesInRange(pos, range)
    local count = 0
    for k, v in pairs(ObjManager.Get("ally", "heroes")) do
        local hero = v.AsHero
        if hero and hero:Distance(pos) < range and hero.IsAlive then
            count = count + 1
        end
    end
    return count
end

function Ashe.LoadMenu()
    Menu.RegisterMenu("UnrulyAshe", "Unruly Ashe", function()
        Menu.ColumnLayout("cols", "cols", 2, true, function()
            Menu.ColoredText("Combo", 0xFFD700FF, true)
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true)
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)

            Menu.NextColumn()

            Menu.ColoredText("Harass", 0xFFD700FF, true)
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true)
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
            Menu.Checkbox("Harass.UseE", "Use [E]", false) 
        end)        

        Menu.Separator()
    
        Menu.ColoredText("Misc Options", 0xFFD700FF, true)
        Menu.Checkbox("Misc.AutoR", "Auto [R] Immobile/Dash")
        Menu.Keybind("Misc.ForceR", "Force Ult Key", string.byte('T'))
        Menu.Slider("Misc.MaxDistR", "Ult Max Distance", 1500, 400, 3000, 100)
            
        Menu.Separator()

        Menu.ColoredText("Draw Options", 0xFFD700FF, true)
        Menu.Checkbox("Draw.W.Enabled",   "Draw [W] Range")
        Menu.ColorPicker("Draw.W.Color", "Draw [W] Color", 0x1CA6A1FF) 
        Menu.Checkbox("Draw.R.Enabled",   "Draw [R] Range")
        Menu.ColorPicker("Draw.R.Color", "Draw [R] Color", 0x0E1E6EFF) 
    end)
end

local lastTick = 0
local function CanPerformCast()
    local curTime = clock()
    if curTime - lastTick > 0.25 then 
        lastTick = curTime

        local gameAvailable = not (Game.IsChatOpen() or Game.IsMinimized())
        return gameAvailable and not (Player.IsDead or Player.IsRecalling) and Orbwalker.CanCast()
    end
end

function Ashe.OnTick()    
    _R.Range = Menu.Get("Misc.MaxDistR")
    if not CanPerformCast() then return end

    local mode = Orbwalker.GetMode()
    if Ashe.LogicR() then return end
    if Ashe.LogicQ(mode) then return end
    if Ashe.LogicW(mode) then return end    
end

function Ashe.LogicQ(_mode)
    if Menu.Get(_mode .. ".UseQ", true) and _Q:IsReady() then
        if TS:GetTarget(-1) then
            return _Q:Cast()
        end        
    end
end
function Ashe.LogicW(_mode)
    if Menu.Get(_mode .. ".UseW", true) and _W:IsReady() then
        local target = _W:GetTarget()
        if target then
            return _W:CastOnHitChance(target, Enums.HitChance.Medium)
        end        
    end
end
function Ashe.LogicR()
    if Menu.Get("Misc.ForceR") and _R:IsReady() then
        local target = _R:GetTarget()
        if target then
            return _R:CastOnHitChance(target, 0.85)
        end        
    end
end
function Ashe.AutoR(source)
    if not (source.IsEnemy and Menu.Get("Misc.AutoR") and _R:IsReady()) then return end

    local target = _R:GetTarget()
    if target and CountAlliesInRange(target.Position, 800) > 0 then
        return _R:CastOnHitChance(target, Enums.HitChance.VeryHigh)
    end
end

function Ashe.OnDraw() 
    if Menu.Get("Draw.W.Enabled") then
        Renderer.DrawCircle3D(Player.Position, _W.Range, 60, 2, Menu.Get("Draw.W.Color"))
    end
    if Menu.Get("Draw.R.Enabled") then
        Renderer.DrawCircle3D(Player.Position, _R.Range, 25, 2, Menu.Get("Draw.R.Color"))
    end
end

function Ashe.OnVisionLost(obj)
    if Menu.Get(Orbwalker.GetMode() .. ".UseE", true) and _E:IsReady() then
        local lastTarget = obj:Distance(Player) < TS:GetTrueAutoAttackRange(Player, obj) and Orbwalker.GetLastTarget()
        if lastTarget and lastTarget == obj then
            return _E:Cast(obj.Position)
        end        
    end
end

function Ashe.OnGapclose(source, dashInst)
    Ashe.AutoR(source)
end
function Ashe.OnHeroImmobilized(source, endT)
    Ashe.AutoR(source)
end

function OnLoad()
    Ashe.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Ashe[eventName] then
            EventManager.RegisterCallback(eventId, Ashe[eventName])
        end
    end    
    return true
end
