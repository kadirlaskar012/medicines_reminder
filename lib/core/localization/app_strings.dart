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
  String get tabCabinet => code == 'bn' ? 'ওষুধ' : (code == 'hi' ? 'दवाइयां' : 'Medicines');
  String get tabHistory => code == 'bn' ? 'ইতিহাস' : (code == 'hi' ? 'इतिहास' : 'History');
  String get tabSettings => code == 'bn' ? 'সেটিংস' : (code == 'hi' ? 'सेटिंग्स' : 'Settings');
  String get todayTab => tabToday;
  String get medicinesTab => tabCabinet;
  String get settingsTab => tabSettings;
  String get searchMedicineHint => code == 'bn' ? 'ওষুধ বা ডোজ অনুসন্ধান করুন...' : (code == 'hi' ? 'दवा या खुराक खोजें...' : 'Search medicines...');
  String get refillStockTitle => code == 'bn' ? 'স্টক রিফিল করুন' : (code == 'hi' ? 'स्टॉक रीफिल करें' : 'Refill Stock');
  String get addedPillsCount => code == 'bn' ? 'নতুন যোগ করা ওষুধের সংখ্যা' : (code == 'hi' ? 'जोड़ी गई गोलियों की संख्या' : 'Pills to add');
  String get addStockBtn => code == 'bn' ? 'স্টক যুক্ত করুন' : (code == 'hi' ? 'स्टॉक जोड़ें' : 'Add Stock');
  String get deleteConfirmTitle => code == 'bn' ? 'ওষুধ মুছে ফেলুন' : (code == 'hi' ? 'दवा हटाएं' : 'Delete Medicine');
  String get deleteConfirmMessage => code == 'bn' ? 'আপনি কি নিশ্চিত যে মুছে ফেলতে চান?' : (code == 'hi' ? 'क्या आप वाकई इसे हटाना चाहते हैं?' : 'Are you sure you want to delete?');
  String get delete => code == 'bn' ? 'মুছে ফেলুন' : (code == 'hi' ? 'हटाएं' : 'Delete');

  // Today / Daily Schedule
  String get todayDate => code == 'bn' ? 'আজকের তারিখ' : (code == 'hi' ? 'आज की तारीख' : 'Today');
  String get resetToToday => code == 'bn' ? 'আজকের তারিখ' : (code == 'hi' ? 'आज की तारीख' : 'Today');
  String get allTakenStatus => code == 'bn' ? 'সব ওষুধ নেওয়া হয়েছে' : (code == 'hi' ? 'सभी दवाएं ली गईं' : 'All Taken');
  String get partialStatus => code == 'bn' ? 'আংশিক নেওয়া হয়েছে' : (code == 'hi' ? 'आंशिक खुराक' : 'Partially Taken');
  String get missedStatus => code == 'bn' ? 'ওষুধ বাদ/মিস হয়েছে' : (code == 'hi' ? 'दवा छूट गई' : 'Missed / Skipped');
  String get dailySchedule => code == 'bn' ? 'আজকের শিডিউল' : (code == 'hi' ? 'दैनिक अनुसूची' : 'Daily Schedule');
  String get allDoneToday => code == 'bn' ? 'আজকের সব ওষুধ নেওয়া সম্পন্ন!' : (code == 'hi' ? 'आज की सभी दवाएं पूरी हुईं!' : 'All Done for Today!');
  String get allDoneSub => code == 'bn' ? 'আপনার স্বাস্থ্যের যত্ন নেওয়ার জন্য চমৎকার কাজ।' : (code == 'hi' ? 'अपने स्वास्थ्य का ध्यान रखने के लिए बहुत बढ़िया।' : 'Great job staying on track with your health.');
  String get dosesRemaining => code == 'bn' ? 'ওষুধ বাকি আছে' : (code == 'hi' ? 'दवाइयां बाकी हैं' : 'doses remaining');
  String get morning => code == 'bn' ? 'সকাল' : (code == 'hi' ? 'सुबह' : 'Morning');
  String get afternoon => code == 'bn' ? 'দুপুর' : (code == 'hi' ? 'दोपहर' : 'Afternoon');
  String get evening => code == 'bn' ? 'সন্ধ্যা' : (code == 'hi' ? 'शाम' : 'Evening');
  String get night => code == 'bn' ? 'রাত' : (code == 'hi' ? 'रात' : 'Night');
  String get noDosesScheduled => code == 'bn' ? 'এই দিনের জন্য কোনো ওষুধ নেই' : (code == 'hi' ? 'इस दिन के लिए कोई दवा नहीं है' : 'No medicines scheduled for this day');
  String get tapToAddFirst => code == 'bn' ? 'নতুন ওষুধ যুক্ত করতে নিচের + বোতাম চাপুন' : (code == 'hi' ? 'नई दवा जोड़ने के लिए नीचे + बटन दबाएं' : 'Tap + below to add your medicines');
  String get adherenceScore => code == 'bn' ? 'আজকের গ্রহণের হার' : (code == 'hi' ? 'आज की सफलता दर' : 'Today\'s Adherence');

  // Time-based Greetings
  String get goodMorning => code == 'bn' ? 'শুভ সকাল,' : (code == 'hi' ? 'सुप्रभात,' : 'Good morning,');
  String get goodAfternoon => code == 'bn' ? 'শুভ দুপুর,' : (code == 'hi' ? 'शुभ दोपहर,' : 'Good afternoon,');
  String get goodEvening => code == 'bn' ? 'শুভ সন্ধ্যা,' : (code == 'hi' ? 'शुभ संध्या,' : 'Good evening,');
  String get goodNight => code == 'bn' ? 'শুভ রাত্রি,' : (code == 'hi' ? 'शुभ रात्रि,' : 'Good night,');

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
  String get today => code == 'bn' ? 'আজ' : (code == 'hi' ? 'आज' : 'Today');

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

  // Measurement Units
  String unitName(String unit) {
    switch (unit.toLowerCase()) {
      case 'tablets':
      case 'tablet': return code == 'bn' ? 'ট্যাবলেট' : (code == 'hi' ? 'टैबलेट' : 'Tablets');
      case 'capsules':
      case 'capsule': return code == 'bn' ? 'ক্যাপসুল' : (code == 'hi' ? 'कैप्सूल' : 'Capsules');
      case 'pills':
      case 'pill': return code == 'bn' ? 'পিল' : (code == 'hi' ? 'गोलियां' : 'Pills');
      case 'strips':
      case 'strip': return code == 'bn' ? 'স্ট্রিপ (পাতা)' : (code == 'hi' ? 'पत्ता (स्ट्रिप)' : 'Strips');
      case 'ml': return 'ml';
      case 'bottles':
      case 'bottle': return code == 'bn' ? 'বোতল' : (code == 'hi' ? 'बोतल' : 'Bottles');
      case 'spoons':
      case 'spoon': return code == 'bn' ? 'চামচ' : (code == 'hi' ? 'चम्मच' : 'Spoons');
      case 'drops':
      case 'drop': return code == 'bn' ? 'ড্রপ' : (code == 'hi' ? 'बूंदें' : 'Drops');
      case 'puffs':
      case 'puff': return code == 'bn' ? 'পাফ' : (code == 'hi' ? 'पफ' : 'Puffs');
      case 'canisters':
      case 'canister': return code == 'bn' ? 'ক্যানিস্টার' : (code == 'hi' ? 'कैनिस्टर' : 'Canisters');
      case 'vials':
      case 'vial': return code == 'bn' ? 'ভায়াল' : (code == 'hi' ? 'वायल' : 'Vials');
      case 'ampoules':
      case 'ampoule': return code == 'bn' ? 'অ্যাম্পুল' : (code == 'hi' ? 'एम्पूल' : 'Ampoules');
      case 'tubes':
      case 'tube': return code == 'bn' ? 'টিউব' : (code == 'hi' ? 'ट्यूब' : 'Tubes');
      case 'g': return 'g';
      case 'softgels': return code == 'bn' ? 'সফটজেল' : (code == 'hi' ? 'सॉफ्टजेल' : 'Softgels');
      case 'gummies': return code == 'bn' ? 'গামিজ' : (code == 'hi' ? 'गमीज़' : 'Gummies');
      case 'units': return code == 'bn' ? 'ইউনিট' : (code == 'hi' ? 'यूनिट' : 'Units');
      case 'doses': return code == 'bn' ? 'ডোজ' : (code == 'hi' ? 'खुराक' : 'Doses');
      case 'packs': return code == 'bn' ? 'প্যাক' : (code == 'hi' ? 'पैक' : 'Packs');
      default: return unit;
    }
  }

  String formatStockLeft(int count, String unit) {
    final localizedUnit = unitName(unit);
    if (code == 'bn') {
      if (unit.toLowerCase() == 'tablets' || unit.toLowerCase() == 'pills' || unit.toLowerCase() == 'capsules' || unit.isEmpty) {
        return '$countটি বাকি';
      }
      return '$count $localizedUnit বাকি';
    } else if (code == 'hi') {
      return '$count $localizedUnit बची हैं';
    }
    return '$count $localizedUnit left';
  }

  String get measurementUnitLabel => code == 'bn' ? 'পরিমাপক ইউনিট' : (code == 'hi' ? 'मापक इकाई' : 'Measurement Unit');

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
  String get signInWithGoogle => code == 'bn' ? 'গুগল দিয়ে সাইন ইন করুন' : (code == 'hi' ? 'गूगल से साइन इन करें' : 'Continue with Google');
  String get orSignInWithPhone => code == 'bn' ? 'অথবা মোবাইল নম্বর দিয়ে' : (code == 'hi' ? 'या मोबाइल नंबर से' : 'OR WITH MOBILE NUMBER');
  String get signInOrLoginTitle => code == 'bn' ? 'লগইন বা সাইন ইন করুন' : (code == 'hi' ? 'लॉगिन या साइन इन करें' : 'Sign In to Account');
  String get orTryGoogleSignIn => code == 'bn' ? 'SMS কোড আসছে না? গুগল দিয়ে লগইন করুন' : (code == 'hi' ? 'SMS कोड नहीं आ रहा? गूगल से लॉगिन करें' : 'SMS delayed? Try Google Sign-In');

  // Profile Setup & Onboarding
  String get setupProfileTitle => code == 'bn' ? 'আপনার প্রোফাইল সেটআপ' : (code == 'hi' ? 'अपनी प्रोफ़ाइल सेट करें' : 'Set Up Your Profile');
  String get setupProfileSub => code == 'bn' ? 'ঔষধের সঠিক হিসাব ও রিমাইন্ডারের জন্য নাম ও বয়স লিখুন।' : (code == 'hi' ? 'दवा के सही समय और रिमाइंडर के लिए अपना नाम व आयु दर्ज करें।' : 'Enter your name and age for personalized reminders.');
  String get yourName => code == 'bn' ? 'আপনার নাম' : (code == 'hi' ? 'आपका नाम' : 'Your Name');
  String get enterNameHint => code == 'bn' ? 'নাম লিখুন (যেমন: কাদির)' : (code == 'hi' ? 'नाम दर्ज करें (उदा: राहुल)' : 'Enter name (e.g. Kadir)');
  String get yourAge => code == 'bn' ? 'আপনার বয়স' : (code == 'hi' ? 'आपकी आयु' : 'Your Age');
  String get enterAgeHint => code == 'bn' ? 'বয়স (যেমন: ২৮)' : (code == 'hi' ? 'आयु (उदा: 28)' : 'Age (e.g. 28)');
  String get ageYears => code == 'bn' ? 'বছর' : (code == 'hi' ? 'वर्ष' : 'years');
  String get completeSetupBtn => code == 'bn' ? 'সেটআপ সম্পন্ন করুন' : (code == 'hi' ? 'सेटअप पूरा करें' : 'Complete Setup');
  String get skipForNow => code == 'bn' ? 'পরে করব' : (code == 'hi' ? 'बाद में करें' : 'Skip for now');
  String get nameRequired => code == 'bn' ? 'অনুগ্রহ করে আপনার নাম লিখুন' : (code == 'hi' ? 'कृपया अपना नाम दर्ज करें' : 'Please enter your name');
  String get ageRequired => code == 'bn' ? 'অনুগ্রহ করে সঠিক বয়স লিখুন (১-১২০)' : (code == 'hi' ? 'कृपया मान्य आयु दर्ज करें (1-120)' : 'Please enter a valid age (1-120)');
  String get editMyProfile => code == 'bn' ? 'আমার প্রোফাইল সম্পাদনা' : (code == 'hi' ? 'मेरी प्रोफाइल संपादित करें' : 'Edit My Profile');
  String get saveChanges => code == 'bn' ? 'সংরক্ষণ করুন' : (code == 'hi' ? 'सहेजें' : 'Save Changes');
  String get profileUpdated => code == 'bn' ? 'প্রোফাইল সফলভাবে সংরক্ষিত হয়েছে' : (code == 'hi' ? 'प्रोफाइल सफलतापूर्वक सहेज ली गई' : 'Profile saved successfully');

  // Theme & Appearance
  String get themeOption => code == 'bn' ? 'অ্যাপ থিম (THEME)' : (code == 'hi' ? 'ऐप थीम (THEME)' : 'APP THEME');
  String get themeSystem => code == 'bn' ? 'সিস্টেম ডিফল্ট' : (code == 'hi' ? 'सिस्टम डिफ़ॉल्ट' : 'System');
  String get themeLight => code == 'bn' ? 'লাইট মোড' : (code == 'hi' ? 'लाइट मोड' : 'Light');
  String get themeDark => code == 'bn' ? 'ডার্ক মোড' : (code == 'hi' ? 'डार्क मोड' : 'Dark');

  // Celebration Banner
  String get allDosesCompletedTitle => code == 'bn' ? 'চমৎকার! আজকের সব ওষুধ সম্পন্ন 🎉' : (code == 'hi' ? 'शाबाश! आज की सभी दवाएं पूरी हुईं 🎉' : 'Great Job! All Doses Completed 🎉');
  String get allDosesCompletedSub => code == 'bn' ? 'আপনি সফলভাবে আজকের ১০০% নিয়ম মেনে চলেছেন। সুস্থ থাকুন!' : (code == 'hi' ? 'आपने आज १००% समय पर दवा ली है। स्वस्थ रहें!' : 'You reached 100% adherence for today. Keep staying healthy!');

  // Treatment Course Duration
  String get treatmentCourse => code == 'bn' ? 'চিকিৎসার মেয়াদ / কোর্স (Treatment Course)' : (code == 'hi' ? 'इलाज की अवधि (Course)' : 'Treatment Course');
  String get courseOngoing => code == 'bn' ? 'চলমান / নিয়মিত' : (code == 'hi' ? 'दीर्घकालिक / नियमित' : 'Ongoing / Chronic');
  String courseDaysLabel(int days) {
    if (days == 14) return code == 'bn' ? '২ সপ্তাহ' : (code == 'hi' ? '२ सप्ताह' : '2 Weeks');
    if (days == 30) return code == 'bn' ? '১ মাস' : (code == 'hi' ? '१ महीना' : '1 Month');
    return code == 'bn' ? '$days দিন' : (code == 'hi' ? '$days दिन' : '$days Days');
  }
  String get twoWeeks => code == 'bn' ? '২ সপ্তাহ' : (code == 'hi' ? '२ सप्ताह' : '2 Weeks');
  String get threeDays => code == 'bn' ? '৩ দিন' : (code == 'hi' ? '३ दिन' : '3 Days');
  String get sevenDays => code == 'bn' ? '৭ দিন' : (code == 'hi' ? '७ दिन' : '7 Days');
  String get tenDays => code == 'bn' ? '১০ দিন' : (code == 'hi' ? '१० दिन' : '10 Days');
  String get twentyOneDays => code == 'bn' ? '২১ দিন' : (code == 'hi' ? '२१ दिन' : '21 Days');
  String get oneMonth => code == 'bn' ? '১ মাস' : (code == 'hi' ? '१ महीना' : '1 Month');
  String get customCourse => code == 'bn' ? 'কাস্টম মেয়াদ' : (code == 'hi' ? 'कस्टम अवधि' : 'Custom Course');
  String get customEndDate => code == 'bn' ? 'কাস্টম শেষ তারিখ' : (code == 'hi' ? 'কাস্টম শেষ তারিখ' : 'Custom End Date');
  String get courseCompleted => code == 'bn' ? 'কোর্স সম্পন্ন' : (code == 'hi' ? 'कोर्स पूरा हुआ' : 'Course Completed');
  String get courseEndsOn => code == 'bn' ? 'কোর্স শেষ হবে' : (code == 'hi' ? 'कोर्स समाप्त होगा' : 'Ends on');

  // Quick Frequency Shortcuts
  String get quickDoseFrequency => code == 'bn' ? '১-ক্লিক ফ্রিকোয়েন্সি শর্টকাট' : (code == 'hi' ? '१-क्लिक खुराक शॉर्टकट' : 'Quick Frequency Shortcuts');
  String get doseOnceDaily => code == 'bn' ? '১ বার (১+০+০)' : (code == 'hi' ? '१ बार (१+०+०)' : 'Once (1-0-0)');
  String get doseTwiceDaily => code == 'bn' ? '২ বার (১+০+১)' : (code == 'hi' ? '२ बार (१+०+১)' : 'Twice (1-0-1)');
  String get doseThriceDaily => code == 'bn' ? '৩ বার (১+১+১)' : (code == 'hi' ? '३ बार (१+१+১)' : '3 Times (1-1-1)');
  String get doseFourDaily => code == 'bn' ? '৪ বার (১+১+১+১)' : (code == 'hi' ? '४ बार (१+१+১+১)' : '4 Times');
  String get doseAsNeeded => code == 'bn' ? 'প্রয়োজনে (SOS / As Needed)' : (code == 'hi' ? 'ज़रूरत पड़ने पर (SOS)' : 'As Needed (SOS)');

  // Routine & Meal Presets
  String get routineMealSlot => code == 'bn' ? 'ওষুধ খাওয়ার সময় ও নিয়ম (Taking Time)' : (code == 'hi' ? 'दवा लेने का समय और नियम' : 'Taking Time & Routine');
  String get morningSlot => code == 'bn' ? 'সকাল' : (code == 'hi' ? 'सुबह' : 'Morning');
  String get lunchSlot => code == 'bn' ? 'দুপুর' : (code == 'hi' ? 'दोपहर' : 'Lunch');
  String get afternoonSlot => code == 'bn' ? 'বিকাল' : (code == 'hi' ? 'दोपहर बाद' : 'Afternoon');
  String get eveningSlot => code == 'bn' ? 'সন্ধ্যা' : (code == 'hi' ? 'शाम' : 'Evening');
  String get nightSlot => code == 'bn' ? 'রাত্রি' : (code == 'hi' ? 'रात' : 'Night');

  String formatNumber(int n) {
    if (code == 'bn') {
      const bnDigits = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
      return n.toString().split('').map((c) {
        final d = int.tryParse(c);
        return d != null ? bnDigits[d] : c;
      }).join();
    } else if (code == 'hi') {
      const hiDigits = ['०', '१', '२', '३', '४', '५', '६', '७', '८', '९'];
      return n.toString().split('').map((c) {
        final d = int.tryParse(c);
        return d != null ? hiDigits[d] : c;
      }).join();
    }
    return n.toString();
  }

  String dailyDoseCount(int count) {
    final numStr = formatNumber(count);
    if (code == 'bn') {
      return 'দিনে $numStr বার';
    } else if (code == 'hi') {
      return 'दिन में $numStr बार';
    }
    if (count == 1) return 'Once Daily';
    if (count == 2) return 'Twice Daily';
    if (count == 3) return '3 Times Daily';
    return '$count Times Daily';
  }
  String get breakfast => code == 'bn' ? 'সকালের নাস্তা (Breakfast)' : (code == 'hi' ? 'सुबह का नाश्ता' : 'Breakfast');
  String get lunch => code == 'bn' ? 'দুপুরের খাবার (Lunch)' : (code == 'hi' ? 'दोपहर का भोजन' : 'Lunch');
  String get eveningSnacks => code == 'bn' ? 'বিকেলের নাস্তা (Evening)' : (code == 'hi' ? 'शाम का नाश्ता' : 'Evening Snacks');
  String get dinner => code == 'bn' ? 'রাতের খাবার (Dinner)' : (code == 'hi' ? 'रात का खाना' : 'Dinner');
  String get bedtimeSlot => code == 'bn' ? 'ঘুমানোর আগে (Bedtime)' : (code == 'hi' ? 'सोने से पहले' : 'Bedtime');
  String get customClock => code == 'bn' ? 'কাস্টম সময়' : (code == 'hi' ? 'कस्टम समय' : 'Custom Clock');
  String get addCustomTime => code == 'bn' ? '+ অন্য কাস্টম সময় যোগ করুন' : (code == 'hi' ? '+ अन्य कस्टम समय जोड़ें' : '+ Add Custom Time');
  String get extraDetailsOptional => code == 'bn' ? 'অতিরিক্ত তথ্য (ঐচ্ছিক)' : (code == 'hi' ? 'अतिरिक्त विवरण (वैकल्पिक)' : 'Additional Details (Optional)');

  // Days of Week
  String get daysOfWeekTitle => code == 'bn' ? 'সপ্তাহের নির্দিষ্ট দিন' : (code == 'hi' ? 'सप्ताह के विशिष्ट दिन' : 'Days of the Week');
  String get everydayOption => code == 'bn' ? 'প্রতিদিন' : (code == 'hi' ? 'प्रतिदिन' : 'Everyday');

  // Medicine Strip Photo
  String get medicinePhoto => code == 'bn' ? 'ওষুধের পাতার আসল ছবি (ঐচ্ছিক)' : (code == 'hi' ? 'दवा के पत्ते की असली तस्वीर (वैकल्पिक)' : 'Medicine Strip / Box Photo (Optional)');
  String get takePhoto => code == 'bn' ? 'ক্যামেরা' : (code == 'hi' ? 'कैमरा' : 'Camera');
  String get chooseFromGallery => code == 'bn' ? 'গ্যালারি' : (code == 'hi' ? 'गैलरी' : 'Gallery');
  String get removePhoto => code == 'bn' ? 'ছবি মুছুন' : (code == 'hi' ? 'हटाएं' : 'Remove');

  // Expiry Date
  String get expiryDateTitle => code == 'bn' ? 'ওষুধের মেয়াদোত্তীর্ণের তারিখ (Expiry Date)' : (code == 'hi' ? 'दवा की समाप्ति तिथि (Expiry Date)' : 'Medicine Expiry Date');
  String get selectExpiryDate => code == 'bn' ? 'মেয়াদ শেষের তারিখ বেছে নিন' : (code == 'hi' ? 'समाप्ति तिथि चुनें' : 'Select Expiry Date');
  String get expiresOn => code == 'bn' ? 'মেয়াদ শেষ:' : (code == 'hi' ? 'समाप्ति:' : 'Expires:');
  String get expiredAlert => code == 'bn' ? 'মেয়াদোত্তীর্ণ!' : (code == 'hi' ? 'समाप्त!' : 'Expired!');
  String get change => code == 'bn' ? 'পরিবর্তন' : (code == 'hi' ? 'बदलें' : 'Change');

  // ==================== AUTH & ACCOUNT (EMAIL & PASSWORD) ====================
  String get authSignInTitle => code == 'bn' ? 'স্বাগতম ফিরে আসার জন্য' : (code == 'hi' ? 'वापसी पर स्वागत है' : 'Welcome Back');
  String get authSignInSub => code == 'bn'
      ? 'আপনার ওষুধের রিমাইন্ডার ও স্বাস্থ্য ডেটা সিঙ্ক করতে ইমেল দিয়ে সাইন ইন করুন'
      : (code == 'hi' ? 'अपनी दवाइयों के रिमाइंडर और स्वास्थ्य डेटा के लिए ईमेल से साइन इन करें' : 'Sign in with your email to access your reminders & health data');
  String get authSignUpTitle => code == 'bn' ? 'নতুন অ্যাকাউন্ট তৈরি করুন' : (code == 'hi' ? 'नया खाता बनाएं' : 'Create Account');
  String get authSignUpSub => code == 'bn'
      ? 'নিরাপদ ক্লাউড ব্যাকআপের জন্য আপনার ইমেল দিয়ে অ্যাকাউন্ট খুলুন'
      : (code == 'hi' ? 'सुरक्षित क्लाउड बैकअप के लिए ईमेल से खाता बनाएं' : 'Sign up with your email for secure cloud backup');
  String get authSignInTab => code == 'bn' ? 'সাইন ইন' : (code == 'hi' ? 'साइन इन' : 'Sign In');
  String get authSignUpTab => code == 'bn' ? 'সাইন আপ' : (code == 'hi' ? 'साइन अप' : 'Sign Up');
  String get authFullNameHint => code == 'bn' ? 'আপনার পুরো নাম (যেমন: কাদির লস্কর)' : (code == 'hi' ? 'आपका पूरा नाम (उदा. राहुल शर्मा)' : 'Your Full Name (e.g. John Doe)');
  String get authEmailHint => code == 'bn' ? 'আপনার ইমেল ঠিকানা (যেমন: name@gmail.com)' : (code == 'hi' ? 'आपका ईमेल पता (उदा. name@gmail.com)' : 'Your Email Address (e.g. name@gmail.com)');
  String get authPasswordHint => code == 'bn' ? 'পাসওয়ার্ড দিন (কমপক্ষে ৬ অক্ষর)' : (code == 'hi' ? 'पासवर्ड दर्ज करें (कम से कम ६ अक्षर)' : 'Password (at least 6 characters)');
  String get authPasswordSecretHint => code == 'bn' ? 'গোপন পাসওয়ার্ড লিখুন' : (code == 'hi' ? 'गोपनीय पासवर्ड दर्ज करें' : 'Enter secret password');
  String get authConfirmPasswordHint => code == 'bn' ? 'পাসওয়ার্ড নিশ্চিত করুন' : (code == 'hi' ? 'पासवर्ड की पुष्टि करें' : 'Confirm Password');
  String get authSecurityQuestionLabel => code == 'bn' ? 'পাসওয়ার্ড রিকভারি সিকিউরিটি প্রশ্ন' : (code == 'hi' ? 'पासवर्ड रिकवरी सुरक्षा प्रश्न' : 'Password Recovery Security Question');
  String get authSecurityAnswerHint => code == 'bn' ? 'আপনার উত্তর (যেমন: কলকাতা, ঢাকা)' : (code == 'hi' ? 'आपका उत्तर (उदा. कोलकाता, दिल्ली)' : 'Your Answer (e.g. London, Paris)');
  String get authSignInBtn => code == 'bn' ? 'ইমেল দিয়ে সাইন ইন করুন' : (code == 'hi' ? 'ईमेल से साइन इन करें' : 'Sign In with Email');
  String get authSignUpBtn => code == 'bn' ? 'অ্যাকাউন্ট তৈরি করুন' : (code == 'hi' ? 'खाता बनाएं' : 'Create Account');
  String get authForgotPasswordLink => code == 'bn' ? 'পাসওয়ার্ড ভুলে গেছেন?' : (code == 'hi' ? 'पासवर्ड भूल गए?' : 'Forgot Password?');
  String get authDontHaveAccount => code == 'bn' ? 'কোনো অ্যাকাউন্ট নেই? ' : (code == 'hi' ? 'कोई खाता नहीं है? ' : "Don't have an account? ");
  String get authAlreadyHaveAccount => code == 'bn' ? 'ইতিমধ্যে অ্যাকাউন্ট আছে? ' : (code == 'hi' ? 'पहले से खाता है? ' : 'Already have an account? ');

  List<String> get authSecurityQuestions {
    if (code == 'bn') {
      return [
        'আপনার জন্মস্থান বা প্রিয় শহর কোনটি?',
        'আপনার প্রথম স্কুলের নাম কী?',
        'আপনার প্রিয় খাবার কোনটি?',
        'আপনার শৈশবের প্রিয় বন্ধুর নাম কী?',
        'আপনার প্রিয় বই বা লেখকের নাম কী?',
      ];
    } else if (code == 'hi') {
      return [
        'आपका जन्मस्थान या पसंदीदा शहर कौन सा है?',
        'आपके पहले स्कूल का नाम क्या है?',
        'आपका पसंदीदा भोजन कौन सा है?',
        'आपके बचपन के सबसे अच्छे दोस्त का नाम क्या है?',
        'आपकी पसंदीदा किताब या लेखक का नाम क्या है?',
      ];
    }
    return [
      'What is your birthplace or favorite city?',
      'What is the name of your first school?',
      'What is your favorite food or dish?',
      'What is the name of your childhood best friend?',
      'What is your favorite book or author?',
    ];
  }

  // Auth Validation Messages
  String get errEnterValidEmail => code == 'bn' ? 'অনুগ্রহ করে একটি সঠিক ইমেল ঠিকানা লিখুন (যেমন: name@gmail.com)' : (code == 'hi' ? 'कृपया एक वैध ईमेल पता दर्ज करें (उदा. name@gmail.com)' : 'Please enter a valid email address (e.g. name@gmail.com)');
  String get errEnterPassword => code == 'bn' ? 'অনুগ্রহ করে আপনার পাসওয়ার্ড লিখুন' : (code == 'hi' ? 'कृपया अपना पासवर्ड दर्ज करें' : 'Please enter your password');
  String get errEnterFullName => code == 'bn' ? 'অনুগ্রহ করে আপনার পুরো নাম লিখুন' : (code == 'hi' ? 'कृपया अपना पूरा नाम दर्ज करें' : 'Please enter your full name');
  String get errPasswordLength => code == 'bn' ? 'পাসওয়ার্ড কমপক্ষে ৬ অক্ষরের হতে হবে' : (code == 'hi' ? 'पासवर्ड कम से कम ६ अक्षरों का होना चाहिए' : 'Password must be at least 6 characters');
  String get errPasswordsDoNotMatch => code == 'bn' ? 'দুইবারের পাসওয়ার্ড মিলছে না! একই পাসওয়ার্ড দিন।' : (code == 'hi' ? 'दोनों पासवर्ड मेल नहीं खाते! कृपया समान पासवर्ड दर्ज करें।' : 'Passwords do not match! Please enter the same password.');
  String get errEnterSecurityAnswer => code == 'bn' ? 'পাসওয়ার্ড রিকভারির জন্য সিকিউরিটি প্রশ্নের উত্তর দিন' : (code == 'hi' ? 'पासवर्ड रिकवरी के लिए सुरक्षा प्रश्न का उत्तर दें' : 'Please answer the security question for password recovery');
  String get msgSignInSuccess => code == 'bn' ? '🎉 সফলভাবে সাইন ইন হয়েছে! ক্লাউড ডেটা সিঙ্ক সক্রিয়।' : (code == 'hi' ? '🎉 सफलतापूर्वक साइन इन हुआ! क्लाउड सिंक सक्रिय है।' : '🎉 Signed in successfully! Cloud sync active.');
  String get msgSignUpSuccess => code == 'bn' ? '🛡️ সফলভাবে অ্যাকাউন্ট তৈরি হয়েছে ও ক্লাউড ব্যাকআপ সক্রিয় হয়েছে!' : (code == 'hi' ? '🛡️ खाता सफलतापूर्वक बनाया गया और क्लाउड बैकअप सक्रिय है!' : '🛡️ Account created successfully and cloud backup active!');
  String get msgInvalidCredentials => code == 'bn' ? '❌ ভুল ইমেল বা পাসওয়ার্ড! সঠিক তথ্য দিন অথবা Forgot Password চাপুন।' : (code == 'hi' ? '❌ गलत ईमेल या पासवर्ड! कृपया जांचें या पासवर्ड भूल गए पर टैप करें।' : '❌ Incorrect email or password! Please verify or tap Forgot Password.');
  String get msgEmailNotFound => code == 'bn' ? 'এই ইমেলে কোনো রেজিস্টার্ড অ্যাকাউন্ট পাওয়া যায়নি!' : (code == 'hi' ? 'इस ईमेल पर कोई पंजीकृत खाता नहीं मिला!' : 'No registered account found with this email!');
  String get msgAnswerIncorrect => code == 'bn' ? '❌ উত্তর সঠিক নয়! পুনরায় চেষ্টা করুন অথবা অ্যাডমিনের সাহায্য নিন।' : (code == 'hi' ? '❌ उत्तर गलत है! पुनः प्रयास करें या एडमिन से मदद लें।' : '❌ Incorrect answer! Please retry or request admin assistance.');
  String get msgPasswordResetSuccess => code == 'bn' ? '✅ পাসওয়ার্ড সফলভাবে পরিবর্তন ও সাইন ইন সম্পন্ন হয়েছে!' : (code == 'hi' ? '✅ पासवर्ड सफलतापूर्वक अपडेट किया गया!' : '✅ Password updated and signed in successfully!');

  // Supabase Inbuilt Auth & Email Verification
  String get authVerificationSentTitle => code == 'bn' ? 'ইমেল ভেরিফাই করুন' : (code == 'hi' ? 'ईमेल सत्यापित करें' : 'Verify Your Email');
  String authVerificationSentDesc(String email) => code == 'bn'
      ? '$email ঠিকানায় একটি ভেরিফিকেশন লিঙ্ক পাঠানো হয়েছে। দয়া করে আপনার ইনবক্স (বা স্প্যাম ফোল্ডার) চেক করুন এবং লিঙ্কটিতে ক্লিক করে অ্যাকাউন্টটি সক্রিয় করুন।'
      : (code == 'hi'
          ? '$email पर एक सत्यापन लिंक भेजा गया है। कृपया इनबॉक्स जांचें और लिंक पर क्लिक करके खाता सक्रिय करें।'
          : "We've sent a verification link to $email. Please check your inbox (and spam folder) and click the confirmation link to activate your account.");
  String get authEmailNotConfirmed => code == 'bn'
      ? 'ইমেল এখনো ভেরিফাই করা হয়নি! অনুগ্রহ করে আপনার ইনবক্স চেক করে লিঙ্কটিতে ক্লিক করুন।'
      : (code == 'hi'
          ? 'ईमेल अभी तक सत्यापित नहीं हुआ है! कृपया इनबॉक्स जांचें और लिंक पर क्लिक करें।'
          : 'Email not confirmed yet! Please check your inbox and verify your email before signing in.');
  String get authResendVerification => code == 'bn' ? 'ভেরিফিকেশন ইমেল পুনরায় পাঠান' : (code == 'hi' ? 'सत्यापन लिंक पुनः भेजें' : 'Resend Verification Email');
  String get authVerificationResent => code == 'bn' ? 'ভেরিফিকেশন লিঙ্ক সফলভাবে পাঠানো হয়েছে!' : (code == 'hi' ? 'सत्यापन लिंक पुनः भेजा गया!' : 'Verification link resent! Please check your inbox.');
  String get authAlreadyVerifiedBtn => code == 'bn' ? 'ভেরিফাই করেছি, সাইন ইন করুন' : (code == 'hi' ? 'सत्यापित कर लिया, साइन इन करें' : "I've Verified, Sign In");
  String get authOrEnterCode => code == 'bn' ? 'অথবা ইমেলের ৬ সংখ্যার কোড লিখুন' : (code == 'hi' ? 'या ईमेल का 6-अंकीय कोड दर्ज करें' : 'Or enter 6-digit verification code');
  String get authVerifyCodeBtn => code == 'bn' ? 'কোড ভেরিফাই করুন' : (code == 'hi' ? 'कोड सत्यापित करें' : 'Verify Code');
  String get authCheckingVerification => code == 'bn' ? 'ভেরিফিকেশন যাচাই করা হচ্ছে...' : (code == 'hi' ? 'सत्यापन जांचा जा रहा है...' : 'Checking verification...');
  String get authResetPasswordEmailDesc => code == 'bn'
      ? 'আপনার রেজিস্টার্ড ইমেল ঠিকানা দিন। আমরা আপনাকে পাসওয়ার্ড পরিবর্তনের অফিশিয়াল লিঙ্ক পাঠাব।'
      : (code == 'hi'
          ? 'अपना पंजीकृत ईमेल दर्ज करें। हम आपको पासवर्ड रीसेट लिंक भेजेंगे।'
          : 'Enter your registered email address. We will send you an official password reset link.');
  String get authSendResetLink => code == 'bn' ? 'রিসেট লিঙ্ক পাঠান' : (code == 'hi' ? 'रीसेट लिंक भेजें' : 'Send Reset Link');
  String get authPasswordResetSent => code == 'bn'
      ? 'পাসওয়ার্ড রিসেট লিঙ্ক আপনার ইমেলে পাঠানো হয়েছে! দয়া করে ইনবক্স চেক করুন।'
      : (code == 'hi'
          ? 'पासवर्ड रीसेट लिंक ईमेल पर भेजा गया है! कृपया इनबॉक्स जांचें।'
          : 'Password reset link sent to your email! Please check your inbox.');

  // ==================== NOTIFICATIONS & ACTIVITY HUB ====================
  String get notifHubTitle => code == 'bn' ? 'বিজ্ঞপ্তি ও অ্যাক্টিভিটি' : (code == 'hi' ? 'सूचनाएं व हब' : 'Notifications & Hub');
  String get notifTestTooltip => code == 'bn' ? 'টেস্ট নোটিফিকেশন পাঠান' : (code == 'hi' ? 'टेस्ट नोटिफिकेशन भेजें' : 'Test Live Notification');
  String get notifTestTriggered => code == 'bn' ? 'লকস্ক্রিন ও সিস্টেম নোটিফিকেশন টেস্ট পাঠানো হয়েছে!' : (code == 'hi' ? 'लाइव टेस्ट नोटिफिकेशन आपके फोन पर भेजा गया!' : 'Live test notification triggered on your phone!');
  String get notifAdherenceTitle => code == 'bn' ? 'আজকের ওষুধ নিয়মনিষ্ঠা' : (code == 'hi' ? 'आज की खुराक अनुपालन' : "Today's Dose Adherence");
  String notifDosesCompletedOf(int taken, int total) => code == 'bn'
      ? '$total টি ডোজের মধ্যে $taken টি সম্পূর্ণ'
      : (code == 'hi' ? '$total में से $taken खुराक पूरी हुईं' : '$taken of $total doses completed');
  String notifStreakDays(int days) => code == 'bn' ? 'ধারাবাহিকতা: $days দিন চালু' : (code == 'hi' ? 'क्रम: $days दिन सक्रिय' : '$days-Day Streak Active');
  String get notifFilterAll => code == 'bn' ? 'সকল' : (code == 'hi' ? 'सभी' : 'All');
  String get notifFilterAction => code == 'bn' ? 'অ্যাকশন চাই' : (code == 'hi' ? 'कार्रवाई आवश्यक' : 'Action Needed');
  String get notifFilterUpcoming => code == 'bn' ? 'আসন্ন' : (code == 'hi' ? 'आगामी' : 'Upcoming');
  String get notifFilterStock => code == 'bn' ? 'স্টক এলার্ট' : (code == 'hi' ? 'स्टॉक अलर्ट' : 'Stock Alert');
  String get notifFilterCompleted => code == 'bn' ? 'নেওয়া ওষুধ' : (code == 'hi' ? 'पूर्ण' : 'Completed');
  String get notifAllCaughtUpTitle => code == 'bn' ? 'কোন নতুন নোটিফিকেশন নেই' : (code == 'hi' ? 'सब कुछ अपडेट है!' : 'All Caught Up!');
  String get notifAllCaughtUpSub => code == 'bn' ? 'আপনার সব ওষুধের সময়সূচী ঠিকমতো চলছে।' : (code == 'hi' ? 'आपकी सभी दवाएं समय पर चल रही हैं।' : 'All scheduled medicines and stock alerts are up to date.');
  String get notifOverdueBadge => code == 'bn' ? 'বাকি রয়েছে' : (code == 'hi' ? 'अतिदेय' : 'OVERDUE');
  String get notifTakeNowBtn => code == 'bn' ? 'খেয়েছি' : (code == 'hi' ? 'दवा ली' : 'Take Now');
  String get notifSnooze10mBtn => code == 'bn' ? '১০ মি. পরে' : (code == 'hi' ? '১০ मि. बाद' : 'Snooze 10m');
  String get notifSnoozeSuccess => code == 'bn' ? '১০ মিনিটের জন্য রিমাইন্ডার স্থগিত করা হয়েছে!' : (code == 'hi' ? '১০ मिनट के लिए स्नूज़ किया गया!' : 'Snoozed for 10 minutes!');
  String notifDoseTakenSuccess(String medName) => code == 'bn' ? '$medName ডোজ সম্পূর্ণ হিসেবে রেকর্ড করা হয়েছে!' : (code == 'hi' ? '$medName खुराक पूरी दर्ज की गई!' : '$medName marked as taken!');
  String get notifLowStockWarning => code == 'bn' ? 'স্টক শেষ এলার্ট' : (code == 'hi' ? 'कम स्टॉक चेतावनी' : 'Low Stock Warning');
  String notifLowStockDosesLeft(int stock) => code == 'bn' ? 'মাত্র $stock টি ওষুধ অবশিষ্ট আছে।' : (code == 'hi' ? 'केवल $stock खुराक बची हैं। जल्द रीफिल करें।' : 'Only $stock doses left! Refill soon.');
  String get notifRefillBtn => code == 'bn' ? 'রিফিল' : (code == 'hi' ? 'रीफिल' : 'Refill');
  String get notifCompletedDose => code == 'bn' ? 'সম্পন্ন ডোজ' : (code == 'hi' ? 'पूर्ण खुराक' : 'Dose Completed');
  String get ok => code == 'bn' ? 'ঠিক আছে' : (code == 'hi' ? 'ठीक है' : 'OK');

  // Sorting & Filtering in Medicines
  String get sortBy => code == 'bn' ? 'সাজান' : (code == 'hi' ? 'क्रमबद्ध करें' : 'Sort by');
  String get sortAZ => code == 'bn' ? 'অক্ষর অনুযায়ী (A-Z)' : (code == 'hi' ? 'वर्णमाला (A-Z)' : 'Alphabetical (A-Z)');
  String get sortZA => code == 'bn' ? 'বিপরীত (Z-A)' : (code == 'hi' ? 'उलटा (Z-A)' : 'Alphabetical (Z-A)');
  String get sortNewest => code == 'bn' ? 'নতুন যোগ করা' : (code == 'hi' ? 'नवीनतम पहले' : 'Newest First');
  String get sortLowStock => code == 'bn' ? 'কম স্টক আগে' : (code == 'hi' ? 'कम स्टॉक पहले' : 'Low Stock First');
  String get filterByType => code == 'bn' ? 'ধরন' : (code == 'hi' ? 'प्रकार' : 'Type');
  String get allTypes => code == 'bn' ? 'সকল ধরন' : (code == 'hi' ? 'सभी प्रकार' : 'All Types');
  String get filterStock => code == 'bn' ? 'স্টক ফিল্টার' : (code == 'hi' ? 'स्टॉक फ़िल्टर' : 'Stock');
  String get lowStockOnly => code == 'bn' ? 'কম স্টক আছে' : (code == 'hi' ? 'केवल कम स्टॉक' : 'Low Stock Only');

  // Actions
  String get takeAction => code == 'bn' ? 'খেয়েছি' : (code == 'hi' ? 'ले लिया' : 'Take');
  String get snoozeAction => code == 'bn' ? 'পরে' : (code == 'hi' ? 'बाद में' : 'Snooze');
  String get skipAction => code == 'bn' ? 'বাদ' : (code == 'hi' ? 'छोड़ें' : 'Skip');

  // Onboarding Language Screen
  String get chooseLanguage => code == 'bn' ? 'আপনার ভাষা নির্বাচন করুন' : (code == 'hi' ? 'अपनी भाषा चुनें' : 'Choose Your Language');
  String get chooseLanguageSubtitle => code == 'bn'
      ? 'ওষুধের সঠিক রিমাইন্ডারের জন্য পছন্দের ভাষা বাছুন। পরবর্তীতে সেটিংসে পরিবর্তন করতে পারবেন।'
      : (code == 'hi'
          ? 'दवा रिमाइंडर के लिए अपनी पसंदीदा भाषा चुनें। इसे बाद में सेटिंग्स से बदला जा सकता है।'
          : 'Select your preferred language for medication reminders. You can change it anytime in Settings.');
  String get notifConfirmedTaken => code == 'bn' ? 'সফলভাবে নেওয়া হয়েছে' : (code == 'hi' ? 'सफलतापूर्वक ली गई' : 'Confirmed taken on time');
  String get continueBtn => code == 'bn' ? 'এগিয়ে যান' : (code == 'hi' ? 'आगे बढ़ें' : 'Continue');

  // Status Correction on Completed Doses
  String get changeStatusTitle => code == 'bn' ? 'স্ট্যাটাস পরিবর্তন করুন' : (code == 'hi' ? 'स्थिति बदलें' : 'Change Dose Status');
  String get changeStatusSub => code == 'bn'
      ? 'ভুলবশত ক্লিক হয়ে থাকলে নিচের অপশন থেকে পরিবর্তন করুন'
      : (code == 'hi' ? 'गलती से क्लिक हुआ हो तो नीचे से स्थिति बदलें' : 'Choose an alternate option to correct this dose');
  String get markAsSkippedOption => code == 'bn' ? 'স্কিপ (Skip) হিসেবে চিহ্নিত করুন' : (code == 'hi' ? 'छोड़ दिया (Skip) के रूप में बदलें' : 'Mark as Skipped');
  String get markAsTakenOption => code == 'bn' ? 'ওষুধ গ্রহণ করেছি (Taken) হিসেবে চিহ্নিত করুন' : (code == 'hi' ? 'दवा ले ली (Taken) के रूप में बदलें' : 'Mark as Taken');
  String get resetToPendingOption => code == 'bn' ? 'পেন্ডিং তালিকায় ফিরিয়ে নিন (Reset)' : (code == 'hi' ? 'वापस लंबित सूची में लाएं (Reset)' : 'Reset to Pending');
  String get confirmChangeTitle => code == 'bn' ? 'নিশ্চিত করুন' : (code == 'hi' ? 'पुष्टि करें' : 'Confirm Action');
  String confirmSkipMsg(String name) => code == 'bn'
      ? 'আপনি কি নিশ্চিত যে আপনি $name ওষুধটি Skip করতে চান?'
      : (code == 'hi' ? 'क्या आप वाकई $name दवा को छोड़ना (Skip) चाहते हैं?' : 'Are you sure you want to mark $name as Skipped?');
  String confirmTakeMsg(String name) => code == 'bn'
      ? 'আপনি কি নিশ্চিত যে আপনি $name ওষুধটি গ্রহণ করেছেন (Taken)?'
      : (code == 'hi' ? 'क्या आप वाकई $name दवा ले चुके हैं (Taken)?' : 'Are you sure you want to mark $name as Taken?');
  String confirmResetMsg(String name) => code == 'bn'
      ? 'আপনি কি নিশ্চিত যে $name আবার পেন্ডিং তালিকায় ফিরিয়ে নিতে চান?'
      : (code == 'hi' ? 'क्या आप वाकई $name को वापस पेंडिंग सूची में लाना चाहते हैं?' : 'Are you sure you want to reset $name to Pending?');
  String get statusUpdatedMsg => code == 'bn' ? 'স্ট্যাটাস সফলভাবে আপডেট করা হয়েছে' : (code == 'hi' ? 'स्थिति सफलतापूर्वक अपडेट की गई' : 'Status updated successfully');
  String get cancelBtn => code == 'bn' ? 'বাতিল' : (code == 'hi' ? 'रद्द करें' : 'Cancel');
  String get confirmBtn => code == 'bn' ? 'নিশ্চিত' : (code == 'hi' ? 'पुष्टि करें' : 'Confirm');
}


