![](images/customize.png?raw=true)
# How to Customize flixel-modding

```haxe
@:buildModpack(CustomMetadataFormat)
class CustomModpack extends flixel.system.FlxBaseModpack<CustomMetadataFormat> {}
```

```haxe
@:buildMetadata("metadata_file.json", "icon_file.png")
class CustomMetadataFormat extends flixel.system.FlxBaseMetadataFormat {}
```

## More documentation
[How to Setup flixel-modding](doc_setup.md)

[How to Create modpacks flixel-modding](doc_create.md)