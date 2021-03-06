#if defined _betterplacement_included
    #endinput
#endif
#define _betterplacement_included

enum CmdArgumentType
{
    Height = 1,
    Alpha = 2
};

enum EntityPropType
{
    DynamicProp = 1,
    MultiplayerProp = 2
};

/**
* Starts the GUI of betterplacement.
*
* @param client             Client index.
* @param model              For example 'models\props\cs_office\radio.mdl' or 'chicken', as long as it is valid. ('model\' is not needed, since the plugin will pick it up and fix the issue)
* @param height             The height that will be added to the position of the entity, to avoid blockage on floor.
* @param alpha              The Alpha/Transparency of the fake entity, the number should be between 0 and 255.
* @param PropTypeArg        The prop type of the entity that is going to get placed. The prop types you can choose from are DynamicProp(1) or MultiplayerProp(2).
* @param EntityTargetName   The target name of the entity it is going to save, to distinguish between plugins. (Recommended to use the name of the plugin)
*/
native void BP_PlaceEntity(int client, char model[PLATFORM_MAX_PATH], float height, int alpha, EntityPropType PropTypeArg, char EntityTargetName[64]);

/**
* Checks if the target names are equal.
*
* @param client             Client index.
* @param TargetName         The target name is is going to check with.
*/
native bool BP_HasTargetName(int client, char TargetName[64]);

/**
* Gets called before DispatchSpawn() gets called of the fake entity.
*
* @param Entity             Entity index that's going to get spawned.
* @param client             Client index of the entity.
*/
forward void BP_OnFakeEntitySpawnPre(int entity, int client);

/**
* Gets called after DispatchSpawn() gets called of the fake entity.
*
* @param Entity             Entity index that's going to get spawned.
* @param client             Client index of the entity.
*/
forward void BP_OnFakeEntitySpawn(int entity, int client);

/**
* Gets called before DispatchSpawn() gets called of the entity.
*
* @param Entity             Entity index that's going to get spawned.
* @param client             Client index of the entity.
* @param EntityPosition     Entity's position.
* @param EntityAngle        Entity's angle.
*/
forward void BP_OnEntitySpawnPre(int entity, int client, float EntityPosition[3], float EntityAngle[3]);

/**
* Gets called after DispatchSpawn() gets called of the fake entity.
*
* @param Entity             Entity index that's going to get spawned.
* @param client             Client index of the entity.
* @param EntityPosition     Entity's position.
* @param EntityAngle        Entity's angle.
*/
forward void BP_OnEntitySpawn(int entity, int client, float EntityPosition[3], float EntityAngle[3]);