![](images/customize.png?raw=true)
# How to Customize flixel-modding

## 1. Creating a custom modpack

You can define your own modpack class by extending the base modpack and applying the `@:buildModpack` metadata.  
This tells flixel-modding how to build your modpack at compile-time.

```haxe
@:buildModpack(CustomMetadataFormat)
class CustomModpack extends flixel.system.FlxBaseModpack<CustomMetadataFormat> {}
```

## 2. Creating a custom metadata format

Just like modpacks, metadata formats can also be customized.  
You can use the `@:buildMetadata` metadata to point to your metadata file and icon.

```haxe
@:buildMetadata("metadata_file.json", "icon_file.png")
class CustomMetadataFormat extends flixel.system.FlxBaseMetadataFormat {}
```

This allows you to define your own metadata structure while still being compatible with flixel-modding.

## 3. Initializing flixel-modding with custom classes

When initializing flixel-modding, you can provide your own modpack class, metadata format, file system, asset system, and even custom asset paths.

```haxe
var customFileSystem:IFileSystem = new CustomFileSystem();
var customAssetSystem:IAssetSystem = new CustomAssetSystem();

var customAssetPath:String = "assets_folder";
var customModPath:String = "mods_folder";

FlxModding.init(CustomModpack, CustomMetadataFormat, customFileSystem, customAssetSystem, customAssetPath, customModPath);
```

This gives you full control over how mods are loaded, stored, and accessed within your project.

## More documentation
[How to Setup flixel-modding](doc_setup.md)

[How to Create modpacks flixel-modding](doc_create.md)

[Back to Main Page](../README.md)
