package com.vbudi.omnichannel;

import java.util.Date;

public class ReviewItem {
    String comment;
    String reviewer_email;
    String reviewer_name;
    Date review_date;
    int itemId;
    int rating;

    public ReviewItem(int itemId, int rating, String comment, String email, String name, Date date) {
        this.itemId = itemId;
        this.reviewer_email = email;
        this.reviewer_name = name;
        this.review_date = date;
        this.rating = rating;
        this.comment = comment;
    }

    public String getComment() { return comment; }
    public int getRating() { return rating; }
    public String getName() { return reviewer_name; }
    public String getEmail() { return reviewer_email; }
    public int getItemId() { return itemId; }
    public Date getDate() { return review_date; }
}
