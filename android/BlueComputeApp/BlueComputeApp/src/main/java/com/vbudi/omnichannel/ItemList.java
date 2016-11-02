package com.vbudi.omnichannel;

import android.annotation.TargetApi;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.ArrayAdapter;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.AdapterView;
import android.widget.Toast;
import android.view.View;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.util.Properties;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.util.concurrent.Exchanger;

import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.HttpResponse;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import android.os.AsyncTask;
import android.app.ProgressDialog;
import android.widget.TextView;

public class ItemList extends AppCompatActivity {

    ListView listView;
    ItemTile tileAdapter;
    String apicUrl, apicClientId;
    InventoryItem[] values;

    @Override
    public void onBackPressed() {
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_item_list);
        SharedPreferences sp = getSharedPreferences("omniChannel",0);
        SharedPreferences.Editor spe = sp.edit();

        listView = (ListView) findViewById(R.id.list);
        try {
            InputStream is = this.getAssets().open("config.properties");
            Properties props = new Properties();
            props.load(is);

            apicUrl = props.getProperty("apicUrl");
            apicClientId = props.getProperty("apicClientId");
            spe.putString("apicUrl", apicUrl);
            spe.putString("apicClientId", apicClientId);
            spe.commit();

            is.close();
        } catch (Exception e) {
        }

        String url = apicUrl+"/api/items";

        new LoadItemList().execute(url);
        listView.setOnItemClickListener(new OnItemClickListener() {

            @Override
            public void onItemClick(AdapterView<?> parent, View view,
                                    int position, long id) {

                // ListView Clicked item value
                InventoryItem  itemValue    = (InventoryItem) listView.getItemAtPosition(position);
                int itemId = itemValue.getId();

                // Show Alert
                Toast.makeText(getApplicationContext(),
                        "Position :"+position+"  ListItem : " +itemValue , Toast.LENGTH_LONG)
                        .show();
                openDetail(listView,itemId);
            }

        });
    }

    public void setItemListDisplay(ItemTile adapter) {
        listView.setAdapter(adapter);
    }

    public void openDetail(View view, int itemId) {
        Intent intent = new Intent(this, ItemDetail.class);
        SharedPreferences sp = getSharedPreferences("omniChannel",0);
        SharedPreferences.Editor spe = sp.edit();
        spe.putInt("itemId",itemId);
        spe.commit();
        System.out.println("<<<"+itemId);
        startActivity(intent);
    }

    private class LoadItemList extends AsyncTask<String, Void, Void> {

        private final HttpClient client = new DefaultHttpClient();
        private String content;
        private String error = null;
        private ProgressDialog dialog = new ProgressDialog(ItemList.this);

        protected void onPreExecute() {
            dialog.setMessage("Please wait..");
            dialog.show();
        }

        @TargetApi(19)
        protected Void doInBackground(String... urls) {
            HttpGet request = new HttpGet(urls[0]);
            // add request header
            try {
                request.addHeader("x-ibm-client-id", apicClientId);
                HttpResponse response = client.execute(request);

                System.out.println("Response Code : "
                        + response.getStatusLine().getStatusCode());

                BufferedReader rd = new BufferedReader(
                        new InputStreamReader(response.getEntity().getContent()));

                StringBuffer result = new StringBuffer();
                String line = "";
                while ((line = rd.readLine()) != null) {
                    result.append(line);
                }
                JSONArray jsonResponse;
                jsonResponse = new JSONArray(result.toString());
                int lengthJsonArr = jsonResponse.length();
                values = new InventoryItem[lengthJsonArr];
                Bitmap[] itemPicture = new Bitmap[lengthJsonArr];

                for(int i=0; i < lengthJsonArr; i++) {
                    JSONObject item = jsonResponse.getJSONObject(i);
                    values[i] = new InventoryItem(item.optInt("id"),
                            item.optString("name"),
                            item.optString("img"),
                            item.optString("description"),
                            item.optInt("price"));
                    URL newurl = new URL(apicUrl+"/"+item.optString("img"));
                    itemPicture[i] = BitmapFactory.decodeStream(newurl.openConnection().getInputStream());
                }

                tileAdapter = new ItemTile(ItemList.this, android.R.id.text1, values, itemPicture);

            } catch (Exception e) {
                e.printStackTrace();
            }

            return null;
        }

        protected void onPostExecute(Void unused) {
            setItemListDisplay(tileAdapter);
            dialog.dismiss();
        }
    }

    public class ItemTile extends ArrayAdapter<InventoryItem> {
        private InventoryItem[] items;
        private View rootView;
        private Bitmap[] itemPicture;

        public ItemTile(Context context, int textViewResourceId, InventoryItem[] items, Bitmap[] itemPicture) {
            super(context, textViewResourceId, items);
            this.items = items;
            this.itemPicture = itemPicture;
        }
        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            View v = convertView;
            if (v == null) {
                LayoutInflater vi = (LayoutInflater) getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                v = vi.inflate(R.layout.item_tile, null);
            }
            rootView = v;
            int tileId = v.getId();
            InventoryItem item = items[position];
            if (item != null) {
                ImageView img = (ImageView) v.findViewById(R.id.image);
                TextView name = (TextView) v.findViewById(R.id.name);
                TextView price = (TextView) v.findViewById(R.id.price);
                if (name != null) {
                    name.setText(item.getName());
                }
                if(price != null) {
                    price.setText("Price: $" + item.getPrice() );
                }
                if (img != null) {
                    img.setImageBitmap(itemPicture[position]);
                }
            }
            return v;
        }
    }

}
