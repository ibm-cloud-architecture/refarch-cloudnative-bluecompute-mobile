package com.vbudi.omnichannel;

import android.annotation.TargetApi;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Point;
import android.os.AsyncTask;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.Display;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;
import android.widget.ArrayAdapter;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.ListView;
import android.widget.RatingBar;
import android.widget.TextView;

import org.apache.http.HttpResponse;
import org.apache.http.client.HttpClient;
import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.DefaultHttpClient;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URL;
import java.util.Date;
import java.util.List;
import java.util.Properties;
import java.text.DateFormat;
import java.text.SimpleDateFormat;

public class ItemDetail extends AppCompatActivity {
    int itemId;
    String apicUrl;
    String apicClientId;

    @Override
    @TargetApi(17)
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Intent intent = getIntent();

        setContentView(R.layout.activity_item_detail);
        SharedPreferences sp = getSharedPreferences("omniChannel",0);
        apicUrl = sp.getString("apicUrl",null);
        apicClientId = sp.getString("apicClientId",null);
        itemId = sp.getInt("itemId", 999);

        new LoadItem().execute(apicUrl+"/api/items/"+itemId);
        new LoadReviews().execute(apicUrl+"/api/reviews/list?itemId="+itemId);
    }

    public void displayDetailFields(InventoryItem item, Bitmap itemPicture) {
        TextView name = (TextView) this.findViewById(R.id.itemName);
        name.setText(item.getName());
        TextView desc = (TextView) this.findViewById(R.id.itemDescription);
        desc.setText(item.getDesc());
        TextView price = (TextView) this.findViewById(R.id.itemPrice);
        price.setText("$"+item.getPrice());
        ImageView img = (ImageView) this.findViewById(R.id.itemImage);
        img.setImageBitmap(itemPicture);
    }

    @Override
    public void onBackPressed() {
    }

    public void displayReviewFields(ReviewItem[] reviews) {
        ListView lv = (ListView) this.findViewById(R.id.reviewList);

        ReviewTile adapter = new ReviewTile(ItemDetail.this, android.R.id.text1, reviews);
        int numRev = reviews.length;
        float starVal=0;
        if (numRev>0)  {
            for (int i=0;i<numRev; i++) {
                starVal += reviews[i].getRating();
            }
            starVal = starVal / numRev;
        }
        RatingBar rb = (RatingBar) this.findViewById(R.id.rating);
        rb.setRating(starVal);
        rb.setFocusable(false);
        rb.setOnTouchListener(new View.OnTouchListener() {
            public boolean onTouch(View v, MotionEvent event) {
                return true;
            }
        });
        lv.setAdapter(adapter);
    }

    public void addReview(View view) {
        Intent intent = new Intent(this, AddReview.class);
        startActivity(intent);
    }

    public void loadInventory(View view) {
        Intent intent = new Intent(this, ItemList.class);
        startActivity(intent);
    }

    public class ReviewTile extends ArrayAdapter<ReviewItem> {
        private ReviewItem[] reviews;

        public ReviewTile(Context context, int textViewResourceId, ReviewItem[] reviews) {
            super(context, textViewResourceId, reviews);
            this.reviews = reviews;
        }

        @Override
        public View getView(int position, View convertView, ViewGroup parent) {
            View v = convertView;
            if (v == null) {
                LayoutInflater vi = (LayoutInflater) getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                v = vi.inflate(R.layout.review_tile, null);
            }
            ReviewItem rev = reviews[position];
            if (rev != null) {
                TextView desc = (TextView) v.findViewById(R.id.description);
                TextView name = (TextView) v.findViewById(R.id.name);
                RatingBar rating = (RatingBar) v.findViewById(R.id.rating);
                rating.setOnTouchListener(new View.OnTouchListener() {
                    public boolean onTouch(View v, MotionEvent event) {
                        return true;
                    }
                });
                rating.setFocusable(false);
                if (desc != null) {
                    desc.setText(rev.getComment());
                }
                if (name != null) {
                    name.setText(rev.getName());
                }
                if (rating != null) {
                    rating.setRating(rev.getRating());
                }
            }
            return v;
        }
    }

        private class LoadItem extends AsyncTask<String, Void, Void> {

        private final HttpClient client = new DefaultHttpClient();
        private InventoryItem item;
        private Bitmap itemPicture;
        private String error = null;
        private ProgressDialog dialog = new ProgressDialog(ItemDetail.this);

        protected void onPreExecute() {
            dialog.setMessage("Please wait..");
            dialog.show();
        }

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
                String OutputData = "";
                JSONObject jr;

                try {
                    jr = new JSONObject(result.toString());
                    URL newurl = new URL(apicUrl+"/"+jr.optString("img"));
                    itemPicture = BitmapFactory.decodeStream(newurl.openConnection().getInputStream());

                    item = new InventoryItem(jr.optInt("id"),
                            jr.optString("name"),
                            jr.optString("img"),
                            jr.optString("description"),
                            jr.optInt("price"));
                } catch (Exception e) {
                    e.printStackTrace();
                }

            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
            return null;
        }

        protected void onPostExecute(Void unused) {
            if (error != null) {
                System.out.println("Output : "+error);
            } else {
                displayDetailFields(item, itemPicture);
            }
            dialog.dismiss();
        }
    }


    private class LoadReviews extends AsyncTask<String, Void, Void> {

        private final HttpClient client = new DefaultHttpClient();
        private ReviewItem reviews[];
        private String error = null;
        private ProgressDialog dialog = new ProgressDialog(ItemDetail.this);

        protected void onPreExecute() {
            dialog.setMessage("Please wait..");
            dialog.show();
        }

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
                String OutputData = "";
                JSONArray jr;

                try {
                    jr = new JSONArray(result.toString());
                    if (jr.length()>0) {
                        int numReview = jr.length();
                        reviews = new ReviewItem[numReview];
                        for (int i=0;i<numReview;i++) {
                            JSONObject rev = jr.getJSONObject(i);
                            String dateStr = rev.getString("review_date");
                            DateFormat df = new SimpleDateFormat("MM/dd/yyyy");
                            Date revDate = new Date();
                            try {
                                revDate = df.parse(dateStr);
                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                            reviews[i] = new ReviewItem(rev.getInt("itemId"),
                                    rev.getInt("rating"),
                                    rev.getString("comment"),
                                    rev.getString("reviewer_email"),
                                    rev.getString("reviewer_name"),
                                    revDate);
                        }
                    } else {
                        reviews = new ReviewItem[0];
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                }

            } catch (IOException ioe) {
                ioe.printStackTrace();
            }
            return null;
        }

        protected void onPostExecute(Void unused) {
            if (error != null) {
                System.out.println("Output : "+error);
            } else {
                if (reviews.length>0) displayReviewFields(reviews);
            }
            dialog.dismiss();
        }
    }
}
