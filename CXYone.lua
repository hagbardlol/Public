local DreamTSLib = _G.DreamTS or require("DreamTS")

---@type SDK_SDK
local SDK = DreamTSLib.TargetSelectorSdk.SDK

---@type SDK_AIHeroClient
local myHero = SDK.Player

if myHero:GetCharacterName() ~= "Yone" then return end

local Yone = {}

local update_data = {
    Robur = {
        ScriptName = "CXYone",
        ScriptVersion = "1.5",
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

function Yone:__init()
    self.q = {
        type = "linear",
        speed = math.huge,
        range = 450,
        delay = math.max(0.175, 0.35 - ((myHero:GetAttackSpeedMod() - 1) * (0.35 - 0.3325) / 0.12)),
        width = 80,
        castRate = "instant",
    }
    self.q2 = {
        type = "linear",
        speed = 1500,
        range = 985,
        delay = 0.35,
        width = 160,
        castRate = "slow",
    }
    self.w = {
        type = "cone",
        speed = math.huge,
        range = 600,
        delay = (0.5 * (1 - math.min((myHero:GetAttackSpeedMod() - 1) * 0.58, 0.66))),
        angle = 80,
        castRate = "slow",
    }
    self.r = {
        type = "linear",
        speed = math.huge,
        range = 990,
        delay = 0.8,
        width = 225,
        castRate = "slow",
    }
    self:Menu()
    self.shadow = nil
    self.mark = nil
    self.marks = {}
    self.death = false
    self.TS =
        DreamTS(
        self.menu:GetLocalChild("dreamTs"),
        {
            Damage = DreamTS.Damages.AD
        }
    )
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnTick, function() self:OnTick() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnDraw, function() self:OnDraw() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnCreateObject, function(obj) self:OnCreateObject(obj) end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnDeleteObject, function(obj) self:OnDeleteObject(obj) end)
    self.fontSize = 25
    self.font1Size = 12
end

function Yone:Menu()
    self.menu = SDK.Libs.Menu("cxyone", "Cyrex Yone")
    
    self.menu
    :AddLabel("Cyrex Yone Settings", true)
    :AddSubMenu("dreamTs", "Target Selector")

    self.menu
    :AddSubMenu("Key", "Key Settings")
        :AddKeybind("r", "Use R on X Enemys", string.byte("T"))
        :AddSlider("rx", "^ R If Enemies >=", {min = 1, max = 5, default = 3, step = 1})
        :AddKeybind("q", "Auto Stack Q", string.byte("A"), true, true)
        :GetParent()
    :AddSubMenu("combo", "Combo Settings")
        :AddLabel("Q Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddCheckbox("q3", "Use Q3", true)
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W", true)
        :AddLabel("R Settings", true)
        :AddCheckbox("r", "Use R", true)
        :AddCheckbox("er", "Use only with Shadow", true)
        :AddSlider("rx", "Auto R If Enemies >= ", {min = 1, max = 5, default = 3, step = 1})
        :GetParent()
    :AddSubMenu("harass", "Harass Settings")
        :AddCheckbox("q", "Use Q", true)
        :AddCheckbox("q3", "Use Q3", true)
        :AddCheckbox("w", "Use W", true)
        :GetParent()
    :AddSubMenu("lc", "Lane Clear Settings")
        :AddLabel("Lane Clear Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddSlider("qx", "Use Q If Minions >=", {min = 1, max = 12, default = 3, step = 1})
        :AddLabel("Last Hit Settings", true)
        :AddCheckbox("qlh", "Use Q", true)
        :GetParent()
    :AddSubMenu("jg", "Jungle Clear Settings")
        :AddLabel("Jungle Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddCheckbox("w", "Use W", true)
        :GetParent()
    :AddSubMenu("auto", "Automatic Settings")
        :AddLabel("Killsteal Settings", true)
        :AddCheckbox("uks", "Use Smart Killsteal", true)
        :AddCheckbox("uksq", "Use Q in Killsteal", true)
        :AddCheckbox("uksq3", "Use Q3 in Killsteal", true)
        :AddCheckbox("ukse", "Use Experimental E Killsteal", true)
        :AddSlider("ukser", "E KS Range Scan (1v1)", {min = 450, max = 1000, default = 600, step = 25})
        :AddKeybind("urks", "Use R in Killsteal", string.byte("K"), true, true)
        :GetParent()
    :AddSubMenu("draws", "Draw")
        :AddCheckbox("q", "Q", true)
        :AddCheckbox("r", "R", true)
        :AddCheckbox("shadow", "Draw Shadow", true)
        :AddCheckbox("mark", "Draw Mark Killable", true)
        :GetParent()
    :AddLabel("Version: " .. update_data.Robur.ScriptVersion .. "", true)
    :AddLabel("Author: Coozbie", true)

    self.menu:Render()
end

local color_white = SDK.Libs.Color.GetD3DColor(255,7,141,237)
local color_red   = SDK.Libs.Color.GetD3DColor(255,255,0,0)
local color_w     = SDK.Libs.Color.GetD3DColor(255,255,255,255)
local color_g     = SDK.Libs.Color.GetD3DColor(255,0,255,0)


function Yone:OnDraw()
    if not myHero:IsOnScreen() then
        return
    end
    local hero_pos = myHero:GetPosition()

    if self.menu:GetLocal("draws.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        if myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ" then
            SDK.Renderer:DrawCircle3D(myHero:GetPosition(), 450, color_white)
        else
            SDK.Renderer:DrawCircle3D(myHero:GetPosition(), 1050, color_white)
        end
    end
    if self.menu:GetLocal("draws.r") and myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), 1000, color_white)
    end
    if self.menu:GetLocal("draws.shadow") and self.shadow then
        local hero_pos_2d = SDK.Renderer:WorldToScreen(Vector(hero_pos.x - 60,hero_pos.y, hero_pos.z -25))
        local font_size = 10
        SDK.Renderer:DrawCircle3D(self.shadow:GetPosition(), 100, color_w)
        SDK.Renderer:DrawText("Enemys Near Shadow: "..#self:count_enemies_in_range(self.shadow:GetPosition(), 500), 20, hero_pos_2d, color_w)
    end
    local hero_pos_q = SDK.Renderer:WorldToScreen(Vector(hero_pos.x - 60,hero_pos.y, hero_pos.z -55))
    if self.menu:GetLocal("Key.q") then
        SDK.Renderer:DrawText("Stack Q: On", 20, hero_pos_q, color_w)
    else
        SDK.Renderer:DrawText("Stack Q: Off", 20, hero_pos_q, color_w)
    end
    if self.menu:GetLocal("draws.mark") and self.shadow and self.mark then
        for i, enemy in ipairs(self.marks) do
            local hero_pos_m = SDK.Renderer:WorldToScreen(Vector(hero_pos.x - 200,hero_pos.y, hero_pos.z + 500 + i *100))
            SDK.Renderer:DrawText(enemy.hero:GetCharacterName() .. " IS DEAD", 20, hero_pos_m, color_red)
        end
    end
end


local delayedActions, delayedActionsExecuter = {}, nil
function Yone:DelayAction(func, delay, args) --delay in seconds
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

function Yone:GetDistanceSqr(p1, p2)
    p2 = p2 or myHero:GetPosition()
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return dx*dx + dz*dz
end

function Yone:GetPercentHealth(obj)
    obj = obj or myHero
    return obj:GetHealthPercent()
end

function Yone:MoveToMouse()
    SDK.Input:MoveTo(SDK.Renderer:GetMousePos3D())
end

function Yone:ValidTarget(object, distance) 
    return object and object:IsValid() and object:IsEnemy() and object:IsVisible() and not object:GetBuff('SionPassiveZombie') and not object:GetBuff('FioraW') and object:IsAlive() and not object:IsInvulnerable() and (not distance or  object:GetPosition():DistanceSqr(myHero:GetPosition()) <= distance * distance)
end

function Yone:TotalAD(obj)
    obj = obj or myHero
    return obj:GetTotalAD()
end

function Yone:GetBonusAD(obj)
    obj = obj or myHero
    return obj:GetFlatPhysicalDamageMod()
end

function Yone:GetTotalAP(obj)
    local obj = obj or myHero
    return obj:GetTotalAP()
end

function Yone:count_enemies_in_range(position, range)
    local enemies_in_range = {}
    for _, enemy in ipairs(SDK.ObjectManager:GetEnemyHeroes()) do
        local hero = enemy:AsAI()
        if hero:IsValid() and hero:IsTargetable() and hero:IsAlive() and (hero:GetPosition():DistanceSqr(position) < (range * range)) then
            enemies_in_range[#enemies_in_range + 1] = enemy
        end
    end
    return enemies_in_range
end

function Yone:GetClosestEnemyToMouse()
    -- TODO: rework this
    local mousePos = SDK.Renderer:GetMousePos3D()
    local closestDist = 1000000
    local closestEnemy = nil
    for _, enemy in pairs(enemies) do
        if enemy:IsValid() and enemy:IsVisible() and enemy:IsAlive() then
            local dist = self:GetDistanceSqr(enemy:GetPosition(), mousePos)
            if dist < closestDist then
                closestDist = dist
                closestEnemy = enemy
            end
        end
    end
    return closestEnemy
end

function Yone:GetEnemyHeroesInRange(range, pos)
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

function Yone:GetAARange(target)
    return myHero:GetAttackRange() + myHero:GetBoundingRadius() + (target and target:GetBoundingRadius() or 0)
end

function Yone:OnCreateObject(obj)
    if obj:IsValid() then
        if obj:GetTeam() == myHero:GetTeam() and obj:GetName():lower():find("testcuberender10vision") then
            self.shadow = obj
        end
        if obj:GetName():lower():find("yone") and obj:GetName():lower():find("mark_execute") then
            self.mark = obj
            self.death = true
            local hero, closest = nil, 100000 ^ 2
            for _, enemy in pairs(enemies) do
                local dist = self:GetDistanceSqr(enemy:GetPosition(), obj:GetPosition())
                if dist < closest then
                    closest = dist
                    hero = enemy
                end
            end
            table.insert(self.marks, {obj = obj, hero = hero})
        end
    end
end

function Yone:OnDeleteObject(obj)
    if obj:IsValid() then
        if obj:GetTeam() == myHero:GetTeam() and obj:GetName():lower():find("testcuberender10vision") then
            self.shadow = nil
        end
        if obj:GetName():lower():find("yone") and obj:GetName():lower():find("mark_execute") then
            self.mark = nil
            self.death = false
            for i = #self.marks, 1, -1 do
                if obj == self.marks[i].obj then
                    table.remove(self.marks, i)
                end
            end
        end
    end
end

function Yone:UpdateSpellDelays()
    local Q1_MAX_WINDUP = 0.35
    local Q1_MIN_WINDUP = 0.175
    local LOSS_WINDUP_PER_ATTACK_SPEED = (0.35 - 0.3325) / 0.12

    local additional_attack_speed = (myHero:GetAttackSpeedMod() - 1)
    local q1_delay = math.max(Q1_MIN_WINDUP, Q1_MAX_WINDUP - (additional_attack_speed * LOSS_WINDUP_PER_ATTACK_SPEED))
    self.q.delay = q1_delay
    self.q2.delay = q1_delay
    self.w.delay = (0.5 * (1 - math.min((myHero:GetAttackSpeedMod() - 1) * 0.58, 0.66)))
end

function Yone:qDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        local qDamage = ((25 * myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetLevel()) - 5 + (self:TotalAD() * 1.05))
        return self.TS.CalcDmg(myHero, target:AsAI(), qDamage, 0, 0)
    end
end

function Yone:rDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        local rDamageAP = ((100 * myHero:GetSpell(SDK.Enums.SpellSlot.R):GetLevel()) + (self:TotalAD() * 0.4))
        local rDamageAD = ((100 * myHero:GetSpell(SDK.Enums.SpellSlot.R):GetLevel()) + (self:TotalAD() * 0.4))
        return self.TS.CalcDmg(myHero, target:AsAI(), rDamageAD+rDamageAP, 0, 0)
    end
end

function Yone:CountEnemiesInR(endPos)
    local count = 0
    for i, enemy in ipairs(enemies) do
        if self:ValidTarget(enemy) then
            local col = _G.Prediction.IsCollision(self.r, myHero:GetPosition(), endPos, enemy.data)
            if col then
                count = count + 1
            end
        end
    end
    return count
end

function Yone:MultiR(minCount)
    local rTargets, rPreds = self.TS:GetTargets(self.r,
        myHero:GetPosition(),
        function(unit)
            return self:GetDistanceSqr(unit:GetPosition()) <= (self.r.range + unit:GetBoundingRadius()) ^ 2
        end
    )
    local bestCount, bestObj, bestPred = minCount - 1, nil, nil
    for _, enemy in pairs(rTargets) do
        count = 0
        local pred = rPreds[enemy:GetNetworkId()]
        if pred then
            for _, enemy2 in pairs(rTargets) do
                local col = _G.Prediction.IsCollision(self.r, myHero:GetPosition(), pred.castPosition, enemy2.data)
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
        SDK.Input:Cast(SDK.Enums.SpellSlot.R, bestPred.castPosition)
    end
end

function Yone:CastQ(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ" then
        local pred = _G.Prediction.SDK.GetPrediction(target, self.q, myHero:GetPosition())
        if pred and pred.castPosition and self:GetDistanceSqr(pred.castPosition) <= (self.q.range * self.q.range) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.Q, pred.castPosition)
            pred:Draw()
        end
    end
end

function Yone:CastQ3(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ3" then
        local pred = _G.Prediction.SDK.GetPrediction(target, self.q2, myHero:GetPosition())
        if pred and pred.castPosition and self:GetDistanceSqr(pred.castPosition) <= (self.q2.range * self.q2.range) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.Q, pred.castPosition)
            pred:Draw()
        end
    end
end

function Yone:CastW(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then
        local pred = _G.Prediction.SDK.GetPrediction(target, self.w, myHero:GetPosition())
        if pred and pred.castPosition and self:GetDistanceSqr(pred.castPosition) <= (self.w.range * self.w.range) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.W, pred.castPosition)
            pred:Draw()
        end
    end
end

function Yone:CastR(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        local pred = _G.Prediction.SDK.GetPrediction(target, self.r, myHero:GetPosition())
        if pred and pred.castPosition and self:GetDistanceSqr(pred.castPosition) <= (self.r.range * self.r.range) then
            SDK.Input:Cast(SDK.Enums.SpellSlot.R, pred.castPosition)
            pred:Draw()
        end
    end
end

function Yone:KillSteal()
    for i, enemy in ipairs(enemies) do
        if enemy and self:ValidTarget(enemy) then
            local hp = enemy:GetHealth()
            local d = self:GetDistanceSqr(enemy:GetPosition())
            local q = myHero:CanUseSpell(SDK.Enums.SpellSlot.Q)
            local e = myHero:CanUseSpell(SDK.Enums.SpellSlot.E)
            local r = myHero:CanUseSpell(SDK.Enums.SpellSlot.R)
            local qd = self:qDmg(enemy)
            local rd = self:rDmg(enemy)
            if self.menu:GetLocal("auto.uksq") and q and hp < qd and d < (450 * 450) and myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ" then
                self:CastQ(enemy)
            end
            if self.menu:GetLocal("auto.uksq3") and q and hp < qd and d < (985 * 985) and myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ3" then
                self:CastQ3(enemy)
            end
            if self.menu:GetLocal("auto.urks") and r and hp < rd and d < (1000 * 1000) then
                self:CastR(enemy)
            end
            if self.menu:GetLocal("auto.ukse") and e and myHero:GetMana() > 0 and self.death and #self:GetEnemyHeroesInRange(self.menu:GetLocal("auto.ukser")) == 1 then
                SDK.Input:Cast(SDK.Enums.SpellSlot.E, SDK.Renderer:GetMousePos3D())
            end
        end
    end
end


function Yone:JungleClear()
    local Jungle = _G.CoreEx.ObjectManager.GetNearby("neutral", "minions")
    for iJGLQ, objJGLQ in ipairs (Jungle) do
        local minion = objJGLQ.AsMinion
        if minion and minion.IsMinion and minion.MaxHealth > 6 and not minion.IsDead and minion.Position:DistanceSqr(myHero:GetPosition()) < (450 * 450) and _G.Libs.TargetSelector():IsValidTarget(minion) then
            if self.menu:GetLocal("jg.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ" then
                SDK.Input:Cast(SDK.Enums.SpellSlot.Q, minion.Position)
            end
            if self.menu:GetLocal("jg.w") and myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then
                SDK.Input:Cast(SDK.Enums.SpellSlot.W, minion.Position)
            end
        end
    end
end

function Yone:CountMinQ(endPos)
    local count = 0
    for i, enemy in ipairs(SDK.ObjectManager:GetEnemyMinions()) do
        enemy = enemy:AsAI()
        if enemy and enemy:GetMoveSpeed() > 0 and enemy:IsAlive() and enemy:IsVisible() then
            local col = _G.Prediction.IsCollision(self.q, myHero:GetPosition(), endPos, enemy.data)
            if col then
                count = count + 1
            end
        end
    end
    return count
end

function Yone:LaneClear()
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and self.menu:GetLocal("lc.q") and myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ" then
        for i, minion1 in ipairs(SDK.ObjectManager:GetEnemyMinions()) do
            minion1 = minion1:AsAI()
            if minion1 and minion1:IsValid() and minion1:IsAlive()  and minion1:GetMaxHealth() > 6 then
                local pred = _G.Prediction.SDK.GetPrediction(minion1, self.q, myHero:GetPosition())
                if pred and pred.castPosition and self:GetDistanceSqr(pred.castPosition) < (450 * 450) then
                    if self:CountMinQ(pred.castPosition) >= self.menu:GetLocal("lc.qx") then
                        SDK.Input:Cast(SDK.Enums.SpellSlot.Q, pred.castPosition)
                        break
                    end
                end
            end
        end
    end
end

function Yone:LastHit()
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and self.menu:GetLocal("lc.qlh") and myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ" then
        for i, minion in ipairs(SDK.ObjectManager:GetEnemyMinions()) do
            minion = minion:AsAI()
            if minion and minion:IsValid() and minion:IsAlive() and minion:GetMaxHealth() > 6 and minion:GetPosition():DistanceSqr(myHero:GetPosition()) < (450 * 450) then 
                if (self:qDmg(minion) > minion:GetHealth()) then
                    if minion:GetName() == "CampRespawn" or minion:GetName() == "WardCorpse" then return end
                    self:CastQ(minion)
                end
            end
        end
    end
end

function Yone:OnTick()
    self:UpdateSpellDelays()
    local target = self:GetTarget(myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ" and 450 or 985)
    local target2 = self:GetTarget(600)
    if _G.Libs.Orbwalker.GetMode() == "Combo" then
        if target and target.IsAI and self:ValidTarget(target) then
            local q = myHero:CanUseSpell(SDK.Enums.SpellSlot.Q)
            if self.menu:GetLocal("combo.q") and q and not myHero:IsWindingUp() then
                self:CastQ(target)
            end
            if self.menu:GetLocal("combo.q3") and q and myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ3" then
                local qtarget = self:GetClosestEnemyToMouse()
                if not qtarget then
                    return
                end
                local pred = _G.Prediction.SDK.GetPrediction(qtarget, self.q2, myHero:GetPosition())
                if qtarget and pred and pred.castPosition and self:GetDistanceSqr(pred.castPosition) <= (self.q2.range * self.q2.range) then
                    SDK.Input:Cast(SDK.Enums.SpellSlot.Q, pred.castPosition)
                    pred:Draw()
                end
            end
        end
        if target2 and target2.IsAI and self:ValidTarget(target2) then
            local w = myHero:CanUseSpell(SDK.Enums.SpellSlot.W)
            if self.menu:GetLocal("combo.w") and w and not myHero:IsWindingUp() then         
                self:CastW(target2)
            end
        end
        if (myHero:CanUseSpell(SDK.Enums.SpellSlot.R) and self.menu:GetLocal("combo.er")) then
            if (self.shadow and self.menu:GetLocal("combo.rx") > 0 and self:MultiR(self.menu:GetLocal("combo.rx"))) then
                return
            end
        else
            if (myHero:CanUseSpell(SDK.Enums.SpellSlot.R) and self.menu:GetLocal("combo.rx") > 0 and self:MultiR(self.menu:GetLocal("combo.rx"))) then
                return
            end
        end
    end
    if _G.Libs.Orbwalker.GetMode() == "Harass" then
        if target and self:ValidTarget(target) then
            if self.menu:GetLocal("harass.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
                self:CastQ(target)
            end
            if self.menu:GetLocal("harass.q3") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
                self:CastQ3(target)
            end
            if self.menu:GetLocal("harass.w") and myHero:CanUseSpell(SDK.Enums.SpellSlot.W) then         
                self:CastW(target)
            end      
        end
    end
    if self.menu:GetLocal("auto.uks") then self:KillSteal() end
    if _G.Libs.Orbwalker.GetMode() == "Waveclear" then self:JungleClear() self:LaneClear() self:LastHit() end
    if _G.Libs.Orbwalker.GetMode() == "Lasthit" then self:LastHit() end
    if self.menu:GetLocal("Key.r") and myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        self:MoveToMouse()
        for i, enemy in ipairs(enemies) do
            if self:ValidTarget(enemy) then
                local pred = _G.Prediction.SDK.GetPrediction(enemy, self.r, myHero:GetPosition())
                if pred and pred.castPosition and self:GetDistanceSqr(pred.castPosition) <= (1000 * 1000) then
                    if self:CountEnemiesInR(pred.castPosition) >= self.menu:GetLocal("Key.rx") then
                        SDK.Input:Cast(SDK.Enums.SpellSlot.R, pred.castPosition)
                    end
                end
            end
        end
    end
    if self.menu:GetLocal("Key.q") then
        if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ" and #self:GetEnemyHeroesInRange(450) == 0 then
            for i, obj in ipairs(SDK.ObjectManager:GetEnemyMinions()) do
                obj = obj:AsAI()
                if obj and obj:IsValid() and obj:IsAlive() and obj:GetMaxHealth() > 6 and self:GetDistanceSqr(obj:GetPosition()) <= (450 * 450) and myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetName() == "YoneQ" and obj:AsMinion() then
                    if obj:GetName() == "CampRespawn" or obj:GetName() == "WardCorpse" then return end
                    self:CastQ(obj)
                end
            end
        end
    end
end


local get_d3d_color = SDK.Libs.Color.GetD3DColor
function Yone:Hex(a, r, g, b)
    return get_d3d_color(a, r, g, b)
end

function Yone:GetTarget(dist, all)
    local res = self.TS:update(function(unit) return _G.Prediction.SDK.IsValidTarget(unit, dist) end)
    if all then
        return res
    else
        if res and res[1] then
            return res[1]
        end
    end
end

if myHero:GetCharacterName() == "Yone" then
    Yone:__init()
end
