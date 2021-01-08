# VisualThreat

VERSION: Alpha V 1.0

Visual Threat is a World of Warcraft Addon that presents a VERY simple visual display of the threat (a.k.a aggro) on each party member. For example, if you are in a party with 5 members, the threat display will be a vertical stack of party member icons. While in combat, the icons will be ordered by threat, from highest to lowest. The member with the highest threat will, hopefully, be the tank. The icons are ordered from highest (top or first icon) to lowest (bottom or last icon). Over the course of an encounter threat levels will change (e.g., the tank loses aggro). When the change is such as the icons need to reordered the addon will shuffle the icons so that the highest to lowest ordering is maintained.

The stack also includes an icon for each pet in the party. So, in a party of 5 with a warlock and a hunter, each with a pet summoned, the threat stack will be composed of 7 icons.

NEXT RELEASE: Alpha V 2.0
Two new features will be added:

1. When a player moves to the top of the stack, its icon will display a flashing red icon for a brief time.
2. Visual Threat will incorporate information from the COMBAT_EVENT_LOG_UNFILTERED. The first change will be to add a damage metric to the threat percent. Specifically, in addition to threat, each icon will display the player's contribution to the total damage done by party. For example, if the total party damage is 100K and your character has contributed 30K to the effort, your icon will display your threat along with a 30% damage figure.
