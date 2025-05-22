## Library Changelog

## v12.7 (Unreleased)
- Added a way for modders to apply mod options from lua code:
``CurrentModOptions:SetProperty("ExampleModOption", true)
ApplyModOptions(CurrentModId)``

### Examine:
- Hints for Parents>menuitems weren't showing up (thanks Tremualin).

## v12.6 (4 May 2025)
- MsgWait hasn't been displaying my default image for quite some time.
- Toggle UI Transparency will always default to off on new dialogs.
- Empty space next to Transparency checkbox is now not clickable as checkbox.
- Some dialogs showed Double-click rollup info twice.

## v12.5 (6 Mar 2025)
- ExportMapDataToCSV is slightly faster
- ExportMapDataToCSV won't show planetary anomalies if you have BB DLC without my Fix Bugs mod.
- GetName:
	- Fixed HGE names.
	- Having issues with g_LastBuildItem.
	- Seem to have gotten rid of anymore `[C](-1)` showing up.

### Examine:
- Fixed issue displaying certain "going to" positions.
- Added Table>context menu>Tool Bar>Clear Table: Remove all entries from this table.

## v12.4 (4 Jan 2025)
- Added checkbox to toggle UI transparency to my dialogs.
- Added DoSomethingQuestion(): Generic warning msg.
- Added CopyProperties(): Lets you skip certain properties when copying.
- Cleaned up how GetNearestIdleDrone looks for drones.
- RetName was showing weird crap for numbers.
- Moved RetThreadInfo/FindThreadFunc from ECM to Lib.

### Examine:
- Added Tool Bar>Clear Table: Remove all entries from this table.
- Removed toggle UI transparency button.
- Holding Ctrl and closing an examine dialog by pressing X will no longer close the console log dialog.
- Cleaned up ThreadsRegister results.
- Shows more info for some tables.

## v12.3 (17 Nov 2024)
- Added GetCityLabels()
	- If loading pre-picard saves in picard (picard game update not dlc)
	- Only needed during OnMsg.LoadGame
- Examining certain objs wouldn't open child examine below parent examine.

### Examine:
- Fixed Tools>Functions

## v12.2 (4 Aug 2024)
- Split ChoGGi funcs into their own table for localing.
- Find Dialog tries to show correct table index number when searching an indexed table (usually off by one).
- Examine Dump text file name is changed to use date instead of screenshot name func.
- ExportMapDataToCSV uses DLC for filename.
- Pasting in code in console should properly add spaces.
- Stopped using TranslationTable, might cause some string issues.
- DeleteObject was leaving particles behind for certain buildings.
- Fixed ExportMapDataToCSV maxing out at 12 for CSV export (thanks Sicarious).
- Added ChangeCargoValue().

## v12.1 (4 Sep 2023)
### Examine:
- Examine>Delete All skips dust plumes.
- Examine>Tool Bar>Copy All Text: Copies dialog text to clipboard.
- Examine>Tool Bar>Delete All Objects: Removes all objects of the same type (from current map).

## v12.0 (22 July 2023)
- Changed ExportMapDataToCSV() to not translate NESW strings.
- Hid Examine>Child checkbox.

## v11.9 (6 May 2023)

### Examine:
- Clicking the @ for objects will select that obj.
- Game could crash when viewing preview of some descriptions.

## v11.8 (23 Mar 2023)
- Found some more Picard map stuff to update.
- Cleaned up some log spam from some of my mods.
- Issue with Examine and certain tables.

## v11.7 (4 Dec 2022)
- Fix log spam when using this mod on pre-Picard versions of the game.
- Tooltip for Mod Options entry in game menu.
- RGBtoColour() ignored A from RGBA
- GetPassablePointNearby()/GetRandomPassable()/GetRandomPassablePoint() and picard.

### Examine:
- Added UI Click To Examine to toolbar buttons.
- UI flash wasn't working when first opening examine dialog.

## v11.6 (11 Sep 2022)
- Mod Option: Disable Dialog Escape: Pressing Escape won't close dialog boxes (default enabled).
- Log spam from AttachToNearestDome().
- You can use OpenExamineDelayed()/exd() before classes process (err re-process for mods).
	> It'll open all stored objs after ClassesPostprocess, so some stuff can change, but it's better than naught.

## v11.5 (10 July 2022)
- Fixed SetBuildingLimits and tracks not being able to be built.
- Single click to change mod toggle options.
- Added ObjectCloner().

## v11.4 (7 May 2022)
- Fixed Emergency Lua GC (from this mod at least, thanks Tremualin).
- FindNearestResource counts resources stored in building depots.
- Prints a warning if paradox account isn't signed in (mods won't update).

## v11.3 (30 Apr 2022)
- I was using GetMapID(obj), but it doesn't actually take a param...
- Some tables were giving examine a hard time.

## v11.2 (7 Apr 2022)
- Changed RetName() for less dbg_reg().* showing up for names.

## v11.1 (20 Mar 2022)
- Fixed issue when using Chinese lang.
- Added a fix for ModItemOptionInputBox not showing option the first time you open it.

## v11.0 (5 Mar 2022)
- Another issue with deleting domes.

## v10.9 (20 Feb 2022)
- Added class name to examine>parents for ease of copying name.
- Added limit count to RetMapBreakthroughs().

### Examine:
- Log spam when examining `_G`.
- When selecting ui objects the flashing visiblity is now the flashing rectangle from xwin inspect.
- Fixed issue examining certain strings.

## v10.8 (29 Jan 2022)
- Examine may have shown an obj as on an asteroid when it wasn't.
- Added MoveRealm() (send objs to another realm).
- Added UpdateGrowthThreads() (remove deleted obj animator threads).
- An old picard fix for log spam was skipping some Path Markers underground.
- str examine now adds a title and turns autorefresh on.

## v10.7 (1 Jan 2022)
- Added RetObjMapId().
- Stopped using .entity for RetName().
- Added FlushLog() (same as FlushLogFile).
- Changed table.append to table.iappend (thanks for the heads up devs).

## v10.6 (30 Oct 2021)
- Objects in examine show which map their on (see tooltip for map id).
- Fixed "attempt to index a nil value (field 'def') (42)"

## v10.5 (3 Oct 2021)
- Re-fangled how specs are set.

### Examine:
- Shows map_id for cities.
- Tooltips show map_id object is in.

## v10.4 (20 Sep 2021)
- Removed the margins from buildable grid (it hid a couple areas of the grid numebrs).
- Forgot to check for UICity when examining a box().
- Added Chinese (Simplified) translation by aiawar.
- Added RotateBuilding(), SetPosRandomBuildablePos().
- Fixed issue with spawning veg.

## v10.3 (11 Sep 2021)
- Fixed some log spam from research text in main menu.
- Picard update (more fixes).

## v10.2 (7 Sep 2021)
- Picard update

## v10.1 (1 Aug 2021)
- Added LaunchHumanMeteor.
- Fixed issue with map locations resetting challenge mod number.
- Updated log spam remover for SurfaceDepositPreciousMinerals.

### Examine:
- Moved some more Examine funcs from ECM I missed.
- Fixed crash examining PointLight objects (okay not properly fixed, since some invisible objects do have a mesh).
- Changed Examine>table>* menu>MonitorFunc to be more forgiving.
- Clear button will now remove any bboxes added by other examines.
- Made the = in examine an orangy colour to notice it in large 'text' = 'text' tables.
- Examining tables that are both strings/numbers (g_MapSectors) are now sorted properly.

## v10.0 (21 June 2021)
- Properly fixed issue with CTD while examining certain game objects (thanks LukeH).
- Added SetBldMaintenance.
- Moved some examine funcs from ECM to Lib.
- Added my prevent blank mission profile screen fix.

## v9.9 (8 May 2021)
- Examining funcs with the blacklist enabled gave an error.
- Hopefully a fix for that HGE::l_SetPos log spam (it doesn't harm anything, but it's annoying).
- Added mod option to ignore persist errors.
- Added SetPropertyProp.
- MsgWait will pause the game.
- Check y position of my dialogs to stay on screen.

## v9.8 (24 Apr 2021)
- Forgot to check if examine needed funcs were in blacklist.
- Slight speedup for ExportMapDataToCSV.
- Made X close icon a little smaller, so it fits the height of the Examine toolbar.
- Examine: "Go to text" is now "Search".
- More params for OpenInMultiLineTextDlg.
- Sorts list of mods by title in Options>Mod Options (default was mod load order).
- Exposed mod string id lists (see Locales directory).
- Added GetLowestPointEachSector.
- Tidied up examining a dot path str.

## v9.7 (10 Apr 2021)
- Added IsArray.
- ExportMapDataToCSV has option to return data in tables instead of csv.
- CreateNumberEditor: Added param to skip creating XEdit.
- Added: Examine/ExecCode/FindValue/ImageViewer/ObjectEditor (and Open* funcs).
- Examine: Added tooltip_info/exec_tables.

## v9.6 (24 March 2021)
- Added SetChoGGiPalette, IsGamepadButtonPressed.
- DeleteObject tries to delete domes the first time instead of making you do two passes with a confusing msg.
- EmptyMechDepot Tito update.
- MsgPopup cycle objs was borked.

## v9.5 (19 March 2021)
- Added option to tame GetAllAttaches.

## v9.4 (19 March 2021)
- Made funcs use either mouse or gamepad for positions.

## v9.3 (18 March 2021)
- ModItemOptionInputBox removed (devs added it in Tito-Hotfix).
- SetLandScapingLimits has option to ignore out of bounds error for Tito.

## v9.2 (15 March 2021)
- Version number.

## v9.1 (14 March 2021)
- Added RGBtoColour.
- Added a new mod option: ModItemOptionInputBox a text input box for the user.

## v9.0 (1 March 2021)
- Fiddled with IsAttachAboveHeightLimit.
- RetAllOfClass is now MapGet.

## v8.9 (2 Jan 2021)
- Log spam.
- Error in SendDroneToCC.

## v8.8 (25 Dec 2020)
- Added mod option to toggle Mod Options button (added in v8.6).
- Added SendDroneToCC.

## v8.7 (8 Dec 2020)
- Added IsDroneIdle/GetIdleDrones/PlacePolyline/FisherYates_Shuffle.
- Changed DotNameToObject to DotPathToObject.
- RetName checks for TMeta/TConcatMeta.
- My cleanup save func may have been removing some blinky lights when saving?
- Added CycleSelectedObjects()

## v8.6 (6 Nov 2020)
- Added Open File to MultiLineText when viewing source code from Examine (opens in default text editor).
- Added a Mod Options button to the in-game menu (no idea why the devs hid it in options).
- Integrated Mod Options Expanded mod.

## v8.5 (11 Sep 2020)
- Titlebar rollup was showing exec code area (ignoring checkbox).
- Path Markers were leaving stuff in objs when the game was saved (thread log spam).

## v8.4 (13 Aug 2020)
- Moved obj path marker func into Lib.

## v8.3 (18 July 2020)
- The selected dialog will be pulled to the foreground of other dialogs.

## v8.2 (2 May 2020)
- Added code to Double upload my library mod (PC/Console).

## v8.1 (22 Apr 2020)
- Launching rockets (and probably landing) were being deleted when the game was saved.

## v8.0 (12 Apr 2020)
- Version bump.

## v7.9 (25 Mar 2020)
- Fixed accessing Tourist desc in main menu (TFormat.has_researched).

## v7.8 (20 Jan 2020)
- Added CleanInfoAttachDupes/ObjHexShape_Toggle from ECM mod.

## v7.7 (13 Jan 2020)
- Some log spam for ListDialog.
- Minor code cleanup.

## v7.6 (25 Oct 2019)
- Minor speed up for DotNameToObject.
- ReportPersistErrors log spam.
- Minor tweaks.

## v7.5 (9 Aug 2019)
- MsgPopup tried to translate numbers to string ids.
- BuildableHexGrid checks directly adjacent hexes for height diffs.

## v7.4 (5 Aug 2019)
- Blank text for certain items.

## v7.3 (3 Aug 2019)
- Cleaned up IsValidXWin.
- Added a class filter to GetAllAttaches.

## v7.2 (24 July 2019)
- Broke Filter list items last update.

## v7.1 (8 July 2019)
- RetName:
	- Uses class names instead of "Anomaly".
	- Added some more tables.
	- Just noticed that the gimped "_G" doesn't work well with pairs(), so I manually added some stuff.

## v7.0 (18 June 2019)
- Added Update Text func/button to MultiLineText.

## v6.9 (7 June 2019)
- Fixed bug in Settings.lua (thanks JajajTec).
- Sped up CSV mapdata export / removed dupes (thanks ve2dmn/Gem).

## v6.8 (1 June 2019)
- Export Map Data NESW strings were missing.
- Colour Modifier checkmarks were broked.

## v6.7 (30 May 2019)
- Cernan.

## v6.6 (22 May 2019)
- Bump.

## v6.5 (17 May 2019)
- Code cleanup.

## v6.4 (15 May 2019)
- ValidateImage didn't work with non-Library images.
- DeleteObject works with multi-selection.
- Made DotNameToObject compatible with keys that don't support dotnames (spaces and so on).
- RetName:
- Added the func names from some metatables (point,box,etc).
- Class funcs now looks like: Unit.lua(75):MoveSleep.
- Add a Msg("PostSaveGame") to the end of PersistGame().
- Removed some log spam from:
	- DeleteObject
	- List Choice dialog.

## v6.3 (30 Mar 2019)
- Added some more func names to RetName.
- Restored RetName for objlists.
- Code cleanup.

## v6.2 (17 Mar 2019)
- Xbox.

## v6.1 (15 Mar 2019)
- Code cleanup.

## v6.0 (14 Mar 2019)
- Added the func names from g_Classes to the RetName func.
- Broke the Colour Modifier last update.

## v5.9 (10 Mar 2019)
- Added a context menu to text inputs:
	- As an extra bonus found out where selection was cleared on focus loss.
- List Dialog:
- > Cleaned up hint ordering.
- > Hide custom value checkbox for certain lists (where you edit the list value instead of adding one).

## v5.8 (6 Mar 2019)
- Broke it for non-English langs.
- Pretty large code cleanup, but that should be it for awhile.

## v5.7 (5 Mar 2019)
- Fixed CSV exporting.
- Code cleanup / Moved some ECM only funcs to ECM.
- Fixed DeleteObject not deleting everything on funky modded buildings.
- DotNameToObject won't set off the "undefined global" msg anymore.
- ShowObj/ShowPoint use a list of random colours instead of just green.
- Added ... to popup menus with submenus.
- RetNam:
	- It was returning some userdata: "id" instead of translated strings.
	- It was returning "*C func" for non-C funcs.
- List Dialog:
	- Some List items were having a fake icon added (appearing as a space in front of the name).
	- Show Custom Value is now hidden by default behind the checkbox (it also scrolls to the "item").
	- custom_type 7/8 now return the checkbox states.
	- Added a skip_icons setting.
	- Change Object Colour>BaseColor works on Text, Polyline, etc objects now.

## v5.6 (25 Feb 2019)
- Changed my AttachSpots toggle func to only clear text objs from itself.
- Changed my in-game objects to use an "O" prefix to keep them separate from my Xwin objects.
- Changed my Show/Clear Obj funcs to support removing marked objs in Examine.
- Added func names to RetName func.
- My dialogs shouldn't be larger then the resolution anymore (for those with a smaller res).
- Fixed DeleteObject and the geo-dome ground.
- Sped up Toggle Object Collision (on stuff with lots of attachments).

## v5.5 (17 Feb 2019)
- Added a text search area to the MultiLineText dialog.
- Removed some log spam from MsgPop added last update.
- Fiddled around with the List dialog a bit:
	- Checkboxes are at the top, and some margins added.
	- Added a checkbox to the custom value area, and hide the listitem by default.

## v5.4 (8 Feb 2019)
- Added a bit of colour to the dialogs.
- I shrunk the Colour Modifier width an update or two ago.
- Toggling titlebar rollup on a list with hidden ok/cancel buttons stays hidden.
- Made dialog buttons/checkboxes bold text.

## v5.3 (8 Feb 2019)
- List dialog will set width by width of list items.
- Added action names/ids to RetName.
- RetName didn't work with ParSystem objects.
- Added a tooltip to the toolbar of my dialogs letting people know about rolluping them up.

## v5.2 (28 Jan 2019)
- Trying to fix some log spam made some names show up as table:XXXXXX/Missing text.

## v5.1 (25 Jan 2019)
- Support for "Next SM Update".
- Added .visible to checks for List dialog (defaults to true).

## v5.0 (3 Jan 2019)
- List dialog was sometimes showing the value instead of the text for the list.
- Editor mode toggle wasn't showing selection text till the second time it's opened.

## v4.9 (23 Dec 2018)
- List dialog:
	- Items had shrunk to the size of the text.
	- Filter Items didn't work too well on number lists.

## v4.8 (15 Dec 2018)
- Pasting RGB(0,0,0) into the colour modifier now works with the blacklist.
- My Shift-Esc to close my dialogs action wasn't getting removed from terminal actions.
- List dialogs didn't have a horizontal scroll.

## v4.7 (10 Dec 2018)
- Updates scale of opened dialogs when user changes scale in Options.
- Mushed dialogs no longer spew stuff outside of their boxes.

## v4.6 (6 Dec 2018)
- Midly broke list choice filter (for certain last items).

## v4.5 (6 Dec 2018)
- Removed length limit of dialog titles.
- the bottom entry in list dialog was never filtered.

## v4.4 (1 Dec 2018)
- More strings.
- Support for more dialogs having icons in the title bar.

## v4.3 (30 Nov 2018)
- Strings mostly, some code cleanup.

## v4.2 (29 Nov 2018)
- Cleaned up some of the UI code.
- Some log spam from list dialog.
- Filter items wasn't clearing when the filter was blank.

## v4.1 (26 Nov 2018)
- You can now paste RGB(0,0,0) or RGBA(0,0,0,0) into the colour modifier.
- Pressing enter after entering text in the value textbox in the list dialogs will fire the ok button.

## v4.0 (25 Nov 2018)
- A setting that caused a few different issues...
- Updated my large popup msgs to be smaller.

## v3.9 (24 Nov 2018)
- Shift-Esc will close an in-focus dialog.
- Hopefully fixed an issue with Change Object Colour.

## v3.8 (24 Nov 2018)
- Moved my spawn colonist func here.
- Made my random colour func work better.
- Code cleanup.

## v3.7 (21 Nov 2018)
- Fixed shuttles not paying attention to newly added/removed hills/rocks.

## v3.6 (20 Nov 2018)
- Changed my msg func to use an object that works in the main menu as well as in-game.
- Gagarin changed how certain buildings work, so change object colour and examine weren't able to list all attachments.
- List dialog filter items checks for more text.
- Checkbox menu item background turns the same colour as other menu items.

## v3.5 (18 Nov 2018)
- Other mods using XShortcutsTarget shortcuts won't be borked from this mod.
- Cleaned up some strings.
- I'll get names right one of these days.

## v3.4 (16 Nov 2018)
- Broke my get obj name function last update.

## v3.3 (15 Nov 2018)
- Code cleanup/Gagarin.

## v3.2 (6 Nov 2018)
- Code cleanup.
- Moved all my buildings/vehicles into their own category.

## v3.1 (5 Nov 2018)
- Cleaned up my DeleteObject func to remove the (hopefully) last of the log spam.
- Returns names of (some more) tables.
- Popup menus close when parent closes.

## v3.0 (1 Nov 2018)
- Better compatibility with other mods that use custom shortcut keys.
- Returns names of (some) tables.
- Shows function file/line number instead of "function: 0000000008D7C100".
- Converted UI to Use TextStyle.

## v2.9 (30 Oct 2018)
- AnimDebug_Toggle wasn't removing oriention obj.
- Slight speed up for my random colour func.

## v2.8 (24 Oct 2018)
- Strings mostly (more of an update for ECM).

## v2.7 (24 Oct 2018)
- Code cleanup.
- More icons may show up in the list choices.

## v2.6 (20 Oct 2018)
- Forgot to change a line back, and broke some tooltip hints.
- It seems I broke my blinky object awhile back.

## v2.5 (20 Oct 2018)
- Added image scaling to PopupToggle.
- Sometimes tooltip image didn't show correctly.

## v2.4 (19 Oct 2018)
- Horizontal buttons added by my mods now have a hover shine (selection panel).
- Objects spawned by ECM (ctrl-shift-s) now have a selection particle around them.

## v2.3 (17 Oct 2018)
- List choice didn't show value in hint if it was false.
- Fixed Colonists>Set Gender New.

## v2.2 (12 Oct 2018)
- Right-clicking in list dialogs will update selection.
- Sped up ToggleCollisions func.

## v2.1 (12 Oct 2018)
- Code cleanup.

## v2.0 (10 Oct 2018)
- Cleaned up locales.
- Added more functionality to spawned entity objects.
- Fixed possible issue with RotatyThing (change object colour, and some others).

## v1.9 (8 Oct 2018)
- Fixed issue with the Need/Free stuff in cheats pane not working with all/modded buildings.
- Made sure clear markers will always clear markers.

## v1.8 (2 Oct 2018)
- Submenus added to PopupToggle.
- Cleaned up a minor issue with DotNameToObject.
- Fixed issue with some overridden keybindings (thanks Bobcupcatdolphin).

## v1.7 (30 Sep 2018)
- ECM bump.

## v1.6 (28 Sep 2018)
- More strings.
- Added another custom_type to ListChoice.
- Fix for shortcuts in multiple mods.

## v1.5 (28 Sep 2018)
- More strings.
- Added/Changed some funcs.
- Removed hint from list choice list box (still shows up for title bar and Ok button).

## v1.4 (26 Sep 2018)
- Sagan Update.

## v1.3 (25 Sep 2018)
### Changed:
- Misc touchups.

## v1.2 (22 Sep 2018)
### Changed:
- Darker list items, and some hover action.
- List filter items now checks hints as well.

### Fixed:
- Messed up some of my dialog positioning code somewhere along the line.

## v1.1 (17 Sep 2018)
### Changed:
- Double-clicking a title bar will rollup the dialog into the title bar.
- If a dialog is highlighted (in blue) Shift-Esc will close it.

### Fixed:
- Couple minor issues for list choice dialogs.

## v1.0 (12 Sep 2018)
### Fixed:
- Esc will close my dialogs if the title bar is blue.

## v0.9 (9 Sep 2018)
### Added:
- More functions.
- My actions reload code.
### Changed:
- Made turning off the log for ECM more obvious.
### Fixed:
- Missed the UIScale Msg

## v0.8 (8 Sep 2018)
### Fixed:
- Broke some of my selection buttons.

## v0.7 (7 Sep 2018)
### Changed:
- Removed some more ECM only functions.
### Fixed:
- My dialogs will try to use a parent object when being opened, added a fallback if they can't.

## v0.6 (6 Sep 2018)
### Fixed:
- Problem with Examine dialogs and ECM.

## v0.5 (5 Sep 2018)
### Fixed:
- Some menus may have shown "nil" for the title.

## v0.4 (5 Sep 2018)
- *Sigh*

## v0.3 (5 Sep 2018)
### Changed:
- What mods have to look for (needed a way for them to load as soon as this mod is loaded).

## v0.2 (5 Sep 2018)
### Added:
- My `_Functions.lua` file.

## v0.1 (5 Sep 2018)
### Added:
- Moved a bunch of usually used functions/etc from ECM to here.
