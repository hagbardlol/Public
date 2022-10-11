local SCRIPT_NAME, VERSION, LAST_UPDATE = "CXAIO", "1.0.5", "10/08/2022"
_G.CoreEx.AutoUpdate("https://raw.githubusercontent.com/hagbardlol/Public/main/CXAIO.lua", VERSION)
module(SCRIPT_NAME, package.seeall, log.setup)
clean.module(SCRIPT_NAME, clean.seeall, log.setup)

local Player = _G.Player

local supportedChamp = {
    Zed = true,
    Cassiopeia = true,
    LeeSin = true,
    Ahri = true,
    Ashe = true,
    Fizz = true,
    Kassadin = true,
    Kayn = true,
    Nilah = true,
    Rengar = true,
    Sivir = true,
    TahmKench = true,
    Urgot = true,
    Yone = true,
}

if supportedChamp[Player.CharName] then
    LoadEncrypted("CX"..Player.CharName)
end
