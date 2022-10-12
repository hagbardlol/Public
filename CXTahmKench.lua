local Player = _G.Player
if Player.CharName ~= "TahmKench" then return end
local DreamTS = _G.DreamTS or require("DreamTS")

--[[These 2 lines let you call DEBUG(), INFO(), WARN() etc]]
module("CX TahmKench", package.seeall, log.setup)
clean.module("CX TahmKench", clean.seeall, log.setup)

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred, DamageLib = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred, _G.Libs.DamageLib
local Spell = _G.Libs.Spell

---@type AIHeroClient
local myHero = Player



local TahmKench = {}
local version = 1.0

local SCRIPT_NAME, VERSION, LAST_UPDATE = "CXTahmKench", "1.2", "22/08/2022"
_G.CoreEx.AutoUpdate("https://raw.githubusercontent.com/Coozbie/hagbardlol/Public/CXTahmKench.lua", VERSION)

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


local ignite =
    myHero:GetSpell(Enums.SpellSlots.Summoner1).Name == "SummonerDot" and Enums.SpellSlots.Summoner1 or
    myHero:GetSpell(Enums.SpellSlots.Summoner2).Name == "SummonerDot" and Enums.SpellSlots.Summoner2 or
    nil

function TahmKench:__init()
    self.q = setmetatable({
        type = "linear",
        speed = 2800 * (myHero.BoundingRadius/80),
        delay = 0.25,
        width = 140,
        collision = {
            ["Wall"] = true,
            ["Hero"] = true,
            ["Minion"] = true,
        }
    }, {__index = function(self, key) if key == "range" then return ((myHero.BoundingRadius/80) * 835) end end})
    self.w = setmetatable({
        type = "circular",
        speed = math.huge,
        delay = 1.5,
        radius = 240,
    }, {__index = function(self, key) if key == "range" then return (950 + (50 * myHero:GetSpell(Enums.SpellSlots.W).Level)) end end})
    self.TS =
        DreamTS(
        "CX TahmKench",
        {
            Damage = DreamTS.Damages.AP
        }
    )
    self:Menu()
    EventManager.RegisterCallback(Enums.Events.OnTick, function() self:OnTick() end)
    EventManager.RegisterCallback(Enums.Events.OnDraw, function() self:OnDraw() end)
    EventManager.RegisterCallback(Enums.Events.OnUnkillableMinion, function(...) self:OnUnkillableMinion(...) end)
    EventManager.RegisterCallback(Enums.Events.OnDrawDamage, function(...) self:OnDrawDamage(...) end)
end

function TahmKench:Menu()
    Menu.RegisterMenu("CXTahmKench", "Cyrex TahmKench", function()
        Menu.Separator("Cyrex TahmKench Settings")
        self.TS:RenderMenu()


        Menu.NewTree("Combo", "Combo Settings", function()
            Menu.Separator("Q Settings")
            Menu.Checkbox("combo.q", "Use Q", true)
            Menu.Separator("W Settings")
            Menu.Checkbox("combo.w", "Use W", true)
            Menu.Separator("^ This Option is Troll ^")
            Menu.Separator("E Settings")
            Menu.Checkbox("combo.e", "Use E", true)
            Menu.Slider("combo.ehp", "What Grey HP% to E", 20, 0, 100, 5)
            Menu.Slider("combo.ex", "E on X Enemys in Range", 1, 0, 5, 1)
            Menu.Separator("R Settings")
            Menu.Checkbox("combo.r", "Use R for Ally", true)
            Menu.NewTree("combo.r.a", "Ally Settings", function()
                for i, enemy in pairs(ObjManager.Get("ally", "heroes")) do
                    if enemy ~= myHero then
                        Menu.Separator(enemy.CharName)
                        Menu.Slider("combo.r.a".. enemy.CharName, "Save Priority: " .. enemy.CharName, 1, 0, 5, 1)
                        Menu.Slider("combo.r.a".. enemy.CharName .. "hp", " ^- Health Percent: ", 50, 0, 100, 1)
                    end  
                end
            end)
        end)

        Menu.NewTree("Harass", "Harass Settings", function()
            Menu.Separator("Q Settings")
            Menu.Checkbox("harass.q", "Use Q", true)
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
            Menu.Separator("W Settings")
            Menu.Checkbox("jg.w", "Use W", true)            
            Menu.Separator("E Settings")
            Menu.Checkbox("jg.e", "Use E", true)
        end)

        Menu.NewTree("draws", "Draw Settings", function()
            Menu.Checkbox("draws.q", "Draw Q Range", true)
            Menu.Checkbox("draws.w", "Draw W Range", true)
            Menu.Checkbox("draws.r", "Draw R Range", true)
            Menu.Checkbox("draws.d.dmg", "Draw Combo Dmg", true)
            Menu.ColorPicker("draws.d.color", "Dmg Color", 0xFAAA1EFF)
        end)

        Menu.Separator("Author: Coozbie " .. version)
    end)
end

local color_white = 0xFFFFFFFF
local color_red = 0xFF0000FF

function TahmKench:OnDraw()
    local hero_pos = myHero.Position

    if myHero.IsOnScreen then
        if Menu.Get("draws.q") and IsSpellReady("Q") then
            Renderer.DrawCircle3D(hero_pos, self.q.range, nil, 2, 0x078DEDFF)
        end
        if Menu.Get("draws.w") and IsSpellReady("W") then
            Renderer.DrawCircle3D(hero_pos, self.w.range, nil, 2, 0x078DEDFF)
        end
        if Menu.Get("draws.r") and IsSpellReady("R") then
            Renderer.DrawCircle3D(hero_pos, 300, nil, 2, 0x078DEDFF)
        end
    end
end

function TahmKench:GetEnemyAndJungleMinions(radius, fromPos)
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

function TahmKench:JungleClear()
    if IsSpellReady("W") and Menu.Get("jg.w") then
        local JGE = ObjManager.GetNearby("neutral", "minions")
        for iJGE, objJGE in ipairs(JGE) do
            if rTS:IsValidTarget(objJGE, 700) and objJGE.MaxHealth > 3 then
                Input.Cast(Enums.SpellSlots.W, objJGE.ServerPos)
            end
        end
    end
    if IsSpellReady("Q") and Menu.Get("jg.q") then
        local JGW = ObjManager.GetNearby("neutral", "minions")
        for iJGW, objJGW in ipairs(JGW) do
            if rTS:IsValidTarget(objJGW, 650) and objJGW.MaxHealth > 3 then
                Input.Cast(Enums.SpellSlots.Q, objJGW.ServerPos)
            end
        end
    end
end

function TahmKench:pDmg(target)
    local pDamage = (8 + (52/17) * (myHero.Level - 1)) + ((myHero.MaxHealth - (570 + 68.4 * (myHero.Level - 1))) * 0.025)
    return DamageLib.CalculateMagicalDamage(myHero, target, pDamage)
end

function TahmKench:qDmg(target)
    local qDamage = (30 + (50 * myHero:GetSpell(Enums.SpellSlots.Q).Level) + (myHero.TotalAP * 0.7)) + self:pDmg(target)
    return DamageLib.CalculateMagicalDamage(myHero, target, qDamage)
end

function TahmKench:rDmg(target)
    local basedmg = ((150 * myHero:GetSpell(Enums.SpellSlots.R).Level) - 50)
    local bonushp = (0.15 + (0.05 * math.floor(myHero.TotalAP / 100)) ) * target.MaxHealth
    local rDamage = basedmg + bonushp
    return DamageLib.CalculateMagicalDamage(myHero, target, rDamage)
end

function TahmKench:CalculateElectrocuteDamage(target)
    local bonusAD, bonusAP = Player.BonusAD, Player.BonusAP
    local rawDamage = (8.824 * myHero.Level + 21.176) + (bonusAD * 0.4) + (bonusAP * 0.25)

    if bonusAP > bonusAD then
        return DamageLib.CalculateMagicalDamage(myHero, target, rawDamage)
    end
    return DamageLib.CalculatePhysicalDamage(myHero, target, rawDamage)
end

function TahmKench:OnDrawDamage(target, dmgList)
    if Menu.Get("draws.d.dmg") and target.IsOnScreen then        
        local dmg = DamageLib.GetAutoAttackDamage(Player, target, true) -- Already Adds Passive Damage
        if IsSpellReady("Q") then dmg = dmg + self:qDmg(target) end
        if IsSpellReady("W") then dmg = dmg + DamageLib.GetSpellDamage(Player, target, "W") end
        if IsSpellReady("R") then dmg = dmg + self:rDmg(target) end        
        if ignite and IsSpellReady(ignite) then dmg = dmg + (50 + (20 * myHero.Level)) end
        if myHero:GetBuff("ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua") then
            dmg = dmg + self:CalculateElectrocuteDamage(target)
        end
        table.insert(dmgList, {Damage=dmg, Color=Menu.Get("draws.d.color")})
    end
end

function TahmKench:get_stacks(target)
    local stacks = 0
    if target:GetBuff('tahmkenchpdebuffcounter') then
        stacks = target:GetBuffCount('tahmkenchpdebuffcounter')
    end
    return stacks
end

function TahmKench:CastQ(pred)
    if pred.rates["slow"] then
        Input.Cast(Enums.SpellSlots.Q, pred.castPosition)
        return true
    end
end

function TahmKench:CastW(pred)
    if pred.rates["instant"] then
        Input.Cast(Enums.SpellSlots.W, pred.castPosition)
        return true
    end
end

function TahmKench:KillSteal()
    local enemy = self:GetTargetNormal(350)
    if enemy and rTS:IsValidTarget(enemy) then
        local hp = enemy.Health
        local d = myHero:Distance(enemy)
        local r = IsSpellReady("R")
        local rd = self:rDmg(enemy)
        if r and self:get_stacks(enemy) == 3 and hp < rd and d < (350) then
            Input.Cast(Enums.SpellSlots.R, enemy)
        end
    end
end

function TahmKench:AutoShield()
    if IsSpellReady("E") then
        if Menu.Get("combo.e") and CountEnemiesInRange(myHero.ServerPos, 800) >= Menu.Get("combo.ex") and (myHero.SpecialHealth/ myHero.MaxHealth) * 100 >= Menu.Get("combo.ehp") then
            Input.Cast(Enums.SpellSlots.E)
        end
    end
end

function TahmKench:PrioritizedR()
    if Menu.Get("combo.r") and IsSpellReady("R") then
        local heroTarget = nil
        for i, hero in pairs(ObjManager.Get("ally", "heroes")) do
            if hero ~= myHero and Menu.Get("combo.r.a" .. hero.CharName) > 0 and myHero:Distance(hero) <= 300 and CountEnemiesInRange(hero.ServerPos, 500) >= 1 then
                if Menu.Get("combo.r.a" .. hero.CharName .. "hp") >= hero.HealthPercent then
                    if heroTarget == nil then
                        heroTarget = hero
                    elseif Menu.Get("combo.r.a" .. hero.CharName) < Menu.Get("combo.r.a" .. heroTarget.CharName) then
                        heroTarget = hero
                    end
                end
            end
        end
        if heroTarget then
            return heroTarget
        else
            return nil
        end    
    end
end

function TahmKench:OnTick()
    local orbMode = _G.Libs.Orbwalker.GetMode()
    local ComboMode = orbMode == "Combo"
    local HarassMode = orbMode == "Harass"
    local JungleMode = orbMode == "Waveclear"

    if IsSpellReady("E") then
        self:AutoShield()
    end

    if IsSpellReady("R") and self:PrioritizedR() then
        Input.Cast(Enums.SpellSlots.R, self:PrioritizedR())
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
        if (Menu.Get("combo.w") and ComboMode) then
            local target, pred = self.TS:GetTarget(self.w, myHero)
            if pred and self:CastW(pred) then
                return
            end
        end
    end

    if Menu.Get("auto.uks") then self:KillSteal() end
    if JungleMode then self:JungleClear() end
end

---@return AIBaseClient
function TahmKench:GetTargetNormal(dist, all)
    local res = self.TS:update(function(unit) return rTS:IsValidTarget(unit, dist) end)
    return (all and res) or (res and res[1])
end

function TahmKench:OnUnkillableMinion(minion)
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

TahmKench:__init()