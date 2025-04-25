# 1.1.0 (January 23, 2025)

First hotfix for flixel-modding
- Added a tutorial section for those visual learners
- Mirgated flixel-modding from only being accessable for HaxeFlixel version 6.0.0 to version 5.9.0 (thx swordcube)
- `flixel.system.FlxModding`: Changed getting Metadata has been reworked from a simple text file to an actual Json file instead
- `flixel.system.FlxModding`: Added `create` to make a new Modpack template for you to customize
- `flixel.system.FlxModding`: Changed some code that when `FlxG.resetGame` is called it also reloads mods

# 1.0.0 (January 21, 2025)

First ever version of flixel-modding
- `flixel.system.FlxModding`: Added `init` and `reload` with the purpose of reloading mods and initilizing FlxModding
- `flixel.system.FlxModpack`: Added `name`, `author`, and `active` to make Modpack's more discriptive
