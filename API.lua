---@alias Pointer number
---@alias Handle_t number

--[[
    ██       ██████   ██████ 
    ██      ██    ██ ██      
    ██      ██    ██ ██   ███ 
    ██      ██    ██ ██    ██ 
    ███████  ██████   ██████  
]]
--[[
    [Usage]:

    module("modname", package.seeall, log.setup, ...)
    clean.module("modname", clean.seeall, log.setup, ...)
]]
---@class log
---@field setup fun(module_id: string) @helper function to create local logging shortcuts (DEBUG, INFO, ...) passed as Parameter To 'module'.
log = "Common logging module. Only Shows Messages Above Current Logging Level."

---@type fun()
stacktrace = "Prints the current lua stack trace."

---@type fun(level: integer, module: string, format: string, var_args:any)
LOG = "Logger main function. Any log message has to pass through this function."
---@type fun(format: string, var_args:any)
DEBUG = "Log a Debug Message"
---@type fun(format: string, var_args:any)
INFO = "Log an Information Message"
---@type fun(format: string, var_args:any)
WARN = "Log a Warning Message"
---@type fun(format: string, var_args:any)
ERROR = "Log an Error Message"
---@type fun(format: string, var_args:any)
FATAL = "Log a Fatal Error Message"

--[[
    ██    ██ ████████ ██ ██      ███████ 
    ██    ██    ██    ██ ██      ██      
    ██    ██    ██    ██ ██      ███████ 
    ██    ██    ██    ██ ██           ██ 
     ██████     ██    ██ ███████ ███████        
]]

---@class json
---@field encode fun(lua_data: table, prettify:boolean|nil) @json.encode({ 1, 2, 3, { x = 10 } }) -- Returns '[1,2,3,{"x":10}]'
---@field decode fun(json_data: string) @json.decode('[1,2,3,{"x":10}]') -- Returns { 1, 2, 3, { x = 10 } }
local json
_G.json = json

---@type string
_NAME = "Name Of The Current Module"

---@type fun()
Class = "oo.lua class. Supports :new() and :extend()"

---@type AIHeroClient
local Player
_G.Player = Player

---@type fun(time_ms: integer, cb: function, var_args: any):nil
delay = "No-Lock Delayed Execution"
---@type fun(time_ms: integer, cb: function, var_args: any):nil
timer = "Periodic Execution"
---@type fun():integer
getCurrentMillis = "Miliseconds since Robur Startup"

---@type fun(md5sum: string, expected: string):boolean
checkFileMd5 = "checks the message digest of a file, and displays error prompt on mismatch"
---@type fun(path: string):boolean
io.exists = "Returns if a file exists"
---@type fun(path: string, mode: string, absolute: boolean):string
io.readFile = "reads a whole file and returns the contents as a big string"
---@type fun(path: string, data: any):nil
io.writeFile = "writes a file. Warning: overwrites existing content"

---@type fun(str: string, substr: any):boolean
local starts_with
string.starts_with = starts_with

---@type fun(str: string, substr: any):boolean
local ends_with
string.ends_with = ends_with

---@type fun(format:string, var_args: any):string
printf = "a shortcut to print(string.format(fmt, ...))"

---@type fun(var_args: table | number | string | boolean | nil):table
array_concat = "merge arrays (sequentially indexed tables, won't work for associative tables)"
---@type fun(var_args: table):table
array_merge = "merge arrays (associative tables)"

---@type fun(level: integer):integer
getCallerPos = "return position within caller."
---@type fun(level: integer):string
getCallerName = "return the name of a calling function."
---@type fun(check: table):nil @checkargs({arg3, "number"}, {arg1, "string,number", "something went wrong!"})
checkargs = "quickly check for and error() on wrong type or missing arguments"

---@type fun(table: table, mod: any):table
enumHelper = "A function that converts a table to a two-way mapping of keys and values."

_G.Libs = {}
_G.CoreEx = {}
_G.CoreEx.Enums = {}
_G.CoreEx.Geometry = {}

--[[
    ██    ██ ███████  ██████ ████████  ██████  ██████ 
    ██    ██ ██      ██         ██    ██    ██ ██   ██ 
    ██    ██ █████   ██         ██    ██    ██ ██████  
     ██  ██  ██      ██         ██    ██    ██ ██   ██ 
      ████   ███████  ██████    ██     ██████  ██   ██   
]]

---@class Vector @Vector(x, y, z)
---@field x number
---@field y number
---@field z number
---@field AsArray fun(self: Vector):Pointer
---@field SetHeight fun(self: Vector, h: number | nil):nil 
---@field ToScreen fun(self: Vector):Vector
---@field ToMM fun(self: Vector):Vector
---@field Unpack fun(self: Vector):number, number, number
---@field LenSqr fun(self: Vector):number
---@field Len fun(self: Vector):number
---@field DistanceSqr fun(self: Vector, v: Vector|GameObject):number
---@field Distance fun(self: Vector, v:Vector|GameObject):number
---@field LineDistance fun(self: Vector, _segStart: Vector, _segEnd: Vector, onlyIfOnSegment:boolean):number
---@field Normalize fun(self: Vector):Vector
---@field Normalized fun(self: Vector):Vector
---@field Extended fun(self: Vector, to:Vector|GameObject, distance:number):Vector
---@field Center fun(self: Vector, v:Vector|GameObject):Vector
---@field CrossProduct fun(self: Vector, v:Vector|GameObject):Vector
---@field DotProduct fun(self: Vector, v:Vector|GameObject):number
---@field ProjectOn fun(self: Vector, _segStart:Vector|GameObject, _segEnd:Vector|GameObject):boolean, Vector, Vector @returns: isOnSegment, pointSegment, pointLine
---@field Polar fun(self: Vector):number
---@field AngleBetween fun(self: Vector, _v1:Vector|GameObject, _v2:Vector|GameObject):number
---@field RotateX fun(self: Vector, phi: number):Vector
---@field RotateY fun(self: Vector, phi: number):Vector
---@field RotateZ fun(self: Vector, phi: number):Vector
---@field Rotate fun(self: Vector, phiX:number, phiY:number, phiZ:number):Vector
---@field Rotated fun(self: Vector, phiX:number, phiY:number, phiZ:number):Vector
---@field RotatedAroundPoint fun(self: Vector, p:Vector|GameObject, phiX:number, phiY:number, phiZ:number):Vector
---@field IsValid fun(self: Vector):boolean
---@field Perpendicular fun(self: Vector):Vector
---@field Perpendicular2 fun(self: Vector):Vector
---@field Absolute fun(self: Vector):Vector
---@field Draw fun(self: Vector, color: integer):nil
---@field IsOnScreen fun(self: Vector):boolean
---@field IsWall fun(self: Vector):boolean 
---@field IsGrass fun(self: Vector):boolean 
---@field IsWithinTheMap fun(self: Vector):boolean 
---@field GetTerrainHeight fun(self: Vector):number 
local Vector

---@type fun(x: number|Vector|nil, y: number|nil, z: number|nil):Vector
local vecCtor
_G.CoreEx.Geometry.Vector = vecCtor

--[[
    ██████   █████  ████████ ██   ██ 
    ██   ██ ██   ██    ██    ██   ██ 
    ██████  ███████    ██    ███████ 
    ██      ██   ██    ██    ██   ██ 
    ██      ██   ██    ██    ██   ██ 
]]
---@class Path @Path(pos1, pos2)
---@field GetPoints fun(self:Path):Vector[]
---@field GetPaths fun(self:Path):Path[]
---@field Direction fun(self:Path):Vector
---@field Len fun(self:Path):number
---@field Contains fun(self:Path, geometry: Vector|Path):boolean
---@field Intersects fun(self:Path, geometry: Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Distance fun(self:Path, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):number
---@field Draw fun(self:Path, color:number|nil):nil
local Path

---@type fun(pos1: Vector|Path, pos2: Vector):Path
local pathCtor
_G.CoreEx.Geometry.Path = pathCtor

--[[
     ██████ ██ ██████   ██████ ██      ███████ 
    ██      ██ ██   ██ ██      ██      ██      
    ██      ██ ██████  ██      ██      █████   
    ██      ██ ██   ██ ██      ██      ██      
     ██████ ██ ██   ██  ██████ ███████ ███████ 
]]
---@class Circle @Circle(centerPos, Radius)
---@field GetPoints fun(self:Circle, quality:number|nil):Vector[]
---@field GetPaths fun(self:Circle, quality:number|nil):Path[]
---@field Contains fun(self:Circle, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Intersects fun(self:Circle, geometry: Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Distance fun(self:Circle, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):number
---@field IsOnScreen fun(self:Circle):boolean
---@field Draw fun(self:Circle, color:number|nil, quality:number|nil):nil
---@field Offseted fun(self:Circle, distance: number):boolean
local Circle

---@type fun(pos1: Vector|Circle, radius: number):Circle
local circleCtor
_G.CoreEx.Geometry.Circle = circleCtor

--[[
    ██████  ███████  ██████ ████████  █████  ███    ██  ██████  ██      ███████ 
    ██   ██ ██      ██         ██    ██   ██ ████   ██ ██       ██      ██      
    ██████  █████   ██         ██    ███████ ██ ██  ██ ██   ███ ██      █████   
    ██   ██ ██      ██         ██    ██   ██ ██  ██ ██ ██    ██ ██      ██      
    ██   ██ ███████  ██████    ██    ██   ██ ██   ████  ██████  ███████ ███████ 
]]
---@class Rectangle @Rectangle(startPos, endPos, width)
---@field GetPoints fun(self:Rectangle, quality:number|nil):Vector[]
---@field GetPaths fun(self:Rectangle, quality:number|nil):Path[]
---@field Contains fun(self:Rectangle, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Intersects fun(self:Circle, geometry: Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Distance fun(self:Rectangle, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):number
---@field IsOnScreen fun(self:Rectangle):boolean
---@field Draw fun(self:Rectangle, color:number|nil):nil
---@field Offseted fun(self:Circle, distance: number):boolean
local Rectangle

---@type fun(startPos: Vector|Rectangle, endPos: Vector, width: number):Rectangle
local rectangleCtor
_G.CoreEx.Geometry.Rectangle = rectangleCtor

--[[
     ██████  ██████  ███    ██ ███████ 
    ██      ██    ██ ████   ██ ██      
    ██      ██    ██ ██ ██  ██ █████   
    ██      ██    ██ ██  ██ ██ ██      
     ██████  ██████  ██   ████ ███████
]]
---@class Cone @Cone(startPos, endPos, radians, radius)
---@field GetPoints fun(self:Cone, quality:number|nil):Vector[]
---@field GetPaths fun(self:Cone, quality:number|nil):Path[]
---@field Contains fun(self:Cone, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Intersects fun(self:Cone, geometry: Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Distance fun(self:Cone, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):number
---@field IsOnScreen fun(self:Cone):boolean
---@field Draw fun(self:Cone, color:number|nil, quality:number|nil):nil
---@field Offseted fun(self:Circle, distance: number):boolean
local Cone

---@type fun(startPos: Vector|Cone, endPos: Vector, radians: number, radius: number):Cone
local coneCtor
_G.CoreEx.Geometry.Cone = coneCtor

--[[
    ██████  ██ ███    ██  ██████  
    ██   ██ ██ ████   ██ ██       
    ██████  ██ ██ ██  ██ ██   ███ 
    ██   ██ ██ ██  ██ ██ ██    ██ 
    ██   ██ ██ ██   ████  ██████  
]]
---@class Ring @Ring(points)
---@field GetPoints fun(self:Ring, quality:number|nil):Vector[]
---@field GetPaths fun(self:Ring, quality:number|nil):Path[]
---@field Contains fun(self:Ring, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Intersects fun(self:Ring, geometry: Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Distance fun(self:Ring, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):number
---@field IsOnScreen fun(self:Ring):boolean
---@field Draw fun(self:Ring, color:number|nil):nil
---@field Offseted fun(self:Ring, distance: number):boolean
local Ring

---@type fun(center: Vector[]|Ring, r_min: number, r_max: number):Ring
local ringCtor
_G.CoreEx.Geometry.Ring = ringCtor

--[[
    ██████   ██████  ██      ██    ██  ██████   ██████  ███    ██ 
    ██   ██ ██    ██ ██       ██  ██  ██       ██    ██ ████   ██ 
    ██████  ██    ██ ██        ████   ██   ███ ██    ██ ██ ██  ██ 
    ██      ██    ██ ██         ██    ██    ██ ██    ██ ██  ██ ██ 
    ██       ██████  ███████    ██     ██████   ██████  ██   ████
]]
---@class Polygon @Polygon(points)
---@field GetPoints fun(self:Polygon, quality:number|nil):Vector[]
---@field GetPaths fun(self:Polygon, quality:number|nil):Path[]
---@field Contains fun(self:Polygon, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Intersects fun(self:Polygon, geometry: Circle|Path|Rectangle|Cone|Polygon):boolean
---@field Distance fun(self:Polygon, geometry: Vector|Circle|Path|Rectangle|Cone|Polygon):number
---@field IsOnScreen fun(self:Polygon):boolean
---@field Draw fun(self:Polygon, color:number|nil):nil
---@field Offseted fun(self:Polygon, distance: number):boolean
local Polygon

---@type fun(points: Vector[]|Polygon):Cone
local polyCtor
_G.CoreEx.Geometry.Polygon = polyCtor

--[[
    ███████ ██████  ███████ ██      ██      
    ██      ██   ██ ██      ██      ██      
    ███████ ██████  █████   ██      ██      
         ██ ██      ██      ██      ██      
    ███████ ██      ███████ ███████ ███████                                         
]]
---@class SpellData
---@field IsValid boolean
---@field SpellFlags integer
---@field SpellAffectFlags integer
---@field SpellAffectFlags2 integer
---@field Name string
---@field AlternateName string
---@field MissileName string
---@field Level integer
---@field IsLearned boolean
---@field ToggleState integer
---@field Ammo number
---@field MaxAmmo number
---@field CooldownExpireTime number
---@field TotalCooldown number
---@field RemainingCooldown number
---@field NextAmmoRechargeTime number
---@field TotalAmmoRechargeTime number
---@field RemainingAmmoRechargeTime number
---@field ManaCost number
---@field DisplayRange number
---@field CastRange number
---@field CastRadius number
---@field CastRadius2 number
---@field LineWidth number
---@field ConeAngle number
---@field ConeRadius number
---@field MissileSpeed number
---@field IsInstant boolean
---@field IsDispellable boolean
---@field IsGrowingRange boolean
local SpellData

---@class SpellCast
---@field Slot integer
---@field SpellData SpellData
---@field CastDelay number
---@field TotalDelay number
---@field StartPos Vector
---@field EndPos Vector
---@field EndPosRelease Vector
---@field Caster AIBaseClient
---@field Source AIBaseClient
---@field Target AttackableUnit
---@field Missile MissileClient
---@field StartTime number
---@field EndTime number
---@field CastEndTime number
---@field IsBasicAttack boolean
---@field IsSpecialAttack boolean
---@field IsBeingCast boolean
---@field IsBeingCharged boolean
---@field StoppedBeingCharged boolean
---@field SpellWasCast boolean
---@field Name string
---@field AlternateName string
---@field MissileName string
---@field MissileSpeed number
---@field SpellFlags integer
---@field SpellAffectFlags integer
---@field SpellAffectFlags2 integer
---@field CastRadius2 number
---@field ConeAngle number
---@field ConeRadius number
---@field LineWidth number
local SpellCast

--[[
    ██████  ██    ██ ███████ ███████     ██ ███    ██ ███████ ████████ 
    ██   ██ ██    ██ ██      ██          ██ ████   ██ ██         ██    
    ██████  ██    ██ █████   █████       ██ ██ ██  ██ ███████    ██    
    ██   ██ ██    ██ ██      ██          ██ ██  ██ ██      ██    ██    
    ██████   ██████  ██      ██          ██ ██   ████ ███████    ██    
]]
---@class BuffInst
---@field IsValid boolean
---@field Name string
---@field Source AIBaseClient
---@field BuffType Enum_BuffTypes
---@field Count integer
---@field StartTime number
---@field EndTime number
---@field Duration number
---@field DurationLeft number
---@field IsCC boolean
---@field IsNotDebuff boolean
---@field IsFear boolean
---@field IsRoot boolean
---@field IsSilence boolean
---@field IsDisarm boolean
local BuffInst

---@class Pathing
---@field Velocity Vector
---@field StartPos Vector
---@field EndPos Vector
---@field IsMoving boolean
---@field IsDashing boolean
---@field DashGravity number
---@field DashSpeed number
---@field CurrentWaypoint integer
---@field Waypoints Vector[]
---@field WaypointCount integer
local Pathing

--[[
     ██████   █████  ███    ███ ███████      ██████  ██████       ██ ███████  ██████ ████████ 
    ██       ██   ██ ████  ████ ██          ██    ██ ██   ██      ██ ██      ██         ██    
    ██   ███ ███████ ██ ████ ██ █████       ██    ██ ██████       ██ █████   ██         ██ 
    ██    ██ ██   ██ ██  ██  ██ ██          ██    ██ ██   ██ ██   ██ ██      ██         ██ 
     ██████  ██   ██ ██      ██ ███████      ██████  ██████   █████  ███████  ██████    ██ 
]]

---@class GameObject
---@field IsValid boolean
---@field Ptr Pointer
---@field Handle Handle_t
---@field IsMe boolean
---@field IsNeutral boolean
---@field IsAlly boolean
---@field IsEnemy boolean
---@field IsMonster boolean
---@field TeamId integer
---@field Name string
---@field IsOnScreen boolean
---@field IsDead boolean
---@field IsZombie boolean
---@field TypeFlags integer
---@field IsParticle boolean
---@field IsMissile boolean
---@field IsAttackableUnit boolean
---@field IsAI boolean
---@field IsMinion boolean
---@field IsHero boolean
---@field IsTurret boolean
---@field IsNexus boolean
---@field IsInhibitor boolean
---@field IsBarracks boolean
---@field IsStructure boolean
---@field IsShop boolean
---@field IsWard boolean
---@field AsAI AIBaseClient
---@field AsHero AIHeroClient
---@field AsTurret AITurretClient
---@field AsMinion AIMinionClient
---@field AsMissile MissileClient
---@field AsAttackableUnit AttackableUnit
---@field IsVisible boolean
---@field BoundingRadius number
---@field Distance fun(self: GameObject, p2: Vector):number
---@field EdgeDistance fun(self: GameObject, p2: Vector):number
---@field BBoxMin Vector
---@field BBoxMax Vector
---@field Position Vector
---@field Orientation Vector
---@field IsInGrass boolean @true if obj is in brush
---@field IsInBaronPit boolean
---@field IsInDragonPit boolean
---@field IsInTopLane boolean
---@field IsInMidLane boolean
---@field IsInBotLane boolean
---@field IsInRiver boolean
---@field IsInJungle boolean
---@field IsInAllyJungle boolean @true if obj is inside LocalPlayer's Jungle
---@field IsInEnemyJungle boolean @true if obj is inside LocalPlayer's Enemy Jungle
---@field IsInBase boolean @true if obj is inside LocalPlayer's Base
---@field IsInEnemyBase boolean @true if obj is inside LocalPlayer's Enemy Base
---@field MapArea table @{Team="Order"|"Chaos"|"Neutral", Area="Base"|"TopLane"|"MidLane"|"BotLane"|"TopJungle"|"BotJungle"|"TopRiver"|"BotRiver"|"DragonPit"|"BaronPit"}
---@field TeamName string @"Order"|"Chaos"|"Neutral"
local GameObject

--[[
     █████  ████████ ████████  █████   ██████ ██   ██  █████  ██████  ██      ███████ 
    ██   ██    ██       ██    ██   ██ ██      ██  ██  ██   ██ ██   ██ ██      ██      
    ███████    ██       ██    ███████ ██      █████   ███████ ██████  ██      █████   
    ██   ██    ██       ██    ██   ██ ██      ██  ██  ██   ██ ██   ██ ██      ██      
    ██   ██    ██       ██    ██   ██  ██████ ██   ██ ██   ██ ██████  ███████ ███████
]]
---@class AttackableUnit : GameObject
---@field Health number
---@field MaxHealth number
---@field HealthPercent number
---@field Mana number
---@field MaxMana number
---@field ManaPercent number
---@field ShieldAll number
---@field ShieldAD number
---@field ShieldAP number
---@field FirstResource number
---@field FirstResourceMax number
---@field SecondResource number
---@field SecondResourceMax number
---@field IsTargetable boolean
---@field IsInvulnerable boolean
---@field IsAlive boolean
---@field Owner AIHeroClient
local AttackableUnit

--[[
     █████  ██ ██████   █████  ███████ ███████ 
    ██   ██ ██ ██   ██ ██   ██ ██      ██      
    ███████ ██ ██████  ███████ ███████ █████   
    ██   ██ ██ ██   ██ ██   ██      ██ ██      
    ██   ██ ██ ██████  ██   ██ ███████ ███████  
]]
---@class AIBaseClient  : AttackableUnit
---@field CanMove boolean
---@field CanAttack boolean
---@field CanCast boolean
---@field IsImmovable boolean
---@field IsStealthed boolean
---@field IsTaunted boolean
---@field IsFeared boolean
---@field IsFleeing boolean
---@field IsSurpressed boolean
---@field IsAsleep boolean
---@field IsNearSighted boolean
---@field IsGhosted boolean
---@field IsGhostProof boolean
---@field IsCharmed boolean
---@field IsSlowed boolean
---@field IsGrounded boolean
---@field IsDodgingMissiles boolean
---@field PercentCooldownMod number
---@field PercentCooldownCapMod number
---@field AbilityHasteMod number
---@field PassiveCooldownEndTime number
---@field PassiveCooldownTotalTime number
---@field FlatPhysicalDamageMod number
---@field PercentPhysicalDamageMod number
---@field PercentBonusPhysicalDamageMod number
---@field PercentBasePhysicalDamageMod number
---@field FlatMagicalDamageMod number
---@field PercentMagicalDamageMod number
---@field FlatMagicReduction number
---@field PercentMagicReduction number
---@field FlatCastRangeMod number
---@field AttackSpeedMod number
---@field BaseAttackDamage number
---@field FlatBaseAttackDamageMod number
---@field PercentBaseAttackDamageMod number
---@field BaseAbilityDamage number
---@field CritDamageMultiplier number
---@field DodgeChance number
---@field CritChance number
---@field Armor number
---@field BonusArmor number
---@field SpellBlock number
---@field BonusSpellBlock number
---@field HealthRegen number
---@field BaseHealthRegen number
---@field MoveSpeed number
---@field MoveSpeedBaseIncrease number
---@field AttackRange number
---@field FlatArmorPen number
---@field PhysicalLethality number
---@field PercentArmorPen number
---@field PercentBonusArmorPen number
---@field PercentCritBonusArmorPen number
---@field PercentCritTotalArmorPen number
---@field FlatMagicPen number
---@field MagicalLethality number
---@field PercentMagicPen number
---@field PercentBonusMagicPen number
---@field PercentLifeStealMod number
---@field PercentSpellVampMod number
---@field PercentCCReduction number
---@field PercentEXPBonus number
---@field ManaRegen number
---@field PrimaryResourceRegen number
---@field PrimaryResourceBaseRegen number
---@field SecondaryResourceRegen number
---@field SecondaryResourceBaseRegen number
---@field IsMoving boolean
---@field IsCasting boolean
---@field IsWindingUp boolean
---@field IsChanneling boolean
---@field IsRanged boolean
---@field IsMelee boolean
---@field SkinId integer @Not Implemented
---@field AttackData SpellCast
---@field AttackData2 SpellCast
---@field BaseAD number
---@field BonusAD number
---@field TotalAD number
---@field BaseAP number
---@field BonusAP number
---@field TotalAP number
---@field IsHerald boolean
---@field IsRedBuff boolean
---@field IsBlueBuff boolean
---@field IsBaron boolean
---@field IsDragon boolean
---@field CharName string
---@field BaseHealth number
---@field BonusHealth number
---@field AttackDelay number
---@field AttackCastDelay number
---@field ActiveSpell SpellCast
---@field Pathing Pathing
---@field ServerPos Vector
---@field HealthBarScreenPos Vector
---@field BuffCount integer
---@field Buffs BuffInst[] @{[buffName_lower] = Buff}
---@field Direction Vector
---@field TimeUntilRespawn number
---@field FastPrediction fun(self: AIBaseClient, delay_ms: number):Vector
---@field GetSpell fun(self: AIBaseClient, slot: integer):SpellData|nil
---@field GetSpellState fun(self: AIBaseClient, slot: integer):number
---@field GetBuff fun(self: AIBaseClient, index_or_name: integer|string):BuffInst|nil
---@field GetBuffCount fun(self: AIBaseClient, index_or_name: string):number
---@field IsFacing fun(self: AIBaseClient, pos_or_obj:Vector|GameObject, max_degrees:number|nil):boolean
---@field GetBuffsOfType fun(self: AIBaseClient, buffType: Enum_BuffTypes):BuffInst[] @{[buffName_lower] = Buff}
---@field HasBuffOfType fun(self: AIBaseClient, buffType: Enum_BuffTypes):boolean
---@field HasBuffOfTypeList fun(self: AIBaseClient, buffTypes: Enum_BuffTypes[]):boolean @buffTypes={Enums.BuffTypes.Stun, Enums.BuffTypes.Taunt, ...}
local AIBaseClient

--[[
     █████  ██ ██   ██ ███████ ██████   ██████  
    ██   ██ ██ ██   ██ ██      ██   ██ ██    ██ 
    ███████ ██ ███████ █████   ██████  ██    ██ 
    ██   ██ ██ ██   ██ ██      ██   ██ ██    ██ 
    ██   ██ ██ ██   ██ ███████ ██   ██  ██████   
]]
---@class AIHeroClient  : AIBaseClient
---@field RespawnTime number
---@field Experience number
---@field Level number
---@field Gold number
---@field TotalGold number
---@field VisionScore number
---@field IsRecalling boolean
---@field IsTeleporting boolean
---@field IsInFountain boolean
---@field Perks table @{[perkId] = perkName}
---@field Items Item[] @{[itemSlot] = item}
---@field RecallInfo string
---@field HasPerk fun(id_or_name: number|string):boolean
---@field IsSpellEvolved fun(slot:Enum_SpellSlots):boolean
---@field CanLevelSpell fun(slot:Enum_SpellSlots):boolean
---@field CanEvolveSpell fun(slot:Enum_SpellSlots):boolean
---@field CountAlliesInRange fun(range:number):boolean @Allies of the unit, not player
---@field CountEnemiesInRange fun(range:number):boolean @Enemies of the unit, not player
local AIHeroClient

--[[
     █████  ██ ███    ███ ██ ███    ██ ██  ██████  ███    ██ 
    ██   ██ ██ ████  ████ ██ ████   ██ ██ ██    ██ ████   ██ 
    ███████ ██ ██ ████ ██ ██ ██ ██  ██ ██ ██    ██ ██ ██  ██ 
    ██   ██ ██ ██  ██  ██ ██ ██  ██ ██ ██ ██    ██ ██  ██ ██ 
    ██   ██ ██ ██      ██ ██ ██   ████ ██  ██████  ██   ████ 
]]
---@class AIMinionClient  : AIBaseClient
---@field IsPet boolean
---@field IsLaneMinion boolean
---@field IsEpicMinion boolean
---@field IsEliteMinion boolean
---@field IsScuttler boolean
---@field IsSiegeMinion boolean
---@field IsSuperMinion boolean
---@field IsJunglePlant boolean
---@field IsBarrel boolean
---@field IsSennaSoul boolean
---@field BonusDamageToMinions number
---@field ReducedDamageFromMinions number
local AIMinionClient

--[[
     █████  ██ ████████ ██    ██ ██████  ██████  ███████ ████████ 
    ██   ██ ██    ██    ██    ██ ██   ██ ██   ██ ██         ██    
    ███████ ██    ██    ██    ██ ██████  ██████  █████      ██    
    ██   ██ ██    ██    ██    ██ ██   ██ ██   ██ ██         ██    
    ██   ██ ██    ██     ██████  ██   ██ ██   ██ ███████    ██   
]]
---@class AITurretClient  : AIBaseClient
---@field Tier '"Fountain"'|'"Inhibitor"'|'"T2"'|'"T1"'|'"Nexus1"'|'"Nexus2"'
local AITurretClient

--[[
    ███    ███ ██ ███████ ███████ ██ ██      ███████ 
    ████  ████ ██ ██      ██      ██ ██      ██      
    ██ ████ ██ ██ ███████ ███████ ██ ██      █████   
    ██  ██  ██ ██      ██      ██ ██ ██      ██      
    ██      ██ ██ ███████ ███████ ██ ███████ ███████    
]]
---@class MissileClient  : GameObject
---@field StartPos Vector
---@field EndPos Vector
---@field CasterDirection Vector
---@field StartTime number
---@field CastEndTime number
---@field EndTime number
---@field IsBasicAttack boolean
---@field IsSpecialAttack boolean
---@field Caster AIBaseClient
---@field Source AIBaseClient
---@field Target AttackableUnit
---@field Width number
---@field Speed number
---@field SpellCastInfo SpellCast
local MissileClient

---_G.CoreEx.ObjectManager
---@class ObjectManager
---@field Player AIHeroClient
---@field Get fun(_team: string , _type:string):table<Handle_t, GameObject> @_team: {all, ally, enemy, neutral, no_team}, _type:{heroes, minions, turrets, inhibitors, hqs, wards, particles, missiles, others}
---@field GetNearby fun(_team: string , _type:string):GameObject[] @Objects within 1500 range _team: {all, ally, enemy, neutral, no_team}, _type:{heroes, minions, turrets, inhibitors, hqs, wards, particles, missiles, others}
---@field GetObjectByHandle fun(handle: Handle_t):GameObject
local ObjectManager
_G.CoreEx.ObjectManager = ObjectManager

--[[
    ██ ███    ██ ██████  ██    ██ ████████ 
    ██ ████   ██ ██   ██ ██    ██    ██    
    ██ ██ ██  ██ ██████  ██    ██    ██    
    ██ ██  ██ ██ ██      ██    ██    ██    
    ██ ██   ████ ██       ██████     ██    
]]
---_G.CoreEx.Input
local Input = {}
---@overload fun(slot: integer, Target:AttackableUnit):boolean
---@overload fun(slot: integer, TargetPos:Vector):boolean
---@overload fun(slot: integer, TargetPos:Vector, StartPos:Vector):boolean
---@param slot integer
---@return boolean
function Input.Cast(slot) end
---@param target AttackableUnit
---@return boolean
function Input.Attack(target) end
---@return boolean
function Input.HoldPosition() end
---@param pos Vector
---@return boolean
function Input.MoveTo(pos) end
---@param slot integer
---@param pos Vector|nil
---@return boolean
function Input.Release(slot, pos) end
---@param slot Enum_SpellSlots
---@return boolean
function Input.LevelSpell(slot) end
_G.CoreEx.Input = Input

--[[
    ██████  ███████ ███    ██ ██████  ███████ ██████  ███████ ██████  
    ██   ██ ██      ████   ██ ██   ██ ██      ██   ██ ██      ██   ██ 
    ██████  █████   ██ ██  ██ ██   ██ █████   ██████  █████   ██████  
    ██   ██ ██      ██  ██ ██ ██   ██ ██      ██   ██ ██      ██   ██ 
    ██   ██ ███████ ██   ████ ██████  ███████ ██   ██ ███████ ██   ██ 
]]

---@class Sprite
---@field SetScale fun(newWidth: number, newHeight: number):nil @Call Once When you Want To Resize The Sprite
---@field SetMask fun(p_min: Vector, p_max: Vector):nil @Call Once When you Want To Change The Sprite Mask
---@field SetColor fun(rgba: integer):nil @Call Once When you Want To Recolor The Sprite
---@field Draw fun(screenPos: Vector, radius: integer|nil, centered: boolean|nil):nil @Call on OnDraw
---@field NewFromMask fun(p_min: Vector, p_max: Vector):nil @Call Once When you Want To Create A New Sprite From Mask
local Sprite

---@class Renderer
---@field DrawCircle fun(center: Vector, radius: integer, thickness: integer|nil, color:integer|nil, filled:boolean|nil):nil
---@field DrawCircleMM fun(center:Vector, radius: integer, thickness:integer|nil, color:integer|nil, filled:boolean|nil):nil
---@field DrawCircle3D fun(center:Vector, radius: integer, quality:integer, thickness:integer|nil, color:integer|nil):nil
---@field DrawLine fun(pos1:Vector, pos2:Vector, thickness:integer|nil, color:integer|nil):nil
---@field DrawLine3D fun(pos1:Vector, pos2:Vector, thickness:integer|nil, color:integer|nil):nil
---@field DrawText fun(pos:Vector, size:Vector, text:string, color:integer):nil
---@field DrawTextOnTopLeft fun(text:string, color:integer):nil
---@field DrawTextOnPlayer fun(text:string, color:integer):nil
---@field DrawRectOutline fun(pos:Vector, size:Vector, rounding:integer, thickness:integer, color:integer):nil
---@field DrawRectOutline3D fun(start:Vector, end:Vector, width:integer, thickness:integer, color:integer):nil
---@field DrawFilledRect fun(pos:Vector, size:Vector, rounding:integer, color:integer):nil
---@field DrawFilledRect3D fun(start:Vector, end:Vector, width:integer, color:integer):nil
---@field IsOnScreen fun(pos: Vector):boolean
---@field IsOnScreen2D fun(pos: Vector):boolean
---@field WorldToScreen fun(pos: Vector):Vector
---@field WorldToMinimap fun(pos: Vector):Vector
---@field MinimapToWorld fun(pos: Vector):Vector
---@field GetResolution fun():Vector
---@field GetMousePos fun():Vector
---@field CalcTextSize fun(text: string):Vector
---@field CreateSprite fun(relPath: string, width: integer, height: integer):Sprite @(eg. path relative to sprite folder or relPath="assets/characters/aatrox/hud/aatrox_circle.png" view path on https://raw.communitydragon.org/latest/game/). Call Only Once Per Sprite! 
local Renderer 
_G.CoreEx.Renderer = Renderer

--[[
     ██████   █████  ███    ███ ███████ 
    ██       ██   ██ ████  ████ ██      
    ██   ███ ███████ ██ ████ ██ █████   
    ██    ██ ██   ██ ██  ██  ██ ██      
     ██████  ██   ██ ██      ██ ███████ 
]]
---@class Game
---@field GetTime fun():number
---@field GetLatency fun():integer
---@field IsMinimized fun():boolean
---@field IsChatOpen fun():boolean
---@field IsShopOpen fun():boolean
---@field GetTeamDragonCount fun(team: number, dragonType: Enums_DragonTypes)
---@field IsTFT fun():boolean
---@field IsRankedGame fun():boolean
---@field IsCustomGame fun():boolean
---@field GetMapID fun():Enums_GameMaps
---@field GetGameMode fun():string @"CLASSIC", "ARAM", "URF", "ONEFORALL", "NEXUSBLITZ", "PRACTICETOOL"
---@field GetQueueType fun():string @"UNKNOWN", "CUSTOM", "HA_NORMAL_ARAM", "SR_SPECIAL_URF", "SR_SPECIAL_AR", "SR_SPECIAL_OFA", "SR_NORMAL_CLASH", "SR_NORMAL_DRAFT", "SR_NORMAL_BLIND", "SR_RANKED_SOLO", "SR_RANKED_FLEX", "SR_TUTO_1", "SR_TUTO_2", "SR_TUTO_3", "TFT", "TFT_RANKED"
local Game
_G.CoreEx.Game = Game

--[[
    ███    ██  █████  ██    ██     ███    ███ ███████ ███████ ██   ██ 
    ████   ██ ██   ██ ██    ██     ████  ████ ██      ██      ██   ██ 
    ██ ██  ██ ███████ ██    ██     ██ ████ ██ █████   ███████ ███████ 
    ██  ██ ██ ██   ██  ██  ██      ██  ██  ██ ██           ██ ██   ██ 
    ██   ████ ██   ██   ████       ██      ██ ███████ ███████ ██   ██ 
]]
---@class Nav
---@field WorldToCell fun(worldPos:Vector):Vector
---@field CellToWorld fun(x: number, z:number):Vector
---@field GetTerrainHeight fun(worldPos:Vector):number
---@field IsWall fun(worldPos:Vector):boolean
---@field IsGrass fun(worldPos:Vector):boolean
---@field IsWithinTheMap fun(worldPos:Vector):boolean
---@field GetCellSize fun():number
---@field GetCellCount fun():Vector
---@field GetMapArea fun(pos:Vector):table @returns {Team="Order"|"Chaos"|"Neutral", Area="Base"|"TopLane"|"MidLane"|"BotLane"|"TopJungle"|"BotJungle"|"TopRiver"|"BotRiver"|"DragonPit"|"BaronPit"}
local Nav
_G.CoreEx.Nav = Nav

--[[
    ██ ████████ ███████ ███    ███ 
    ██    ██    ██      ████  ████ 
    ██    ██    █████   ██ ████ ██ 
    ██    ██    ██      ██  ██  ██ 
    ██    ██    ███████ ██      ██ 
]]
---@class Item
---@field Name string
---@field ItemId integer 
---@field CurrentStacks integer @eg. Number of Pots   
---@field MaxStacks integer  @eg. Max Pots In Slot (5)
---@field Count number @eg. Current Active Wards     
---@field MaxCount number @eg. Max Active Wards  
---@field Duration number @eg. 90 
---@field RechargeTime number @eg. 240
---@field Charges number @eg. DeadManPlate's Charges
---@field MaxCharges number @eg. 2 
---@field HasActiveAbility boolean    
local Item

--[[
    ███████ ██    ██ ███████ ███    ██ ████████ ███    ███  █████  ███    ██  █████   ██████  ███████ ██████  
    ██      ██    ██ ██      ████   ██    ██    ████  ████ ██   ██ ████   ██ ██   ██ ██       ██      ██   ██ 
    █████   ██    ██ █████   ██ ██  ██    ██    ██ ████ ██ ███████ ██ ██  ██ ███████ ██   ███ █████   ██████  
    ██       ██  ██  ██      ██  ██ ██    ██    ██  ██  ██ ██   ██ ██  ██ ██ ██   ██ ██    ██ ██      ██   ██ 
    ███████   ████   ███████ ██   ████    ██    ██      ██ ██   ██ ██   ████ ██   ██  ██████  ███████ ██   ██ 
]]
---@class EventManager 
---@field EventExists fun(event: string):boolean           
---@field RegisterEvent fun(event: string):nil         
---@field RemoveEvent fun(event: string):nil  
---@field FireEvent fun(event: string, var_args:any):nil         
---@field RegisterCallback fun(event: string, func: function):nil @see Enums.Events
---@field RemoveCallback fun(event: string, func: function):nil   @see Enums.Events
local EventManager
_G.CoreEx.EventManager = EventManager

--[[
    ███████ ███    ██ ██    ██ ███    ███ ███████ 
    ██      ████   ██ ██    ██ ████  ████ ██      
    █████   ██ ██  ██ ██    ██ ██ ████ ██ ███████ 
    ██      ██  ██ ██ ██    ██ ██  ██  ██      ██ 
    ███████ ██   ████  ██████  ██      ██ ███████
]]
---@class Enum_AbilityResourceTypes
---@field Mana integer
---@field Energy integer
---@field Shield integer
---@field Battlefury integer
---@field Dragonfury integer
---@field Rage integer
---@field Heat integer
---@field Gnarfury integer
---@field Ferocity integer
---@field BloodWell integer
---@field Wind integer
---@field Ammo integer
---@field Other integer
local AbilityResourceTypes
_G.CoreEx.Enums.AbilityResourceTypes = AbilityResourceTypes

---@class Enum_DamageTypes
---@field Physical integer
---@field Magical integer
---@field Mixed integer
---@field True integer
local DamageTypes 
_G.CoreEx.Enums.DamageTypes = DamageTypes

---@class Enum_BuffTypes
---@field Internal integer
---@field Aura integer
---@field CombatEnchancer integer
---@field CombatDehancer integer
---@field SpellShield integer
---@field Stun integer
---@field Invisibility integer
---@field Silence integer
---@field Taunt integer
---@field Berserk integer
---@field Polymorph integer
---@field Slow integer
---@field Snare integer
---@field Damage integer
---@field Heal integer
---@field Haste integer
---@field SpellImmunity integer
---@field PhysicalImmunity integer
---@field Invulnerability integer
---@field AttackSpeedSlow integer
---@field NearSight integer
---@field Currency integer
---@field Fear integer
---@field Charm integer
---@field Poison integer
---@field Suppression integer
---@field Blind integer
---@field Counter integer
---@field Shred integer
---@field Flee integer
---@field Knockup integer
---@field Knockback integer
---@field Disarm integer
---@field Grounded integer
---@field Drowsy integer
---@field Asleep integer
---@field Obscured integer
---@field ClickproofToEnemies integer
---@field Unkillable integer
local BuffTypes
_G.CoreEx.Enums.BuffTypes = BuffTypes

---@class Enum_ObjectTypeFlags
---@field GameObject integer
---@field NeutralCamp integer
---@field DeadObject integer
---@field InvalidObject integer
---@field AIBaseCommon integer
---@field AI integer
---@field Minion integer
---@field Hero integer
---@field Turret integer
---@field Missile integer
---@field Building integer
---@field AttackableUnit integer
local ObjectTypeFlags
_G.CoreEx.Enums.ObjectTypeFlags = ObjectTypeFlags

---@class Enum_GameObjectOrders
---@field HoldPosition integer
---@field MoveTo integer
---@field AttackUnit integer
---@field AutoAttackPet integer
---@field AutoAttack integer
---@field MovePet integer
---@field AttackTo integer
---@field Stop integer
---@field StopPet integer
local GameObjectOrders
_G.CoreEx.Enums.GameObjectOrders = GameObjectOrders

---@class Enum_Teams
---@field None integer
---@field Order integer
---@field Chaos integer
---@field Neutral integer
local Teams
_G.CoreEx.Enums.Teams = Teams

---@class Enum_SpellSlots
---@field Unknown integer
---@field Q integer
---@field W integer
---@field E integer
---@field R integer
---@field Summoner1 integer
---@field Summoner2 integer
---@field Item1 integer
---@field Item2 integer
---@field Item3 integer
---@field Item4 integer
---@field Item5 integer
---@field Item6 integer
---@field Trinket integer
---@field Recall integer
---@field BasicAttack integer
---@field SecondaryAttack integer
local SpellSlots
_G.CoreEx.Enums.SpellSlots = SpellSlots

---@class Enum_ItemSlots
---@field Unknown integer
---@field Item1 integer
---@field Item2 integer
---@field Item3 integer
---@field Item4 integer
---@field Item5 integer
---@field Item6 integer
---@field Trinket integer
local ItemSlots
_G.CoreEx.Enums.ItemSlots = ItemSlots

---@class Enum_SpellStates
---@field Ready integer
---@field Unknown integer
---@field Invalid integer
---@field NotLearned integer
---@field Disabled integer
---@field CrowdControlled integer
---@field Cooldown integer
---@field NoMana integer
---@field Locked integer
---@field Cooldown2 integer
local SpellStates
_G.CoreEx.Enums.SpellStates = SpellStates

---@class Enum_Events
---@field OnTick string                @[[30FPS]] void OnTick(lagfree) @lagfree is a counter cycling 1, 2, 3, 4, 1, 2..
---@field OnUpdate string              @[[60FPS]] void OnUpdate(lagfree) @lagfree is a counter cycling 1, 2, 3, 4, 5, 6, 7, 8, 1, 2..
---@field OnDraw string                @[[Screen Refresh Rate]] void OnDraw()
---@field OnDrawMenu string            @[[Screen Refresh Rate]] void OnDrawMenu()
---@field OnDrawHUD string             @[[Screen Refresh Rate]] void OnDrawHUD()
---@field OnDrawDamage string          @[[Screen Refresh Rate]] void OnDrawDamage(target, dmgList) @default color: insert(dmgList, number) | custom color > insert(dmgList, {Damage=300, Color=0xFF0000FF})
---@field OnKey string                 @[[KeyPress]] void OnKey(e, message, wparam, lparam)
---@field OnMouseEvent string          @[[KeyPress]] void OnMouseEvent(message, wparam, lparam)
---@field OnKeyDown string             @[[KeyPress]] void OnKeyDown(keycode, char, lparam)
---@field OnKeyUp string               @[[KeyPress]] void OnKeyUp(keycode, char, lparam)
---@field OnCreateObject string        @[[After Creation]] void OnCreateObject(obj)
---@field OnDeleteObject string        @[[Before Deletion]] void OnDeleteObject(obj)
---@field OnCastSpell string           @[[Change/Block Player Casts]] void OnCastSpell(Args) --Args={Process, Slot, TargetPosition, TargetEndPosition, Target}
---@field OnProcessSpell string        @[[Animation Start]] void OnProcessSpell(obj, spellcast)
---@field OnUpdateChargedSpell string  @[[Change Pos/Block Charged Spell]] void OnUpdateChargedSpell(Args) --Args={Spell, TargetPosition, Release} (Can't Change SpellData)
---@field OnSpellCast string           @[[Animation End]] void OnSpellCast(obj, spellcast)
---@field OnCastStop string            @[[Animation Interrupted]] void OnCastStop(sender, spellcast, bStopAnimation, bExecuteCastFrame, bDestroyMissile)   
---@field OnBasicAttack string         @[[Animation Start]] void OnBasicAttack(obj, spellcast)
---@field OnNewPath string             @[[Animation Start]] void OnNewPath(obj, pathing)
---@field OnIssueOrder string          @[[Change/Block Player Orders]] void OnIssueOrder(Args) --Args={Process, Order, Position, Target}
---@field OnBuffUpdate string          @[[After Update]] void OnBuffUpdate(obj, buffInst)
---@field OnBuffGain string            @[[After Creation]] void OnBuffGain(obj, buffInst)
---@field OnBuffLost string            @[[Before Deletion]] void OnBuffLost(obj, buffInst)
---@field OnPlayAnimation string       @[[Before Animation Start]] void PlayAnimation(obj, animationName)
---@field OnVisionGain string          @[[Hero Leaves FOG]] void OnVisionGain(obj)
---@field OnVisionLost string          @[[Hero Enters FOG]] void OnVisionLost(obj)
---@field OnTeleport string            @[[Works in FOG]] void OnTeleport(obj, name, duration_secs, status) --status: "Started", "Finished" or "Interrupted"
---@field OnGameEnd string             @[[Called When Nexus Is Destroyed]] void OnGameEnd(obj) --obj: Destroyed Nexus
---@field OnPreAttack string           @[[Orbwalker Wants To Attack]] void OnPreAttack(args) --args: {Process, Target}
---@field OnPostAttack string          @[[Orbwalker Finished Attacking]] void OnPostAttack(target)
---@field OnPreMove string             @[[Orbwalker Wants To Move]] void OnPreMove(args) --args:{Process, Position}
---@field OnPostMove string            @[[Orbwalker Started Moving]] void OnPostMove(endPosition)
---@field OnUnkillableMinion string    @[[Orbwalker Cant Kill a Minion]] void OnUnkillableMinion(minion)
---@field OnGapclose string            @[[Source Is Dashing/Blinking]] void OnGapClose(Source, DashInstance)
---@field OnInterruptibleSpell string  @[[Source Is Channelling]] void OnInterruptibleSpell(Source, SpellCast, Danger, EndTime, CanMoveDuringChannel)
---@field OnHeroImmobilized string     @[[Source Is Casting/CCed]] void OnHeroImmobilized(Source, EndTime, IsStasis)
---@field OnExtremePriority string     @[[Improved OnTick]] void OnExtremePriority(lagfree) --Evade, Autosmite, etc @lagfree is a counter cycling 1, 2, 3, 4, 5, 6, 7, 8, 1, 2..
---@field OnHighPriority string        @[[Improved OnTick]] void OnHighPriority(lagfree) --important spells etc @lagfree is a counter cycling 1, 2, 3, 4, 1, 2..
---@field OnNormalPriority string      @[[Improved OnTick]] void OnNormalPriority(lagfree) --Orbwalker, Normal Spells @lagfree is a counter cycling 1, 2, 3, 4, 1, 2..
---@field OnLowPriority string         @[[Improved OnTick]] void OnLowPriority(lagfree) -Pseudo-Useless Spells @lagfree is a counter cycling 1, 2, 3, 4, 1, 2..
---@field OnAttackReset string
---@field OnOrbwalkerPreTick string
---@field OnOrbwalkerNewTarget string
local Events
_G.CoreEx.Enums.Events = Events

---@class PerkIDs
---@field PressTheAttack number
---@field LethalTempo number
---@field FleetFootwork number
---@field Conqueror number
---@field Overheal number
---@field Triumph number
---@field PresenceOfMind number
---@field LegendAlacrity number
---@field LegendTenacity number
---@field LegendBloodline number
---@field CoupdeGrace number
---@field CutDown number
---@field LastStand number
---@field Electrocute number
---@field Predator number
---@field DarkHarvest number
---@field HailOfBlades number
---@field CheapShot number
---@field TasteofBlood number
---@field SuddenImpact number
---@field ZombieWard number
---@field GhostPoro number
---@field EyeballCollection number
---@field RavenousHunter number
---@field IgeniousHunter number
---@field RelentlessHunter number
---@field UltimateHunter number
---@field SummonAery number
---@field ArcaneComet number
---@field PhaseRush number
---@field NullifyingOrb number
---@field ManaflowBand number
---@field NimbusCloak number
---@field Transcendence number
---@field Celerity number
---@field AbsoluteFocus number
---@field Scorch number
---@field Waterwalking number
---@field GatheringStorm number
---@field GraspoftheUndying number
---@field Aftershock number
---@field Guardian number
---@field Demolish number
---@field FontofLife number
---@field ShieldBash number
---@field Conditioning number
---@field SecondWind number
---@field BonePlating number
---@field Overgrowth number
---@field Revitalize number
---@field Unflinching number
---@field GlacialAugment number
---@field UnsealedSpellbook number
---@field PrototypeOmnistone number
---@field HextechFlash number
---@field MagicalFootwear number
---@field PerfectTiming number
---@field FutureMarket number
---@field MinionDematerializer number
---@field BiscuitDelivery number
---@field CosmicInsight number
---@field ApproachVelocity number
---@field TimeWarpTonic number
---@field CDRScaling number
---@field AttackSpeed number
---@field AdaptiveForce number
---@field Armor number
---@field Health number
---@field MagicResist number
local PerkIDs
_G.CoreEx.Enums.PerkIDs = PerkIDs

---@class Enums_HitChance
---@field Collision number
---@field OutOfRange number
---@field VeryLow number
---@field Low number
---@field Medium number
---@field High number
---@field VeryHigh number
---@field Dashing number
---@field Immobile number
local HitChance
_G.CoreEx.Enums.HitChance = HitChance

---@class Enums_GameMaps
---@field NexusBlitz number
---@field Convergence number
---@field HowlingAbyss number
---@field SummonersRift number
---@field ProvingGrounds number
local GameMaps
_G.CoreEx.Enums.GameMaps = GameMaps

---@class Enums_QueueTypes
---@field UNKNOWN number
---@field CUSTOM number
---@field HA_NORMAL_ARAM number
---@field SR_SPECIAL_URF number
---@field SR_SPECIAL_AR number
---@field SR_SPECIAL_OFA number
---@field SR_NORMAL_CLASH number
---@field SR_NORMAL_DRAFT number
---@field SR_NORMAL_BLIND number
---@field SR_RANKED_SOLO number
---@field SR_RANKED_FLEX number
---@field SR_TUTO_1 number
---@field SR_TUTO_2 number
---@field SR_TUTO_3 number
---@field TFT number
---@field TFT_RANKED number
local QueueTypes
_G.CoreEx.Enums.QueueTypes = QueueTypes

---@class Enums_DragonTypes
---@field All number
---@field Hextech number
---@field Fire number
---@field Air number
---@field Water number
---@field Earth number
---@field Elder number
local DragonTypes
_G.CoreEx.Enums.DragonTypes = DragonTypes

--[[
    ██████   █████  ███████ ██   ██     ██      ██ ██████  
    ██   ██ ██   ██ ██      ██   ██     ██      ██ ██   ██ 
    ██   ██ ███████ ███████ ███████     ██      ██ ██████  
    ██   ██ ██   ██      ██ ██   ██     ██      ██ ██   ██ 
    ██████  ██   ██ ███████ ██   ██     ███████ ██ ██████  
]]
---@class DashPath
---@field StartPos Vector
---@field EndPos Vector
---@field Delay number
---@field EndDelay number
---@field Speed number
---@field StartTime number
---@field DashTime number
---@field EndTime number @StartTime + Delay + DashTime + EndDelay
local DashPath

---@class DashInstance
---@field Slot number
---@field Range number
---@field Delay number
---@field EndDelay number
---@field StartTime number
---@field Target AIBaseClient
---@field StartPos Vector
---@field FixedRange boolean @Whether Dash Is Always Cast At Max Range
---@field IsBlink boolean
---@field IsGapClose boolean @Wheter Its an intentional Dash or unintentional (Knockback etc)
---@field IsTargeted boolean
---@field Invulnerable boolean @Wheter Target Is Invulnerable Until EndDelay
---@field GetPaths fun(self:DashInstance):DashPath[]
---@field GetSpeed fun(self:DashInstance):number
---@field GetPosition fun(self:DashInstance, delay: number|nil):Vector
---@field Prediction fun(self:DashInstance, FromPos:Vector, Speed: number, Delay: number, Radius: number, UseHitbox:boolean, IsTrap:boolean):Vector, number @colisionPos, flightTime
local DashInstance

---@class DashLib
---@field GetDash fun(Obj: AIHeroClient):DashInstance|nil @returns nil if target isnt dashing/blinking
---@field IsDash fun(charName:string, spellName:string):boolean
local DashLib
_G.Libs.DashLib = DashLib

---@class ImmobileLib
---@field GetChannelBeingCast fun(unit: AIHeroClient):table @{Caster, EndTime, CanMove, Danger}  
---@field GetImmobileTimeLeft fun(unit: AIHeroClient):number
local ImmobileLib
_G.Libs.ImmobileLib = ImmobileLib

--[[
    ██████   █████  ███    ███  █████   ██████  ███████     ██      ██ ██████  
    ██   ██ ██   ██ ████  ████ ██   ██ ██       ██          ██      ██ ██   ██ 
    ██   ██ ███████ ██ ████ ██ ███████ ██   ███ █████       ██      ██ ██████  
    ██   ██ ██   ██ ██  ██  ██ ██   ██ ██    ██ ██          ██      ██ ██   ██ 
    ██████  ██   ██ ██      ██ ██   ██  ██████  ███████     ███████ ██ ██████  
]]
---@class DamageLib
---@field CalculatePhysicalDamage fun(source:AIBaseClient, target: AttackableUnit, rawDmg: number):number
---@field CalculateMagicalDamage fun(source:AIBaseClient, target: AttackableUnit, rawDmg: number):number
---@field GetStaticAutoAttackDamage fun(source:AIBaseClient, isMinionTarget:boolean):table @Use this when you'll call GetAutoAttackDamage multiple times (memoization)
---@field GetAutoAttackDamage fun(source:AIBaseClient, target: AttackableUnit, checkPassives:boolean, staticDamage:table|nil):number
local DamageLib
_G.Libs.DamageLib = DamageLib

--[[
    ██   ██ ███████  █████  ██    ████████ ██   ██  ██████  ██████  ███████ ██████  
    ██   ██ ██      ██   ██ ██       ██    ██   ██  ██   ██ ██   ██ ██      ██   ██ 
    ███████ █████   ███████ ██       ██    ███████  ██████  ██████  █████   ██   ██ 
    ██   ██ ██      ██   ██ ██       ██    ██   ██  ██      ██   ██ ██      ██   ██ 
    ██   ██ ███████ ██   ██ ███████  ██    ██   ██  ██      ██   ██ ███████ ██████   
]]
---@class HealthPred
---@field GetDamagePrediction fun(Target:AttackableUnit, Time: number, SimulateDmg: boolean):number, number, number @returns dmgPred, maxIncomingDmg, incomingDmgCount / SimulateDmg: extrapolates attacks that havent started yet
---@field GetHealthPrediction fun(Target:AttackableUnit, Time: number, SimulateDmg: boolean):number, number, number @returns hpPred, maxIncomingDmg, incomingDmgCount / SimulateDmg: extrapolates attacks that havent started yet
---@field GetKillstealHealth fun(Target:AIHeroClient, Time: number, DmgType: Enum_DamageTypes):number
local HealthPred
_G.Libs.HealthPred = HealthPred

--[[
     ██████  ██████  ██      ██      ██ ███████ ██  ██████  ███    ██     ██      ██ ██████  
    ██      ██    ██ ██      ██      ██ ██      ██ ██    ██ ████   ██     ██      ██ ██   ██ 
    ██      ██    ██ ██      ██      ██ ███████ ██ ██    ██ ██ ██  ██     ██      ██ ██████  
    ██      ██    ██ ██      ██      ██      ██ ██ ██    ██ ██  ██ ██     ██      ██ ██   ██ 
     ██████  ██████  ███████ ███████ ██ ███████ ██  ██████  ██   ████     ███████ ██ ██████  
]]

---@class CollisionResult
---@field Result boolean
---@field Positions Vector[]
---@field Objects GameObject[]
local CollisionResult

---@class CollisionLib
---@field SearchWall fun(startPos: Vector, endPos: Vector, width: number, speed: number, delay_ms: number):CollisionResult
---@field SearchHeroes fun(startPos: Vector, endPos: Vector, width: number, speed: number, delay_ms: number, maxResults: integer, allyOrEnemy: '"ally"'|'"enemy"', handlesToIgnore: number[]):CollisionResult
---@field SearchMinions fun(startPos: Vector, endPos: Vector, width: number, speed: number, delay_ms: number, maxResults: integer, allyOrEnemy: '"ally"'|'"enemy"', handlesToIgnore: number[]):CollisionResult
---@field SearchYasuoWall fun(startPos: Vector, endPos: Vector, width: number, speed: number, delay_ms: number, maxResults: integer, allyOrEnemy: '"ally"'|'"enemy"'):CollisionResult
local CollisionLib
_G.Libs.CollisionLib = CollisionLib

--[[
    ██████  ██████  ███████ ██████  ██  ██████ ████████ ██  ██████  ███    ██ 
    ██   ██ ██   ██ ██      ██   ██ ██ ██         ██    ██ ██    ██ ████   ██ 
    ██████  ██████  █████   ██   ██ ██ ██         ██    ██ ██    ██ ██ ██  ██ 
    ██      ██   ██ ██      ██   ██ ██ ██         ██    ██ ██    ██ ██  ██ ██ 
    ██      ██   ██ ███████ ██████  ██  ██████    ██    ██  ██████  ██   ████ 
]]
---@class PredictionInput
---@field Range number
---@field Radius number @This is Width/2 for Linear Spells
---@field Speed number
---@field Delay number
---@field Type '"Circular"'|'"Linear"'|'"Cone"'
---@field ConeAngleRad number|nil
---@field MinHitChance number|nil
---@field MinHitChanceEnum Enums_HitChance|nil
---@field Collisions table|nil @{Heroes=true, Minions=true, WindWall=true, Wall=true}
---@field MaxCollisions number|nil
---@field IsTrap boolean|nil
---@field UseHitbox boolean|nil
---@field EffectRadius number|nil @When Spell Does Extra Damage/Effect Within X Radius (Eg. Xerath W)
local PredictionInput

---@class PredictionResult
---@field CollisionTime number
---@field CastPosition Vector
---@field TargetPosition Vector
---@field HitChance number
---@field HitChanceEnum number
---@field CollisionCount number
---@field CollisionObjects GameObject[]
---@field CollisionPoints Vector[]
local PredictionResult

---@class Prediction
---@field GetPredictedPosition fun(target: AIBaseClient, input: PredictionInput, source: Vector):PredictionResult
local Prediction
_G.Libs.Prediction = Prediction

--[[
    ████████  █████  ██████   ██████  ███████ ████████     ███████ ███████ ██      ███████  ██████ ████████  ██████  ██████  
       ██    ██   ██ ██   ██ ██       ██         ██        ██      ██      ██      ██      ██         ██    ██    ██ ██   ██ 
       ██    ███████ ██████  ██   ███ █████      ██        ███████ █████   ██      █████   ██         ██    ██    ██ ██████  
       ██    ██   ██ ██   ██ ██    ██ ██         ██             ██ ██      ██      ██      ██         ██    ██    ██ ██   ██ 
       ██    ██   ██ ██   ██  ██████  ███████    ██        ███████ ███████ ███████ ███████  ██████    ██     ██████  ██   ██
]]
---@class TargetSelector
---@field AddMode fun(name:string, order: '"ascending"'|'"descending"', val_fn:function) @val_fn: Evaluates the current target. i.e. function(target) return target.Health end 
---@field OverrideMode fun(name:string, order: '"ascending"'|'"descending"', val_fn:function) @val_fn: Evaluates the current target. i.e. function(target) return target.Health end 
---@field ForceTarget fun(self: TargetSelector, Target:AIHeroClient|nil)
---@field GetForcedTarget fun(self: TargetSelector):AIHeroClient|nil
---@field GetValidTargets fun(self: TargetSelector, maxRange: number, enemies:AIHeroClient[]|nil, checkMissileBlocks: boolean|nil, source: AIBaseClient|nil, isAttack: boolean|nil):AIHeroClient[]
---@field SelectTargetForMode fun(self: TargetSelector, enemies: AIHeroClient[], mode: string):AIHeroClient
---@field GetTargetFromList fun(self: TargetSelector, possibleTargets: AIHeroClient[], checkMissileBlocks: boolean|nil, isAttack: boolean|nil):AIHeroClient
---@field GetTarget fun(self: TargetSelector, maxRange:number|nil, checkMissileBlocks: boolean|nil, source: AIBaseClient|nil, isAttack: boolean|nil):AIHeroClient
---@field SortTargetsForMode fun(self: TargetSelector, enemies: AIHeroClient[], mode: string):AIHeroClient[]
---@field GetTargetsFromList fun(self: TargetSelector, possibleTargets: AIHeroClient[], checkMissileBlocks: boolean|nil, isAttack: boolean|nil):AIHeroClient[]
---@field GetTargets fun(self: TargetSelector, maxRange:number|nil, checkMissileBlocks: boolean|nil, source: AIBaseClient|nil, isAttack: boolean|nil):AIHeroClient[]
---@field GetTrueAutoAttackRange fun(self: TargetSelector, Source: AIBaseClient, Target: AttackableUnit)
---@field IsValidTarget fun(self: TargetSelector, o: GameObject, maxRange: number|'-1'|nil, from: Vector|nil)
---@field IsValidAutoRange fun(self: TargetSelector, Target: GameObject, Source: AIBaseClient|nil)
---@field HasUndyingBuff fun(self: TargetSelector, Target: AIBaseClient, extraTime: number|nil)
local TargetSelector

--USAGE: _G.Libs.TargetSelector()
---@type fun():TargetSelector
local tsConstructor;
_G.Libs.TargetSelector = tsConstructor

--[[
     ██████  ██████  ██████  ██     ██  █████  ██      ██   ██ ███████ ██████  
    ██    ██ ██   ██ ██   ██ ██     ██ ██   ██ ██      ██  ██  ██      ██   ██ 
    ██    ██ ██████  ██████  ██  █  ██ ███████ ██      █████   █████   ██████  
    ██    ██ ██   ██ ██   ██ ██ ███ ██ ██   ██ ██      ██  ██  ██      ██   ██ 
     ██████  ██   ██ ██████   ███ ███  ██   ██ ███████ ██   ██ ███████ ██   ██ 
]]

---@class Orbwalker
---@field IgnoreMinion fun(obj: AttackableUnit):nil @Use When You'll Kill Minion With Spell and Dont Want Orb To Last Hit 
---@field IsIgnoringMinion fun(obj: AttackableUnit):boolean
---@field StopIgnoringMinion fun(obj: AttackableUnit):nil
---@field GetIgnoredMinions fun():table @{[handle1] = true, [handle2] = true, etc}
---@field IsLasthitMinion fun(obj: GameObject):boolean @Returns if we already attacked a minion with intent to last hit (don't cast on that minion)
---@field GetMode fun():'"Combo"'|'"Harass"'|'"Waveclear"'|'"Lasthit"'|'"Flee"'|'"nil"'
---@field GetTarget fun():GameObject|nil
---@field GetLastTarget fun():AttackableUnit|nil
---@field GetSpellFarmTargets fun(spell:SpellBase, onlyUnkilalble: boolean|nil):AIMinionClient[]
---@field BlockMove fun(value: boolean):nil
---@field IsMovingDisabled fun():boolean
---@field BlockAttack fun(value: boolean):nil
---@field IsAttackingDisabled fun():boolean
---@field IsAttackReady fun():boolean
---@field IsWindingUp fun():boolean
---@field CanMove fun():boolean
---@field CanAttack fun():boolean
---@field CanCast fun():boolean
---@field IsFastClearEnabled fun():boolean
---@field IsLaneFreezeEnabled fun():boolean
---@field IsSupportModeEnabled fun():boolean
---@field MoveTo fun(position: Vector) @Forces Orb To Move To This Position. Use Orbwalker.MoveTo(nil) to reset. WARNING! IMPROPER USAGE MIGHT MAKE ORB STUCK!
---@field Move fun(position: Vector):nil @Useful for Custom Modes etc
---@field Attack fun(target: AttackableUnit):nil @Useful for Custom Modes etc
---@field ResetAttack fun():nil @Useful for Custom Modes etc
---@field Orbwalk fun(position: Vector, target: AttackableUnit|nil, orbMode:string|nil):nil @Kites [target] Moving Towards [position]. Useful for Custom Modes etc
---@field TimeSinceLastAttack fun():number @Seconds Passed Since Last Attack Start
---@field TimeSinceLastAttackOrder fun():number @Seconds Passed Since Last Attack Request
---@field TimeSinceLastMove fun():number @Seconds Passed Since Last Move Start
---@field TimeSinceLastMoveOrder fun():number @Seconds Passed Since Last Move Request
---@field GetTrueAutoAttackRange fun(source: AIBaseClient, target:AttackableUnit|nil):number
---@field GetTrueAutoAttackMissileSpeed fun():number
---@field GetAutoAttackDamage fun(minion: AttackableUnit):number @Only For Minions, For Other Objects use DamageLib.GetAutoAttackDamage
---@field HasTurretTargetting fun(obj: AttackableUnit):boolean @Returns if Object is being attacked by a turret
---@field CheckAutoAttackMissileCollision fun(obj: GameObject):boolean @Returns if your auto-attack missile collides with Yasuo Wall, Samira Wall, Jax Counter-Strike on travel to obj
---@field ForceTarget fun(Target:AIHeroClient|nil):nil
---@field GetForcedTarget fun():AIHeroClient|nil
---@field RemoveForcedTarget fun():nil
---@field FineTuneUnkillable fun(val: number):nil
local Orbwalker
_G.Libs.Orbwalker = Orbwalker

--[=[
    Use this ONLY WHEN you need more time to kill unkillable Minions.
    It'll make the event fire earlier, leting you cast slower 
    spells, but will also add false positives. 
    eg. fire for a minion that could be killed with an AA
    *** Orbwalker.FineTuneUnkillable(0.75) ***

    Below is an example of how to use it on your scripts:
    function Annie.OnUnkillableMinion(minion)
        --[[ Some Other Script Will Already Kill This Minion ]]
        if Orbwalker.IsIgnoringMinion(minion) then        
            return
        end

        --[[ Use Q To Kill And Tell Orbwalker/Other Scripts To Ignore This Minion]]
        if Menu.Get("Annie.lasthit.unkillableQ") and spells.Q:IsInRange(minion) then
            if spells.Q:IsReady() and spells.Q:CanKillTarget(minion) and spells.Q:Cast(minion) then
                Orbwalker.IgnoreMinion(minion)
                return
            end
        end

        --[[ Use W To Kill And Tell Orbwalker/Other Scripts To Ignore This Minion]]
        if Menu.Get("Annie.lasthit.unkillableW") and spells.W:IsInRange(minion) then
            if spells.W:IsReady() and spells.W:CanKillTarget(minion) and spells.W:Cast(minion) then
                Orbwalker.IgnoreMinion(minion)
                return
            end    
        end
    end
]=]
-- 



--[[
    ██████  ██████   ██████  ███████ ██ ██      ██ ███    ██  ██████  
    ██   ██ ██   ██ ██    ██ ██      ██ ██      ██ ████   ██ ██       
    ██████  ██████  ██    ██ █████   ██ ██      ██ ██ ██  ██ ██   ███ 
    ██      ██   ██ ██    ██ ██      ██ ██      ██ ██  ██ ██ ██    ██ 
    ██      ██   ██  ██████  ██      ██ ███████ ██ ██   ████  ██████  
]]
---@class Profiler
---@field Start fun():nil
---@field Stop fun():nil
---@field Reset fun():nil
---@field Report fun(filename:string):nil @Creates a file named PerformanceReport.log on your robur folder
local Profiler
_G.Libs.Profiler = Profiler

---@class SpellBase
---@field GetSpellData fun(self:SpellBase):SpellData|nil
---@field SetTargetSelector fun(self:SpellBase, newTS:TargetSelector)
---@field SetRangeCheckObj fun(self:SpellBase, obj:AIBaseClient)
---@field IsReady fun(self:SpellBase, extraTime:number|nil):boolean
---@field IsLearned fun(self:SpellBase):boolean
---@field GetLevel fun(self:SpellBase):number
---@field GetName fun(self:SpellBase):string
---@field GetState fun(self:SpellBase):Enum_SpellStates
---@field GetToggleState fun(self:SpellBase):number
---@field GetManaCost fun(self:SpellBase):number
---@field GetCurrentAmmo fun(self:SpellBase):number
---@field GetMaxAmmo fun(self:SpellBase):number
---@field GetTarget fun(self:SpellBase):AIHeroClient|nil
---@field GetTargets fun(self:SpellBase):AIHeroClient[]
---@field GetFarmTargets fun(self:SpellBase, onlyUnKillable:boolean):AIMinionClient[]
---@field GetDamage fun(self:SpellBase, target:AIBaseClient, stage:string|nil):number
---@field GetHealthPred fun(self:SpellBase, target:AIBaseClient):number
---@field CanCast fun(self:SpellBase, target:AIBaseClient):boolean
---@field IsValidTarget fun(self:SpellBase, target:AIBaseClient):boolean
---@field IsInRange fun(self:SpellBase, pos_or_target:AIBaseClient|Vector):boolean
---@field IsLeavingRange fun(self:SpellBase, target:AIBaseClient):boolean
---@field CanKillTarget fun(self:SpellBase, target:AIBaseClient, stage: string|nil, extraDmg:number|nil):boolean
local SpellBase

---@class Skillshot : SpellBase
---@field GetPrediction fun(self:Skillshot, target:AIBaseClient):PredictionResult
---@field GetCollision fun(self:Skillshot, startPos:Vector, endPos:Vector, team_lbl: string|nil, ignoreList: table|nil):CollisionResult
---@field GetFirstCollision fun(self:Skillshot, startPos:Vector, endPos:Vector, team_lbl: string|nil, ignoreList: table|nil):CollisionResult
---@field Cast fun(self:Skillshot, pos_target:AIBaseClient|Vector):boolean
---@field CastOnHitChance fun(self:Skillshot, target:AIBaseClient, minHitChance:number|Enums_HitChance):boolean
---@field GetBestLinearCastPos fun(self:Skillshot, targets: Vector[]|AIBaseClient[]):Vector,number
---@field GetBestCircularCastPos fun(self:Skillshot, targets: Vector[]|AIBaseClient[]):Vector,number
---@field CastIfWillHit fun(self:Skillshot, minTargets, _type):boolean
---@field GetDamage fun(self:Skillshot, target:AIBaseClient, stage:string|nil):number @stage: "Default", "Empowered", "SecondCast", "ThirdCast", "SecondForm", "ThirdForm"..
---@field GetHealthPred fun(self:Skillshot, target:AIBaseClient):number
---@field GetKillstealHealth fun(self:Skillshot, target:AIHeroClient):number @Current health + shield + yasuo passive etc
local Skillshot

---@class Targeted : SpellBase
---@field Cast fun(self:Targeted, pos_target:AIBaseClient|Vector):boolean
local Targeted

---@class Active : SpellBase
---@field Cast fun(self:Active, pos_target:AIBaseClient|Vector|nil):boolean
local Active

---@class Chargeable : Skillshot
---@field IsCharging boolean
---@field GetRange fun(self:Chargeable):number
---@field IsFullyCharged fun(self:Chargeable):boolean
---@field GetTargetMaxRange fun(self:Chargeable):AIHeroClient|nil
---@field GetTargetsMaxRange fun(self:Chargeable):AIHeroClient[]
---@field StartCharging fun(self:Chargeable):boolean @Start charging the spell
---@field Release fun(self:Chargeable, pos_target: AIBaseClient|Vector):boolean @Release a spell during charge
---@field ReleaseOnHitChance fun(self:Chargeable, target:AIBaseClient, minHitChance:number|Enums_HitChance):boolean @Release a spell during charge
---@field Cast fun(self:Chargeable, pos_target: AIBaseClient|Vector):boolean @Instant cast the spell at min range towards position or target prediction
local Chargeable

---@class SpellLib
---@field Skillshot fun(input: PredictionInput):Skillshot
---@field Targeted fun(input: PredictionInput):Targeted
---@field Active fun(input: PredictionInput):Active
---@field Chargeable fun(input: PredictionInput):Chargeable
local SpellLib
_G.Libs.Spell = SpellLib

--[[
     █████  ██       ██████   ██████  ██████  ██ ████████ ██   ██ ███    ███ ███████ 
    ██   ██ ██      ██       ██    ██ ██   ██ ██    ██    ██   ██ ████  ████ ██      
    ███████ ██      ██   ███ ██    ██ ██████  ██    ██    ███████ ██ ████ ██ ███████ 
    ██   ██ ██      ██    ██ ██    ██ ██   ██ ██    ██    ██   ██ ██  ██  ██      ██ 
    ██   ██ ███████  ██████   ██████  ██   ██ ██    ██    ██   ██ ██      ██ ███████ 
]]

---@type fun(points:Vector[], radius: number):Vector, number @Returns BestPos + HitCount
local BestCoveringCircle
_G.CoreEx.Geometry.BestCoveringCircle = BestCoveringCircle

---@type fun(points:Vector[], startPos:Vector, width: number):Vector, number @Returns BestPos + HitCount
local BestCoveringRectangle
_G.CoreEx.Geometry.BestCoveringRectangle = BestCoveringRectangle

---@type fun(points:Vector[], startPos:Vector, radians: number):Vector, number @Returns BestPos + HitCount
local BestCoveringCone
_G.CoreEx.Geometry.BestCoveringCone = BestCoveringCone

---@type fun(center1:Vector, radius1:number, center2:Vector, radius2:number):Vector[] @Returns the 2 Points Where Circles Intersect
local CircleCircleIntersection
_G.CoreEx.Geometry.CircleCircleIntersection = CircleCircleIntersection

---@type fun(lineP1:Vector, lineP2:Vector, center:Vector, radius:number, isInfiniteLine: boolean|nil):Vector[] @Returns the Points Where Line and Circle Intersect
local LineCircleIntersection
_G.CoreEx.Geometry.LineCircleIntersection = LineCircleIntersection

---@class Menu
---@field Set fun(id: string, value: any, nothrow: boolean):any
---@field Get fun(id: string, nothrow: boolean|nil):any
---@field GetKey fun(id: string, nothrow: boolean):any
---@field Indent fun(func: function):nil
---@field SameLine fun(offset: integer|nil, spacing: integer|nil):nil
---@field Separator fun(text: string|nil):nil
---@field Text fun(displayText: string, centered:boolean|nil):nil
---@field ColoredText fun(displayText: string, color: integer, centered:boolean|nil):nil
---@field SmallButton fun(id: string, displayText: string, func: function):nil
---@field Button fun(id: string, displayText: string, func: function, size: Vector|nil):nil
---@field Checkbox fun(id: string, displayText: string, default: boolean):boolean
---@field ColorPicker fun(id: string, displayText: string, default: integer):integer
---@field Dropdown fun(id: string, displayText: string, default:integer, list:table):integer 
---@field Keybind fun(id: string, displayText: string, defaultKey: integer, toggle: boolean|nil, defaultVal: boolean|nil, dontUseColumns: boolean|nil):boolean
---@field Slider fun(id: string, displayText: string, default:number, minValue:number, maxValue:number, step:number):number
---@field NewTree fun(id: string, displayText: string, func: function):nil
---@field ColumnLayout fun(id: string, displayText: string, columns: integer, borders: boolean, func: function):nil
---@field NextColumn fun():nil
---@field RegisterPermashow fun(id: string, displayText: string, func: function, isVisible: function|nil):nil
---@field RegisterMenu fun(id: string, displayText: string, func: function, args : table|nil):nil @args eg {Author="Thorn", LastModified="23-Aug-2021", Version="1.0.0"}
---@field IsKeyPressed fun(vKey: number):boolean
local Menu
_G.Libs.NewMenu = Menu

--[[
    ███████ ██    ██  █████  ██████  ███████ 
    ██      ██    ██ ██   ██ ██   ██ ██      
    █████   ██    ██ ███████ ██   ██ █████   
    ██       ██  ██  ██   ██ ██   ██ ██      
    ███████   ████   ██   ██ ██████  ███████
]]

---@class DetectedSpell
---@field GetName fun():string
---@field GetSlot fun():Enum_SpellSlots
---@field GetCaster fun():AIBaseClient|nil
---@field GetType fun():string @"Ring", "Circle", "Line", "MissileLine", "Cone", "MissileCone", "Arc"
---@field IsEnabled fun():boolean @Returns true if Skill is enabled on Evade menu
---@field IsDangerous fun():boolean @Returns true if Skill is marked as Dangerous on Evade menu
---@field GetDangerLevel fun():number @Returns Skill DangerLevel from Evade menu
---@field IsSafePoint fun(position: Vector):boolean
---@field IsAboutToHit fun(time_in_secs:number, hero_or_pos:Vector|AIHeroClient):boolean
local DetectedSpell

---@class Evade
---@field IsEnabled fun():boolean @Returns true if Evade is Enabled
---@field IsEvading fun():boolean @Returns true if Evade is currently dodging a spell
---@field IsDodgeOnlyDangerous fun():boolean @Returns true if Evade is in "DodgeOnlyDangerous" mode 
---@field IsAboutToHit fun(time_in_secs:number, hero:AIHeroClient):boolean @Returns true if any spells will hit [hero] in [time_in_secs] seconds
---@field IsSpellShielded fun(hero:AIHeroClient):boolean
---@field GetBestWalkPosition fun(position: Vector, speed: number, delay_in_secs: number):Vector|nil
---@field GetBestDashPosition fun(position: Vector, speed: number, delay_in_secs: number, range: number, fixed_range:boolean):Vector|nil
---@field GetBestBlinkPosition fun(position: Vector, delay_in_secs: number, range: number, fixed_range:boolean):Vector|nil
---@field IsPointSafe fun(position: Vector):boolean
---@field IsPathSafe fun(position: Vector, speed: number, delay_in_secs: number):boolean
---@field IsBlinkSafe fun(position: Vector, delay_in_secs: number):boolean
---@field GetDetectedSkillshots fun():DetectedSpell[] @All detected Skills 
---@field GetEnabledSkillshots fun():DetectedSpell[] @All Detected skills enabled in Evade
---@field GetDangerousSkillshots fun():DetectedSpell[] @Skills Player is inside
local Evade
_G.CoreEx.EvadeAPI = Evade

--[[
    ████████ ██████   █████  ███    ██ ███████ ██       █████  ████████ ██  ██████  ███    ██ ███████ 
       ██    ██   ██ ██   ██ ████   ██ ██      ██      ██   ██    ██    ██ ██    ██ ████   ██ ██      
       ██    ██████  ███████ ██ ██  ██ ███████ ██      ███████    ██    ██ ██    ██ ██ ██  ██ ███████ 
       ██    ██   ██ ██   ██ ██  ██ ██      ██ ██      ██   ██    ██    ██ ██    ██ ██  ██ ██      ██ 
       ██    ██   ██ ██   ██ ██   ████ ███████ ███████ ██   ██    ██    ██  ██████  ██   ████ ███████                                                        
]]

--[[
    1. Create a .json file using the name you register your Menu and put inside folder "\\lol\\Translations"
        Menu.RegisterMenu("UnrulyEzreal", "Unruly Ezreal", function() end) -> "\\lol\\Translations\\UnrulyEzreal.json"

    2. Edit the created file with a map of Language, MenuID and Translated Display Strings using the following format:
        To Translate These Options:
            Menu.ColoredText("Draw Options", 0xFFD700FF, true)
            Menu.Checkbox("Drawing.W.Enabled",   "Draw [W] Range")
        Into Spanish and French, We Write:
            {
                "Default": {
                    "Draw Options": "Draw Options",
                    "Drawing.W.Enabled": "Draw [W] Range",
                },
                "Español" : {
                    "Draw Options": "Opciones de sorteo",
                    "Drawing.W.Enabled": "Dibujar [W] Rango",
                },
                "Français" : {
                    "Draw Options": "Options de tirage",
                    "Drawing.W.Enabled": "Dessiner la portée [W]",
                }
            }

    3. Now the language you added should appear on Script Menu!
    PS: "Default" language isn't needed, but it helps other users/devs translate the script to their own languages
]]

--[[
     █████  ██    ██ ████████  ██████      ██    ██ ██████  ██████   █████  ████████ ███████ 
    ██   ██ ██    ██    ██    ██    ██     ██    ██ ██   ██ ██   ██ ██   ██    ██    ██      
    ███████ ██    ██    ██    ██    ██     ██    ██ ██████  ██   ██ ███████    ██    █████   
    ██   ██ ██    ██    ██    ██    ██     ██    ██ ██      ██   ██ ██   ██    ██    ██      
    ██   ██  ██████     ██     ██████       ██████  ██      ██████  ██   ██    ██    ███████                                                        
]]
--[[
    1. Put a ".version" file with the same name and path of your script at the git
        eg. https://github.com/Thorn/Public/blob/main/UnrulyEzreal.lua
            https://github.com/Thorn/Public/blob/main/UnrulyEzreal.version
    2. Call CoreEx.AutoUpdate() on the script, passing the link and local version
        eg. CoreEx.AutoUpdate("https://raw.githubusercontent.com/Thorn/Public/main/UnrulyEzreal.lua", "1.0.0")
]]

---@type fun(rawLink:string, version:string):nil
local AutoUpdate
_G.CoreEx.AutoUpdate = AutoUpdate

