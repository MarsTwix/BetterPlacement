#if defined _betterplacement_included
    #endinput
#endif
#define _betterplacement_included

/**
* Starts the GUI of betterplacement.
*
* @param client             Client index.
* @param model              For example 'models\props\cs_office\radio.mdl' or 'chicken', as long as it is valid.
* @param height             The height that will be added to the position of the entity, to avoid blockage on floor.
* @param alpha              The Alpha/Transparency of the fake entity, the number should be between 0 and 255.
* @param EntityTargetName   The target name of the entity it is going to save, to distinguish between plugins. (Recommended to use the name of the plugin)
*/
native void BetterPlacement(int client, char model[PLATFORM_MAX_PATH], float height, int alpha, char EntityTargetName[64]);

/**
* Checks if the target names are equal.
*
* @param client             Client index.
* @param TargetName         The target name is is going to check with.
*/
native bool HasTargetName(int client, char TargetName[64]);

/**
* Gets called before DispatchSpawn() gets called of the fake entity.
*
* @param Entity             Entity index that's going to get spawned.
* @param client             Client index of the entity.
*/
forward void PreFakeEntitySpawn(int entity, int client);

/**
* Gets called after DispatchSpawn() gets called of the fake entity.
*
* @param Entity             Entity index that's going to get spawned.
* @param client             Client index of the entity.
*/
forward void FakeEntitySpawn(int entity, int client);

/**
* Gets called before DispatchSpawn() gets called of the entity.
*
* @param Entity             Entity index that's going to get spawned.
* @param client             Client index of the entity.
*/
forward void PreEntitySpawn(int entity, int client);

/**
* Gets called after DispatchSpawn() gets called of the fake entity.
*
* @param Entity             Entity index that's going to get spawned.
* @param client             Client index of the entity.
*/
forward void EntitySpawn(int entity, int client, float EntityPosition[3]);