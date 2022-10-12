local DreamTSLib = _G.DreamTS or require("DreamTS")

---@type SDK_SDK
local SDK = DreamTSLib.TargetSelectorSdk.SDK

---@type SDK_AIHeroClient
local myHero = SDK.Player

if myHero:GetCharacterName() ~= "Kayn" then return end

local Kayn = {}

local update_data = {
    Robur = {
        ScriptName = "CXKayn",
        ScriptVersion = "1.4",
        Repo = "https://raw.githubusercontent.com/hagbardlol/Public/main/"
    }
}

SDK.Common.AutoUpdate(update_data)

local DreamTS = DreamTSLib.TargetSelectorSdk
local Vector = SDK.Libs.Vector
local HealthPred = Libs.HealthPred
local DamageLib = Libs.DamageLib

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

function Kayn:__init()
    self.q = {
        type = "linear",
        speed = math.huge,
        range = 450,
        delay = 0.15,
        width = 100,
    }
    self.w = {
        type = "linear",
        speed = math.huge,
        range = 700,
        delay = 0.55,
        width = 170,
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
end

function Kayn:Menu()
    self.menu = SDK.Libs.Menu("cxKayn", "Cyrex Kayn")

    self.menu
    :AddLabel("Cyrex Kayn Settings", true)
    :AddSubMenu("dreamTs", "Target Selector")

    self.menu
    :AddSubMenu("combo", "Combo Settings")
        :AddLabel("Q Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W", true)
        :AddSlider("wx", "^ W If Enemies >=", {min = 1, max = 5, default = 3, step = 1})
        :AddCheckbox("r", "Use R", true)
        :AddSlider("hp", "Min HP% for R", {min = 0, max = 100, default = 30, step = 5})
        :GetParent()
    :AddSubMenu("harass", "Harass Settings")
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W", true)
        :GetParent()
    :AddSubMenu("jg", "Jungle Clear Settings")
        :AddLabel("xd", "Jungle Settings")
        :AddCheckbox("q", "Use Q", true)
        :AddCheckbox("w", "Use W", true)
        :GetParent()
    :AddSubMenu("auto", "Automatic Settings")
        :AddLabel("Killsteal Settings", true)
        :AddCheckbox("uks", "Use Killsteal", true)
        :AddCheckbox("uwks", "Use W in Killsteal", true)
        :AddCheckbox("urks", "Use R in Killsteal", true)
        :GetParent()
    :AddSubMenu("draws", "Draw")
        :AddCheckbox("q", "Q", true)
        :AddCheckbox("w", "W", true)
        :AddCheckbox("r", "R", true)
        :GetParent()
    :AddLabel("Version: " .. update_data.Robur.ScriptVersion .. "", true)
    :AddLabel("Author: Coozbie", true)

    self.menu:Render()
end

local color_white = SDK.Libs.Color.GetD3DColor(255,7,141,237)
local color_red   = SDK.Libs.Color.GetD3DColor(255,255,0,0)
local color_w     = SDK.Libs.Color.GetD3DColor(255,255,255,255)
local color_g     = SDK.Libs.Color.GetD3DColor(255,0,255,0)

function Kayn:OnDraw()
    if not myHero:IsOnScreen() then
        return
    end
    if self.menu:GetLocal("draws.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), 325, color_white)
    end
    if self.menu:GetLocal("draws.w") and myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then
        if myHero:GetSpell(SDK.Enums.SpellSlot.W):GetName() == "KaynAssW" then
            SDK.Renderer:DrawCircle3D(myHero:GetPosition(), 900, color_white)
        else
            SDK.Renderer:DrawCircle3D(myHero:GetPosition(), 700, color_white)
        end
    end
    if self.menu:GetLocal("draws.r") and myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        if myHero:GetSpell(SDK.Enums.SpellSlot.W):GetName() == "KaynAssW" then
            SDK.Renderer:DrawCircle3D(myHero:GetPosition(), 750, color_white)
        else
            SDK.Renderer:DrawCircle3D(myHero:GetPosition(), 550, color_white)
        end
    end
end

function Kayn:GetPercentHealth(obj)
    obj = obj or myHero
    return obj:GetHealthPercent()
end

local delayedActions, delayedActionsExecuter = {}, nil
function Kayn:DelayAction(func, delay, args) --delay in seconds
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

function Kayn:GetAARange(target)
    return myHero:GetAttackRange() + myHero:GetBoundingRadius() + (target and target:GetBoundingRadius() or 0)
end

function Kayn:MoveToMouse()
    SDK.Input:MoveTo(SDK.Renderer:GetMousePos3D())
end

function Kayn:ValidTarget(object, distance) 
    return object and object:IsValid() and object:IsEnemy() and object:IsVisible() and not object:GetBuff('SionPassiveZombie') and not object:GetBuff('FioraW') and object:IsAlive() and not object:IsInvulnerable() and (not distance or  object:GetPosition():DistanceSqr(myHero:GetPosition()) <= distance * distance)
end

function Kayn:TotalAD(obj)
    obj = obj or myHero
    return obj:GetTotalAD()
end

function Kayn:GetBonusAD(obj)
    obj = obj or myHero
    return obj:GetFlatPhysicalDamageMod()
end

function Kayn:GetDistanceSqr(p1, p2)
    p2 = p2 or myHero:GetPosition()
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return dx*dx + dz*dz
end

function Kayn:wDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then
        local wDamage = (45 + (45 * myHero:GetSpell(SDK.Enums.SpellSlot.W):GetLevel()) + (self:GetBonusAD() * 1.3))
        return self.TS.CalcDmg(myHero, target:AsAI(), wDamage, 0, 0)
    end
end

function Kayn:rDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        if myHero:GetSpell(SDK.Enums.SpellSlot.W):GetName() == "KaynAssW" then
            local rDamage = (50 + (100 * myHero:GetSpell(SDK.Enums.SpellSlot.R):GetLevel()) + (self:GetBonusAD() * 1.75))
            return self.TS.CalcDmg(myHero, target:AsAI(), rDamage, 0, 0)
        end
        if myHero:GetSpell(SDK.Enums.SpellSlot.W):GetName() == "KaynW" then
            local rDamage = (0.15 + (0.13 * (self:GetBonusAD() / 100))) * target:GetMaxHealth()
            return self.TS.CalcDmg(myHero, target:AsAI(), rDamage, 0, 0)
        end
    end
end

function Kayn:CastQ(pred)
    if pred.rates["instant"] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.Q, pred.castPosition)
        pred:Draw()
        return true
    end
end

function Kayn:CastW(pred)
    if pred.rates["slow"] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.W, pred.castPosition)
        pred:Draw()
        return true
    end
end

function Kayn:CastR(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        if myHero:GetSpell(SDK.Enums.SpellSlot.W):GetName() == "KaynAssW" and self:GetDistanceSqr(target:GetPosition()) < (750 * 750) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.R, target)
        end
        if myHero:GetSpell(SDK.Enums.SpellSlot.W):GetName() == "KaynW" and self:GetDistanceSqr(target:GetPosition()) < (550 * 550) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.R, target)
        end
    end
end

function Kayn:UpdateSpellDelays()
    if myHero:GetSpell(SDK.Enums.SpellSlot.W):GetName() == "KaynAssW" then
        self.w.range = 900
    else
        self.w.range = 700
    end
end

function Kayn:MultiR(minCount)
    local rTargets, rPreds =
        self.TS:GetTargets(
        self.w,
        myHero:GetPosition(),
        function(unit)
            return self:GetDistanceSqr(unit:GetPosition()) <= (self.w.range + unit:GetBoundingRadius()) ^ 2
        end
    )
    local bestCount, bestObj, bestPred = minCount - 1, nil, nil
    for _, enemy in pairs(rTargets) do
        count = 0
        local pred = rPreds[enemy:GetNetworkId()]
        if pred then
            for _, enemy2 in pairs(rTargets) do
                local col = _G.Prediction.IsCollision(self.w, myHero:GetPosition(), pred.castPosition, enemy2.data)
                if col then
                    count = count + 1
                end
            end
            if count > bestCount then
                bestCount = count
                bestObj = enemy:AsAI()
                bestPred = pred
            end
        end
    end
    if bestObj then
        SDK.Input:Cast(SDK.Enums.SpellSlot.W, bestPred.castPosition)
        --bestPred:Draw()
    end
end

function Kayn:KillSteal()
    for i, enemy in ipairs(enemies) do
        if enemy and self:ValidTarget(enemy) then
            local hp = enemy:GetHealth()
            local d = self:GetDistanceSqr(enemy:GetPosition())
            local r = myHero:CanUseSpell(SDK.Enums.SpellSlot.R)
            local rd = self:rDmg(enemy)
            if self.menu:GetLocal("auto.urks") and r and rd > hp and d < (750 * 750) and enemy:GetBuff('kaynrenemymark') then
                self:CastR(enemy)
            end
        end
    end
end

function Kayn:JungleClear()
    local Jungle = _G.CoreEx.ObjectManager.GetNearby("neutral", "minions")
    for iJGLQ, objJGLQ in ipairs (Jungle) do
        local minion = objJGLQ.AsMinion
        if minion and minion.MaxHealth > 6 and minion.Position:DistanceSqr(myHero:GetPosition()) < (600 * 600) and _G.Libs.TargetSelector():IsValidTarget(minion) then
            if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and self.menu:GetLocal("jg.q") and minion.Position:DistanceSqr(myHero:GetPosition()) < (350 * 350) then
                SDK.Input:Cast(SDK.Enums.SpellSlot.Q, minion.Position)
            end
            if myHero:CanUseSpell(SDK.Enums.SpellSlot.W) and self.menu:GetLocal("jg.w") then
                SDK.Input:Cast(SDK.Enums.SpellSlot.W, minion.Position)
            end
        end
    end
end

function Kayn:OnTick()
    self:UpdateSpellDelays()
    local ComboMode = _G.Libs.Orbwalker.GetMode() == "Combo"
    local HarassMode = _G.Libs.Orbwalker.GetMode() == "Harass"
    local WaveclearMode = _G.Libs.Orbwalker.GetMode() == "Waveclear"

    if (myHero:CanUseSpell(SDK.Enums.SpellSlot.W) and self.menu:GetLocal("combo.wx") > 0 and self:MultiR(self.menu:GetLocal("combo.wx"))) then
        return
    end

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then
        local w_targets, w_preds = self.TS:GetTargets(self.w, myHero:GetPosition())
        local w_ks, w_ks_pred = self.TS:GetTargets(self.w, myHero:GetPosition(), function(enemy) return self:wDmg(enemy) >= enemy:GetHealth() end)
        if (ComboMode and self.menu:GetLocal("combo.w")) or (HarassMode and self.menu:GetLocal("harass.w")) then
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

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        local q_targets, q_preds = self.TS:GetTargets(self.q, myHero:GetPosition())

        if (ComboMode and self.menu:GetLocal("combo.q")) then
            local target = q_targets[1]
            if target then
                local pred = q_preds[target:GetNetworkId()]
                if pred and self:CastQ(pred) then
                    return
                end
            end
        end
    end

    local target = self:GetTarget(750)
    if ComboMode then
        if target and self:ValidTarget(target) then
            local r = myHero:CanUseSpell(SDK.Enums.SpellSlot.R)
            if r and myHero:GetSpell(SDK.Enums.SpellSlot.R):GetName() == "KaynR" and self:GetPercentHealth() < self.menu:GetLocal("combo.hp") then
                for i, enemy in ipairs(enemies) do
                    if enemy and self:ValidTarget(enemy) and enemy:GetBuff('kaynrenemymark') then
                        self:CastR(enemy)
                    end
                end
            end

        end
    end
    if self.menu:GetLocal("auto.uks") then self:KillSteal() end
    if WaveclearMode then self:JungleClear() end
    if myHero:GetSpell(SDK.Enums.SpellSlot.R):GetName() == "KaynRJumpOut" then
        self:DelayAction(function() SDK.Input:Cast(SDK.Enums.SpellSlot.R, SDK.Renderer:GetMousePos3D()) end, 2.5)
    end
end

local get_d3d_color = SDK.Libs.Color.GetD3DColor
function Kayn:Hex(a, r, g, b)
    return get_d3d_color(a, r, g, b)
end

function Kayn:GetTarget(dist, all)
    local res = self.TS:update(function(unit) return _G.Prediction.SDK.IsValidTarget(unit, dist) end)
    if all then
        return res
    else
        if res and res[1] then
            return res[1]
        end
    end
end

if myHero:GetCharacterName() == "Kayn" then
    Kayn:__init()
end
