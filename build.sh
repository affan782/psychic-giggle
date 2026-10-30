#!/usr/bin/env bash
set -euo pipefail

# Generates and builds the KK Daily Android WebView app on a cloud runner.

mkdir -p app/src/main/java/com/kkdaily/app
mkdir -p app/src/main/res/values app/src/main/res/drawable

cat > settings.gradle <<'GRADLE'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = 'KKDaily'
include ':app'
GRADLE

cat > build.gradle <<'GRADLE'
plugins {
    id 'com.android.application' version '8.7.3' apply false
}
GRADLE

cat > gradle.properties <<'GRADLE'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
org.gradle.parallel=true
android.useAndroidX=true
GRADLE

cat > app/build.gradle <<'GRADLE'
plugins {
    id 'com.android.application'
}

android {
    namespace 'com.kkdaily.app'
    compileSdk 35

    defaultConfig {
        applicationId 'com.kkdaily.app'
        minSdk 23
        targetSdk 32
        versionCode 1
        versionName '1.0.0'
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}
GRADLE

cat > app/src/main/AndroidManifest.xml <<'MANIFEST'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />

    <application
        android:allowBackup="false"
        android:icon="@drawable/ic_launcher"
        android:label="KK Daily"
        android:supportsRtl="true"
        android:theme="@style/AppTheme"
        android:usesCleartextTraffic="false">
        <activity
            android:name=".MainActivity"
            android:configChanges="orientation|screenSize|keyboardHidden"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
MANIFEST

cat > app/src/main/res/values/styles.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme" parent="android:style/Theme.Material.Light.NoActionBar">
        <item name="android:fontFamily">sans</item>
        <item name="android:colorAccent">#7FF451</item>
        <item name="android:statusBarColor">#1E0D3B</item>
        <item name="android:navigationBarColor">#1E0D3B</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:windowActionModeOverlay">true</item>
        <item name="android:windowBackground">#FFFFFF</item>
    </style>
</resources>
XML

cat > app/src/main/res/drawable/ic_launcher.xml <<'XML'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#1E0D3B" android:pathData="M0,0h108v108h-108z" />
    <path android:fillColor="#00000000" android:strokeColor="#FFFFFF" android:strokeWidth="8" android:strokeLineCap="round" android:strokeLineJoin="round"
        android:pathData="M25,24 L25,84 M25,54 L49,24 M25,54 L49,84" />
    <path android:fillColor="#00000000" android:strokeColor="#7FF451" android:strokeWidth="8" android:strokeLineCap="round" android:strokeLineJoin="round"
        android:pathData="M58,24 L58,84 M58,54 L83,24 M58,54 L83,84" />
</vector>
XML

cat > app/src/main/java/com/kkdaily/app/MainActivity.java <<'JAVA'
package com.kkdaily.app;

import android.Manifest;
import android.app.Activity;
import android.app.DownloadManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.location.Criteria;
import android.location.Location;
import android.location.LocationListener;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.webkit.CookieManager;
import android.webkit.DownloadListener;
import android.webkit.GeolocationPermissions;
import android.webkit.JavascriptInterface;
import android.webkit.URLUtil;
import android.webkit.ValueCallback;
import android.webkit.WebChromeClient;
import android.webkit.WebResourceRequest;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import java.util.Locale;

public class MainActivity extends Activity {
    private static final String HOME_URL = "https://kkdaily.store/";
    private static final int LOCATION_REQUEST = 4101;
    private static final int FILE_CHOOSER_REQUEST = 4102;

    private WebView webView;
    private ProgressBar progressBar;
    private ValueCallback<Uri[]> fileCallback;
    private GeolocationPermissions.Callback pendingGeoCallback;
    private String pendingGeoOrigin;
    private boolean fetchLocationAfterPermission = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setStatusBarColor(Color.rgb(30, 13, 59));
        getWindow().setNavigationBarColor(Color.rgb(30, 13, 59));

        CookieManager cookieManager = CookieManager.getInstance();
        cookieManager.setAcceptCookie(true);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setBackgroundColor(Color.WHITE);

        LinearLayout header = new LinearLayout(this);
        header.setOrientation(LinearLayout.HORIZONTAL);
        header.setGravity(Gravity.CENTER_VERTICAL);
        header.setPadding(dp(16), 0, dp(12), 0);
        header.setBackgroundColor(Color.rgb(30, 13, 59));
        root.addView(header, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(58)));

        LinearLayout brand = new LinearLayout(this);
        brand.setOrientation(LinearLayout.HORIZONTAL);
        brand.setGravity(Gravity.CENTER_VERTICAL);
        TextView kk = new TextView(this);
        kk.setText("KK");
        kk.setTextColor(Color.rgb(127, 244, 81));
        kk.setTextSize(23);
        kk.setTypeface(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD);
        TextView daily = new TextView(this);
        daily.setText(" DAILY");
        daily.setTextColor(Color.WHITE);
        daily.setTextSize(17);
        daily.setTypeface(android.graphics.Typeface.DEFAULT, android.graphics.Typeface.BOLD);
        brand.addView(kk);
        brand.addView(daily);
        header.addView(brand, new LinearLayout.LayoutParams(0, dp(48), 1f));

        Button locationButton = new Button(this);
        locationButton.setText("USE LOCATION");
        locationButton.setTextSize(11);
        locationButton.setAllCaps(false);
        locationButton.setTextColor(Color.rgb(30, 13, 59));
        locationButton.setBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.rgb(127, 244, 81)));
        locationButton.setPadding(dp(10), 0, dp(10), 0);
        header.addView(locationButton, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT, dp(40)));
        locationButton.setOnClickListener(v -> requestAppLocation());

        progressBar = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        progressBar.setMax(100);
        progressBar.setProgressTintList(android.content.res.ColorStateList.valueOf(Color.rgb(127, 244, 81)));
        progressBar.setProgressBackgroundTintList(android.content.res.ColorStateList.valueOf(Color.rgb(245, 245, 245)));
        root.addView(progressBar, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, dp(3)));

        webView = new WebView(this);
        CookieManager.getInstance().setAcceptThirdPartyCookies(webView, true);
        webView.setBackgroundColor(Color.WHITE);
        webView.setOverScrollMode(View.OVER_SCROLL_NEVER);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setDomStorageEnabled(true);
        settings.setDatabaseEnabled(true);
        settings.setGeolocationEnabled(true);
        settings.setLoadsImagesAutomatically(true);
        settings.setJavaScriptCanOpenWindowsAutomatically(true);
        settings.setSupportMultipleWindows(false);
        settings.setAllowFileAccess(true);
        settings.setAllowContentAccess(true);
        settings.setMediaPlaybackRequiresUserGesture(true);
        settings.setMixedContentMode(WebSettings.MIXED_CONTENT_NEVER_ALLOW);
        settings.setUserAgentString(settings.getUserAgentString() + " KKDailyAndroid/1.0");

        webView.setWebViewClient(new WebViewClient() {
            @Override
            public boolean shouldOverrideUrlLoading(WebView view, WebResourceRequest request) {
                return routeUrl(request.getUrl().toString());
            }

            @Override
            public boolean shouldOverrideUrlLoading(WebView view, String url) {
                return routeUrl(url);
            }

            @Override
            public void onReceivedError(WebView view, WebResourceRequest request,
                                        android.webkit.WebResourceError error) {
                super.onReceivedError(view, request, error);
                if (request.isForMainFrame()) {
                    Toast.makeText(MainActivity.this,
                            "Internet check karein aur dobara try karein.", Toast.LENGTH_LONG).show();
                }
            }
        });

        webView.setWebChromeClient(new WebChromeClient() {
            @Override
            public void onProgressChanged(WebView view, int newProgress) {
                progressBar.setProgress(newProgress);
                progressBar.setVisibility(newProgress >= 100 ? View.GONE : View.VISIBLE);
            }

            @Override
            public void onGeolocationPermissionsShowPrompt(String origin,
                    GeolocationPermissions.Callback callback) {
                if (!isKkDailyOrigin(origin)) {
                    callback.invoke(origin, false, false);
                    return;
                }
                if (hasLocationPermission()) {
                    callback.invoke(origin, true, false);
                } else {
                    pendingGeoOrigin = origin;
                    pendingGeoCallback = callback;
                    requestLocationPermissions();
                }
            }

            @Override
            public boolean onShowFileChooser(WebView view, ValueCallback<Uri[]> callback,
                    FileChooserParams params) {
                if (fileCallback != null) fileCallback.onReceiveValue(null);
                fileCallback = callback;
                Intent intent;
                try {
                    intent = params.createIntent();
                    intent.addCategory(Intent.CATEGORY_OPENABLE);
                    startActivityForResult(intent, FILE_CHOOSER_REQUEST);
                    return true;
                } catch (Exception e) {
                    fileCallback = null;
                    Toast.makeText(MainActivity.this, "File picker open nahi ho saka.", Toast.LENGTH_SHORT).show();
                    return false;
                }
            }
        });

        webView.setDownloadListener(new DownloadListener() {
            @Override
            public void onDownloadStart(String url, String userAgent, String contentDisposition,
                                        String mimeType, long contentLength) {
                try {
                    DownloadManager.Request request = new DownloadManager.Request(Uri.parse(url));
                    request.addRequestHeader("Cookie", CookieManager.getInstance().getCookie(url));
                    request.addRequestHeader("User-Agent", userAgent);
                    request.setMimeType(mimeType);
                    request.setTitle(URLUtil.guessFileName(url, contentDisposition, mimeType));
                    request.setDescription("KK Daily download");
                    request.setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED);
                    request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS,
                            URLUtil.guessFileName(url, contentDisposition, mimeType));
                    DownloadManager manager = (DownloadManager) getSystemService(DOWNLOAD_SERVICE);
                    manager.enqueue(request);
                    Toast.makeText(MainActivity.this, "Download shuru ho gaya.", Toast.LENGTH_SHORT).show();
                } catch (Exception e) {
                    Toast.makeText(MainActivity.this, "Download start nahi ho saka.", Toast.LENGTH_SHORT).show();
                }
            }
        });

        root.addView(webView, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT, 0, 1f));
        setContentView(root);
        webView.loadUrl(HOME_URL);
    }

    private boolean routeUrl(String rawUrl) {
        try {
            Uri uri = Uri.parse(rawUrl);
            String scheme = uri.getScheme() == null ? "" : uri.getScheme().toLowerCase(Locale.ROOT);
            if (("http".equals(scheme) || "https".equals(scheme)) && isKkDailyHost(uri.getHost())) {
                return false;
            }
            if ("about".equals(scheme) || "javascript".equals(scheme) || "blob".equals(scheme)) {
                return false;
            }
            Intent intent;
            if ("intent".equals(scheme)) {
                intent = Intent.parseUri(rawUrl, Intent.URI_INTENT_SCHEME);
                if (intent.resolveActivity(getPackageManager()) != null) startActivity(intent);
            } else {
                intent = new Intent(Intent.ACTION_VIEW, uri);
                if (intent.resolveActivity(getPackageManager()) != null) startActivity(intent);
            }
        } catch (Exception e) {
            Toast.makeText(this, "Link open nahi ho saka.", Toast.LENGTH_SHORT).show();
        }
        return true;
    }

    private boolean isKkDailyOrigin(String origin) {
        try { return isKkDailyHost(Uri.parse(origin).getHost()); }
        catch (Exception e) { return false; }
    }

    private boolean isKkDailyHost(String host) {
        if (host == null) return false;
        return host.equalsIgnoreCase("kkdaily.store") || host.equalsIgnoreCase("www.kkdaily.store")
                || host.toLowerCase(Locale.ROOT).endsWith(".kkdaily.store");
    }

    private int dp(float value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    private boolean hasLocationPermission() {
        return checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                || checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
    }

    private void requestAppLocation() {
        fetchLocationAfterPermission = true;
        if (hasLocationPermission()) {
            fetchAndSendLocation();
        } else {
            requestLocationPermissions();
        }
    }

    private void requestLocationPermissions() {
        requestPermissions(new String[]{
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
        }, LOCATION_REQUEST);
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == LOCATION_REQUEST) {
            boolean granted = hasLocationPermission();
            if (pendingGeoCallback != null && pendingGeoOrigin != null) {
                pendingGeoCallback.invoke(pendingGeoOrigin, granted, false);
                pendingGeoCallback = null;
                pendingGeoOrigin = null;
            }
            if (fetchLocationAfterPermission) {
                fetchLocationAfterPermission = false;
                if (granted) fetchAndSendLocation();
                else Toast.makeText(this, "Order location ke liye permission allow karein.", Toast.LENGTH_LONG).show();
            }
        }
    }

    private void fetchAndSendLocation() {
        try {
            LocationManager manager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
            Criteria criteria = new Criteria();
            criteria.setAccuracy(Criteria.ACCURACY_FINE);
            String provider = manager.getBestProvider(criteria, true);
            if (provider == null) {
                if (manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)) provider = LocationManager.NETWORK_PROVIDER;
                else if (manager.isProviderEnabled(LocationManager.GPS_PROVIDER)) provider = LocationManager.GPS_PROVIDER;
            }
            if (provider == null) {
                Toast.makeText(this, "Phone ki Location/GPS setting on karein.", Toast.LENGTH_LONG).show();
                return;
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                manager.getCurrentLocation(provider, null, getMainExecutor(), location -> {
                    if (location != null) sendLocationToWebsite(location);
                    else Toast.makeText(this, "Location nahi mil saki. GPS on karke dobara try karein.", Toast.LENGTH_LONG).show();
                });
            } else {
                manager.requestSingleUpdate(provider, new LocationListener() {
                    @Override public void onLocationChanged(Location location) { sendLocationToWebsite(location); }
                    @Override public void onStatusChanged(String p, int status, Bundle extras) { }
                    @Override public void onProviderEnabled(String p) { }
                    @Override public void onProviderDisabled(String p) { }
                }, Looper.getMainLooper());
                Toast.makeText(this, "Location hasil ki ja rahi hai...", Toast.LENGTH_SHORT).show();
            }
        } catch (SecurityException e) {
            Toast.makeText(this, "Location permission allow nahi hui.", Toast.LENGTH_LONG).show();
        } catch (Exception e) {
            Toast.makeText(this, "Location service available nahi.", Toast.LENGTH_LONG).show();
        }
    }

    private void sendLocationToWebsite(Location location) {
        double lat = location.getLatitude();
        double lon = location.getLongitude();
        float accuracy = location.getAccuracy();
        String js = "(function(){var p={latitude:" + lat + ",longitude:" + lon
                + ",accuracy:" + accuracy + ",source:'android'};"
                + "window.KKDailyAppLocation=p;"
                + "window.dispatchEvent(new CustomEvent('kkdailyapp-location',{detail:p}));"
                + "})();";
        if (webView != null) webView.evaluateJavascript(js, null);
        Toast.makeText(this, "Location app ko mil gayi. Checkout mein Use Location option select karein.", Toast.LENGTH_LONG).show();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == FILE_CHOOSER_REQUEST && fileCallback != null) {
            Uri[] results = WebChromeClient.FileChooserParams.parseResult(resultCode, data);
            fileCallback.onReceiveValue(results);
            fileCallback = null;
        }
    }

    @Override
    @SuppressWarnings("deprecation")
    public void onBackPressed() {
        if (webView != null && webView.canGoBack()) webView.goBack();
        else super.onBackPressed();
    }

    @Override
    protected void onDestroy() {
        if (fileCallback != null) fileCallback.onReceiveValue(null);
        if (webView != null) {
            webView.stopLoading();
            webView.destroy();
        }
        super.onDestroy();
    }
}
JAVA
gradle --no-daemon assembleDebug
