if Player.CharName ~= "Jinx" then return end

module("Unruly Jinx", package.seeall, log.setup)
clean.module("Unruly Jinx", clean.seeall, log.setup)

local _VER, _LASTMOD = "1.0.4", "04-Jan-2021"
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyJinx.lua", _VER)

local huge, min, max, abs, insert = math.huge, math.min, math.max, math.abs, table.insert

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Jinx = {}
Jinx.MobsToSteal = {}
Jinx.CacheHealth = 0
Jinx.CacheTime = 0
Jinx.LastCastW = 0

local spells = {
    Q = Spell.Active({
        Slot = Enums.SpellSlots.Q,
        Range = 825,
        Range2 = 625
    }),
    W = Spell.Skillshot({
        Slot = Enums.SpellSlots.W,
        Range = 1500,
        Delay = 0.6,
        Speed = 3300,
        Radius = 60,
        Type = "Linear",
        Collisions = {Minions=true, WindWall=true},
        UseHitbox = true
    }),
    E = Spell.Skillshot({
        Slot = Enums.SpellSlots.E,
        Range = 920,
        Delay = 1.2,
        Speed = 1750,
        Radius = 120,
        Type = "Circular",
        Collisions = {WindWall=true},
        IsTrap = true,
    }),
    R = Spell.Skillshot({
        Slot = Enums.SpellSlots.R,
        Range = 3000,
        Delay = 0.6,
        Speed = 1700,
        Speed2 = 2200,
        Radius = 140,
        Type = "Linear",
        Collisions = {Heroes=true, WindWall=true},
    }),
}

local function IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell, true) and spells[spell]:IsReady()
end

local function HasBuffOfType(targ, type)
    for k, buff in pairs(targ.Buffs) do
        if buff.BuffType == type then
            return buff
        end
    end
end

local function CountInRange(pos, range, team)
    pos = pos.Position or pos
    local res = 0
    for k, v in pairs(ObjManager.Get(team, "heroes")) do
        if v.IsTargetable and v:Distance(pos) <= range then
            res = res + 1
        end
    end
    return res
end
local CountAlliesInRange  = function(pos, range) return CountInRange(pos, range, "ally") end
local CountEnemiesInRange = function(pos, range) return CountInRange(pos, range, "enemy") end

local function IsUnderTurret(pos)
    pos = pos.Position or pos

    for _, turret in pairs(ObjManager.Get("enemy", "turrets")) do
        if not turret.IsDead and pos:Distance(turret.Position) <= 900 then
            return true
        end
    end
    return false
end

function Jinx.IsFishBones()
    return Player:GetBuff("JinxQ")
end
function Jinx.GetExtraRangeQ()
    return ({100, 125, 150, 175, 200})[spells.Q:GetLevel()] or 0
end
function Jinx.GetRealPowPowRange(target) return spells.Q.Range2 end
function Jinx.GetRealRocketRange(target) return Jinx.GetRealPowPowRange() + Jinx.GetExtraRangeQ() end
function Jinx.GetUltTravelTime(targetpos)
    local distance = Player:Distance(targetpos)
    local distSpeed1 = min(1350, distance)
    local distSpeed2 = distance - distSpeed1
    return spells.R.Delay + (distSpeed1 / spells.R.Speed) + (distSpeed2 / spells.R.Speed2)
end
function Jinx.SetMana()
    if Player.HealthPercent < 0.2 then
        Jinx.QMANA = 0
        Jinx.WMANA = 0
        Jinx.EMANA = 0
        Jinx.RMANA = 0
    else
        Jinx.QMANA = 10
        Jinx.WMANA = spells.W:GetManaCost()
        Jinx.EMANA = spells.E:GetManaCost()

        local manaForSecondW = Jinx.WMANA - Player.ManaRegen * Player:GetSpell(Enums.SpellSlots.W).TotalCooldown
        Jinx.RMANA = (spells.R:IsReady() and spells.R:GetManaCost()) or manaForSecondW
    end
end

function Jinx.OnExtremePriority()
    Jinx.Auto()
end
function Jinx.OnNormalPriority(lagfree)
    if not Game.CanSendInput() then return end

    if lagfree == 1 then
        Jinx.SetMana()
        spells.Q.Range = Jinx.GetRealRocketRange()
    end

    local ModeToExecute = Jinx[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute(lagfree)
    end
end

function Jinx.ComboLogic(mode, lagfree)
    if IsEnabledAndReady("E", mode) then
        if Player.Mana > (Jinx.RMANA + Jinx.WMANA + Jinx.EMANA) then
            if spells.E:CastIfWillHit(2, "heroes") then
                return
            end

            local pPos = Player.Position
            for k, v in ipairs(spells.E:GetTargets()) do
                if v:IsFacingAway(pPos) or HasBuffOfType(v, Enums.BuffTypes.Slow) then
                    if spells.E:CastOnHitChance(v, Menu.Get(mode..".ChanceE")) then
                        return
                    end
                elseif v.IsMelee and v:IsFacing(pPos) and v:Distance(pPos) < 400 then
                    if spells.E:Cast(pPos) then
                        return
                    end
                end
            end
        end
    end

    if IsEnabledAndReady("Q", mode) and not Orbwalker.IsWindingUp() then
        if Jinx.IsFishBones() then
            if Player.Mana < (Jinx.RMANA + Jinx.WMANA + 20) and spells.Q:Cast() then
                return
            end
        else
            local targRocket = TS:GetTarget(Jinx.GetRealRocketRange(), true, nil, true)
            if targRocket then
                local targAA = TS:GetTarget(-1, true, nil, true)
                if not targAA or CountEnemiesInRange(targRocket, 250) > 2 then
                    local minMana = Jinx.RMANA + Jinx.WMANA + ((mode == "Combo" and 10) or (Jinx.EMANA + 20))
                    if Player.Mana > minMana or Orbwalker.GetAutoAttackDamage(targRocket) * 3.3 > targRocket.Health then
                        if spells.Q:Cast() then
                            return
                        end
                    end
                end
            end

            if mode == "Harass" and Jinx.FarmOutOfRange() then
                return
            end
        end
    end
    if IsEnabledAndReady("W", mode) and Orbwalker.CanCast() then
        local wTargs = spells.W:GetTargets()
        if #wTargs == 0 then return end

        local pPos, rocketRange = Player.Position, Jinx.GetRealRocketRange()
        local rIsReady = IsEnabledAndReady("R", mode) and Player.Mana > (Jinx.RMANA + Jinx.WMANA)
        for k, v in ipairs(wTargs) do
            if v:Distance(pPos) > rocketRange then
                local comboDmg = spells.W:GetDamage(v) + (rIsReady and spells.R:GetDamage(v) or 0)
                if comboDmg > spells.W:GetKillstealHealth(v) then
                    if spells.W:CastOnHitChance(v, Enums.HitChance.VeryHigh) then
                        return
                    end
                end
            end
        end

        if not Menu.Get("Misc.OutRangeW") or CountEnemiesInRange(pPos, Jinx.GetRealPowPowRange()) == 0 then
            local minMana = Jinx.RMANA + Jinx.WMANA + ((mode == "Combo" and 10) or (Jinx.WMANA * 2 + 40))
            if Player.Mana > minMana then
                for k, v in ipairs(wTargs) do
                    if spells.W:CastOnHitChance(v, Menu.Get(mode..".ChanceW")) then
                        return
                    end
                end
            end
        end
    end
    if IsEnabledAndReady("R", mode) then
        if Game.GetTime() - Jinx.LastCastW < 1 then return end

        local pPos, minRange = Player.Position, Jinx.GetRealRocketRange() + 200
        for k, v in ipairs(spells.R:GetTargets()) do
            local dist = v:Distance(pPos)
            if dist > minRange and spells.R:CanKillTarget(v) then
                local multiHit = CountEnemiesInRange(v, 400) > 2
                local snipeTarget = dist > minRange + 200 and CountAlliesInRange(v, 500) == 0 and CountEnemiesInRange(Player, 400) == 0
                if (snipeTarget or multiHit) and spells.R:CastOnHitChance(v, Enums.HitChance.VeryHigh) then
                    return
                end
            end
        end
    end
end

function Jinx.Auto()
    local baron, dragon, force = Menu.Get("Misc.BaronR"), Menu.Get("Misc.DragonR"), Menu.Get("Misc.ForceR")
    if not (spells.R:IsReady() and (baron or dragon or force)) then return end

    if force then
        for k, v in pairs(spells.R:GetTargets()) do
            if spells.R:CastOnHitChance(v, Enums.HitChance.High) then
                return
            end
        end
    else
        local time = Game.GetTime()
        local pPos = Player.Position
        for k, v in pairs(Jinx.MobsToSteal) do
            local ePos, eHealth = v.Position, v.Health
            local isValid = v.IsTargetable and ((dragon and v.IsDragon) or (baron and v.IsBaron))
            local shouldSteal = isValid and ePos:Distance(pPos) > 1000 and CountAlliesInRange(ePos, 1000) == 0 and eHealth < v.MaxHealth
            if shouldSteal then
                if Jinx.CacheHealth == 0 then
                    Jinx.CacheHealth = eHealth
                end

                if time - Jinx.CacheTime > 4 then
                    if Jinx.CacheHealth - eHealth > 0 then
                        Jinx.CacheHealth = eHealth
                    end
                    Jinx.CacheTime = time
                else
                    local dmgSec = (Jinx.CacheHealth - eHealth) * (abs(Jinx.CacheTime - time)/4)
                    if (Jinx.CacheHealth - eHealth >= 0) then
                        local killTime = (eHealth - spells.R:GetDamage(v)) / (dmgSec / 4)
                        if Jinx.GetUltTravelTime(ePos) > killTime then
                            spells.R:Cast(ePos)
                            return
                        end
                    else
                        Jinx.CacheHealth = eHealth
                    end
                end
            end
        end
    end
end
function Jinx.Combo(lagfree)  Jinx.ComboLogic("Combo", lagfree)  end
function Jinx.Harass(lagfree) Jinx.ComboLogic("Harass", lagfree) end
function Jinx.Waveclear(lagfree)
    if Jinx.FarmOutOfRange() then
        return
    end

    if Orbwalker.CanMove() then
        local fastPush = Orbwalker.IsFastClearEnabled()
        if Jinx.IsFishBones() then
            local lastTarg = Orbwalker.GetLastTarget()
            if not (fastPush and Menu.Get("Clear.PushQ")) and not (lastTarg and Menu.Get("Clear.JungleQ") and lastTarg.IsMonster) then
                spells.Q:Cast()
                return
            end
        elseif fastPush then
            local minions = 0
            for k, v in ipairs(ObjManager.GetNearby("enemy", "minions")) do
                if TS:IsValidAutoRange(v) then
                    minions = minions + 1
                    if minions > 2 and spells.Q:Cast() then
                        return
                    end
                end
            end
        end

        local jgUseW = spells.W:IsReady() and Menu.Get("Clear.JungleW") and Orbwalker.GetMode() == "Waveclear"
        if jgUseW then
            local monsters = {}
            local mousePos = Renderer.GetMousePos()
            for k, target in ipairs(ObjManager.GetNearby("neutral", "minions")) do
                local tPos = target.Position
                if tPos:Distance(mousePos) < 600 and spells.W:IsInRange(tPos) and target.IsTargetable then
                    if target.Health > 2*Orbwalker.GetAutoAttackDamage(target) then
                        insert(monsters, target)
                    end
                end
            end

            if #monsters > 0 then
                table.sort(monsters, function(a, b) return a.MaxHealth > b.MaxHealth end)
                spells.W:Cast(monsters[1]:FastPrediction(spells.W.Delay*1000))
            end
        end
    end
end
function Jinx.Lasthit()
    if Jinx.FarmOutOfRange() then
        return
    end
end

function Jinx.FarmOutOfRange()
    if Jinx.IsFishBones() or not (spells.Q:IsReady() and Menu.Get("Clear.FarmQ")) then return end
    if Orbwalker.IsWindingUp() or not Orbwalker.CanAttack() then return end

    local pPos, atkCastDelay = Player.Position, Player.AttackCastDelay
    local aaRange, rocketRange = TS:GetTrueAutoAttackRange(Player), Jinx.GetRealRocketRange()
    for k, v in ipairs(ObjManager.GetNearby("enemy", "minions")) do
        local dist = v:Distance(pPos)
        if dist > aaRange and TS:IsValidTarget(v, rocketRange) then
            local flightTime = atkCastDelay + dist/Player.AttackData.MissileSpeed
            local hpPred = HealthPred.GetHealthPrediction(v, flightTime, false)
            if hpPred > 0 and hpPred < Orbwalker.GetAutoAttackDamage(v) * 1.1 and spells.Q:Cast() then
                return true
            end
        end
    end
end

function Jinx.OnGapclose(source, dash)
    if not (source.IsEnemy and Menu.Get("Misc.GapE") and spells.E:IsReady()) then return end

    local paths  = dash:GetPaths()
    local endPos = paths[#paths].EndPos
    local pPos  = Player.Position
    local pDist = pPos:Distance(endPos)

    if pDist < 500 and pDist < pPos:Distance(dash.StartPos) and source:IsFacing(pPos) then
        if spells.E:CastOnHitChance(source, Enums.HitChance.VeryHigh) then
            return
        end
    end
end

function Jinx.OnInterruptibleSpell(Source, SpellCast, Danger, EndTime, CanMoveDuringChannel)
    if Danger < 3 or CanMoveDuringChannel or not Source.IsEnemy then return end

    if Menu.Get("Misc.IntE") and spells.E:IsReady() then
        if spells.E:CastOnHitChance(Source, Enums.HitChance.VeryHigh) then
            return
        end
    end
end

function Jinx.OnHeroImmobilized(source, endT, isStasis)
    if not source.IsEnemy or IsUnderTurret(Player) then return end

    if spells.E:IsReady() and Menu.Get("Misc.AutoE") then
        if spells.E:CastOnHitChance(source, Enums.HitChance.VeryHigh) then
            return
        end
    end
    if spells.W:IsReady() and Menu.Get("Misc.AutoW") then
        if spells.W:CastOnHitChance(source, Enums.HitChance.VeryHigh) then
            return
        end
    end
end

function Jinx.OnPreAttack(args)
    if not spells.Q:IsReady() then return end

    local targ = args.Target
    local mode = Orbwalker.GetMode()
    local fastClear = Orbwalker.IsFastClearEnabled()

    if Jinx.IsFishBones() then --[[Logic To Disable FishBones]]
        if targ.IsHero then
            local lowMana = false
            local inCloseRange = Player:Distance(targ) < Jinx.GetRealPowPowRange(targ)
            if mode == "Combo" then
                if Player.Mana < (Jinx.RMANA + 20) then
                    local aaDmg = Orbwalker.GetAutoAttackDamage(targ)
                    local health = HealthPred.GetKillstealHealth(targ, 1, Enums.DamageTypes.Physical)
                    lowMana = aaDmg * 3 < health
                end
            elseif mode == "Harass" then
                lowMana = Player.Mana < (Jinx.RMANA + Jinx.EMANA + 2*Jinx.WMANA)
            end
            if inCloseRange or lowMana then
                --[[Disable When Can Hit With PowPow or Need to Save Mana]]
                spells.Q:Cast()
                return
            end
        elseif fastClear or targ.IsMonster then
            if Player:Distance(targ) > Jinx.GetRealPowPowRange(targ) then
                return
            end
            for _, team in ipairs({"neutral", "enemy"}) do
                for k, v in ipairs(ObjManager.GetNearby(team, "minions")) do
                    if v ~= targ and v.IsTargetable and v:Distance(targ) < 300 then
                        return
                    end
                end
            end
            --[[Disable When Can Hit With PowPow And Only 1 Minion Left]]
            spells.Q:Cast()
            return
        elseif mode ~= "Combo" then
            --[[Disable When Attacking Non-Hero + Not Combo/FastClear]]
            spells.Q:Cast()
            return
        end
    else --[[Logic To Enable FishBones]]
        if (fastClear and Menu.Get("Clear.PushQ")) or (targ.IsMonster and Menu.Get("Clear.JungleQ")) then
            local rocketRange = Jinx.GetRealRocketRange()
            local validMinions = {}
            for k, v in ipairs(ObjManager.GetNearby("neutral", "minions")) do
                if TS:IsValidTarget(v, rocketRange) then insert(validMinions, v) end
            end
            for k, v in ipairs(ObjManager.GetNearby("enemy", "minions")) do
                if TS:IsValidTarget(v, rocketRange) then insert(validMinions, v) end
            end

            for k, v in ipairs(validMinions) do
                local count = 1
                local pos = v.Position
                for k2, v2 in ipairs(validMinions) do
                    if v ~= v2 and v2:Distance(pos) < 300 then
                        --[[Enable When Hit 2+]]
                        spells.Q:Cast()
                        return
                    end
                end
            end
        end
    end
end

function Jinx.OnCreateObject(obj)
    if obj.IsDragon or obj.IsBaron then
        Jinx.MobsToSteal[obj.Handle] = obj
    end
end
function Jinx.OnDeleteObject(obj)
    Jinx.MobsToSteal[obj.Handle] = nil
end
function Jinx.OnSpellCast(obj, spellcast)
    if obj.IsMe and spellcast.Slot == Enums.SpellSlots.W then
        Jinx.LastCastW = Game.GetTime()
    end
end

function Jinx.OnDraw()
    local playerPos = Player.Position
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color"))
        end
    end
end

function Jinx.LoadMenu()
    Menu.RegisterMenu("UnrulyJinx", "Unruly Jinx", function()
        Menu.ColumnLayout("cols", "cols", 3, true, function()
            Menu.ColoredText("Combo", 0xFFD700FF, true)
            Menu.Checkbox("Combo.UseQ",  "Use [Q]", true)
            Menu.Checkbox("Combo.UseW",  "Use [W]", true)
            Menu.Slider("Combo.ChanceW", "HitChance", 0.75, 0, 1, 0.01)
            Menu.Checkbox("Combo.UseE",  "Use [E]", true)
            Menu.Slider("Combo.ChanceE", "HitChance", 0.9, 0, 1, 0.01)
            Menu.Checkbox("Combo.UseR",  "Use [R]", true)

            Menu.NextColumn()

            Menu.ColoredText("Harass", 0xFFD700FF, true)
            Menu.Checkbox("Harass.UseQ",  "Use [Q]", true)
            Menu.Checkbox("Harass.UseW",  "Use [W]", true)
            Menu.Slider("Harass.ChanceW", "HitChance", 0.8, 0, 1, 0.01)
            Menu.Checkbox("Harass.UseE",  "Use [E]", false)
            Menu.Slider("Harass.ChanceE", "HitChance", 0.9, 0, 1, 0.01)

            Menu.NextColumn()

            Menu.ColoredText("Clear", 0xFFD700FF, true)
            Menu.Checkbox("Clear.FarmQ",   "Use [Q] Farm", true)
            Menu.Checkbox("Clear.PushQ",   "Use [Q] Push", true)
            Menu.Checkbox("Clear.JungleQ", "Use [Q] Jungle", true)
            Menu.Checkbox("Clear.JungleW", "Use [W] Jungle", true)
        end)

        Menu.Separator()

        Menu.ColoredText("Misc Options", 0xFFD700FF, true)
        Menu.ColumnLayout("cols2", "cols", 2, true, function()
            Menu.Checkbox("Misc.AutoW", "Auto [W] Immobile", true)
            Menu.Checkbox("Misc.AutoE", "Auto [E] Immobile", true)
            Menu.Checkbox("Misc.GapE",  "Auto [E] Gapclose", true)
            Menu.Checkbox("Misc.IntE",  "Auto [E] Interrupt", true)

            Menu.NextColumn()

            Menu.Checkbox("Misc.OutRangeW",  "Only [W] Out of Range", true)
            Menu.Checkbox("Misc.BaronR",  "Steal Baron [R]", true)
            Menu.Checkbox("Misc.DragonR", "Steal Dragon [R]", true)
            Menu.Keybind("Misc.ForceR", "Force [R] Key", string.byte('T'), nil, nil, true)
        end)

        Menu.Separator()

        Menu.ColoredText("Draw Options", 0xFFD700FF, true)
        Menu.Checkbox("Drawing.Q.Enabled",  "Draw [Q] Range")
        Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0xEF476FFF)
        Menu.Checkbox("Drawing.W.Enabled",  "Draw [W] Range")
        Menu.ColorPicker("Drawing.W.Color", "Draw [W] Color", 0x06D6A0FF)
        Menu.Checkbox("Drawing.E.Enabled",  "Draw [E] Range")
        Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x118AB2FF)
    end, {Author="Thorn", LastModified=_LASTMOD, Version=_VER})
end

function OnLoad()
    Jinx.LoadMenu()

    for k, v in pairs(ObjManager.Get("neutral", "minions")) do
        Jinx.OnCreateObject(v)
    end
    for eventName, eventId in pairs(Enums.Events) do
        if Jinx[eventName] then
            EventManager.RegisterCallback(eventId, Jinx[eventName])
        end
    end
    return true
end
