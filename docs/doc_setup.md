![](assets/images/documentation/setup.png?raw=true)

Install **flixel-modding** using haxelib:

```sh
haxelib install flixel-modding
```

Add the path and the library to your `project.xml`:

```xml
<assets path="mods" />
<haxelib name="flixel-modding" />
```

Before creating your `FlxGame` instance, initialize the modding system using the following code:

```haxe
FlxModding.init();
```

This sets up the modding environment, scans the `mods/` folder, and ensures all mod assets are ready before the game starts. If this line is skipped, mods will not load.

Here’s a complete example of a `Main.hx` with modding properly initialized:

```haxe
class Main extends Sprite
{
    public function new()
    {
        FlxModding.init();
        addChild(new FlxGame(0, 0, PlayState));
    }
}
```

After setup, create a `mods/` folder in your project directory. To ensure the filesystem detects the folder, add a placeholder file inside it called something like `mods-go-here.txt`. Then place any replacement assets inside the folder, making sure the file paths match the originals. For example:

```
mods/
 ├── mods-go-here.txt
 └── images/
     └── player.png
```

If an asset with the same path and name exists in both the `mods/` folder and your default assets folder, the version from `mods/` will automatically override the default one. This allows for simple replacements without changing any code. New assets can also be added in the same way and loaded with your usual asset calls.

With this setup complete, your project is now capable of loading and swapping assets from mods. From here you can expand into creating structured mods with metadata, icons, and custom systems depending on how advanced you want your mod support to be.