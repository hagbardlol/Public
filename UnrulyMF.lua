if Player.CharName ~= "MissFortune" then return end

module("UnrulyMF", package.seeall, log.setup)
clean.module("UnrulyMF", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyMF.lua", "1.0.5")

local insert = table.insert

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local MissFortune = {}

local spells = {
    Q = Spell.Targeted({
        Slot            = Enums.SpellSlots.Q,
        Range           = 675,
        Radius          = 80,
        Speed           = 1400, 
        Delay           = 0.25, 
        Type            = "Linear", 
        Collisions      = { WindWall = true },

        ExtraRange      = 450,
        ConeAngleRad    = 80 * math.pi / 180,
    }),
    Q_Pred = Spell.Skillshot({
        Slot            = Enums.SpellSlots.Q,
        Range           = 1100,
        Radius          = 80,
        Speed           = 1400, 
        Delay           = 0.25, 
        Type            = "Linear", 
        Collisions      = { WindWall = true },
    }),
    W = Spell.Active({
        Range           = 1000,
        Slot            = Enums.SpellSlots.W
    }),
    E = Spell.Skillshot({
        Slot            = Enums.SpellSlots.E,
        Range           = 1000,
        Radius          = 200,
        Delay           = 0.25,
        Type            = "Circular"
    }),
    R = Spell.Skillshot({
        Slot            = Enums.SpellSlots.R,
        Range           = 1350,
        ConeAngleRad    = 30 * math.pi / 180,
        Speed           = 2000,
        Delay           = 0.25,
        Type            = "Cone",
        Collisions      = { WindWall = true },
    }),
}

local function IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell) and spells[spell]:IsReady()
end

local function IsRunningTowardsOrAway(obj, pos)
    local dist = obj:Distance(pos)
    return (dist <= 600 and obj.IsMelee and obj:IsFacing(pos)) or 
           (dist >= 600 and obj:IsFacingAway(pos))
end

function MissFortune.LoadMenu()
    Menu.RegisterMenu("UnrulyMF", "Unruly MF", function ()
        Menu.ColumnLayout("cols", "cols", 4, true, function()
            Menu.NewTree("Combo Settings", "Combo Settings", function()
            Menu.Separator("Combo Settings")
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true)
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)
            Menu.Checkbox("Combo.SwitchTarget", "[Passive]", false)
        end)
        end)

            Menu.NewTree("Harass Settings", "Harass Settings", function()
            Menu.Separator("Harass Settings")
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true)
            Menu.Checkbox("Harass.UseW", "Use [W]", false)
            Menu.Checkbox("Harass.UseE", "Use [E]", true)
            Menu.Checkbox("Harass.SwitchTarget", "[Passive]", true)
        end)

            Menu.NewTree("Lane Clear Settings", "Lane Clear Settings", function()
            Menu.Separator("Lane Clear Settings")
            Menu.Checkbox("Clear.FarmQ", "Use [Q]", true)
            Menu.Separator("FastClear", 0xFFD700FF, true)
            Menu.Checkbox("Clear.PushQ", "Use [Q]", true)
            Menu.Checkbox("Clear.PushW", "Use [W]", true)
            Menu.Checkbox("Clear.PushE", "Use [E]", true)
        end)

            Menu.NewTree("Jungle Clear Settings", "Jungle Clear Settings", function()
            Menu.Separator("Jungle Clear Settings")
            Menu.Checkbox("Turret.UseW", "Use [W]", true)
            Menu.Separator("Jungle", 0xFFD700FF, true)
            Menu.Checkbox("Jungle.UseQ", "Use [Q]", true)
            Menu.Checkbox("Jungle.UseW", "Use [W]", true)
            Menu.Checkbox("Jungle.UseE", "Use [E]", false)
        end)

        Menu.ColumnLayout("cols2", "cols2", 2, true, function()
            Menu.NewTree("Drawing Options", "Drawing Options", function()
            Menu.Separator("Drawing Options")
            Menu.Checkbox("Drawing.Q.Enabled",  "Draw [Q] Range", true)
            Menu.ColorPicker("Drawing.Q.Color", "Color [Q]", 0xEF476FFF)
            Menu.Checkbox("Drawing.E.Enabled",  "Draw [E] Range", true)
            Menu.ColorPicker("Drawing.E.Color", "Color [E]", 0x118AB2FF)
            Menu.Checkbox("Drawing.R.Enabled",  "Draw [R] Range", true)
            Menu.ColorPicker("Drawing.R.Color", "Color [R]", 0xFFD166FF)
        end)

            Menu.NewTree("Misc Options", "Misc Options", function()
            Menu.Separator("Misc Options")
            Menu.Checkbox("Misc.BlockTargChange", "Dont Swap [Passive] If\nTarget Will Die Soon", true)
            Menu.Checkbox("Misc.AutoQ", "Auto [Q] Bounce Crit", true)
            Menu.Checkbox("Misc.UnkillableQ", "Auto [Q] Avoid Lose CS", true)
            Menu.Checkbox("Misc.GapE", "Use [E] Gapclose", true)
            Menu.Keybind("Misc.ForceR", "Force [R] Key", string.byte('T'), false, false, true)
        end)
            Menu.Separator("Author: Thorn")
        end)
    end)
end

function MissFortune.CanKillMinionQ(obj, dmgOnMinions)    
    local charName = obj.CharName
    if not dmgOnMinions[charName] then
        dmgOnMinions[charName] = DmgLib.GetSpellDamage(Player, obj, Enums.SpellSlots.Q, "Default")
    end
    return dmgOnMinions[charName] > obj.Health
end

function MissFortune.GetUnitsForQ(range, killableOnly)
    local playerPos = Player.Position
    local targetList = {
        ObjManager.GetNearby("enemy", "heroes"),
        ObjManager.GetNearby("enemy", "minions"),
        ObjManager.GetNearby("neutral", "minions")
    }

    local objects, dmgOnMinions = {}, {}
    for _, t in ipairs(targetList) do
        for __, obj in ipairs(t) do
            if obj.IsTargetable and obj:Distance(playerPos) < range and (not killableOnly or MissFortune.CanKillMinionQ(obj, dmgOnMinions)) then
                insert(objects, obj)
            end
        end
    end

    return objects
end

function MissFortune.HasBuffW()
    return Player:GetBuff("MissFortuneViciousStrikes")
end

function MissFortune.GetConeQ(obj)
    local p = obj.Position
    return Geometry.Cone(p, p:Extended(Player.Position, -spells.Q.ExtraRange), spells.Q.ConeAngleRad, spells.Q.ExtraRange)
end

function MissFortune.GetBounceTargetQ(unkillableOnly)    
    local targets = TS:GetTargets(spells.Q.Range + spells.Q.ExtraRange)
    if #targets < 1 then return end

    local units = MissFortune.GetUnitsForQ(spells.Q.Range, unkillableOnly)
    if #units < 1 then return end

    local cones = {}
    for _, enemy in ipairs(targets) do        
        local pred = spells.Q_Pred:GetPrediction(enemy)
        if pred and pred.HitChanceEnum >= Enums.HitChance.Low then
            local targPos = pred.TargetPosition
            for i, bounceObj in ipairs(units) do
                if not cones[i] then
                    cones[i] = MissFortune.GetConeQ(bounceObj)
                end

                local hitCone = cones[i]
                if hitCone:Contains(targPos) then
                    local otherMinionFound = false
                    for j, colObj in ipairs(units) do
                        if i~= j and hitCone:Contains(colObj.Position) then
                            otherMinionFound = true
                            break
                        end
                    end

                    if not otherMinionFound then
                        return bounceObj
                    end
                end            
            end
        end
    end
end

function MissFortune.IsUlting()
    local aS = Player.ActiveSpell
    return aS and aS.Name == "MissFortuneBulletTime"
end

function MissFortune.Auto(lagfree) 
    local mode = Orbwalker.GetMode()

    local wontCancelAA = mode == "nil" or Orbwalker.CanCast()
    if wontCancelAA and Menu.Get("Misc.AutoQ") and spells.Q:IsReady()then 
        local targ = MissFortune.GetBounceTargetQ(true)
        if targ and spells.Q:Cast(targ) then
            return true
        end
    end    
    
    local farmQ = Menu.Get("Clear.FarmQ") and (mode == "Waveclear" or mode == "Lasthit")
    if (farmQ or Menu.Get("Misc.UnkillableQ")) and spells.Q:IsReady() then
        local targs = spells.Q:GetFarmTargets(true)
        if targs[1] and spells.Q:Cast(targs[1]) then
            return true
        end
    end

    if (MissFortune.ForceR or Menu.Get("Misc.ForceR")) and spells.R:IsReady() then
        if spells.E:IsReady() and Player.Mana > (spells.E:GetManaCost() + spells.R:GetManaCost()) then
            if spells.E:CastIfWillHit(1, "heroes") then
                MissFortune.ForceR = true
                return true
            end
        else
            local targets = spells.R:GetTargets()
            local bestPos, hitCount = spells.R:GetBestConeCastPos(targets)
            if bestPos and hitCount >= 1 and spells.R:Cast(bestPos) then
                MissFortune.ForceR = false
                return true
            end
        end        
    end
end
function MissFortune.Combo(lagfree)  MissFortune.ComboLogic("Combo", lagfree)  end
function MissFortune.Harass(lagfree) MissFortune.ComboLogic("Harass", lagfree) end
function MissFortune.Waveclear(lagfree)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local lastTarg = Orbwalker.GetLastTarget()
       
    if lagfree == 2 and spells.Q:IsReady() then
        local qMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseQ")
        if qMonster and TS:IsValidAutoRange(lastTarg) then
            if spells.Q:Cast(lastTarg) then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushQ") then
            local minions = ObjManager.GetNearby("enemy", "minions")
            for i, obj in ipairs(minions) do
                if obj.IsTargetable and spells.Q:IsInRange(obj.Position) then
                    local cone = MissFortune.GetConeQ(obj)
                    for j, obj2 in ipairs(minions) do
                        if i ~= j and obj.IsTargetable and cone:Contains(obj2.Position) then
                            if spells.Q:Cast(obj) then
                                return
                            end
                        end
                    end                    
                end
            end
        end
    end        
    if lagfree == 3 and spells.E:IsReady() then  
        local eMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseE")
        if eMonster and TS:IsValidAutoRange(lastTarg) then
            if spells.E:Cast(lastTarg:FastPrediction(1000)) then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushE") then
            if spells.E:CastIfWillHit(4, "minions") then
                return
            end
        end
    end  
    if lagfree == 4 and spells.W:IsReady() and not MissFortune.HasBuffW() then        
        local wTurret = lastTarg and lastTarg.IsTurret and Menu.Get("Turret.UseW")
        local wMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseW")        
        if (wTurret or wMonster) and TS:IsValidAutoRange(lastTarg) then
            if spells.W:Cast() then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushW") then
            local minions = 0
            for k, v in ipairs(ObjManager.GetNearby("enemy", "minions")) do
                if TS:IsValidAutoRange(v) then
                    minions = minions + 1
                    if minions > 2 and spells.W:Cast() then
                        return
                    end
                end
            end
        end
    end  
end

function MissFortune.ComboLogic(mode, lagfree)   
    if lagfree == 2 and IsEnabledAndReady("Q", mode) then
        for k, qTarget in ipairs(spells.Q:GetTargets()) do
            if spells.Q:Cast(qTarget) then
                return
            end
        end

        local targ = MissFortune.GetBounceTargetQ(false)
        if targ and spells.Q:Cast(targ) then
            return
        end
    end        
    if lagfree == 3 and IsEnabledAndReady("E", mode) then
        if spells.E:CastIfWillHit(2, "heroes") then
            return
        end

        local pPos = Player.Position
        local atkRange = Orbwalker.GetTrueAutoAttackRange(Player)
        for k, obj in ipairs(spells.E:GetTargets()) do
            local dist = pPos:FastDistance(obj.Position)
            if (dist < 600 and obj.IsMelee) or (dist > atkRange * 0.75) then
                if spells.E:CastOnHitChance(obj, Enums.HitChance.Low) then
                    return
                end
            end
        end  
    end  
    if lagfree == 4 and IsEnabledAndReady("W", mode) and not MissFortune.HasBuffW() then
        local pPos = Player.Position
        for k, obj in ipairs(spells.W:GetTargets()) do
            local pos = obj.Position
            if TS:IsValidAutoRange(obj) or Player:IsFacing(pos) or Player:IsFacingAway(pos) then
                if spells.W:Cast() then
                    return
                end
            end
        end
    end  
end

function MissFortune.OnNormalPriority(lagfree)    
    if not Game.CanSendInput() or MissFortune.IsUlting() then return end 

    if MissFortune.Auto(lagfree) then return end
    if not Orbwalker.CanCast() then return end

    local ModeToExecute = MissFortune[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute(lagfree)
    end
end

function MissFortune.OnGapclose(Source, DashInstance)
    if Source.IsAlly or not (Menu.Get("Misc.GapE") and spells.E:CanCast(Source)) then 
        return
    end
    
    if IsRunningTowardsOrAway(Source, Player.Position) then
        if spells.E:CastOnHitChance(Source, Enums.HitChance.Low) then
            return
        end
    end
end

function MissFortune.OnSpellCast(obj, spellcast)
    if not obj.IsMe then
        return
    end
    
    if (spellcast.IsBasicAttack or spellcast.Slot == Enums.SpellSlots.Q) then
        MissFortune.LastPassiveTarg = spellcast.Target
    end
end

function MissFortune.OnPreAttack(args)
    local mode = Orbwalker.GetMode()
    if Menu.Get(mode..".SwitchTarget", true) then
        local curTarg = args.Target
        local lastTarget = MissFortune.LastPassiveTarg
        if not lastTarget or lastTarget ~= curTarg then return end
        
        if Menu.Get("Misc.BlockTargChange") and curTarg.Health < 3 * Orbwalker.GetAutoAttackDamage(curTarg)then
            return
        end

        for _, target in ipairs(TS:GetTargets(-1, true, nil, true)) do
            if target ~= lastTarget then
                args.Target = target
                return
            end
        end
    end
end

function MissFortune.OnDraw()
    local playerPos = Player.Position    
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

-- Load Script
local function Init()
    MissFortune.LoadMenu()

    for EventName, EventId in pairs(Enums.Events) do
        if MissFortune[EventName] then
            EventManager.RegisterCallback(EventId, MissFortune[EventName])
        end
    end
    return true
end
Init()
