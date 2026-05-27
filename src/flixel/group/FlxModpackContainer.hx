package flixel.group;

import flixel.system.FlxBaseModpack;
import flixel.group.FlxContainer.FlxTypedContainer;

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
class FlxModpackContainer extends FlxTypedContainer<FlxBaseModpack>
{
    public function new()
    {
        super();
    }

    public function getModpacks(?status:FlxModpackContainerStatus = ALL):Array<FlxBaseModpack>
    {
        var result:Array<FlxBaseModpack> = [];
        
        for (modpack in members)
        {
            switch (status)
            {
                default: 
                    result.push(modpack);

                case ACTIVE: 
                    if (modpack.active != false) 
                        result.push(modpack);

                case INACTIVE: 
                    if (modpack.active != true) 
                        result.push(modpack);
            }
        }

        return result;
    }
}