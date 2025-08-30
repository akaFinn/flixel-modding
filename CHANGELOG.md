## Changelog

# [1.5.0] **Beta** - (Augest 30, 2025)

Better scripting, Metadata Macros, and more

### Added
- Created `flixel.util.FlxModUtil` to better store functions and macros designed for modding
- Created `flixel.util.FlxScriptUtil` as a way to handle scripting for hscript, polymod, and rulescript
- Made two new signals `onModActived` and `onModDeactived` found in `FlxModding` and do exactly what you think they do
- Added `buildMetadata` to `flixel.util.FlxModUtil` a metadata tag made with macros
- Added `buildModpack` to `flixel.util.FlxModUtil` a metadata tag made with macros
- Added support for RuleScript Classes **BETA**
- Added console commands `listMods`, `reloadMods`, `toggleModding`, `activateMods`, and `deactiveMods`
- Added better documentation for flixel-modding
- Added support to create custom modpack's using `create`

### Changed
- Moved `FlxBaseMetadataFormat`, `FlxMetadataFormat`, and `PolymodMetadataFormat` to their own files
- Changed the `buildDebuggerTools` function to only run if the `FLX_DEBUG` flag is active to avoid crashing
- Updated the `README.md` to include a example of how you can inject a custom Modpack & MetadataFormat Class
- Changed the `create` function so that it detects what type it is based off the provided Metadataformat
- Changed `FlxModding.mods` to `FlxModding.modpacks`

### Removed
- Deleted the `metaPath` & `iconPath` variables from both `FlxMetadataFormat`, and `PolymodMetadataFormat`

# [1.4.0] - (Augest 23, 2025)

Custom Modpack & Metadata formatting, File & Asset System changeability, and Asset compatibility for OpenFL/Lime Assets

### Added
- Support for custom Modpack Classes
- Support for custom Metadata Formats
- Fully functional support with OpenFL's/Lime's Asset system
- Compatibility with HaxeFlixel version's under 5.9.0 (Wow so awesome and cool)
- Some more sizes for the logo so that it wouldn't look so compressed
- Created new classes: 
  - `flixel.system.FlxModpack` and `flixel.system.FlxModpack.FlxMetadataFormat` classes that are represented for flixel modpacks
  - `flixel.system.polymod.PolymodModpack` and `flixel.system.polymod.PolymodModpack.PolymodMetadataFormat` classes that are represented for polymod modpacks
  - `flixel.system.FlxBaseModpack` and `flixel.system.FlxBaseModpack.FlxBaseMetadataFormat` classes that are designed to be extended
- Added `exists` to `FlxModding` a function that checks if a modpack actually exists via a file name
- Created new File System classes:
  - `flixel.system.fileSystem.IFileSystem` an interface used as a base for all file system classes
  - `flixel.system.fileSystem.SysFileSystem` a class used as an alternative the sys package file system
  - `flixel.system.fileSystem.RamFileSystem` a class that takes cache data and uses it as its own system
  - `flixel.system.fileSystem.WebFileSystem` a class designed for JS/Web build targets
- Added `onModsCleared` a signal that gets called when the `FlxModding.clear` function gets called
- Created new Asset System classes:
  - `flixel.system.assetSystem.IAssetSystem` an interface used as a base for all asset system classes
  - `flixel.system.assetSystem.FlxAssetSystem` a class that acts as an alternative for `FlxG.assets`
- Added a button in the debugger that links back to the haxelib page
- Added a feature to the `init` function in `FlxModding` to where polymod scripted classes get parsed and loaded

### Changed
- Changed a few things in the `README.md` file to make it *cleaner* if that makes sense
- Changed how ALL modpack's load/reload, each different modpack type is no longer defined via a variable and instead each one has their own class such as `FlxModpack` or `PolymodModpack`
- Reworked how the `reload` function works so that it takes all modpack types
- Reworked the `get` function from `FlxModding` works so now its based off of the file name for the modpack and not the display name and it also checks if the modpack exists
- Fully Reworked the `create` function for `FlxModding` to know allow you to create different types of modpacks `FLIXEL`, `POLYMOD`, & `CUSTOM`
- Changed the `sort` function for `FlxModding` to be based of the `ID` parameter instead of a custom one
- Renamed the `redirect` function from `FlxModding` to `sanitize`
- Renamed the `pathway` function from `FlxModding` to `redirect`

### Removed
- All instances of OpenFL's/Lime's Asset system seen in flixel modding, and replaced their respective caching systems with `FlxCache`
- The `allowCaching` parameter for the `init` function in `flixel.system.FlxModding`
- Removed `FlxCache` due to it being pointless and fucking dumb

# [1.3.0] - (July 26, 2025)

Even more hotfixes, and Polymod support, and HScript support.

### Added
- Created a new class `flixel.system.scripting.FlxHScript` it can run HScript code with the `Flixel` library and still be functional
- Support for Polymod modpack's including grabbing a Polymod metadata and icon
- Added comments to `flixel.system.FlxModpack`
- Added `sort` to `flixel.system.FlxModding` as a way to quickly sort each modpack based on their priority parameter
- Added `debug` to `flixel.system.FlxModding` is a variable that toggles debug prints for flixel-modding
- Added `clear` to `flixel.system.FlxModding` a function that deletes all mods founds in `FlxModding.mods` along with its data
- Added `type` in `flixel.system.FlxModpack` to tell the difference between Flixel Modpacks and Polymod mod's
- Added `metaDirectory` in `flixel.system.FlxModpack` a function that acts like the `directory` function except it returns the pathway to the metadata depending on the type of modpack
- Added `iconDirectory` in `flixel.system.FlxModpack` a function that acts like the `directory` function except it returns the pathway to the icon depending on the type of modpack

### Changed
- Fixed the comment for `flixel.system.FlxModding.create` (Forgot to put in the other parameters like an idiot WOOPS!)
- Changed `caching` to `cache` in `flixel.system.FlxModding` and changed the class to the newly added `flixel.system.FlxCache`
- Changed the initializing process to not crash your project when targeting JavaScript or HTML5
- Changed the error system to where intead of it just flashing the error on screen and closing the window it brings up a whole popup explaining what happened

# [1.2.0] - (July 24, 2025)

First major update for flixel-modding.

### Added
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

### Changed
- Changed `flixel.system.FlxModpack` to extend `FlxBasic`
- Changed `getAsset`, `loadAsset`, `exists`, and `isLocal` to properly support Flixel assets without crashing
- Changed `reload` from `flixel.system.FlxModding` to take an optional parameter `updateMetadata` which, when true, updates all mod metadata files on reload
- Changed `init` in `flixel.system.FlxModding` to have an optional `allowCaching` parameter to set the `caching` toggle
- Changed `toString` from `flixel.system.FlxModpack` to properly output `FlxModpack` data

### Removed
- Removed any scraps from when I was trying to make `FlxModding` work with OpenFL, I'm sorry but some things just aren't meant to be

# [1.1.0] - (April 23, 2025)

First hotfix for flixel-modding.

### Added
- Added `create` to `flixel.system.FlxModding` to make a new Modpack template for you to customize

### Changed
- Mirgated flixel-modding from only being accessable for HaxeFlixel version 6.0.0 to version 5.9.0 (thx swordcube)
- Changed getting Metadata has been reworked from a simple text file to an actual Json file instead
- Changed some code that when `FlxG.resetGame` is called it also reloads mods

# [1.0.0] - (April 21, 2025)

First ever version of flixel-modding.

### Added
- Added `init` and `reload` to `flixel.system.FlxModding` with the purpose of reloading mods and initilizing FlxModding
- Added `name`, `author`, and `active` to `flixel.system.FlxModpack` to make Modpack's more discriptive
