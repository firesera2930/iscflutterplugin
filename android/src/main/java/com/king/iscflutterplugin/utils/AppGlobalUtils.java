package com.king.iscflutterplugin.utils;

import android.app.Application;

import java.lang.reflect.Method;

public class AppGlobalUtils {
    private static Application myApp;
    public static Application getApplication() {
        if(myApp==null){
            try {
                Method currentApplication = Class.forName("android.app.ActivityThread").
                        getDeclaredMethod("currentApplication");
                myApp = (Application) currentApplication.invoke(null);
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return myApp;
    }
}
