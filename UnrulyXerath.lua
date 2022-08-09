--[[
    First Release By Thorn @ 10.Oct.2020    
]]

if Player.CharName ~= "Xerath" then return end

module("Unruly Xerath", package.seeall, log.setup)
clean.module("Unruly Xerath", clean.seeall, log.setup)
CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/UnrulyXerath.lua", "1.0.6")

local clock = os.clock
local insert = table.insert
local huge, min, max = math.huge, math.min, math.max

local _SDK = _G.CoreEx
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Profiler = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Profiler

local _Q = {    
    Slot = Enums.SpellSlots.Q,
    Speed = huge,
    Range = 750,    
    Delay = 0.6,
    Radius = 145/2,
    Type = "Linear",

    IsCharging = false,
    MinRange = 750,
    MaxRange = 1500,
    FullChargeTime = 1.5,
    ChargeStartTime = 0,
    ChargeSentTime = 0,
    ReleaseSentTime = 0,
}
local _W = {    
    Slot = Enums.SpellSlots.W,
    Speed = huge,
    Range = 1000,
    Delay = 0.75,
    Radius = 125,
    EffectRadius = 125,
    Type = "Circular",
}
local _E = {    
    Slot = Enums.SpellSlots.E,
    Speed = 1400,
    Range = 1050,
    Delay = 0.25,
    Radius = 60,
    Type = "Linear",
    Collisions = {Heroes=true, Minions=true, WindWall=true},
    UseHitbox = true
}
local _R = {    
    Slot = Enums.SpellSlots.R,
    Speed = huge,
    Range = 5000,
    Delay = 0.7,
    Radius = 200,
    Type = "Circular",
}
local function IsSpellReady(slot)
    return Player:GetSpellState(Enums.SpellSlots[slot]) == Enums.SpellStates.Ready
end
local function GameIsAvailable()
    return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end
local lastCasts = {}
local function CastSpell(slot, ...)
    local curTime, lastCast = Game.GetTime(), lastCasts[slot]
    if lastCast and curTime < (lastCast + 0.4) then
        return
    end
    if Input.Cast(slot, ...) then
        lastCasts[slot] = curTime
        return true
    end
end

---@type TargetSelector
local TS = _G.Libs.TargetSelector()
local Xerath = {}

function Xerath.IsEnabledAndReady(spell, mode)
    return Menu.Get(mode .. ".Use"..spell) and IsSpellReady(spell)
end
function Xerath.ReleaseQ(pos)
    Input.Release(_Q.Slot, pos)        
    _Q.ReleasePos = pos
end
function Xerath.GetExtraDistQ(mode) return 75 + (Menu.Get(mode.. ".ExtraRangeQ", true) or 0) end
function Xerath.IsCastingR() return Player:GetBuff("XerathLocusOfPower2") end
function Xerath.MaxCharges() local r = Player:GetSpell(Enums.SpellSlots.R); return (r.IsLearned and 2 + r.Level) or 3 end
function Xerath.IsPassiveReady() return Player:GetBuff("xerathascended2onhit") end

function Xerath.GetRawDamageQ()
    return 40 + Player:GetSpell(_Q.Slot).Level * 40 + 0.75 * Player.TotalAP
end
function Xerath.GetRawDamageW()
    return 30 + Player:GetSpell(_W.Slot).Level * 30 + 0.6 * Player.TotalAP
end
function Xerath.GetDamageR()
    return 150 + Player:GetSpell(_R.Slot).Level * 50 + 0.45 * Player.TotalAP
end

function Xerath.GetRangeQ() 
    if not _Q.IsCharging then return _Q.MinRange end
    local mod = (Game.GetTime() - Game.GetLatency()/1000 - _Q.ChargeStartTime)/_Q.FullChargeTime
    return min(_Q.MaxRange, _Q.MinRange + (_Q.MaxRange - _Q.MinRange)*mod)
end
function Xerath.GetBestPosW(targets)
    local points = {}
    for k, v in ipairs(targets) do        
        insert(points, v.AsAI:FastPrediction(_W.Delay))
    end
    return Geometry.BestCoveringCircle(points, _W.Radius)
end

function Xerath.CastOnBestTarget(spell, minHitChance)
    local targ = TS:GetTarget(spell.Range)
    if targ then
        local pred = Prediction.GetPredictedPosition(targ, spell, Player.Position)
        if pred and pred.HitChance > minHitChance then
            return CastSpell(spell.Slot, pred.CastPosition)
        end
    end
end
function Xerath.ChainCC(minChance)
    local pPos = Player.Position
    local delay = Game.GetLatency()/1000 + _E.Delay

    for k, targ in ipairs(TS:GetTargets(_E.Range)) do        
        local flightTime = delay + (pPos:Distance(targ)/_E.Speed)
        if ImmobileLib.GetImmobileTimeLeft(targ) <= flightTime then
            local pred = Prediction.GetPredictedPosition(targ, _E, pPos)
            if pred and pred.HitChance >= minChance and CastSpell(_E.Slot, pred.CastPosition) then
                return true
            end 
        end
    end    
end

local lastTick = 0
function Xerath.OnTick()        
    _Q.Range = Xerath.GetRangeQ()    

    local gameTime = Game.GetTime()
    if gameTime < (lastTick + 0.25) then return end
    lastTick = gameTime    

    if not GameIsAvailable() then return end

    if Xerath.Auto() then return end
    local ModeToExecute = Xerath[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
end

function Xerath.Auto()
    if not Xerath.IsCastingR() then return end

    local mode = Xerath.ModesR[Menu.Get("Misc.ModeR")+1]
    if (mode == "On Tap [Auto]" or mode == "On Tap [Near Mouse]") and not Menu.Get("Misc.KeyR") then
        return
    end

    local function UseChargeR(targets, excludeTarget)
        for k, targ in ipairs(targets) do
            if targ ~= excludeTarget then
                local pred = Prediction.GetPredictedPosition(targ, _R, Player.Position)
                if pred and pred.HitChance >= Menu.Get("Combo.ChanceR") and Input.Cast(_R.Slot, pred.CastPosition) then
                    Xerath.LastUltTarget = targ
                    Xerath.TargetWillDie = (targ.Health + targ.ShieldAll)
                    return true
                end 
            end
        end
    end
    
    if mode == "Smart" or mode == "Obvious" or mode == "On Tap [Auto]" then
        local HasntFiredYet = Xerath.ChargesRemaining == Xerath.MaxCharges()
        if not Xerath.LastUltTarget or HasntFiredYet then
            if UseChargeR(TS:GetTargets(_R.Range)) then 
                return true
            end
        elseif Xerath.LastUltTarget then
            local shouldRepeatTarget = not Xerath.TargetWillDie or (Game.GetTime() - Xerath.LastChargeTime > (_R.Delay + 0.1))
            if shouldRepeatTarget and TS:IsValidTarget(Xerath.LastUltTarget, _R.Range) then
                if UseChargeR({Xerath.LastUltTarget}) then 
                    return true
                end
            else
                local canCast = mode ~= "Smart" or Game.GetTime() > (Xerath.LastChargeTime + 1)
                if canCast and UseChargeR(TS:GetTargets(_R.Range), Xerath.LastUltTarget) then 
                    return true
                end
            end
        end
    elseif mode == "Near Mouse" or mode == "On Tap [Near Mouse]" then
        local mousePos = Renderer.GetMousePos()
        for k, targ in pairs(TS:GetTargets(_R.Range)) do
            if targ:Distance(mousePos) < 500 and UseChargeR({targ})then
                return true
            end
        end
    end   
end

function Xerath.ComboLogic(mode)
    local gameTime = Game.GetTime()
    if _Q.IsCharging then
        if Xerath.IsEnabledAndReady("Q", mode) and gameTime > (_Q.ChargeSentTime + 0.075) then
            local extraRange = Xerath.GetExtraDistQ(mode)

            local pPos, targ = Player.Position, (TS:GetTarget(-1) or TS:GetTarget(_Q.MaxRange))
            local rangeCheck = (_Q.Range + extraRange < _Q.MaxRange and (_Q.Range - extraRange) or _Q.Range)
                        
            if targ and pPos:Distance(targ) < rangeCheck then 
                local pred = Prediction.GetPredictedPosition(targ, _Q, pPos)
                if pred and (pred.HitChance >= Menu.Get(mode .. ".ChanceQ") or _Q.Range == _Q.MaxRange) then
                    Xerath.ReleaseQ(pred.CastPosition)            
                end 
            end
        end
        return
    end

    local stillCastingR = Player.AttackRange > 2000
    if Player.IsCasting or stillCastingR then
        return
    end

    if mode == "Combo" then
        if Xerath.IsEnabledAndReady("W", mode) and Xerath.CastOnBestTarget(_W, Menu.Get(mode .. ".ChanceW")) then
            return
        end
    elseif mode == "Harass" then
        if Xerath.IsEnabledAndReady("W", mode) then
            local pos, hits = Xerath.GetBestPosW(TS:GetTargets(_W.Range))
            if pos and hits > 0 then
                CastSpell(_W.Slot, pos)
            end
        end
    end

    if Xerath.IsEnabledAndReady("E", mode) and Xerath.ChainCC(Menu.Get(mode .. ".ChanceE")) then            
        return
    end
    if mode == "Combo" and Xerath.IsEnabledAndReady("R", mode) and not Xerath.IsCastingR() then
        local pPos = Player.Position
        local targets = TS:GetTargets(_R.Range)

        local enemiesNearby = false
        for k, targ in ipairs(targets) do
            if targ:Distance(pPos) < _W.Range then
                enemiesNearby = true
                break
            end
        end

        -- Start R If You Can Kill Enemy Nearby (and other spells failed)
        if not enemiesNearby then
            local rawDmg = Xerath.GetDamageR() * Xerath.MaxCharges()
            for k, targ in ipairs(targets) do
                local rDmg = DmgLib.CalculateMagicalDamage(Player, targ, rawDmg)
                if rDmg > (targ.Health + targ.ShieldAll) then
                    CastSpell(_R.Slot, Renderer.GetMousePos())
                    return
                end
            end  
        end          
    end    
    if Xerath.IsEnabledAndReady("Q", mode) and gameTime > (max(_Q.ChargeSentTime, _Q.ReleaseSentTime) + 1) then -- Start Charging
        local targ = TS:GetTarget(-1) or TS:GetTarget(_Q.MaxRange)
        if targ and CastSpell(_Q.Slot, Renderer.GetMousePos()) then 
            _Q.ChargeSentTime = gameTime
            
            if targ:Distance(Player) < (_Q.MinRange - Xerath.GetExtraDistQ(mode)) then
                delay(75, function()
                    local pred = Prediction.GetPredictedPosition(targ, _Q, Player.Position)
                    if pred then 
                        Xerath.ReleaseQ(pred.CastPosition)
                    end
                end)
            end
            return
        end
    end    
end

function Xerath.Combo()
    Xerath.ComboLogic("Combo")
end
function Xerath.Harass()
    Xerath.ComboLogic("Harass")
end
function Xerath.Lasthit()
    local farmQ = Xerath.IsEnabledAndReady("Q", "LHit") and Menu.Get("LHit.MinHitQ")
    local farmW = Xerath.IsEnabledAndReady("W", "LHit") and Menu.Get("LHit.MinHitW")
   
    if farmQ or farmW then
        local pPos, pointsQ, pointsW = Player.Position, {}, {}
        local dmgQ, dmgW = Xerath.GetRawDamageQ(), Xerath.GetRawDamageW()

        for k, v in pairs(ObjManager.Get("enemy", "minions")) do
            local minion = v.AsAI
            if minion then
                local pos = minion:FastPrediction(_W.Delay)
                local dist = pos:Distance(pPos)
                if dist < _W.Range and minion.IsTargetable then
                    local healthPred = HealthPred.GetHealthPrediction(minion, _W.Delay)
                    if healthPred < DmgLib.CalculateMagicalDamage(Player, minion, dmgW) then
                        insert(pointsW, pos)
                    end
                    if dist < _Q.MinRange and healthPred < DmgLib.CalculateMagicalDamage(Player, minion, dmgQ) then
                        insert(pointsQ, pos)
                    end
                end 
            end                       
        end

        if farmW then
            local bestPos, hitCount = Geometry.BestCoveringCircle(pointsW, _W.Radius)
            if bestPos and hitCount > farmW and Input.Cast(_W.Slot, bestPos) then
                return
            end
        end
        if farmQ then
            local bestPos, hitCount = Geometry.BestCoveringRectangle(pointsQ, pPos, _Q.Radius*2)
            if bestPos and hitCount > farmQ and Input.Cast(_Q.Slot, bestPos) then
                delay(75, Xerath.ReleaseQ, bestPos)
                return
            end
        end
    end
end

local function GetHighestHealthUnitInRange(units, range)
    local pPos = Player.Position
    local bestObj, bestHealth = nil, 50
    for k, unit in ipairs(units) do
        if unit and unit.MaxHealth > bestHealth and unit:Distance(pPos) < range then
            bestObj = unit
            bestHealth = unit.MaxHealth
        end
    end
    return bestObj
end

function Xerath.Waveclear()
    local farmQ = Xerath.IsEnabledAndReady("Q", "LClear") and Menu.Get("LClear.MinHitQ")
    local farmW = Xerath.IsEnabledAndReady("W", "LClear") and Menu.Get("LClear.MinHitW")
   
    if farmQ or farmW then
        local pPos, pointsW = Player.Position, {}

        for k, v in pairs(ObjManager.Get("enemy", "minions")) do
            local minion = v.AsAI
            if minion then
                local pos = minion:FastPrediction(_W.Delay)
                if pos:Distance(pPos) < _W.Range and minion.IsTargetable then
                    insert(pointsW, pos)
                end 
            end                       
        end

        if farmW then
            local bestPos, hitCount = Geometry.BestCoveringCircle(pointsW, _W.Radius)
            if bestPos and hitCount > farmW and Input.Cast(_W.Slot, bestPos) then
                return
            end
        end
        if farmQ then
            local pointsQ = {}
            for k, v in ipairs(pointsW) do
                if v:Distance(pPos) < _Q.MinRange then
                    insert(pointsQ, v)
                end
            end
            local bestPos, hitCount = Geometry.BestCoveringRectangle(pointsQ, pPos, _Q.Radius*2)
            if bestPos and hitCount > farmQ and Input.Cast(_Q.Slot, bestPos) then
                delay(75, Xerath.ReleaseQ, bestPos)
                return
            end
        end
    end
    
    local jgQ = Xerath.IsEnabledAndReady("Q", "JClear")
    local jgW = Xerath.IsEnabledAndReady("W", "JClear")
    local jgE = Xerath.IsEnabledAndReady("E", "JClear")
   
    if jgQ or jgW or jgE then
        local pPos, mPos = Player.Position, Renderer.GetMousePos()
        local units, maxRange = {}, max(_Q.Range, _W.Range, _E.Range)

        for k, v in pairs(ObjManager.Get("neutral", "minions")) do
            local minion = v.AsAI
            if minion and minion:Distance(pPos) < maxRange and minion:Distance(mPos) < 900 then
                if minion.IsTargetable and minion.MaxHealth > 6 then
                    insert(units, minion)
                end
            end                       
        end

        local qTarg = jgQ and GetHighestHealthUnitInRange(units, _Q.Range)
        if qTarg and Input.Cast(_Q.Slot, qTarg.Position) then 
            delay(75, Xerath.ReleaseQ, qTarg.Position)    
            return 
        end

        local eTarg = jgE and GetHighestHealthUnitInRange(units, _E.Range)
        if eTarg and Input.Cast(_E.Slot, eTarg.Position) then return end

        local wTarg = jgW and GetHighestHealthUnitInRange(units, _W.Range)
        if wTarg and Input.Cast(_W.Slot, wTarg.Position) then return end            
    end
end

function Xerath.OnUpdateChargedSpell(args) -- {Spell, TargetPosition, Release}
    if args.Spell.Name == "XerathArcanopulseChargeUp" and args.Release then
        if _Q.ReleasePos then
            args.TargetPosition = _Q.ReleasePos
        end
        _Q.ReleaseSentTime = Game.GetTime()        
        _Q.IsCharging = false
    end
end
function Xerath.OnCastStop(sender, spellcast, bStopAnimation, bExecuteCastFrame, bDestroyMissile)
    if sender.IsMe and spellcast.Slot == _Q.Slot then
        _Q.IsCharging = false
        _Q.ReleasePos = nil
    end
end

---@param Caster AIBaseClient
---@param Spell SpellCast
function Xerath.OnProcessSpell(Caster, Spell)
    if not Caster.IsMe then return end
    local name = Spell.Name
    -- WARN("Started %s", name)
    if Spell.Slot == _Q.Slot then
        local gameTime = Game.GetTime()
        if not _Q.IsCharging and (gameTime - _Q.ReleaseSentTime) > 1 then
            _Q.IsCharging = true
            _Q.ChargeStartTime = gameTime
            _Q.ReleasePos = nil
        end
    end

    if name == "XerathLocusOfPower2" then
        Xerath.LastChargePosition = Geometry.Vector()
        Xerath.LastChargeTime = 0
        Xerath.ChargesRemaining = Xerath.MaxCharges()
        Xerath.TapKeyPressed = false
    elseif name == "xerathlocuspulse" then
        Xerath.LastChargePosition = Spell.EndPos
        Xerath.LastChargeTime = Game.GetTime()
        Xerath.ChargesRemaining = Xerath.ChargesRemaining - 1
        Xerath.TapKeyPressed = false
    end
end

function Xerath.LoadMenu()
    Menu.RegisterMenu("UnrulyXerath", "Unruly Xerath", function()
        Menu.ColumnLayout("cols", "cols", 2, true, function()
            Menu.NewTree("Drawing Options", "Drawing Options", function()
            Menu.Separator("Drawing Options")
            Menu.Checkbox("Drawing.Q.Enabled",   "Draw [Q] Range", true)
            Menu.ColorPicker("Drawing.Q.Color", "Draw [Q] Color", 0xEF476FFF)
            Menu.Checkbox("Drawing.W.Enabled",   "Draw [W] Range")
            Menu.ColorPicker("Drawing.W.Color", "Draw [W] Color", 0x06D6A0FF)
            Menu.Checkbox("Drawing.E.Enabled",   "Draw [E] Range", true)
            Menu.ColorPicker("Drawing.E.Color", "Draw [E] Color", 0x118AB2FF)
            Menu.Checkbox("Drawing.R.EnabledMM",   "Draw [R] Range Minimap")
            Menu.ColorPicker("Drawing.R.ColorMM", "Draw [R] Color", 0xFFD166FF)
        end)
        end)

            Menu.NewTree("Combo Settings", "Combo Settings", function()
            Menu.Separator("Combo Settings")
            Menu.Checkbox("Combo.UseQ", "Use [Q]", true)
            Menu.Slider("Combo.ExtraRangeQ", "Humanize Range", 0, 0, 400, 25)
            Menu.Slider("Combo.ChanceQ", "HitChance [Q]", 0.40, 0, 1, 0.05)
            Menu.Checkbox("Combo.UseW", "Use [W]", true)
            Menu.Slider("Combo.ChanceW", "HitChance [W]", 0.15, 0, 1, 0.05)
            Menu.Checkbox("Combo.UseE", "Use [E]", true)
            Menu.Slider("Combo.ChanceE", "HitChance [E]", 0.30, 0, 1, 0.05)
            Menu.Checkbox("Combo.UseR", "Use [R]", true)
            Menu.Slider("Combo.ChanceR", "HitChance [R]", 0.30, 0, 1, 0.05)
        end)

            Menu.NewTree("Harass Settings", "Harass Settings", function()
            Menu.Separator("Harass Settings")
            Menu.Checkbox("Harass.UseQ", "Use [Q]", true)
            Menu.Slider("Harass.ExtraRangeQ", "Humanize Range", 0, 0, 400, 25)
            Menu.Slider("Harass.ChanceQ", "HitChance [Q]", 0.40, 0, 1, 0.05)
            Menu.Checkbox("Harass.UseW", "Use [W]", true)
            Menu.Slider("Harass.ChanceW", "HitChance [W]", 0.15, 0, 1, 0.05)
            Menu.Checkbox("Harass.UseE", "Use [E]", true)
            Menu.Slider("Harass.ChanceE", "HitChance [E]", 0.30, 0, 1, 0.05)
        end)

            Menu.NewTree("Last Hit Settings", "Last Hit Settings", function()
            Menu.Separator("Last Hit Settings")
            Menu.Checkbox("LHit.UseQ", "Use [Q]", true)
            Menu.Slider("LHit.MinHitQ", "Minions Killed", 3, 0, 10)
            Menu.Checkbox("LHit.UseW", "Use [W]", true)
            Menu.Slider("LHit.MinHitW", "Minions Killed", 3, 0, 10)
        end)

            Menu.NewTree("Lane Clear Settings", "Lane Clear Settings", function()
            Menu.Separator("Lane Clear Settings")
            Menu.Checkbox("LClear.UseQ", "Use [Q]", true)
            Menu.Slider("LClear.MinHitQ", "Minions Hit", 3, 0, 10)
            Menu.Checkbox("LClear.UseW", "Use [W]", true)
            Menu.Slider("LClear.MinHitW", "Minions Hit", 3, 0, 10)
        end)

            Menu.NewTree("Jungle Clear Settings", "Jungle Clear Settings", function()
            Menu.Separator("Jungle Clear Settings")
            Menu.Checkbox("JClear.UseQ", "Use [Q]", true)
            Menu.Checkbox("JClear.UseW", "Use [W]", true)
            Menu.Checkbox("JClear.UseE", "Use [E]", false)
        end)

            Menu.NewTree("Misc Options", "Misc Options", function()
            Menu.Separator("Misc Options")
            Menu.Checkbox("Misc.GapE", "Use [E] Gapclose", true)
            Menu.SameLine(200)
            Menu.Checkbox("Misc.IntE", "Use [E] Interrupt", true)
            Menu.Dropdown("Misc.ModeR", "Use [R] Mode", 1, Xerath.ModesR)
            Menu.Keybind("Misc.KeyR", "[R] Tap Key", string.byte('T'))
        end)

            Menu.Separator("Author: Thorn")
        end)
end

function Xerath.Init()   
    Xerath.TapKeyPressed = false
    Xerath.ChargesRemaining = 0
    Xerath.LastChargeTime = 0
    Xerath.LastChargePosition = Geometry.Vector()    
    Xerath.ModesR = {"Smart", "Obvious", "Near Mouse", "On Tap [Auto]", "On Tap [Near Mouse]"}

    Xerath.LoadMenu()
end

---@param source AIBaseClient
---@param dash DashInstance
function Xerath.OnGapclose(source, dash)
    if not (source.IsEnemy and Menu.Get("Misc.GapE") and IsSpellReady("E")) then return end

    local pred = Prediction.GetPredictedPosition(source, _E, Player.Position)
    if pred and pred.HitChanceEnum > Enums.HitChance.Low then
        return CastSpell(_E.Slot, pred.CastPosition)
    end
end

---@param source AIBaseClient
---@param spell SpellCast
function Xerath.OnInterruptibleSpell(source, spell, danger, endT, canMove)
    if not (source.IsEnemy and Menu.Get("Misc.IntE") and IsSpellReady("E") and danger > 2) then return end

    local pred = Prediction.GetPredictedPosition(source, _E, Player.Position)
    if pred and pred.HitChanceEnum > Enums.HitChance.Low then
        return CastSpell(_E.Slot, pred.CastPosition)
    end
end

function Xerath.OnDraw() 
    local spells = {Q={Range=_Q.MaxRange}, W=_W, E=_E}
    local playerPos = Player.Position
    
    if Menu.Get("Drawing.R.EnabledMM") then
        Renderer.DrawCircleMM(playerPos, _R.Range, 2, Menu.Get("Drawing.R.ColorMM")) 
    end

    for k, v in pairs(spells) do
        if Menu.Get("Drawing."..k..".Enabled", true) then
            Renderer.DrawCircle3D(playerPos, v.Range, 30, 2, Menu.Get("Drawing."..k..".Color")) 
        end
    end
end

function OnLoad()
    Xerath.Init()
    for eventName, eventId in pairs(Enums.Events) do
        if Xerath[eventName] then
            EventManager.RegisterCallback(eventId, Xerath[eventName])
        end
    end
    return true
end
