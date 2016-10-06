# PhD flopper: ignore explosive and falling damage for Black Ops 3 Mod tools

# Note
Just to note, with the current state of the mod tools, adding the perk icon in is a little complex, so I've not put that in this

# Credits
Thank you based DTZxPorter for Wraith

# Video
[Video in action](https://www.youtube.com/watch?v=Jxyr_UBjwv0)

# How to use
- Firstly, you will need to use Wraith(Thank you Porter) to extract the models for PhD Flopper.
- Inside zm_perk_phdflopper.gsh, change the defined variables: ``PHD_MACHINE_DISABLED_MODEL`` and ``PHD_MACHINE_ACTIVE_MODEL`` to the names of the models you have imported.

- Copy the gsc files to your root/usermaps/mapname/scripts/zm folder
  - [zm_overrides.gsc](Scripts/zm_overrides.gsc)
  - [\_zm_perk_phdflopper.gsc](Scripts/_zm_perk_phdflopper.gsc)
  - [\_zm_perk_phdflopper.csc](Scripts/_zm_perk_phdflopper.csc)
  - [\_zm_perk_phdflopper.gsh](Scripts/_zm_perk_phdflopper.gsh)
- Add ``#using scripts\zm\zm_overrides;`` beneath ``#using scripts\zm\_zm_zonemgr;`` in your zm_mapname.gsc, located in the same folder.
- Add the line ``level.overridePlayerDamage = &zm_overrides::player_damage_override;`` inside function main()
