#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\math_shared;
#using scripts\shared\system_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\util_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\visionset_mgr_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#using scripts\shared\ai\zombie_utility;

#using scripts\zm\_util;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm;
#using scripts\zm\_zm_net;
#using scripts\zm\_zm_perks;
#using scripts\zm\_zm_melee_weapon;
#using scripts\zm\_zm_pers_upgrades;
#using scripts\zm\_zm_pers_upgrades_functions;
#using scripts\zm\_zm_pers_upgrades_system;
#using scripts\zm\_zm_score;
#using scripts\zm\_zm_stats;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_laststand;

#insert scripts\zm\_zm_perks.gsh;
#insert scripts\zm\_zm_utility.gsh;
#insert scripts\zm\_zm_laststand.gsh;

#namespace zm_overrides;

function player_damage_override( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	iDamage = self check_player_damage_callbacks( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime );
	
	if( self.scene_takedamage === false )
	{
		return 0;
	}
	
	if ( IS_TRUE( self.use_adjusted_grenade_damage ) )
    {
        self.use_adjusted_grenade_damage = undefined;
        if( ( self.health > iDamage ) )
        {
        	return iDamage;
        }
    }

	if ( !iDamage )
	{
		return 0;
	}
	
	// WW (8/20/10) - Sledgehammer fix for Issue 43492. This should stop the player from taking any damage while in laststand
	if( self laststand::player_is_in_laststand() )
	{
		return 0;
	}
	
	if ( isDefined( eInflictor ) )
	{
		if ( IS_TRUE( eInflictor.water_damage ) )
		{
			return 0;
		}
	}

	if ( isDefined( eAttacker ) )
	{
		if( IS_EQUAL( eAttacker.owner, self ) ) 
		{
			return 0;
		}
		
		if( isDefined( self.ignoreAttacker ) && self.ignoreAttacker == eAttacker ) 
		{
			return 0;
		}
		
		// AR (5/30/12) - Stop Zombie players from damaging other Zombie players
		if ( IS_TRUE( self.is_zombie ) && IS_TRUE( eAttacker.is_zombie ) )
		{
			return 0;
		}
		
		if( (isDefined( eAttacker.is_zombie ) && eAttacker.is_zombie) )
		{
			self.ignoreAttacker = eAttacker;
			self thread remove_ignore_attacker();

			if ( isdefined( eAttacker.custom_damage_func ) )
			{
				iDamage = eAttacker [[ eAttacker.custom_damage_func ]]( self );
			}
		}
		
		eAttacker notify( "hit_player" ); 

		if ( isdefined( eAttacker ) && isdefined( eAttacker.func_mod_damage_override ) )
		{
			sMeansOfDeath = eAttacker [[ eAttacker.func_mod_damage_override ]]( eInflictor, sMeansOfDeath, weapon );
		}

		if( sMeansOfDeath == "MOD_FALLING")
		{
			if ( self hasperk(PERK_PHDFLOPPER))
			{
				return 0;
			}
		}
		
		if( sMeansOfDeath != "MOD_FALLING" )
		{
			self thread playSwipeSound( sMeansOfDeath, eattacker );
			if( IS_TRUE(eattacker.is_zombie) || IsPlayer(eAttacker) )
				self PlayRumbleOnEntity( "damage_heavy" );
			
			if( IS_TRUE(eattacker.is_zombie) )
			{
				self zm_audio::create_and_play_dialog( "general", "attacked" );
			}

			canExert = true;
			
			if ( IS_TRUE( level.pers_upgrade_flopper ) )
			{
				// If the player has persistent flopper power, then no exert on explosion
				if ( IS_TRUE( self.pers_upgrades_awarded[ "flopper" ] ) )
				{
					canExert = ( sMeansOfDeath != "MOD_PROJECTILE_SPLASH" && sMeansOfDeath != "MOD_GRENADE" && sMeansOfDeath != "MOD_GRENADE_SPLASH" );
				}
			}
			
			if ( IS_TRUE( canExert ) )
			{
			    if(RandomIntRange(0,1) == 0 )
			    {
			    	self thread zm_audio::playerExert( "hitmed" );
			        //self thread zm_audio::create_and_play_dialog( "general", "hitmed" );
			    }
			    else
			    {
			    	self thread zm_audio::playerExert( "hitlrg" );
			        //self thread zm_audio::create_and_play_dialog( "general", "hitlrg" );
			    }
			}
		}
	}
	
	//Audio(RG:2/1/2016) adding underwater drowning exert.
	if ( isDefined( sMeansOfDeath) && sMeansOfDeath == "MOD_DROWN")
	{
		self thread zm_audio::playerExert( "drowning", true );
		self.voxDrowning = true;
	}
	
	if( isdefined( level.perk_damage_override ) )
	{
		foreach( func in level.perk_damage_override )
		{
			n_damage = self [[ func ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime );
			if( isdefined( n_damage ) )
			{
				iDamage = n_damage;		
			}
		}
	}	
	finalDamage = iDamage;
	
		
	// claymores and freezegun shatters, like bouncing betties, harm no players
	if ( zm_utility::is_placeable_mine( weapon ) )
	{
		return 0;
	}

	if ( isDefined( self.player_damage_override ) )
	{
		self thread [[ self.player_damage_override ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime );
	}	
	
	if ( sMeansOfDeath == "MOD_PROJECTILE" || sMeansOfDeath == "MOD_PROJECTILE_SPLASH" || sMeansOfDeath == "MOD_GRENADE" || sMeansOfDeath == "MOD_GRENADE_SPLASH" || sMeansOfDeath == "MOD_EXPLOSIVE" )
	{
		// player explosive splash damage (caps explosive damage), fixes raygun damage being fatal (or grenades) when damaging yourself
		if ( !IS_TRUE( self.is_zombie ) )
		{
			// Don't do this for projectile damage coming from zombies
			if ( !isdefined( eAttacker ) || ( !IS_TRUE( eAttacker.is_zombie ) && !IS_TRUE( eAttacker.b_override_explosive_damage_cap ) ) )
			{
				if ( self hasperk(PERK_PHDFLOPPER))
				{
					return 0;
				}
				// Only do it for ray gun
				if( isdefined(weapon.name) && ((weapon.name == "ray_gun") || ( weapon.name == "ray_gun_upgraded" )) )
				{
					// Clamp it, we don't want to increase the damage from player raygun splash damage or grenade splash damage
					// Don't create more damage than we are trying to apply
					if ( ( self.health > 25 ) && ( iDamage > 25 ) )
					{
						return 25;
					}
				}
				else if ( ( self.health > 75 ) && ( iDamage > 75 ) )
				{
					return 75;
				}
			}
		}
	}

	if( iDamage < self.health )
	{
		if ( IsDefined( eAttacker ) )
		{
			if( IsDefined( level.custom_kill_damaged_VO ) )
			{
				eAttacker thread [[ level.custom_kill_damaged_VO ]]( self );
			}
			else
			{
				eAttacker.sound_damage_player = self;	
			}
			
			if( IS_TRUE( eAttacker.missingLegs ) )
			{
			    self zm_audio::create_and_play_dialog( "general", "crawl_hit" );
			}
		}
		
		// MM (08/10/09)
		return finalDamage;
	}
	
	//player died
	if( isdefined( eAttacker ) )
	{
		if(isDefined(eAttacker.animname) && eAttacker.animname == "zombie_dog")
		{
			self zm_stats::increment_client_stat( "killed_by_zdog" );
			self zm_stats::increment_player_stat( "killed_by_zdog" );
		}
		else if(IS_TRUE(eAttacker.is_avogadro))
		{
			self zm_stats::increment_client_stat( "killed_by_avogadro", false );
			self zm_stats::increment_player_stat( "killed_by_avogadro" );
		}
	}

	self thread clear_path_timers();
		
	if( level.intermission )
	{
		level waittill( "forever" );
	}
	
	// AR (3/7/12) - Keep track of which player killed player in Zombify modes like Cleansed / Turned
	// Confirmed with Alex 
	if ( level.scr_zm_ui_gametype == "zcleansed" && iDamage > 0 )
	{
		if ( IsDefined( eAttacker ) && IsPlayer( eAttacker ) && eAttacker.team != self.team && ( ( !IS_TRUE( self.laststand ) && !self laststand::player_is_in_laststand() ) || !IsDefined( self.last_player_attacker ) ) )
		{
			// Restore Health To Zombie Player
			//--------------------------------
			if ( IsDefined( eAttacker.maxhealth ) && IS_TRUE( eAttacker.is_zombie ) )
			{
				eAttacker.health = eAttacker.maxhealth;
			}
			
			//self.last_player_attacker = eAttacker;

			if ( IsDefined( level.player_kills_player ) )
			{
				self thread [[ level.player_kills_player]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime );
			}			
		}
	}
  
	players = GetPlayers();
	count = 0;
	for( i = 0; i < players.size; i++ )
	{
		if( players[i] == self || players[i].is_zombie || players[i] laststand::player_is_in_laststand() || players[i].sessionstate == "spectator" )
		{
			count++;
		}
	}
	
	if( count < players.size || (isDefined(level._game_module_game_end_check) && ![[level._game_module_game_end_check]]()) )
	{
		if ( IsDefined( self.lives ) && self.lives > 0 && IS_TRUE( level.force_solo_quick_revive ) &&  self HasPerk( PERK_QUICK_REVIVE ) )
		{
			self thread wait_and_revive();
		}
		
		// MM (08/10/09)
		return finalDamage;
	}
	
	// PORTIZ 7/27/16: added level.no_end_game_check here, because if it's true by this point, this function will end up returning finalDamage anyway. additionally, 
	// no_end_game_check has been updated to support incrementing/decrementing, which makes it more robust than a single level.check_end_solo_game_override as more
	// mechanics are introduced that require solo players to go into last stand instead of losing the game immediately
	if ( players.size == 1 && level flag::get( "solo_game" ) )
	{
		if ( IS_TRUE( level.no_end_game_check ) || ( isdefined( level.check_end_solo_game_override ) && [[level.check_end_solo_game_override]]() ) )
		{
			return finalDamage;
		}
		else if ( self.lives == 0 || !self HasPerk( PERK_QUICK_REVIVE ) )
		{
			self.intermission = true;
		}
	}
	
	// WW (01/05/11): When a two players enter a system link game and the client drops the host will be treated as if it was a solo game
	// when it wasn't. This led to SREs about undefined and int being compared on death (self.lives was never defined on the host). While
	// adding the check for the solo game flag we found that we would have to create a complex OR inside of the if check below. By breaking
	// the conditions out in to their own variables we keep the complexity without making it look like a mess.
	solo_death = ( players.size == 1 && level flag::get( "solo_game" ) && ( self.lives == 0  || !self HasPerk(PERK_QUICK_REVIVE) ) ); // there is only one player AND the flag is set AND self.lives equals 0
	non_solo_death = ( ( count > 1 || ( players.size == 1 && !level flag::get( "solo_game" ) ) ) /*&& !level.is_zombie_level*/ ); // the player size is greater than one OR ( players.size equals 1 AND solo flag isn't set ) AND not a zombify game level
	if ( (solo_death || non_solo_death) && !IS_TRUE(level.no_end_game_check ) ) // if only one player on their last life or any game that started with more than one player
	{	
		level notify("stop_suicide_trigger");
		self AllowProne( true ); //just in case
		self thread zm_laststand::PlayerLastStand( eInflictor, eAttacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, psOffsetTime );
		if( !isdefined( vDir ) )
		{
			vDir = ( 1.0, 0.0, 0.0 );
		}
		self FakeDamageFrom(vDir);
		
		level notify("last_player_died");
		if ( isdefined(level.custom_player_fake_death) )
			self thread [[level.custom_player_fake_death]](vDir, sMeansOfDeath);
		else
			self thread player_fake_death();
	}

	if( count == players.size && !IS_TRUE( level.no_end_game_check ) )
	{
		if ( players.size == 1 && level flag::get( "solo_game" ))
		{
			if ( self.lives == 0 || !self HasPerk(PERK_QUICK_REVIVE) ) // && !self laststand::player_is_in_laststand()
			{
				self.lives = 0;
				level notify("pre_end_game");
				util::wait_network_frame();
				if(level flag::get("dog_round"))
				{
					increment_dog_round_stat( "lost" );	
						
				}				
				level notify( "end_game" );
			}
			else
			{
				return finalDamage;
			}
		}
		else
		{
			level notify("pre_end_game");
			util::wait_network_frame();
			if(level flag::get("dog_round"))
			{
				increment_dog_round_stat( "lost" );	
					
			}
			level notify( "end_game" );
		}
		return 0;	// MM (09/16/09) Need to return something
	}
	else
	{
		// MM (08/10/09)
		
		surface = "flesh";
		
		return finalDamage;
	}
}

function check_player_damage_callbacks( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	if ( !isdefined( level.player_damage_callbacks ) )
	{
		return iDamage;
	}
	
	for ( i = 0; i < level.player_damage_callbacks.size; i++ )
	{
		newDamage = self [[ level.player_damage_callbacks[i] ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, weapon, vPoint, vDir, sHitLoc, psOffsetTime );
		if ( -1 != newDamage )
		{
			return newDamage;
		}
	}

	return iDamage;
}

function remove_ignore_attacker()
{
	self notify( "new_ignore_attacker" );
	self endon( "new_ignore_attacker" );
	self endon( "disconnect" );
	
	if( !isDefined( level.ignore_enemy_timer ) )
	{
		level.ignore_enemy_timer = 0.4;
	}
	
	wait( level.ignore_enemy_timer );
	
	self.ignoreAttacker = undefined;
}

function playSwipeSound( mod, attacker )
{
	if( IS_TRUE(attacker.is_zombie) || (isdefined( attacker.archetype ) && attacker.archetype == "margwa" ) )
	{
		self playsoundtoplayer( "evt_player_swiped", self );
		return;
	}
}

function clear_path_timers()
{
	zombies = GetAITeamArray( level.zombie_team );
	foreach( zombie in zombies )
	{
		if ( isdefined( zombie.favoriteenemy ) && ( zombie.favoriteenemy == self ) )
		{
			zombie.zombie_path_timer = 0;
		}
	}
}

function wait_and_revive()
{
	
	self endon( "remote_revive" );
	level flag::set( "wait_and_revive" );
	level.wait_and_revive = true;

	if ( isdefined( self.waiting_to_revive ) && self.waiting_to_revive == true )
	{
		return;
	}

	self.waiting_to_revive = true;
	self.lives--;

	if ( isdefined( level.exit_level_func ) )
	{
		self thread [[ level.exit_level_func ]]();
	}
	/*else
	{
		if ( GetPlayers().size == 1 )
		{
			level.move_away_points =  PositionQuery_Source_Navigation( GetPlayers()[0].origin, ZM_POSITION_QUERY_LAST_STAND_MOVE_DIST_MIN, ZM_POSITION_QUERY_LAST_STAND_MOVE_DIST_MAX, ZM_POSITION_QUERY_MOVE_DIST_MAX, ZM_POSITION_QUERY_RADIUS );
		}
	}*/

	solo_revive_time = 10.0;

	name = level.player_name_directive[self GetEntityNumber()];
	self.revive_hud setText( &"ZOMBIE_REVIVING_SOLO", name );
	self laststand::revive_hud_show_n_fade( solo_revive_time );

	level flag::wait_till_timeout( solo_revive_time, "instant_revive" );

	if ( level flag::get( "instant_revive" ) )
	{
		self laststand::revive_hud_show_n_fade( 1.0 );
	}
	
	level flag::clear( "wait_and_revive" );
	level.wait_and_revive = false;

	self zm_laststand::auto_revive( self );
	self.waiting_to_revive = false;
}

function player_fake_death()
{
	level notify ("fake_death");
	self notify ("fake_death");

	self TakeAllWeapons();
	self AllowStand( false );
	self AllowCrouch( false );
	self AllowProne( true );

	self.ignoreme = true;
	self EnableInvulnerability();

	wait( 1 );
	self FreezeControls( true );
}

function increment_dog_round_stat(stat)
{
	players = GetPlayers();
	foreach(player in players)
	{
		player zm_stats::increment_client_stat( "zdog_rounds_" + stat );
	}
}
