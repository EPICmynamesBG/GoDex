package godex.godexapp;

/**
 * Created by GbearTheGenius on 7/13/16.
 */
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.os.AsyncTask;
import android.util.Log;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.UUID;

public class ServerHelper {
    static String url = "http://api.godex.io:8080/api/";
    static String charset = "UTF-8";
    static int statusCode =200;

    //get a random UUID
    static UUID uuid = UUID.randomUUID();


    //TODO Modify to deal with Array of JSON Objects
    public static JSONObject postRequest(String query) {

        HttpURLConnection connection = null;
        try {
            connection = (HttpURLConnection) new URL(url + query).openConnection();
            connection.setRequestMethod("POST");
            connection.setRequestProperty("Accept-Charset", charset);

            statusCode = connection.getResponseCode();
            if (statusCode != 200) {
                return null;
            }

            InputStream response = connection.getInputStream();
            BufferedReader bR = new BufferedReader(new InputStreamReader(response));
            String line = "";

            StringBuilder responseStrBuilder = new StringBuilder();
            while((line =  bR.readLine()) != null){
                responseStrBuilder.append(line);
            }
            response.close();

            return new JSONObject(responseStrBuilder.toString());

        } catch (IOException | JSONException e) {
            e.printStackTrace();
        }
        return new JSONObject();
    }

    public static JSONObject updateRequest(String query) {
        HttpURLConnection connection = null;
        try {
            connection = (HttpURLConnection) new URL(url + query).openConnection();
            connection.setRequestMethod("PUT");
            connection.setRequestProperty("Accept-Charset", charset);

            OutputStreamWriter out = new OutputStreamWriter(connection.getOutputStream());
            out.write("Resource content");
            out.close();

            statusCode = connection.getResponseCode();
            if (statusCode != 200) {
                return null;
            }

            InputStream response = connection.getInputStream();
            BufferedReader bR = new BufferedReader(new InputStreamReader(response));
            String line = "";

            StringBuilder responseStrBuilder = new StringBuilder();
            while((line =  bR.readLine()) != null){
                responseStrBuilder.append(line);
            }
            response.close();
            return new JSONObject(responseStrBuilder.toString());

        } catch (IOException | JSONException e) {
            e.printStackTrace();
        }
        return new JSONObject();
    }

    public static String getRequest(String query) {
        HttpURLConnection connection = null;
        try {
            connection = (HttpURLConnection) new URL(url + query).openConnection();
            connection.setRequestMethod("GET");
            connection.setRequestProperty("Accept-Charset", charset);

            statusCode = connection.getResponseCode();
            if (statusCode != 200) {
                return null;
            }

            InputStream response = connection.getInputStream();
            BufferedReader bR = new BufferedReader(  new InputStreamReader(response));
            String line = "";

            StringBuilder responseStrBuilder = new StringBuilder();
            while((line =  bR.readLine()) != null){
                responseStrBuilder.append(line);
            }
            response.close();
            return responseStrBuilder.toString();

        } catch (IOException e) {
            e.printStackTrace();
        }
        return "";
    }

    public static boolean deleteRequest(String query) {
        HttpURLConnection connection = null;
        try {
            connection = (HttpURLConnection) new URL(url + query).openConnection();
            connection.setRequestMethod("DELETE");
            connection.setRequestProperty("Accept-Charset", charset);

            statusCode = connection.getResponseCode();
            if (statusCode != 200) {
                return false;
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
        return true;
    }

    public static int getStatusCode() {
        return statusCode;
    }

    static long currID;
    static int fin;


    static AsyncTask<Void, Void, Void> taskRequest = new AsyncTask<Void, Void, Void>() {
        @Override
        protected Void doInBackground(Void... params) {

            int num = 1;
            fin = 0;

                //TODO check how many pokemon are there
                while(ServerHelper.getStatusCode() == 200 && num < 144) {

                    String query = String.format("%03d", num);
           //         Log.d("Queries", "/AllPokemon/FindById/:"+query);

                    String t = ServerHelper.getRequest("/AllPokemon/FindById/"+query);

                    t=t.substring(1, t.length()-1);

                    try {
                        JSONObject json = new JSONObject(t);
       //                 Log.i("ServerHelp: ", json+"");

                        if(json != null)
                            DataHelper.addValue(t);
                        else
                            return null;

                    } catch (JSONException e) {
                        e.printStackTrace();
                    }

                    num++;

                }
            return null;
        }

        @Override
        protected void onPostExecute(final Void token) {
            fin = 1;
        }
    };

}
//TODO THIS NEED TO HAVE THE CORRECT CODE
class LocTask extends AsyncTask<Void, Void, Void> {
    int fin = 0;
    @Override
    protected Void doInBackground(Void... params) {
        fin = 0;
        long num = ServerHelper.currID;

        String query = String.format("%03d", num);

        String t = ServerHelper.getRequest("CaughtPokemon/"+query);

        t=t.substring(1, t.length()-1);

        //get the data
        String[] spl = t.split("\\},\\{");
        DataHelper.currLocSearch = spl;

        return null;
    }

    @Override
    protected void onPostExecute(final Void token) {
        fin = 1;
    }
};
