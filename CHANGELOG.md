# 1.3.0 (July 26, 2025)

Yet another hotfix for flixel-modding

## Added
- Created a new class `flixel.system.scripting.FlxHScript` it can run HScript code with the `Flixel` library and still be functional
- Support for Polymod modpack's including grabbing a Polymod metadata and icon
- Added comments to `flixel.system.FlxModpack`
- Added `sort` to `flixel.system.FlxModding` as a way to quickly sort each modpack based on their priority parameter
- Added `debug` to `flixel.system.FlxModding` is a variable that toggles debug prints for flixel-modding
- Added `clear` to `flixel.system.FlxModding` a function that deletes all mods founds in `FlxModding.mods` along with its data
- Added `type` in `flixel.system.FlxModpack` to tell the difference between Flixel Modpacks and Polymod mod's
- Added `metaDirectory` in `flixel.system.FlxModpack` a function that acts like the `directory` function except it returns the pathway to the metadata depending on the type of modpack
- Added `iconDirectory` in `flixel.system.FlxModpack` a function that acts like the `directory` function except it returns the pathway to the icon depending on the type of modpack

## Changed
- Fixed the comment for `flixel.system.FlxModding.create` (Forgot to put in the other parameters like an idiot WOOPS!)
- Changed `caching` to `cache` in `flixel.system.FlxModding` and changed the class to the newly added `flixel.system.FlxCache`
- Changed the initializing process to not crash your project when targeting JavaScript or HTML5
- Changed the error system to where intead of it just flashing the error on screen and closing the window it brings up a whole popup explaining what happened

# 1.2.0 (July 24, 2025)

First major update for flixel-modding

## Added
- Added support for creating modpack icons & metadata files
- Added comments in `flixel.system.FlxModding` for functions and variables
- Added `updateMetadata` to `flixel.system.FlxModpack` that will take the data provided in the class and save it to the modpack's metadata file
- Added `directory` to `flixel.system.FlxModpack`, a function that forms a full directory for the requested modpack
- Added `caching` to `flixel.system.FlxModding`, a toggle for people who don’t want their assets cached when loaded (default: `false`)
- Added `update` to `flixel.system.FlxModding`, a function to update the metadata of multiple modpacks or a single one
- Added lifecycle signals to `flixel.system.FlxModding`:
  - `preModsReload` and `postModsReload` signals fire before and after mods reload
  - `preModsUpdate` and `postModsUpdate` signals fire before and after mods update
  - `onModAdded` and `onModRemoved` signals fire when modpacks are added or removed, passing the relevant `FlxModpack` instance

## Changed
- Changed `flixel.system.FlxModpack` to extend `FlxBasic`
- Changed `getAsset`, `loadAsset`, `exists`, and `isLocal` to properly support Flixel assets without crashing
- Changed `reload` from `flixel.system.FlxModding` to take an optional parameter `updateMetadata` which, when true, updates all mod metadata files on reload
- Changed `init` in `flixel.system.FlxModding` to have an optional `allowCaching` parameter to set the `caching` toggle
- Changed `toString` from `flixel.system.FlxModpack` to properly output `FlxModpack` data

## Removed
- Removed any scraps from when I was trying to make `FlxModding` work with OpenFL, I'm sorry but some things just aren't meant to be

# 1.1.0 (April 23, 2025)

First hotfix for flixel-modding

## Added
- Added `create` to `flixel.system.FlxModding` to make a new Modpack template for you to customize

## Changed
- Mirgated flixel-modding from only being accessable for HaxeFlixel version 6.0.0 to version 5.9.0 (thx swordcube)
- Changed getting Metadata has been reworked from a simple text file to an actual Json file instead
- Changed some code that when `FlxG.resetGame` is called it also reloads mods

# 1.0.0 (April 21, 2025)

First ever version of flixel-modding

## Added
- Added `init` and `reload` to `flixel.system.FlxModding` with the purpose of reloading mods and initilizing FlxModding
- Added `name`, `author`, and `active` to `flixel.system.FlxModpack` to make Modpack's more discriptive
