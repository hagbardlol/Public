module("AIO Loader", package.seeall, log.setup)
clean.module("AIO Loader", clean.seeall, log.setup)
_G.CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/champions.lua", "1.0.3")

local aioChamps = {
    Akshan = true,
    Amumu = true,
    Ashe = true,
    Corki = true,
    Diana = true,
    Ezreal = true,
    Hecarim = true,
    Karma = true,
    Kayle = true,
    Kennen = true,
    MissFortune = true,
    Nautilus = true,
    Senna = true,
    Swain = true,
    Vex = true,
    Xerath = true
}

local supportedChamp = {
    --Aatrox = true,
    Ahri = true,
    Akali = true,
    --Akshan = true,
    --Alistar = true,
    --Amumu = true,
    --Anivia = true,
    Annie = true,
    Aphelios = true,
    --Ashe = true,
    --AurelionSol = true,
    Azir = true,
    Belveth = true,
    --Blitzcrank = true,
    --Brand = true,
    Caitlyn = true,
    Camille = true,
    Cassiopeia = true,
    Chogath = true,
    --Corki = true,
    Darius = true,
    --Diana = true,
    DrMundo = true,
    Draven = true,
    Ekko = true,
    Elise = true,
    Evelynn = true,
    --Ezreal = true,
    Fiora = true,
    Fizz = true,
    Garen = true,
    Gnar = true,
    Gragas = true,
    Graves = true,
    Gwen = true,
    --Hecarim = true,
    Illaoi = true,
    Irelia = true,
    --Janna = true,
    JarvanIV = true,
    Jax = true,
    Jayce = true,
    Jhin = true,
    --Jinx = true,
    Kaisa = true,
    Kalista = true,
    --Karma = true,
    Karthus = true,
    Kassadin = true,
    Katarina = true,
    --Kayle = true,
    Kayn = true,
    --Kennen = true,
    Khazix = true,
    Kindred = true,
    Kled = true,
    KogMaw = true,
    --Leblanc = true,
    LeeSin = true,
    Leona = true,
    Lillia = true,
    Lissandra = true,
    --Lucian = true,
    --Lulu = true,
    --Lux = true,
    --Malphite = true,
    Malzahar = true,
    --Maokai = true,
    --MasterYi = true,
    --MissFortune = true,
    Mordekaiser = true,
    Morgana = true,
    Nami = true,
    --Nasus = true,
    --Nautilus = true,
    Neeko = true,
    Nilah = true,
    --Nocturne = true,
    Nunu = true,
    --Olaf = true,
    Orianna = true,
    Poppy = true,
    Pyke = true,
    Qiyana = true,
    Quinn = true,
    Rakan = true,
    --Rammus = true,
    --Renata = true,
    Renekton = true,
    Rengar = true,
    Rumble = true,
    Ryze = true,
    --Samira = true,
    Sejuani = true,
    --Senna = true,
    Seraphine = true,
    Sett = true,
    --Shaco = true,
    Shyvana = true,
    Sion = true,
    Sivir = true,
    Sona = true,
    Soraka = true,
    --Swain = true,
    Sylas = true,
    Syndra = true,
    TahmKench = true,
    --Taliyah = true,
    Talon = true,
    --Teemo = true,
    Thresh = true,
    Tristana = true,
    Trundle = true,
    --Tryndamere = true,
    --TwistedFate = true,
    Twitch = true,
    Udyr = true,
    Urgot = true,
    Varus = true,
    Vayne = true,
    --Veigar = true,
    Velkoz = true,
    --Vex = true,
    --Vi = true,
    Viktor = true,
    --Vladimir = true,
    Volibear = true,
    Warwick = true,
    --Xayah = true,
    --Xerath = true,
    XinZhao = true,
    Yasuo = true,
    Yone = true,
    Zed = true,
    --Zeri = true,
    --Ziggs = true,
    --Zilean = true,
    --Zyra = true
}

local charName = _G.Player.CharName
if supportedChamp[charName] then
    _G.LoadEncrypted(charName)
elseif aioChamps[charName] then
    _G.LoadEncrypted("AIO")
end
