package flixel.system.fileSystem;

import lime.utils.AssetLibrary;
import lime.utils.Assets;

@:access(lime.utils.Assets)
@:access(lime.utils.AssetLibrary)
class WebFileSystem extends RamFileSystem
{
    public function new()
    {
        super();

        @:privateAccess
        {
            setFolder(FlxModding.assetDirectory + "/");
            setFolder(FlxModding.modsDirectory + "/");
        }

        for (library in Assets.libraries)
        {
            for (asset in library.types.keys())
            {
                switch (library.types.get(asset))
                {
                    case TEXT: setFileContent(asset, library.cachedText.get(asset));
                    case BINARY: setFileBytes(asset, library.cachedBytes.get(asset));

                    default: trace("uhh...?", asset);
                }
            }
        }
    }
}