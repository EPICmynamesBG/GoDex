package godex.godexapp;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Typeface;
import android.location.Location;
import android.os.AsyncTask;
import android.os.Handler;
import android.os.Parcel;
import android.support.annotation.NonNull;
import android.support.annotation.Nullable;
import android.support.design.widget.Snackbar;
import android.support.design.widget.TabLayout;
import android.support.v4.app.ActivityCompat;
import android.support.v4.app.FragmentManager;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.SearchView;
import android.support.v7.widget.Toolbar;

import android.support.v4.app.Fragment;
import android.support.v4.app.FragmentPagerAdapter;
import android.support.v4.view.ViewPager;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;

import android.webkit.WebView;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

//import com.arlib.floatingsearchview.suggestions.model.SearchSuggestion;
import com.google.android.gms.common.api.GoogleApiClient;
import com.google.android.gms.drive.Permission;
import com.google.android.gms.location.places.AutocompleteFilter;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;


//import com.arlib.floatingsearchview.*;
//import com.arlib.floatingsearchview.suggestions.*;


import com.roughike.bottombar.BottomBar;
import com.roughike.bottombar.BottomBarBadge;
import com.roughike.bottombar.BottomBarFragment;
import com.roughike.bottombar.BottomBarTab;

import com.google.android.gms.location.*;
import com.google.android.gms.maps.*;
import com.google.android.gms.common.*;


import com.roughike.bottombar.OnTabClickListener;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Array;
import java.net.HttpURLConnection;
import java.net.URL;
import java.security.Permissions;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Locale;

public class MainActivity extends AppCompatActivity implements com.google.android.gms.location.LocationListener, GoogleApiClient.ConnectionCallbacks, GoogleApiClient.OnConnectionFailedListener, OnMapReadyCallback {

    /**
     * The {@link android.support.v4.view.PagerAdapter} that will provide
     * fragments for each of the sections. We use a
     * {@link FragmentPagerAdapter} derivative, which will keep every
     * loaded fragment in memory. If this becomes too memory intensive, it
     * may be best to switch to a
     * {@link android.support.v4.app.FragmentStatePagerAdapter}.
     */
    //private SectionsPagerAdapter mSectionsPagerAdapter;

    /**
     * The {@link ViewPager} that will host the section contents.
     */
    private ViewPager mViewPager;
    private BottomBar mBottomBar;
    private SearchView mSearchView;
    static AppCompatActivity current;

    static GoogleApiClient googleApiClient;
    GoogleMap mMap;
    private SectionsPagerAdapter mSectionsPagerAdapter;
    static Location loc;


    public void populateDex() {
        ServerHelper.taskRequest.execute();
    }


    public static void setCurr(AppCompatActivity tr) {
        current = tr;
    }

    @Override
    protected void onStart() {
        super.onStart();

        //populate the PokeDex
        populateDex();
        setCurr(this);


        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            // TODO: Consider calling
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION}, 999);

        }


    }

    @Override
    protected void onCreate(final Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.fragment_main);

       // FrameLayout frameLayout = (FrameLayout)findViewById(R.id.fragment_container);


        ///setting up the Google API
        googleApiClient = new GoogleApiClient.Builder(this)
                .addApi(LocationServices.API)
                .addConnectionCallbacks(this)
                .addOnConnectionFailedListener(this)
                .build();

        googleApiClient.connect();


        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            // TODO: Consider calling
            ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION}, 999);

        } else {
            Log.d("MapLog", "Permissions are done");
        }


//        FrameLayout rel = (FrameLayout) findViewById(R.id.framee);
//        rel.setVisibility(View.VISIBLE);

        mBottomBar = BottomBar.attach(this, savedInstanceState);

        mBottomBar.setActiveTabColor("#FFDD34");
        mBottomBar.noNavBarGoodness();




        pageNum = 0;
        PlaceholderFragment pl = new PlaceholderFragment();
        BottomBarFragment frag1 = new BottomBarFragment(pl, android.R.drawable.btn_star, "Explore");
        pageNum = 1;
        pl = new PlaceholderFragment();
        BottomBarFragment frag2 = new BottomBarFragment(pl, android.R.drawable.arrow_up_float, "Sightings");

        mBottomBar.setFragmentItems(getSupportFragmentManager(), R.id.frag_main, frag1, frag2);

        final BottomBarBadge unreadMessages1 = mBottomBar.makeBadgeForTabAt(0, "#FF0000", 0);
        final BottomBarBadge unreadMessages = mBottomBar.makeBadgeForTabAt(1, "#FF0000", 0);




        pageNum = 0;

        final OnMapReadyCallback act = this;
        final Activity thing = this;

        int u = 0;
        loc = LocationServices.FusedLocationApi.getLastLocation(googleApiClient);

        // Listen for tab changes
        mBottomBar.setOnTabClickListener(new OnTabClickListener() {


            @Override
            public void onTabSelected(int position) {
                // The user selected a tab at the specified position

                if (position == 0) {
                    Log.d("Things", "tab 1");

                    //set the Fragment to page1.xml
                    pageNum = 1;
                    unreadMessages1.show();
                    unreadMessages.hide();


//
//                    FrameLayout rel = (FrameLayout) findViewById(R.id.framee);
//                    rel.setVisibility(View.INVISIBLE);


                } else if (position == 1) {
                    Log.d("Things", "tab 2");

                    pageNum = 0;
                    //set the Fragment to page2.xml
                    unreadMessages.show();
                    unreadMessages1.hide();
                    //get Location
                    if (ActivityCompat.checkSelfPermission(thing, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(thing, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {

                        Toast.makeText(thing, "Turn on your GPS and/or give the App Permission!", Toast.LENGTH_LONG).show();
                        return;
                    }
                    loc = LocationServices.FusedLocationApi.getLastLocation(googleApiClient);
//
//                    FrameLayout rel = (FrameLayout) findViewById(R.id.framee);
//                    rel.setVisibility(View.INVISIBLE);

                }

            }

            @Override
            public void onTabReSelected(int position) {
                // The user reselected a tab at the specified position!
            }
        });


        // Create the adapter that will return a fragment for each of the three
        // primary sections of the activity.
        mSectionsPagerAdapter = new SectionsPagerAdapter(getSupportFragmentManager());

        //Set up the ViewPager with the sections adapter.
//        mViewPager = (ViewPager) findViewById(R.id.container);
//        mViewPager.setAdapter(mSectionsPagerAdapter);
//
//        TabLayout tabLayout = (TabLayout) findViewById(R.id.tabs);
//        tabLayout.setupWithViewPager(mViewPager);

    }


//    @Override
//    public boolean onCreateOptionsMenu(Menu menu) {
//        // Inflate the menu; this adds items to the action bar if it is present.
//        getMenuInflater().inflate(R.menu.menu_main, menu);
//        return true;
//    }

    //    @Override
//    public boolean onOptionsItemSelected(MenuItem item) {
//        // Handle action bar item clicks here. The action bar will
//        // automatically handle clicks on the Home/Up button, so long
//        // as you specify a parent activity in AndroidManifest.xml.
//        int id = item.getItemId();
//
//        //noinspection SimplifiableIfStatement
//        if (id == R.id.action_info) {
//            return true;
//        }
//        if(id == R.id.searchView) {
//            mSearchView.animate(); // animate, ONLY FOR MENU ITEM
//            return true;
//        }
//
//        return super.onOptionsItemSelected(item);
//    }
    static int pageNum;

    @Override
    public void onConnected(@Nullable Bundle bundle) {

    }

    @Override
    public void onConnectionSuspended(int i) {

    }

    @Override
    public void onLocationChanged(Location location) {


    }

    @Override
    public void onConnectionFailed(@NonNull ConnectionResult connectionResult) {

    }

    @Override
    public void onMapReady(GoogleMap googleMap) {


        mMap = googleMap;
        // mMap.setMyLocationEnabled(true);

        // Add a marker in Sydney and move the camera
        LatLng sydney = new LatLng(-34, 151);
        googleMap.addMarker(
                new MarkerOptions()
                        .position(sydney).title("Marker in Sydney")
                        .icon(BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_AZURE)));

        Log.d("MapLog", "Map is Ready! what is");


        CameraUpdate cu = CameraUpdateFactory.newLatLng(sydney);
        googleMap.moveCamera(cu);


    }

    static View refMap;

    /**
     * A placeholder fragment containing a simple view.
     */
    public static class PlaceholderFragment extends Fragment implements com.google.android.gms.location.LocationListener, OnMapReadyCallback {
        /**
         * The fragment argument representing the section number for this
         * fragment.
         */
        private static final String ARG_SECTION_NUMBER = "section_number";
        GoogleMap googleMap;
        Marker mPositionMarker;
        Location current;


        public PlaceholderFragment() {

        }


        /**
         * Returns a new instance of this fragment for the given section
         * number.
         */
        public static PlaceholderFragment newInstance(int sectionNumber) {
            PlaceholderFragment fragment = new PlaceholderFragment();
            Bundle args = new Bundle();

            args.putInt(ARG_SECTION_NUMBER, sectionNumber);
            fragment.setArguments(args);

            pageNum = sectionNumber;

            return fragment;

        }

        @Override
        public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {

            View rootView = null;

            //page changing
            if (pageNum == 0) {
                Log.d("Error", "Frag made " + pageNum);

                rootView = inflater.inflate(R.layout.page1, container, false);






                AutoCompleteTextView lists = (AutoCompleteTextView) rootView.findViewById(R.id.searchBar);
                ArrayAdapter<String> adapter = new ArrayAdapter<>(getActivity(), R.layout.simple_drop_down, DataHelper.key.toArray(new String[DataHelper.key.size()]));
                Log.d("SizeOData", "" + DataHelper.key.size());

                //attach it the TextView
                lists.setAdapter(adapter);

                //keep track of the page with the Map
                MainActivity.refMap = rootView;

                MapView mMapView = (MapView) rootView.findViewById(R.id.mapView);
                mMapView.onCreate(savedInstanceState);

                googleMap = mMapView.getMap();
                googleMap.getUiSettings().setMyLocationButtonEnabled(true);
                googleMap.setMyLocationEnabled(true);

                mMapView.onResume();// needed to get the map to display immediately

                try {
                    MapsInitializer.initialize(getActivity().getApplicationContext());
                } catch (Exception e) {
                    e.printStackTrace();
                }

                googleMap = mMapView.getMap();


                // latitude and longitude
                LocationRequest locReq = LocationRequest.create();
                locReq.setInterval(5000);
                locReq.setPriority(LocationRequest.PRIORITY_HIGH_ACCURACY);
                locReq.setFastestInterval(1000);

                if (ActivityCompat.checkSelfPermission(MainActivity.current, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(MainActivity.current, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {

                    return null;
                }
                //test the ImageTask
                ImageTask.Url = "http://i1.wp.com/nintendo-papercraft.com/wp-content/uploads/2014/04/pokeball.png?resize=512%2C376";
                new ImageTask().execute();

                String str = "fuck this";
                if(googleMap == null)
                    str = "nulled"
                //Do some Map things
                Log.i("MapLog","OnMapReady " + str);

                googleMap.setMyLocationEnabled(true);

                Location mloc = LocationServices.FusedLocationApi.getLastLocation(MainActivity.googleApiClient);
                current = mloc;
                googleMap.addMarker(new MarkerOptions()
                        .position(new LatLng(mloc.getLatitude(), mloc.getLongitude()))
                        .title("Hello world")
                        .icon(BitmapDescriptorFactory.fromBitmap(ImageTask.done)));
//
//                CameraPosition cameraPosition = new CameraPosition.Builder()
//                        .target(new LatLng(mloc.getLatitude(), mloc.getLongitude())).zoom(17).build();
//                googleMap.animateCamera(CameraUpdateFactory
//                        .newCameraPosition(cameraPosition));




            }
            else if (pageNum == 1) {
                Log.d("Error", "Frag made " + pageNum);
                rootView = inflater.inflate(R.layout.page2, container, false);

                WebView web = (WebView) rootView.findViewById(R.id.webView);
                web.loadUrl("http://www.infendo.com/wp-content/uploads/2012/10/whos-that-pokemon.png");

                AutoCompleteTextView lists = (AutoCompleteTextView) rootView.findViewById(R.id.searchin);
                ArrayAdapter<String> adapter = new ArrayAdapter<>(getActivity(), R.layout.simple_drop_down, DataHelper.key.toArray(new String[DataHelper.key.size()]));


                TextView tx = (TextView)rootView.findViewById(R.id.textView2);
                Typeface custom_font = Typeface.createFromAsset(getActivity().getAssets(),  "fonts/pokemon.ttf");
                tx.setTypeface(custom_font);

                //attach it the TextView
                lists.setAdapter(adapter);


            } else if (pageNum == 2) {
                Log.d("Error", "Frag made " + pageNum);
                rootView = inflater.inflate(R.layout.splash, container, false);

            }

            return rootView;


        }

        @Override
        public void onLocationChanged(Location location) {

            //remove the old marker
            //get current Location
            //put marker there
            // Get the current location
            if (ActivityCompat.checkSelfPermission(MainActivity.current, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(MainActivity.current, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {

                return;
            }


           Log.i("MapLog","LocationChanged");
            Location currentLocation = LocationServices.FusedLocationApi.getLastLocation(MainActivity.googleApiClient);
            current = currentLocation;
            // Display the current location in the UI
            if (currentLocation != null) {
                LatLng currentLatLng = new LatLng(currentLocation.getLatitude(), currentLocation.getLongitude());
                if (mPositionMarker == null) {

                    googleMap.addMarker(new MarkerOptions()
                            .position(currentLatLng)
                            .title("Eu"));
                    googleMap.moveCamera(CameraUpdateFactory.newLatLngZoom(currentLatLng, 15));
                } else
                    mPositionMarker.setPosition(currentLatLng);
            }

            CameraPosition cameraPosition = new CameraPosition.Builder()
                    .target(new LatLng(currentLocation.getLatitude(), currentLocation.getLongitude())).zoom(17).build();
            googleMap.animateCamera(CameraUpdateFactory
                    .newCameraPosition(cameraPosition));


        }

        public void addPokemon(Pokemon pokemon) {
            //Bitmap loaed
            ImageTask.Url = pokemon.getImageSource();
            new ImageTask().execute();

            //place marked on locations
            googleMap.addMarker(new MarkerOptions()
                    .position(new LatLng(loc.getLatitude(), loc.getLongitude()))
                    .icon(BitmapDescriptorFactory.fromBitmap(ImageTask.done))
                    .title("Pokemon"));


        }

        @Override
        public void onMapReady(GoogleMap googleMap) {

            if (ActivityCompat.checkSelfPermission(getActivity(), Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(getActivity(), Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {

                return;
            }

            Location mloc = LocationServices.FusedLocationApi.getLastLocation(MainActivity.googleApiClient);
            current = mloc;

            Log.i("MapLog","OnMapReady");

            googleMap.setMyLocationEnabled(true);


            googleMap.addMarker(new MarkerOptions()
                    .position(new LatLng(mloc.getLatitude(), mloc.getLongitude()))
                    .title("Hello world")
                    .icon(BitmapDescriptorFactory.fromBitmap(ImageTask.done)));

            CameraPosition cameraPosition = new CameraPosition.Builder()
                    .target(new LatLng(mloc.getLatitude(), mloc.getLongitude())).zoom(17).build();
            googleMap.animateCamera(CameraUpdateFactory
                    .newCameraPosition(cameraPosition));
        }
    }

    /**
     * A {@link FragmentPagerAdapter} that returns a fragment corresponding to
     * one of the sections/tabs/pages.
     */
    public class SectionsPagerAdapter extends FragmentPagerAdapter {

        public SectionsPagerAdapter(FragmentManager fm) {
            super(fm);
        }

        @Override
        public Fragment getItem(int position) {
            // getItem is called to instantiate the fragment for the given page.
            // Return a PlaceholderFragment (defined as a static inner class below).
            return PlaceholderFragment.newInstance(position + 1);
        }

        @Override
        public int getCount() {
            // Show 3 total pages.
            return 2;
        }

        @Override
        public CharSequence getPageTitle(int position) {
            switch (position) {
                case 0:
                    return "Fuck";
                case 1:
                    return "You";

            }
            return null;
        }
    }
}
class ImageTask extends AsyncTask<Void, Void, Bitmap> {

    static String Url;
    static Bitmap done;

    @Override
    protected Bitmap doInBackground(Void... params) {
        // Get bitmap from server
        Bitmap overlay;
        try {
            URL url = new URL(Url);
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setDoInput(true);
            connection.connect();
            InputStream input = connection.getInputStream();
            overlay = BitmapFactory.decodeStream(input);
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
        return overlay;     }

    protected void onPostExecute(Bitmap bitmap) {
        // If received bitmap successfully, draw it on our drawable
        if (bitmap != null ) {
            Bitmap marker = BitmapFactory.decodeResource(MainActivity.current.getResources(), R.drawable.custom_marker);
            if(marker == null) {
                Log.d("Error42","wat is up");
                return;
            }

            Bitmap newMarker = marker.copy(Bitmap.Config.ARGB_8888, true);
            Canvas canvas = new Canvas(newMarker);
            // Offset the drawing by 25x25
            canvas.drawBitmap(bitmap, 25, 25, null);

        }
    }
}