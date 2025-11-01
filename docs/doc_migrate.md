![](images/migrate.png?raw=true)
# How to Migrate to flixel-modding

If your project was previously using **Polymod**, migrating to **flixel-modding** is fast and painless.  
flixel-modding was built with full **Polymod compatibility**, meaning you don’t need to rename files, change folder layouts, or rebuild your metadata formats. It just works.

---

## 1. Remove Polymod dependencies

First, remove Polymod from your project to avoid conflicts.

### Uninstall Polymod

```sh
haxelib remove polymod
```

### Clean up your `project.xml`

Find and remove the following line:

```xml
<haxelib name="polymod" />
```

Once it’s gone, you’re ready to switch over to flixel-modding.

---

## 2. Install flixel-modding

You can learn how to install flixel-modding using the link listed under **How to Setup flixel-modding** at the bottom of the guide, or go to the **Main Page** and find the link there.

---

## 3. Replace Polymod initialization with flixel-modding

Polymod usually had something like this:

```haxe
Polymod.init({
    modRoot: "mods",
    dirs: ["example_mod"],
    framework: PolymodFramework.FLIXEL
});
```

In **flixel-modding**, all of that’s handled automatically.

Replace it with:

```haxe
FlxModding.init();
```

That’s it. flixel-modding will automatically detect any existing Polymod-style modpacks in your `mods` directory and load them using its built-in Polymod adapter.

> **Note:** Always call `FlxModding.init()` *before* creating your `FlxGame` instance, or your mods won’t load properly.

Example:

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

---

## 4. Keep your old mod structure

If you already have a Polymod setup that looks like this:

```
mods/
 └── example_mod/
      ├── _polymod_meta.json
      ├── _polymod_icon.png
      ├── data/
      ├── images/
      └── music/
```

Good news — you don’t have to touch it.

flixel-modding can **natively load Polymod-style modpacks** using its internal Polymod compatibility layer.  
That means it’ll automatically parse your existing `_polymod_meta.json` files, recognize the same metadata, and mount the assets the same way Polymod did — just with better performance and integration.

So yeah, no need to rename anything, no need to rewrite metadata formats, and no need to reorganize your mods. None of that bullshit.

---

## 5. Clean up old Polymod calls

Finally, remove any remaining Polymod-specific calls like:

```haxe
Polymod.reload();
Polymod.loadMod();
Polymod.unloadMod();
```

flixel-modding automatically handles mod loading at startup.  
If you need to toggle mods on or off, you can just adjust their metadata or use your own runtime logic.

---

## More documentation

- [How to Setup flixel-modding](doc_setup.md)
- [How to Create modpacks flixel-modding](doc_create.md)
- [How to Customize flixel-modding](doc_customize.md)
- [Back to Main Page](../README.md)
