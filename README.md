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

PARTY LEGEND:
PT: Player Tank
P1: Player with unitId party1
P2: Player with unitId party2
P3: Player with unitId party3
P4: Player with unitId party4
Pn: The Nth player of the party.

NOTE: VisualThreat treats pets no differently that players. Thus, a Blizzard 5 player party with 
4 members having pets would have a total of 9 players (PT, P1, P2, ... P8).

(dt): Damage Taken
(dd): Damage Done
(hr): Healing Received.
(th): Threat

This formula proposes that a party's performance is increased to the extent the tank is able
to soak up damage that would otherwise be taken by the other members of the party. However,
this metric is conditioned by the amount of work the healer has to do. The more healing necessary
to keep the tank (and the group) alive, the lower will be the group's efficiency

                    PT(dt) - Sum( P1(dt) + ... + Pn(dt)
DAMAGE TAKEN =  K ---------------------------------------
                                PT(hr)

                     PT(dd))  -  SUM(P1(dd)...Pn(dd))
DAMAGE DONE =   K -------------------------------
                     SUM(P1(hr)) + ... + Pn(hr)

                    (PT(th) - SUM( P1(th) + ... + Pn(th) )
THREAT      =   K --------------------------------------
                          SUM(P1(dt)...Pn(dt))

