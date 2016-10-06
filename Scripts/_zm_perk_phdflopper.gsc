#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\system_shared;
#using scripts\shared\util_shared;
#using scripts\shared\visionset_mgr_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\zm\_util;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_pers_upgrades;
#using scripts\zm\_zm_pers_upgrades_functions;
#using scripts\zm\_zm_pers_upgrades_system;
#using scripts\zm\_zm_stats;
#using scripts\zm\_zm_utility;

#insert scripts\zm\_zm_perk_phdflopper.gsh;
#insert scripts\zm\_zm_perks.gsh;
#insert scripts\zm\_zm_utility.gsh;

#precache( "material", PHD_SHADER );
#precache( "string", "ZOMBIE_PERK_PHDFLOPPER" );
#precache( "fx", "_t6/misc/fx_zombie_cola_dtap_on" );

#namespace zm_perk_phdflopper;

REGISTER_SYSTEM( "zm_perk_phdflopper", &__init__, undefined )

// PhD Flopper

//-----------------------------------------------------------------------------------
// setup
//-----------------------------------------------------------------------------------
function __init__()
{
	enable_phd_perk_for_level();
}

function enable_phd_perk_for_level()
{	
	// register sleight of hand perk for level
	zm_perks::register_perk_basic_info( PERK_PHDFLOPPER, "phd", PHD_PERK_COST, "Hold ^3[{+activate}]^7 for PHD Flopper [Cost: &&1]", GetWeapon( PHD_PERK_BOTTLE_WEAPON ) );
	zm_perks::register_perk_precache_func( PERK_PHDFLOPPER, &phd_precache );
	zm_perks::register_perk_clientfields( PERK_PHDFLOPPER, &phd_register_clientfield, &phd_set_clientfield );
	zm_perks::register_perk_machine( PERK_PHDFLOPPER, &phd_perk_machine_setup );
	zm_perks::register_perk_threads( PERK_PHDFLOPPER, &give_phd_perk, &take_phd_perk );
	zm_perks::register_perk_host_migration_params( PERK_PHDFLOPPER, PHD_RADIANT_MACHINE_NAME, PHD_MACHINE_LIGHT_FX );
}

function phd_precache()
{
	if( IsDefined(level.phd_precache_override_func) )
	{
		[[ level.phd_precache_override_func ]]();
		return;
	}
	
	level._effect[PHD_MACHINE_LIGHT_FX] = "_t6/misc/fx_zombie_cola_dtap_on";
	
	level.machine_assets[PERK_PHDFLOPPER] = SpawnStruct();
	level.machine_assets[PERK_PHDFLOPPER].weapon = GetWeapon( PHD_PERK_BOTTLE_WEAPON );
	level.machine_assets[PERK_PHDFLOPPER].off_model = PHD_MACHINE_DISABLED_MODEL;
	level.machine_assets[PERK_PHDFLOPPER].on_model = PHD_MACHINE_ACTIVE_MODEL;
}

function phd_register_clientfield()
{
	clientfield::register("toplayer", "phd_perk", VERSION_SHIP, 1, "int");
	clientfield::register( "clientuimodel", PERK_CLIENTFIELD_PHDFLOPPER, VERSION_SHIP, 2, "int" );
}

function phd_set_clientfield( state )
{
	self clientfield::set_player_uimodel( PERK_CLIENTFIELD_PHDFLOPPER, state );
}

function phd_perk_machine_setup( use_trigger, perk_machine, bump_trigger, collision )
{
//Dont have the PhD sounds so this is using deadshots
	use_trigger.script_sound = "mus_perks_deadshot_jingle";
	use_trigger.script_string = "deadshot_perk";
	use_trigger.script_label = "mus_perks_deadshot_sting";
	use_trigger.target = PHD_RADIANT_MACHINE_NAME;
	perk_machine.script_string = "deadshot_vending";
	perk_machine.targetname = PHD_RADIANT_MACHINE_NAME;
	if(IsDefined(bump_trigger))
	{
		bump_trigger.script_string = "phd_vending";
	}
}

function give_phd_perk()
{
	self clientfield::set_to_player( "phd_perk", 1);
}

function take_phd_perk( b_pause, str_perk, str_result )
{
	self clientfield::set_to_player( "phd_perk", 0);
}
