package flixel.group;

import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.system.FlxBaseMetadataFormat;
import flixel.system.FlxBaseModpack;

enum FlxModpackContainerStatus
{
    ALL;
    ACTIVE;
    INACTIVE;
}

/**
 * @author akaFinn
 * @since 1.6.0
 */
class FlxModpackContainer extends FlxTypedContainer<FlxBaseModpack<FlxBaseMetadataFormat>>
{
    public function new()
    {
        super();
    }

    public function getModpacks(?status:FlxModpackContainerStatus = ALL, ?type:FlxModpackType = null):Array<FlxBaseModpack<FlxBaseMetadataFormat>>
    {
        var result:Array<FlxBaseModpack<FlxBaseMetadataFormat>> = [];
        
        for (modpack in members)
        {
            switch (status)
            {
                default: if (type == null || modpack.type == type) result.push(modpack);
                case ACTIVE: if ((type == null || modpack.type == type) && modpack.active != false) result.push(modpack);
                case INACTIVE: if ((type == null || modpack.type == type) && modpack.active != true) result.push(modpack);
            }
        }

        return result;
    }
}