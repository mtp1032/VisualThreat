# VisualThreat

VERSION: Alpha V 1.0

Visual Threat is a World of Warcraft Addon that presents a VERY simple visual display of the threat (a.k.a aggro) on each party member. the Addon displays relative threat as a vertical stack of player portaits (the "threat stack") ordered by relative threat from high (the top) to low (the bottom). 

1. The addon visualizes relative threat by positioning the player icons such that the icon of the player with the most threat is at top of the threat stack. As you might have surmised, the icon of the player with the least threat is at the bottom. The stack updates in real time. Player icons will rise and fall in the stack as their threat changes.

2. In addition to position, each icon provides the following details: 
    (a) The % of total threat relative to other members of the party.
    (b) The amount of damage taken by a player.
    (c) The amount of healing a player has received.
    (d) When out of combat, clicking on an icon will calculate various metrics of tank, healing, and DPS threat management.
    (e) The amount of damage and healing done by a player (via Mouseover)

The stack also includes an icon for each pet in the party. So, in a party of 5 with a warlock and a hunter, each with a pet summoned, the threat stack will be composed of 7 icons.

How good is your tank?

                       (DamageTakenByTank - Sum( damageTakenByOtherGroupMembers))
Group Performance =  K ------------------------------------------------------------
                                   Healing Received by tank)


