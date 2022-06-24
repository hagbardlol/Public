--[[
    First Release By Thorn @ 10.Oct.2020    
]]

if Player.CharName ~= "Ezreal" then return end

module("Unruly Ezreal", package.seeall, log.setup)
clean.module("Unruly Ezreal", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyEzreal.lua", "1.0.3")

local clock = os.clock
local insert, sort = table.insert, table.sort
local huge, min, max, abs = math.huge, math.min, math.max, math.abs

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Ezreal = {}

local spells = {
    Q = Spell.Skillshot({
        Slot = Enums.SpellSlots.Q,
        Range = 1200,
        Speed = 2000,
        Delay = 0.25,
        Radius = 60,
        Type = "Linear",
        Collisions = {Minions=true, WindWall=true},
        UseHitbox = true -- check
    }),
    W = Spell.Skillshot({
        Slot = Enums.SpellSlots.W,
        Range = 1200,
        Delay = 0.25,
        Speed = 1700,
        Radius = 80,
        Type = "Linear",
        Collisions = {WindWall=true},
        UseHitbox = true -- check
    }),
    E = Spell.Skillshot({
        Slot = Enums.SpellSlots.E,
        Range = 475 + 750,
        Radius = 80,
        Delay = 0.3,
        Type = "Circular",
    }),
    R = Spell.Skillshot({
        Slot = Enums.SpellSlots.R,
        Delay = 1,
        Speed = 2000,
        Radius = 160,
        Type = "Linear",
        Collisions = {WindWall=true},
        UseHitbox = true -- check
    }),
}

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

function Ezreal.GetRawDamageQ()
    --20 / 45 / 70 / 95 / 120 (+ 120% AD) (+ 15% AP)
    return (-5 + spells.Q:GetLevel() * 25) + (1.2 * Player.TotalAD) + (0.15 * Player.TotalAP)
end
function Ezreal.GetRawDamageW()
    --80 / 135 / 190 / 245 / 300 (+ 60% bonus AD) (+ 70 / 75 / 80 / 85 / 90% AP)
    local wLevel = spells.W:GetLevel()
    return (25 + wLevel * 55) + (0.6 * Player.BonusAD) + ((0.65 + 0.05 * wLevel) * Player.TotalAP)
end
function Ezreal.GetRawDamageE()
    --80 / 130 / 180 / 230 / 280 (+ 50% bonus AD) (+ 75% AP)
    return (30 + spells.E:GetLevel() * 50) + (0.5 * Player.BonusAD) + (0.75 * Player.TotalAP)
end
function Ezreal.GetRawDamageR()
    --350 / 500 / 650 (+ 100% bonus AD) (+ 90% AP)
    return (200 + spells.R:GetLevel() * 150) + (1.0 * Player.BonusAD) + (0.90 * Player.TotalAP)
end

function Ezreal.IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell) and spells[spell]:IsReady()
end
local lastTick = 0
function Ezreal.OnTick()    
    if not GameIsAvailable() then return end 

    local gameTime = Game.GetTime()
    if gameTime < (lastTick + 0.25) then return end
    lastTick = gameTime    

    if Ezreal.Auto() then return end
    if not Orbwalker.CanCast() then return end

    local ModeToExecute = Ezreal[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end
function Ezreal.OnDraw() 
    local playerPos = Player.Position
    local pRange = Orbwalker.GetTrueAutoAttackRange(Player)   
    
    if Menu.Get("Drawing.R.MinEnabled") then
        Renderer.DrawCircle3D(playerPos, Menu.Get("Misc.MinDistR"), 30, 2, Menu.Get("Drawing.R.Color")) 
    end
    if Menu.Get("Drawing.R.MaxEnabled") then
        Renderer.DrawCircle3D(playerPos, Menu.Get("Misc.MaxDistR"), 30, 2, Menu.Get("Drawing.R.Color")) 
    end

    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

function Ezreal.GetTargets(range)
    if Menu.Get("Misc.ObvMode") then
        return TS:GetTargets(range, true)
    end
    return {TS:GetTarget(range, true)}
end

function Ezreal.GetMinionsQ(t, team_lbl)
    for k, v in pairs(ObjManager.Get(team_lbl, "minions")) do
        local minion = v.AsAI
        local minionInRange = minion and minion.MaxHealth > 6 and spells.Q:IsInRange(minion)
        local shouldIgnoreMinion = minion and (Orbwalker.IsLasthitMinion(minion) or Orbwalker.IsIgnoringMinion(minion))
        if minionInRange and not shouldIgnoreMinion and minion.IsTargetable then
            insert(t, minion)
        end                       
    end
end

function Ezreal.ComboLogic(mode)
    if Ezreal.IsEnabledAndReady("W", mode) then
        local wChance = Menu.Get(mode .. ".ChanceW")
        for k, wTarget in ipairs(Ezreal.GetTargets(spells.W.Range)) do
            if spells.W:CastOnHitChance(wTarget, wChance) then
                return
            end
        end
    end
    if Ezreal.IsEnabledAndReady("Q", mode) then
        local qChance = Menu.Get(mode .. ".ChanceQ")
        for k, qTarget in ipairs(Ezreal.GetTargets(spells.Q.Range)) do
            if spells.Q:CastOnHitChance(qTarget, qChance) then
                return
            end
        end
    end    
    if Ezreal.IsEnabledAndReady("E", mode) then
        local rawDmg = Ezreal.GetRawDamageE()
        local checkSafety = Menu.Get(mode .. ".SafeE")       

        for k, eTarget in ipairs(Ezreal.GetTargets(spells.E.Range)) do
            local eDmg = DmgLib.CalculateMagicalDamage(Player, eTarget, rawDmg)
            local ksHealth = HealthPred.GetKillstealHealth(eTarget, spells.E.Delay)
            
            if eDmg > ksHealth then
                local pred = spells.E:GetPrediction(eTarget)
                local isSafe = pred and (not checkSafety or CountEnemiesInRange(pred.CastPosition, 500) < 2)
                if isSafe and spells.E:Cast(pred.CastPosition) then
                    return
                end
            end         
        end        
    end    
end

function Ezreal.FarmLogic(minions)    
    local rawDmg = Ezreal.GetRawDamageQ()

    for k, minion in ipairs(minions) do
        local healthPred = spells.Q:GetHealthPred(minion)
        local qDmg = DmgLib.CalculatePhysicalDamage(Player, minion, rawDmg)
        if healthPred > 0 and healthPred < qDmg and spells.Q:CastOnHitChance(minion, Enums.HitChance.Medium) then        
            return true
        end                       
    end    
end

function Ezreal.Auto() 
    if not spells.R:IsReady() then return end

    local pPos = Player.Position
    local rawDmg = Ezreal.GetRawDamageR()
    local rMinRange, rMaxRange = Menu.Get("Misc.MinDistR"), Menu.Get("Misc.MaxDistR")

    local autoR = Menu.Get("Misc.AutoR")
    local rToKill = Menu.Get("Misc.ForceR") or (Orbwalker.GetMode() == "Combo" and Menu.Get("Combo.UseR"))
    
    local points = {}
    for k, rTarget in ipairs(TS:GetTargets(rMaxRange, true)) do        
        local pred = spells.R:GetPrediction(rTarget)
        if pred and pred.HitChanceEnum >= Enums.HitChance.VeryHigh then
            insert(points, pred.CastPosition)

            if rToKill and rTarget:Distance(pPos) > rMinRange then
                local rDmg = DmgLib.CalculateMagicalDamage(Player, rTarget, rawDmg)
                local ksHealth = spells.R:GetKillstealHealth(rTarget)
                
                if rDmg > ksHealth and spells.R:Cast(pred.CastPosition) then
                    return
                end 
            end
        end   
    end

    if autoR then
        local bestPos, hitCount = spells.R:GetBestLinearCastPos(points)
        if hitCount >= Menu.Get("Misc.AutoR") then
            spells.R:Cast(bestPos)
        end
    end
end

function Ezreal.Combo()  Ezreal.ComboLogic("Combo")  end
function Ezreal.Harass() Ezreal.ComboLogic("Harass") end
function Ezreal.Waveclear()
    local pPos = Player.Position

    if spells.W:IsReady() and Menu.Get("Clear.PushW") then
        local aaRange = Orbwalker.GetTrueAutoAttackRange(Player)
        local function CheckCastW(type_lbl)
            for k, v in pairs(ObjManager.Get("enemy", type_lbl)) do
                local turret = v.AsAI
                if turret and turret:EdgeDistance(pPos) < aaRange and turret.IsTargetable then
                    return spells.W:Cast(turret.Position)
                end                       
            end
        end
        CheckCastW("hqs")
        CheckCastW("inhibitors")
        CheckCastW("turrets")
    end

    if not spells.Q:IsReady() then return end
    local farmQ   = Menu.Get("Clear.FarmQ")
    local jungleQ = Menu.Get("Clear.JungleQ")
    local pushQ   = Menu.Get("Clear.PushQ")
    if not (farmQ or jungleQ or pushQ) then return end

    local minionsInRange = {}
    do -- Fill Minions In Range And Sort
        if jungleQ then Ezreal.GetMinionsQ(minionsInRange, "neutral") end
        if farmQ or pushQ then Ezreal.GetMinionsQ(minionsInRange, "enemy") end        
        sort(minionsInRange, function(a, b) return a.MaxHealth > b.MaxHealth end)
    end    

    if farmQ and Ezreal.FarmLogic(minionsInRange) then 
        return
    end

    if not (jungleQ or pushQ) then return end
    local rawDmg = Ezreal.GetRawDamageQ()
    for k, minion in pairs(minionsInRange) do    
        local isNeutral = minion.IsNeutral
        if (pushQ or isNeutral) then  
            local healthPred = spells.Q:GetHealthPred(minion)
            local qDmg = DmgLib.CalculatePhysicalDamage(Player, minion, rawDmg)
            if healthPred > 0 and (isNeutral or (healthPred-qDmg)/minion.MaxHealth > 0.3) and spells.Q:CastOnHitChance(minion, Enums.HitChance.Medium) then        
                return
            end
        end
    end        
end
function Ezreal.Lasthit()
    if spells.Q:IsReady() and Menu.Get("Clear.FarmQ") then        
        local minionsInRange = {}

        do -- Fill Minions In Range And Sort
            Ezreal.GetMinionsQ(minionsInRange, "enemy")      
            sort(minionsInRange, function(a, b) return a.MaxHealth > b.MaxHealth end)
        end

        Ezreal.FarmLogic(minionsInRange)
    end
end
---@param source AIBaseClient
---@param dash DashInstance
function Ezreal.OnGapclose(source, dash)
    if not (source.IsEnemy and Menu.Get("Misc.GapE") and spells.E:IsReady()) then return end

    local paths = dash:GetPaths()
    local endPos = paths[#paths].EndPos
    local pPos = Player.Position
    local pDist = pPos:Distance(endPos)

    if pDist < 400 and pDist < pPos:Distance(dash.StartPos) and source:IsFacing(pPos) then
        local maxRange = min(Orbwalker.GetTrueAutoAttackRange(Player, source), pDist + spells.E.Range)
        local castPos = pPos:Extended(endPos, - (maxRange - pDist))
        spells.E:Cast(castPos)        
    end
end
---@param source AIBaseClient
---@param spell SpellCast
function Ezreal.OnSpellCast(source, spell)
    if not (source.IsMe and spell.Slot == spells.Q.Slot) then return end

    local sPos, ePos = spell.StartPos, spell.EndPos
    local col = spells.Q:GetFirstCollision(sPos, sPos:Extended(ePos, spells.Q.Range), "enemy", Orbwalker.GetIgnoredMinions())

    local minionHit = col and col.Objects[1]
    if minionHit then
        local qDmg = DmgLib.CalculatePhysicalDamage(Player, minionHit, Ezreal.GetRawDamageQ())
        if qDmg > spells.Q:GetHealthPred(minionHit) then
            Orbwalker.IgnoreMinion(minionHit)
        end
    end    
end



function Ezreal.LoadMenu()

    Menu.RegisterMenu("UnrulyEzreal", "Unruly Ezreal", function()
        Menu.ColumnLayout("cols", "cols", 3, true, function()
            Menu.ColoredText("Combo", 0xFFD700FF, true)
            Menu.Checkbox("Combo.UseQ",   "Use [Q]", true)
            Menu.Slider("Combo.ChanceQ", "HitChance [Q]", 0.7, 0, 1, 0.05)    
            Menu.Checkbox("Combo.UseW",   "Use [W]", true)
            Menu.Slider("Combo.ChanceW", "HitChance [W]", 0.7, 0, 1, 0.05)
            Menu.Checkbox("Combo.UseE",   "Use [E]", true)   
            Menu.Indent(function()
                Menu.Checkbox("Combo.KillableE", "Use To Kill", true) 
                Menu.Checkbox("Combo.SafeE",     "Safety Check", true) 
            end) 
            
            Menu.Checkbox("Combo.UseR", "Use [R]", true)  

            Menu.NextColumn()

            Menu.ColoredText("Harass", 0xFFD700FF, true)
            Menu.Checkbox("Harass.UseQ",   "Use [Q]", true)
            Menu.Slider("Harass.ChanceQ", "HitChance [Q]", 0.8, 0, 1, 0.05)    
            Menu.Checkbox("Harass.UseW",   "Use [W]", true)
            Menu.Slider("Harass.ChanceW", "HitChance [W]", 0.85, 0, 1, 0.05)
            Menu.Checkbox("Harass.UseE",   "Use [E]", false)    
            Menu.Indent(function()
                Menu.Checkbox("Harass.KillableE", "Use To Kill", false) 
                Menu.Checkbox("Harass.SafeE",     "Safety Check", true) 
            end) 

            Menu.NextColumn()

            Menu.ColoredText("Clear", 0xFFD700FF, true)
            Menu.Checkbox("Clear.FarmQ",   "Use [Q] Farm", true)
            Menu.Checkbox("Clear.JungleQ", "Use [Q] Jungle", true)
            Menu.Checkbox("Clear.PushQ",   "Use [Q] Push", true)
            Menu.Checkbox("Clear.PushW",   "Use [W] On Turrets", true)
        end)    

        Menu.Separator()

        Menu.ColoredText("Misc Options", 0xFFD700FF, true)
        Menu.Checkbox("Misc.ObvMode", "Obvious Scripter Mode", true)      
        Menu.Checkbox("Misc.GapE", "Use [E] Gapclose", true)      
        Menu.Slider("Misc.MinDistR", "Min Distance [R]", 1000, 1000, 2500, 100)
        Menu.Slider("Misc.MaxDistR", "Max Distance [R]", 2500, 1000, 3000, 100)
        Menu.Slider("Misc.AutoR", "Auto [R] If Hit X", 3, 2, 5)
        Menu.Keybind("Misc.ForceR", "Force [R] Key", string.byte('T'))

        Menu.Separator()

        Menu.ColoredText("Draw Options", 0xFFD700FF, true)
        Menu.Checkbox("Drawing.Q.Enabled",   "Draw [Q] Range")
        Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0xEF476FFF) 
        Menu.Checkbox("Drawing.W.Enabled",   "Draw [W] Range")
        Menu.ColorPicker("Drawing.W.Color", "Draw [W] Color", 0x06D6A0FF) 
        Menu.Checkbox("Drawing.E.Enabled",   "Draw [E] Range")
        Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x118AB2FF)    
        Menu.Checkbox("Drawing.R.MinEnabled",   "Draw [R] Min Range")
        Menu.Checkbox("Drawing.R.MaxEnabled",   "Draw [R] Max Range")
        Menu.ColorPicker("Drawing.R.Color", "Draw [R] Color", 0xFFD166FF)    
    end)     
end

function OnLoad()
    Ezreal.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Ezreal[eventName] then
            EventManager.RegisterCallback(eventId, Ezreal[eventName])
        end
    end    
    return true
end
