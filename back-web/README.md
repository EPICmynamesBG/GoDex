# PokedexGo API Documentation

{.../api/AllPokemon}

GET - Gets all of the pokemon supported in the store

{.../api/AllPokemon/Enabled}

GET - Gets all of the pokemon suppoerte in the store, that are enabled

{.../api/AllPokemon/Disabled}

GET - Gets all of the pokemon suppoerte in the store, that are disabled

{../api/FindById/:pokemon_id}
:pokemon_id - Number - Id for pokemon (also known as pid)

GET - Gets the pokemon from the store using the pid

{.../api/CaughtPokemon}

GET - Gets all of the posted caught pokemon instances

{.../api/CaughtPokemon/:pokemon_id}
:pokemon_id - Number -  Id for pokemon (also known as pid)

GET - Gets all of the caught pokemon instances using the pid

{.../api/CaughtPokemon/:uuid/:pokemon_id/:geo_lat/:geo_long}
:pokemon_id - Number - Id for  for pokemon (also known as pid)
:geo_lat - Number - Lattitude location of pokemon caught
:geo_long - Number - Longitude location of pokemon caught

POST - Adds a captured pokemon instance. Checks to make sure the pid entered exists.
     - Returns either an error from mongo, a json object containing a new error saying pid doesn't exist, or the json object of the new captured pokemon instance
