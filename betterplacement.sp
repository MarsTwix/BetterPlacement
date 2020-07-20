#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

enum struct PlayerData
{
    int ClientsRadio;

    bool active;
    bool EntityBlocked;
    bool DistanceBlocked;

    char model[PLATFORM_MAX_PATH];
    char EntityTargetName[64];
    float Vector2;
    int alpha;
}

PlayerData g_iPlayer[MAXPLAYERS+1];

GlobalForward g_fwPreFakeEntitySpawn = null;
GlobalForward g_fwFakeEntitySpawn = null;

GlobalForward g_fwPreEntitySpawn = null;
GlobalForward g_fwEntitySpawn = null;

public Plugin myinfo =
{
    name = "Better Placement",
    author = "MarsTwix",
    description = "This is a GUI to better place entities.",
    version = "1.0.0",
    url = "clwo.eu"
};

public void OnPluginStart()
{
    RegConsoleCmd("sm_betterplacement", Command_BetterPlacement, "You can spawn an entity");
    HookEvent("player_death", Event_PlayerDeath);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("BetterPlacement", Native_BetterPlacement);
    CreateNative("HasTargetName", Native_HasTargetName);

    g_fwPreFakeEntitySpawn = new GlobalForward("PreFakeEntitySpawn", ET_Ignore, Param_Cell, Param_Cell);
    g_fwFakeEntitySpawn = new GlobalForward("FakeEntitySpawn", ET_Ignore, Param_Cell, Param_Cell);
    g_fwPreEntitySpawn = new GlobalForward("PreEntitySpawn", ET_Ignore, Param_Cell, Param_Cell);
    g_fwEntitySpawn = new GlobalForward("EntitySpawn", ET_Ignore, Param_Cell, Param_Cell, Param_Array);
    return APLRes_Success;
}

Action Command_BetterPlacement(int client, int args)
{
    if(args == 2)
    {
        char arg1[PLATFORM_MAX_PATH];
        GetCmdArg(1, arg1, sizeof(arg1));
        g_iPlayer[client].model = arg1;

        char Arg2String[16];
        GetCmdArg(2, Arg2String, sizeof(Arg2String));
        float Arg2Float = StringToFloat(Arg2String);
        g_iPlayer[client].Vector2 = Arg2Float;

        char Arg3String[4];
        GetCmdArg(3, Arg3String, sizeof(Arg3String));
        int Arg3Int = StringToInt(Arg3String);
        if(Arg3Int > 255 || Arg3Int < 0)
        {
            PrintToChat(client, "Alpha/transparency should be between 0 and 255!");
        }

        CreateFakeEntity(client);
        return Plugin_Handled;
    }
    else
    {
        PrintToChat(client, "Usage: sm_spawnentity (modelname) (height of entity) (alpha/transparency)");
        return Plugin_Handled;
    }
}

public int Native_BetterPlacement(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char modelname[PLATFORM_MAX_PATH];
    GetNativeString(2, modelname, sizeof(modelname));
    g_iPlayer[client].model = modelname;

    float Vector2Num = view_as<float>(GetNativeCell(3));
    g_iPlayer[client].Vector2 = Vector2Num;

    int AlphaNum = GetNativeCell(4);
    if (AlphaNum == -1)
    {
        g_iPlayer[client].alpha = 150;
    }
    else if(AlphaNum > 255 || AlphaNum < 0)
    {
        PrintToServer("Alpha/transparency should be between 0 and 255!");
        return -1;
    }
    else
    {
        g_iPlayer[client].alpha = AlphaNum;
    }

    char TargetName[64];
    GetNativeString(5, TargetName, sizeof(TargetName));
    g_iPlayer[client].EntityTargetName = TargetName;
    CreateFakeEntity(client);
    return 0;
}

public int Native_HasTargetName(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    char TargetName[64];
    GetNativeString(2, TargetName, sizeof(TargetName));
    if (StrEqual(TargetName, g_iPlayer[client].EntityTargetName))
    {
        return true;
    }
    else
    {
        return false;
    }
}

Action CreateFakeEntity(int client)
{
    float vector[3];
    int entity;
    if (StrContains(g_iPlayer[client].model, "/") != -1 || StrContains(g_iPlayer[client].model, "\\") != -1)
    {
        if (StrContains(g_iPlayer[client].model, "models/") != -1 || StrContains(g_iPlayer[client].model, "models\\") != -1)
        {
            entity = CreateEntityByName("prop_dynamic_override");
            PrecacheModel(g_iPlayer[client].model);  
            SetEntityModel(entity, g_iPlayer[client].model);
        }

        else
        {
            PrintToServer("couldn't spawn %s, because 'models/' or 'models\\' is forgotten at the front!", g_iPlayer[client].model)
            return Plugin_Handled;
        }
    }

    else
    {
        entity = CreateEntityByName(g_iPlayer[client].model);
    }   
    
    if (entity == -1)
    {
        PrintToServer("couldn't spawn %s!", g_iPlayer[client].model);
        return Plugin_Handled;
    }
    else if (g_iPlayer[client].active == false)
    {
        g_iPlayer[client].ClientsRadio = entity;
        g_iPlayer[client].active = true;

        GetAimCoords(client, vector);
        vector[2] += g_iPlayer[client].Vector2;
        
        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
        SetEntityRenderColor(entity, 255, 255, 255, g_iPlayer[client].alpha);

        SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

        Call_StartForward(g_fwPreFakeEntitySpawn);
        Call_PushCell(entity);
        Call_PushCell(client);
        Call_Finish();

        DispatchSpawn(entity);
        TeleportEntity(entity, vector, NULL_VECTOR, NULL_VECTOR);

        Call_StartForward(g_fwFakeEntitySpawn);
        Call_PushCell(entity);
        Call_PushCell(client);
        Call_Finish();

        return Plugin_Handled;
    }
    return Plugin_Handled;
}

void CreateEntity(int client)
{
    if (g_iPlayer[client].EntityBlocked == true)
    {
        PrintHintText(client, "You can't place the radio there, because it is in something!");
    }
    else if(g_iPlayer[client].DistanceBlocked == true)
    {
        PrintHintText(client, "You can't place the radio there, because it is too far away!");
    }
    else
    {
        g_iPlayer[client].active = false
        float EntityPos[3];
        float angle[3];

        int entity;

        if (StrContains(g_iPlayer[client].model, "/") != -1 || StrContains(g_iPlayer[client].model, "\\") != -1)
        {
            entity = CreateEntityByName("prop_physics_multiplayer");
            PrecacheModel(g_iPlayer[client].model);  
            SetEntityModel(entity, g_iPlayer[client].model);
        }

        else
        {
            entity = CreateEntityByName(g_iPlayer[client].model);
        }

        if (entity == -1)
        {
            PrintToChat(client, "couldn't spawn {yellow}%s{default}!", g_iPlayer[client].model);
        }

        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
        SetEntityRenderColor(entity, 255, 255, 255)

        GetAimCoords(client, EntityPos);
        EntityPos[2] += g_iPlayer[client].Vector2;
        angle = SetEntityAngle(client, angle);

        Call_StartForward(g_fwPreEntitySpawn);
        Call_PushCell(entity);
        Call_PushCell(client);
        Call_Finish();

        DispatchSpawn(entity);

        RemoveEntity(g_iPlayer[client].ClientsRadio);
        PrintHintText(client, "");
        TeleportEntity(entity, EntityPos, angle, NULL_VECTOR);

        Call_StartForward(g_fwEntitySpawn);
        Call_PushCell(entity);
        Call_PushCell(client);
        Call_PushArray(EntityPos, 3);
        Call_Finish();
    }
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if(buttons == IN_USE && g_iPlayer[client].active == true)
    {
        CreateEntity(client);
    }
    if(buttons == IN_RELOAD && g_iPlayer[client].active == true)
    {
        RemoveFakeEntity(client);
    }
}

public void OnGameFrame()
{
    for (int i = 0; i <= MaxClients; i++)
    {
        if (g_iPlayer[i].active == true && !IsFakeClient(i) && IsClientConnected(i) && IsClientInGame(i) && i > 0 && IsPlayerAlive(i))
        { 
            float vector[3];
            float EntityAng[3];

            GetAimCoords(i, vector)
            vector[2] += g_iPlayer[i].Vector2;

            EntityAng = SetEntityAngle(i, EntityAng);

            TeleportEntity(g_iPlayer[i].ClientsRadio, vector, EntityAng, NULL_VECTOR);

            float ClientPos[3];
            GetClientAbsOrigin(i, ClientPos);
            float distance = GetVectorDistance(vector, ClientPos);
            
        

            if (distance > 200.0)
            {
                SetEntityRenderColor(g_iPlayer[i].ClientsRadio, 255, 165, 0, 200);
                g_iPlayer[i].DistanceBlocked = true;
                g_iPlayer[i].EntityBlocked = false;
            }
            
            if (CheckIfEntityIsStuck(g_iPlayer[i].ClientsRadio))
            {
                SetEntityRenderColor(g_iPlayer[i].ClientsRadio, 255, 0, 0, 200);
                g_iPlayer[i].EntityBlocked = true;
                g_iPlayer[i].DistanceBlocked = false;
            }
            else if(!CheckIfEntityIsStuck(g_iPlayer[i].ClientsRadio) && g_iPlayer[i].DistanceBlocked == false)
            {
                SetEntityRenderColor(g_iPlayer[i].ClientsRadio, 255, 255, 255, 200);
                g_iPlayer[i].EntityBlocked = false;

            }

            else if (distance < 200.0 && g_iPlayer[i].EntityBlocked == false)
            {
                SetEntityRenderColor(g_iPlayer[i].ClientsRadio, 255, 255, 255, 200);
                g_iPlayer[i].DistanceBlocked = false;
            }
        }
    }
}

void GetAimCoords(int client, float vector[3]) {
	float vAngles[3];
	float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer, client);
	if (TR_DidHit(trace)) {   	 
		TR_GetEndPosition(vector, trace);
	}
	trace.Close();
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask, int client) {
	return ((entity > MaxClients || entity < 1) && g_iPlayer[client].ClientsRadio != entity);
}

float SetEntityAngle(int client, float EntityAng[3])
{
    float ClientAng[3];

    GetEntPropVector(g_iPlayer[client].ClientsRadio, Prop_Data, "m_angRotation", EntityAng);
    GetClientEyeAngles(client, ClientAng);
    EntityAng[1] = ClientAng[1];
    return EntityAng;
}

bool CheckIfEntityIsStuck(int entity)
{
    float vecMin[3], vecMax[3], vecOrigin[3];
	
    GetEntPropVector(entity, Prop_Send, "m_vecMins", vecMin);
    GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMax);
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);
    
    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceEntityFilterSolid);
    return TR_DidHit();
}

public bool TraceEntityFilterSolid(int entity, int contentsMask) 
{
	return (entity < MaxClients || entity < 1);
}

public Action Hook_SetTransmit(entity, client) 
{
    if (entity == g_iPlayer[client].ClientsRadio)
    {
        char time[16];
        FormatTime(time, sizeof(time), "%H:%M:%S", GetTime());
        PrintToConsoleAll("[%s] SetTransmit has been reached!", time);
        return Plugin_Continue;
    }
    return Plugin_Stop;
}
public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    RemoveFakeEntity(client);
}

public void OnClientDisconnect(int client)
{
    RemoveFakeEntity(client);
}

void RemoveFakeEntity(int client)
{
    if (g_iPlayer[client].active == true)
    {
        g_iPlayer[client].active = false;
        RemoveEntity(g_iPlayer[client].ClientsRadio);
        PrintHintText(client, "");
    }
}