<h1 align="center">
    BetterPlacement v1.0.0
</h1>
<p align="center">
    <strong>BetterPlacement is a GUI, that helps with placing entities/props. You can place any entity/prop you want! For the gamemode like ttt you can place/hide items better, instead of guessing where is will be placed.</strong>
</p>

## Plugin status
*Be aware this plugin is still in development, so expect some changes and issues.*

## Importance details about plugin
There is no need for `models\` or `models/` infront of the model path, since the plugin will automatically detect it if it is infront or not (you can still do `models\` or `models/` if there is need to!). To spawn a walking/living chicken just do `chicken`, you don't need a path for that.

## Keybinds 
 - `Use key` (Default: E) ~ *To place the entity/prop.*
 - `Weapon inspect key` (Default: F) ~ *To rotate the entity/prop.*
 - `Reload key` (Default: R) ~ *To cancel the entity/prop.*

## Commands/ConVars
**Comamnds:**
 - `sm_spawnprop [Model path] (Added height) (Alpha/Transparncy)` ~ *The command to start the plugin.*

**ConVars:**
 - `bp_default_height` ~ *If the added height is not filled in, this will be the default value.*
 - `bp_default_alpha <0-255>` ~ *If the added Alpha/Transparncy is not filled in, this will be the default value.*
 
 - `bp_ask_argument <0/1>` ~ *If the plugin should ask for the command argument, if disabled it will fill in the default command argument(see next ConVar)*
 - `bp_default_argument <1/2>` ~ *The default command argument, if asking for the command argument is disabled.* `1` = *Added height to the entity.* / `2` = *Alpha/Transparncy.*
 
 - `bp_ask_model_type <0/1>` ~ *If the plugin should ask for the modeltype, if disabled it will fill in the default model type(see next ConVar)*
 - `bp_default_model_type <1/2>` ~ *The default model type, if asking for the model type is disabled.* `1` = *DynamicProp in other words: doesn't move.* / `2` = *MultiplayerProp in other words: does move.*

 - `bp_ask_visibility <0/1>` ~ *If the plugin should ask if the fake entity is visable to other players, if disabled it will fill in the default visibility(see next ConVar)*
 - `bp_default_visibility <0/1>` ~ *The default value if the fake entity should be visable to other players, if asking for the visibility is disabled.*
 
## For Developers
All Forwards and Natives can be found [here](https://github.com/MarsTwix/BetterPlacement/blob/master/include/betterplacement.inc)!

## Important links
 - https://github.com/MarsTwix/BetterPlacement ~ *To this github for reference and as download link.*
 - http://paste.dy.fi/9p0/plain ~ *For most prop/entity paths.*
 - https://github.com/MarsTwix/BetterPlacement/projects/2 ~ *To know what i've in mind building, building on and what is finished.*

## README legend
 - **Fake Entity** = the transparent entity, before you place the real entity.
 - **[** Command argument **]** = required.
 - **(** Command argument **)** = optional.