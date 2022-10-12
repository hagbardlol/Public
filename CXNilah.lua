local DreamTSLib = _G.DreamTS or require("DreamTS")

---@type SDK_SDK
local SDK = DreamTSLib.TargetSelectorSdk.SDK

---@type SDK_AIHeroClient
local myHero = SDK.Player

if myHero:GetCharacterName() ~= "Nilah" then return end

local Nilah = {}

local update_data = {
    Robur = {
        ScriptName = "CXNilah",
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
local CastModeOptions = {"instant", "medium", "slow", "veryslow"}
--[[
BUFFS
- alistareattack
OnProc
- FioraQ, range = 400, Speed = 500
- FizzQ, range = 550, Speed = 20
]]
local TargetedAA = {
    ["AkaliBasicAttackPassiveMelee"] = {charName = "Akali", delay = 0.17, speed = math.huge},
    ["AkaliBasicAttackPassive"] = {charName = "Akali", delay = 0.17, speed = math.huge},
    ["PowerFistAttack"] = {charName = "Blitzcrank", delay = 0.25, speed = math.huge},
    ["CaitlynPassiveMissile"] = {charName = "Caitlyn", delay = 0.25, speed = math.huge},
    ["CamilleQAttackEmpowered"] = {charName = "Camille", delay = 0.25, speed = math.huge},
    ["DariusNoxianTacticsONHAttack"] = {charName = "Darius", delay = 0.25, speed = math.huge},
    ["DravenSpinningAttack"] = {charName = "Draven", delay = 0.25, speed = math.huge},
    ["DravenSpinningAttack2"] = {charName = "Draven", delay = 0.25, speed = math.huge},
    ["EkkoEAttack"] = {charName = "Ekko", delay = 0.25, speed = math.huge},
    ["FioraEAttack"] = {charName = "Fiora", delay = 0.25, speed = math.huge},
    ["FioraEAttack2"] = {charName = "Fiora", delay = 0.25, speed = math.huge},
    ["FizzWBasicAttack"] = {charName = "Fizz", delay = 0.25, speed = math.huge},
    ["GalioPassiveAttack"] = {charName = "Galio", delay = 0.25, speed = math.huge},
    ["LeonaShieldOfDaybreakAttack"] = {charName = "Leona", delay = 0.32, speed = math.huge},
}

local TargetedSpell = {
    ["GangplankQProceed"]           = {charName = "Gangplank"   , slot = "Q" , delay = 0.25, speed = 2600       , isMissile = true },
    ["IreliaQ"]                     = {charName = "Irelia"      , slot = "Q" , delay = 0,    speed = 1800       , isMissile = false},
    ["FizzQ"]                       = {charName = "Fizz"        , slot = "Q" , delay = 0,    speed = math.huge  , isMissile = false},
    ["MasterYiQ"]                   = {charName = "MasterYi"    , slot = "Q" , delay = 0,    speed = math.huge  , isMissile = false},
    ["BlindingDart"]                = {charName = "Teemo"       , slot = "Q" , delay = 0.25, speed = 1500       , isMissile = true },
}

function Nilah:__init()
    self.q = {
        type = "linear",
        speed = math.huge,
        range = 600,
        delay = 0.25,
        width = 150,
        collision = {
            ["Wall"] = false,
            ["Hero"] = false,
            ["Minion"] = false
        }
    }
    self.r = {
        type = "circular",
        speed = math.huge,
        range = 1,
        delay = 0.25,
        radius = 450,
    }
    self:Menu()
    self.QlvlDmg = {[1] = 0.9, [2] = 1, [3] = 1.10, [4] = 1.20, [5] = 1.3}
    self.TS =
        DreamTS(
        self.menu:GetLocalChild("dreamTs"),
        {
            Damage = DreamTS.Damages.AD
        }
    )
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnTick, function() self:OnTick() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnDraw, function() self:OnDraw() end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnProcessSpell, function(unit, spell) self:OnProcessSpell(unit, spell) end)
    SDK.EventManager:RegisterCallback(SDK.Enums.Events.OnBasicAttack, function(unit, spell) self:OnExecuteCastFrames(unit, spell) end)
end

function Nilah:Menu()
    self.menu = SDK.Libs.Menu("cxNilah", "Cyrex Nilah")

    self.menu
    :AddLabel("Cyrex Nilah Settings", true)
    :AddSubMenu("dreamTs", "Target Selector")

    self.menu
    :AddSubMenu("Key", "Key Settings")
        :AddKeybind("e", "Semi Manual E", string.byte("E"))
        :AddKeybind("s", "Escape Key", string.byte("S"))
        :AddCheckbox("stack", "Keep 1 Stack", true)
        :GetParent()
    :AddSubMenu("combo", "Combo Settings")
        :AddLabel("Q Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddLabel("W Settings", true)
        :AddCheckbox("w", "Use W", true)
        :AddSlider('wDelay', 'Xs before Spell hit', {min = 0, max = 0.75, default = 0.1, step = 0.01})
        :AddLabel("E Settings", true)
        :AddCheckbox("e", "Use E", true)
        :AddLabel("R Settings", true)
        :AddCheckbox("r", "Use R", true)
        :AddSlider("rx", "R If Enemies >=", {min = 1, max = 5, default = 3, step = 1})
        :GetParent()

    self.menu
    :AddSubMenu("blockSpell", "Auto W Block Spell")
    local block_sub_menu = self.menu:GetLocalChild("blockSpell")

    for i, enemy in ipairs(enemies) do
        for k, spell in pairs(TargetedSpell) do
            if enemy:GetCharacterName() == spell.charName then
                block_sub_menu:AddLabel(enemy:GetCharacterName() .."  ", true)
                block_sub_menu:AddCheckbox(k, enemy:GetCharacterName() .." ["..spell.slot.."] | "..k, true)
                block_sub_menu:AddSlider(k .. "hp", " ^- Health Percent: ", {min = 5, max = 100, default = 100, step = 5})
            end
        end
    end
    self.menu
    :AddSubMenu("blockaa", "Auto W Special AA")
    local block_aa_menu = self.menu:GetLocalChild("blockaa")

    for i, enemy in ipairs(enemies) do
        for k, spell in pairs(TargetedAA) do
            if enemy:GetCharacterName() == spell.charName then
                block_aa_menu:AddLabel(enemy:GetCharacterName() .."  ", true)
                block_aa_menu:AddCheckbox(k, enemy:GetCharacterName() .." [AA]", true)
                block_aa_menu:AddSlider(k .. "hp", " ^- Health Percent: ", {min = 5, max = 100, default = 100, step = 5})
            end
        end
    end

    self.menu
    :AddSubMenu("harass", "Harass Settings")
        :AddLabel("Q Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :AddCheckbox("tc", "Turret Check", true)
        :AddSlider("mana", "Min Mana Percent:", {min = 0, max = 100, default = 10, step = 5})
        :GetParent()
    :AddSubMenu("jg", "Jungle Clear Settings")
        :AddLabel("Jungle Settings", true)
        :AddCheckbox("q", "Use Q", true)
        :GetParent()
    :AddSubMenu("lc", "Lane Clear")
        :AddCheckbox("q", "Use Q (Fast Clear)", true)
        :AddSlider("qx", "Min Minions:", {min = 0, max = 8, default = 3, step = 1})
        :AddSlider("qm", "Min Mana Percent:", {min = 0, max = 100, default = 10, step = 5})
        :GetParent()
    :AddSubMenu("auto", "Automatic Settings")
        :AddLabel("Killsteal Settings", true)
        :AddCheckbox("uqks", "Use Q in Killsteal", true)
        :AddCheckbox("ueks", "Use E in Killsteal", true)
        :AddCheckbox("urks", "Use R in Killsteal", true)
        :GetParent()
    :AddSubMenu("misc", "Misc. Settings")
        :AddLabel("Prediction Settings", true)
        :AddDropdown("qc", "Q Combo", CastModeOptions, 3)
        :AddDropdown("qh", "Q Harass", CastModeOptions, 1)
        :AddDropdown("r", "Killsteal R", CastModeOptions, 3)
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

function Nilah:OnDraw()
    if not myHero:IsOnScreen() then
        return
    end

    if self.menu:GetLocal("draws.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), self.q.range, color_white)
    end
    if self.menu:GetLocal("draws.r") and myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        SDK.Renderer:DrawCircle3D(myHero:GetPosition(), 450, color_white)
    end  
end

local delayedActions, delayedActionsExecuter = {}, nil
function Nilah:DelayAction(func, delay, args) --delay in seconds
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

function Nilah:GetPercentHealth(obj)
    obj = obj or myHero
    return obj:GetHealthPercent()
end

function Nilah:GetTotalAP(obj)
  local obj = obj or myHero
  return obj:GetTotalAP()
end

function Nilah:MoveToMouse()
    SDK.Input:MoveTo(SDK.Renderer:GetMousePos3D())
end

function Nilah:TotalAD(obj)
    obj = obj or myHero
    return obj:GetTotalAD()
end

---@param obj SDK_AIBaseClient | nil
function Nilah:GetBonusAD(obj)
  obj = obj or myHero
  return obj:GetFlatPhysicalDamageMod()
end

function Nilah:GetDistanceSqr(p1, p2)
    p2 = p2 or myHero:GetPosition()
    local dx = p1.x - p2.x
    local dz = p1.z - p2.z
    return dx*dx + dz*dz
end

function Nilah:GetCastRate(spell)
    return CastModeOptions[self.menu:GetLocal("misc." .. spell)]
end

function Nilah:GetDistance(p1, p2)
  return math.sqrt(self:GetDistanceSqr(p1, p2))
end

function Nilah:ValidTarget(object, distance) 
    return object and object:IsValid() and object:IsEnemy() and object:IsVisible() and not object:GetBuff('SionPassiveZombie') and not object:GetBuff('FioraW') and object:IsAlive() and not object:IsInvulnerable() and (not distance or  object:GetPosition():DistanceSqr(myHero:GetPosition()) <= distance * distance)
end

function Nilah:GetAARange(target)
    return myHero:GetAttackRange() + myHero:GetBoundingRadius() + (target and target:GetBoundingRadius() or 0)
end

function Nilah:qDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        local qDamage = (5 * myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetLevel() + (self.QlvlDmg[myHero:GetSpell(SDK.Enums.SpellSlot.Q):GetLevel()] * self:TotalAD())) * (1 + myHero:GetCritChance())
        return self.TS.CalcDmg(myHero, target:AsAI(), qDamage, 0, 0)
    end
end

--print(myHero:GetSpell(SDK.Enums.SpellSlot.E):GetAmmo())

function Nilah:eDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.E) then
        local eDamage = 40 + (25 * myHero:GetSpell(SDK.Enums.SpellSlot.E):GetLevel()) + (0.2 * self:TotalAD())
        return self.TS.CalcDmg(myHero, target:AsAI(), eDamage, 0, 0)
    end
end

function Nilah:rDmg(target)
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        local rDamage = 25 + (100 * myHero:GetSpell(SDK.Enums.SpellSlot.R):GetLevel()) + (1.2 * self:GetBonusAD())
        return self.TS.CalcDmg(myHero, target:AsAI(), rDamage, 0, 0)
    end
end

function Nilah:AADmg(target)
    local ad = myHero:GetBaseAttackDamage() + myHero:GetFlatPhysicalDamageMod()
    local Defense = 100 / (100 + target:GetArmor())
    local damage = (ad * Defense)   
    return damage   
end

function Nilah:GetEnemyHeroesInRange(range, pos)
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

function Nilah:OnProcessSpell(unit, spell)
    local target = spell:GetTarget()
    if spell:GetName() == "NilahE" and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        if target and target:IsValid() and target:IsEnemy() and target:IsHero() then
            SDK.Input:Cast(SDK.Enums.SpellSlot.Q, myHero:GetPosition())
        end
    end
    if not (unit:IsEnemy() and target and target:IsMe()) then return end
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.W) and self.menu:GetLocal("combo.w") then
        local spellName = spell:GetName()
        local data = TargetedSpell[spellName]
        if data and self.menu:GetLocal("blockSpell." .. spellName) and self.menu:GetLocal("blockSpell." .. spellName .. "hp") >= Player.HealthPercent * 100 then
            local dt = unit:GetPosition():Distance(myHero:GetPosition())
            local hitTime = data.delay + dt/data.speed - self.menu:GetLocal("combo.wDelay")
            delay(hitTime*1000, function() SDK.Input:Cast(SDK.Enums.SpellSlot.W, myHero) end)
        end
    end
end

function Nilah:OnExecuteCastFrames(unit, spell)
    if not spell:GetName():lower():find("attack") then return end
    local target = spell:GetTarget()
    if not (unit:IsEnemy() and target and target:IsMe()) then return end

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.W) and self.menu:GetLocal("combo.w") then
        local spellName = spell:GetName()
        local data = TargetedAA[spellName]
        if data and self.menu:GetLocal("blockaa." .. spellName) and self.menu:GetLocal("blockaa." .. spellName .. "hp") >= Player.HealthPercent * 100 then
            local dt = unit:GetPosition():Distance(myHero:GetPosition())
            local hitTime = unit:GetAttackCastDelay() - self.menu:GetLocal("combo.wDelay")
            delay(hitTime*1000, function() SDK.Input:Cast(SDK.Enums.SpellSlot.W, myHero) end)
        end
    end
end

function Nilah:JungleClear()
    local enemyMinions = SDK.ObjectManager:GetEnemyMinions()
    for i = 1, #enemyMinions do
        local obj = enemyMinions[i]:AsAI()
        if obj and obj:IsValid() and obj:GetMaxHealth() > 6 and not obj:IsDead() and obj:IsTargetable() and obj:GetTeam() == 300 then
            local d = self:GetDistanceSqr(obj:GetPosition())
            if d <= (600 * 600) then
                if self.menu:GetLocal("jg.q") and myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) and d <= (600 * 600) then
                    local pred = _G.Prediction.SDK.GetPrediction(obj, self.q, myHero:GetPosition())
                    if pred and pred.castPosition then
                        SDK.Input:Cast(SDK.Enums.SpellSlot.Q, pred.castPosition)
                    end
                end
            end
        end
    end
end

function Nilah:KillSteal()
    for i, enemy in ipairs(enemies) do
        if enemy and self:ValidTarget(enemy)then
            local hp = enemy:GetHealth()
            local d = self:GetDistanceSqr(enemy:GetPosition()) < (550 * 550)
            local e = myHero:CanUseSpell(SDK.Enums.SpellSlot.E)
            local q = myHero:CanUseSpell(SDK.Enums.SpellSlot.Q)
            local r = myHero:CanUseSpell(SDK.Enums.SpellSlot.R)
            local ed = self:eDmg(enemy)
            local qd = self:qDmg(enemy)
            local rd = self:rDmg(enemy)
            local aa = self:AADmg(enemy)
            if e and d and (ed + aa) >= hp and #self:GetEnemyHeroesInRange(550, enemy:GetPosition()) <= 2 then
                SDK.Input:Cast(SDK.Enums.SpellSlot.E, enemy)
            end
            if e and q and d and (ed + qd + aa) >= hp and #self:GetEnemyHeroesInRange(550, enemy:GetPosition()) <= 2 then
                SDK.Input:Cast(SDK.Enums.SpellSlot.E, enemy)
            end
            if e and q and r and d and (enemy:GetHealth() / (rd + qd + ed + aa)) >= 0.50 and (ed + qd + rd) >= hp and #self:GetEnemyHeroesInRange(550, enemy:GetPosition()) <= 2 then
                SDK.Input:Cast(SDK.Enums.SpellSlot.E, enemy)
            end
        end
    end
end

function Nilah:GetBestE()
    if not myHero:CanUseSpell(SDK.Enums.SpellSlot.E) then return end
    local mousePos = SDK.Renderer:GetMousePos3D()
    local origDist = self:GetDistanceSqr(mousePos)
    local minDistance = self:GetDistanceSqr(mousePos)
    local minDistObj = nil
    local enemiesInRange = self:GetTarget(550, true)
    for _, enemy in ipairs(enemiesInRange) do
        local enemyDist = self:GetDistanceSqr(enemy:GetPosition(), mousePos)
        if enemyDist < minDistance then
            minDistance = enemyDist
            minDistObj = enemy
        end
    end
    return minDistObj or nil
end

function Nilah:UnderTurret(unit)
    if not unit or unit:IsDead() or not unit:IsVisible() or not unit:IsTargetable() then
        return true
    end
    for i, objx in pairs(SDK.ObjectManager:GetEnemyTurrets()) do
        local obj = objx:AsAI()
        if obj and obj:GetHealth() and obj:GetHealth() > 0 and self:GetDistanceSqr(obj:GetPosition(), unit:GetPosition()) <= 900 ^ 2 then
            return true
        end
    end
    return false
end

function Nilah:GetBestEscape()
    if not myHero:CanUseSpell(SDK.Enums.SpellSlot.E) then return end
    local mousePos = SDK.Renderer:GetMousePos3D()
    local origDist = self:GetDistanceSqr(mousePos)
    local minDistance = self:GetDistanceSqr(mousePos)
    local minDistObj = nil
    local minionsInRange = SDK.ObjectManager:GetEnemyMinions()
    local aminionsInRange = SDK.ObjectManager:GetAllyMinions()
    for _, minionx in ipairs(minionsInRange) do
        local minion = minionx:AsAI()
        local minionDist = self:GetDistanceSqr(minion:GetPosition(), mousePos)
        if minion and minion:GetHealth() > 5 and self:GetDistanceSqr(minion:GetPosition()) <= (550 * 550) then
            if minionDist < minDistance then
                minDistance = minionDist
                minDistObj = minion
            end
        end
    end
    for _, minionx in ipairs(aminionsInRange) do
        local minion = minionx:AsAI()
        local minionDist = self:GetDistanceSqr(minion:GetPosition(), mousePos)
        if minion and self:GetDistanceSqr(minion:GetPosition()) <= (550 * 550) then
            if minionDist < minDistance then
                minDistance = minionDist
                minDistObj = minion
            end
        end
    end
    local enemiesInRange = self:GetTarget(550, true)
    for _, enemy in ipairs(enemiesInRange) do
        local enemyDist = self:GetDistanceSqr(enemy:GetPosition(), mousePos)
        if enemyDist < minDistance then
            minDistance = enemyDist
            minDistObj = enemy
        end
    end

    return minDistObj or nil
end

function Nilah:LaneClear()
    if self.menu:GetLocal("lc.q") then
        local minionsInERange = _G.CoreEx.ObjectManager.GetNearby("enemy", "minions")
        local minionsPositions = {}
        local myPos = myHero:GetPosition()
        for _, minion in ipairs(minionsInERange) do
            if minion.Position:DistanceSqr(myHero:GetPosition()) < (self.q.range * self.q.range) then
                table.insert(minionsPositions, minion.Position)
            end
        end
        local bestPos, numberOfHits = _G.CoreEx.Geometry.BestCoveringRectangle(minionsPositions, myPos, self.q.width * 2)
        if _G.Libs.Orbwalker.IsFastClearEnabled() then
            if numberOfHits >= self.menu:GetLocal("lc.qx") then
                if Player.ManaPercent * 100 >= self.menu:GetLocal("lc.qm") then
                    if SDK.Input:Cast(SDK.Enums.SpellSlot.Q, bestPos) then
                        return
                    end
                end
            end
        end
    end
end

function Nilah:CastQ(pred, tag)
    if pred.rates[self:GetCastRate(tag)] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.Q, pred.castPosition)
        pred:Draw()
        return true
    end
end

function Nilah:CastR(pred, tag)
    if pred.rates[self:GetCastRate(tag)] then
        SDK.Input:Cast(SDK.Enums.SpellSlot.R, pred.castPosition)
        return true
    end
end

function Nilah:OnTick()
    local ComboMode = _G.Libs.Orbwalker.GetMode() == "Combo"
    local HarassMode = _G.Libs.Orbwalker.GetMode() == "Harass"
    local WaveclearMode = _G.Libs.Orbwalker.GetMode() == "Waveclear"

    if myHero:CanUseSpell(SDK.Enums.SpellSlot.Q) then
        local q_targets, q_preds = self.TS:GetTargets(self.q, myHero:GetPosition())
        local q_ks, q_ks_pred = self.TS:GetTargets(self.q, myHero:GetPosition(), function(enemy) return self:qDmg(enemy) >= enemy:GetHealth() end)
        if (ComboMode and self.menu:GetLocal("combo.q")) then
            local target = q_targets[1]
            if target then
                local pred = q_preds[target:GetNetworkId()]
                if pred and self:CastQ(pred, "qc") then
                    return
                end
            end
        end
        if self.menu:GetLocal("auto.uqks") then
            local target = q_ks[1]
            if target then
                local pred = q_ks_pred[target:GetNetworkId()]
                if pred and self:CastQ(pred, "qc") then
                    return
                end
            end
        end
        if HarassMode and self.menu:GetLocal("harass.q") and not _G.Libs.Orbwalker.HasTurretTargetting(myHero) and (((myHero:GetMana() / myHero:GetMaxMana()) * 100) >= self.menu:GetLocal("harass.mana")) then
            local target = q_targets[1]
            if target then
                if self.menu:GetLocal("harass.tc") and not self:UnderTurret(myHero) then
                    local pred = q_preds[target:GetNetworkId()]
                    if pred and self:CastQ(pred, "qh") then
                        return
                    end
                elseif not self.menu:GetLocal("harass.tc") then
                    local pred = q_preds[target:GetNetworkId()]
                    if pred and self:CastQ(pred, "qh") then
                        return
                    end
                end
            end
        end
        if WaveclearMode then
            self:LaneClear()
        end
    end
    if myHero:CanUseSpell(SDK.Enums.SpellSlot.R) then
        local r_targets, r_preds = self.TS:GetTargets(self.r, myHero:GetPosition())
        local r_ks, r_ks_pred = self.TS:GetTargets(self.r, myHero:GetPosition(), function(enemy) return (enemy:GetHealth() / self:rDmg(enemy)) >= 0.50 and self:rDmg(enemy) >= enemy:GetHealth() end)
        if self.menu:GetLocal("auto.urks") then
            local target = r_ks[1]
            if target then
                local pred = r_ks_pred[target:GetNetworkId()]
                if pred and self:CastR(pred, "r") then
                    return
                end
            end
        end
        if (ComboMode and self.menu:GetLocal("combo.r")) then
            for i, enemy in ipairs(enemies) do
                if self:ValidTarget(enemy) then
                    local pred = _G.Prediction.SDK.GetPrediction(enemy, self.r, myHero:GetPosition())
                    if pred and pred.castPosition and self:GetDistanceSqr(pred.castPosition) <= (450 * 450) then
                        if #self:GetEnemyHeroesInRange(420) >= self.menu:GetLocal("combo.rx") then
                            SDK.Input:Cast(SDK.Enums.SpellSlot.R, pred.castPosition)
                        end
                    end
                end
            end
        end
    end
    if WaveclearMode then self:JungleClear() end
    if self.menu:GetLocal("Key.stack") and myHero:GetSpell(SDK.Enums.SpellSlot.E):GetAmmo() == 2 then 
        if self.menu:GetLocal("Key.e") then
            local bestPos = self:GetBestE()
            if bestPos and SDK.Input:Cast(SDK.Enums.SpellSlot.E, bestPos) then
                return
            end
        end
        if self.menu:GetLocal("Key.s") then
            local bestPos = self:GetBestEscape()
            if bestPos and SDK.Input:Cast(SDK.Enums.SpellSlot.E, bestPos) then
                return
            end
        end
    end
    if not self.menu:GetLocal("Key.stack") then
        if self.menu:GetLocal("Key.e") then
            local bestPos = self:GetBestE()
            if bestPos and SDK.Input:Cast(SDK.Enums.SpellSlot.E, bestPos) then
                return
            end
        end
        if self.menu:GetLocal("Key.s") then
            local bestPos = self:GetBestEscape()
            if bestPos and SDK.Input:Cast(SDK.Enums.SpellSlot.E, bestPos) then
                return
            end
        end
    end
    if self.menu:GetLocal("auto.ueks") then self:KillSteal() end
end


local get_d3d_color = SDK.Libs.Color.GetD3DColor
function Nilah:Hex(a, r, g, b)
    return get_d3d_color(a, r, g, b)
end

function Nilah:GetTarget(dist, all)
    local res = self.TS:update(function(unit) return _G.Prediction.SDK.IsValidTarget(unit, dist) end)
    if all then
        return res
    else
        if res and res[1] then
            return res[1]
        end
    end
end

if myHero:GetCharacterName() == "Nilah" then
    Nilah:__init()
end
