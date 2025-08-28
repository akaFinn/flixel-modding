![](images/setup.png?raw=true)
# How to Setup flixel-modding

## 1. Installing flixel-modding
Install **flixel-modding** using haxelib.

```sh
haxelib install flixel-modding
```

Add the library to your `project.xml`.

```xml
<haxelib name="flixel-modding" />
```

## 2. Creating folders

Create a folder inside your project and name it, for this example we'll just be calling our folder `mods`, but you can name it whatever you want.

**Disclaimer**
You must create a single file inside your `mods` folder **before** building your project so that the file system can register and find it, I have no idea why it can't find it without the file but this is the best workaround that I found so whatever. So because of that, your mods folder should look like this:

```
mods/
 └── mods-go-here.txt
 ```

Once that's done add the asset path to your `project.xml`.

```xml
<assets path="mods" />
```

## 3. Setting up flixel-modding

Before creating your `FlxGame` instance, initialize the modding system using the following code:

```haxe
FlxModding.init();
```

This sets up the modding environment, scans the `mods` folder, and ensures all mod assets are ready before the game starts. If this line is skipped, mods will not load.

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

## More documentation
[How to Create modpacks flixel-modding](doc_create.md)

[How to Customize flixel-modding](doc_customize.md)