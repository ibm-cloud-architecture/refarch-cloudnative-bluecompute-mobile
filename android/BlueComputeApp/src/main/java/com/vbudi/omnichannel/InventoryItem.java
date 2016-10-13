package com.vbudi.omnichannel;

/**
 * Created by vbudi on 10/4/2016.
 */

public class InventoryItem {
    int id;
    String name;
    String image;
    String description;
    int price;

    public InventoryItem(int id, String name, String image, String description, int price) {
        this.id = id;
        this.name = name;
        this.image = image;
        this.description = description;
        this.price = price;
    }

    public int getId() {
        return id;
    }

    public String getImage() {
        return image;
    }

    public String getName() {
        return name;
    }

    public String getDesc() {
        return description;
    }

    public int getPrice() {
        return price;
    }

    public String toString() { return name+" $"+price; }
}