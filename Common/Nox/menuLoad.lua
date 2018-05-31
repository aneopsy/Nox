--x--
icons, Menu = {}
icons.NOX = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/NoxLogo.png"
Menu = MenuElement({id = charName, name = "Nox | Champs tracker", type = MENU, leftIcon = icons.NOX})

-- Timez
Menu:MenuElement(
    {
        id = "Timez",
        name = "Timez",
        type = MENU,
        leftIcon = "https://raw.githubusercontent.com/aneopsy/Nox/master/Icons/drawings.png"
    }
)

-- RecallTracker
Menu:MenuElement(
    {
        type = MENU,
        id = "RecallTracker",
        name = "Recall Tracker",
        leftIcon = "http://puu.sh/pPVxo/6e75182a01.png"
    }
)