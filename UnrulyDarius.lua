--[[
    First Release By Thorn @ 18.Oct.2020    
]]

if Player.CharName ~= "Darius" then return end

module("Unruly Darius", package.seeall, log.setup)
clean.module("Unruly Darius", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyDarius.lua", "1.0.5")

local clock = os.clock
local insert, sort = table.insert, table.sort
local huge, min, max, abs, ceil, pi, sin, cos = math.huge, math.min, math.max, math.abs, math.ceil, math.pi, math.sin, math.cos

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell
local Vector = Geometry.Vector

---@type TargetSelector
local TS = _G.Libs.TargetSelector()    
local Darius = {}

local spells = {
    Q = Spell.Active({
        Slot = Enums.SpellSlots.Q,
        Range = 420,
        Delay = 0.75,

        LastCast = 0,
        MinRange = 275,
    }),
    W = Spell.Active({
        Slot = Enums.SpellSlots.W,
        Range = Orbwalker.GetTrueAutoAttackRange(Player) + 25,

        LastCast = 0
    }),
    E = Spell.Skillshot({
        Slot = Enums.SpellSlots.E,
        Range = 535,
        Delay = 0.25,
        Radius = 50,
        Type = "Cone"
    }),
    R = Spell.Targeted({
        Slot = Enums.SpellSlots.R,
        Range = 475,
        Delay = 0.36
    })
}

-- local rocketSprite = Renderer.CreateSprite("Rocket.png", 256, 256)

local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end
local function CountHeroesInRange(team, range)
    return #(TS:GetValidTargets(range, ObjManager.Get(team, "heroes"), false))
end

function Darius.GetDamageR(target)
    local rawDmg = (100 * spells.R:GetLevel()) + (0.75 * Player.BonusAD)
    local buff = target:GetBuff("DariusHemo")
    if buff then
        rawDmg = rawDmg * (1 + 0.2 * buff.Count)
    end    
    return rawDmg
end
function Darius.IsEnabledAndReady(spell, mode)
    return Menu.Get(mode..".Use"..spell) and spells[spell]:IsReady()
end
local lastTick = 0
function Darius.OnTick()    
    if not GameIsAvailable() then return end    

    if Darius.Auto() or not Orbwalker.CanCast() then return end
    
    local gameTime = Game.GetTime()
    if gameTime < (lastTick + 0.2) then return end
    lastTick = gameTime    

    local ModeToExecute = Darius[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end
function Darius.OnDraw() 
    --rocketSprite:Draw(Renderer.GetCursorPos(), 0, true)

    local playerPos = Player.Position
    local pRange = Orbwalker.GetTrueAutoAttackRange(Player)   
    
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

function Darius.Auto()
    local gameTime = Game.GetTime()
    if Menu.Get("Misc.Magnet") and (gameTime < (spells.Q.LastCast + 0.5) or Player:GetBuff("dariusqcast")) then 
        if gameTime > (Orbwalker.TimeOfLastMove() + 0.08) then 
            local bestPos, hitCount = Darius.GetBestPosQ()
            if hitCount > 0 and Player.Pathing.EndPos:Distance(bestPos) > 50 then
                Input.MoveTo(bestPos)
                Orbwalker.BlockMove(true)
                return true
            end
        end        
    else
        Orbwalker.BlockMove(false)
    end

    if Orbwalker.GetMode() == "Combo" and Darius.IsEnabledAndReady("R", "Combo") then
        for k, v in pairs(ObjManager.Get("enemy", "heroes")) do
            local hero = v.AsHero
            if hero and TS:IsValidTarget(hero, spells.R.Range) then    
                local killHealth = HealthPred.GetKillstealHealth(hero, spells.R.Delay, Enums.DamageTypes.True)
                if Darius.GetDamageR(hero) > killHealth and spells.R:Cast(hero) then
                    return true
                end
            end
        end
    end
end

function Darius.ComboLogic(mode)  
    if Darius.IsEnabledAndReady("Q", mode) then
        local qTarget = spells.Q:GetTarget()        
        if qTarget then
            local waitForW = Game.GetTime() < (spells.W.LastCast + 0.5) or Player:GetBuff("NoxianTacticsONH")
            if not (waitForW and TS:IsValidAutoRange(qTarget)) and spells.Q:Cast() then
                return
            end
        end
    end
    if Darius.IsEnabledAndReady("E", mode) then
        local eTarget = spells.E:GetTarget()
        if eTarget and not TS:IsValidAutoRange(eTarget) then
            if spells.E:Cast(eTarget) then
                return
            end            
        end
    end
end

function Darius.Combo()     Darius.ComboLogic("Combo")  end
function Darius.Harass()    Darius.ComboLogic("Harass") end

---@param _target AttackableUnit
function Darius.OnPostAttack(_target)
    local target = _target.AsAI
    if not (target and spells.W:IsReady()) then return end    
    
    local CastTurret = Menu.Get("Misc.TurretW") and target.IsTurret
    local CastHero = false

    local mode = Orbwalker.GetMode()
    if (mode == "Combo" or mode == "Harass") then
        CastHero = Menu.Get(mode .. ".UseW") and target.IsHero
    end    

    if CastHero or CastTurret then
        spells.W:Cast()
    end
end
---@param source AIBaseClient
---@param dash DashInstance
function Darius.OnGapclose(source, dash)
    if not (Menu.Get("Misc.GapE") and spells.E:IsReady()) then return end
    if not (source.IsEnemy and spells.E:IsInRange(source)) then return end
    
    local paths  = dash:GetPaths()
    local endPos = paths[#paths].EndPos 

    local pPos = Player.Position 
    if pPos:Distance(endPos) > spells.E.Range then
        spells.E:CastOnHitChance(source, Enums.HitChance.Low)       
    end    
end

---@param source AIBaseClient
---@param spell SpellCast
function Darius.OnInterruptibleSpell(source, spell, danger, endT, canMove)
    if not (source.IsEnemy and Menu.Get("Misc.IntE") and spells.E:IsReady() and danger > 2) then return end

    spells.E:CastOnHitChance(source, Enums.HitChance.Low)
end

function Darius.OnProcessSpell(obj, spell)
    if obj.IsMe then
        if spell.Slot == spells.Q.Slot then
            spells.Q.LastCast = Game.GetTime()
        elseif spell.Slot == spells.W.Slot then
            spells.W.LastCast = Game.GetTime()
        end
    end
end

local minRange, maxRange, midRange = spells.Q.MinRange, spells.Q.Range, (spells.Q.MinRange+spells.Q.Range)/2 
function Darius.CountEnemiesHitQ(points, pos)
    local hit = 0    

    for k, v in ipairs(points) do
        local dist = v:Distance(pos)
        if dist > minRange and dist < maxRange then
            hit = hit + (1/max(abs(dist - midRange), 50))
        end
    end

    return hit
end

function Darius.GetBestPosQ()     
    local pPos = Player.Position
    local buff = Player:GetBuff("dariusqcast")
    
    local timeLeft = buff and buff.DurationLeft or spells.Q.Delay
    local maxDist = timeLeft * Player.MoveSpeed
    local bestDist = maxDist + spells.Q.Range

    local points = {}
    for k, enemy in pairs(ObjManager.Get("enemy", "heroes")) do
        local hero = enemy.AsHero
        if hero and hero.IsTargetable and hero:Distance(pPos) < bestDist then
            insert(points, hero:FastPrediction(timeLeft))
        end
    end

    local bestPos, bestCount = pPos, Darius.CountEnemiesHitQ(points, pPos)
    local posChecked, maxPosToCheck = 0, 50
    local radiusIndex, posRadius = 0, 25

    while posChecked < maxPosToCheck do
        radiusIndex = radiusIndex + 1

        local curRadius = radiusIndex * (2 * posRadius)
        local curCircleChecks = ceil((pi * curRadius) / posRadius)
        for i=1, curCircleChecks-1 do
            posChecked = posChecked + 1

            local cRad = (2 * pi / (curCircleChecks-1)) * i
            local pos = Vector(pPos.x + curRadius * cos(cRad), pPos.y, pPos.z + curRadius * sin(cRad))            
            local dist = pos:Distance(pPos)
            local hit = Darius.CountEnemiesHitQ(points, pos)

            if hit > bestCount or (hit == bestCount and dist < bestDist) then
                bestPos, bestCount, bestDist = pos, hit, dist
            end
        end
    end

    return bestPos, bestCount
end

function Darius.LoadMenu()
    Menu.RegisterMenu("UnrulyDarius", "Unruly Darius", function()
            Menu.NewTree("Combo Settings", "Combo Settings", function()
            Menu.Separator("Combo Settings")
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true)
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)
            Menu.Checkbox("Combo.UseR", "Use [R]", true)
        end)

            Menu.NewTree("Harass Settings", "Harass Settings", function()
            Menu.Separator("Harass Settings")
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true)
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
            Menu.Checkbox("Harass.UseE", "Use [E]", true)
        end)
    
            Menu.NewTree("Misc Options", "Misc Options", function()
            Menu.Separator("Misc Options")
            Menu.Checkbox("Misc.Magnet", "Force Move To Hit [Q]", true)
            Menu.Checkbox("Misc.TurretW", "Use [W] On Turrets", true)
            Menu.Checkbox("Misc.GapE", "Use [E] Gapclose", true)
            Menu.Checkbox("Misc.IntE", "Use [E] Interrupt", true)
        end)
        
            Menu.Separator("Drawing Options", 0xFFD700FF, true)
            Menu.Checkbox("Drawing.Q.Enabled", "[Q] Range", true)
            Menu.ColorPicker("Drawing.Q.Color", "[Q] Color", 0xEF476FFF)
            Menu.Checkbox("Drawing.E.Enabled", "[E] Range")
            Menu.ColorPicker("Drawing.E.Color", "[E] Color", 0x118AB2FF)
            Menu.Checkbox("Drawing.R.Enabled", "[R] Range")
            Menu.ColorPicker("Drawing.R.Color", "[R] Color", 0xFFD166FF)
            Menu.Separator("Author: Thorn")
    end)
end

function OnLoad()
    Darius.LoadMenu()

    for eventName, eventId in pairs(Enums.Events) do
        if Darius[eventName] then
            EventManager.RegisterCallback(eventId, Darius[eventName])
        end
    end    
    return true
end
