# KK Daily Android App — APK build (laptop ki zaroorat nahi)

Yeh package aapki live website `https://kkdaily.store` ko Android app mein kholta hai. Products, cart, login aur orders website se hi chalte rahenge.

## App mein kya hai
- KK Daily purple/green branding aur app icon
- Android location permission (Fine/Coarse)
- Website jab HTML geolocation maangegi to Android permission prompt aaye ga
- Header ka **USE LOCATION** button current GPS coordinates website ko `kkdailyapp-location` event ke zariye bhejta hai
- Payment screenshot/image upload ke liye file picker
- Receipt/PDF downloads; external payment/social links phone par open honge
- Back button website ke previous page par jata hai

## Location aur checkout ka zaroori note
App user se location permission maang sakti hai aur current coordinates website tak bhej sakti hai. Checkout address field ko automatically bharne ke liye website checkout code ko yeh event handle karna hoga, ya website ko `navigator.geolocation` call karna hoga. Website ka checkout source is package mein nahi, is liye koi field naam assume nahi kiya gaya.

Website ke checkout JavaScript mein event handle karne ka example:

```javascript
window.addEventListener('kkdailyapp-location', function (event) {
  const { latitude, longitude, accuracy } = event.detail;
  // Apne checkout form mein map pin / coordinates set karein.
});
```

## APK phone se banane ka tareeqa (GitHub cloud build)
Is chat ke build environment mein Android SDK aur internet download access available nahi, is liye yahan APK binary compile nahi ho saki. Project ke saath GitHub Actions cloud builder diya gaya hai; laptop/Android Studio ki zaroorat nahi.

1. ZIP ko phone par download karke extract karein. Aisa file manager use karein jo hidden `.github` folder bhi dikhaye (misal: ZArchiver mein show hidden files on karein).
2. `github.com` par sign in karein aur **New repository** banayein. Naam `kkdaily-android` rakh sakte hain; repository empty rakhein.
3. Repository mein **Add file → Upload files** kholein aur sirf `build.sh` aur `README_Roman_Urdu.md` ko root par upload karke commit karein.
4. Ab **Add file → Create new file** select karein. File name mein bilkul `.github/workflows/build.yml` likhein. ZIP ke extracted folder mein `.github/workflows/build.yml` ko text editor se khol kar uska poora content copy karein, GitHub editor mein paste karein, phir **Commit changes** karein. GitHub par yeh exact folder path create ho jayega.
5. Repository ke **Actions** tab mein `Build KK Daily APK` ka run kholein. Successful hone par **Artifacts** mein `KK-Daily-APK` download karein.
6. Artifact ZIP extract karein; andar `app-debug.apk` hoga. Us par tap karke install karein. Android pooche to browser/file manager ke liye **Install unknown apps** allow karein.

## Notes
- Yeh debug-signed APK hai, phone par direct installation/testing ke liye. Play Store par publish karne ke liye release signing key, store assets, privacy disclosures aur us waqt ki target-SDK requirements poori karni hongi.
- App ko internet chahiye; website offline nahi chalegi.
- Location sirf user ke allow karne par li jaati hai; app background mein location track nahi karti.
