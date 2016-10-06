#using scripts\codescripts\struct;

#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;
#using scripts\shared\visionset_mgr_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_zm_perks;

#insert scripts\zm\_zm_perk_phdflopper.gsh;
#insert scripts\zm\_zm_perks.gsh;
#insert scripts\zm\_zm_utility.gsh;

#precache( "client_fx", "_t6/misc/fx_zombie_cola_dtap_on" );

#namespace zm_perk_phdflopper;

REGISTER_SYSTEM( "zm_perk_phdflopper", &__init__, undefined )

// DEAD SHOT ( PHD FLOPPER )
	
function __init__()
{
	enable_phd_perk_for_level();
}

function enable_phd_perk_for_level()
{
	// register custom functions for hud/lua
	zm_perks::register_perk_clientfields( PERK_PHDFLOPPER, &phd_client_field_func, &phd_code_callback_func );
	zm_perks::register_perk_effects( PERK_PHDFLOPPER, PHD_MACHINE_LIGHT_FX );
	zm_perks::register_perk_init_thread( PERK_PHDFLOPPER, &init_phd );
}

function init_phd()
{
	if( IS_TRUE(level.enable_magic) )
	{
		level._effect["phd_light"]						= "_t6/misc/fx_zombie_cola_dtap_on";
	}	
}

function phd_client_field_func()
{
	clientfield::register( "toplayer", "phd_perk", VERSION_SHIP, 1, "int", &player_phd_perk_handler, !CF_HOST_ONLY, CF_CALLBACK_ZERO_ON_NEW_ENT);
	clientfield::register( "clientuimodel", PERK_CLIENTFIELD_PHDFLOPPER, VERSION_SHIP, 2, "int", undefined, !CF_HOST_ONLY, CF_CALLBACK_ZERO_ON_NEW_ENT ); 
}

function phd_code_callback_func()
{
}

function player_phd_perk_handler(localClientNum, oldVal, newVal, bNewEnt, bInitialSnap, fieldName, bWasTimeJump)
{
	if ( !self IsLocalPlayer() || IsSpectating( localClientNum, false ) || ( (isdefined(level.localPlayers[localClientNum])) && (self GetEntityNumber() != level.localPlayers[localClientNum] GetEntityNumber())) )
	{
		return;
	}
	
	if(newVal)
	{
		self UseAlternateAimParams();
	}
	else
	{
		self ClearAlternateAimParams();
	}
}
