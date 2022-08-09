--[[
    First Release By Thorn @ 09.May.2021    
]]

if Player.CharName ~= "Varus" then return end

module("Unruly Varus", package.seeall, log.setup)
clean.module("Unruly Varus", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyVarus.lua", "1.0.5")

local clock = os.clock
local insert, sort = table.insert, table.sort
local huge, min, max, abs = math.huge, math.min, math.max, math.abs

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

local CastTime = 0
local LastTarg, LastMis = nil, nil

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Varus = {}

local spells = {
    Q = Spell.Chargeable({
        Slot = Enums.SpellSlots.Q,
        Range = 925,
        Speed = 1850,
        Radius = 70,
        Type = "Linear",
        Collisions = {WindWall=true},
        UseHitbox = true,

        MinRange = 925,
        MaxRange = 1600,
        FullChargeTime = 1.5,
        MaxDamageTime = 2,
    }),
    W = Spell.Active({
        Slot = Enums.SpellSlots.W,        
    }),
    E = Spell.Skillshot({
        Slot = Enums.SpellSlots.E,
        Range = 975,
        Speed = 1500,
        Radius = 120,
        Delay = 0.35,
        Type = "Circular",
    }),
    R = Spell.Skillshot({
        Slot = Enums.SpellSlots.R,
        Range = 1050,
        Delay = 0.25,
        Speed = 1950,
        Radius = 120,
        Type = "Linear",
        Collisions = {WindWall=true},
        UseHitbox = true
    }),
}

local function CountAlliesInRange(pos, range, t)
    local res = 0
    for k, v in pairs(t or ObjManager.Get("ally", "heroes")) do
        local hero = v.AsHero
        if hero and hero.IsTargetable and hero:Distance(pos) < range then
            res = res + 1
        end
    end
    return res
end
local function CountEnemiesInRange(pos, range, t)
    local res = 0
    for k, v in pairs(t or ObjManager.Get("enemy", "heroes")) do
        local hero = v.AsHero
        if hero and hero.IsTargetable and hero:Distance(pos) < range then
            res = res + 1
        end
    end
    return res
end
local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end
function Varus.IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell) and spells[spell]:IsReady()
end
function Varus.TimeLeftToReleaseQ()
    local buff = Player:GetBuff("VarusQ")
    return buff and buff.DurationLeft or 99
end
function Varus.IsFullyChargedOverride()
    return Game.GetTime() > spells.Q.ChargeStartTime + spells.Q.MaxDamageTime
end
function Varus.ReleaseOrStartCharging(target, chance, mode)
    if spells.Q.IsCharging then
        if spells.Q:ReleaseOnHitChance(target, chance) then
            return true
        end
    else
        if Varus.IsEnabledAndReady("W", mode) and spells.W:Cast() then
            return
        end
        local dist = target:Distance(Player)
        if dist < (spells.Q.MinRange - 100) then
            return spells.Q:Cast(target.Position)
        elseif target:Distance(Player) < (spells.Q.MaxRange-300) then
            return spells.Q:StartCharging()
        end
    end
end
function Varus.GetStacksW(target)
    local incoming = LastTarg and target == LastTarg
    local buff= target:GetBuff("VarusWDebuff")
    return min(3, (buff and buff.Count or 0) + (incoming and 1 or 0))
end
function Varus.GetTargets(range)
    if Menu.Get("Misc.ObvMode") then
        return TS:GetTargets(range, true)
    end
    return {TS:GetTarget(range, true)}
end

local lastTick = 0
function Varus.OnNormalPriority(lagfree)    
    if not GameIsAvailable() then return end 

    if Varus.Auto() then return end
    if not Orbwalker.CanCast() then return end

    local ModeToExecute = Varus[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute(lagfree)
    end
end
function Varus.Combo(lagfree)  Varus.ComboLogic("Combo", lagfree)  end
function Varus.Harass(lagfree) Varus.ComboLogic("Harass", lagfree) end
function Varus.Waveclear(lagfree) Varus.FarmLogic(lagfree) end

function Varus.OnDraw()
    local playerPos = Player.Position
    
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, (k == "Q" and v.MaxRange) or v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

function Varus.ComboLogic(mode, lagfree)
    local canCast = (Game.GetTime() - CastTime > 1)

    if lagfree == 1 and Varus.IsEnabledAndReady("E", mode) then
        local eChance = Menu.Get(mode .. ".ChanceE")
        local eTargets = Varus.GetTargets(spells.E.Range)

        -- [[KS E Logic]]
        for k, eTarget in ipairs(eTargets) do
            local eDmg = spells.E:GetDamage(eTarget)
            local wDmg = spells.W:GetDamage(eTarget)
            if (eDmg + wDmg) > spells.E:GetKillstealHealth(eTarget) then
                if spells.E:CastOnHitChance(eTarget, eChance) then
                    return
                end
            end
        end

        if canCast then
            local enemiesInRange = TS:GetTargets(-1)
            local cantAA = #enemiesInRange == 0

            -- [[Slow / Proc Stacks Logic]]
            for k, eTarget in ipairs(eTargets) do
                if (cantAA or Varus.GetStacksW(eTarget) == 3) then
                    if spells.E:CastOnHitChance(eTarget, eChance) then
                        return
                    end
                end
            end
        end
    elseif lagfree == 2 and Varus.IsEnabledAndReady("Q", mode) then
        local qChance = (Varus.TimeLeftToReleaseQ() > 1 and Menu.Get(mode .. ".ChanceQ")) or Enums.HitChance.Low
        local qTargets = Varus.GetTargets(spells.Q.MaxRange-300)

        -- [[KS Q Logic]]
        for k, qTarget in ipairs(qTargets) do
            local qDmg = spells.Q:GetDamage(qTarget)
            local wDmg = spells.W:GetDamage(qTarget)
            local wActiveDmg = Varus.IsEnabledAndReady("W", mode) and spells.W:GetDamage(qTarget, "SecondForm") or 0

            if (qDmg + wDmg + wActiveDmg) > spells.Q:GetKillstealHealth(qTarget) then
                if Varus.ReleaseOrStartCharging(qTarget, qChance, mode) then
                    return
                end
            end
        end

        local enemiesInRange = TS:GetTargets(-1)        
        if spells.Q.IsCharging then
            -- [[Release Q Logic]]
            if not Menu.Get(mode .. ".MaxQ") or Varus.IsFullyChargedOverride() or #enemiesInRange > 0 then
                for k, qTarget in ipairs(qTargets) do
                    if spells.Q:ReleaseOnHitChance(qTarget, qChance) then
                        return
                    end
                end
            end
        elseif canCast then
            -- [[Charge Q Logic]]
            local cantAA = #enemiesInRange == 0
            local cantUseE = not spells.E:IsReady()            
            for k, qTarget in ipairs(qTargets) do
                local wStacks = Varus.GetStacksW(qTarget)
                if cantAA or (cantUseE and wStacks == 3) then
                    if not Menu.Get(mode .. ".StacksQ") or wStacks == 3 then
                        if Varus.ReleaseOrStartCharging(qTarget, qChance, mode) then
                            return
                        end
                    end
                end
            end
        end        
    elseif lagfree == 3 and mode == "Combo" and Varus.IsEnabledAndReady("R", mode) then
        local rTargets = spells.R:GetTargets()

        local pPos = Player.Position
        local hasLowHealth = Player.HealthPercent < 0.5
        local minHit = Menu.Get("Combo.MinR")
        local rChance = Menu.Get("Combo.ChanceR")
        local castOnDangerous = Menu.Get("Combo.DangerousR")

        for k, rTarget in ipairs(rTargets) do
            local pos = rTarget.Position

            --[[Escape Danger Logic]]
            if hasLowHealth and castOnDangerous then
                if rTarget.IsMelee and pos:FastDistance(pPos) < 350 then
                    if spells.R:CastOnHitChance(rTarget, rChance) then
                        return
                    end
                end
            end

            --[[AOE Logic]]
            if minHit > 0 and CountEnemiesInRange(pos, 450) >= minHit then
                if spells.R:CastOnHitChance(rTarget, rChance) then
                    return
                end
            end

            --[[Duel Logic]]
            if (CountAlliesInRange(pos, 650) == 0 or hasLowHealth) then
                local comboDmg = spells.Q:GetDamage(rTarget) + spells.W:GetDamage(rTarget) + spells.R:GetDamage(rTarget)
                if comboDmg > spells.Q:GetKillstealHealth(rTarget) then
                    if spells.R:CastOnHitChance(rTarget, rChance) then
                        return
                    end
                end
            end
        end
    end    
end

function Varus.FarmLogic(lagfree)
    local jungleQ, jungleE = Menu.Get("Clear.JungleQ"), Menu.Get("Clear.JungleE")
    local pushQ, pushE = Menu.Get("Clear.PushQ"), Menu.Get("Clear.PushE")

    if spells.E:IsReady() then
        local pushE, jungleE = Menu.Get("Clear.PushE"), Menu.Get("Clear.JungleE")

        if lagfree == 1 and jungleE then
            for k, v in ipairs(ObjManager.GetNearby("neutral", "minions")) do
                local monster = v.AsMinion
                if monster and spells.E:IsInRange(monster) and monster.IsAlive and Varus.GetStacksW(monster) == 3 then
                    if spells.E:Cast(monster.Position) then
                        return
                    end
                end
            end
        elseif lagfree == 2 and pushE then
            if spells.E:CastIfWillHit(3, "minions") then
                return
            end
        end
    end
    if spells.Q:IsReady() then
        local pushQ, jungleQ = Menu.Get("Clear.PushQ"),Menu.Get("Clear.JungleQ")

        if lagfree == 3 and jungleQ then
            for k, v in ipairs(ObjManager.GetNearby("neutral", "minions")) do
                local monster = v.AsMinion
                if monster and spells.Q:IsInRange(monster) and monster.IsAlive and Varus.GetStacksW(monster) == 3 then
                    if spells.Q:Cast(monster.Position) then
                        return
                    end
                end
            end
        elseif lagfree == 4 and pushE then
            local minHit = (Varus.TimeLeftToReleaseQ() > 1 and 3) or 1
            if spells.Q:CastIfWillHit(minHit, "minions") then
                return
            end
        end
    end
end

function Varus.Auto() 
    if spells.R:IsReady() and Menu.Get("Misc.ForceR") then
        local rTargets = Varus.GetTargets(spells.R.Range)
        for k, rTarget in ipairs(rTargets) do
            if spells.R:CastOnHitChance(rTarget, Enums.HitChance.Low) then
                return
            end
        end
    end    
end

function Varus.OnHeroImmobilized(source, endT)
    if not source.IsEnemy then return end

    if Menu.Get("Misc.AutoR") and CountAlliesInRange(source.Position, 800) > 0 then
        if spells.R:CastOnHitChance(source, Enums.HitChance.Immobile, "Combo") then
            return
        end
    end
    if Menu.Get("Misc.AutoQ") and (spells.Q.IsCharging or endT > (Game.GetTime() + spells.Q.FullChargeTime)) then        
        if Varus.ReleaseOrStartCharging(source, Enums.HitChance.Immobile, "Combo") then
            return
        end
    end
end

---@param source AIBaseClient
---@param dash DashInstance
function Varus.OnGapclose(source, dash)
    if not source.IsEnemy then return end

    local paths = dash:GetPaths()
    local endPos = paths[#paths].EndPos
    local pPos = Player.Position
    local pDist = pPos:Distance(endPos)

    if pDist < 400 and pDist < pPos:Distance(dash.StartPos) and source:IsFacing(pPos) then
        if Menu.Get("Misc.GapR") and spells.R:IsReady() then
            if spells.R:CastOnHitChance(source, Enums.HitChance.Low) then
                return
            end
        end
    
        if Menu.Get("Misc.GapE") and spells.E:IsReady() then
            if spells.E:CastOnHitChance(source, Enums.HitChance.Low) then
                return
            end
        end              
    end
end
---@param source AIBaseClient
---@param spell SpellCast
function Varus.OnSpellCast(source, spell)
    if source.IsMe and spell.Slot ~= spells.W.Slot and spell.Slot <= spells.R.Slot then 
        CastTime = Game.GetTime()
    end   
end

---@param obj GameObject
function Varus.OnCreateObject(obj)
    local mis = obj.AsMissile
    if mis and mis.Name == "VarusWBasicAttack" then
        local owner = mis.Source
        if owner and owner.IsMe then
            LastTarg = mis.Target
            LastMis = obj
        end
    end
end
function Varus.OnDeleteObject(obj)
    if LastMis and LastMis == obj then
        LastTarg, LastMis = nil, nil
    end
end

function Varus.LoadMenu()
    Menu.RegisterMenu("UnrulyVarus", "Unruly Varus", function()
        Menu.ColumnLayout("cols", "cols", 3, true, function()
            Menu.NewTree("Combo Settings", "Combo Settings", function()
            Menu.Separator("Combo Settings")
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true)
            Menu.Indent(function()
                Menu.Checkbox("Combo.MaxQ", "Only Max Range", true)
                Menu.Checkbox("Combo.StacksQ", "Only Max Stacks", false)
                Menu.Slider("Combo.ChanceQ", "HitChance", 0.35, 0, 1, 0.05)
            end)
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)
            Menu.Indent(function()
                Menu.Slider("Combo.ChanceE", "HitChance [E]", 0.35, 0, 1, 0.05)
            Menu.Checkbox("Combo.UseR", "Use [R]", true)
            end)
            Menu.Indent(function()
                Menu.Slider("Combo.ChanceR", "HitChance [R]", 0.50, 0, 1, 0.05)
                Menu.Slider("Combo.MinR", "If X Enemies Hit", 3, 1, 5)
                Menu.Checkbox("Combo.DangerousR", "When Dangerous", true)
            end)
            end)

            Menu.NewTree("Harass Settings", "Harass Settings", function()
            Menu.Separator("Harass Settings")
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true)
            Menu.Indent(function()
                Menu.Checkbox("Harass.MaxQ", "Only Max Range", true)
                Menu.Checkbox("Harass.StacksQ", "Only Max Stacks", true)
                Menu.Slider("Harass.ChanceQ", "HitChance", 0.35, 0, 1, 0.05)
            end)
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
            Menu.Checkbox("Harass.UseE", "Use [E]", true)
            Menu.Indent(function()
                Menu.Slider("Harass.ChanceE", "HitChance [E]", 0.35, 0, 1, 0.05)
            end)
            end)

            Menu.NewTree("Lane Clear Settings", "Lane Clear Settings", function()
            Menu.Separator("Lane Clear Settings")
            Menu.Checkbox("Clear.JungleQ", "Use [Q] Jungle", true)
            Menu.Checkbox("Clear.JungleE", "Use [E] Jungle", true)
            Menu.Checkbox("Clear.PushQ", "Use [Q] Push", true)
            Menu.Checkbox("Clear.PushE", "Use [E] Push", true)
            end)

            Menu.NewTree("Misc Options", "Misc Options", function()
            Menu.Separator("Misc Options")
            Menu.Checkbox("Misc.ObvMode", "Obvious Scripter Mode", true)      
            Menu.Checkbox("Misc.AutoQ", "Auto [Q] Immobile", true)      
            Menu.Checkbox("Misc.AutoR", "Auto [R] Chain CC", true)      
            Menu.Checkbox("Misc.GapE", "Use [E] Gapclose", true)      
            Menu.Checkbox("Misc.GapR", "Use [R] Gapclose", true)      
            Menu.Keybind("Misc.ForceR", "Force [R] Key", string.byte('T'))
            end)

            Menu.NewTree("Drawing Options", "Drawing Options", function()
            Menu.Separator("Drawing Options")
            Menu.Checkbox("Drawing.Q.Enabled", "Draw [Q] Range", true)
            Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0xEF476FFF) 
            Menu.Checkbox("Drawing.E.Enabled", "Draw [E] Range", true)
            Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x118AB2FF)    
            Menu.Checkbox("Drawing.R.Enabled", "Draw [R] Range", true)
            Menu.ColorPicker("Drawing.R.Color", "Draw [R] Color", 0xFFD166FF)
        end)
            end)
            Menu.Separator("Author: Thorn")
        end)
end

function OnLoad()
    Varus.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Varus[eventName] then
            EventManager.RegisterCallback(eventId, Varus[eventName])
        end
    end    
    return true
end
