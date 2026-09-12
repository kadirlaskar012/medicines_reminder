import os

DRAWABLE_DIR = r"android/app/src/main/res/drawable"

VECTORS = {
    "ic_notif_tablet.xml": """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M12,2A10,10 0 1,0 22,12A10,10 0 0,0 12,2zm0,2a8,8 0 0,1 7.93,7H4.07A8,8 0 0,1 12,4zm0,16a8,8 0 0,1 -7.93,-7h15.86A8,8 0 0,1 12,20z"/>
</vector>""",

    "ic_notif_capsule.xml": """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M6,3h12c1.66,0 3,1.34 3,3v12c0,1.66 -1.34,3 -3,3H6c-1.66,0 -3,-1.34 -3,-3V6c0,-1.66 1.34,-3 3,-3zm7,11h3.5v-2H13V8.5h-2V12H7.5v2H11v3.5h2V14z"/>
</vector>""",

    "ic_notif_syrup.xml": """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M9,2h6v2H9V2zm8,5H7C5.9,7 5,7.9 5,9v11c0,1.1 0.9,2 2,2h10c1.1,0 2,-0.9 2,-2V9C19,7.9 18.1,7 17,7zm-4,8h2v2h-2v-2zm-3,-2h2v2h-2v-2zm6,0h2v2h-2v-2z"/>
</vector>""",

    "ic_notif_injection.xml": """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M19.5,4.5l-1.4,-1.4c-0.4,-0.4 -1,-0.4 -1.4,0l-1.8,1.8l-1.4,-1.4l-1.4,1.4l1.4,1.4l-5.7,5.7c-0.8,-0.3 -1.8,-0.2 -2.5,0.5l-0.7,0.7l4.2,4.2l-5.3,5.3l1.4,1.4l5.3,-5.3l4.2,4.2l0.7,-0.7c0.7,-0.7 0.8,-1.7 0.5,-2.5l5.7,-5.7l1.4,1.4l1.4,-1.4l-1.4,-1.4l1.8,-1.8c0.4,-0.4 0.4,-1 0,-1.4z"/>
</vector>""",

    "ic_notif_drops.xml": """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M12,2.69l5.66,5.66a8,8 0 1,1 -11.31,0z"/>
</vector>""",

    "ic_notif_inhaler.xml": """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M17,4h-4V2h-2v2H7C5.9,4 5,4.9 5,6v12c0,1.1 0.9,2 2,2h4v2h2v-2h4c1.1,0 2,-0.9 2,-2V6C19,4.9 18.1,4 17,4zm-1,12H8V7h8v9z"/>
</vector>""",

    "ic_notif_ointment.xml": """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M19,3H5C3.9,3 3,3.9 3,5v14c0,1.1 0.9,2 2,2h14c1.1,0 2,-0.9 2,-2V5C21,3.9 20.1,3 19,3zm-2,10h-4v4h-2v-4H7v-2h4V7h2v4h4v2z"/>
</vector>""",

    "ic_notif_supplement.xml": """<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="24dp"
    android:height="24dp"
    android:viewportWidth="24"
    android:viewportHeight="24">
    <path
        android:fillColor="#FFFFFFFF"
        android:pathData="M17,8C8,10 5.9,16.17 3.82,21.34L5.71,22l1,-2.3A4.49,4.49 0 0,0 8,20C19,20 22,3 22,3c0,0 -1,1 -5,5zm-4.7,5.55A16.48,16.48 0 0,1 6,17.48C7.59,14.07 10.36,11.2 14.09,9.45c-0.57,1.38 -1.18,2.77 -1.79,4.1z"/>
</vector>""",
}

for name, content in VECTORS.items():
    path = os.path.join(DRAWABLE_DIR, name)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Written: {path}")
