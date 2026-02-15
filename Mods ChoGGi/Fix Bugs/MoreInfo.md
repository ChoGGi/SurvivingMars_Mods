### Tested on: [1011166](https://survivingmars.paradoxwikis.com/Patches)

See mod options to toggle certain fixes.

# List of bugs fixed:

### (See below for more info about specific fixes)

### General bugs:
```
Uneven terrain from Flatten tool (mod option to disable).
If an expedition fails (only from storybits?) then the rover doesn't get deleted.
Log spam from RC Transports trying to unload resources when on expeditions.
RC Harvester doesn't collect waste rock.
RC Constructor/RC Terraformer missing Create Transport Route button.
Meteor landed on under construction track while dismantling.
Water Conservation System doesn't show updated consumption in build menu.
Show actual resources in build menu for Dome Streamlining, Mars Nouveau, etc.
If you install Space Race DLC then Shuttle Hubs will disappear from build menu in existing saves.
Key binding certain buildings won't work when pressing the key (Power Switch/Pipe Valve).
Add rocket sound effects to SupplyPods (mod option to disable).
Possible fix for main menu music playing in-game on new games (mod option to disable, since there's no fade out).
Force heat grid to update when starting certain new games.
Future Contemporary Asset Pack has issues when placing spires.
Leftover transport_ticket in colonist objs (assign to residence grayed out, from Trains DLC).
Problem updating supply grid (I've had better descriptions).
Colonists on an expedition now show proper status when selected from command centre (instead of just unknown).
Added missing images for certain Cargo listings.
Gale crater name doesn't show up for 4S138E, 5S138E.

Log spam:
Loading older saves.
IsBuildingInDomeRange(): Dome.lua:1657: attempt to index a nil value (local 'dome')
Toggling power to domes with passages in certain instances.
```

### Storybits (SPOILERS):
```
Rare Anomaly Analyzed: Architecture shows sequence-50 instead of correct string.
Underground bit Morale Boost has a misnamed reference.
Long Winter Cold Wave timer can disappear at 4 Sols.
Make Dust Sickness not effect Biorobots: It doesn't always cure colonists for some reason and Biorobots never die, plus they're robots...
Cyber War: Anyone up for some good old blackmailing? Never rewards funds only lowers standing.
Eureka!: Option 2/3: Always picks from Biotech instead of random category.
FollowUp Storybits in wrong category:
Survey Offer Option 2, Cure For Cancer: Rare Outcome, and Free Will: Violent Urges Solved.
Twin Peeks: spawning, but not showing Beauty/Research effect deposits.
The Man From Mars: Outcome 3: Let him be, whoever he is: None of the options reward anything.
Morale is added based on CustomOutcomeText and Morale stats from Outcome 2.
The Extract: Selecting Shuttle Hub and having Paradox as sponsor doesn't add a Jumper Hub.
Asylum will never start.
Blank Slate doesn't remove any applicants.
Fhtagn! Fhtagn! Option 2 makes all colonists cowards instead of only religious ones.
Dust Sickness: Deaths doesn't apply morale penalty.
The Door To Summer #4 stops working after you fill the rocket.
Some Storybits disappearing from the notifications list instead of popping up a dialog.
Gene Forging tech doesn't increase rare traits chance.
Personal Space changes capacity, but building menu doesn't show it.
Storybit notification issue.
```

### Mysteries:
```
Dredger tech fix (Spoilers: https://www.reddit.com/r/SurvivingMars/comments/xnprjg/).
Marsgate: blank transportation panel in CCC after a certain point in mystery.
St. Elmo's Fire: Stop meteoroids from destroying sinkholes and soft locking the mystery.
The Philosopher's Stone doesn't update sector scanned count when paused.
```

### B&B:
```
Cargo Shuttle flying underground with a colonist being transported to a surface dome.
Rare Anomaly Analyzed: Fossils: Global Support didn't check for Space Race DLC (it now gives random breakthrough).
Colonists underground crash (mod option enabled by default, more info below).
Unlock Artificial Sun for refabbing.
Too much Cave-in rubble will cause lag when new rubble tries to spawn.
Elevator func not checking for invalid resources.
Colonists showing up on wrong map in infobar (also negative counts in infobar, mod option disabled by default).
No flying drones underground (they tend to get stuck in walls/etc).
No Planetary Anomaly Breakthroughs when B&B is installed.
Refabbing rare extractors left the "working" dust plumes around them.
Stop ceiling/floating rubble.
Support struts malfunctioning and cave-ins.
The Bottomless Pit Anomaly is missing on one map.
Mona Lisa Underground Rare Anomaly gives you underground dome prefabs, but locks them to surface.
Mona Lisa Underground Rare Anomaly if using Paradox and you pick Shuttle Hubs, it doesn't give Jumper Hubs.
Unpassable underground rocks stuck in path (not cave-in rubble, but small rocks you can't select).
Water Reclamation Spire and B&B upgrade tech caused issues.
```

### Strings (mispeelings or not good grammer):
```
8390
297691849913

Actual strings not included as there could be spoilers, so only ids (mostly useful for me).
Additions are welcome in any language.
```

### Mod bug fixes:
```
log spam from some mod: "attempt to call a nil value (method 'GetFreeWorkSlots')" and also GetFreeSpace.
Fix applicants with a func instead of a time.
UCP: Never get funding/res points from Observatory.
Log spam from borked colonist (possibly from a mod, could just be B&B again).
Fix for whatever odd thing Mars Underground mod is doing with presets.
Log spam from a modded trait without an id.
Black screen in second new game window when using a Modded sponsor and missing DLC.
Rivals Trade Minerals mod hides Exotic Minerals from lander UI.
Silva's Orion Heavy Rocket (you must disable his Essential files mod, then enable it AFTER enabling this mod, or use my Mod List Editor mod to place this before it).
Horticulture Workshop not unlocking.
Removes stuck cursor buildings (reddish coloured).
GetCheapestTech log spam.
```

### QoL:
```
Even if you have more than one Artificial Sun then panels will only check the "first" one.
```


# Incorporated mods: (so far)
```
Fix Blank Mission Profile
Fix Buildings Broken Down And No Repair
Fix Colonist Daily Interest Loop
Fix Colonists Long Walks (better solution: Use my "No More Outside Suffocation" mod)
Fix Colonists Suffocating Inside Domes
Fix Defence Towers Not Firing At Rovers
Fix Deposits Wrong Map
Fix Destroyed Tunnels Still Work
Fix Double Click Select All Of Type
Fix Dust Devils Block Building
Fix Farm Oxygen
Fix FindDroneToRepair Log Spam
Fix Landscaping Freeze
Fix Layout Construction Tech Lock
Fix Locked Wind Turbine
Fix Meteor Stuck On Map
Fix Mods With Nil Notifications
Fix No Power Dome Buildings
Fix Projector Lamp
Fix RC Commander Drone Freeze
Fix Resupply Menu Not Opening
Fix Rover In Dome
Fix Stuck Malfunctioning Drones At DroneHub
Fix Transport Negative Amounts
Fix Transports Don't Move After Route Set
Fix Unlock RC Safari Resupply
Fix Unrepairable Attack Rovers
Pins Missing Some Status Icons
RC Constructor Terraformer Routes
School Skip Attained Perks
```


# Extra info for incorporated mods/specific fixes:


### FollowUp Storybits in wrong category

All three followups have the same issue.

The bit is in the TechResearched category instead of the FollowUp, so it never shows up...

Also it has Enabled = true, but it's a follow up, and it's already started before the actual story (causes other issues depending on which bit it is).

Survey Offer Option 2 New tech

Free Will: Violent Urges Solved

Cure For Cancer: Rare Outcome (doesn't have Enabled = true)

New games will be needed for most of them (if you haven't researched the tech yet then it'll work).

### School Skip Attained Perks

Schools won't pick a trait the colonist already has when training is complete.

https://www.reddit.com/r/SurvivingMars/comments/kgystg/im_playing_as_church_of_the_new_ark_so_everyone/

### Fix applicants with a func instead of a time.

Some mod (most likey) is inserting a func instead of a time with GenerateApplicant(time, city).

This will change any applicants without a time to the current time, and check for non-number values in GenerateApplicant.

### Uneven terrain / Flatten tool

When finishing landscaping it can set some of the surrounding hexes z values (height) to 65535 (also known as UnbuildableZ).

Calling RefreshBuildableGrid() on the map seems to get rid of them without causing any major issues:

It can mark some hexes as okay to build when they weren't before, but nothing like a cliff side or anything.

If you enable the mod option and notice that you can build on some places you really shouldn't be able to then please let me know :)

If you're bored and want to dig through the funcs in LandscapeFinish() to find out exactly where it's coming from, feel free.

### No Planetary Anomaly Breakthroughs when B&B is installed

Mod option to disable this "fix" (and receive less Breakthroughs).

City:InitBreakThroughAnomalies() is called for each new city (surface/underground/asteroids).

Calling it more than once clears the BreakthroughOrder list.

BreakthroughOrder is used to spawn planetary anomalies.

### Fix Deposits Wrong Map

If you scan a surface sector that has a concrete deposit while underground then the deposit will appear underground.
This will check on load for borked ones and move them to the surface, as well as overriding the borked function to fix newly scanned.
This also fixes underground ones stuck on the surface (less likely).

If it doesn't remove them, then go to the mod options and press apply.

https://forum.paradoxplaza.com/forum/threads/surviving-mars-surface-concrete-deposit-has-no-icon-and-is-not-minable.1496572/

### Colonists underground crash

This will check for colonists underground that are trying to path to a place on the surface.

The game will crash when they run out of usable pathing.

https://www.reddit.com/r/SurvivingMars/comments/1k70uxf/game_crashing_on_the_same_sol_every_time/

v2: A different save and colonists on the surface stuck in underground labels (same mod option as previous fix).

v3: Third time is the charm, this crash was apprently newly arrived colonists going down the elevator instead of the arrival dome.

### Colonists showing up on wrong map in infobar

Disabled by default, can cause freezing when loading saves.

### No flying drones underground

Flying drones tend to get stuck in walls/etc, this makes them into regular ones underground (mod option).

For existing drones you'll need to recall them to their hubs and redeploy.

### The Bottomless Pit Anomaly is missing

SpawnAnomaly() calls FindUnobstructedDepositPos() which for whatever reason,

takes the pos from in front of the wonder and sticks it in the passage behind it... (BlankUnderground_02 map)

SpawnAnomaly() freaks out and changes it to an underground water instead (or just doesn't spawn it).

### Future Contemporary Asset Pack

When placing a building you can change skins, if you use the spire skins from this DLC when placing skins

then it blocks an extra hex (you can see it when placing). This removes that hex on new buildings.

### Fix Rover In Dome

Checks on load for rovers stuck in domes (not open air ones).

Also fixes drones stuck in pastures.

You can also use an expedition that needs a transport rover, make sure your other rovers aren't idle (moving around is enough).

### Fix FindDroneToRepair Log Spam

This seems to be an issue from flying drones and a drone hub being destroyed.

Your log will "fill" up with this error:

Mars/Lua/Units/Drone.lua(256): method FindDroneToRepair

### Fix Destroyed Tunnels Still Work

Rovers will still use destroyed tunnels (in certain situations).

https://forum.paradoxplaza.com/forum/threads/hello-can-you-address-this-little-issue.1463333

### Force heat grid to update

If you paused game on new game load then cold areas don't update till you get a working Subsurface Heater.

### Water Reclamation Spire and B&B

Some buildings don't properly turn off their upgrades which causes them to keep their modifiers on.

The "fix" is turning off upgrades when a building is demolished, turned off, malfunctioned (might be annoying, mod option to keep it as is).

### Fix Buildings Broken Down And No Repair

If you have broken down buildings the drones won't repair. This will check for them on load game.

The affected buildings will say something about exceptional circumstances.

Any buildings affected by this issue will need to be repaired with 000.1 resource after the fix happens.

This also has a fix for buildings hit with lightning during a cold wave.

### Fix Floating Rubble

Move any floating underground rubble to within reach of drones (might have to "push" drones to make them go for it).

### Fix Colonist Daily Interest Loop

A colonist will repeatedly use a daily interest building to satisfy a daily interest already satisfied.

Repeating a daily interest can gain a comfort boost "if" colonist comfort is below the service comfort threshold, but a resource will always be consumed each visit.

This mod will block the colonist from having a visit (i.e., an unemployed scientist will wander around outside till the Sol is over instead of chewing up 0.6 electronics).

https://forum.paradoxplaza.com/forum/threads/surviving-mars-colonists-repeatedly-satisfy-daily-interests.1464969/

Thanks to ThereWillBeBugsToOvercome for noticing it, finding the offending code, doing a detailed write up of it, and testing the fix.

### Fix Stuck Malfunctioning Drones At DroneHub

If you have malfunctioning drones at a dronehub and they never get repaired (off map).

This'll check on load each time for them (once should be enough though), and move them near the hub.

### Fix Farm Oxygen

If you remove a farm that has an oxygen producing crop (workers not needed) the oxygen will still count in the dome.

### Fix Dust Devils Block Building

No more cheesing dust devils with waste rock depots (etc), by placing them on top of said devils (not by building them to block them).

### Fix Defence Towers Not Firing At Rovers

It's from a mystery (trying to keep spoilers to a minimum).

If you're starting a new game than this is fixed, but for older saves on this mystery you'll need this mod.

### Fix Landscaping Freeze

When LandscapeMark hits 4095 bad things happen.

This checks each new day and resets LandscapeLastMark to whatever is the highest number in Landscapes (assuming it's under 3000, otherwise 0).

For those wondering LandscapeLastMark is increased each time you open flatten/ramp (doesn't need to be placed).

Thanks to Quirquie for the bug report (and persistence).

### Fix Unrepairable Attack Rovers

Allows Attack Rovers to be repaired when you can't repair them.

I don't want to say too much as they're from one of the mysteries.

https://www.reddit.com/r/SurvivingMars/comments/12vkbrb/

### Fix Unlock RC Safari Resupply

RC Safaris aren't automagically unlocked in the resupply screen for games saved before Tito/Tourism update.

### Pins Missing Some Status Icons

The pinned rover transport buttons are missing un/load icons.



# Known Bugs:
Mars Nouveau won't count if you remove a Construction site and place the new one in the exact same position (thanks Dark Master).



# See also:


[Fix Cold Wave Stuck](https://steamcommunity.com/sharedfiles/filedetails/?id=2601527081)

[Fix Dredger Mark Left On Ground](https://steamcommunity.com/sharedfiles/filedetails/?id=1646258448)

[Fix Eternal Dust Storm](https://steamcommunity.com/sharedfiles/filedetails/?id=1594158818)

[Fix Flying Drones MidAir Malfunction](https://steamcommunity.com/sharedfiles/filedetails/?id=2473394779)

[Fix Mac Mirror Graphics](https://steamcommunity.com/sharedfiles/filedetails/?id=2549884520)

[Fix Missing Mod Buildings](https://steamcommunity.com/sharedfiles/filedetails/?id=1443225581)

[Fix Missing Mod Icons](https://steamcommunity.com/sharedfiles/filedetails/?id=1725437808)

[Fix Remove Blue Yellow Marks And Ghosts](https://steamcommunity.com/sharedfiles/filedetails/?id=1553086208)

[Fix Remove Invalid Label Buildings](https://steamcommunity.com/sharedfiles/filedetails/?id=1575894376)

[Fix Rocket Stuck](https://steamcommunity.com/sharedfiles/filedetails/?id=1567028510)

[Fix Rover In Dome](https://steamcommunity.com/sharedfiles/filedetails/?id=1829688193)

[Fix Shuttles Stuck Mid-Air](https://steamcommunity.com/sharedfiles/filedetails/?id=1549680063)

[Fix Sol 2983](https://steamcommunity.com/sharedfiles/filedetails/?id=2705335465) < Don't enable unless needed!

[Fix Stuck Mirror Sphere Devices](https://steamcommunity.com/sharedfiles/filedetails/?id=2082012035)
