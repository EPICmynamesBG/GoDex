#!/bin/bash

# Dowloads all pokemon through a given id 

BASE_URL="http://assets.pokemon.com/assets/cms2/img/pokedex/full"
DOWNLOAD_DIR="PokemonImages"
LAST_POKEMON_ID=151


if [ ! -d $DOWNLOAD_DIR ]; then
    mkdir $DOWNLOAD_DIR;
fi

cd $DOWNLOAD_DIR;

for i in $(seq -f "%03g" 1 $LAST_POKEMON_ID)
do
    url="$BASE_URL/$i.png";
    wget $url;
    echo "Downloaded $parseId";
done

echo "Downloaded Pokemon through id $LAST_POKEMON_ID";