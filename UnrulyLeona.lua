if Player.CharName ~= "Leona" then return end

module("UnrulyLeona", package.seeall, log.setup)
clean.module("UnrulyLeona", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyLeona.lua", "1.0.5")

local insert = table.insert
local max, min = math.max, math.min

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Leona = {}

local spells = {
    Q = Spell.Active({
        Slot            = Enums.SpellSlots.Q,
        Range           = 225
    }),
    W = Spell.Active({
        Slot            = Enums.SpellSlots.W,
        Range           = 450
    }),
    E = Spell.Skillshot({
        Slot            = Enums.SpellSlots.E,
        Range           = 900,
        Speed           = 2000,
        Radius          = 70,
        Delay           = 0.25,
        Type            = "Linear"
    }),
    R = Spell.Skillshot({
        Slot            = Enums.SpellSlots.R,
        Range           = 1200,
        Radius          = 350,
        EffectRadius    = 200,
        Delay           = 1,
        Type            = "Circular"
    })
}

local function IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell, true) and spells[spell]:IsReady()
end

local function IsRunningTowardsOrAway(obj, pos)
    local dist = obj:Distance(pos)
    return (dist <= 600 and obj.IsMelee and obj:IsFacing(pos)) or 
           (dist >= 600 and obj:IsFacingAway(pos))
end

local function IsSpellShielded(target)
    return _G.CoreEx.EvadeAPI.IsSpellShielded(target)
end

function Leona.LoadMenu()
    Menu.RegisterMenu("UnrulyLeona", "Unruly Leona", function ()
        Menu.ColumnLayout("cols", "cols", 4, true, function()
            Menu.NewTree("Combo Settings", "Combo Settings", function()
            Menu.Separator("Combo Settings")
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true)
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)
            Menu.Checkbox("Combo.UseR", "Use [R]", true)
            Menu.Indent(function()
                Menu.Checkbox("ComboR.Duel", "Whitelist", true)
                Menu.Slider("ComboR.MinHit", "Min Hit", 3, 2, 5)
        end)
        end)

            Menu.NewTree("Harass Settings", "Harass Settings", function()
            Menu.Separator("Harass Settings")
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true)
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
            Menu.Checkbox("Harass.UseE", "Use [E]", false)
        end)

            Menu.NewTree("Lane Clear Settings", "Lane Clear Settings", function()
            Menu.Separator("Lane Clear Settings")
            Menu.Checkbox("Clear.PushQ", "Use [Q]", true)
            Menu.Checkbox("Clear.PushW", "Use [W]", true)
            Menu.Checkbox("Clear.PushE", "Use [E]", true)
        end)
            
            Menu.NewTree("Jungle Clear Settings", "Jungle Clear Settings", function()
            Menu.Separator("Jungle Clear Settings")
            Menu.Checkbox("Jungle.UseQ",   "Use [Q]", true)
            Menu.Checkbox("Jungle.UseW",   "Use [W]", true)
        end)

            Menu.NewTree("Misc Options", "Misc Options", function()
            Menu.Separator("Misc Options")
            Menu.Checkbox("Misc.GapE", "[E] AntiGap", true)
            Menu.Checkbox("Misc.IntE", "[E] Interrupt", true)
            Menu.Checkbox("Misc.GapR", "[R] AntiGap", true)
            Menu.Checkbox("Misc.IntR", "[R] Interrupt", true)
        end)
            --Menu.Separator("Whitelist [R]")
            --local added = {}
            --for k, v in pairs(ObjManager.Get("enemy", "heroes")) do
                --local charName = v.CharName
                --if not added[charName] then
                    --added[charName] = true
                    --Menu.Checkbox("ComboR.Duel." .. charName, charName, TS:GetPriority(v) >= 2)
                --end
            --end
        end)

        Menu.NewTree("DrawTree", "Drawing Settings", function()
            Menu.Checkbox("Drawing.Q.Enabled",  "Draw [Q] Range", false)
            Menu.ColorPicker("Drawing.Q.Color", "Color [Q]", 0xEF476FFF)
            Menu.Checkbox("Drawing.W.Enabled",  "Draw [W] Range", true)
            Menu.ColorPicker("Drawing.W.Color", "Color [W]", 0x118AB2FF)
            Menu.Checkbox("Drawing.E.Enabled",  "Draw [E] Range", true)
            Menu.ColorPicker("Drawing.E.Color", "Color [E]", 0x118AB2FF)
            Menu.Checkbox("Drawing.R.Enabled",  "Draw [R] Range", true)
            Menu.ColorPicker("Drawing.R.Color", "Color [R]", 0xFFD166FF)
        end)
            Menu.Separator("Author: Thorn")
    end)
end

function Leona.Combo(lagfree)  Leona.ComboLogic("Combo", lagfree)  end
function Leona.Harass(lagfree) Leona.ComboLogic("Harass", lagfree) end
function Leona.Waveclear(lagfree)
    local fastClear = Orbwalker.IsFastClearEnabled()
    local lastTarg = Orbwalker.GetLastTarget()
       
    if lagfree == 1 and spells.Q:IsReady() then
        local qMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseQ")
        if qMonster and TS:IsValidAutoRange(lastTarg) then
            if spells.Q:Cast() then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushQ") then
            for i, obj in ipairs(ObjManager.GetNearby("enemy", "minions")) do
                if TS:IsValidAutoRange(obj) then
                    local dmg = Orbwalker.GetAutoAttackDamage(obj) + spells.Q:GetDamage(obj)
                    if dmg > obj.Health and spells.Q:Cast() then
                        return
                    end
                end
            end
        end
    end
    if lagfree == 2 and spells.W:IsReady() then
        local wMonster = lastTarg and lastTarg.IsMonster and Menu.Get("Jungle.UseW")
        if wMonster and TS:IsValidTarget(lastTarg, spells.W.Range) then
            if spells.W:Cast() then
                return
            end
        end

        if fastClear and Menu.Get("Clear.PushW") then
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
    if lagfree == 3 and spells.E:IsReady() then
        if fastClear and Menu.Get("Clear.PushE") and spells.E:CastIfWillHit(3, "minions") then
            return
        end
    end 
end

function Leona.ComboLogic(mode, lagfree) 
    if lagfree == 1 and IsEnabledAndReady("Q", mode) then
        local qTarget = TS:GetTarget(-1)
        if qTarget and not IsSpellShielded(qTarget) and spells.Q:Cast() then
            return
        end    
    end   
    if lagfree == 2 and IsEnabledAndReady("W", mode) then
        if spells.W:GetTarget() and spells.W:Cast() then
            return
        end
    end 
    if lagfree == 3 and IsEnabledAndReady("E", mode) then
        for k, eTarget in ipairs(spells.E:GetTargets()) do
            if not IsSpellShielded(eTarget) and spells.E:CastOnHitChance(eTarget, Enums.HitChance.Low) then
                return
            end
        end
    end
    if lagfree == 4 and IsEnabledAndReady("R", mode) then        
        if spells.R:CastIfWillHit(Menu.Get("ComboR.MinHit"), "heroes") then
            return
        end
        if Menu.Get("ComboR.Duel") then
            for k, rTarg in ipairs(spells.R:GetTargets()) do
                local whitelist = Menu.Get("ComboR.Duel." .. rTarg.CharName, true)
                if whitelist and not IsSpellShielded(rTarg) then
                    if spells.R:CastOnHitChance(rTarg, Enums.HitChance.Low) then
                        return
                    end
                end
            end
        end
    end
end

function Leona.OnSpellCast(obj, spellcast)
    if not (obj.IsMe and Leona.BurstStage) then return end

    local castSlot = spellcast.Slot
    if castSlot == spells.W.Slot and Leona.BurstStage == 1 then
        Leona.BurstStage = 2
    elseif castSlot == spells.Q.Slot and Leona.BurstStage == 2 then
        Leona.BurstStage = 3
    elseif castSlot == spells.R.Slot and Leona.BurstStage == 3 then
        Leona.ResetBurstMode()
    end
end

function Leona.OnNormalPriority(lagfree)     
    if not Game.CanSendInput() then return end 
    
    if not Orbwalker.CanCast() then return end
    local ModeToExecute = Leona[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute(lagfree)
    end
end

function Leona.OnDraw()  
    local playerPos = Player.Position    
    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

function Leona.OnGapclose(source, dashInst)
    if not source.IsEnemy then return end
    if Menu.Get("Misc.GapE") and spells.E:IsReady() then 
        if spells.E:CastOnHitChance(source, Enums.HitChance.Low) then
            return
        end
    end
    if Menu.Get("Misc.GapR") and spells.R:IsReady() then 
        if spells.R:CastOnHitChance(source, Enums.HitChance.Low) then
            return
        end
    end
end

function Leona.OnInterruptibleSpell(Source, SpellCast, Danger, EndTime, CanMoveDuringChannel)
    if Danger < 3 or CanMoveDuringChannel or not Source.IsEnemy then return end

    if Menu.Get("Misc.IntE") and spells.E:IsReady() then 
        if spells.E:CastOnHitChance(Source, Enums.HitChance.Low) then
            return
        end
    end    
    if Menu.Get("Misc.IntR") and spells.R:IsReady() then 
        if spells.R:CastOnHitChance(Source, Enums.HitChance.Low) then
            return
        end
    end
end

-- Load Script
local function Init() 
    Leona.LoadMenu()

    for EventName, EventId in pairs(Enums.Events) do
        if Leona[EventName] then
            EventManager.RegisterCallback(EventId, Leona[EventName])
        end
    end
    return true
end
Init()
