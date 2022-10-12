local Player = _G.Player
if Player.CharName ~= "Rengar" then return end
local DreamTS = _G.DreamTS or require("DreamTS")

--[[These 2 lines let you call DEBUG(), INFO(), WARN() etc]]
module("CX Rengar", package.seeall, log.setup)
clean.module("CX Rengar", clean.seeall, log.setup)

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred, DamageLib = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred, _G.Libs.DamageLib
local Spell = _G.Libs.Spell

---@type AIHeroClient
local myHero = Player



local Rengar = {}
local version = 1.0

local SCRIPT_NAME, VERSION, LAST_UPDATE = "CXRengar", "1.0.2", "22/08/2022"
_G.CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/CXRengar.lua", VERSION)

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

function Rengar:__init()
    self.e = {
        type = "linear",
        speed = 1500,
        range = 935,
        delay = 0.25,
        width = 140,
        collision = {
            ["Wall"] = true,
            ["Hero"] = true,
            ["Minion"] = true
        }
    }
    self.LastCasts =
    {
        Q = nil,
        W = nil,
        E = nil
    }
    self.TS =
        DreamTS(
        "CX Rengar",
        {
            Damage = DreamTS.Damages.AD
        }
    )
    self:Menu()
    EventManager.RegisterCallback(Enums.Events.OnTick, function() self:OnTick() end)
    EventManager.RegisterCallback(Enums.Events.OnLowPriority, function() self:OnTickSlow() end)
    EventManager.RegisterCallback(Enums.Events.OnDraw, function() self:OnDraw() end)
    EventManager.RegisterCallback(Enums.Events.OnPostAttack, function(target) self:OnExecuteCastFrame(target) end)
    EventManager.RegisterCallback(Enums.Events.OnBuffGain, function(obj, buff) self:OnBuffUpdate(obj, buff) end)
    EventManager.RegisterCallback(Enums.Events.OnNewPath, function(obj, pathing) self:OnNewPath(obj, pathing) end)
end

function Rengar:Menu()
    Menu.RegisterMenu("CXRengar", "Cyrex Rengar", function()
        Menu.Separator("Cyrex Rengar Settings")
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
            Menu.Checkbox("combo.prio", "Prio W Heal over DMG", true)
            Menu.Slider("combo.whp", "What Grey HP% to W", 20, 5, 100, 5)
            Menu.Separator("E Settings")
            Menu.Checkbox("combo.e", "Use E", true)
            Menu.Separator("Max Fury Settings")
            Menu.Keybind("combo.use", "Prio Q ON/Prio E OFF",  string.byte("T"), true, true)
        end)

        Menu.NewTree("w", "Fury W Settings", function()
        Menu.Slider("w.lvl", "Min lvl usage >=", 1, 1, 25, 1)
        Menu.Slider("w.delay", "Delay: ", 0, 0, 1, 0.05)
        Menu.Slider("w.mincc", "Min CC Time to Cast: ", 0, 0, 3, 0.1)
            Menu.NewTree("w.qss", "Buff Config", function()
                Menu.Checkbox("w.qss.stun", "Use for Stun", true)
                Menu.Checkbox("w.qss.exh", "Use for Exhaust", true)
                Menu.Checkbox("w.qss.silence", "Use for Silence", true)
                Menu.Checkbox("w.qss.charm", "Use for Charm", true)
                Menu.Checkbox("w.qss.taunt", "Use for Taunt", true)
                Menu.Checkbox("w.qss.root", "Use for Root", true)
                Menu.Checkbox("w.qss.sup", "Use for Suppression", true)
                Menu.Checkbox("w.qss.blind", "Use for Blind", true)
                Menu.Checkbox("w.qss.fear", "Use for Fear", true)
                Menu.Checkbox("w.qss.knock", "Use for KnockUp", true)
                Menu.Checkbox("w.qss.sleep", "Use for Sleep", true)
                Menu.Checkbox("w.qss.poly", "Use for Polymorph", true)
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
            Menu.Checkbox("draws.e", "Draw E Range", true)
            Menu.Checkbox("draws.r", "Draw Fury Status", true)
        end)

        Menu.Separator("Author: Coozbie " .. version)
    end)
end

local color_white = 0xFFFFFFFF
local color_red = 0xFF0000FF

function Rengar:OnDraw()
    local hero_pos = myHero.Position

    if myHero.IsOnScreen then
        if Menu.Get("draws.e") and IsSpellReady("E") then
            Renderer.DrawCircle3D(hero_pos, self.e.range, nil, 2, 0x078DEDFF)
        end
    end
    if Menu.Get("draws.r") then
        if Menu.Get("combo.use") then
            Renderer.DrawTextOnPlayer("FURY STATUS: Q", color_white)
        else
            Renderer.DrawTextOnPlayer("FURY STATUS: E", color_white)
        end
    end
end

function Rengar:ShouldCast()
    local curTime, latency = Game.GetTime(), Game.GetLatency()/1000
    for spell, time in pairs(self.LastCasts) do
        if curTime < (time + latency) then
            return false
        end
    end
    return true
end

function Rengar:GetEnemyAndJungleMinions(radius, fromPos)
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

function Rengar:GetBestEscape()
    if not myHero:GetBuff("rengarpassivebuff") then return end
    local mousePos = Renderer.GetMousePos()
    local origDist = myHero:Distance(mousePos)
    local minDistance = myHero:Distance(mousePos)
    local minDistObj = nil
    local minionsInRange = self:GetEnemyAndJungleMinions(rTS:GetTrueAutoAttackRange(myHero))
    for _, minion in ipairs(minionsInRange) do
        local minionDist = minion:Distance(mousePos)
        if minion and minion.Health > 2 and myHero:Distance(minion) <= (750) then
            if minionDist < minDistance then
                minDistance = minionDist
                minDistObj = minion
            end
        end
    end
    local enemiesInRange = self:GetTargetNormal(750, true)
    for _, enemy in ipairs(enemiesInRange) do
        local enemyDist = enemy:Distance(mousePos)
        if enemyDist < minDistance then
            minDistance = enemyDist
            minDistObj = enemy
        end
    end
    return minDistObj or nil
end

function Rengar:OnBuffUpdate(obj, buff)
    if obj.IsMe and buff.DurationLeft >= Menu.Get("w.mincc") then
        if buff.BuffType == Enums.BuffTypes.Stun and Menu.Get("w.qss.stun") then
            self:AntiCC("Stun")
        end
        if buff.BuffType == Enums.BuffTypes.Suppression and Menu.Get("w.qss.sup") then
            self:AntiCC("Suppression")
        end
        if buff.name == "SummonerExhaust" and Menu.Get("w.qss.exh") then
            self:AntiCC("Exhaust")
        end
        if buff.BuffType == Enums.BuffTypes.Silence and Menu.Get("w.qss.silence") then
            self:AntiCC("Silence")
        end
        if buff.BuffType == Enums.BuffTypes.Taunt and Menu.Get("w.qss.taunt") then
            self:AntiCC("Taunt")
        end
        if buff.BuffType == Enums.BuffTypes.Snare and Menu.Get("w.qss.root") then
            self:AntiCC("Snare")
        end
        if buff.BuffType == Enums.BuffTypes.Charm and Menu.Get("w.qss.charm") then
            self:AntiCC("Charm")
        end
        if buff.BuffType == Enums.BuffTypes.Blind and Menu.Get("w.qss.blind") then
            self:AntiCC("Blind")
        end
        if buff.BuffType == Enums.BuffTypes.Fear and Menu.Get("w.qss.fear") then
            self:AntiCC("Fear")
        end
        if buff.BuffType == Enums.BuffTypes.Polymorph and Menu.Get("w.qss.poly") then
            self:AntiCC("Polymorph")
        end
        if buff.BuffType == Enums.BuffTypes.Knockup and Menu.Get("w.qss.knock") then
            self:AntiCC("KnockUp")
        end
        if buff.BuffType == Enums.BuffTypes.Asleep and Menu.Get("w.qss.sleep") then
            self:AntiCC("Asleep")
        end
    end
end

function Rengar:AntiCC(typeName)
    if myHero.Level >= Menu.Get("w.lvl") then
        if IsSpellReady("W") and myHero.Mana == 4 then
            local WDelay = Menu.Get("w.delay") * 1000
            delay(WDelay, function() Input.Cast(Enums.SpellSlots.W) end)
        end
    end
end

function Rengar:OnExecuteCastFrame(target)
    if _G.Libs.Orbwalker.GetMode() == "Combo" or _G.Libs.Orbwalker.GetMode() == "Waveclear" then
        if Menu.Get("combo.q") and IsSpellReady("Q") and not myHero:GetBuff("rengarpassivebuff") then
            if target and rTS:IsValidTarget(target) and myHero:Distance(target) < rTS:GetTrueAutoAttackRange(myHero, target) + 25 then
                Input.Cast(Enums.SpellSlots.Q)
            end
        end
    end
end

function Rengar:JungleClear()
    if myHero.Mana == 4 then return end
    if IsSpellReady("E") and Menu.Get("jg.e") then
        local JGE = ObjManager.GetNearby("neutral", "minions")
        for iJGE, objJGE in ipairs(JGE) do
            if rTS:IsValidTarget(objJGE, 700) and objJGE.MaxHealth > 3 then
                Input.Cast(Enums.SpellSlots.E, objJGE.ServerPos)
            end
        end
    end
    if IsSpellReady("W") and Menu.Get("jg.w") then
        local JGW = ObjManager.GetNearby("neutral", "minions")
        for iJGW, objJGW in ipairs(JGW) do
            if rTS:IsValidTarget(objJGW, 400) and objJGW.MaxHealth > 3 then
                if ((myHero.SpecialHealth/ myHero.MaxHealth) * 100 >= 15 or myHero.Mana == 3) then
                    Input.Cast(Enums.SpellSlots.W)
                end
            end
        end
    end
end

function Rengar:OnNewPath(obj, pathing)
    if Menu.Get("combo.q") and IsSpellReady("Q") then
        if _G.Libs.Orbwalker.GetMode() == "Combo" then
            if obj.IsMe and pathing.DashSpeed > 0 then
                Input.Cast(Enums.SpellSlots.Q)
            end
        end
    end
end

function Rengar:CastE(pred, rate)
    rate = rate or "instant"
    if pred.rates[rate] then
        Input.Cast(Enums.SpellSlots.E, pred.castPosition)
        pred:draw()
        self.LastCasts.E = Game.GetTime() + 0.25
        return true
    end
end


function Rengar:Run()
    local bestPos = self:GetBestEscape()
    if bestPos and Input.Attack(bestPos) then
        return
    end
end

function Rengar:OnTickSlow()
    local orbMode = _G.Libs.Orbwalker.GetMode()
    if orbMode == "Waveclear" then self:JungleClear() end
end

function Rengar:OnTick()
    local orbMode = _G.Libs.Orbwalker.GetMode()
    local ComboMode = orbMode == "Combo"
    local HarassMode = orbMode == "Harass"

    if IsSpellReady("E") and self:ShouldCast() and Menu.Get("combo.e") and ComboMode then
        if myHero.Mana == 4 and Menu.Get("combo.use") then return end
        local target, pred = self.TS:GetTarget(self.e, myHero)
        if pred and not myHero:GetBuff("rengarpassivebuff") and self:CastE(pred, "slow") then
            return
        end
    end

    if IsSpellReady("W") then
        if myHero.Mana == 4 then return end
        local target = self:GetTargetNormal(400)
        if Menu.Get("combo.w") then
            if Menu.Get("combo.prio") then
                if (myHero.SpecialHealth/ myHero.MaxHealth) * 100 >= Menu.Get("combo.whp") then
                    Input.Cast(Enums.SpellSlots.W)
                end
            else
                if ComboMode and ((myHero.SpecialHealth/ myHero.MaxHealth) * 100 >= 15 or myHero.Mana == 3) and target and Input.Cast(Enums.SpellSlots.W) then
                    return
                end
            end
        end
    end

    if orbMode == "Flee" and not myHero:GetBuff("RengarR") then self:Run() end
end

---@return AIBaseClient
function Rengar:GetTargetNormal(dist, all)
    local res = self.TS:update(function(unit) return rTS:IsValidTarget(unit, dist) end)
    return (all and res) or (res and res[1])
end

Rengar:__init()
