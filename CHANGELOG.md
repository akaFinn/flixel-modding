# 1.2.0 (July 24, 2025)

First major update for flixel-modding

- Added support for creating modpack icons
- Added comments in `flixel.system.FlxModding` for functions and variables
- Changed `flixel.system.FlxModpack` to extend `FlxBasic`
- Removed any scraps from when I was trying to make `FlxModding` work with OpenFL, I'm sorry but some things just aren't meant to be ¯\_(ツ)\_/¯
- `flixel.system.FlxModpack`: Added `updateMetadata` that will take the data provided in the class and save it to the modpack's metadata file
- `flixel.system.FlxModpack`: Added `directory`, a function that forms a full directory for the requested modpack
- `flixel.system.FlxModding`: Added `caching`, a toggle for people who don’t want their assets cached when loaded (default: `false`)
- `flixel.system.FlxModding`: Added `update`, a function to update the metadata of multiple modpacks or a single one
- `flixel.system.FlxModding`: Changed `getAsset`, `loadAsset`, `exists`, and `isLocal` to properly support Flixel assets without crashing
- `flixel.system.FlxModding`: Changed `reload` to take an optional parameter `updateMetadata` which, when true, updates all mod metadata files on reload
- `flixel.system.FlxModding`: Changed `init` to have an optional `allowCaching` parameter to set the `caching` toggle
- `flixel.system.FlxModpack`: Changed `toString` to properly output `FlxModpack` data
- `flixel.system.FlxModding`: Added lifecycle signals:
  - `preModsReload` and `postModsReload` signals fire before and after mods reload
  - `preModsUpdate` and `postModsUpdate` signals fire before and after mods update
  - `onModAdded` and `onModRemoved` signals fire when modpacks are added or removed, passing the relevant `FlxModpack` instance

# 1.1.0 (April 23, 2025)

First hotfix for flixel-modding
- Mirgated flixel-modding from only being accessable for HaxeFlixel version 6.0.0 to version 5.9.0 (thx swordcube)
- `flixel.system.FlxModding`: Changed getting Metadata has been reworked from a simple text file to an actual Json file instead
- `flixel.system.FlxModding`: Added `create` to make a new Modpack template for you to customize
- `flixel.system.FlxModding`: Changed some code that when `FlxG.resetGame` is called it also reloads mods

# 1.0.0 (April 21, 2025)

First ever version of flixel-modding
- `flixel.system.FlxModding`: Added `init` and `reload` with the purpose of reloading mods and initilizing FlxModding
- `flixel.system.FlxModpack`: Added `name`, `author`, and `active` to make Modpack's more discriptive
