local DreamTSLib = _G.DreamTS or require("DreamTS")

---@type SDK_SDK
local SDK = DreamTSLib.TargetSelectorSdk.SDK

---@type SDK_AIHeroClient
local myHero = SDK.Player

if myHero:GetCharacterName() ~= "Ashe" then return end

local Ashe = {}

local update_data = {
    Robur = {
        ScriptName = "CXAshe",
        ScriptVersion = "1.6",
        Repo = "https://raw.githubusercontent.com/hagbardlol/Public/main/"
    }
}

SDK.Common.AutoUpdate(update_data)

local DreamTS = DreamTSLib.TargetSelectorSdk
local Vector = SDK.Libs.Vector
local roburTS = _G.Libs.TargetSelector()
local HealthPred = Libs.HealthPred

---@param objects SDK_GameObject[]
---@return SDK_AIHeroClient[]
local function GetHerosFromObjects(objects)
    local res = {}
    for i, obj in ipairs(objects) do
        res[i] = obj:AsHero()
    end
    return res
end

local enemies = GetHerosFromObjects(SDK.ObjectManager:GetEnemyHeroes())

function Ashe:__init()
    self.w = {
        type = "linear",
        speed = 1500,
        range = 1200,
        delay = 0.25,
        width = 120,
        collision = {
            ["Wall"] = true,
            ["Hero"] = true,
            ["Minion"] = true
        }
    }
    self.r = {
        type = "linear",
        speed = 1600,
        range = 2000,
        delay = 0.25,
        width = 240,
        collision = {
            ["Wall"] = true,
            ["Hero"] = true,
            ["Minion"] = false
        }
    }
    self:Menu()
    self.TS =
        DreamTS(
        self.menu:GetLocalChild("dreamTs"),
        {
            Damage = DreamTS.Damages.AD
        }
    )
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnTick, function() self:OnTick() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnDraw, function() self:OnDraw() end)
    _G.CoreEx.EventManager.RegisterCallback(_G.CoreEx.Enums.Events.OnPostAttack, function(target) self:OnExecuteCastFrame(SDK.Types.AIBaseClient(target)) end)
end

function Ashe:Menu()
    self.menu = SDK.Libs.Menu("cxashe", "Cyrex Ashe")

    self.menu
    :AddLabel("Cyrex Ashe Settings", true)
    :AddSubMenu("dreamTs", "Target Selector")

    self.menu
    :AddSubMenu("combo", "Combo Settings")
        :AddLabel("Q Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W")
        :GetParent()

    :AddSubMenu("r", "Ultimate Settings")
        :AddLabel("R Combo Settings", true)
        :AddCheckbox("rm", "R if Enemy in Melee", true)
        :AddLabel("Semi-Manual R Settings", true)
        :AddCheckbox("r", "Use R", true)
        :AddKeybind("rt", "Use Semi Manual R", string.byte("T"))
        :AddSubMenu("bl", "Black List")

    local r_menu = self.menu:GetLocalChild("r.bl"):AsMenu()

    for _, enemy in ipairs(enemies) do
        r_menu:AddCheckbox(enemy:GetCharacterName(), "Do Not Hit: " .. enemy:GetCharacterName(), false)
    end

    local rm = self.menu:GetLocalChild("r"):AsMenu()
    rm:AddLabel("Anti-Gap Settings", true)
    rm:AddSubMenu("ag", "Anti Gapclose")

    local anti_gap_menu = self.menu:GetLocalChild("r.ag"):AsMenu()
    self.antiGapHeros = {}
    for _, hero in ipairs(enemies) do
        local char_name = hero:GetCharacterName()
        anti_gap_menu:AddCheckbox(char_name, "AntiGap:" .. char_name, true)
        self.antiGapHeros[hero:GetNetworkId()] = true
    end

    self.menu
    :AddSubMenu("harass", "Harass Settings")
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W", true)
        :GetParent()
    :AddSubMenu("auto", "Automatic Settings")
        :AddLabel("Killsteal Settings", true)
        :AddCheckbox("uwks", "Use W in Killsteal", true)
        :AddCheckbox("urks", "Use R in Killsteal", true)
        :GetParent()
    :AddSubMenu("draws", "Draw")
        :AddCheckbox("w", "W", true)
        :GetParent()
        :AddLabel("Version: " .. update_data.Robur.ScriptVersion .. "", true)
        :AddLabel("Author: Coozbie", true)

    self.menu:Render()
end


local color_white = SDK.Libs.Color.GetD3DColor(255,7,141,237)

function Ashe:OnDraw()
    if not myHero:IsOnScreen() then
        return
    end

    if self.menu:GetLocal("draws.w") and myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), self.w.range, color_white)
    end    
end

local delayedActions, delayedActionsExecuter = {}, nil
function Ashe:DelayAction(func, delay, args) --delay in seconds
    if not delayedActionsExecuter then
        function delayedActionsExecuter()
            for t, funcs in pairs(delayedActions) do
                if t <= os.clock() then
                    for i = 1, #funcs do
                        local f = funcs[i]
                        if f and f.func then
                            f.func(unpack(f.args or {}))
                        end
                    end
                    delayedActions[t] = nil
                end
            end
        end
        SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnTick, delayedActionsExecuter)
    end
    local t = os.clock() + (delay or 0)
    if delayedActions[t] then
        delayedActions[t][#delayedActions[t] + 1] = {func = func, args = args}
    else
        delayedActions[t] = {{func = func, args = args}}
    end
end

function Ashe:GetPercentHealth(obj)
    obj = obj or myHero
    return obj:GetHealthPercent()
end

function Ashe:GetTotalAP(obj)
  local obj = obj or myHero
  return obj:GetTotalAP()
end

function Ashe:MoveToMouse()
    SDK.Input:MoveTo(SDK.Renderer:GetMousePos3D())
end

function Ashe:TotalAD(obj)
    obj = obj or myHero
    return obj:GetTotalAD()
end

---@param obj SDK_AIBaseClient | nil
function Ashe:GetBonusAD(obj)
  obj = obj or myHero
  return obj:GetFlatPhysicalDamageMod()
end

function Ashe:GetDistanceSqr(p1, p2)
    p2 = p2 or myHero:GetPosition()
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return dx*dx + dz*dz
end

function Ashe:ValidTarget(object, distance) 
    return object and object:IsValid() and object:IsEnemy() and object:IsVisible() and not object:GetBuff('SionPassiveZombie') and not object:GetBuff('FioraW') and object:IsAlive() and not object:IsInvulnerable() and (not distance or  object:GetPosition():DistanceSqr(myHero:GetPosition()) <= distance * distance)
end

function Ashe:GetAARange(target)
    return myHero:GetAttackRange() + myHero:GetBoundingRadius() + (target and target:GetBoundingRadius() or 0)
end

function Ashe:wDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then
        local wDamage = (5 + (15 * myHero:GetSpell(SDK.Enums.SpellSlot.W):GetLevel()) + (self:TotalAD() * 1))
        return self.TS.CalcDmg(myHero, target:AsAI(), wDamage, 0, 0)
    end
end

function Ashe:rDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        local rDamage = ((200 * myHero:GetSpell(SDK.Enums.SpellSlot.R):GetLevel())) + (self:GetTotalAP() * 1)
        return self.TS.CalcDmg(myHero, target:AsAI(), rDamage, 0, 0)
    end
end

function Ashe:GetEnemyHeroesInRange(range, pos)
    local pos = pos or myHero:GetPosition()
    local h = {}
    local enemies = SDK.ObjectManager:GetEnemyHeroes()
    for i = 1, #enemies do
        local hero = enemies[i]:AsAI()
        if hero and hero:IsEnemy() and not hero:IsInvulnerable() and hero:IsAlive() and hero:IsVisible() and hero:IsTargetable() and hero:GetPosition():DistanceSqr(pos) < range * range then
            h[#h + 1] = hero
        end
    end
    return h
end

function Ashe:CastW(pred)
    if pred.rates["slow"] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.W, pred.castPosition)
        pred:Draw()
        return true
    end
end

function Ashe:CastR(pred, rate)
    rate = rate or "slow"
    if pred.rates[rate] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.R, pred.castPosition)
        pred:Draw()
        return true
    end
end

function Ashe:OnExecuteCastFrame(target)
    if self.menu:GetLocal("combo.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and (_G.Libs.Orbwalker.GetMode() == "Combo") then
        if target and roburTS:IsValidTarget(target.data) and target:GetPosition():Distance(myHero:GetPosition()) < self:GetAARange(target) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.Q, myHero)
        end
    end
end

function Ashe:OnTick()
    local ComboMode = _G.Libs.Orbwalker.GetMode() == "Combo"
    local HarassMode = _G.Libs.Orbwalker.GetMode() == "Harass"
    local WaveclearMode = _G.Libs.Orbwalker.GetMode() == "Waveclear"

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then
        local w_targets, w_preds = self.TS:GetTargets(self.w, myHero:GetPosition())
        local w_ks, w_ks_pred = self.TS:GetTargets(self.w, myHero:GetPosition(), function(enemy) return self:wDmg(enemy) >= enemy:GetHealth() end)

        if (ComboMode and self.menu:GetLocal("combo.w") and not myHero:GetBuff("AsheQAttack")) or (HarassMode and self.menu:GetLocal("harass.w") and not myHero:GetBuff("AsheQAttack")) then
            local target = w_targets[1]
            if target then
                local pred = w_preds[target:GetNetworkId()]
                if pred and self:CastW(pred) then
                    return
                end
            end
        end
        if self.menu:GetLocal("auto.uwks") then
            local target = w_ks[1]
            if target then
                local pred = w_ks_pred[target:GetNetworkId()]
                if pred and self:CastW(pred) then
                    return
                end
            end
        end
    end
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        local r_targets, r_preds = self.TS:GetTargets(self.r, myHero:GetPosition(), nil, nil, self.TS.Modes["Closest To Mouse"])
        local r_ks, r_ks_pred = self.TS:GetTargets(self.r, myHero:GetPosition(), function(enemy) return self:rDmg(enemy) >= enemy:GetHealth() end)

        if (ComboMode and self.menu:GetLocal("r.rm")) then
            local target = r_targets[1]
            if target then
                local pred = r_preds[target:GetNetworkId()]
                if pred and self:GetDistanceSqr(target:GetPosition()) < 300^2 and self:CastR(pred, "instant") then
                    return
                end
            end
        end
        if (self.menu:GetLocal("r.rt") and self.menu:GetLocal("r.r")) then
            local target = r_targets[1]
            if target then
                local pred = r_preds[target:GetNetworkId()]
                if pred and not self.menu:GetLocal("r.bl." .. target:GetCharacterName()) and self:CastR(pred, "slow") then
                    return
                end
            end
        end
        if self.menu:GetLocal("auto.urks") then
            local target = r_ks[1]
            if target then
                local pred = r_ks_pred[target:GetNetworkId()]
                if pred and self:CastR(pred) then
                    return
                end
            end
        end
        for i = 1, #r_targets do
            local unit = r_targets[i]
            local pred = r_preds[unit:GetNetworkId()]
            if pred then
                if pred.targetDashing and self.antiGapHeros[unit:GetNetworkId()] and self.menu:GetLocal("r.ag." .. unit:GetCharacterName()) and self:CastR(pred) then
                    return
                end
                if pred.isInterrupt and self:CastR(pred) then
                    return
                end
            end
        end
    end
end

local get_d3d_color = SDK.Libs.Color.GetD3DColor
function Ashe:Hex(a, r, g, b)
    return get_d3d_color(a, r, g, b)
end

function Ashe:GetTargetNormal(dist, all)
    local res = self.TS:update(function(unit) return _G.Prediction.SDK.IsValidTarget(unit, dist) end)
    if all then
        return res
    else
        if res and res[1] then
            return res[1]
        end
    end
end

if myHero:GetCharacterName() == "Ashe" then
    Ashe:__init()
end
