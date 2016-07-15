package godex.godexapp;

import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Set;
import java.util.HashSet;
import java.util.TreeSet;

/**
 * Created by GbearTheGenius on 7/13/16.
 */
public class DataHelper {

    static HashMap<String,Pokemon> pokedex = new HashMap<>();
    static Set<String> key = new TreeSet<>();

    static String[] currLocSearch;

    public static void addValue( String thing) {
        JSONObject val = null;
        try {

            val = new JSONObject(thing);

        } catch (JSONException e) {
            e.printStackTrace();
        }


        try {
            Pokemon add = new Pokemon(val);
            pokedex.put(add.getName(), add);

            Log.d("Datathelper", add.toString());

        } catch (JSONException e) {
            e.printStackTrace();
        }
        key = pokedex.keySet();
    }

    public static Pokemon getVal(String name ) {
        Pokemon poke = pokedex.get(name);

        return poke;
    }

}
class Pokemon {

    private long id;
    private String name;
    private String imageSource;

    public Pokemon(JSONObject values) throws JSONException {
        //parse the JSON and extract the data to be used later
        id = values.getInt("pid");
        name = values.getString("name");
        imageSource = values.getString("image");

    }
    public long getId() {
        return id;
    }
    public String getName() {
        return name;
    }
    public String getImageSource() {
        return imageSource;
    }
    public String toString() {
        return id+": "+name;
    }

}