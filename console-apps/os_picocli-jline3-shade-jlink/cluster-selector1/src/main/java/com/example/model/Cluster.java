package com.example.model;

public class Cluster {
    public final String id;
    public String context;
    public String name;
    public String env;
    public String url;

    public Cluster(String id) {
        this.id = id;
    }

    public void setProperty(String prop, String val) {
        switch(prop) {
            case "context": this.context = val; break;
            case "name": this.name = val; break;
            case "env": this.env = val; break;
            case "url": this.url = val; break;
        }
    }
}
