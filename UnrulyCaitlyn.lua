--[[
    First Release By Thorn @ 22.Nov.2020    
]]

if Player.CharName ~= "Caitlyn" then return end

module("Unruly Caitlyn", package.seeall, log.setup)
clean.module("Unruly Caitlyn", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyCaitlyn.lua", "1.0.6")

local clock = os.clock
local insert = table.insert

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local Spell, DamageLib = _G.Libs.Spell, _G.Libs.DamageLib

local Spells = {
    Q = Spell.Skillshot({
        Slot   = Enums.SpellSlots.Q,
        Delay  = 0.625,
        Speed  = 2200,
        Range  = 1250,
        Radius = 60,
        Type   = "Linear",
        Collisions = {WindWall=true},
    }),
    Q2 = Spell.Skillshot({
        Slot   = Enums.SpellSlots.Q,
        Delay  = 0.625,
        Speed  = 2200,
        Range  = 1250,
        Radius = 90,
        Type   = "Linear",
        Collisions = {WindWall=true},
    }),
    W = Spell.Skillshot({
        Slot   = Enums.SpellSlots.W,
        Delay  = 1,
        Speed  = math.huge,
        Range  = 800,
        Radius = 75,        
        IsTrap = true,
        Type   = "Circular",
    }),
    E = Spell.Skillshot({
        Slot   = Enums.SpellSlots.E,
        Delay  = 0.25,
        Speed  = 1600,
        Range  = 750,
        Radius = 70,
        Type   = "Linear",
        Collisions = {Heroes=true, Minions=true, WindWall=true},

        Knockback = 400,
    }),
    R = Spell.Targeted({
        Slot   = Enums.SpellSlots.R,
        Delay  = 1.375,
        Speed  = 3200,
        Range  = 3500,
        Radius = 40
    }),
}


---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Caitlyn = {}
local blockList = {}

local function CountHeroesInRange(pos, range, team)
    local count = 0
    for k, v in pairs(ObjManager.Get(team, "heroes")) do
        local hero = v.AsHero
        if hero and hero:Distance(pos) < range and hero.IsAlive then
            count = count + 1
        end
    end
    return count
end

function Caitlyn.LoadMenu()
    Menu.RegisterMenu("UnrulyCaitlyn", "Unruly Caitlyn", function()       
        Menu.NewTree("CaitlynCombo", "Combo Settings", function()
        Menu.Separator("Combo Settings")
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true)
            Menu.Slider("Combo.SafeQ", "Block [Q] Enemies Nearby", 1, 0, 5)
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Slider("Combo.SaveW", "Save Traps", 1, 0, 5)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)            
        end)            

        Menu.NewTree("CaitlynHarass", "Harass Settings", function()
        Menu.Separator("Harass Settings")
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true)
            Menu.Slider("Harass.SafeQ", "Block [Q] Enemies Nearby", 1, 0, 5)
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
            Menu.Slider("Harass.SaveW", "Save Traps", 2, 0, 5)
            Menu.Checkbox("Harass.UseE", "Use [E]", false) 
        end)

        Menu.NewTree("Fast Clear", "Clear Settings", function()
        Menu.Separator("Fast Clear Settings")
            Menu.Checkbox("Clear.PushQ", "Use [Q]", true) 
        end)
        
        Menu.NewTree("CaitlynFlee", "Flee Settings", function()
        Menu.Separator("Flee Settings")
            Menu.Checkbox("Flee.UseE", "Use [E]", true) 
        end)       
    
        Menu.NewTree("CaitlynMisc", "Misc Settings", function()
        Menu.Separator("Misc Settings")
            Menu.Checkbox("Misc.AutoQ", "Auto [Q] Immobile")
            Menu.Checkbox("Misc.AutoW", "Auto [W] Immobile/Dash", true)
            Menu.Checkbox("Misc.GapW", "Auto [W] GapClose")
            Menu.Checkbox("Misc.GapE", "Auto [E] GapClose", true)          
            Menu.Checkbox("Misc.AutoR", "Auto [R] Killable", true)
            Menu.Slider("Misc.MinRangeR", "Min Range For [R]", 1000, 1000, Spells.R.Range-500, 50) 
            Menu.Slider("Misc.SafeRangeR", "Block [R] Enemies Nearby", 500, 0, 1250, 50)              
        end)

        Menu.NewTree("CaitlynDraw", "Draw Settings", function()
        Menu.Separator("Drawing Settings")
            Menu.Checkbox("Drawing.Q.Enabled", "Draw [Q] Range", true)
            Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0xEF476FFF) 
            Menu.Checkbox("Drawing.W.Enabled", "Draw [W] Range", false)
            Menu.ColorPicker("Drawing.W.Color", "Draw [W] Color", 0x06D6A0FF) 
            Menu.Checkbox("Drawing.E.Enabled", "Draw [E] Range", false)
            Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x118AB2FF) 
            Menu.Checkbox("Drawing.R.EnabledMM", "Draw [R] Range Minimap", false)
            Menu.ColorPicker("Drawing.R.ColorMM", "Draw [R] Color", 0xFFD166FF)
        end)
        Menu.Separator("Hotkeys")
        Menu.Keybind("Misc.ForceE", "[E] To Cursor", string.byte('T'))     
        Menu.Separator("Author: Thorn")
    end)
end

local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end
function Caitlyn.IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell) and Spells[spell]:IsReady()
end
function Caitlyn.GetRawDamageR()
    return 75 + 225 * Spells.R:GetLevel() + 2*Player.BonusAD
end

local lastTick = 0
function Caitlyn.OnTick()        
    if not GameIsAvailable() then return end  

    if Caitlyn.Auto() then return end
    if not Orbwalker.CanCast() then return end   

    local gameTime = Game.GetTime()
    if gameTime < (lastTick + 0.25) then return end
    lastTick = gameTime    
    
    for k, v in pairs(blockList) do
        if gameTime > v + 2.5 then
            blockList[k] = nil
        end
    end

    local ModeToExecute = Caitlyn[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end
function Caitlyn.OnDraw() 
    local pPos = Player.Position

    if Menu.Get("Drawing.R.EnabledMM") then
        Renderer.DrawCircleMM(pPos, Spells.R.Range, 2, Menu.Get("Drawing.R.ColorMM"))
    end
    
    for k, v in pairs(Spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(pPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

function Caitlyn.Auto()
    if Menu.Get("Misc.ForceE") and Spells.E:IsReady() then
        local castPos = Player.Position:Extended(Renderer.GetMousePos(), -400)
        if Spells.E:Cast(castPos) then
            return true
        end
    end

    local pPos = Player.Position
    if Menu.Get("Misc.AutoR") and Spells.R:IsReady() and Player:CountEnemiesInRange(Menu.Get("Misc.SafeRangeR")) == 0 then
        local minRange = Menu.Get("Misc.MinRangeR")
        local rawDmg = Caitlyn.GetRawDamageR()

        for k, hero in ipairs(Spells.R:GetTargets()) do
            local dist = hero:Distance(pPos)
            if dist > minRange and hero:CountEnemiesInRange(500) == 0 then
                local timeToReach = Spells.R.Delay + dist/Spells.R.Speed
                local dmg = DamageLib.CalculatePhysicalDamage(Player, hero, rawDmg)
                if dmg > HealthPred.GetKillstealHealth(hero, timeToReach, Enums.DamageTypes.Physical) and Spells.R:Cast(hero) then
                    return true
                end
            end
        end
    end
end

function Caitlyn.ComboLogic(mode)
    local pPos, pRange = Player.Position, TS:GetTrueAutoAttackRange(Player)

    if Caitlyn.IsEnabledAndReady("E", mode) then
        for k, hero in ipairs(Spells.E:GetTargets()) do
            if Spells.E:CastOnHitChance(hero, 0.85) then --hero:Distance(pPos) < (pRange - 400) -- This check makes it worse I think
                return
            end
        end

        if not TS:GetTarget(-1) then
            local bestTarget = TS:GetTarget(TS:GetTrueAutoAttackRange(Player) + Spells.E.Knockback)
            if bestTarget then
                local aaDmg = DamageLib.GetAutoAttackDamage(Player, bestTarget, true)
                local health = HealthPred.GetKillstealHealth(bestTarget, 0.25, Enums.DamageTypes.Physical)
                if aaDmg * 2 > health and Spells.E:Cast(pPos:Extended(bestTarget.Position, -400)) then
                    return
                end
            end
        end
    end
    if Caitlyn.IsEnabledAndReady("W", mode) and Spells.W:GetCurrentAmmo() > Menu.Get(mode..".SaveW") then
        for k, hero in ipairs(Spells.W:GetTargets()) do
            if not blockList[hero.Handle] and Spells.W:CastOnHitChance(hero, Enums.HitChance.Low) then
                blockList[hero.Handle] = Game.GetTime()
                return
            end
        end
    end
    
    local enemiesAround = CountHeroesInRange(pPos, pRange, "enemy")
    if Caitlyn.IsEnabledAndReady("Q", mode) and enemiesAround <= Menu.Get(mode..".SafeQ") then
        for k, hero in ipairs(Spells.Q:GetTargets()) do
            if Spells.Q:CastOnHitChance(hero, Enums.HitChance.Low) then
                return
            end
        end
    end    
end

function Caitlyn.Combo()  Caitlyn.ComboLogic("Combo")  end
function Caitlyn.Harass() Caitlyn.ComboLogic("Harass") end
function Caitlyn.Flee() 
    if Caitlyn.IsEnabledAndReady("E", "Flee") then
        for k, hero in ipairs(Spells.E:GetTargets()) do
            if Spells.E:CastOnHitChance(hero, 0.85) then
                return
            end
        end
    end
end
function Caitlyn.Waveclear()
    local fastClear = Orbwalker.IsFastClearEnabled()
       
    if fastClear and Spells.Q:IsReady() and Menu.Get("Clear.PushQ") then
        if Spells.Q:CastIfWillHit(3, "minions") then
            return
        end
    end     
end

function Caitlyn.OnGapclose(source, dash)
    if not source.IsEnemy then return end

    if not blockList[source.Handle] and Spells.W:IsReady() and Menu.Get("Misc.AutoW") then
        if Spells.W:CastOnHitChance(source, Enums.HitChance.Low) then
            blockList[source.Handle] = Game.GetTime()
            return
        end
    end

    local paths  = dash:GetPaths()
    local endPos = paths[#paths].EndPos
    local pPos  = Player.Position
    local pDist = pPos:Distance(endPos)    

    if pDist < 500 and pDist < pPos:Distance(dash.StartPos) and source:IsFacing(pPos) then
        if not blockList[source.Handle] and Spells.W:IsReady() and Menu.Get("Misc.GapW") then
            if Spells.W:CastOnHitChance(source, Enums.HitChance.Low) then
                blockList[source.Handle] = Game.GetTime()
                return
            end
        end
        if Spells.E:IsReady() and Menu.Get("Misc.GapE") then
            if Spells.E:CastOnHitChance(source, Enums.HitChance.Low) then
                return
            end
        end
    end
end
function Caitlyn.OnHeroImmobilized(source, endT)
    if not source.IsEnemy then return end

    if not blockList[source.Handle] and Spells.W:IsReady() and Menu.Get("Misc.AutoW") then
        if Spells.W:CastOnHitChance(source, Enums.HitChance.Low) then
            blockList[source.Handle] = Game.GetTime()
            return
        end
    end
    if Spells.Q:IsReady() and Menu.Get("Misc.AutoQ") then
        if Spells.Q:CastOnHitChance(source, Enums.HitChance.Low) then
            return
        end
    end
end

function OnLoad()
    Caitlyn.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Caitlyn[eventName] then
            EventManager.RegisterCallback(eventId, Caitlyn[eventName])
        end
    end    
    return true
end
