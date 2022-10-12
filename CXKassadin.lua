local Player = _G.Player
if Player.CharName ~= "Kassadin" then return end
local DreamTS = _G.DreamTS or require("DreamTS")

--[[These 2 lines let you call DEBUG(), INFO(), WARN() etc]]
module("CX Kassadin", package.seeall, log.setup)
clean.module("CX Kassadin", clean.seeall, log.setup)

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred, DamageLib = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred, _G.Libs.DamageLib
local Spell = _G.Libs.Spell

---@type AIHeroClient
local myHero = Player



local Kassadin = {}
local version = 1.1

local SCRIPT_NAME, VERSION, LAST_UPDATE = "CXKassadin", "1.3", "22/08/2022"
_G.CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/CXKassadin.lua", VERSION)

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

local interruptableSpells = {
  ["anivia"] = {{menuslot = "R", slot = 3, spellname = "glacialstorm", channelduration = 6}},
  ["caitlyn"] = {{menuslot = "R", slot = 3, spellname = "caitlynaceinthehole", channelduration = 1}},
  ["ezreal"] = {{menuslot = "R", slot = 3, spellname = "ezrealtrueshotbarrage", channelduration = 1}},
  ["fiddlesticks"] = {{menuslot = "W", slot = 1, spellname = "drain", channelduration = 5},{menuslot = "R", slot = 3, spellname = "crowstorm", channelduration = 1.5}},
  ["gragas"] = {{menuslot = "W", slot = 1, spellname = "gragasw", channelduration = 0.75}},
  ["galio"] = {{menuslot = "W", slot = 1, spellname = "galiow", channelduration = 3}},
  ["janna"] = {{menuslot = "R", slot = 3, spellname = "reapthewhirlwind", channelduration = 3}},
  ["karthus"] = {{menuslot = "R", slot = 3, spellname = "karthusfallenone", channelduration = 3}},
  ["katarina"] = {{menuslot = "R", slot = 3, spellname = "katarinar", channelduration = 2.5}},
  ["lucian"] = {{menuslot = "R", slot = 3, spellname = "lucianr", channelduration = 2}},
  ["lux"] = {{menuslot = "R", slot = 3, spellname = "luxmalicecannon", channelduration = 0.5}},
  ["malzahar"] = {{menuslot = "R", slot = 3, spellname = "malzaharr", channelduration = 2.5}},
  ["masteryi"] = {{menuslot = "W", slot = 1, spellname = "meditate", channelduration = 4}},
  ["masteryi"] = {{menuslot = "W", slot = 1, spellname = "masteryiw", channelduration = 4}},
  ["missfortune"] = {{menuslot = "R", slot = 3, spellname = "missfortunebullettime", channelduration = 3}},
  ["nunu"] = {{menuslot = "R", slot = 3, spellname = "absolutezero", channelduration = 3}},
  ["pantheon"] = {{menuslot = "R", slot = 3, spellname = "pantheonrjump", channelduration = 2}},
  ["shen"] = {{menuslot = "R", slot = 3, spellname = "shenr", channelduration = 3}},
  ["twistedfate"] = {{menuslot = "R", slot = 3, spellname = "gate", channelduration = 1.5}},
  ["varus"] = {{menuslot = "Q", slot = 0, spellname = "varusq", channelduration = 4}},
  ["warwick"] = {{menuslot = "R", slot = 3, spellname = "warwickr", channelduration = 1.5}},
  ["xerath"] = {{menuslot = "R", slot = 3, spellname = "xerathlocusofpower2", channelduration = 3}},
}

local ignite =
    myHero:GetSpell(Enums.SpellSlots.Summoner1).Name == "SummonerDot" and Enums.SpellSlots.Summoner1 or
    myHero:GetSpell(Enums.SpellSlots.Summoner2).Name == "SummonerDot" and Enums.SpellSlots.Summoner2 or
    nil

function Kassadin:__init()
    self.e = {
        type = "cone",
        speed = math.huge,
        range = 600,
        delay = 0.25,
        angle = 80,
        castRate = "instant"
    }
    self.r = {
        type = "circular",
        speed = math.huge,
        range = 550,
        delay = 0.25,
        radius = 150,
        castRate = "instant"
    }
    self.efline2 = {
        type = "linear",
        speed = 1600,
        range = 800,
        delay = 0.3,
        width = 80,
    }
    self.TS =
        DreamTS(
        "CX Kassadin",
        {
            Damage = DreamTS.Damages.AP
        }
    )
    self:Menu()
    EventManager.RegisterCallback(Enums.Events.OnTick, function() self:OnTick() end)
    EventManager.RegisterCallback(Enums.Events.OnDraw, function() self:OnDraw() end)
    EventManager.RegisterCallback(Enums.Events.OnProcessSpell, function(...) self:OnProcessSpell(...) end)
    EventManager.RegisterCallback(Enums.Events.OnPostAttack, function(target) self:OnExecuteCastFrame(target) end)
    EventManager.RegisterCallback(Enums.Events.OnUnkillableMinion, function(...) self:OnUnkillableMinion(...) end)
    EventManager.RegisterCallback(Enums.Events.OnDrawDamage, function(...) self:OnDrawDamage(...) end)
end

function Kassadin:Menu()
    Menu.RegisterMenu("CXKassadin", "Cyrex Kassadin", function()
        Menu.Separator("Cyrex Kassadin Settings")
        self.TS:RenderMenu()

        Menu.NewTree("Key", "Key Settings", function()
            Menu.Separator("UNBIND KEYS ON GAME")
            Menu.Keybind("Key.s", "Escape Key", string.byte("S"))
            -- Menu.Keybind("Key.run", "Flee", string.byte("S")) -- You should use Orbwalker.GetMode() == "Flee"
        end)

        Menu.NewTree("Combo", "Combo Settings", function()
            Menu.Separator("Q Settings")
            Menu.Checkbox("combo.q", "Use Q", true)
            Menu.Separator("W Settings")
            Menu.Checkbox("combo.w", "Use W", true)
            Menu.Separator("E Settings")
            Menu.Checkbox("combo.e", "Use E", true)
            Menu.Separator("R Settings")
            Menu.NewTree("combo.rs", "Custom Settings", function()
                Menu.Checkbox("combo.rs.ur", "Use R", false)
                Menu.Dropdown("combo.rs.rmode", "Choose Style: ", 1, {"Always", "Dmg Check"})
                Menu.Slider("combo.rs.hpr", "Min. HP% to R", 20, 10, 100, 1)
                Menu.Slider("combo.rs.rx", "R if X Enemys in Range", 1, 1, 5, 1)
                Menu.Slider("combo.rs.stacks", "Stacks to Keep", 3, 0, 4, 1)
            end)
        end)

        Menu.NewTree("Harass", "Harass Settings", function()
            Menu.Separator("Q Settings")
            Menu.Checkbox("harass.q", "Use Q", true)
            Menu.Separator("W Settings")
            Menu.Checkbox("harass.w", "Use W", true)            
            Menu.Separator("E Settings")
            Menu.Checkbox("harass.e", "Use E", true)
        end)

        Menu.NewTree("Auto", "Automatic Settings", function()
            Menu.Separator("Killsteal Settings")
            Menu.Checkbox("auto.uks", "Use Killsteal", true)
            Menu.Checkbox("auto.urks", "Use R in Killsteal", true)            
            Menu.Separator("Auto Spells")
            Menu.Checkbox("auto.q", "Use Q for Channelings", true)
            Menu.NewTree("auto.interruptmenu", "Interrupt Settings", function()
                for i, enemy in pairs(ObjManager.Get("enemy", "heroes")) do
                    local name = string.lower(enemy.CharName)
                    if interruptableSpells[name] then
                        for v = 1, #interruptableSpells[name] do
                            local spell = interruptableSpells[name][v]
                            Menu.Checkbox(string.format(tostring(enemy.CharName) .. tostring(spell.menuslot)), "Interrupt " .. tostring(enemy.CharName) .. " " .. tostring(spell.menuslot),true)
                        end
                    end
                end
            end)
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
            Menu.Checkbox("draws.r", "Draw R Range", true)
            Menu.Checkbox("draws.d.dmg", "Draw Combo Dmg", true)
            Menu.ColorPicker("draws.d.color", "Dmg Color", 0xFAAA1EFF)
        end)

        Menu.Separator("Author: Coozbie " .. version)
    end)
end

local color_white = 0xFFFFFFFF
local color_red = 0xFF0000FF

function Kassadin:OnDraw()
    local hero_pos = myHero.Position

    if myHero.IsOnScreen then
        if Menu.Get("draws.q") and IsSpellReady("Q") then
            Renderer.DrawCircle3D(hero_pos, 650, nil, 2, 0x078DEDFF)
        end
        if Menu.Get("draws.r") and IsSpellReady("R") then
            Renderer.DrawCircle3D(hero_pos, self.r.range, nil, 2, 0x078DEDFF)
        end
    end
end

function Kassadin:GetEnemyAndJungleMinions(radius, fromPos)
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

function Kassadin:OnExecuteCastFrame(target)
    if (_G.Libs.Orbwalker.GetMode() == "Combo" and Menu.Get("combo.w")) or (_G.Libs.Orbwalker.GetMode() == "Harass" and Menu.Get("harass.w")) or (_G.Libs.Orbwalker.GetMode() == "Waveclear" and Menu.Get("jg.w")) then
        if IsSpellReady("W") then
            if target and rTS:IsValidTarget(target) and myHero:Distance(target) < rTS:GetTrueAutoAttackRange(myHero, target) + 50 then
                Input.Cast(Enums.SpellSlots.W)
            end
        end
    end
end

function Kassadin:JungleClear()
    if myHero.Mana == 4 then return end
    if IsSpellReady("E") and Menu.Get("jg.e") then
        local JGE = ObjManager.GetNearby("neutral", "minions")
        for iJGE, objJGE in ipairs(JGE) do
            if rTS:IsValidTarget(objJGE, 700) and objJGE.MaxHealth > 3 then
                Input.Cast(Enums.SpellSlots.E, objJGE.ServerPos)
            end
        end
    end
    if IsSpellReady("Q") and Menu.Get("jg.q") then
        local JGW = ObjManager.GetNearby("neutral", "minions")
        for iJGW, objJGW in ipairs(JGW) do
            if rTS:IsValidTarget(objJGW, 650) and objJGW.MaxHealth > 3 then
                Input.Cast(Enums.SpellSlots.Q, objJGW)
            end
        end
    end
end

function Kassadin:OnProcessSpell(unit, spell)
    if Menu.Get("auto.q") and IsSpellReady("Q") then
        if unit.IsEnemy then
            local enemyName = string.lower(unit.CharName)
            if interruptableSpells[enemyName] then
                for i = 1, #interruptableSpells[enemyName] do
                    local spellCheck = interruptableSpells[enemyName][i]
                    if string.lower(spell.Name) == spellCheck.spellname then
                        if myHero:Distance(unit) < 650 and rTS:IsValidTarget(unit) then
                            Input.Cast(Enums.SpellSlots.Q, unit)
                        end
                    end
                end
            end
        end
    end
end

function Kassadin:get_stacks()
    local stacks = 0
    if myHero:GetBuff('RiftWalk') then
        stacks = myHero:GetBuffCount('RiftWalk')
    end
    return stacks
end

function Kassadin:qDmg(target)
    local qDamage = (35 + (30 * myHero:GetSpell(Enums.SpellSlots.Q).Level) + (myHero.TotalAP * 0.7))
    return DamageLib.CalculateMagicalDamage(myHero, target, qDamage)
end

function Kassadin:wDmg(target)
    local wDamage = (25 + (25 * myHero:GetSpell(Enums.SpellSlots.W).Level) + (myHero.TotalAP * 0.8))
    return DamageLib.CalculateMagicalDamage(myHero, target, wDamage)
end

function Kassadin:eDmg(target)
    local eDamage = (55 + (25 * myHero:GetSpell(Enums.SpellSlots.E).Level) + (myHero.TotalAP * 0.85))
    return DamageLib.CalculateMagicalDamage(myHero, target, eDamage)
end

function Kassadin:rDmg(target)
    local rDamage = (60 + (20 * myHero:GetSpell(Enums.SpellSlots.R).Level) + (myHero.TotalAP * 0.4)) + (myHero.MaxMana * .02) 
    local stack_damage = 30 + (10 * myHero:GetSpell(Enums.SpellSlots.R).Level) + (myHero.TotalAP * .1) + (myHero.MaxMana * .01)
    local bonus_damage = stack_damage * self:get_stacks() 
    local total = rDamage + bonus_damage
    return DamageLib.CalculateMagicalDamage(myHero, target, total)
end

function Kassadin:CalculateElectrocuteDamage(target)
    local bonusAD, bonusAP = Player.BonusAD, Player.BonusAP
    local rawDamage = (8.824 * myHero.Level + 21.176) + (bonusAD * 0.4) + (bonusAP * 0.25)

    if bonusAP > bonusAD then
        return DamageLib.CalculateMagicalDamage(myHero, target, rawDamage)
    end
    return DamageLib.CalculatePhysicalDamage(myHero, target, rawDamage)
end

function Kassadin:OnDrawDamage(target, dmgList)
    if Menu.Get("draws.d.dmg") and target.IsOnScreen then        
        local dmg = DamageLib.GetAutoAttackDamage(Player, target, true) -- Already Adds Passive Damage
        if IsSpellReady("Q") then dmg = dmg + self:qDmg(target) end
        if IsSpellReady("W") then dmg = dmg + self:wDmg(target) end
        if IsSpellReady("E") then dmg = dmg + self:eDmg(target) end
        if IsSpellReady("R") then dmg = dmg + self:rDmg(target) end        
        if ignite and IsSpellReady(ignite) then dmg = dmg + (50 + (20 * myHero.Level)) end
        if myHero:GetBuff("ASSETS/Perks/Styles/Domination/Electrocute/Electrocute.lua") then
            dmg = dmg + self:CalculateElectrocuteDamage(target)
        end
        table.insert(dmgList, {Damage=dmg, Color=Menu.Get("draws.d.color")})
    end
end

function Kassadin:CastE(pred, rate)
    rate = rate or "instant"
    if pred.rates[rate] then
        Input.Cast(Enums.SpellSlots.E, pred.castPosition)
        pred:draw()
        return true
    end
end

function Kassadin:CastR(target)
    if IsSpellReady("R") and rTS:IsValidTarget(target) then
        local pred = _G.DreamPred.GetPrediction(target, self.r, myHero.Position)
        if pred and pred.castPosition and myHero:Distance(pred.castPosition) <= self.r.range then
            Input.Cast(Enums.SpellSlots.R, pred.castPosition)
        end
    end
end

function Kassadin:CastGPR(target)
    if IsSpellReady("R") then
        if myHero:Distance(target) < 1100 and myHero:Distance(target) > 500 then
            Input.Cast(Enums.SpellSlots.R, target.Position)
        end
    end
end

function Kassadin:CastQ(target)
    if IsSpellReady("Q") then
        if myHero:Distance(target) < 650 then
            Input.Cast(Enums.SpellSlots.Q, target)
        end
    end
end

function Kassadin:CastEKS(target)
    if IsSpellReady("E") then
        local pred = _G.DreamPred.GetPrediction(target, self.e, myHero.Position)
        if pred and pred.castPosition and myHero:Distance(pred.castPosition) <= self.e.range then
            Input.Cast(Enums.SpellSlots.E, pred.castPosition)
        end
    end
end

local ITEM_SLOTS =
{
    Enums.SpellSlots.Item1,
    Enums.SpellSlots.Item2,
    Enums.SpellSlots.Item3,
    Enums.SpellSlots.Item4,
    Enums.SpellSlots.Item5,
    Enums.SpellSlots.Item6,
    Enums.SpellSlots.Trinket,
}

function Kassadin:GetItem(name)
    for i, slot in ipairs(ITEM_SLOTS) do
        if myHero:GetSpellState(slot) == 0 then
            if myHero:GetSpell(slot).Name == name then
                return slot
            end
        end
    end
end

function Kassadin:CastEver(pred)
    local ef = self:GetItem("6656Cast")
    if ef and pred.rates["slow"] then
        Input.Cast(ef, pred.castPosition)
        return true
    end
end

function Kassadin:Run()
    if IsSpellReady("R") then
        Input.Cast(Enums.SpellSlots.R, Renderer.GetMousePos())
    end
end

function Kassadin:KillSteal()
    local enemy = self:GetTargetNormal(1150)
    if enemy and rTS:IsValidTarget(enemy) then
        local hp = enemy.Health
        local d = myHero:Distance(enemy)
        local q = IsSpellReady("Q")
        local w = IsSpellReady("W")
        local e = IsSpellReady("E")
        local r = IsSpellReady("R")
        local qd = self:qDmg(enemy)
        local wd = self:wDmg(enemy)
        local ed = self:eDmg(enemy)
        local rd = self:rDmg(enemy)
        if q and hp < qd and d < (650) then
            self:CastQ(enemy)
        elseif e and hp < ed and d < (650) then 
            self:CastEKS(enemy)
        elseif r and hp < rd and Menu.Get("auto.urks") and d < (550) then
            self:CastR(enemy)
        elseif r and w and hp < rd + wd and Menu.Get("auto.urks") and d < (550) then
            self:CastR(enemy)
        elseif q and r and hp < qd and d < (1150) and d > (650) then
            self:CastGPR(enemy)
            self:CastQ(enemy)
        elseif q and r and e and hp < qd + ed and d < (1150) and d > (650) then
            self:CastGPR(enemy)
            self:CastQ(enemy)
            self:CastEKS(enemy)
        elseif q and e and hp < qd + ed and d < (650) then
            self:CastQ(enemy)
            self:CastEKS(enemy)
        elseif q and e and r and hp < qd + ed + rd and Menu.Get("auto.urks") and d < (550) then
            self:CastR(enemy)
            self:CastQ(enemy)
            self:CastEKS(enemy)
        elseif q and e and r and w and hp < qd + ed + rd + wd and Menu.Get("auto.urks") and d < (550) then 
            self:CastR(enemy)
            self:CastQ(enemy)
            self:CastEKS(enemy)
        end
    end
end


function Kassadin:OnTick()
    local orbMode = _G.Libs.Orbwalker.GetMode()
    local ComboMode = orbMode == "Combo"
    local HarassMode = orbMode == "Harass"
    local JungleMode = orbMode == "Waveclear"

    if IsSpellReady("E") then
        if (Menu.Get("combo.e") and ComboMode) or (Menu.Get("harass.e") and HarassMode) then
            local target, pred = self.TS:GetTarget(self.e, myHero)
            if pred and self:CastE(pred, "instant") then
                return
            end
        end
    end

    if IsSpellReady("Q") then
        local target = self:GetTargetNormal(650)
        if (Menu.Get("combo.q") and ComboMode) or (Menu.Get("harass.q") and HarassMode) then
            if target and Input.Cast(Enums.SpellSlots.Q, target) then
                return
            end
        end
    end

    if IsSpellReady("R") and ComboMode then
        local target = self:GetTargetNormal(500)
        if Menu.Get("combo.rs.ur") and (myHero.Health / myHero.MaxHealth) * 100 >= Menu.Get("combo.rs.hpr") and self:get_stacks() < Menu.Get("combo.rs.stacks") then
            if CountEnemiesInRange(myHero, 800) <= Menu.Get("combo.rs.rx") then
                if Menu.Get("combo.rs.rmode") == 2 then
                    if self:rDmg(target) + self:qDmg(target) + self:eDmg(target) > target.Health then
                        self:CastR(target)
                    end
                else
                    self:CastR(target)
                end
            end
        end
    end

    if orbMode == "Flee" then self:Run() end
    if Menu.Get("auto.uks") then self:KillSteal() end
    if JungleMode then self:JungleClear() end
    if ComboMode then
        local target, pred = self.TS:GetTarget(self.efline2, myHero)
        if pred and self:CastEver(pred) then
            return
        end
    end
end

---@return AIBaseClient
function Kassadin:GetTargetNormal(dist, all)
    local res = self.TS:update(function(unit) return rTS:IsValidTarget(unit, dist) end)
    return (all and res) or (res and res[1])
end

function Kassadin:OnUnkillableMinion(minion)
    if Orbwalker.IsIgnoringMinion(minion) then        
        return
    end

    local dist = myHero:Distance(minion)
    if IsSpellReady("Q") and dist <= 650 then
        local time = 0.25 + dist/1400
        local dmg = DamageLib.GetSpellDamage(myHero, minion, Enums.SpellSlots.Q)
        local health = HealthPred.GetHealthPrediction(minion, time)
        if dmg > health and Input.Cast(Enums.SpellSlots.Q, minion) then
            Orbwalker.IgnoreMinion(minion)
            return
        end
    end
end

Kassadin:__init()
