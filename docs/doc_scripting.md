![](images/setup.png?raw=true)
# How to Script with flixel-modding

## 1. Installing hscript

Install **hscript** using haxelib.

```sh
haxelib install hscript
```

Or install **hscript** using [git](https://git-scm.com/downloads)

```sh
haxelib git hscript https://github.com/HaxeFoundation/hscript.git
```

Add the library to your `project.xml` or `project.hxp`.

```xml
<haxelib name="hscript" />
```

```haxe
this.haxelibs.push(new Haxelib("hscript"));