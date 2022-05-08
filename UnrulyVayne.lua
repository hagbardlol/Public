--[[
    First Release By Thorn @ 11.Nov.2020
]]

if Player.CharName ~= "Vayne" then return end

module("Unruly Vayne", package.seeall, log.setup)
clean.module("Unruly Vayne", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://github.com/hagbardlol/Public/raw/main/UnrulyVayne.lua", "1.0.2")

local insert = table.insert
local min, max = math.min, math.max

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Vayne = {}

local spells = {
    Q = Spell.Skillshot({
        Slot = Enums.SpellSlots.Q,
        Range = 300,        
        Type = "Linear",

        DashTime = 0.4,
    }),
    E = Spell.Targeted({
        Slot = Enums.SpellSlots.E,
        Range = 650,
        Delay = 0.25,
    }),
    E_Pred = Spell.Skillshot({
        Slot = Enums.SpellSlots.E,
        Range = 650,
        Delay = 0.25,
        Radius = 10,
        Type = "Linear",
    }),
    R = Spell.Active({
        Slot = Enums.SpellSlots.R,
        Range = 1000
    }),
}

local function GetNearbyHeroesAndTurrets(pos, range)
    local heroList, closestTurret = {}, nil

    for k, v in pairs(ObjManager.Get("enemy", "heroes")) do
        local hero = v.AsHero
        if hero and hero:Distance(pos) < range and hero.IsMelee and hero.IsTargetable then
            insert(heroList, hero)
        end
    end

    for k, v in pairs(ObjManager.Get("enemy", "turrets")) do
        local turret = v.AsTurret
        if turret and turret.IsAlive and turret:Distance(pos) < (900+range) then
            closestTurret = turret
        end
    end
    return heroList, closestTurret
end
local function IsSafePosition(pos, heroList, nearbyTurret)
    local pPos = Player.Position
    if not heroList then
        heroList, nearbyTurret = GetNearbyHeroesAndTurrets(pos, 400)
    end

    if nearbyTurret and pos:Distance(nearbyTurret) <= 900 and pPos:Distance(nearbyTurret) >= 900 then
        return false
    end

    for k, hero in ipairs(heroList) do
        local dist = hero:Distance(pos)
        if dist < 400 and dist <= hero:Distance(pPos) then
            return false
        end
    end
    return true
end

local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end

function Vayne.IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell) and spells[spell]:IsReady()
end
local lastTick = 0
function Vayne.OnTick()
    local gameTime = Game.GetTime()
    if gameTime < (lastTick + 0.25) or not GameIsAvailable() then return end
    lastTick = gameTime

    if Vayne.Auto() then return end
    if not Orbwalker.CanCast() then return end

    local ModeToExecute = Vayne[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end
function Vayne.OnDraw()
    local pPos = Player.Position

    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(pPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color"))
        end
    end
end

function Vayne.ComboLogic(mode)
    if mode == "Combo" and Vayne.IsEnabledAndReady("R", "Combo") then
        if #TS:GetTargets(spells.R.Range, true) >= Menu.Get("Combo.MinR") and spells.R:Cast() then
            return
        end
    end
    if Vayne.IsEnabledAndReady("Q", mode) then
        local qPos, skipSafety, qLogic = nil, nil, Menu.Get(mode .. ".LogicQ")
        if qLogic == 0 then
            qPos, skipSafety = Vayne.GetBestTumblePos()
        elseif qLogic == 1 then
            qPos = Renderer.GetMousePos()
        elseif qLogic == 3 then
            qPos = Vayne.GetPeelPosQ()
        end

        if qPos and (skipSafety or IsSafePosition(qPos)) then
            spells.Q:Cast(qPos)
        end
    end
    if Vayne.PeelLogicE() then
        return
    end
end

function Vayne.GetPeelPosQ()    
    local pPos = Player.Position
    local heroList, nearbyTurret = GetNearbyHeroesAndTurrets(pPos, 400 + spells.Q.Range)

    for k, hero in ipairs(heroList) do
        if hero:Distance(pPos) < 400 and hero:IsFacing(pPos) then
            local ePred = hero:FastPrediction(spells.Q.DashTime)
            local aaRange = TS:GetTrueAutoAttackRange(Player, hero)
            local safeDist = min(aaRange * 0.85, pPos:Distance(ePred)+spells.Q.Range)

            local safePos = Vayne.GetBestCircleIntersection(pPos, spells.Q.Range, ePred, safeDist, heroList, nearbyTurret)
            if safePos then
                return safePos
            end
        end
    end
end

function Vayne.PeelLogicQ(override)
    if not (spells.Q:IsReady() and (override or Menu.Get("Peel.Q"))) then return end

    local safePos = Vayne.GetPeelPosQ()
    if safePos and spells.Q:Cast(safePos) then
        return true
    end
end

function Vayne.PeelLogicE(override)
    if not (spells.E:IsReady() and (override or Menu.Get("Peel.E"))) then return end

    local pPos = Player.Position    
    for k, obj in pairs(ObjManager.Get("enemy", "heroes")) do
        local hero = obj.AsHero
        if hero and hero:Distance(pPos) < 400 and hero.IsTargetable and hero.IsMelee and hero:IsFacing(pPos) then
            if spells.E:Cast(hero) then
                return true
            end
        end
    end
end

function Vayne.CanCondemn(pos, from)
    from = from or Player.Position
    local startPos = pos:Extended(from, -50)
    local endPos   = pos:Extended(from, -425)
    return Collision.SearchWall(startPos, endPos, 10, 25000, spells.E.Delay).Result
end
function Vayne.CondemnChance(target, from)    
    local tPos = target.Position
    if not Vayne.CanCondemn(tPos, from) then return -1 end

    local pred = spells.E_Pred:GetPrediction(target)
    if pred and pred.HitChanceEnum >= Enums.HitChance.High then
        return (Vayne.CanCondemn(pred.TargetPosition, from) and pred.HitChanceEnum) or -1
    else
        local colChance, maxCols = 0, 8
        local delay = Game.GetLatency()/1000 + spells.E_Pred.Delay
        local points = Geometry.Circle(tPos, target.MoveSpeed * delay):GetPoints(maxCols)
        for k, point in ipairs(points) do
            if Vayne.CanCondemn(point, from) then
                colChance = colChance + 1
            end
        end
        return colChance
    end
    return -1
end
function Vayne.GetBestTumblePos()
    local pPos = Player.Position
    local ultActive = false
    local eTarget = TS:GetTarget(spells.Q.Range + spells.E.Range, true)
    if not eTarget then return end

    -- Cast Q to Condemn or Save Q to Condemn soon
    if spells.E:IsReady(spells.Q:GetSpellData().TotalCooldown) then
        local bestPos, minChance = nil, 0 
        local points  = Geometry.Circle(pPos, spells.Q.Range):GetPoints(8)           

        for k, point in ipairs(points) do
            local condemnChance = Vayne.CondemnChance(eTarget, point)
            if condemnChance >= minChance then
                bestPos = point
                minChance = condemnChance
            end
        end

        if bestPos and minChance > Enums.HitChance.Low then
            if spells.E:IsReady() and minChance > (Menu.Get("Misc.ChanceE") + 3) then
                return bestPos, true
            end
            if not ultActive then
                return
            end
        end
    end

    -- Cast Q To Peel
    local peelPos = Vayne.GetPeelPosQ()
    if peelPos then return peelPos, true end
    
    -- Cast Q To Hide or Improve DPS
    if ultActive or not Vayne.DoesTumbleReduceDPS() then
        local ePred = eTarget:FastPrediction(spells.Q.DashTime)
        local aaRange = TS:GetTrueAutoAttackRange(Player, eTarget)
        
        local safePos = Vayne.GetBestCircleIntersection(pPos, spells.Q.Range, ePred, aaRange * 0.75)
        if safePos then
            return safePos
        end
    end
end
function Vayne.GetBestCircleIntersection(c1, r1, c2, r2, heroList, nearbyTurret)
    local points = Geometry.CircleCircleIntersection(c1, r1, c2, r2)
    if #points == 2 then
        if not heroList then
            heroList, nearbyTurret = GetNearbyHeroesAndTurrets(c1, 400 + r1)
        end
        local safe1 = IsSafePosition(points[1], heroList, nearbyTurret)
        local safe2 = IsSafePosition(points[2], heroList, nearbyTurret)

        if safe1 and safe2 then
            local mousePos = Renderer.GetMousePos()
            return (points[1]:Distance(mousePos) < points[2]:Distance(mousePos) and points[1]) or points[2]
        elseif safe1 then
            return points[1]
        elseif safe2 then
            return points[2]
        end
    end
end
function Vayne.GetStacksW(aiTarget)
    local b = aiTarget:GetBuff("vaynesilvereddebuff")
    return (b and b.Count) or 0
end
function Vayne.DoesTumbleReduceDPS()
    local atkDelay, mod = Player.AttackDelay, (0.55 + 0.05 * spells.Q:GetLevel())
    return spells.Q.DashTime > ((atkDelay - Orbwalker.TimeSinceLastAttack()) + atkDelay * mod)
end

function Vayne.Auto()
    local mode = Orbwalker.GetMode()
    
    local canUseE = Menu.Get("Misc.AutoE") or Menu.Get(mode .. ".UseE", true)
    if spells.E:IsReady() and canUseE then
        local minChance = Menu.Get("Misc.ChanceE") + 3        
        local eTargets = (Menu.Get("Misc.ObvMode") and TS:GetTargets(spells.E.Range, true)) or {TS:GetTarget(spells.E.Range, true)}    

        for k, eTarget in ipairs(eTargets) do
            if Vayne.CondemnChance(eTarget) >= minChance and spells.E:Cast(eTarget) then
                return
            end
        end
    end
end

function Vayne.Flee()   return (Vayne.PeelLogicQ(true) or Vayne.PeelLogicE(true)) end
function Vayne.Combo()  Vayne.ComboLogic("Combo")  end
function Vayne.Harass() Vayne.ComboLogic("Harass") end

---@param source AIBaseClient
---@param dash DashInstance
function Vayne.OnGapclose(source, dash)
    if not source.IsEnemy then return end

    local paths = dash:GetPaths()
    local endPos = paths[#paths].EndPos
    local pPos = Player.Position
    local pDist = pPos:Distance(endPos)
    if pDist > 400 or pDist > pPos:Distance(dash.StartPos) or not source:IsFacing(pPos) then return end

    if Menu.Get("Misc.GapQ") and spells.Q:IsReady() then
        local castPos, mousePos = nil, Renderer.GetMousePos()

        if pPos:LineDistance(dash.StartPos, endPos, true) < 100 then
            --Dash Sideways
            local perp = (endPos - dash.StartPos):Perpendicular():Normalized()
            local p1, p2 = pPos + perp * spells.Q.Range, pPos - perp * spells.Q.Range
            castPos = (mousePos:Distance(p1) < mousePos:Distance(p2) and p1) or p2
        elseif source.IsMelee then
            --Dash Backwards
            castPos = pPos:Extended(endPos, -spells.Q.Range)
        end

        if castPos and spells.Q:Cast(castPos) then
            return
        end
    end
    if Menu.Get("Misc.GapE") and spells.E:IsReady() then
        spells.E:Cast(source)
    end
end

---@param source AIBaseClient
---@param spell SpellCast
function Vayne.OnInterruptibleSpell(source, spell, danger, endT, canMove)
    if not (source.IsEnemy and Menu.Get("Misc.IntE") and spells.E:IsReady() and danger > 3) then return end

    spells.E:Cast(source)
end

function Vayne.OnPreAttack(args) --args: {Process, Target}    
    if Player:GetBuff("vaynetumblefade") then
        if Player:GetBuff("summonerexhaust") then
            args.Process = false
            return
        elseif Menu.Get("Misc.StayInv") then
            local pPos = Player.Position
            for k, v in pairs(ObjManager.Get("enemy", "heroes")) do
                local hero = v.AsHero
                if hero and hero:Distance(pPos) < 400 and hero.IsMelee and hero.IsTargetable then
                    args.Process = false
                    return
                end
            end
        end
    end

    local mode = Orbwalker.GetMode()
    if mode == "Combo" or mode == "Harass" then
        for k, v in ipairs(TS:GetTargets(-1, true)) do
            local hero = v.AsHero
            if hero and Vayne.GetStacksW(hero) == 2 then
                args.Target = hero
                return
            end
        end
    end 
end

---@param _target AttackableUnit
function Vayne.OnPostAttack(_target)
    local target = _target.AsAI
    if not target then return end    
    
    local mode = Orbwalker.GetMode()    
    if target.IsHero then
        if mode == "Combo" and Menu.Get("Duel.Enabled") and spells.R:IsReady() then
            if Menu.Get("Duel." .. target.CharName, true) and spells.R:Cast() then
                return
            end
        end
        if mode == "Harass" and Menu.Get("Harass.ProcE") and spells.E:IsReady() then
            if Vayne.GetStacksW(target) == 1 and spells.E:Cast(target) then
                return
            end
        end
    elseif mode == "Waveclear" and spells.Q:IsReady() then 
        if target.IsStructure then
            local pPos = Player.Position
            local aaRange = TS:GetTrueAutoAttackRange(Player, target) * 0.9
            local bestPos, bestDist = nil, 600
    
            local points = Geometry.Circle(target.Position, aaRange):GetPoints(20)
            for k, point in ipairs(points) do
                local dist = pPos:Distance(point)
                if dist <= bestDist and point:IsWall() then
                    bestPos = point
                    bestDist = dist                
                end
            end    
            if bestPos and spells.Q:Cast(bestPos) then
                return
            end
        elseif target.IsMinion then
            local shouldCastQ = false
            if (target.IsNeutral) then
                shouldCastQ = Menu.Get("Clear.JungleQ")
            else
                shouldCastQ = Menu.Get("Clear.PushQ")
            end
    
            if shouldCastQ and spells.Q:Cast(Renderer.GetMousePos()) then
                return
            end
        end
    end
end

function Vayne.LoadMenu()
    Menu.RegisterMenu("UnrulyVayne", "Unruly Vayne", function()
        Menu.ColumnLayout("cols", "cols", 3, true, function()
            Menu.ColoredText("Combo", 0xFFD700FF, true)
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true) 
            Menu.Dropdown("Combo.LogicQ", "[Q] Logic", 0, {"Unruly", "To Mouse", "Kiting Only"}) 
            Menu.Checkbox("Combo.UseE", "Use [E] To Stun", true) 
            Menu.Checkbox("Combo.UseR", "Use [R]", true) 
            Menu.Slider("Combo.MinR", "Min Enemies Nearby", 2, 1, 5) 

            Menu.NextColumn()

            Menu.ColoredText("Harass", 0xFFD700FF, true)
            Menu.Checkbox("Harass.UseQ",   "Use [Q]", true) 
            Menu.Dropdown("Harass.LogicQ", "[Q] Logic", 0, {"Unruly", "To Mouse", "Kiting Only"}) 
            Menu.Checkbox("Harass.UseE",   "Use [E] To Stun", false) 
            Menu.Checkbox("Harass.ProcE",  "Use [E] To Proc [W]", true) 

            Menu.NextColumn()

            Menu.ColoredText("Clear", 0xFFD700FF, true)
            Menu.Checkbox("Clear.JungleQ", "Use [Q] Jungle", true) 
            Menu.Checkbox("Clear.PushQ",   "Use [Q] Push", false) 
            Menu.Checkbox("Clear.TurretQ", "Use [Q] On Turrets", true) 
        end)

        Menu.Separator()

        Menu.ColumnLayout("cols2", "cols2", 3, true, function()
            Menu.ColoredText("Misc Options", 0xFFD700FF, true)
            Menu.Checkbox("Misc.ObvMode", "Obvious Scripter Mode", true) 
            Menu.Checkbox("Misc.StayInv", "Stay Inv. Dangerous", true) 
            Menu.Checkbox("Misc.AutoE", "Auto [E] Stun", true) 
            Menu.Dropdown("Misc.ChanceE", "Stun Chance", 2, {"Low", "Normal", "High", "Very High", "Guaranteed"}) 
            Menu.Checkbox("Misc.GapQ",  "Use [Q] Gapclose", true) 
            Menu.Checkbox("Misc.GapE",  "Use [E] Gapclose", true) 
            Menu.Checkbox("Misc.IntE",  "Use [E] Interrupt", true) 
            
            Menu.NextColumn()


            Menu.ColoredText("Peel Options", 0xFFD700FF, true)
            Menu.Checkbox("Peel.Q", "Use [Q] For Peel", true) 
            Menu.Checkbox("Peel.E", "Use [E] For Peel", false) 
            Menu.Indent(function()
                local alreadyAdded = {}
                for k, v in pairs(ObjManager.Get("enemy", "heroes")) do
                    local name = v.AsHero.CharName
                    if not alreadyAdded[name] then
                        Menu.Checkbox("Peel." .. name, name, false)
                    end
                    alreadyAdded[name] = true                    
                end
            end)

            Menu.NextColumn()

            Menu.ColoredText("Duel Options", 0xFFD700FF, true)
            Menu.Checkbox("Duel.Enabled", "Use For Duel", true) 
            Menu.Indent(function()
                local alreadyAdded = {}                
                for k, v in pairs(ObjManager.Get("enemy", "heroes")) do
                    local name = v.AsHero.CharName
                    if not alreadyAdded[name] then
                        Menu.Checkbox("Duel." .. name, name, false)
                    end
                    alreadyAdded[name] = true    
                end
            end)
        end)        

        Menu.Separator()

        Menu.ColoredText("Draw Options", 0xFFD700FF, true)
        Menu.Checkbox("Drawing.Q.Enabled",   "Draw [Q] Range")  -- Done
        Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0xEF476FFF)  -- Done
        Menu.Checkbox("Drawing.E.Enabled",   "Draw [E] Range")  -- Done
        Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x118AB2FF)  -- Done
    end)
end

function OnLoad()
    Vayne.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Vayne[eventName] then
            EventManager.RegisterCallback(eventId, Vayne[eventName])
        end
    end
    return true
end