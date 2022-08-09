if Player.CharName ~= "Udyr" then return end

module("Unruly Udyr", package.seeall, log.setup)
clean.module("Unruly Udyr", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyUdyr.lua", "1.0.5")

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell

local spells = {
    Q = Spell.Active({Slot = Enums.SpellSlots.Q}),
    W = Spell.Active({Slot = Enums.SpellSlots.W}),
    E = Spell.Active({Slot = Enums.SpellSlots.E}),
    R = Spell.Active({Slot = Enums.SpellSlots.R}),    
}

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Udyr = {}
Udyr.aaCount = 0

function Udyr.IsEnabled(spell, mode)
    return Menu.Get(mode .. ".Use"..spell, true)
end
function Udyr.IsEnabledAndReady(spell, mode)
    return Udyr.IsEnabled(spell, mode) and spells[spell]:IsReady()
end

function Udyr.OnPostAttack(target)
    Udyr.aaCount = Udyr.aaCount + 1
end
function Udyr.OnSpellCast(obj, spellcast)
    if obj.IsMe and spellcast.Slot <= 3 then
        Udyr.aaCount = 0
    end
end

local lagfree = 0
function Udyr.OnNormalPriority(_lagfree)    
    if Player.IsDead then Udyr.aaCount = 0; return end
    if (Game.IsChatOpen() or Game.IsMinimized() or Player.IsRecalling) then 
        return 
    end    

    lagfree = _lagfree  
    if Menu.Get("Misc.StunRotation") then
        Udyr.StunRotation()
    end
      
    local ModeToExecute = Udyr[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end
function Udyr.Combo()  Udyr.ComboLogic("Combo")  end
function Udyr.Harass() Udyr.ComboLogic("Harass") end
function Udyr.Waveclear()  
    if lagfree == 1 then   
        local lastTarg = Orbwalker.GetLastTarget()
        if lastTarg and lastTarg.IsMinion then
            if lastTarg.IsMonster then
                if (Udyr.IsEnabled("E", "Clear") and spells.E:IsLearned() and Udyr.CanStunE(lastTarg)) then
                    if spells.E:IsReady() then
                        spells.E:Cast()
                    end
                    return
                end

                if Player.Level < 4 or Menu.Get("Misc.CurrentMeta") == 0 then
                    Udyr.TigerMeta("Clear")
                else
                    Udyr.PhoenixMeta("Clear")
                end  
            else
                if Udyr.IsEnabledAndReady("R", "Clear") then
                    spells.R:Cast()
                    return
                end
            end
        end 
    end   

    if lagfree == 2 and Menu.Get("Misc.KeepPassive") then
        local buff = Player:GetBuff("UdyrMonkeyAgilityBuff")
        if not buff or buff.DurationLeft < 0.5 then
            for k, spell in pairs(spells) do
                if Udyr.IsEnabledAndReady(k, "Clear") and spell:Cast() then
                    return
                end
            end
        end
    end
end
function Udyr.Flee() 
    if Udyr.IsEnabledAndReady("E", "Flee") then
        spells.E:Cast()
        return
    end

    local buff = Player:GetBuff("UdyrMonkeyAgilityBuff")
    local count = buff and buff.Count or 0
    if count == 0 or count == 3 then
        return
    end

    local qLvl = spells.Q:IsReady() and spells.Q:GetLevel() or 0
    local wLvl = spells.W:IsReady() and spells.W:GetLevel() or 0
    local rLvl = spells.R:IsReady() and spells.R:GetLevel() or 0

    if Udyr.IsEnabledAndReady("Q", "Flee") and qLvl >= wLvl and qLvl >= rLvl then
        spells.Q:Cast()
    elseif Udyr.IsEnabledAndReady("W", "Flee") and wLvl >= qLvl and wLvl >= rLvl then
        spells.W:Cast()
    elseif Udyr.IsEnabledAndReady("R", "Flee") and rLvl >= qLvl and rLvl >= wLvl then
        spells.R:Cast()
    end
end

function Udyr.StunRotation()
    local playerPos = Player.Position
    local bestDist, nextTargetToStun = 1000, nil
    for k, v in ipairs(TS:GetTargets(1500)) do
        local dist = v:Distance(playerPos)
        if dist < bestDist and Udyr.CanStunE(v) then
            bestDist = dist
            nextTargetToStun = v
        end
    end

    if nextTargetToStun then
        if lagfree == 1 and Orbwalker.CanCast() then
            if spells.E:IsReady() and spells.E:Cast() then
                return
            end
        end
        Orbwalker.Orbwalk(nextTargetToStun.Position, nextTargetToStun)
    else
        Orbwalker.Orbwalk()
    end
end

function Udyr.ComboLogic(mode)
    local target = TS:GetTarget(600)
    if not target then return end
    
    --[[Always prioritize stunning enemy]]
    if (Udyr.IsEnabled("E", mode) and spells.E:IsLearned() and Udyr.CanStunE(target)) then
        if spells.E:IsReady() then
            spells.E:Cast()
        end
        return
    end

    --[[If you're ready to attack or there are no enemy in range, return]]
    local attackRange = Orbwalker.GetTrueAutoAttackRange(Player, target)
    if not Orbwalker.CanCast() or Player:Distance(target) > (attackRange+100) then
        return
    end

    if Menu.Get("Misc.CurrentMeta") == 0 then
        Udyr.TigerMeta(mode)
    else
        Udyr.PhoenixMeta(mode)
    end        
end

function Udyr.TigerMeta(mode)    
    --[[Always Use Q]]
    if Udyr.IsEnabledAndReady("Q", mode) then
        spells.Q:Cast()
        return
    end

    local stance = Udyr.GetStance()
    
    --[[If you cant Q, Always Use R]]
    local alreadyUsedQ = (stance == "Tiger" and Udyr.aaCount > 1)
    local skipQ = alreadyUsedQ or not Udyr.IsEnabled("Q", mode) or not spells.Q:IsLearned()
    if Udyr.IsEnabledAndReady("R", mode) and skipQ and spells.R:Cast() then
        return
    end

    --[[If you cant Q or R, Always Use W]]
    local alreadyUsedR = (stance == "Phoenix" and (Udyr.aaCount == 1 or Udyr.aaCount > 3))
    local skipR = alreadyUsedR or not Udyr.IsEnabled("R", mode) or not spells.R:IsLearned()
    if Udyr.IsEnabledAndReady("W", mode) and skipQ and skipR then
        if Player.HealthPercent < (Menu.Get(mode..".MinHealthW")/100) then
            spells.W:Cast()
            return
        end
    end
end

function Udyr.PhoenixMeta(mode)    
    --[[Always Use R]]
    if Udyr.IsEnabledAndReady("R", mode) then
        spells.R:Cast()
        return
    end
    
    local stance = Udyr.GetStance()

    --[[If you cant R, Always Use Q]]
    local alreadyUsedR = (stance == "Phoenix" and (Udyr.aaCount == 1 or Udyr.aaCount > 3))
    local skipR = alreadyUsedR or not Udyr.IsEnabled("R", mode) or not spells.R:IsLearned()
    if Udyr.IsEnabledAndReady("Q", mode) and skipR and spells.Q:Cast() then
        return
    end

    --[[If you cant Q or R, Always Use W]]
    local alreadyUsedQ = (stance == "Tiger" and Udyr.aaCount > 1)    
    local skipQ = alreadyUsedQ or not Udyr.IsEnabled("Q", mode) or not spells.Q:IsLearned()
    if Udyr.IsEnabledAndReady("W", mode) and skipQ and skipR then
        if Player.HealthPercent < (Menu.Get(mode..".MinHealthW")/100) then
            spells.W:Cast()
            return
        end
    end
end

function Udyr.GetStance()
    if Player:GetBuff("UdyrTigerStance") then
        return "Tiger"
    elseif Player:GetBuff("UdyrTurtleStance") then
        return "Turtle"
    elseif Player:GetBuff("UdyrBearStance") then
        return "Bear"
    elseif Player:GetBuff("UdyrPhoenixStance") then
        return "Phoenix"
    end
    return "None"
end
function Udyr.CanStunE(target)
    return not target:GetBuff("UdyrBearStunCheck")
end

function Udyr.LoadMenu()
    Menu.RegisterMenu("UnrulyUdyr", "Unruly Udyr", function()
        Menu.ColumnLayout("cols", "cols", 4, true, function()
            Menu.NewTree("Combo Settings", "Combo Settings", function()
            Menu.Separator("Combo Settings")
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true)
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Slider("Combo.MinHealthW", "Min Health %", 70, 0, 100, 1)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)       
            Menu.Checkbox("Combo.UseR", "Use [R]", true)  
        end)

            Menu.NewTree("Harass Settings", "Harass Settings", function()
            Menu.Separator("Harass Settings")
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true)
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
            Menu.Slider("Harass.MinHealthW", "Min Health %", 70, 0, 100, 1)
            Menu.Checkbox("Harass.UseE", "Use [E]", true)       
            Menu.Checkbox("Harass.UseR", "Use [R]", true)  
        end)

            Menu.NewTree("Lane Clear Settings", "Lane Clear Settings", function()
            Menu.Separator("Lane Clear Settings")
            Menu.Checkbox("Clear.UseQ", "Use [Q]", true)
            Menu.Checkbox("Clear.UseW", "Use [W]", true)
            Menu.Slider("Clear.MinHealthW", "Min Health %", 70, 0, 100, 1)
            Menu.Checkbox("Clear.UseE", "Use [E]", true)    
            Menu.Checkbox("Clear.UseR", "Use [R]", true)    
        end)

            Menu.NewTree("Flee Settings", "Flee Settings", function()
            Menu.Separator("Flee Settings")
            Menu.Checkbox("Flee.UseQ", "Use [Q]", true)
            Menu.Checkbox("Flee.UseW", "Use [W]", true)
            Menu.Checkbox("Flee.UseE", "Use [E]", true)
            Menu.Checkbox("Flee.UseR", "Use [R]", true)
        end)
        end)

        Menu.Separator("Misc Options")
        Menu.Dropdown("Misc.CurrentMeta", "Current Meta", 1, {"Tiger", "Phoenix"})
        Menu.Keybind("Misc.StunRotation", "Stun Rotation", string.byte('T'))
        Menu.Checkbox("Misc.KeepPassive", "Keep Passive Alive During Jungle", true)
        Menu.Separator("Author: Thorn")
    end)
end

function OnLoad()
    Udyr.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Udyr[eventName] then
            EventManager.RegisterCallback(eventId, Udyr[eventName])
        end
    end    
    return true
end
