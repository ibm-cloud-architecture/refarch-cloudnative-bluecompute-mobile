package com.vbudi.omnichannel;

import android.annotation.TargetApi;
import android.app.ProgressDialog;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.AsyncTask;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.webkit.WebView;
import android.widget.Button;
import android.widget.EditText;
import android.widget.RatingBar;

import org.apache.http.HttpResponse;
import org.apache.http.NameValuePair;
import org.apache.http.client.HttpClient;
import org.apache.http.client.entity.UrlEncodedFormEntity;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.entity.StringEntity;
import org.apache.http.impl.client.DefaultHttpClient;
import org.apache.http.message.BasicNameValuePair;

import java.io.InputStream;
import java.net.URLEncoder;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.Properties;

public class AddReview extends AppCompatActivity {
    String apicUrl, apicClientId;
    int itemId;
    String accessToken;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        SharedPreferences sp = getSharedPreferences("omniChannel",0);
        apicUrl = sp.getString("apicUrl",null);
        apicClientId = sp.getString("apicClientId",null);
        itemId = sp.getInt("itemId", 999);
        accessToken = sp.getString("accessToken","");

        // do oAuth authentication
        setContentView(R.layout.activity_add_review);

        Intent intent = getIntent();
        Uri uri = intent.getData();

        if (uri != null) {
            String uriStr = uri.toString();
            int posToken = uriStr.indexOf("access")+13;
            int endToken = uriStr.indexOf("&", posToken);
            accessToken = uriStr.substring(posToken,endToken);
            sp.edit().putString("accessToken", accessToken);
            sp.edit().commit();
        }

        if (accessToken.equals("")) {
            String authUrl = apicUrl+"/oauth20/authorize?client_id="+apicClientId+"&scope=review&redirect_uri=&response_type=token&state=xyz";
            Intent i = new Intent(Intent.ACTION_VIEW);
            i.setData(Uri.parse(authUrl));
            startActivity(i);
        } else  {
            Button submitButton = (Button) findViewById(R.id.submit);
            submitButton.setOnClickListener( new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    // Submite form to API
                    SharedPreferences sp = getSharedPreferences("omniChannel",0);
                    String reviewUrl = apicUrl+"/api/reviews/comment";
                    EditText cmt = (EditText) AddReview.this.findViewById(R.id.comment);
                    EditText nm = (EditText) AddReview.this.findViewById(R.id.name);
                    RatingBar rb = (RatingBar) AddReview.this.findViewById(R.id.ratingBar);

                    new SubmitReview().execute(reviewUrl, nm.getText().toString(), cmt.getText().toString(), (new Integer(Math.round(rb.getRating()))).toString(), ""+sp.getInt("itemId",15000));
                }
            });
        }
    }

    @Override
    public void onBackPressed() {
    }

    public void loadItemDetail() {
        Intent intent = new Intent(this, ItemDetail.class);
        startActivity(intent);
    }

    private class SubmitReview extends AsyncTask<String, Void, Void> {

        private final HttpClient client = new DefaultHttpClient();
        private String content;
        private String error = null;
        private ProgressDialog dialog = new ProgressDialog(AddReview.this);

        protected void onPreExecute() {
            dialog.setMessage("Please wait..");
            dialog.show();
        }

        @TargetApi(19)
        protected Void doInBackground(String... urls) {
            HttpPost request = new HttpPost(urls[0]);

            // add request header
            try {
                String name = urls[1];
                String comment = urls[2].replaceAll("\\r\\n|\\r|\\n|\\t", " ");
                String rating = urls[3];
                String itemIdStr = urls[4];

                request.addHeader("x-ibm-client-id", apicClientId);
                request.addHeader("accept", "application/json");
                request.addHeader("authorization", "Bearer "+accessToken);
                request.addHeader("content-type", "application/json");
                //Post Data
                DateFormat df = new SimpleDateFormat("MM/dd/yyyy");
                Date today = Calendar.getInstance().getTime();
                String todayStr = df.format(today);

                StringBuffer sbJson = new StringBuffer("{");
                sbJson.append("\"reviewer_name\": \""+ name +"\",");
                sbJson.append("\"comment\": \""+comment+"\",");
                sbJson.append("\"reviewer_email\": \"bmxedu@ibm.com\",");
                sbJson.append("\"rating\": "+ rating +",");
                sbJson.append("\"review_date\": \""+todayStr+"\"    ,");
                sbJson.append("\"itemId\": "+itemIdStr+"}");

                //Encoding POST data
                request.setEntity(new StringEntity(sbJson.toString()));

                System.out.println("-=-=-"+request.getURI().toString()+"-=-=-");
                System.out.println("-=-=-"+sbJson.toString()+"-=-=-");
                HttpResponse response = client.execute(request);

                System.out.println("Response Code : " + response.getStatusLine().getStatusCode());
            } catch (Exception e) {
                e.printStackTrace();
            }

            return null;
        }

        protected void onPostExecute(Void unused) {
            dialog.dismiss();
            loadItemDetail();
        }
    }

}
