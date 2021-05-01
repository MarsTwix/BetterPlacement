#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <betterplacement>

//sounds
#define SND_Placing "buttons/button9.wav"
#define SND_Rotating "items/flashlight1.wav"
#define SND_Blocked "buttons/weapon_cant_buy.wav"
#define SND_Cancel "buttons/combine_button7.wav"

enum struct PlayerData
{
    //client's entities
    int ClientsFakeEntity;
    int ClientsEntity;

    int EntityRotation;

    //cvar vars
    char SecondArgument[16];
    EntityPropType ClientsPropType;
    bool ClientsVisibility;

    //if the client's entity is active
    bool active;

    //blockage vars
    bool EntityBlocked;
    bool DistanceBlocked;
    bool BlockedPlacing;
    bool CancelPlacing;

    //check if fake entity can be created
    bool GoGUI;

    //entity properties
    char model[PLATFORM_MAX_PATH];
    char EntityTargetName[64];
    float Vector2;
    int alpha;
}

//cvars
ConVar g_cDefaultHeight = null;
ConVar g_cDefaultAlpha = null;
ConVar g_cDefaultMaxDistance = null;

ConVar g_cAskArgument = null;
ConVar g_cDefaultArgument = null;

ConVar g_cAskModelType = null;
ConVar g_cDefaultModelType = null;

ConVar g_cAskVisibility = null;
ConVar g_cDefaultVisibility = null;

ConVar g_cStuckBlock = null;
ConVar g_cDistanceBlock = null;

PlayerData g_iPlayer[MAXPLAYERS+1];

//forwards
GlobalForward g_fwOnFakeEntitySpawnPre = null;
GlobalForward g_fwOnFakeEntitySpawn = null;

GlobalForward g_fwOnEntitySpawnPre = null;
GlobalForward g_fwOnEntitySpawn = null;

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
    g_cDefaultHeight = CreateConVar("bp_default_height", "5.0", "The default value of the height that will be added to the entity.");
    g_cDefaultAlpha = CreateConVar("bp_default_alpha", "190", "The default value of the alpha that will be set to the entity.");
    g_cDefaultMaxDistance = CreateConVar("bp_default_max_distance", "200", "The default value of the max distance until blockage.");

    g_cAskArgument = CreateConVar("bp_ask_argument", "1", "Asks for which command argument, if disabled default command argument will be filled in.");
    g_cDefaultArgument = CreateConVar("bp_default_argument", "1", "The default command argument, if the ask for which command argument is disabled.");

    g_cAskModelType = CreateConVar("bp_ask_model_type", "1", "Asks for the model type, if disabled default model type will be filled in.");
    g_cDefaultModelType = CreateConVar("bp_default_model_type", "2", "The default value, if the ask for model type is disabled.");

    g_cAskVisibility = CreateConVar("bp_ask_visibility", "0", "Asks if other players are allowed to see the fake entity, if disabled default visibility will be filled in.");
    g_cDefaultVisibility = CreateConVar("bp_default_visibility", "1", "The default value for if other players can see the fake entity, if the ask for visibility is disabled.");

    g_cStuckBlock = CreateConVar("bp_stuck_block", "1", "To enable the blockage if an entity will be stuck when spawned");
    g_cDistanceBlock = CreateConVar("bp_distance_block", "1", "To enable the blockage if an entity is too far from the player");

    RegAdminCmd("sm_spawnprop", Command_SpawnProp, ADMFLAG_GENERIC, "You can spawn an entity");
    RegAdminCmd("sm_removemyprop", Command_RemoveMyProp, ADMFLAG_GENERIC, "Deletes the last places entity");
    AddCommandListener(Command_Rotation, "+lookatweapon");
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_end", OnRoundEnd, EventHookMode_Post);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("BP_PlaceEntity", Native_PlaceEntity);
    CreateNative("BP_HasTargetName", Native_HasTargetName);

    g_fwOnFakeEntitySpawnPre = new GlobalForward("BP_OnFakeEntitySpawnPre", ET_Ignore, Param_Cell, Param_Cell);
    g_fwOnFakeEntitySpawn = new GlobalForward("BP_OnFakeEntitySpawn", ET_Ignore, Param_Cell, Param_Cell);
    g_fwOnEntitySpawnPre = new GlobalForward("BP_OnEntitySpawnPre", ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_Array);
    g_fwOnEntitySpawn = new GlobalForward("BP_OnEntitySpawn", ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_Array);
    return APLRes_Success;
}

public void OnMapStart()
{
    PrecacheSound(SND_Placing);
    PrecacheSound(SND_Rotating);
    PrecacheSound(SND_Blocked);
    PrecacheSound(SND_Cancel);
}

public void OnPluginEnd()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        RemoveFakeEntity(i);
    }
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        RemoveFakeEntity(i);
    }
} 

public void OnClientDisconnect(int client)
{
    RemoveFakeEntity(client);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    RemoveFakeEntity(client);
}

Action Command_SpawnProp(int client, int args)
{
    if(args == 3)
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
            return Plugin_Handled;
        }
        else
        {
            g_iPlayer[client].alpha = Arg3Int;
        }

        AskModelType(client);
        
        return Plugin_Handled;
    }

    else if(args == 2)
    {
        char arg1[PLATFORM_MAX_PATH];
        GetCmdArg(1, arg1, sizeof(arg1));
        g_iPlayer[client].model = arg1;

        char Arg2String[16];
        GetCmdArg(2, Arg2String, sizeof(Arg2String));

        if (g_cAskArgument.BoolValue == true)
        {
            g_iPlayer[client].SecondArgument = Arg2String;
            AskArgument(client);
        }
        else
        {
            if (g_cDefaultArgument.IntValue == view_as<int>(Height))
            {
                float Arg2Float = StringToFloat(Arg2String);
                g_iPlayer[client].Vector2 = Arg2Float;
            }
            else
            {
                int Arg2Int = StringToInt(Arg2String);

                if(Arg2Int > 255 || Arg2Int < 0)
                {
                    float Arg2Float = StringToFloat(Arg2String);
                    g_iPlayer[client].Vector2 = Arg2Float;

                    g_iPlayer[client].alpha = g_cDefaultAlpha.IntValue;
                }
                else
                {
                    if(Arg2Int > 255 || Arg2Int < 0)
                    {
                        PrintToChat(client, "Alpha/transparency should be between 0 and 255!");
                        return Plugin_Handled;
                    }
                    else
                    {
                        g_iPlayer[client].alpha = Arg2Int;
                        g_iPlayer[client].Vector2 = g_cDefaultHeight.FloatValue;
                    }
                }
                AskModelType(client);
            }
        }

        return Plugin_Handled;
    }
    else
    {
        PrintToChat(client, "Usage: sm_betterplacement [Modelpath/Name] (Added height) (Alpha/Transparency)");
        return Plugin_Handled;
    }
}

Action Command_RemoveMyProp(int client, int args){
    if(g_iPlayer[client].ClientsEntity != 0)
    {
        RemoveEntity(g_iPlayer[client].ClientsEntity);
        g_iPlayer[client].ClientsEntity = 0;
    }
}

//rotation with inspect
Action Command_Rotation(int client, const char[] command, int argc)
{
    if (g_iPlayer[client].active)
    {
        g_iPlayer[client].EntityRotation += 90;
        EmitSoundToClient(client, SND_Rotating);

        if (g_iPlayer[client].EntityRotation == 360)
        {
            g_iPlayer[client].EntityRotation = 0;
        }
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public int Native_PlaceEntity(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    char modelname[PLATFORM_MAX_PATH];
    GetNativeString(2, modelname, sizeof(modelname));
    g_iPlayer[client].model = modelname;

    float Vector2Num = view_as<float>(GetNativeCell(3));
    if (Vector2Num == -1)
    {
        g_iPlayer[client].Vector2 = g_cDefaultHeight.FloatValue;
    }

    else 
    {
        g_iPlayer[client].Vector2 = Vector2Num;
    }

    int AlphaNum = GetNativeCell(4);
    if (AlphaNum == -1)
    {
        g_iPlayer[client].alpha = g_cDefaultAlpha.IntValue;
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

    g_iPlayer[client].ClientsPropType = GetNativeCell(6);
    if (g_iPlayer[client].ClientsPropType != DynamicProp || g_iPlayer[client].ClientsPropType != MultiplayerProp)
    {
        PrintToServer("The entity prop type should be DynamicProp(1) or MultiplayerProp(2)!");
        return -1;
    }

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



void AskArgument(client)
{
    Panel pChooseArgument = new Panel(); 
    pChooseArgument.DrawText("Choose a command argument");
    pChooseArgument.DrawItem("Added height", ITEMDRAW_CONTROL);
    pChooseArgument.DrawItem("Alpha/Transparency", ITEMDRAW_CONTROL);
    pChooseArgument.DrawItem("", ITEMDRAW_SPACER);
    pChooseArgument.CurrentKey = 9;
    pChooseArgument.DrawItem("Cancel", ITEMDRAW_CONTROL);
    pChooseArgument.Send(client, PanelHandler_ChooseArgument, 240);
}

public int PanelHandler_ChooseArgument(Menu menu, MenuAction action, int client, int choice)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (choice)
            {
                case 1:
                {
                    g_iPlayer[client].Vector2 = StringToFloat(g_iPlayer[client].SecondArgument);
                    g_iPlayer[client].alpha = g_cDefaultAlpha.IntValue;

                    g_iPlayer[client].GoGUI = true;
                    AskModelType(client);
                }
                case 2:
                {
                    g_iPlayer[client].alpha = StringToInt(g_iPlayer[client].SecondArgument);
                    g_iPlayer[client].Vector2 = g_cDefaultHeight.FloatValue;

                    g_iPlayer[client].GoGUI = true;
                    AskModelType(client);
                }
                case 9:
                {
                    g_iPlayer[client].GoGUI = false;
                }
            }
        }
        case MenuAction_Cancel:
        {
            g_iPlayer[client].GoGUI = false;
            delete menu;
        }
    }
}


void AskModelType(int client)
{
    if(!StrEqual(g_iPlayer[client].model, "chicken",false) && g_cAskModelType.BoolValue == true){
        Panel pChoosePropType = new Panel(); 
        pChoosePropType.DrawText("Choose a prop type");
        pChoosePropType.DrawItem("Dynamic prop type", ITEMDRAW_CONTROL);
        pChoosePropType.DrawItem("Multiplayer prop type", ITEMDRAW_CONTROL);
        pChoosePropType.DrawItem("", ITEMDRAW_SPACER);
        pChoosePropType.CurrentKey = 9;
        pChoosePropType.DrawItem("Cancel", ITEMDRAW_CONTROL);
        pChoosePropType.Send(client, PanelHandler_ChoosePropType, 240);
        
    }
    else
    {   
        g_iPlayer[client].ClientsPropType = view_as<EntityPropType>(g_cDefaultModelType.IntValue);
        AskVisibility(client);
    }
}

public int PanelHandler_ChoosePropType(Menu menu, MenuAction action, int client, int choice)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (choice)
            {
                case 1:
                {
                    g_iPlayer[client].ClientsPropType = DynamicProp;
                    g_iPlayer[client].GoGUI = true;
                    AskVisibility(client);
                }
                case 2:
                {
                    g_iPlayer[client].ClientsPropType = MultiplayerProp;
                    g_iPlayer[client].GoGUI = true;
                    AskVisibility(client);
                }
                case 9:
                {
                    g_iPlayer[client].GoGUI = false;
                }
            }
        }
        case MenuAction_Cancel:
        {
            g_iPlayer[client].GoGUI = false;
            delete menu;
        }
    }
}

void AskVisibility(int client)
{
    if (g_cAskVisibility.BoolValue == true)
    {
        Panel pChooseVisibility = new Panel(); 
        pChooseVisibility.DrawText("Fake entity visible to other players");
        pChooseVisibility.DrawItem("Yes", ITEMDRAW_CONTROL);
        pChooseVisibility.DrawItem("No", ITEMDRAW_CONTROL);
        pChooseVisibility.DrawItem("", ITEMDRAW_SPACER);
        pChooseVisibility.CurrentKey = 9;
        pChooseVisibility.DrawItem("Cancel", ITEMDRAW_CONTROL);
        pChooseVisibility.Send(client, PanelHandler_ChooseVisibility, 240);
    }

    else
    {
        g_iPlayer[client].ClientsVisibility = g_cDefaultVisibility.BoolValue;
        CreateFakeEntity(client);
    }
}

public int PanelHandler_ChooseVisibility(Menu menu, MenuAction action, int client, int choice)
{
    switch (action)
    {
        case MenuAction_Select:
        {
            switch (choice)
            {
                case 1:
                {
                    g_iPlayer[client].ClientsPropType = DynamicProp;
                    g_iPlayer[client].GoGUI = true;
                    CreateFakeEntity(client);
                }
                case 2:
                {
                    g_iPlayer[client].ClientsPropType = MultiplayerProp;
                    g_iPlayer[client].GoGUI = true;
                    CreateFakeEntity(client);
                }
                case 9:
                {
                    g_iPlayer[client].GoGUI = false;
                }
            }
        }
        case MenuAction_Cancel:
        {
            g_iPlayer[client].GoGUI = false;
            delete menu;
        }
    }
}

Action CreateFakeEntity(int client)
{
    float vector[3];
    int entity;
    char ClientModel[PLATFORM_MAX_PATH];

    //checks if it not a name, but a path and adds `models/` or `models\` to the path if missed
    if (StrContains(g_iPlayer[client].model, "/") != -1 || StrContains(g_iPlayer[client].model, "\\") != -1)
    {
        ClientModel = g_iPlayer[client].model;
        if (StrContains(g_iPlayer[client].model, "models/") == -1 || StrContains(g_iPlayer[client].model, "models\\") == -1)
        {
            if (ClientModel[0] == '\\' || ClientModel[0] == '/')
            {
                Format(ClientModel, sizeof(ClientModel), "models%s", g_iPlayer[client].model);
                g_iPlayer[client].model = ClientModel;
            }
            else
            {
                Format(ClientModel, sizeof(ClientModel), "models\\%s", g_iPlayer[client].model);
                g_iPlayer[client].model = ClientModel;
            }
        }
        entity = CreateEntityByName("prop_dynamic_override");
        PrecacheModel(g_iPlayer[client].model);  
        SetEntityModel(entity, g_iPlayer[client].model);
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
        g_iPlayer[client].ClientsFakeEntity = entity;
        g_iPlayer[client].active = true;

        GetAimCoords(client, vector);
        vector[2] += g_iPlayer[client].Vector2;

        SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
        SetEntityRenderColor(entity, 255, 255, 255, g_iPlayer[client].alpha);

        SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit);

        Call_StartForward(g_fwOnFakeEntitySpawnPre);
        Call_PushCell(entity);
        Call_PushCell(client);
        Call_Finish();

        DispatchSpawn(entity);
        SetEntProp(entity, Prop_Data, "m_takedamage", 0, 1);
        TeleportEntity(entity, vector, NULL_VECTOR, NULL_VECTOR);

        Call_StartForward(g_fwOnFakeEntitySpawn);
        Call_PushCell(entity);
        Call_PushCell(client);
        Call_Finish();

        return Plugin_Handled;
    }
    return Plugin_Handled;
}

void CreateEntity(int client)
{
    //blockage messages and sounds
    if (g_iPlayer[client].EntityBlocked == true)
    {
        PrintHintText(client, "You can't place the entity there, because it is in something!");
        EmitSoundToClient(client, SND_Blocked);
    }
    else if(g_iPlayer[client].DistanceBlocked == true)
    {
        PrintHintText(client, "You can't place the entity there, because it is too far away!");
        EmitSoundToClient(client, SND_Blocked);
    }

    else
    {
        g_iPlayer[client].active = false
        float EntityPos[3];
        float angle[3];

        int entity;

        //checks if it not a name, but a path and adds `models/` or `models\` to the path if missed
        if (StrContains(g_iPlayer[client].model, "/") != -1 || StrContains(g_iPlayer[client].model, "\\") != -1)
        {
            if (g_iPlayer[client].ClientsPropType == DynamicProp)
            {
                entity = CreateEntityByName("prop_dynamic_override");
            }

            else if (g_iPlayer[client].ClientsPropType == MultiplayerProp)
            {
                entity = CreateEntityByName("prop_physics_multiplayer");
            }
            PrecacheModel(g_iPlayer[client].model);  
            SetEntityModel(entity, g_iPlayer[client].model);
        }

        //in this case used if model is 'chicken'
        else
        {
            entity = CreateEntityByName(g_iPlayer[client].model);
        }

        if (entity == -1)
        {
            PrintToChat(client, "couldn't spawn %s!", g_iPlayer[client].model);
        }
        
        else{
            g_iPlayer[client].ClientsEntity = entity;
            SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
            SetEntityRenderColor(entity, 255, 255, 255)

            GetAimCoords(client, EntityPos);
            EntityPos[2] += g_iPlayer[client].Vector2;
            angle = SetEntityAngle(client, angle);

            Call_StartForward(g_fwOnEntitySpawnPre);
            Call_PushCell(entity);
            Call_PushCell(client);
            Call_PushArray(EntityPos, 3);
            Call_PushArray(angle, 3);
            Call_Finish();

            DispatchSpawn(entity);

            RemoveEntity(g_iPlayer[client].ClientsFakeEntity);
            g_iPlayer[client].ClientsFakeEntity = 0;
            TeleportEntity(entity, EntityPos, angle, NULL_VECTOR);
            PrintHintText(client, "You've placed the entity!");
            EmitSoundToClient(client, SND_Placing);

            Call_StartForward(g_fwOnEntitySpawn);
            Call_PushCell(entity);
            Call_PushCell(client);
            Call_PushArray(EntityPos, 3);
            Call_PushArray(angle, 3);
            Call_Finish();
        }
    }
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
    if(buttons == IN_USE && g_iPlayer[client].active == true && g_iPlayer[client].BlockedPlacing == false)
    {
        g_iPlayer[client].BlockedPlacing = true;
        StopSound(client, SNDCHAN_AUTO, SND_Blocked);
        CreateEntity(client);
    }
    else if(buttons != IN_USE && g_iPlayer[client].active == true && g_iPlayer[client].BlockedPlacing == true)
    {
        g_iPlayer[client].BlockedPlacing = false;
    }

    if(buttons == IN_RELOAD && g_iPlayer[client].active == true && g_iPlayer[client].CancelPlacing == false)
    {
        g_iPlayer[client].CancelPlacing = true;
        RemoveFakeEntity(client);
        StopSound(client, SNDCHAN_AUTO, SND_Cancel);
        EmitSoundToClient(client, SND_Cancel);
        PrintHintText(client, "You have canceled the placement of the entity!")
    }
    else if(buttons != IN_RELOAD && g_iPlayer[client].active == true && g_iPlayer[client].CancelPlacing == true)
    {
        g_iPlayer[client].CancelPlacing = false;
    }
}

public void OnGameFrame()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        //blockage check
        if (g_iPlayer[i].active == true && !IsFakeClient(i) && IsClientConnected(i) && IsClientInGame(i) && i > 0 && IsPlayerAlive(i))
        { 
            float vector[3];
            float EntityAng[3];

            GetAimCoords(i, vector)
            vector[2] += g_iPlayer[i].Vector2;

            EntityAng = SetEntityAngle(i, EntityAng);

            TeleportEntity(g_iPlayer[i].ClientsFakeEntity, vector, EntityAng, NULL_VECTOR);

            float ClientPos[3];
            GetClientAbsOrigin(i, ClientPos);
            ClientPos[2] = vector[2];
            float distance = GetVectorDistance(vector, ClientPos);
            
            if (distance > g_cDefaultMaxDistance.FloatValue && g_cDistanceBlock.BoolValue)
            {
                SetEntityRenderColor(g_iPlayer[i].ClientsFakeEntity, 255, 165, 0, g_iPlayer[i].alpha);
                g_iPlayer[i].DistanceBlocked = true;
                g_iPlayer[i].EntityBlocked = false;
            }
            
            if (CheckIfEntityIsStuck(g_iPlayer[i].ClientsFakeEntity) && g_cStuckBlock.BoolValue)
            {
                SetEntityRenderColor(g_iPlayer[i].ClientsFakeEntity, 255, 0, 0, g_iPlayer[i].alpha);
                g_iPlayer[i].EntityBlocked = true;
                g_iPlayer[i].DistanceBlocked = false;
            }
            else if(!CheckIfEntityIsStuck(g_iPlayer[i].ClientsFakeEntity) && g_iPlayer[i].DistanceBlocked == false)
            {
                SetEntityRenderColor(g_iPlayer[i].ClientsFakeEntity, 255, 255, 255, g_iPlayer[i].alpha);
                g_iPlayer[i].EntityBlocked = false;

            }

            else if (distance < g_cDefaultMaxDistance.FloatValue && g_iPlayer[i].EntityBlocked == false)
            {
                SetEntityRenderColor(g_iPlayer[i].ClientsFakeEntity, 255, 255, 255, g_iPlayer[i].alpha);
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
	return ((entity > MaxClients || entity < 1) && g_iPlayer[client].ClientsFakeEntity != entity);
}

float SetEntityAngle(int client, float EntityAng[3])
{
    float ClientAng[3];

    GetEntPropVector(g_iPlayer[client].ClientsFakeEntity, Prop_Data, "m_angRotation", EntityAng);
    GetClientEyeAngles(client, ClientAng);
    EntityAng[1] = ClientAng[1];
    EntityAng[1] += g_iPlayer[client].EntityRotation;
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
    int FakeEntitysClient = GetFakeEntitysClient(entity);

    //show to everyone because of ask
    if(g_iPlayer[FakeEntitysClient].ClientsVisibility == true && g_cAskVisibility.BoolValue == true)
    {
        return Plugin_Continue;
    }

    //show to client only because of aks
    else if (entity == g_iPlayer[client].ClientsFakeEntity && g_iPlayer[FakeEntitysClient].ClientsVisibility == false && g_cAskVisibility.BoolValue == true)
    {
        return Plugin_Continue;
    }
    
    //show to everyone when by default
    else if(g_iPlayer[FakeEntitysClient].ClientsVisibility == true && g_cAskVisibility.BoolValue == false)
    {
        return Plugin_Continue;
    }

    //show to client only when by default
    else if (entity == g_iPlayer[client].ClientsFakeEntity && g_iPlayer[FakeEntitysClient].ClientsVisibility == false && g_cAskVisibility.BoolValue == false)
    {
        return Plugin_Continue;
    }
    return Plugin_Stop;
}

void RemoveFakeEntity(int client)
{
    if (g_iPlayer[client].active == true)
    {
        g_iPlayer[client].active = false;
        g_iPlayer[client].EntityRotation = 0;
        RemoveEntity(g_iPlayer[client].ClientsFakeEntity);
        g_iPlayer[client].ClientsFakeEntity = 0;
        PrintHintText(client, "");
    }
}

int GetFakeEntitysClient(int entity)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(g_iPlayer[i].ClientsFakeEntity == entity)
        {
            return 1;
        }
    }
    return -1;
}