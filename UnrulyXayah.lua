if Player.CharName ~= "Xayah" then return end

module("UnrulyXayah", package.seeall, log.setup)
clean.module("UnrulyXayah", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://github.com/hagbardlol/Public/raw/main/UnrulyXayah.lua", "1.0.3")

local insert = table.insert
local max, min = math.max, math.min

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Xayah = {}
Xayah.FeatherList = {}

local spells = {
    Q = Spell.Skillshot({
        Slot            = Enums.SpellSlots.Q,
        Range           = 1100,
        Speed           = 4000,
        Radius          = 60,
        Delay           = 0.25,
        Type            = "Linear",
        Collisions      = { WindWall = true },
    }),
    W = Spell.Active({
        Slot            = Enums.SpellSlots.W
    }),
    E = Spell.Active({
        Slot            = Enums.SpellSlots.E
    }),
    E_Pred = Spell.Skillshot({
        Slot            = Enums.SpellSlots.E,
        Range           = 25000,
        Speed           = math.huge,
        Radius          = 60,
        Delay           = 0,
        Type            = "Linear",
        Collisions      = { WindWall = true },
    }),
    R = Spell.Skillshot({
        Slot            = Enums.SpellSlots.R,
        Range           = 1100,
        Delay           = 1,
        Type            = "Cone",
        ConeAngleRad    = 60 * math.pi / 180,
    })
}

local function IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell, true) and spells[spell]:IsReady()
end

local function IsSpellShielded(target)
    return _G.CoreEx.EvadeAPI.IsSpellShielded(target)
end

function Xayah.HasActiveW()
    return Player:GetBuff("XayahW")
end
function Xayah.GetPassiveCount()
    return Player:GetBuffCount("XayahPassiveActive")
end
function Xayah.CountHits(target)
    local pred = spells.E_Pred:GetPrediction(target)
    if not target.IsMinion and (not pred or pred.HitChanceEnum < Enums.HitChance.High) then return 0 end
    
    local count = 0
    local pPos, tPos = Player.ServerPos, (target.IsMinion and target.ServerPos) or pred.TargetPosition
    local hitRadius = target.BoundingRadius + spells.E_Pred.Radius
    for k, v in pairs(Xayah.FeatherList) do
        if tPos:LineDistance(pPos, v.Position) <= hitRadius then
            count = count + 1
        end
    end
    return count
end
function Xayah.FeatherDamage(isMinionTarget)
    local eLvl = spells.E:GetLevel()
    local rawDmg = 45 + (10 * eLvl) + (0.6 * Player.BonusAD)
    return rawDmg * (1 + 0.5 * Player.CritChance) * (isMinionTarget and 0.5 or 1)    
end

function Xayah.LoadMenu()
    Menu.RegisterMenu("UnrulyXayah", "Unruly Xayah", function ()
        Menu.ColumnLayout("cols", "cols", 4, true, function()
            Menu.ColoredText("Combo", 0xFFD700FF, true)
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true) 
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)  
            Menu.Indent(function()
                Menu.Checkbox("Combo.RootE", "Root", true)  
                Menu.Checkbox("Combo.KillE", "Kill", true)   
            end)
            Menu.Checkbox("Combo.UseR", "Use [R]", true)
            Menu.Indent(function()
                Menu.Slider("Combo.MinHitR", "Min Hit", 2, 2, 5)  
            end)

            Menu.NextColumn()

            Menu.ColoredText("Harass", 0xFFD700FF, true)
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true) 
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
            Menu.Checkbox("Harass.UseE", "Use [E]", true)
            Menu.Indent(function()
                Menu.Checkbox("Harass.RootE", "Root", true)  
                Menu.Checkbox("Harass.KillE", "Kill", true) 
                Menu.Slider("Harass.MinHitE", "Feathers", 3, 1, 10)  
            end)

            Menu.NextColumn()

            Menu.ColoredText("FastClear", 0xFFD700FF, true)
            Menu.Checkbox("Clear.PushQ",   "Use [Q]", true)          
            Menu.Checkbox("Clear.PushW",   "Use [W]", true)
            Menu.Checkbox("Clear.PushE",   "Use [E]", true)         
            
            Menu.ColoredText("Jungle", 0xFFD700FF, true)
            Menu.Checkbox("Jungle.UseQ",   "Use [Q]", true)       
            Menu.Checkbox("Jungle.UseW",   "Use [W]", true)     
            Menu.Checkbox("Jungle.UseE",   "Use [E]", true) 
        end)    

        Menu.Separator()

        Menu.NewTree("DrawTree", "Drawing Settings", function()
            Menu.Checkbox("Drawing.Q.Enabled",  "Draw [Q] Range", true)
            Menu.ColorPicker("Drawing.Q.Color", "Color [Q]", 0xEF476FFF) 
            Menu.Checkbox("Drawing.R.Enabled",  "Draw [R] Range", true) 
            Menu.ColorPicker("Drawing.R.Color", "Color [R]", 0xFFD166FF)
        end)
    end)
end

function Xayah.Combo(lagfree)  Xayah.ComboLogic("Combo", lagfree)  end
function Xayah.Harass(lagfree) Xayah.ComboLogic("Harass", lagfree) end
function Xayah.Waveclear(lagfree)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local lastTarg = Orbwalker.GetLastTarget()
    local waitPassive = Xayah.GetPassiveCount() > 2
       
    if lagfree == 1 and spells.W:IsReady() then
        local wMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseW")
        if wMonster and TS:IsValidTarget(lastTarg, spells.W.Range) then
            if spells.W:Cast() then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushW") and not waitPassive then
            local count = 0
            for i, obj in ipairs(ObjManager.GetNearby("enemy", "minions")) do
                if TS:IsValidTarget(obj, spells.W.Range) then
                    count = count + 1
                    if count >= 3 and spells.W:Cast() then
                        return
                    end
                end
            end
        end
    end
    if lagfree == 2 and spells.Q:IsReady() then
        local qMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseQ")
        if qMonster and TS:IsValidAutoRange(lastTarg) then
            if spells.Q:Cast(lastTarg.Position) then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushQ") then
            if spells.Q:CastIfWillHit(3, "minions") then
                return
            end
        end
    end
    
    if lagfree == 3 and spells.E:IsReady() then
        local eMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseE")
        if eMonster and TS:IsValidAutoRange(lastTarg) then
            local shouldWait = (spells.Q:IsReady() and Menu.Get("Jungle.UseQ")) or (spells.W:IsReady() and Menu.Get("Jungle.UseW")) or Xayah.GetPassiveCount() > 0
            local canKill = shouldWait and Xayah.CountHits(lastTarg) * Xayah.FeatherDamage(false) > lastTarg.Health
            if ((not shouldWait and Xayah.CountHits(lastTarg) > 0) or canKill) and spells.E:Cast() then                
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushE") then
            local killableMinions = 0
            local dmgPerFeather = Xayah.FeatherDamage(true)
            for k, minion in ipairs(ObjManager.GetNearby("enemy", "minions")) do
                if TS:IsValidTarget(minion) and dmgPerFeather * Xayah.CountHits(minion) >= minion.Health then 
                    killableMinions = killableMinions + 1
                    if killableMinions >= 3 and spells.E:Cast() then
                        return
                    end
                end
            end
        end
    end 
end

function Xayah.ComboLogic(mode, lagfree) 
    if IsEnabledAndReady("E", mode) then
        local eTargets, hits, totCount = spells.E:GetTargets(), {}, 0
        for k, targ in ipairs(eTargets) do
            if not hits[k] then
                hits[k] = Xayah.CountHits(targ)
            end
            totCount = totCount + hits[k]
        end

        local minHit = Menu.Get(mode..".MinHitE", true)
        if minHit and totCount >= minHit and spells.E:Cast() then  
            return
        end

        if Menu.Get(mode..".RootE", true) then
            for k, count in pairs(hits) do
                local targ = eTargets[k]
                if count >= 3 and not IsSpellShielded(targ) and spells.E:Cast() then
                    return
                end
            end
        end
        if Menu.Get(mode..".KillE", true) then
            local dmgPerFeather = Xayah.FeatherDamage(false)
            for k, count in pairs(hits) do
                local targ = eTargets[k]
                local eDmg = DmgLib.CalculatePhysicalDamage(Player, targ, count * dmgPerFeather)
                if eDmg >= spells.E_Pred:GetKillstealHealth(targ) and spells.E:Cast() then
                    return
                end
            end
        end
    end 

    local waitPassive = Xayah.GetPassiveCount() > 2
    if lagfree == 1 and IsEnabledAndReady("Q", mode) and not Xayah.HasActiveW() and not waitPassive then
        local qTarget = spells.Q:GetTarget()
        if qTarget and spells.Q:CastOnHitChance(qTarget, Enums.HitChance.High) then
            return
        end    
    end   
    if lagfree == 2 and IsEnabledAndReady("W", mode) and not waitPassive then
        for k, v in ipairs(ObjManager.GetNearby("enemy", "heroes")) do
            if TS:IsValidAutoRange(v) and spells.W:Cast() then
                return
            end
        end
    end     
    if lagfree == 4 and IsEnabledAndReady("R", mode) and not Xayah.HasActiveW() then
        local minHit = Menu.Get(mode..".MinHitR", true)
        if spells.R:CastIfWillHit(minHit, "heroes") then
            return
        end
    end
end

function Xayah.OnCreateObject(obj)
    if obj.IsParticle and obj.Name == "Xayah_Base_Passive_Dagger_indicator8s" then
        Xayah.FeatherList[obj.Handle] = {Position=obj.Position, EndTime=Game.GetTime()+6}
    end
end
function Xayah.OnDeleteObject(obj)
    Xayah.FeatherList[obj.Handle] = nil
end
function Xayah.OnSpellCast(obj, spell)
    if not obj.IsMe then return end

    local slot = spell.Slot
    if slot == Enums.SpellSlots.E then
        Xayah.FeatherList = {}
    elseif slot == Enums.SpellSlots.Q and IsEnabledAndReady("W", Orbwalker.GetMode()) then
        for k, v in ipairs(ObjManager.GetNearby("enemy", "heroes")) do
            if TS:IsValidAutoRange(v) and spells.W:Cast() then
                return
            end
        end
    end
end
function Xayah.OnPreAttack(args)
    if Xayah.GetPassiveCount() > 2 then
        return 
    end

    local targ = args.Target
    local mode = Orbwalker.GetMode()
    if targ.IsHero and IsEnabledAndReady("W", mode) then
        spells.W:Cast()
    elseif targ.IsMinion or targ.IsStructure then
        local fastClear = Orbwalker.IsFastClearEnabled() and Menu.Get("Clear.PushW")
        local jungleClear = targ.IsMonster and Menu.Get("Jungle.UseW")
        if fastClear or jungleClear then
            spells.W:Cast()
        end
    end
end

function Xayah.OnNormalPriority(lagfree) 
    if not Game.CanSendInput() then return end   

    local curTime = Game.GetTime()
    for handle, data in pairs(Xayah.FeatherList) do
        if data.EndTime < curTime then
            Xayah.FeatherList[handle] = nil
        end
    end     
    
    if not Orbwalker.CanCast() then return end
    local ModeToExecute = Xayah[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute(lagfree)
    end
end

function Xayah.OnDraw()  
    local playerPos = Player.Position    
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

local function Init() 
    Xayah.LoadMenu()
    
    for EventName, EventId in pairs(Enums.Events) do
        if Xayah[EventName] then
            EventManager.RegisterCallback(EventId, Xayah[EventName])
        end
    end
    return true
end
Init()