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

  // App Brand
  String get appName => 'MediRemind';
  String get appTagline => code == 'bn' ? 'স্মার্ট মেডিসিন রিমাইন্ডার সঙ্গী' : (code == 'hi' ? 'स्मार्ट दवाई रिमाइंडर साथी' : 'Smart Medicine Companion');

  // Navigation Tabs
  String get tabToday => code == 'bn' ? 'আজকের শিডিউল' : (code == 'hi' ? 'दैनिक अनुसूची' : 'Today');
  String get tabCabinet => code == 'bn' ? 'ক্যাবিনেট' : (code == 'hi' ? 'दवाइयां' : 'Cabinet');
  String get tabHistory => code == 'bn' ? 'ইতিহাস' : (code == 'hi' ? 'इतिहास' : 'History');
  String get tabSettings => code == 'bn' ? 'সেটিংস' : (code == 'hi' ? 'सेटिंग्स' : 'Settings');

  // Today / Daily Schedule
  String get dailySchedule => code == 'bn' ? 'আজকের শিডিউল' : (code == 'hi' ? 'दैनिक अनुसूची' : 'Daily Schedule');
  String get allDoneToday => code == 'bn' ? 'আজকের সব ওষুধ নেওয়া সম্পন্ন!' : (code == 'hi' ? 'आज की सभी दवाएं पूरी हुईं!' : 'All Done for Today!');
  String get allDoneSub => code == 'bn' ? 'আপনার স্বাস্থ্যের যত্ন নেওয়ার জন্য চমৎকার কাজ।' : (code == 'hi' ? 'अपने स्वास्थ्य का ध्यान रखने के लिए बहुत बढ़िया।' : 'Great job staying on track with your health.');
  String get dosesRemaining => code == 'bn' ? 'ওষুধ বাকি আছে' : (code == 'hi' ? 'दवाइयां बाकी हैं' : 'doses remaining');
  String get morning => code == 'bn' ? 'সকাল' : (code == 'hi' ? 'सुबह' : 'Morning');
  String get afternoon => code == 'bn' ? 'দুপুর' : (code == 'hi' ? 'दोपहर' : 'Afternoon');
  String get evening => code == 'bn' ? 'সন্ধ্যা' : (code == 'hi' ? 'शाम' : 'Evening');
  String get night => code == 'bn' ? 'রাত' : (code == 'hi' ? 'রাত' : 'Night');
  String get noDosesScheduled => code == 'bn' ? 'এই দিনের জন্য কোনো ওষুধ নেই' : (code == 'hi' ? 'इस दिन के लिए कोई दवा नहीं है' : 'No medicines scheduled for this day');
  String get tapToAddFirst => code == 'bn' ? 'নতুন ওষুধ যুক্ত করতে নিচের + বোতাম চাপুন' : (code == 'hi' ? 'नई दवा जोड़ने के लिए नीचे + बटन दबाएं' : 'Tap + below to add your medicines');
  String get adherenceScore => code == 'bn' ? 'আজকের গ্রহণের হার' : (code == 'hi' ? 'आज की सफलता दर' : 'Today\'s Adherence');

  // Days of week short
  String weekdayShort(int weekday) {
    if (code == 'bn') {
      const days = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
      return days[(weekday - 1) % 7];
    } else if (code == 'hi') {
      const days = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];
      return days[(weekday - 1) % 7];
    }
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return days[(weekday - 1) % 7];
  }

  // Weekday single initial for charts
  String weekdayInitial(int index) {
    if (code == 'bn') {
      const days = ['সো', 'ম', 'বু', 'বৃ', 'শু', 'শ', 'র'];
      return days[index % 7];
    } else if (code == 'hi') {
      const days = ['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र'];
      return days[index % 7];
    }
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[index % 7];
  }

  // Weekday Full
  String weekdayFull(int weekday) {
    if (code == 'bn') {
      const days = ['সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'];
      return days[(weekday - 1) % 7];
    } else if (code == 'hi') {
      const days = ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'];
      return days[(weekday - 1) % 7];
    }
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[(weekday - 1) % 7];
  }

  // Month Name
  String monthName(int month) {
    if (code == 'bn') {
      const months = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
      return months[(month - 1) % 12];
    } else if (code == 'hi') {
      const months = ['जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'];
      return months[(month - 1) % 12];
    }
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(month - 1) % 12];
  }

  // Localized Date Formatter for Screen Header
  String formatHeaderDate(DateTime date) {
    if (code == 'bn' || code == 'hi') {
      return '${weekdayFull(date.weekday)}, ${date.day} ${monthName(date.month)}';
    }
    return '${weekdayFull(date.weekday)}, ${monthName(date.month)} ${date.day}';
  }

  // Family Filter & Profiles
  String get allFamily => code == 'bn' ? 'পুরো পরিবার' : (code == 'hi' ? 'पूरा परिवार' : 'All Family');
  String get myself => code == 'bn' ? 'আমার জন্য' : (code == 'hi' ? 'मेरे लिए' : 'Myself');
  String get addMember => code == 'bn' ? 'সদস্য যোগ করুন' : (code == 'hi' ? 'सदस्य जोड़ें' : 'Add Member');
  String get selectProfile => code == 'bn' ? 'পরিবারের সদস্য নির্বাচন' : (code == 'hi' ? 'परिवार का सदस्य चुनें' : 'Select Profile');
  String get newMemberName => code == 'bn' ? 'সদস্যের নাম' : (code == 'hi' ? 'सदस्य का नाम' : 'Member Name');
  String get chooseAvatar => code == 'bn' ? 'অবতার বেছে নিন' : (code == 'hi' ? 'अवतार चुनें' : 'Choose Avatar');
  String get familyProfilesTitle => code == 'bn' ? 'পরিবারের প্রোফাইল' : (code == 'hi' ? 'परिवार की प्रोफाइल' : 'Family Profiles');
  String get allFamilyMembersTitle => code == 'bn' ? 'পরিবারের সকল সদস্য' : (code == 'hi' ? 'परिवार के सभी सदस्य' : 'All Family Members');
  String get allCombinedReminders => code == 'bn' ? 'সবার মোট রিমাইন্ডার একসাথে দেখুন' : (code == 'hi' ? 'सभी के संयुक्त रिमाइंडर देखें' : 'View all combined reminders');
  String get addFamilyMemberTitle => code == 'bn' ? 'নতুন সদস্য যুক্ত করুন' : (code == 'hi' ? 'नया सदस्य जोड़ें' : 'Add Family Member');
  String get memberNameHint => code == 'bn' ? 'যেমন: মা, বাবা, রাফি' : (code == 'hi' ? 'जैसे: मां, पिता, राहुल' : 'e.g. Mom, Dad, Emma');
  String get relationLabel => code == 'bn' ? 'সম্পর্ক' : (code == 'hi' ? 'रिश्ता' : 'Relation');
  String get profileColorLabel => code == 'bn' ? 'প্রোফাইল রঙ' : (code == 'hi' ? 'प्रोफाइल का रंग' : 'Profile Color');

  String relationName(String rel) {
    final lower = rel.toLowerCase();
    if (lower == 'myself' || lower == 'self') {
      return code == 'bn' ? 'নিজের জন্য' : (code == 'hi' ? 'खुद के लिए' : 'Myself');
    }
    if (code == 'bn') {
      switch (lower) {
        case 'mother': return 'মা';
        case 'father': return 'বাবা';
        case 'partner': return 'জীবনসঙ্গী';
        case 'child': return 'সন্তান';
        default: return 'অন্যান্য';
      }
    } else if (code == 'hi') {
      switch (lower) {
        case 'mother': return 'माता जी';
        case 'father': return 'पिता जी';
        case 'partner': return 'जीवनसाथी';
        case 'child': return 'बच्चा';
        default: return 'अन्य';
      }
    }
    return rel;
  }

  String notificationDispatched(String name) {
    if (code == 'bn') return '$name নোটিফিকেশন পাঠানো হয়েছে!';
    if (code == 'hi') return '$name नोटिफिकेशन भेजा गया!';
    return '$name notification dispatched!';
  }

  // Dose Card Actions & Status
  String get takeDose => code == 'bn' ? 'ওষুধ নিন' : (code == 'hi' ? 'दवा लें' : 'Take Dose');
  String get taken => code == 'bn' ? 'নেওয়া হয়েছে' : (code == 'hi' ? 'ली गई' : 'Taken');
  String get takenAt => code == 'bn' ? 'নেওয়া হয়েছে' : (code == 'hi' ? 'ली गई' : 'Taken at');
  String get skipped => code == 'bn' ? 'বাদ দেওয়া হয়েছে' : (code == 'hi' ? 'छोड़ दी गई' : 'Skipped');
  String get due => code == 'bn' ? 'সময় হয়েছে' : (code == 'hi' ? 'समय हो गया' : 'Due');
  String get snooze10m => code == 'bn' ? '১০ মিনিট পর' : (code == 'hi' ? '१० मिनट बाद' : 'Snooze 10m');
  String get skip => code == 'bn' ? 'বাদ দিন' : (code == 'hi' ? 'छोड़ें' : 'Skip');
  String get skipDose => code == 'bn' ? 'ডোজ বাদ দিন' : (code == 'hi' ? 'खुराक छोड़ें' : 'Skip Dose');
  String get iTookMyMedicine => code == 'bn' ? 'আমি ওষুধ নিয়েছি' : (code == 'hi' ? 'मैंने दवा ले ली' : 'I TOOK MY MEDICINE');
  String get alertCaregiverWhatsApp => code == 'bn' ? 'কেয়ারগিভারকে জানান (WhatsApp)' : (code == 'hi' ? 'केयरगिवर को सूचित करें (WhatsApp)' : 'Alert Caregiver (WhatsApp)');
  String snoozedMessage(String medicineName, int minutes) {
    if (code == 'bn') return '$medicineName এর অ্যালার্ম $minutes মিনিটের জন্য স্থগিত করা হয়েছে।';
    if (code == 'hi') return '$medicineName का अलार्म $minutes मिनट के लिए स्थगित कर दिया गया।';
    return 'Snoozed $medicineName for $minutes minutes.';
  }
  String get everyday => code == 'bn' ? 'প্রতিদিন' : (code == 'hi' ? 'हर दिन' : 'Everyday');
  String get weekdays => code == 'bn' ? 'কাজের দিন' : (code == 'hi' ? 'कार्यदिवस' : 'Weekdays');

  // Food Timing
  String get beforeMeal => code == 'bn' ? 'খাওয়ার আগে' : (code == 'hi' ? 'खाने से पहले' : 'Before Meal');
  String get afterMeal => code == 'bn' ? 'খাওয়ার পরে' : (code == 'hi' ? 'खाने के बाद' : 'After Meal');
  String get withMeal => code == 'bn' ? 'খাবারের সাথে' : (code == 'hi' ? 'भोजन के साथ' : 'With Meal');
  String get emptyStomach => code == 'bn' ? 'খালি পেটে' : (code == 'hi' ? 'खाली पेट' : 'Empty Stomach');
  String get bedtime => code == 'bn' ? 'ঘুমানোর আগে' : (code == 'hi' ? 'सोने से पहले' : 'Bedtime');
  String get anytime => code == 'bn' ? 'যেকোনো সময়' : (code == 'hi' ? 'कभी भी' : 'Anytime');

  String foodInstructionName(String instructionKey) {
    switch (instructionKey.toLowerCase()) {
      case 'beforemeal': return beforeMeal;
      case 'aftermeal': return afterMeal;
      case 'withmeal': return withMeal;
      case 'emptystomach': return emptyStomach;
      case 'bedtime': return bedtime;
      case 'anytime': return anytime;
      default: return anytime;
    }
  }

  // Medicine Forms
  String get tablet => code == 'bn' ? 'ট্যাবলেট' : (code == 'hi' ? 'টैबलेट' : 'Tablet');
  String get capsule => code == 'bn' ? 'ক্যাপসুল' : (code == 'hi' ? 'कैप्सूल' : 'Capsule');
  String get syrup => code == 'bn' ? 'সিরাপ' : (code == 'hi' ? 'सिरप' : 'Syrup');
  String get drops => code == 'bn' ? 'ড্রপস' : (code == 'hi' ? 'ড্রॉप्स' : 'Drops');
  String get inhaler => code == 'bn' ? 'ইনহেলার' : (code == 'hi' ? 'इन्हेलर' : 'Inhaler');
  String get injection => code == 'bn' ? 'ইনজেকশন' : (code == 'hi' ? 'इंजेक्शन' : 'Injection');
  String get ointment => code == 'bn' ? 'মলম/ক্রিম' : (code == 'hi' ? 'मरहम/क्रीम' : 'Ointment');
  String get supplement => code == 'bn' ? 'সাপ্লিমেন্ট' : (code == 'hi' ? 'सप्लीमेंट' : 'Supplement');
  String get other => code == 'bn' ? 'অন্যান্য' : (code == 'hi' ? 'अन्य' : 'Other');

  String medicineTypeName(String typeKey) {
    switch (typeKey.toLowerCase()) {
      case 'tablet': return tablet;
      case 'capsule': return capsule;
      case 'syrup': return syrup;
      case 'drops': return drops;
      case 'inhaler': return inhaler;
      case 'injection': return injection;
      case 'ointment': return ointment;
      case 'supplement': return supplement;
      default: return other;
    }
  }

  // Cabinet & Stock
  String get medicineCabinet => code == 'bn' ? 'মেডিসিন ক্যাবিনেট' : (code == 'hi' ? 'दवाई की पेटी' : 'Medicine Cabinet');
  String get searchMedicines => code == 'bn' ? 'ওষুধ বা প্রোফাইল খুঁজুন...' : (code == 'hi' ? 'दवा या प्रोफाइल खोजें...' : 'Search medicines...');
  String get all => code == 'bn' ? 'সব' : (code == 'hi' ? 'सभी' : 'All');
  String get lowStock => code == 'bn' ? 'কম স্টক' : (code == 'hi' ? 'कम स्टॉक' : 'Low Stock');
  String get activeStatus => code == 'bn' ? 'চলমান' : (code == 'hi' ? 'सक्रिय' : 'Active');
  String get archived => code == 'bn' ? 'আর্কাইভ' : (code == 'hi' ? 'পুরালেখ' : 'Archived');
  String get leftCount => code == 'bn' ? 'টি বাকি' : (code == 'hi' ? 'बची हैं' : 'left');
  String get runsOutIn => code == 'bn' ? 'শেষ হবে' : (code == 'hi' ? 'समाप्त होगा' : 'Runs out in');
  String get days => code == 'bn' ? 'দিনে' : (code == 'hi' ? 'दिनों में' : 'days');
  String get daysUnit => code == 'bn' ? 'দিন' : (code == 'hi' ? 'दिन' : 'Days');
  String get refillStock => code == 'bn' ? 'স্টক রিফিল' : (code == 'hi' ? 'स्टॉक भरें' : 'Refill Stock');
  String get addMedicine => code == 'bn' ? 'ওষুধ যোগ করুন' : (code == 'hi' ? 'दवा जोड़ें' : 'Add Medicine');
  String get noMedicinesFound => code == 'bn' ? 'কোনো ওষুধ পাওয়া যায়নি' : (code == 'hi' ? 'कोई दवा नहीं मिली' : 'No medicines found');
  String get tapToAddMedicinePrompt => code == 'bn' ? 'আপনার প্রেসক্রিপশনের ওষুধ সাজাতে নিচের বোতাম চাপুন' : (code == 'hi' ? 'अपनी दवाएं जोड़ने के लिए नीचे दिए गए बटन को दबाएं' : 'Tap Add Medicine to organize your prescriptions');
  String get deleteMedicine => code == 'bn' ? 'ওষুধ মুছে ফেলুন' : (code == 'hi' ? 'दवा हटाएं' : 'Delete Medicine');
  String get deleteConfirm => code == 'bn' ? 'আপনি কি নিশ্চিত এই ওষুধটি তালিকা থেকে মুছে ফেলতে চান?' : (code == 'hi' ? 'क्या आप वाकई इस दवा को हटाना चाहते हैं?' : 'Are you sure you want to delete this medicine?');

  // Add / Edit Medicine Screen
  String get addNewMedicine => code == 'bn' ? 'নতুন ওষুধ যোগ করুন' : (code == 'hi' ? 'नई दवा जोड़ें' : 'Add New Medicine');
  String get editMedicine => code == 'bn' ? 'ওষুধ সম্পাদনা করুন' : (code == 'hi' ? 'दवा संपादित करें' : 'Edit Medicine');
  String get medicineName => code == 'bn' ? 'ওষুধের নাম *' : (code == 'hi' ? 'दवा का नाम *' : 'Medicine Name *');
  String get medicineNameHint => code == 'bn' ? 'যেমন: প্যারাসিটামল, অ্যামোক্সিসিলিন' : (code == 'hi' ? 'जैसे: पैरासिटामोल, एमोक्सिसिलिन' : 'e.g. Paracetamol, Amoxicillin');
  String get dosageStrength => code == 'bn' ? 'ডোজ / মাত্রা *' : (code == 'hi' ? 'खुराक / मात्रा *' : 'Dosage / Strength *');
  String get strengthHint => code == 'bn' ? 'যেমন: ৫০০ মি.গ্রা., ১টি ট্যাবলেট বা ১০ মিলি' : (code == 'hi' ? 'जैसे: ५०० मि.ग्रा., १ गोली या १० मि.ली.' : 'e.g. 500 mg, 1 tablet, 10 ml');
  String get assignToFamilyMember => code == 'bn' ? 'পরিবারের সদস্যের জন্য নির্ধারণ' : (code == 'hi' ? 'परिवार के सदस्य के लिए चुनें' : 'Assign To Family Member');
  String get medicineDetails => code == 'bn' ? 'ওষুধের তথ্য' : (code == 'hi' ? 'दवा का विवरण' : 'Medicine Details');
  String get formAndIcon => code == 'bn' ? 'ওষুধের ধরন ও আইকন' : (code == 'hi' ? 'दवा का प्रकार और आइकन' : 'Medicine Form & Icon');
  String get pillColorTag => code == 'bn' ? 'রঙিন ট্যাগ' : (code == 'hi' ? 'रंग का टैग' : 'Pill Color Tag');
  String get foodTimingInstruction => code == 'bn' ? 'খাওয়ার নিয়ম (ফুড টাইমিং)' : (code == 'hi' ? 'दवा लेने का नियम (भोजन समय)' : 'Intake Instruction (Food Timing)');
  String get reminderSchedules => code == 'bn' ? 'অ্যালার্ম সময়সূচী' : (code == 'hi' ? 'अलार्म का समय' : 'Reminder Schedules');
  String get addTime => code == 'bn' ? 'সময় যোগ করুন' : (code == 'hi' ? 'समय जोड़ें' : 'Add Time');
  String get loudAlarm => code == 'bn' ? 'ফুল স্ক্রিন অ্যালার্ম ও রিংটোন' : (code == 'hi' ? 'फुल स्क्रीन अलार्म व रिंगटोन' : 'Loud Alarm (Screen + Sound)');
  String get gentleNotification => code == 'bn' ? 'সহজ নোটিফিকেশন' : (code == 'hi' ? 'साधारण सूचना' : 'Gentle Notification');
  String get stockInventory => code == 'bn' ? 'স্টক ও ইনভেন্টরি ট্র্যাকিং' : (code == 'hi' ? 'स्टॉक और इन्वेंट्री ट्रैकिंग' : 'Stock & Inventory Tracking');
  String get currentQuantity => code == 'bn' ? 'বর্তমান স্টকের সংখ্যা' : (code == 'hi' ? 'वर्तमान स्टॉक संख्या' : 'Current Quantity');
  String get lowAlertLimit => code == 'bn' ? 'কম স্টকের সতর্কবার্তা সীমা' : (code == 'hi' ? 'कम स्टॉक की चेतावनी सीमा' : 'Low Alert Limit');
  String get doctorNotesOptional => code == 'bn' ? 'ডাক্তারের পরামর্শ ও টিপস (ঐচ্ছিক)' : (code == 'hi' ? 'डॉक्टर की सलाह व टिप्स (वैकल्पिक)' : 'Doctor Notes & Tips (Optional)');
  String get notesHint => code == 'bn' ? 'যেমন: এক গ্লাস পানি দিয়ে খাবেন। ডেইরি প্রোডাক্ট এড়িয়ে চলুন।' : (code == 'hi' ? 'जैसे: एक गिलास पानी के साथ लें। दूध से परहेज करें।' : 'e.g. Drink a full glass of water. Avoid dairy products.');
  String get saveMedicineBtn => code == 'bn' ? 'ওষুধ সংরক্ষণ করুন' : (code == 'hi' ? 'दवा सुरक्षित करें' : 'Save Medicine');
  String get updateMedicineBtn => code == 'bn' ? 'তথ্য আপডেট করুন' : (code == 'hi' ? 'दवा अपडेट करें' : 'Update Medicine');
  String get saveAndSetReminders => code == 'bn' ? 'সংরক্ষণ ও অ্যালার্ম সেট করুন' : (code == 'hi' ? 'सुरक्षित करें और अलार्म लगाएं' : 'Save & Set Reminders');
  String get forWhom => code == 'bn' ? 'কার জন্য এই ওষুধ? *' : (code == 'hi' ? 'यह दवा किसके लिए है? *' : 'Who is this medicine for? *');
  String get save => code == 'bn' ? 'সংরক্ষণ' : (code == 'hi' ? 'सुरक्षित करें' : 'Save');
  String get cancel => code == 'bn' ? 'বাতিল' : (code == 'hi' ? 'रद्द करें' : 'Cancel');
  String get enterNameValidation => code == 'bn' ? 'অনুগ্রহ করে ওষুধের নাম লিখুন' : (code == 'hi' ? 'कृपया दवा का नाम दर्ज करें' : 'Please enter medicine name');
  String get enterDosageValidation => code == 'bn' ? 'অনুগ্রহ করে মাত্রা লিখুন' : (code == 'hi' ? 'कृपया खुराक दर्ज करें' : 'Please enter dosage');
  String get addAtLeastOneReminder => code == 'bn' ? 'কমপক্ষে একটি অ্যালার্মের সময় নির্ধারণ করুন' : (code == 'hi' ? 'कृपया कम से कम एक अलार्म समय जोड़ें' : 'Please add at least one reminder time.');

  // History & Statistics
  String get doseHistory => code == 'bn' ? 'ইতিহাস ও বিশ্লেষণ' : (code == 'hi' ? 'इतिहास व विश्लेषण' : 'History & Analytics');
  String get filterBy => code == 'bn' ? 'ফিল্টার' : (code == 'hi' ? 'फिल्टर' : 'Filter by');
  String get allTime => code == 'bn' ? 'সব সময়' : (code == 'hi' ? 'सभी समय' : 'All Time');
  String get past7Days => code == 'bn' ? 'বিগত ৭ দিন' : (code == 'hi' ? 'पिछले ७ दिन' : 'Past 7 Days');
  String get past30Days => code == 'bn' ? 'বিগত ৩০ দিন' : (code == 'hi' ? 'पिछले ३० दिन' : 'Past 30 Days');
  String get adherenceRate => code == 'bn' ? 'গ্রহণের হার' : (code == 'hi' ? 'सफलता दर' : 'Adherence');
  String get overallScore => code == 'bn' ? 'সামগ্রিক হার' : (code == 'hi' ? 'कुल स्कोर' : 'Overall score');
  String get currentStreak => code == 'bn' ? 'চলমান ধারাবাহিকতা' : (code == 'hi' ? 'लगातार क्रम' : 'Current Streak');
  String get keepItUp => code == 'bn' ? 'ধারাবাহিকতা বজায় রাখুন!' : (code == 'hi' ? 'ऐसे ही जारी रखें!' : 'Keep it up!');
  String get dosesConfirmed => code == 'bn' ? 'নিশ্চিত গ্রহণ' : (code == 'hi' ? 'पुष्टि की गई' : 'Doses confirmed');
  String get dosesMissed => code == 'bn' ? 'বাদ বা মিস হওয়া' : (code == 'hi' ? 'छूट गई खुराक' : 'Doses missed/skipped');
  String get weeklyAdherenceBreakdown => code == 'bn' ? 'সাপ্তাহিক গ্রহণের অনুপাত' : (code == 'hi' ? 'साप्ताहिक दवा लेने का विश्लेषण' : 'Weekly Adherence Breakdown');
  String get weeklyAdherenceSub => code == 'bn' ? 'প্রতিদিন নির্ধারিত ওষুধ নেওয়ার শতাংশ' : (code == 'hi' ? 'प्रतिदिन निर्धारित दवाओं का प्रतिशत' : 'Percentage of scheduled medicines taken each day');
  String get doctorConsultationSummary => code == 'bn' ? 'ডাক্তারের পরামর্শ সারসংক্ষেপ' : (code == 'hi' ? 'डॉक्टर परामर्श सारांश' : 'Doctor Consultation Summary');
  String get exportDoctorPdfSub => code == 'bn' ? 'ডাক্তারকে দেখানোর জন্য ১ পাতার PDF তৈরি করুন' : (code == 'hi' ? 'डॉक्टर के लिए १-पेज का PDF सारांश निकालें' : 'Export 1-page compliance PDF for physician visit');
  String get export => code == 'bn' ? 'এক্সপোর্ট' : (code == 'hi' ? 'निर्यात' : 'Export');
  String get exportDoctorPdf => code == 'bn' ? 'ডাক্তার PDF এক্সপোর্ট' : (code == 'hi' ? 'डॉक्टर PDF निर्यात' : 'Export Doctor PDF');
  String get recentActivity => code == 'bn' ? 'সাম্প্রতিক কার্যকলাপ' : (code == 'hi' ? 'हाल की गतिविधि' : 'Recent Activity');
  String get records => code == 'bn' ? 'টি রেকর্ড' : (code == 'hi' ? 'रिकॉर्ड' : 'Records');
  String get noIntakeLogsTitle => code == 'bn' ? 'এখনও কোনো লগ রেকর্ড নেই' : (code == 'hi' ? 'अभी तक कोई रिकॉर्ड नहीं है' : 'No intake logs recorded yet.');
  String get noIntakeLogsSub => code == 'bn' ? 'ওষুধ খাওয়া সম্পন্ন বা বাদ দিলে এখানে ইতিহাস দেখা যাবে।' : (code == 'hi' ? 'दवा लेने या छोड़ने पर यहां इतिहास दिखाई देगा।' : 'Take or skip scheduled medicines to see history here.');
  String get doseLabel => code == 'bn' ? 'ডোজ' : (code == 'hi' ? 'खुराक' : 'Dose');

  // Settings & Diagnostics
  String get settingsAndDiagnostics => code == 'bn' ? 'সেটিংস ও ডায়াগনস্টিকস' : (code == 'hi' ? 'सेटिंग्स और निदान' : 'Settings & Diagnostics');
  String get androidAlarmReliability => code == 'bn' ? 'অ্যান্ড্রয়েড অ্যালার্ম নির্ভরযোগ্যতা' : (code == 'hi' ? 'एंड्रॉयड अलार्म विश्वसनीयता' : 'Android Alarm Reliability');
  String get androidAlarmSub => code == 'bn' ? 'অ্যান্ড্রয়েড ১২, ১৩, ১৪ এবং ১৫+ ডিভাইসে সঠিক সময়ে কোনো বিলম্ব ছাড়া অ্যালার্ম বাজতে নিচের অনুমতিগুলো চালু রাখুন।' : (code == 'hi' ? 'एंड्रॉयड १२, १३, १४ व १५+ पर सही समय पर अलार्म बजने के लिए नीचे दी गई अनुमतियों को चालू रखें।' : 'To ensure medicines ring precisely on time on Android 12, 13, 14, and 15+, make sure all permissions below are active.');
  String get grantAllPermissions => code == 'bn' ? 'সব অনুমতি প্রদান করুন' : (code == 'hi' ? 'सभी अनुमतियां दें' : 'Grant All Permissions');
  String get systemPermissions => code == 'bn' ? 'সিস্টেম অনুমতি (ANDROID 12-15+)' : (code == 'hi' ? 'सिस्टम अनुमतियां (ANDROID 12-15+)' : 'SYSTEM PERMISSIONS (ANDROID 12-15+)');
  String get notificationPermission => code == 'bn' ? 'নোটিফিকেশন অনুমতি' : (code == 'hi' ? 'सूचना (Notification) अनुमति' : 'Notification Permission');
  String get notifSub => code == 'bn' ? 'অ্যালার্ট ও ওষুধের ব্যানার দেখানোর জন্য আবশ্যক।' : (code == 'hi' ? 'अलर्ट और दवा के बैनर दिखाने के लिए आवश्यक।' : 'Required by Android 13+ to show alerts and reminders.');
  String get exactAlarmPermission => code == 'bn' ? 'সঠিক সময়ে অ্যালার্ম (Exact Alarm)' : (code == 'hi' ? 'सटीक समय अलार्म (Exact Alarm)' : 'Exact Alarm Permission');
  String get exactAlarmSub => code == 'bn' ? 'জিরো-ডিলে এবং সঠিক সেকেন্ডে রিংটোন বাজাতে প্রয়োজন।' : (code == 'hi' ? 'बिना किसी देरी के सही समय पर अलार्म के लिए जरूरी।' : 'Required on Android 12 & 14+ for zero-delay alarms.');
  String get batteryOptimization => code == 'bn' ? 'ব্যাটারি অপটিমাইজেশন উপেক্ষা' : (code == 'hi' ? 'बैटरी अनुकूलन अनदेखा करें' : 'Ignore Battery Optimization');
  String get batteryOptimizationSub => code == 'bn' ? 'সিস্টেম যাতে স্লিপ মোডে অ্যালার্ম বন্ধ না করে দেয়।' : (code == 'hi' ? 'सिस्टम को बैकग्राउंड में अलार्म बंद करने से रोकता है।' : 'Prevents system from putting alarms to sleep.');
  String get activeBadge => code == 'bn' ? 'সক্রিয়' : (code == 'hi' ? 'चालू' : 'Active');
  String get missingBadge => code == 'bn' ? 'প্রয়োজন' : (code == 'hi' ? 'बाकी' : 'Missing');
  String get alarmSoundBannerTest => code == 'bn' ? 'অ্যালার্ম সাউন্ড ও ব্যানার টেস্ট' : (code == 'hi' ? 'अलार्म ध्वनि और बैनर टेस्ट' : 'ALARM SOUND & BANNER TEST');
  String get testAlarmNotifications => code == 'bn' ? 'নোটিফিকেশন অ্যালার্ট টেস্ট' : (code == 'hi' ? 'अलार्म नोटिफिकेशन टेस्ट' : 'Test Alarm Notifications');
  String get testAlarmSub => code == 'bn' ? 'কাস্টম ৩D আইকন ও শব্দের সাথে লাইভ নোটিফিকেশন পরখ করুন।' : (code == 'hi' ? 'कस्टम ३D आइकन और ध्वनि के साथ नोटिफिकेशन जांचें।' : 'Trigger real notifications with custom medicine icons.');
  String get familyMembersProfiles => code == 'bn' ? 'পরিবারের সদস্য ও প্রোফাইল' : (code == 'hi' ? 'परिवार के सदस्य और प्रोफाइल' : 'FAMILY MEMBERS & PROFILES');
  String get languageOption => code == 'bn' ? 'ভাষা নির্বাচন (LANGUAGE)' : (code == 'hi' ? 'भाषा चयन (LANGUAGE)' : 'LANGUAGE (ভাষা)');
  String get selectLanguage => code == 'bn' ? 'আপনার পছন্দের ভাষা বেছে নিন' : (code == 'hi' ? 'अपनी पसंदीदा भाषा चुनें' : 'Choose Your Preferred Language');
  String get langEnglish => 'English';
  String get langBengali => 'বাংলা';
  String get langHindi => 'हिन्दी';
  String get aboutMediRemind => code == 'bn' ? 'MEDIREMIND সম্পর্কে' : (code == 'hi' ? 'MEDIREMIND के बारे में' : 'ABOUT MEDIREMIND');
  String get appDescription => code == 'bn' ? 'সঠিক সময়ে ওষুধ গ্রহণের জন্য নির্ভরযোগ্য ও আধুনিক স্বাস্থ্য সঙ্গী। অফলাইন-ফার্স্ট এবং সম্পূর্ণ সুরক্ষিত।' : (code == 'hi' ? 'समय पर दवा लेने के लिए विश्वसनीय और आधुनिक साथी। ऑफलाइन-फर्स्ट और सुरक्षित।' : 'Designed for reliable, on-time medication schedules across all Android versions. Private, offline-first, and battery-friendly.');

  // Welcome Screen
  String get welcomeTitle => code == 'bn' ? 'আপনার স্বাস্থ্যের পূর্ণ নিয়ন্ত্রণ নিন' : (code == 'hi' ? 'अपने स्वास्थ्य का पूरा नियंत्रण लें' : 'Take Control of Your Health');
  String get welcomeSub => code == 'bn' ? 'সময়মতো ওষুধ গ্রহণ করুন এবং পরিবারের সুস্থতা বজায় রাখুন' : (code == 'hi' ? 'समय पर दवा लें और परिवार की सेहत सुरक्षित रखें' : 'Never miss a dose for you and your loved ones');
  String get exactAlarmsFeature => code == 'bn' ? 'সঠিক সময়ে অ্যালার্ম' : (code == 'hi' ? 'सटीक समय पर अलार्म' : 'Exact Alarms');
  String get familyProfilesFeature => code == 'bn' ? 'পরিবারের প্রতিটি সদস্যের প্রোফাইল' : (code == 'hi' ? 'परिवार के सदस्यों की प्रोफाइल' : 'Family Profiles');
  String get cloudSyncFeature => code == 'bn' ? 'ক্লাউড ব্যাকআপ ও অফলাইন নিরাপত্তা' : (code == 'hi' ? 'ক্লাউড बैकअप और ऑफलाइन सुरक्षा' : 'Cloud Sync & Offline Safe');
  String get getStarted => code == 'bn' ? 'শুরু করুন' : (code == 'hi' ? 'शुरू करें' : 'Get Started');

  // Alarm Ringing Screen
  String get timeForMedicine => code == 'bn' ? 'ওষুধ খাওয়ার সময় হয়েছে!' : (code == 'hi' ? 'দवा लेने का समय हो गया है!' : 'Time for your medicine!');
  String get medicineReminderTag => code == 'bn' ? 'মেডিসিন রিমাইন্ডার' : (code == 'hi' ? 'দवाई रिमाइंडर' : 'MEDICINE REMINDER');

  // Authentication & Cloud Sync
  String get phoneLoginTitle => code == 'bn' ? 'মোবাইল নম্বর দিয়ে লগইন করুন' : (code == 'hi' ? 'फ़ोन नंबर से लॉगिन करें' : 'Sign In with Mobile');
  String get phoneLoginSub => code == 'bn' ? 'ওষুধের তালিকা এবং গ্রহণের ইতিহাস নিরাপদে ক্লাউডে ব্যাকআপ রাখুন।' : (code == 'hi' ? 'दवाइयों की सूची और इतिहास सुरक्षित क्लाउड में बैकअप रखें।' : 'Securely backup medications and intake history to the cloud.');
  String get enterPhoneNumber => code == 'bn' ? 'মোবাইল নম্বর লিখুন' : (code == 'hi' ? 'फ़ोन नंबर दर्ज करें' : 'Enter Mobile Number');
  String get enterPhoneHint => code == 'bn' ? '১০ ডিজিটের নম্বর' : (code == 'hi' ? '१० अंकों का नंबर' : '10-digit mobile number');
  String get sendOtpBtn => code == 'bn' ? 'OTP পাঠান' : (code == 'hi' ? 'OTP भेजें' : 'Send OTP');
  String get verifyOtpTitle => code == 'bn' ? 'OTP যাচাইকরণ' : (code == 'hi' ? 'OTP सत्यापन' : 'Verify OTP');
  String get otpSentTo => code == 'bn' ? '৬ ডিজিটের কোড পাঠানো হয়েছে:' : (code == 'hi' ? '६ अंकों का कोड भेजा गया:' : '6-digit code sent to:');
  String get enterOtpHint => code == 'bn' ? '৬ ডিজিটের OTP' : (code == 'hi' ? '६ अंकों का OTP' : '6-digit OTP');
  String get verifyAndLoginBtn => code == 'bn' ? 'যাচাই করে এগিয়ে যান' : (code == 'hi' ? 'सत्यापित करें और आगे बढ़ें' : 'Verify & Continue');
  String get resendOtpIn => code == 'bn' ? 'পুনরায় কোড পাঠান' : (code == 'hi' ? 'पुनः कोड भेजें' : 'Resend code in');
  String get resendOtpBtn => code == 'bn' ? 'আবার কোড পাঠান' : (code == 'hi' ? 'फिर से भेजें' : 'Resend Code');
  String get continueAsGuest => code == 'bn' ? 'পরে করব (অতিথি মোড)' : (code == 'hi' ? 'बाद में (अतिथि मोड)' : 'Continue as Guest');
  String get accountAndCloudSync => code == 'bn' ? 'অ্যাকাউন্ট ও ক্লাউড ব্যাকআপ' : (code == 'hi' ? 'खाता और क्लाउड बैकअप' : 'ACCOUNT & CLOUD SYNC');
  String get cloudSyncActive => code == 'bn' ? 'ক্লাউড সিঙ্ক চালু' : (code == 'hi' ? 'क्लाउड सिंक सक्रिय' : 'Cloud Sync Active');
  String get cloudSyncInactive => code == 'bn' ? 'শুধুমাত্র অফলাইন (লগইন প্রয়োজন)' : (code == 'hi' ? 'केवल ऑफलाइन (लॉगिन करें)' : 'Offline Only (Login to Sync)');
  String get loginToBackup => code == 'bn' ? 'লগইন করে ডেটা ব্যাকআপ রাখুন' : (code == 'hi' ? 'डेटा बैकअप के लिए लॉगिन करें' : 'Sign in to backup your health data');
  String get signOutBtn => code == 'bn' ? 'লগআউট' : (code == 'hi' ? 'लॉगआउट' : 'Sign Out');
  String get signOutConfirmTitle => code == 'bn' ? 'লগআউট নিশ্চিত করুন' : (code == 'hi' ? 'लॉगआउट की पुष्टि करें' : 'Confirm Sign Out');
  String get signOutConfirmMessage => code == 'bn' ? 'আপনি কি নিশ্চিতভাবে এই ডিভাইস থেকে লগআউট করতে চান? আপনার সংরক্ষিত ডেটা ক্লাউডে সুরক্ষিত থাকবে।' : (code == 'hi' ? 'क्या आप इस डिवाइस से लॉगआउट करना चाहते हैं? आपका डेटा क्लाउड में सुरक्षित रहेगा।' : 'Are you sure you want to sign out from this device? Your data remains safe in the cloud.');
  String get otpInvalidValidation => code == 'bn' ? 'অনুগ্রহ করে সঠিক ৬ ডিজিটের OTP লিখুন' : (code == 'hi' ? 'कृपया सही ६ अंकों का OTP दर्ज करें' : 'Please enter a valid 6-digit OTP');
  String get phoneInvalidValidation => code == 'bn' ? 'অনুগ্রহ করে বৈধ ১০ ডিজিটের মোবাইল নম্বর লিখুন' : (code == 'hi' ? 'कृपया मान्य १० अंकों का फ़ोन नंबर दर्ज करें' : 'Please enter a valid 10-digit mobile number');
}
