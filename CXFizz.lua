local DreamTSLib = _G.DreamTS or require("DreamTS")

---@type SDK_SDK
local SDK = DreamTSLib.TargetSelectorSdk.SDK

---@type SDK_AIHeroClient
local myHero = SDK.Player

if myHero:GetCharacterName() ~= "Fizz" then return end

local Fizz = {}

local update_data = {
    Robur = {
        ScriptName = "CXFizz",
        ScriptVersion = "1.6",
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

function Fizz:__init()
    self.e = {
        type = "circular",
        speed = 1000,
        range = 700,
        delay = 0.25,
        radius = 200,
    }
    self.r = {
        type = "linear",
        speed = 1300,
        range = 1300,
        delay = 0.25,
        width = 250,
    }
    self:Menu()
    self.QlvlDmg = {[1] = 10,[2] = 25,[3] = 40,[4] = 55,[5] = 70}
    self.TS =
        DreamTS(
        self.menu:GetLocalChild("dreamTs"),
        {
            Damage = DreamTS.Damages.AP
        }
    )
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnTick, function() self:OnTick() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnDraw, function() self:OnDraw() end)
    _G.CoreEx.EventManager.RegisterCallback(_G.CoreEx.Enums.Events.OnPostAttack, function(target) self:OnExecuteCastFrame(SDK.Types.AIBaseClient(target)) end)
end

function Fizz:Menu()
    self.menu = SDK.Libs.Menu("cxfizz", "Cyrex Fizz")

    self.menu
    :AddLabel("Cyrex Fizz Settings", true)
    :AddSubMenu("dreamTs", "Target Selector")

    self.menu
    :AddSubMenu("Key", "Key Settings")
        :AddKeybind("manual", "Manual R Aim", string.byte("T"))
        :AddKeybind("run", "Flee", string.byte("S"))
        :GetParent()
    :AddSubMenu("combo", "Combo Settings")
        :AddLabel("Q Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddSlider("qr", "Min. Q Range", {min = 0, max = 550, default = 350, step = 25})
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W", true)
        :AddLabel("E Settings", true)
        :AddCheckbox("e", "Use E", true)
        :AddCheckbox("e2", "Delay E2 For More Damage", true)
        :AddDropdown("ed", "E Mode", {"Mouse Pos", "With Prediction"}, 2)         
        :GetParent()
    :AddSubMenu("harass", "Harass Settings")
        :AddCheckbox("q", "Use Q", true)
        :AddCheckbox("w", "Use W", true)
        :AddSlider("mana", "Min Mana Percent:", {min = 0, max = 100, default = 10, step = 5})
        :GetParent()
    :AddSubMenu("auto", "Automatic Settings")
        :AddLabel("dx", "Killsteal Settings")
        :AddCheckbox("uks", "Use Killsteal", true)
        :AddCheckbox("urks", "Use R in Killsteal", true)
        :GetParent()
    :AddSubMenu("draws", "Draw")
        :AddCheckbox("q", "Q", true)
        :AddCheckbox("r", "R", true)
        :GetParent()
    :AddLabel("Version: " .. update_data.Robur.ScriptVersion .. "", true)
    :AddLabel("Author: Coozbie", true)

    self.menu:Render()
end

local color_white = SDK.Libs.Color.GetD3DColor(255,7,141,237)

function Fizz:OnDraw()
    if not myHero:IsOnScreen() then
        return
    end

    if self.menu:GetLocal("draws.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), self.menu:GetLocal("combo.qr"), color_white)
    end
    if self.menu:GetLocal("draws.r") and myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), 1300, color_white)
    end   
end

local delayedActions, delayedActionsExecuter = {}, nil
function Fizz:DelayAction(func, delay, args) --delay in seconds
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

function Fizz:GetPercentHealth(obj)
    obj = obj or myHero
    return obj:GetHealthPercent()
end

function Fizz:GetAARange(target)
    return myHero:GetAttackRange() + myHero:GetBoundingRadius() + (target and target:GetBoundingRadius() or 0)
end

function Fizz:MoveToMouse()
    SDK.Input:MoveTo(SDK.Renderer:GetMousePos3D())
end

function Fizz:ValidTarget(object, distance) 
    return object and object:IsValid() and object:IsEnemy() and object:IsVisible() and not object:GetBuff('SionPassiveZombie') and not object:GetBuff('FioraW') and object:IsAlive() and not object:IsInvulnerable() and (not distance or  object:GetPosition():DistanceSqr(myHero:GetPosition()) <= distance * distance)
end

function Fizz:GetTotalAP(obj)
    local obj = obj or myHero
    return obj:GetTotalAP()
end

function Fizz:TotalAD(obj)
    obj = obj or myHero
    return obj:GetTotalAD()
end

function Fizz:GetDistanceSqr(p1, p2)
    p2 = p2 or myHero:GetPosition()
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return dx*dx + dz*dz
end

function Fizz:GetDistance(p1, p2)
    return math.sqrt(self:GetDistanceSqr(p1, p2))
end

function Fizz:OnExecuteCastFrame(target)
    if (self.menu:GetLocal("combo.w") or self.menu:GetLocal("harass.w")) and myHero:CanUseSpell(SDK.Enums.SpellSlot.W) and (_G.Libs.Orbwalker.GetMode() == "Combo" or _G.Libs.Orbwalker.GetMode() == "Harass") then
        if target and target:AsHero() and self:ValidTarget(target) and target:GetPosition():DistanceSqr(myHero:GetPosition()) < (self:GetAARange(target) + 50)^2 then
            SDK.Input:Cast(SDK.Enums.SpellSlot.W, myHero)
        end
    end
end

function Fizz:qDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        local qDamage = self.QlvlDmg[myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetLevel()] + (self:GetTotalAP() * .55)
        local ad = self:TotalAD(myHero)
        local Total = qDamage + ad
        return self.TS.CalcDmg(myHero, target:AsAI(), Total, 0, 0)
    end
end

function Fizz:rDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        local rDamage = (125 + (100 * myHero:GetSpell(SDK.Enums.SpellSlot.R):GetLevel()) + (self:GetTotalAP() * 1))
        return self.TS.CalcDmg(myHero, target:AsAI(), rDamage, 0, 0)
    end
end

function Fizz:CastQ(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        if self:GetDistance(target:GetPosition()) < self.menu:GetLocal("combo.qr") then
            SDK.Input:Cast(SDK.Enums.SpellSlot.Q, target)
        end
    end
end

function Fizz:CastE(target)
    if myHero:GetSpell(SDK.Enums.SpellSlot.E):GetName() == "FizzE" then
        if myHero:CanUseSpell(SDK.Enums.SpellSlot.E) and self:GetDistance(target:GetPosition()) < 700 and self:GetDistance(target:GetPosition()) > 400 then
            SDK.Input:Cast(SDK.Enums.SpellSlot.E, target:GetPosition())
        end
    elseif myHero:GetSpell(SDK.Enums.SpellSlot.E):GetName() == "FizzEBuffer" then
        if myHero:CanUseSpell(SDK.Enums.SpellSlot.E) and self:GetDistanceSqr(target:GetPosition()) < (700 * 700) then
            local pred = _G.Prediction.SDK.GetPrediction(target, self.e, myHero:GetPosition())
            if pred and pred.castPosition and self:GetDistanceSqr(pred.castPosition) <= (700 * 700) then
                if self.menu:GetLocal("combo.e2") then
                    self:DelayAction(function() SDK.Input:Cast(SDK.Enums.SpellSlot.E, pred.castPosition) end, 0.75)
                elseif not self.menu:GetLocal("combo.e2") then
                    SDK.Input:Cast(SDK.Enums.SpellSlot.E, pred.castPosition)
                end
            end
        end
    end
end

function Fizz:CastR(pred)
    if pred.rates["slow"] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.R, pred.castPosition)
        pred:Draw()
        return true
    end
end

function Fizz:KillSteal()
    for i, enemy in ipairs(enemies) do
        if enemy and self:ValidTarget(enemy) then
            local hp = enemy:GetHealth()
            local dist = self:GetDistanceSqr(enemy:GetPosition())
            local q = myHero:CanUseSpell(SDK.Enums.SpellSlot.Q)
            if q and dist <= (550 * 550) and self:qDmg(enemy) > hp then
                self:CastQ(enemy)
            end
        end
    end
end

function Fizz:Run()
    if self.menu:GetLocal("Key.run") then
        self:MoveToMouse()
        if myHero:CanUseSpell(SDK.Enums.SpellSlot.E) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.E, SDK.Renderer:GetMousePos3D())
        end
    end
end


function Fizz:OnTick()
    local target = self:GetTarget(600)
    if _G.Libs.Orbwalker.GetMode() == "Combo" then
        if target and self:ValidTarget(target) then
            local q = myHero:CanUseSpell(SDK.Enums.SpellSlot.Q)
            local e = myHero:CanUseSpell(SDK.Enums.SpellSlot.E)
            local d = self:GetDistance(target:GetPosition())
            if self.menu:GetLocal("combo.q") and q then
                self:CastQ(target)
            end
            if self.menu:GetLocal("combo.e") and e then
                local menu_combo_mode = self.menu:GetLocal("combo.ed")
                if menu_combo_mode == 1 then
                    if e and d <= 600 then
                        self:DelayAction(function() SDK.Input:Cast(SDK.Enums.SpellSlot.E, SDK.Renderer:GetMousePos3D()) end, 0.5)
                    end
                elseif menu_combo_mode == 2 then
                    self:CastE(target)
                end
            end
        end
    end
    if _G.Libs.Orbwalker.GetMode() == "Harass" then
        if target and self:ValidTarget(target) then
            if self.menu:GetLocal("harass.q") then         
                self:CastQ(target)
            end          
        end
    end
    self:KillSteal()
    self:Run()
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        local r_targets, r_preds = self.TS:GetTargets(self.r, myHero:GetPosition(), nil, nil, self.TS.Modes["Lowest HP"])
        local r_ks, r_ks_pred = self.TS:GetTargets(self.r, myHero:GetPosition(), function(enemy) return (enemy:GetHealth() / self:rDmg(enemy)) >= 0.50 and self:rDmg(enemy) >= enemy:GetHealth() end)
        if self.menu:GetLocal("auto.urks") then
            local target = r_ks[1]
            if target then
                local pred = r_ks_pred[target:GetNetworkId()]
                if pred and self:CastR(pred) then
                    return
                end
            end
        end
        if self.menu:GetLocal("Key.manual") then
            local target = r_targets[1]
            if target then
                local pred = r_preds[target:GetNetworkId()]
                if pred and self:CastR(pred) then
                    return
                end
            end
        end
    end
end

local get_d3d_color = SDK.Libs.Color.GetD3DColor
function Fizz:Hex(a, r, g, b)
    return get_d3d_color(a, r, g, b)
end

function Fizz:GetTarget(dist, all)
    local res = self.TS:update(function(unit) return _G.Prediction.SDK.IsValidTarget(unit, dist) end)
    if all then
        return res
    else
        if res and res[1] then
            return res[1]
        end
    end
end

if myHero:GetCharacterName() == "Fizz" then
    Fizz:__init()
end
