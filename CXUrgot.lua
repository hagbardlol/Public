local Player = _G.Player
if Player.CharName ~= "Urgot" then return end
local DreamTS = _G.DreamTS or require("DreamTS")

--[[These 2 lines let you call DEBUG(), INFO(), WARN() etc]]
module("CX Urgot", package.seeall, log.setup)
clean.module("CX Urgot", clean.seeall, log.setup)

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred, DamageLib = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred, _G.Libs.DamageLib
local DashLib = _G.Libs.DashLib
local Spell = _G.Libs.Spell

---@type AIHeroClient
local myHero = Player



local Urgot = {}
local version = 1.1

local SCRIPT_NAME, VERSION, LAST_UPDATE = "CXUrgot", "1.3", "22/08/2022"
_G.CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/CXUrgot.lua", VERSION)

local Vector = CoreEx.Geometry.Vector
local rTS = _G.Libs.TargetSelector()

---@param objects SDK_GameObject[]
---@return SDK_AIHeroClient[]
local function GetIndexedList(objects)
    local res = {}
    for i, obj in pairs(objects) do
        res[#res+1] = obj
    end
    return res
end

local function IsSpellReady(slot_or_string)
    local slot = Enums.SpellSlots[slot_or_string] or slot_or_string
    return Player:GetSpellState(slot) == 0
end

local function GetSpellCost(slot_or_string)
    local slot = Enums.SpellSlots[slot_or_string] or slot_or_string
    local spell = Player:GetSpell(slot)
    return spell and spell.ManaCost    
end

local function CountEnemiesInRange(pos, range)
    local res = 0
    for k, hero in pairs(CoreEx.ObjectManager.Get("enemy", "heroes")) do
        if hero:Distance(pos) <= range and hero.IsTargetable then
            res = res + 1
        end
    end
    return res
end

local function CountAllyInRange(pos, range)
    local res = 0
    for k, hero in pairs(CoreEx.ObjectManager.Get("ally", "heroes")) do
        if hero:Distance(pos) <= range and hero.IsTargetable then
            res = res + 1
        end
    end
    return res
end


local ignite =
    myHero:GetSpell(Enums.SpellSlots.Summoner1).Name == "SummonerDot" and Enums.SpellSlots.Summoner1 or
    myHero:GetSpell(Enums.SpellSlots.Summoner2).Name == "SummonerDot" and Enums.SpellSlots.Summoner2 or
    nil

function Urgot:__init()
    self.q = {
        type = "circular",
        speed = math.huge,
        range = 800,
        delay = 0.25, --0.6
        radius = 170,
    }
    self.e = {
        type = "linear",
        speed = 1200,
        range = 445,
        delay = 0.45,
        width = 160,
        collision = {
            ["Wall"] = false,
            ["Hero"] = true,
            ["Minion"] = false,
        }
    }
    self.r = {
        type = "linear",
        speed = 3200,
        range = 2500,
        delay = 0.5,
        width = 160,
        collision = {
            ["Wall"] = true,
            ["Hero"] = true,
            ["Minion"] = false,
        }
    }
    self.TS =
        DreamTS(
        "CX Urgot",
        {
            Damage = DreamTS.Damages.AD
        }
    )
    self:Menu()
    EventManager.RegisterCallback(Enums.Events.OnTick, function() self:OnTick() end)
    EventManager.RegisterCallback(Enums.Events.OnDraw, function() self:OnDraw() end)
    EventManager.RegisterCallback(Enums.Events.OnUnkillableMinion, function(...) self:OnUnkillableMinion(...) end)
    EventManager.RegisterCallback(Enums.Events.OnDrawDamage, function(...) self:OnDrawDamage(...) end)
end

function Urgot:Menu()
    Menu.RegisterMenu("CXUrgot", "Cyrex Urgot", function()
        Menu.Separator("Cyrex Urgot Settings")
        self.TS:RenderMenu()


        Menu.NewTree("Combo", "Combo Settings", function()
            Menu.Separator("Q Settings")
            Menu.Checkbox("combo.q", "Use Q", true)
            Menu.Separator("W Settings")
            Menu.Checkbox("combo.w", "Use W", true)
            Menu.Separator("E Settings")
            Menu.Checkbox("combo.e", "Use E", true)
            Menu.Dropdown("combo.mode", "Choose E Mode: ", 2, {"Normal", "Smart"})  
        end)

        Menu.NewTree("Harass", "Harass Settings", function()
            Menu.Separator("Q Settings")
            Menu.Checkbox("harass.q", "Use Q", true)
            Menu.Slider("harass.mana", "Min Mana Percent", 10, 0, 100, 5)
        end)

        Menu.NewTree("Auto", "Automatic Settings", function()
            Menu.Separator("Killsteal Settings")
            Menu.Checkbox("auto.uks", "Use Killsteal", true)
            Menu.Checkbox("auto.uqks", "Use Q in Killsteal", true)
            Menu.Checkbox("auto.urks", "Use R in Killsteal", true)            
        end)

        Menu.NewTree("jg", "Jungle Settings", function()
            Menu.Separator("Q Settings")
            Menu.Checkbox("jg.q", "Use Q", true)         
            Menu.Separator("E Settings")
            Menu.Checkbox("jg.e", "Use E", true)
        end)

        Menu.NewTree("draws", "Draw Settings", function()
            Menu.Checkbox("draws.q", "Draw Q Range", true)
            Menu.Checkbox("draws.e", "Draw E Range", true)
            Menu.Checkbox("draws.r", "Draw R Range", true)
            Menu.Checkbox("draws.d.dmg", "Draw Combo Dmg", true)
            Menu.ColorPicker("draws.d.color", "Dmg Color", 0xFAAA1EFF)
        end)

        Menu.Separator("Author: Coozbie " .. version)
    end)
end

local color_white = 0xFFFFFFFF
local color_red = 0xFF0000FF

function Urgot:OnDraw()
    local hero_pos = myHero.Position

    if myHero.IsOnScreen then
        if Menu.Get("draws.q") and IsSpellReady("Q") then
            Renderer.DrawCircle3D(hero_pos, self.q.range, nil, 2, 0x078DEDFF)
        end
        if Menu.Get("draws.e") and IsSpellReady("E") then
            Renderer.DrawCircle3D(hero_pos, self.e.range, nil, 2, 0x078DEDFF)
        end
        if Menu.Get("draws.r") and IsSpellReady("R") then
            Renderer.DrawCircle3D(hero_pos, 300, nil, 2, 0x078DEDFF)
        end
    end
end

function Urgot:GetEnemyAndJungleMinions(radius, fromPos)
    fromPos = fromPos or Player.ServerPos

    local result = {}

    ---@param group GameObject[]
    local function AddIfValid(group)
        for _, unit in ipairs(group) do
            local minion = unit.AsMinion

            if rTS:IsValidTarget(minion, radius, fromPos) then
                result[#result+1] = minion
            end
        end
    end

    local enemyMinions = ObjManager.GetNearby("enemy", "minions")
    local jungleMinions = ObjManager.GetNearby("neutral", "minions")

    AddIfValid(enemyMinions)
    AddIfValid(jungleMinions)

    return result
end

function Urgot:JungleClear()
    if IsSpellReady("E") and Menu.Get("jg.e") then
        local JGE = ObjManager.GetNearby("neutral", "minions")
        for iJGE, objJGE in ipairs(JGE) do
            if rTS:IsValidTarget(objJGE, 445) and objJGE.MaxHealth > 3 then
                Input.Cast(Enums.SpellSlots.E, objJGE.ServerPos)
            end
        end
    end
    if IsSpellReady("Q") and Menu.Get("jg.q") then
        local JGW = ObjManager.GetNearby("neutral", "minions")
        for iJGW, objJGW in ipairs(JGW) do
            if rTS:IsValidTarget(objJGW, 700) and objJGW.MaxHealth > 3 then
                Input.Cast(Enums.SpellSlots.Q, objJGW.ServerPos)
            end
        end
    end
end


function Urgot:qDmg(target)
    local qDamage = (((45 * myHero:GetSpell(Enums.SpellSlots.Q).Level) - 20)  + (myHero.TotalAD * 0.7))
    return DamageLib.CalculatePhysicalDamage(myHero, target, qDamage)
end

function Urgot:rDmg(target)
    local rDamage = (((125 * myHero:GetSpell(Enums.SpellSlots.Q).Level) - 25)  + (myHero.BonusAD * 0.5))
    return DamageLib.CalculatePhysicalDamage(myHero, target, rDamage)
end

function Urgot:CalculateElectrocuteDamage(target)
    local bonusAD, bonusAP = Player.BonusAD, Player.BonusAP
    local rawDamage = (8.824 * myHero.Level + 21.176) + (bonusAD * 0.4) + (bonusAP * 0.25)

    if bonusAP > bonusAD then
        return DamageLib.CalculateMagicalDamage(myHero, target, rawDamage)
    end
    return DamageLib.CalculatePhysicalDamage(myHero, target, rawDamage)
end

function Urgot:OnDrawDamage(target, dmgList)
    if Menu.Get("draws.d.dmg") and target.IsOnScreen then        
        local dmg = DamageLib.GetAutoAttackDamage(Player, target, true) -- Already Adds Passive Damage
        if IsSpellReady("Q") then dmg = dmg + self:qDmg(target) end
        if IsSpellReady("E") then dmg = dmg + DamageLib.GetSpellDamage(Player, target, "E") end
        if IsSpellReady("R") then dmg = dmg + self:rDmg(target) end        
        if ignite and IsSpellReady(ignite) then dmg = dmg + (50 + (20 * myHero.Level)) end
        if myHero:GetBuff("ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua") then
            dmg = dmg + self:CalculateElectrocuteDamage(target)
        end
        table.insert(dmgList, {Damage=dmg, Color=Menu.Get("draws.d.color")})
    end
end

function Urgot:CastQ(pred)
    if pred.rates["slow"] then
        Input.Cast(Enums.SpellSlots.Q, pred.castPosition)
        return true
    end
end

function Urgot:CastE(pred)
    if pred.rates["instant"] then
        Input.Cast(Enums.SpellSlots.E, pred.castPosition)
        return true
    end
end

function Urgot:CastGPE(target)
    if IsSpellReady("E") then
        if myHero:Distance(target) < 800 and myHero:Distance(target) > 456 then
            Input.Cast(Enums.SpellSlots.E, target.Position)
        end
    end
end

function Urgot:CastR(target)
    if IsSpellReady("R") and myHero:GetSpell(Enums.SpellSlots.R).Name == "UrgotR" then
        local pred = _G.DreamPred.GetPrediction(target, self.r, myHero.Position)
        if pred and pred.castPosition and pred.rates["slow"] and myHero:Distance(pred.castPosition) <= self.r.range then
            if CountAllyInRange(target.ServerPos, 500) < 2 then
                Input.Cast(Enums.SpellSlots.R, pred.castPosition)
            end
        end
    end
end

function Urgot:KillSteal()
    local enemy = self:GetTargetNormal(2500)
    if enemy and rTS:IsValidTarget(enemy) then
        local hp = enemy.Health
        local d = myHero:Distance(enemy)
        local r = IsSpellReady("R")
        local rd = self:rDmg(enemy)
        if r and d < (2500) and ((hp - rd)/enemy.MaxHealth) * 100 <= 25 then
            self:CastR(enemy)
        end
    end
end


function Urgot:OnTick()
    local orbMode = _G.Libs.Orbwalker.GetMode()
    local ComboMode = orbMode == "Combo"
    local HarassMode = orbMode == "Harass"
    local JungleMode = orbMode == "Waveclear"

    if IsSpellReady("E") then
        local target, pred = self.TS:GetTarget(self.e, myHero)
        if ComboMode and target and Menu.Get("combo.e") then
            local d = myHero:Distance(target)
            if Menu.Get("combo.mode") == 2 then
                if d > 456 and 50 > target.HealthPercent and target.HealthPercent < myHero.HealthPercent then
                    self:CastGPE(target)
                elseif d < 445 and target.HealthPercent < myHero.HealthPercent then
                    if pred and pred.castPosition and self:CastE(pred) then
                        return
                    end
                end
            end
            if Menu.Get("combo.mode") == 1 then
                if pred and pred.castPosition and self:CastE(pred) then
                    return
                end
            end
        end
    end

    if IsSpellReady("Q") then
        local target, pred = self.TS:GetTarget(self.q, myHero)
        if pred and pred.castPosition then
            if ((Menu.Get("combo.q") and ComboMode) or (Menu.Get("harass.q") and HarassMode)) and self:CastQ(pred) then
                return
            end
            if Menu.Get("auto.uqks") then                    
                local time = self.q.delay + myHero:Distance(pred.castPosition)/self.q.speed
                local dmg = self:qDmg(target)
                local health = HealthPred.GetKillstealHealth(target, time, Enums.DamageTypes.Physical)
                if dmg > health and self:CastQ(pred) then return end
            end
        end
    end

    if IsSpellReady("W") then
        local target = self:GetTargetNormal(480)
        if (Menu.Get("combo.w") and ComboMode) and target then
            if myHero:Distance(target) < 460 and myHero:GetSpell(Enums.SpellSlots.W).Name == "UrgotW" then
                Input.Cast(Enums.SpellSlots.W)
            end
            if myHero:Distance(target) > 475 and myHero:GetSpell(Enums.SpellSlots.W).Name ~= "UrgotW" then
                Input.Cast(Enums.SpellSlots.W)
            end
        end
    end

    if Menu.Get("auto.uks") then self:KillSteal() end
    if myHero:GetSpell(Enums.SpellSlots.R).Name == "UrgotRRecast" then Input.Cast(Enums.SpellSlots.R) end
    if JungleMode then self:JungleClear() end
    if myHero:GetBuff('UrgotW') then
        _G.Libs.Orbwalker.BlockAttack(true)
    else
        _G.Libs.Orbwalker.BlockAttack(false)
    end
end

---@return AIBaseClient
function Urgot:GetTargetNormal(dist, all)
    local res = self.TS:update(function(unit) return rTS:IsValidTarget(unit, dist) end)
    return (all and res) or (res and res[1])
end

function Urgot:OnUnkillableMinion(minion)
    if Orbwalker.IsIgnoringMinion(minion) then        
        return
    end

    local dist = myHero:Distance(minion)
    if IsSpellReady("Q") and dist <= self.q.range then
        local time = self.q.delay + dist/self.q.speed
        local dmg = DamageLib.GetSpellDamage(myHero, minion, Enums.SpellSlots.Q)
        local health = HealthPred.GetHealthPrediction(minion, time)
        if dmg > health and Input.Cast(Enums.SpellSlots.Q, minion:FastPrediction(time*1000)) then
            Orbwalker.IgnoreMinion(minion)
            return
        end
    end
end

Urgot:__init()
