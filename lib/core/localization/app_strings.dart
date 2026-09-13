class AppStrings {
  final String code;
  const AppStrings(this.code);

  static const en = AppStrings('en');
  static const bn = AppStrings('bn');
  static const hi = AppStrings('hi');

  static AppStrings of(String languageCode) {
    switch (languageCode) {
      case 'bn':
        return bn;
      case 'hi':
        return hi;
      default:
        return en;
    }
  }

  // Navigation
  String get tabToday => code == 'bn' ? 'আজকের শিডিউল' : (code == 'hi' ? 'दैनिक अनुसूची' : 'Today');
  String get tabCabinet => code == 'bn' ? 'ক্যাবিনেট' : (code == 'hi' ? 'दवाइयां' : 'Cabinet');
  String get tabHistory => code == 'bn' ? 'ইতিহাস' : (code == 'hi' ? 'इतिहास' : 'History');
  String get tabSettings => code == 'bn' ? 'সেটিংস' : (code == 'hi' ? 'सेटिंग्स' : 'Settings');

  // Daily Schedule
  String get dailySchedule => code == 'bn' ? 'দৈনিক সময়সূচী' : (code == 'hi' ? 'दैनिक समय सारणी' : 'Daily Schedule');
  String get allDoneToday => code == 'bn' ? 'আজকের সব ওষুধ নেওয়া সম্পন্ন!' : (code == 'hi' ? 'आज की सभी दवाएं पूरी हुईं!' : 'All Done for Today!');
  String get allDoneSub => code == 'bn' ? 'আপনার স্বাস্থ্যের যত্ন নেওয়ার জন্য চমৎকার কাজ!' : (code == 'hi' ? 'अपने स्वास्थ्य का ध्यान रखने के लिए बहुत बढ़िया!' : 'Great job staying on track with your health.');
  String get pendingDoses => code == 'bn' ? 'ডোজ বাকি আছে' : (code == 'hi' ? 'दवा बाकी है' : 'Doses Remaining');
  String get morning => code == 'bn' ? 'সকাল' : (code == 'hi' ? 'सुबह' : 'Morning');
  String get afternoon => code == 'bn' ? 'দুপুর' : (code == 'hi' ? 'दोपहर' : 'Afternoon');
  String get evening => code == 'bn' ? 'সন্ধ্যা' : (code == 'hi' ? 'शाम' : 'Evening');
  String get night => code == 'bn' ? 'রাত' : (code == 'hi' ? 'रात' : 'Night');

  // Family Filter
  String get allFamily => code == 'bn' ? 'পুরো পরিবার' : (code == 'hi' ? 'पूरा परिवार' : 'All Family');
  String get myself => code == 'bn' ? 'আমার জন্য' : (code == 'hi' ? 'मेरे लिए' : 'Myself');
  String get addMember => code == 'bn' ? 'সদস্য যোগ করুন' : (code == 'hi' ? 'सदस्य जोड़ें' : 'Add Member');

  // Dose Card Actions
  String get takeDose => code == 'bn' ? 'ঔষধ নিন' : (code == 'hi' ? 'दवा लें' : 'Take Dose');
  String get taken => code == 'bn' ? 'নেওয়া হয়েছে' : (code == 'hi' ? 'ली गई' : 'Taken');
  String get snooze10m => code == 'bn' ? '১০ মিনিট পরে' : (code == 'hi' ? '१० मिनट बाद' : 'Snooze 10m');
  String get skip => code == 'bn' ? 'বাদ দিন' : (code == 'hi' ? 'छोड़ें' : 'Skip');

  // Food Timing
  String get beforeMeal => code == 'bn' ? 'খাওয়ার আগে' : (code == 'hi' ? 'खाने से पहले' : 'Before Meal');
  String get afterMeal => code == 'bn' ? 'খাওয়ার পরে' : (code == 'hi' ? 'खाने के बाद' : 'After Meal');
  String get withMeal => code == 'bn' ? 'খাবারের সাথে' : (code == 'hi' ? 'भोजन के साथ' : 'With Meal');
  String get emptyStomach => code == 'bn' ? 'খালি পেটে' : (code == 'hi' ? 'खाली पेट' : 'Empty Stomach');
  String get bedtime => code == 'bn' ? 'ঘুমানোর আগে' : (code == 'hi' ? 'सोने से पहले' : 'Bedtime');
  String get anytime => code == 'bn' ? 'যেকোনো সময়' : (code == 'hi' ? 'कभी भी' : 'Anytime');

  // Medicine Forms
  String get tablet => code == 'bn' ? 'ট্যাবলেট' : (code == 'hi' ? 'टैबलेट' : 'Tablet');
  String get capsule => code == 'bn' ? 'ক্যাপসুল' : (code == 'hi' ? 'कैप्सूल' : 'Capsule');
  String get syrup => code == 'bn' ? 'সিরাপ' : (code == 'hi' ? 'सिरप' : 'Syrup');
  String get drops => code == 'bn' ? 'ড্রপস' : (code == 'hi' ? 'ड्रॉप्स' : 'Drops');
  String get inhaler => code == 'bn' ? 'ইনহেলার' : (code == 'hi' ? 'इन्हेलर' : 'Inhaler');
  String get injection => code == 'bn' ? 'ইনজেকশন' : (code == 'hi' ? 'इंजेक्शन' : 'Injection');
  String get ointment => code == 'bn' ? 'মলম/ক্রিম' : (code == 'hi' ? 'मरहम/क्रीम' : 'Ointment');
  String get supplement => code == 'bn' ? 'ভিটামিন/সাপ্লিমেন্ট' : (code == 'hi' ? 'विटामिन/सप्लीमेंट' : 'Supplement');
  String get other => code == 'bn' ? 'অন্যান্য' : (code == 'hi' ? 'अन्य' : 'Other');

  // Cabinet & Stock
  String get medicineCabinet => code == 'bn' ? 'মেডিসিন ক্যাবিনেট' : (code == 'hi' ? 'दवाई की पेटी' : 'Medicine Cabinet');
  String get searchMedicines => code == 'bn' ? 'ওষুধ খুঁজুন...' : (code == 'hi' ? 'दवा खोजें...' : 'Search medicines...');
  String get all => code == 'bn' ? 'সব' : (code == 'hi' ? 'सभी' : 'All');
  String get lowStock => code == 'bn' ? 'কম স্টক' : (code == 'hi' ? 'कम स्टॉक' : 'Low Stock');
  String get left => code == 'bn' ? 'টি বাকি' : (code == 'hi' ? 'बची हैं' : 'left');
  String get runsOutIn => code == 'bn' ? 'শেষ হবে' : (code == 'hi' ? 'समाप्त होगा' : 'Runs out in');
  String get days => code == 'bn' ? 'দিনে' : (code == 'hi' ? 'दिनों में' : 'days');
  String get refillStock => code == 'bn' ? 'স্টক রিফিল' : (code == 'hi' ? 'स्टॉक भरें' : 'Refill Stock');

  // Add / Edit Medicine
  String get addNewMedicine => code == 'bn' ? 'নতুন ওষুধ যোগ করুন' : (code == 'hi' ? 'नई दवा जोड़ें' : 'Add New Medicine');
  String get editMedicine => code == 'bn' ? 'ওষুধ সম্পাদনা করুন' : (code == 'hi' ? 'दवा संपादित करें' : 'Edit Medicine');
  String get medicineName => code == 'bn' ? 'ওষুধের নাম *' : (code == 'hi' ? 'दवा का नाम *' : 'Medicine Name *');
  String get dosageStrength => code == 'bn' ? 'ডোজ / মাত্রা (যেমন ৫০০ মিলিগ্রাম) *' : (code == 'hi' ? 'खुराक / मात्रा (जैसे ५०० मि.ग्रा.) *' : 'Dosage / Strength *');
  String get formAndIcon => code == 'bn' ? 'ওষুধের ধরন ও আইকন' : (code == 'hi' ? 'दवा का प्रकार और आइकन' : 'Medicine Form & Icon');
  String get pillColorTag => code == 'bn' ? 'রঙিন ট্যাগ' : (code == 'hi' ? 'रंग का टैग' : 'Pill Color Tag');
  String get foodTimingInstruction => code == 'bn' ? 'খাওয়ার নিয়ম (ফুড টাইমিং)' : (code == 'hi' ? 'दवा लेने का नियम (भोजन समय)' : 'Intake Instruction (Food Timing)');
  String get reminderSchedules => code == 'bn' ? 'অ্যালার্ম সময়সূচী' : (code == 'hi' ? 'अलार्म का समय' : 'Reminder Schedules');
  String get addTime => code == 'bn' ? 'সময় যোগ করুন' : (code == 'hi' ? 'समय जोड़ें' : 'Add Time');
  String get loudAlarm => code == 'bn' ? 'পূর্ণ স্ক্রিন অ্যালার্ম ও রিংটোন' : (code == 'hi' ? 'फुल स्क्रीन अलार्म व रिंगटोन' : 'Loud Alarm (Screen + Sound)');
  String get save => code == 'bn' ? 'সংরক্ষণ করুন' : (code == 'hi' ? 'सुरक्षित करें' : 'Save');
  String get cancel => code == 'bn' ? 'বাতিল' : (code == 'hi' ? 'रद्द करें' : 'Cancel');

  // Settings & Language
  String get settingsAndDiagnostics => code == 'bn' ? 'সেটিংস ও ডায়াগনস্টিকস' : (code == 'hi' ? 'सेटिंग्स और निदान' : 'Settings & Diagnostics');
  String get languageOption => code == 'bn' ? 'ভাষা নির্বাচন (Language)' : (code == 'hi' ? 'भाषा चुनें (Language)' : 'App Language');
  String get selectLanguage => code == 'bn' ? 'আপনার পছন্দের ভাষা বেছে নিন' : (code == 'hi' ? 'अपनी पसंदीदा भाषा चुनें' : 'Choose Your Preferred Language');
  String get langEnglish => 'English';
  String get langBengali => 'বাংলা (Bengali)';
  String get langHindi => 'हिन्दी (Hindi)';
  String get alarmSoundTest => code == 'bn' ? 'অ্যালার্ম সাউন্ড ও ব্যানার টেস্ট' : (code == 'hi' ? 'अलार्म और बैनर टेस्ट' : 'Alarm Sound & Banner Test');

  // Welcome Screen
  String get welcomeTitle => code == 'bn' ? 'আপনার স্বাস্থ্যের পূর্ণ নিয়ন্ত্রণ নিন' : (code == 'hi' ? 'अपने स्वास्थ्य का पूरा नियंत्रण लें' : 'Take Control of Your Health');
  String get welcomeSub => code == 'bn' ? 'সময়মতো ওষুধ গ্রহণ করুন এবং পরিবারের সুস্থতা বজায় রাখুন' : (code == 'hi' ? 'समय पर दवा लें और परिवार की सेहत सुरक्षित रखें' : 'Never miss a dose for you and your loved ones');
  String get exactAlarmsFeature => code == 'bn' ? 'সঠিক সময়ে অ্যালার্ম' : (code == 'hi' ? 'सटीक समय पर अलार्म' : 'Exact Alarms');
  String get familyProfilesFeature => code == 'bn' ? 'পরিবারের প্রতিটি সদস্যের প্রোফাইল' : (code == 'hi' ? 'परिवार के सदस्यों की प्रोफाइल' : 'Family Profiles');
  String get cloudSyncFeature => code == 'bn' ? 'ক্লাউড ব্যাকআপ ও অফলাইন নিরাপত্তা' : (code == 'hi' ? 'क्लाउड बैकअप और ऑफलाइन सुरक्षा' : 'Cloud Sync & Offline Safe');
  String get getStarted => code == 'bn' ? 'শুরু করুন' : (code == 'hi' ? 'शुरू करें' : 'Get Started');
}
