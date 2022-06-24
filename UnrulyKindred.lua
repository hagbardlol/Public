--[[
    First Release By Thorn @ 10.Oct.2020    
]]

if Player.CharName ~= "Kindred" then return end

module("Unruly Kindred", package.seeall, log.setup)
clean.module("Unruly Kindred", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyKindred.lua", "1.0.4")

local clock = os.clock
local insert, sort = table.insert, table.sort
local huge, min, max, abs = math.huge, math.min, math.max, math.abs

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

local TS = _G.Libs.TargetSelector()
local Kindred = {}

local spells = {
    Q = Spell.Skillshot({
        Slot = Enums.SpellSlots.Q,
        Range = 340,
        Type = "Linear"
    }),
    W = Spell.Skillshot({
        Slot = Enums.SpellSlots.W,
        Range = 500,
        Delay = 0.4,
        Speed = 1400,
        Radius = 800,
        Type = "Circular"
    }),
    E = Spell.Targeted({
        Slot = Enums.SpellSlots.E,
        Range = 500,
        Delay = 0.25,
    }),
    R = Spell.Active({
        Slot = Enums.SpellSlots.R,
        Range = 500,
    })
}

local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end
local function CountHeroesInRange(team, range)
    return #(TS:GetValidTargets(range, ObjManager.Get(team, "heroes"), false))
end

function Kindred.IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell) and spells[spell]:IsReady()
end
local lastTick = 0
function Kindred.OnTick()    
    if not GameIsAvailable() then return end    

    if Kindred.Auto() then return end
    if not Orbwalker.CanCast() then return end

    local gameTime = Game.GetTime()
    if gameTime < (lastTick + 0.25) then return end
    lastTick = gameTime    

    local ModeToExecute = Kindred[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end
function Kindred.OnDraw() 
    local playerPos = Player.Position
    local pRange = Orbwalker.GetTrueAutoAttackRange(Player)   
    
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

function Kindred.ComboLogic(mode)
    if Kindred.IsEnabledAndReady("Q", mode) then
        local qTarget = TS:GetTarget(spells.Q.Range + 500)
        if qTarget then
            local tPos = qTarget.Position
            local distToMouse  = tPos:Distance(Renderer.GetMousePos())
            local distToPlayer = tPos:Distance(Player)

            if distToMouse < distToPlayer and distToPlayer > Orbwalker.GetTrueAutoAttackRange(Player, qTarget) then
                if spells.Q:Cast(tPos) then
                    return
                end
            end
        end
    end
    if Kindred.IsEnabledAndReady("W", mode) then
        local wTarget = TS:GetTarget(spells.W.Range + 200)
        if wTarget and spells.W:Cast(wTarget:FastPrediction(spells.W.Delay)) then
            return
        end
    end
    if Kindred.IsEnabledAndReady("E", mode) then
        local eTarget = TS:GetTarget(spells.E.Range + 200)

        if eTarget then
            local aaRange = Orbwalker.GetTrueAutoAttackRange(Player, eTarget)
            local dist = eTarget:Distance(Player)
            if dist < aaRange and dist > (aaRange - 150) and spells.E:Cast(eTarget) then
                return
            end            
        end
    end
end

function Kindred.Auto() 
    if not spells.R:IsReady() then return end

    local pPos = Player.Position
    local maxRange = spells.R.Range
    local castDelay = 0.15 + spells.R.Delay + Game.GetLatency()/1000

    for k, v in pairs(ObjManager.Get("ally", "heroes")) do
        local hero = v.AsHero
        if hero and hero:Distance(pPos) < maxRange and hero.IsTargetable then
            local minHealth = (Menu.Get("AutoR."..hero.CharName, true) or 0)/100

            local predDmg = HealthPred.GetDamagePrediction(hero, castDelay, false) 
            local predHealth = (hero.Health - predDmg) / hero.MaxHealth
            if predHealth < minHealth and (predDmg > 0 or CountHeroesInRange("enemy", 1000) > 0) then                
                return spells.R:Cast() 
            end
        end        
    end
end

function Kindred.Combo()  Kindred.ComboLogic("Combo")  end
function Kindred.Harass() Kindred.ComboLogic("Harass") end

function Kindred.OnPreAttack(args) --args: {Process, Target}
    if not Menu.Get("Misc.FocusE") then return end

    for k, enemy in pairs(TS:GetTargets(-1)) do
        if enemy:GetBuff("kindredecharge") then 
            args.Target = enemy
            return
        end
    end
end
---@param _target AttackableUnit
function Kindred.OnPostAttack(_target)
    local target = _target.AsAI
    if not target then return end
    
    local mode = Orbwalker.GetMode()
    local dist = target:Distance(Player)

    if target.IsMonster and mode == "Waveclear" and target.MaxHealth > 6 then
        if dist < spells.W.Range and Kindred.IsEnabledAndReady("W", "JClear") and spells.W:Cast(target.Position)then
            return
        end
        if dist < Orbwalker.GetTrueAutoAttackRange(Player, target) and Kindred.IsEnabledAndReady("E", "JClear") and spells.E:Cast(target) then
            return
        end
        if dist < (spells.Q.Range + 500) and Kindred.IsEnabledAndReady("Q", "JClear") and spells.Q:Cast(Renderer.GetMousePos())then
            return
        end
    end

    if not (mode == "Combo" or mode == "Harass") then return end
    if target.IsHero and dist < (spells.Q.Range + 500) and Kindred.IsEnabledAndReady("Q", mode) then
        local castPos, logic = nil, Menu.Get(mode..".ModeQ")
        if logic == 0 then -- "Smart"
            local pPos = Player.Position
            local cPos = Renderer.GetMousePos()

            local ePos = target:FastPrediction(0.25)
            local eRange = Orbwalker.GetTrueAutoAttackRange(target, Player)
            local eMelee = target.IsMelee
            local eDist = pPos:Distance(ePos)

            local path = Geometry.CircleCircleIntersection(pPos, spells.Q.Range, ePos, eRange)
            if #path > 0 and (not eMelee or eDist > 500) then
                local closestToCursor = (path[1]:Distance(cPos) < path[2]:Distance(cPos) and path[1]) or path[2]
                castPos = pPos:Extended(closestToCursor, 150)
            else
                local pRange = Orbwalker.GetTrueAutoAttackRange(Player, target)
                local distFromBorder = max(150, abs(eRange - eDist))
                local kitingPos = pPos:Extended(ePos, -distFromBorder)
                local toMouse = pPos:Extended(cPos, 150)

                local mDist = toMouse:Distance(pPos)
                if mDist < (pRange * 0.9) and (not eMelee or mDist > eRange) then
                    castPos = toMouse
                elseif eMelee and eDist < eRange and kitingPos:Distance(ePos) < (pRange * 0.9) then
                    castPos = kitingPos
                end
            end
        elseif logic == 1 then --"Cursor Position"
            castPos = Player.Position:Extended(Renderer.GetMousePos(), 150)            
        end

        if castPos and spells.Q:Cast(castPos) then
            return
        end
    end
end
---@param source AIBaseClient
---@param dash DashInstance
function Kindred.OnGapclose(source, dash)
    if not source.IsEnemy then return end

    local paths = dash:GetPaths()
    local endPos = paths[#paths].EndPos
    local pPos = Player.Position
    local pDist = pPos:Distance(endPos)

    if pDist < 500 and pDist < pPos:Distance(dash.StartPos) and source:IsFacing(pPos) then
        if Menu.Get("Misc.GapQ") and spells.Q:IsReady() then
            local p = pPos:Extended(endPos, -spells.Q.Range)
            if spells.Q:Cast(p) then
                return
            end
        end
        if Menu.Get("Misc.GapW") and spells.W:IsReady() then
            if spells.W:Cast(endPos) then
                return
            end
        end
    end
end

function Kindred.LoadMenu()
    Menu.RegisterMenu("UnrulyKindred", "Unruly Kindred", function()
        Menu.ColumnLayout("cols", "cols", 3, true, function()
            Menu.ColoredText("Combo", 0xFFD700FF, true)
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true)    
            Menu.Dropdown("Combo.ModeQ", "Mode [Q]", 0, {"Smart", "Cursor Position"}) 
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)

            Menu.NextColumn()

            Menu.ColoredText("Harass", 0xFFD700FF, true)
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true)    
            Menu.Dropdown("Harass.ModeQ", "Mode [Q]", 0, {"Smart", "Cursor Position"}) 
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
            Menu.Checkbox("Harass.UseE", "Use [E]", true)

            Menu.NextColumn()

            Menu.ColoredText("Jungle", 0xFFD700FF, true)
            Menu.Checkbox("JClear.UseQ", "Use [Q]", true)     
            Menu.Checkbox("JClear.UseW", "Use [W]", true)
            Menu.Checkbox("JClear.UseE", "Use [E]", true)
        end) 

        Menu.Separator()
        Menu.ColumnLayout("cols2", "cols2", 2, true, function()
            Menu.ColoredText("Misc Options", 0xFFD700FF, true)
            Menu.Checkbox("Misc.GapQ", "Use [Q] Gapclose", true)  
            Menu.Checkbox("Misc.GapW", "Use [W] Gapclose", true)  
            Menu.Checkbox("Misc.FocusE", "Focus [E] Target", true)

            Menu.NextColumn()

            Menu.ColoredText("Use [R] Below %", 0xFFD700FF, true)  
            for k, v in pairs(ObjManager.Get("ally", "heroes")) do
                local name = v.AsHero.CharName
                Menu.Slider("AutoR."..name, name, 20, 0, 100) 
            end
        end)

        Menu.Separator()
        Menu.ColoredText("Drawing Options", 0xFFD700FF, true)
        Menu.Checkbox("Drawing.Q.Enabled",   "Draw [Q] Range")
        Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0xEF476FFF) 
        Menu.Checkbox("Drawing.W.Enabled",   "Draw [W] Range")
        Menu.ColorPicker("Drawing.W.Color", "Draw [W] Color", 0x06D6A0FF) 
        Menu.Checkbox("Drawing.E.Enabled",   "Draw [E] Range")
        Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x118AB2FF) 
        Menu.Checkbox("Drawing.R.Enabled",   "Draw [R] Range")
        Menu.ColorPicker("Drawing.R.Color", "Draw [R] Color", 0xFFD166FF)
    end)
end

function OnLoad()
    Kindred.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Kindred[eventName] then
            EventManager.RegisterCallback(eventId, Kindred[eventName])
        end
    end    
    return true
end
