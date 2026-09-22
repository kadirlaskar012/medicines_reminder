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
  String get afternoon => code == 'bn' ? 'বিকাল' : (code == 'hi' ? 'अपराह्न' : 'Afternoon');
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
      return '${weekdayFull(date.weekday)}, ${formatNumber(date.day)} ${monthName(date.month)}';
    }
    return '${weekdayFull(date.weekday)}, ${monthName(date.month)} ${date.day}';
  }

  String formatDayMonthWeekday(DateTime dt) {
    if (code == 'bn' || code == 'hi') {
      return '${weekdayFull(dt.weekday)}, ${formatNumber(dt.day)} ${monthName(dt.month)}';
    }
    return '${weekdayFull(dt.weekday)}, ${dt.day} ${monthName(dt.month)}';
  }

  String formatWeekRange(int weekNum, int startDay, int endDay, int month) {
    if (code == 'bn') {
      return 'সপ্তাহ ${formatNumber(weekNum)} (${formatNumber(startDay)}-${formatNumber(endDay)} ${monthName(month)})';
    } else if (code == 'hi') {
      return 'सप्ताह ${formatNumber(weekNum)} (${formatNumber(startDay)}-${formatNumber(endDay)} ${monthName(month)})';
    }
    return 'Week $weekNum ($startDay-$endDay ${monthName(month)})';
  }

  String formatMonthYear(int month, int year) {
    if (code == 'bn' || code == 'hi') {
      return '${monthName(month)} ${formatNumber(year)}';
    }
    return '${monthName(month)} $year';
  }

  String formatDayMonthYear(DateTime dt) {
    if (code == 'bn' || code == 'hi') {
      return '${formatNumber(dt.day)} ${monthName(dt.month)} ${formatNumber(dt.year)}';
    }
    return '${dt.day} ${monthName(dt.month)} ${dt.year}';
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
  String get missed => code == 'bn' ? 'ছুটে গেছে' : (code == 'hi' ? 'छूट गई' : 'Missed');
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
  String get tablet => code == 'bn' ? 'ট্যাবলেট' : (code == 'hi' ? 'टैबलेट' : 'Tablet');
  String get capsule => code == 'bn' ? 'ক্যাপসুল' : (code == 'hi' ? 'कैप्सूल' : 'Capsule');
  String get syrup => code == 'bn' ? 'সিরাপ' : (code == 'hi' ? 'सिरप' : 'Syrup');
  String get drops => code == 'bn' ? 'ড্রপস' : (code == 'hi' ? 'ड्रॉप्स' : 'Drops');
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
  String get archived => code == 'bn' ? 'আর্কাইভ' : (code == 'hi' ? 'पुरालेख' : 'Archived');
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
  String get scheduledAlarmsTitle => code == 'bn' ? 'ওষুধ খাওয়ার সময় ও অ্যালার্ম' : (code == 'hi' ? 'दवा लेने का समय और अलार्म' : 'Dose Timings & Alarms');
  String get editTiming => code == 'bn' ? 'সময় পরিবর্তন করুন' : (code == 'hi' ? 'समय बदलें' : 'Edit Time');
  String get updateTiming => code == 'bn' ? 'সময় আপডেট করুন' : (code == 'hi' ? 'समय अपडेट करें' : 'Update Time');
  String get addTiming => code == 'bn' ? 'নতুন সময় যোগ করুন' : (code == 'hi' ? 'नया समय जोड़ें' : 'Add Time');
  String get reminderUpdatedSuccess => code == 'bn' ? 'ওষুধের সময় সফলভাবে আপডেট হয়েছে' : (code == 'hi' ? 'दवा का समय सफलतापूर्वक अपडेट हो गया' : 'Reminder time updated successfully');
  String get reminderDeletedSuccess => code == 'bn' ? 'রিমাইন্ডারের সময় মুছে ফেলা হয়েছে' : (code == 'hi' ? 'रिमाइंडर का समय हटा दिया गया है' : 'Reminder time removed');
  String get confirmTimeChange => code == 'bn' ? 'সময় নিশ্চিত করুন' : (code == 'hi' ? 'समय की पुष्टि करें' : 'Confirm Time');
  String get tapToChangeTime => code == 'bn' ? 'সময় পরিবর্তন করতে ট্যাপ করুন' : (code == 'hi' ? 'समय बदलने के लिए टैप करें' : 'Tap to change time');
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
  String get languageOption => code == 'bn' ? 'ভাষা নির্বাচন' : (code == 'hi' ? 'भाषा चयन' : 'Language');
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
  String get cloudSyncFeature => code == 'bn' ? 'ক্লাউড ব্যাকআপ ও অফলাইন নিরাপত্তা' : (code == 'hi' ? 'क्लाउड बैकअप और ऑफ़लाइन सुरक्षा' : 'Cloud Sync & Offline Safe');
  String get getStarted => code == 'bn' ? 'শুরু করুন' : (code == 'hi' ? 'शुरू करें' : 'Get Started');

  // Alarm Ringing Screen
  String get timeForMedicine => code == 'bn' ? 'ওষুধ খাওয়ার সময় হয়েছে!' : (code == 'hi' ? 'दवा लेने का समय हो गया है!' : 'Time for your medicine!');
  String get medicineReminderTag => code == 'bn' ? 'মেডিসিন রিমাইন্ডার' : (code == 'hi' ? 'दवाई रिमाइंडर' : 'MEDICINE REMINDER');

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
  String get treatmentCourse => code == 'bn' ? 'চিকিৎসার মেয়াদ / কোর্স' : (code == 'hi' ? 'इलाज की अवधि / कोर्स' : 'Treatment Course');
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
  String get customEndDate => code == 'bn' ? 'কাস্টম শেষ তারিখ' : (code == 'hi' ? 'कस्टम अंतिम तिथि' : 'Custom End Date');
  String get courseCompleted => code == 'bn' ? 'কোর্স সম্পন্ন' : (code == 'hi' ? 'कोर्स पूरा हुआ' : 'Course Completed');
  String get courseEndsOn => code == 'bn' ? 'কোর্স শেষ হবে' : (code == 'hi' ? 'कोर्स समाप्त होगा' : 'Ends on');

  // Quick Frequency Shortcuts
  String get quickDoseFrequency => code == 'bn' ? '১-ক্লিক ফ্রিকোয়েন্সি শর্টকাট' : (code == 'hi' ? '१-क्लिक खुराक शॉर्टकट' : 'Quick Frequency Shortcuts');
  String get doseOnceDaily => code == 'bn' ? '১ বার (১+০+০)' : (code == 'hi' ? '१ बार (१+०+०)' : 'Once (1-0-0)');
  String get doseTwiceDaily => code == 'bn' ? '২ বার (১+০+১)' : (code == 'hi' ? '२ बार (१+०+१)' : 'Twice (1-0-1)');
  String get doseThriceDaily => code == 'bn' ? '৩ বার (১+১+১)' : (code == 'hi' ? '३ बार (१+१+१)' : '3 Times (1-1-1)');
  String get doseFourDaily => code == 'bn' ? '৪ বার (১+১+১+১)' : (code == 'hi' ? '४ बार (१+१+१+१)' : '4 Times');
  String get doseAsNeeded => code == 'bn' ? 'প্রয়োজনে' : (code == 'hi' ? 'ज़रूरत पड़ने पर' : 'As Needed');

  // Routine & Meal Presets
  String get routineMealSlot => code == 'bn' ? 'ওষুধ খাওয়ার সময় ও নিয়ম' : (code == 'hi' ? 'दवा लेने का समय और नियम' : 'Taking Time & Routine');
  String get morningSlot => code == 'bn' ? 'সকাল' : (code == 'hi' ? 'सुबह' : 'Morning');
  String get lunchSlot => code == 'bn' ? 'দুপুর' : (code == 'hi' ? 'दोपहर' : 'Lunch');
  String get afternoonSlot => code == 'bn' ? 'বিকাল' : (code == 'hi' ? 'दोपहर बाद' : 'Afternoon');
  String get eveningSlot => code == 'bn' ? 'সন্ধ্যা' : (code == 'hi' ? 'शाम' : 'Evening');
  String get nightSlot => code == 'bn' ? 'রাত্রি' : (code == 'hi' ? 'रात' : 'Night');

  String formatNumber(dynamic n) {
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
  String get expiryDateTitle => code == 'bn' ? 'ওষুধের মেয়াদোত্তীর্ণের তারিখ' : (code == 'hi' ? 'दवा की समाप्ति तिथि' : 'Medicine Expiry Date');
  String get noExpiryDate => code == 'bn' ? 'মেয়াদের কোনো তারিখ নেই' : (code == 'hi' ? 'कोई समाप्ति तिथि निर्धारित नहीं' : 'No expiry date set');
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
  String get notifFilterStockRefill => code == 'bn' ? 'স্টক ও রিফিল' : (code == 'hi' ? 'स्टॉक व रीफ़িল' : 'Stock & Refills');
  String get notifFilterDoses => code == 'bn' ? 'ওষুধ ডোজ' : (code == 'hi' ? 'दवा खुराक' : 'Doses');
  String get notifFilterMedicines => code == 'bn' ? 'ওষুধ তথ্য' : (code == 'hi' ? 'दवा जानकारी' : 'Medicines');
  String get notifFilterBoxTitle => code == 'bn' ? 'ফিল্টার নির্বাচন' : (code == 'hi' ? 'फ़िल्टर चुनें' : 'Filter Categories');
  String get notifFilterCompleted => code == 'bn' ? 'নেওয়া ওষুধ' : (code == 'hi' ? 'पूर्ण' : 'Completed');
  String get notifAllCaughtUpTitle => code == 'bn' ? 'কোন নোটিফিকেশন নেই' : (code == 'hi' ? 'कोई सूचना नहीं है' : 'No Notifications Yet');
  String get notifAllCaughtUpSub => code == 'bn' ? 'অ্যাপে ওষুধ যোগ, ডোজ গ্রহণ, রিফিল বা পরিবর্তনের সকল নোটিফিকেশন এখানে জমা হবে।' : (code == 'hi' ? 'ऐप में दवा जोड़ने, खुराक लेने, रीफिल या बदलाव की सभी सूचनाएं यहां दिखेंगी।' : 'All medicine activities, dose logs, and refill alerts will appear here.');
  String get notifOverdueBadge => code == 'bn' ? 'বাকি রয়েছে' : (code == 'hi' ? 'अतिदेय' : 'OVERDUE');
  String get notifTakeNowBtn => code == 'bn' ? 'খেয়েছি' : (code == 'hi' ? 'दवा ली' : 'Take Now');
  String get notifSnooze10mBtn => code == 'bn' ? '১০ মি. পরে' : (code == 'hi' ? '१० मि. बाद' : 'Snooze 10m');
  String get notifSnoozeSuccess => code == 'bn' ? '১০ মিনিটের জন্য রিমাইন্ডার স্থগিত করা হয়েছে!' : (code == 'hi' ? '१० मिनट के लिए स्नूज़ किया गया!' : 'Snoozed for 10 minutes!');
  String notifDoseTakenSuccess(String medName) => code == 'bn' ? '$medName ডোজ সম্পূর্ণ হিসেবে রেকর্ড করা হয়েছে!' : (code == 'hi' ? '$medName खुराक पूरी दर्ज की गई!' : '$medName marked as taken!');
  String get notifLowStockWarning => code == 'bn' ? 'স্টক শেষ এলার্ট' : (code == 'hi' ? 'कम स्टॉक चेतावनी' : 'Low Stock Warning');
  String notifLowStockDosesLeft(int stock) => code == 'bn' ? 'মাত্র $stock টি ওষুধ অবশিষ্ট আছে।' : (code == 'hi' ? 'केवल $stock खुराक बची हैं। जल्द रीफिल करें।' : 'Only $stock doses left! Refill soon.');
  String get notifRefillBtn => code == 'bn' ? 'রিফিল' : (code == 'hi' ? 'रीफिल' : 'Refill');
  String get notifCompletedDose => code == 'bn' ? 'সম্পন্ন ডোজ' : (code == 'hi' ? 'पूर्ण खुराक' : 'Dose Completed');
  String get notifClearAll => code == 'bn' ? 'সব মুছুন' : (code == 'hi' ? 'सभी साफ़ करें' : 'Clear All');
  String get notifClearAllConfirm => code == 'bn' ? 'আপনি কি সমস্ত নোটিফিকেশন ইতিহাস মুছে ফেলতে চান?' : (code == 'hi' ? 'क्या आप सभी सूचनाएं हटाना चाहते हैं?' : 'Are you sure you want to clear all notification history?');
  String get notifClearBtn => code == 'bn' ? 'মুছে ফেলুন' : (code == 'hi' ? 'हटाएं' : 'Clear');
  String get notifCancelBtn => code == 'bn' ? 'বাতিল' : (code == 'hi' ? 'रद्द करें' : 'Cancel');
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

  // Medicine Color Theme & Color Wheel
  String get colorWhite => code == 'bn' ? 'সাদা' : (code == 'hi' ? 'सफेद' : 'White');
  String get defaultColor => code == 'bn' ? 'ডিফল্ট' : (code == 'hi' ? 'डिफ़ॉल्ट' : 'Default');
  String get colorWheel => code == 'bn' ? 'কালার হুইল' : (code == 'hi' ? 'कलर व्हील' : 'Color Wheel');
  String get customColor => code == 'bn' ? 'কাস্টম কালার' : (code == 'hi' ? 'कस्टम रंग' : 'Custom Color');
  String get pickAnyColor => code == 'bn' ? 'পছন্দের যেকোনো রঙ বেছে নিন' : (code == 'hi' ? 'अपनी पसंद का कोई भी रंग चुनें' : 'Pick any color');
  String get tapToChange => code == 'bn' ? 'পরিবর্তন করতে চাপুন' : (code == 'hi' ? 'बदलने के लिए टैप करें' : 'Tap to change');
  String get selectColor => code == 'bn' ? 'কালার নির্বাচন করুন' : (code == 'hi' ? 'रंग चुनें' : 'Select Color');
  String get applyColor => code == 'bn' ? 'বাছাই করুন' : (code == 'hi' ? 'लागू करें' : 'Apply Color');
  String get brightness => code == 'bn' ? 'উজ্জ্বলতা' : (code == 'hi' ? 'चमक' : 'Brightness');
  String get popularColors => code == 'bn' ? 'জনপ্রিয় কালারসমূহ' : (code == 'hi' ? 'लोकप्रिय रंग' : 'Popular Colors');

  // Export Data & Reports PDF
  String get exportReportTitle => code == 'bn' ? 'মেডিকেল রিপোর্ট এক্সপোর্ট (PDF)' : (code == 'hi' ? 'मेडिकल रिपोर्ट निर्यात (PDF)' : 'Export Medical Report (PDF)');
  String get exportReportSub => code == 'bn'
      ? 'তারিখ ও ওষুধ ফিল্টার করে ডাক্তার বা নিজের ব্যবহারের জন্য সুন্দর ও প্রামাণ্য PDF রিপোর্ট তৈরি করুন।'
      : (code == 'hi'
          ? 'तारीख व दवाएं फिल्टर करके डॉक्टर या अपने रिकॉर्ड के लिए सुंदर PDF रिपोर्ट तैयार करें।'
          : 'Filter by date & medicines to generate a verified, clinical-grade adherence PDF report.');
  String get exportOptionsTitle => code == 'bn' ? 'রিপোর্ট ফিল্টার ও কাস্টমাইজেশন' : (code == 'hi' ? 'रिपोर्ट फिल्टर व कस्टमाइज़ेशन' : 'Report Filters & Customization');
  String get dateRangeFilter => code == 'bn' ? 'তারিখের পরিসর' : (code == 'hi' ? 'तारीख सीमा' : 'Date Range');
  String get medicineFilterTitle => code == 'bn' ? 'ওষুধ নির্বাচন' : (code == 'hi' ? 'दवा चयन' : 'Select Medicines');
  String get selectAllMeds => code == 'bn' ? 'সকল ওষুধ' : (code == 'hi' ? 'सभी दवाएं' : 'All Medicines');
  String get selectedMedsSummary => code == 'bn' ? 'টি ওষুধ নির্বাচিত' : (code == 'hi' ? 'दवाएं चयनित' : 'medicines selected');
  String get includeSections => code == 'bn' ? 'রিপোর্টে কী কী তথ্য থাকবে?' : (code == 'hi' ? 'रिपोर्ट में कौन-सी जानकारी शामिल करें?' : 'Include in Report:');
  String get secAdherenceStats => code == 'bn' ? 'অনুপালন পরিসংখ্যান ও স্কোর' : (code == 'hi' ? 'अनुपालन आंकड़े व स्कोर' : 'Adherence Statistics & KPI');
  String get secPrescriptions => code == 'bn' ? 'প্রেসক্রিপশন ও ওষুধের বিবরণ' : (code == 'hi' ? 'पर्चे की दवाएं व विवरण' : 'Prescription & Dosage Details');
  String get secIntakeLog => code == 'bn' ? 'দৈনিক সেবন ইতিহাস লগ' : (code == 'hi' ? 'दैनिक दवा सेवन लॉग' : 'Daily Dose Intake Log');
  String get secDoctorNotes => code == 'bn' ? 'ডাক্তারের পরামর্শ ও নোটস বক্স' : (code == 'hi' ? 'डॉक्टर परामर्श व नोट्स बॉक्स' : 'Doctor Notes & Signature Box');
  String get generateAndSharePdf => code == 'bn' ? 'PDF তৈরি ও শেয়ার করুন' : (code == 'hi' ? 'PDF बनाएं व साझा करें' : 'Generate & Share PDF');
  String get generatingPdfPrompt => code == 'bn' ? 'PDF তৈরি হচ্ছে, অনুগ্রহ করে অপেক্ষা করুন...' : (code == 'hi' ? 'PDF तैयार हो रहा है, कृपया प्रतीक्षा करें...' : 'Generating PDF, please wait...');
  String get exportReportCardBtn => code == 'bn' ? 'রিপোর্ট ডাউনলোড / প্রিন্ট' : (code == 'hi' ? 'रिपोर्ट डाउनलोड / प्रिंट' : 'Download / Print Report');
  String get customDateRangePrompt => code == 'bn' ? 'কাস্টম তারিখ বেছে নিন' : (code == 'hi' ? 'कस्टम तारीख चुनें' : 'Custom Date Range');
  String get noMedsSelectedWarning => code == 'bn' ? 'অনুগ্রহ করে অন্তত একটি ওষুধ নির্বাচন করুন' : (code == 'hi' ? 'कृपया कम से कम एक दवा चुनें' : 'Please select at least one medicine');

  // ==================== TIME SLOTS & TIMINGS ====================
  String get morningShort => code == 'bn' ? 'সকাল' : (code == 'hi' ? 'सुबह' : 'Morn');
  String get lunchShort => code == 'bn' ? 'দুপুর' : (code == 'hi' ? 'दोपहर' : 'Lunch');
  String get afternoonShort => code == 'bn' ? 'বিকাল' : (code == 'hi' ? 'दोपहर बाद' : 'Aft');
  String get eveningShort => code == 'bn' ? 'সন্ধ্যা' : (code == 'hi' ? 'शाम' : 'Eve');
  String get nightShort => code == 'bn' ? 'রাত' : (code == 'hi' ? 'रात' : 'Night');
  String timeSlotScheduled(String slot, String time) => code == 'bn'
      ? '$slot · নির্ধারিত সময় $time'
      : (code == 'hi' ? '$slot · निर्धारित समय $time' : '$slot · Scheduled at $time');

  // ==================== TODAY & REMINDERS ====================
  String get todayDoses => code == 'bn' ? 'আজকের ওষুধ' : (code == 'hi' ? 'आज की दवाएं' : "Today's Doses");
  String get upcomingMedicines => code == 'bn' ? 'আসন্ন ওষুধ' : (code == 'hi' ? 'आगामी दवाएं' : 'Upcoming Medicines');
  String get completedToday => code == 'bn' ? 'আজকের সম্পন্ন' : (code == 'hi' ? 'आज पूर्ण' : 'Completed Today');
  String get backToToday => code == 'bn' ? 'আজকে ফিরুন' : (code == 'hi' ? 'आज पर जाएं' : 'Back to Today');
  String get reportsTab => code == 'bn' ? 'রিপোর্ট' : (code == 'hi' ? 'रिपोर्ट्स' : 'Reports');
  String get holdToCorrectStatus => code == 'bn'
      ? 'হোল্ড প্রেস করে স্ট্যাটাস পরিবর্তন করুন'
      : (code == 'hi' ? 'दबाकर स्थिति बदलें' : 'Hold to change status');
  String get markSkippedPrompt => code == 'bn'
      ? 'ওষুধ খাওয়া হয়নি, বাদ (Skip) হিসেবে চিহ্নিত করুন'
      : (code == 'hi' ? 'दवा नहीं ली गई, छोड़ दी (Skip) के रूप में चिह्नित करें' : 'Dose not taken, mark as skipped');
  String get markTakenPrompt => code == 'bn'
      ? 'ওষুধ নেওয়া সম্পন্ন (Taken) হিসেবে চিহ্নিত করুন'
      : (code == 'hi' ? 'दवा ले ली गई, पूर्ण (Taken) के रूप में चिह्नित करें' : 'Dose taken, mark as completed');
  String get resetPendingPrompt => code == 'bn'
      ? 'স্ট্যাটাস পরিবর্তন করে আবার অপেক্ষারত (Pending) করুন'
      : (code == 'hi' ? 'स्थिति को फिर से लंबित (Pending) करें' : 'Reset back to pending');
  String get skippedDosesFilter => code == 'bn' ? 'ছুটে যাওয়া' : (code == 'hi' ? 'छूटी हुई' : 'Missed / Skipped');
  String get upcomingStatus => code == 'bn' ? 'আসন্ন' : (code == 'hi' ? 'आगामी' : 'Upcoming');
  String get doneLegend => code == 'bn' ? 'সম্পন্ন' : (code == 'hi' ? 'पूर्ण' : 'Done');
  String get pendingLegend => code == 'bn' ? 'বাকি' : (code == 'hi' ? 'लंबित' : 'Pending');
  String get missedLegend => code == 'bn' ? 'ছুটে যাওয়া' : (code == 'hi' ? 'छूटी हुई' : 'Missed');
  String get scheduledTimePrefix => code == 'bn' ? 'নির্ধারিত সময়' : (code == 'hi' ? 'निर्धारित समय' : 'Scheduled at');
  String get nextMedicinesBelowNotice => code == 'bn' ? 'নিচের পরবর্তী ওষুধগুলো দেখুন' : (code == 'hi' ? 'नीचे अगली दवाएं देखें' : 'See next medicines below');
  String get dueNow => code == 'bn' ? 'বাকি আছে' : (code == 'hi' ? 'देरी' : 'Due Now');

  String slotMedicinesHeading(String slot) => code == 'bn' ? '$slot এর ওষুধ' : (code == 'hi' ? '$slot की दवाएं' : '$slot Medicines');
  String dateMedicinesHeading(dynamic date, [String? month]) {
    final dStr = formatNumber(date);
    if (month != null) {
      if (code == 'bn') return '$dStr $month এর ওষুধ';
      if (code == 'hi') return '$dStr $month की दवाएं';
      return '$month $dStr Medicines';
    }
    if (code == 'bn') return '$dStr এর ওষুধ';
    if (code == 'hi') return '$dStr की दवाएं';
    return '$date Medicines';
  }
  String noMedicinesForSlot(String slot) => code == 'bn'
      ? '$slot এর কোনো ওষুধ নেই'
      : (code == 'hi' ? '$slot के लिए कोई दवा नहीं' : 'No medicines scheduled for $slot');
  String get noMedicinesForTimeRange => code == 'bn'
      ? 'এই সময়ে কোনো ওষুধ নেই'
      : (code == 'hi' ? 'इस समय कोई दवा नहीं' : 'No medicines in this time range');
  String noMedicinesForTimeSlot(String range) => code == 'bn'
      ? '$range এ কোনো ওষুধ নেই'
      : (code == 'hi' ? '$range में कोई दवा नहीं' : 'No medicines in $range');
  String dosesRemainingCount(int count) {
    final numStr = formatNumber(count);
    if (code == 'bn') return '$numStrটি বাকি';
    if (code == 'hi') return '$numStr खुराक शेष';
    return '$count doses remaining';
  }
  String dosesDueCount(int count) {
    final numStr = formatNumber(count);
    if (code == 'bn') return '$numStrটি নেওয়া বাকি';
    if (code == 'hi') return '$numStr देय खुराक';
    return '$count due';
  }
  String medicinesCount(int count) {
    final numStr = formatNumber(count);
    if (code == 'bn') return '$numStrটি ওষুধ';
    if (code == 'hi') return '$numStr दवाएं';
    return '$count Medicines';
  }
  String medsCountShort(int count) {
    final numStr = formatNumber(count);
    if (code == 'bn') return '$numStrটি';
    if (code == 'hi') return '$numStr दवाएं';
    return '$count meds';
  }

  // ==================== NOTIFICATIONS & ALARMS ====================
  String get notifActionMarkTaken => code == 'bn' ? 'গ্রহণ করুন' : (code == 'hi' ? 'दवा लें' : 'Take');
  String get notifActionSnooze10m => code == 'bn' ? '১০ মিনিট পর' : (code == 'hi' ? '10 मिनट बाद' : 'Snooze 10m');
  String get notifActionSkip => code == 'bn' ? 'বাদ দিন' : (code == 'hi' ? 'छोड़ें' : 'Skip');
  String get notifActionDismiss => code == 'bn' ? 'বাতিল' : (code == 'hi' ? 'खारिज करें' : 'Dismiss');
  String get doseReminderTitle => code == 'bn' ? 'ওষুধের সময় হয়েছে!' : (code == 'hi' ? 'दवा का समय हो गया!' : 'Medicine Reminder!');
  String get timeToTake => code == 'bn' ? 'ওষুধ খাওয়ার সময় হয়েছে' : (code == 'hi' ? 'दवा लेने का समय' : 'Time to take');
  String get pleaseTakeMedicineOnTime => code == 'bn' ? 'দয়া করে সময়মতো ওষুধ গ্রহণ করুন।' : (code == 'hi' ? 'कृपया समय पर अपनी दवा लें।' : 'Please take your medicine on time.');
  String notifDoseBigText({
    required String medicineName,
    required String dosage,
    required String instruction,
    required String timeStr,
  }) {
    final d = dosage.isNotEmpty ? ' • $dosage' : '';
    if (code == 'bn') {
      return '<b><big>$medicineName</big></b>$d<br>⏰ <b>$timeStr</b> • 🍽️ <b>$instruction</b><br><br><i><font color="#0D9488">✨ "$notifCursiveNote"</font></i>';
    } else if (code == 'hi') {
      return '<b><big>$medicineName</big></b>$d<br>⏰ <b>$timeStr</b> • 🍽️ <b>$instruction</b><br><br><i><font color="#0D9488">✨ "$notifCursiveNote"</font></i>';
    }
    return '<b><big>$medicineName</big></b>$d<br>⏰ <b>$timeStr</b> • 🍽️ <b>$instruction</b><br><br><i><font color="#0D9488">✨ "$notifCursiveNote"</font></i>';
  }
  String notifTimeForMed(String name, [String? dosage]) {
    final d = (dosage != null && dosage.isNotEmpty) ? ' ($dosage)' : '';
    if (code == 'bn') return '$name$d খাওয়ার সময় হয়েছে';
    if (code == 'hi') return '$name$d लेने का समय हो गया है';
    return 'Time to take $name$d';
  }
  String notifTakeBody(String nameOrInstruction, [String? timeOrDosage, String? extra]) {
    if (extra != null && extra.isNotEmpty) {
      if (code == 'bn') return '$nameOrInstruction • নির্ধারিত সময় $timeOrDosage ($extra)';
      if (code == 'hi') return '$nameOrInstruction • समय $timeOrDosage ($extra)';
      return '$nameOrInstruction • Time $timeOrDosage ($extra)';
    }
    final d = (timeOrDosage != null && timeOrDosage.isNotEmpty) ? ' ($timeOrDosage)' : '';
    if (code == 'bn') return '$nameOrInstruction$d খাওয়ার সময় হয়েছে।';
    if (code == 'hi') return '$nameOrInstruction$d लेने का समय हो गया है।';
    return 'Time to take $nameOrInstruction$d.';
  }
  String notifTakeBigText(String name, String dosage, [String? timeSlot]) {
    final slot = (timeSlot != null && timeSlot.isNotEmpty) ? ' • $timeSlot' : '';
    if (code == 'bn') return '$name ($dosage)$slot\nদয়া করে সময়মতো ওষুধ গ্রহণ করুন।';
    if (code == 'hi') return '$name ($dosage)$slot\nकृपया समय पर अपनी दवा लें।';
    return '$name ($dosage)$slot\nPlease take your medicine on time.';
  }
  String notifSnoozedTitle(String name, [String? dosage]) => code == 'bn' ? '$name (স্নুজ করা হয়েছে)' : (code == 'hi' ? '$name (स्नूज़ किया गया)' : '$name (Snoozed)');
  String notifSnoozedBody(String name, [dynamic dosageOrMinutes = 10, dynamic minutes = 10]) {
    final m = (dosageOrMinutes is int) ? dosageOrMinutes : (minutes is int ? minutes : 10);
    final mStr = formatNumber(m);
    if (code == 'bn') return '$name খাওয়ার জন্য $mStr মিনিট পর পুনরায় রিমাইন্ডার দেওয়া হবে।';
    if (code == 'hi') return '$name के लिए $mStr मिनट बाद पुनः रिमाइंडर मिलेगा।';
    return 'Reminder for $name snoozed for $m minutes.';
  }
  String notifLowStockTitle(String name, [dynamic stock]) => code == 'bn' ? 'স্টক সতর্কতা: $name' : (code == 'hi' ? 'स्टॉक अलर्ट: $name' : 'Low Stock Alert: $name');
  String notifLowStockBody(dynamic nameOrStock, [dynamic stockOrUnit]) {
    if (stockOrUnit != null) {
      final sStr = formatNumber(stockOrUnit);
      if (code == 'bn') return '$nameOrStock এর মাত্র $sStrটি ওষুধ বাকি আছে। শীঘ্রই সংগ্রহ করুন!';
      if (code == 'hi') return '$nameOrStock की केवल $sStr दवाएं बची हैं। जल्द रीफिल करें!';
      return 'Only $stockOrUnit units left for $nameOrStock. Please refill soon!';
    } else {
      final sStr = formatNumber(nameOrStock);
      if (code == 'bn') return 'মাত্র $sStrটি ওষুধ বাকি আছে। শীঘ্রই সংগ্রহ করুন!';
      if (code == 'hi') return 'केवल $sStr दवाएं बची हैं। जल्द रीफिल करें!';
      return 'Only $nameOrStock units left! Please refill soon!';
    }
  }
  String get notifTestTitle => code == 'bn' ? 'টেস্ট নোটিফিকেশন' : (code == 'hi' ? 'परीक्षण सूचना' : 'Test Notification');
  String get notifTestBody => code == 'bn'
      ? 'MediRemind অ্যালার্ম ও নোটিফিকেশন সিস্টেম সঠিকভাবে কাজ করছে।'
      : (code == 'hi' ? 'MediRemind अलार्म और सूचना प्रणाली ठीक से काम कर रही है।' : 'MediRemind reminder notifications are working perfectly.');
  String get notifPartnerTagline => code == 'bn' ? 'আপনার সুস্থতার সঙ্গী' : (code == 'hi' ? 'आपका स्वास्थ्य साथी' : 'Your Health Partner');
  String get notifMotivationPrompt => code == 'bn' ? 'সুস্থ থাকতে অনুগ্রহ করে সঠিক সময়ে ওষুধ গ্রহণ করুন।' : (code == 'hi' ? 'स्वस्थ रहने के लिए कृपया समय पर दवा लें।' : 'Please take your medicine on time for a healthier you.');
  String get notifCursiveNote => code == 'bn' ? 'সুস্থ আগামীর জন্য ছোট্ট একটি ধাপ' : (code == 'hi' ? 'एक स्वस्थ कल के लिए छोटा सा कदम' : 'Small step for a healthier tomorrow');
  String formatNotifTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) {
      return code == 'bn' ? 'এখনই' : (code == 'hi' ? 'अभी' : 'Just now');
    } else if (diff.inMinutes < 60) {
      final m = formatNumber(diff.inMinutes);
      return code == 'bn' ? '$m মিনিট আগে' : (code == 'hi' ? '$m मिनट पहले' : '${diff.inMinutes}m ago');
    } else if (diff.inHours < 24) {
      final h = formatNumber(diff.inHours);
      return code == 'bn' ? '$h ঘণ্টা আগে' : (code == 'hi' ? '$h घंटे पहले' : '${diff.inHours}h ago');
    } else {
      final d = formatNumber(diff.inDays);
      return code == 'bn' ? '$d দিন আগে' : (code == 'hi' ? '$d दिन पहले' : '${diff.inDays}d ago');
    }
  }

  String notifDoseTakenTitle(String name) => code == 'bn' ? '$name ওষুধ গ্রহণ সম্পন্ন' : (code == 'hi' ? '$name खुराक पूरी' : '$name Dose Taken');
  String notifDoseTakenMsg(dynamic dosage, [dynamic time]) {
    final tStr = time != null ? (code == 'bn' ? ' • সময়: $time' : (code == 'hi' ? ' • समय: $time' : ' • Time: $time')) : '';
    if (code == 'bn') return 'ডোজ: $dosage$tStr (ওষুধ সেবন সম্পন্ন)';
    if (code == 'hi') return 'खुराक: $dosage$tStr (दवा ली गई)';
    return 'Dose: $dosage$tStr (Completed)';
  }

  String notifDoseSkippedTitle(String name) => code == 'bn' ? '$name বাদ দেওয়া হয়েছে' : (code == 'hi' ? '$name छोड़ी गई' : '$name Dose Skipped');
  String notifDoseSkippedMsg(dynamic dosage, [dynamic time]) {
    final tStr = time != null ? (code == 'bn' ? ' • সময়: $time' : (code == 'hi' ? ' • समय: $time' : ' • Time: $time')) : '';
    if (code == 'bn') return 'ডোজ: $dosage$tStr (বাদ দেওয়া হয়েছে)';
    if (code == 'hi') return 'खुराक: $dosage$tStr (छोड़ दी गई)';
    return 'Dose: $dosage$tStr (Skipped)';
  }

  String notifDoseMissedTitle(String name) => code == 'bn' ? '$name এর ডোজ মিস হয়েছে' : (code == 'hi' ? '$name खुराक छूट गई' : '$name Dose Missed');
  String notifDoseMissedMsg(dynamic dosage, [dynamic time]) {
    final tStr = time != null ? (code == 'bn' ? ' • নির্ধারিত সময়: $time' : (code == 'hi' ? ' • निर्धारित समय: $time' : ' • Scheduled: $time')) : '';
    if (code == 'bn') return 'ডোজ: $dosage$tStr (নেওয়া হয়নি)';
    if (code == 'hi') return 'खुराक: $dosage$tStr (छूट गई)';
    return 'Dose: $dosage$tStr (Missed)';
  }

  String notifDoseSnoozedTitle(String name) => code == 'bn' ? '$name স্থগিত করা হয়েছে' : (code == 'hi' ? '$name स्थगित' : '$name Snoozed');
  String notifDoseSnoozedMsg(dynamic minutes, [dynamic time]) {
    final mStr = formatNumber(minutes);
    if (code == 'bn') return '$mStr মিনিটের জন্য রিমাইন্ডার স্থগিত করা হয়েছে';
    if (code == 'hi') return '$mStr मिनट के लिए रिमाइंडर स्थगित किया गया';
    return 'Reminder snoozed for $minutes minutes';
  }

  String notifMedAddedTitle(String name) => code == 'bn' ? 'নতুন ওষুধ যোগ: $name' : (code == 'hi' ? 'नई दवा जोड़ी गई: $name' : 'New Medicine Added: $name');
  String notifMedAddedMsg(dynamic dosage, [dynamic stock, dynamic instruction]) {
    final sStr = stock != null ? (code == 'bn' ? ' • মজুদ: ${formatNumber(stock)}' : (code == 'hi' ? ' • स्टॉक: ${formatNumber(stock)}' : ' • Stock: ${formatNumber(stock)}')) : '';
    final iStr = instruction != null && instruction.toString().isNotEmpty ? ' • $instruction' : '';
    if (code == 'bn') return 'ডোজ: $dosage$sStr$iStr';
    if (code == 'hi') return 'खुराक: $dosage$sStr$iStr';
    return 'Dose: $dosage$sStr$iStr';
  }

  String notifMedUpdatedTitle(String name) => code == 'bn' ? 'ওষুধের তথ্য আপডেট: $name' : (code == 'hi' ? 'दवा अपडेट: $name' : 'Medicine Updated: $name');
  String notifMedUpdatedMsg(dynamic dosage, [dynamic stock, dynamic unit]) {
    final sVal = stock != null ? '${formatNumber(stock)} ${unit ?? ""}'.trim() : '';
    final sStr = sVal.isNotEmpty ? (code == 'bn' ? ' • মজুদ: $sVal' : (code == 'hi' ? ' • स्टॉक: $sVal' : ' • Stock: $sVal')) : '';
    if (code == 'bn') return 'ডোজ: $dosage$sStr';
    if (code == 'hi') return 'खुराक: $dosage$sStr';
    return 'Dose: $dosage$sStr';
  }

  String notifRefillTitle(String name) => code == 'bn' ? 'স্টক রিফিল সম্পন্ন: $name' : (code == 'hi' ? 'स्टॉक रीफिल: $name' : 'Stock Refilled: $name');
  String notifRefillAddedTitle(String name) => notifRefillTitle(name);
  String notifRefillMsg(dynamic added, [dynamic stock, dynamic unit]) {
    final aStr = formatNumber(added);
    final sVal = stock != null ? '${formatNumber(stock)} ${unit ?? ""}'.trim() : '';
    final sStr = sVal.isNotEmpty ? (code == 'bn' ? ' (মোট মজুদ: $sVal)' : (code == 'hi' ? ' (कुल स्टॉक: $sVal)' : ' (Total stock: $sVal)')) : '';
    if (code == 'bn') return '$aStrটি যোগ করা হয়েছে$sStr';
    if (code == 'hi') return '$aStr दवाएं जोड़ी गईं$sStr';
    return '$added units added$sStr';
  }

  // ==================== MISSED SHEET & HISTORY ====================
  String get missedMedicinesSheetTitle => code == 'bn' ? 'ছুটে যাওয়া ওষুধ' : (code == 'hi' ? 'छूटी हुई दवाएं' : 'Missed Medicines');
  String get allCaughtUpTitle => code == 'bn' ? 'কোনো ওষুধ বাকি নেই 🎉' : (code == 'hi' ? 'सब कुछ पूरा है 🎉' : 'All caught up! 🎉');
  String missedDosesSubtitle(int count) {
    final numStr = formatNumber(count);
    if (code == 'bn') return '$numStrটি ওষুধের ডোজ গ্রহণ করা হয়নি';
    if (code == 'hi') return '$numStr दवाओं की खुराक छूट गई';
    return '$count missed dose(s) pending';
  }
  String get allMissedClearedTitle => code == 'bn' ? 'সব মিসড ওষুধ ক্লিয়ার হয়েছে!' : (code == 'hi' ? 'सभी छूटी दवाएं साफ़ हो गईं!' : 'All Missed Doses Cleared!');
  String get allMissedClearedSubtitle => code == 'bn'
      ? 'আপনার আর কোনো ছুটে যাওয়া ওষুধ বাকি নেই।'
      : (code == 'hi' ? 'आपकी कोई छूटी हुई दवा लंबित नहीं है।' : 'You have no unresolved missed medicines.');
  String get gotIt => code == 'bn' ? 'ঠিক আছে' : (code == 'hi' ? 'समझ गया' : 'Got it');
  String get takeLate => code == 'bn' ? 'দেরিতে খেয়েছি' : (code == 'hi' ? 'देर से ली' : 'Take Late');
  String get todayMissedLabel => code == 'bn' ? 'আজকের' : (code == 'hi' ? 'आज' : 'Today');
  String yesterdayMissedLabel(String date) => code == 'bn' ? 'গতকাল ($date)' : (code == 'hi' ? 'कल ($date)' : 'Yesterday ($date)');
  String get filterByDateTooltip => code == 'bn' ? 'তারিখ দিয়ে ফিল্টার করুন' : (code == 'hi' ? 'तारीख से फ़िल्टर करें' : 'Filter by Date');
  String get showingHistoryForDateOnly => code == 'bn'
      ? 'তারিখের ওষুধের ইতিহাস দেখানো হচ্ছে'
      : (code == 'hi' ? 'दवा का इतिहास दिखाया जा रहा है' : 'Showing logs for selected date only');
  String showingHistoryForDate(String date) => code == 'bn'
      ? '$date তারিখের ওষুধের ইতিহাস দেখানো হচ্ছে'
      : (code == 'hi' ? '$date की दवा का इतिहास दिखाया जा रहा है' : 'Showing logs for $date only');
  String get clearFilterTooltip => code == 'bn' ? 'ফিল্টার মুছুন' : (code == 'hi' ? 'फ़िल्टर हटाएं' : 'Clear filter');
  String get noHistoryForThisDate => code == 'bn' ? 'এই তারিখে কোনো ইতিহাস নেই' : (code == 'hi' ? 'इस तारीख का कोई इतिहास नहीं' : 'No dose records for this date');
  String get historyDateToday => code == 'bn' ? 'আজ' : (code == 'hi' ? 'आज' : 'Today');
  String get historyDateYesterday => code == 'bn' ? 'গতকাল' : (code == 'hi' ? 'कल' : 'Yesterday');

  // ==================== SETTINGS & BACKUP ====================
  String get appearanceAndThemeHeader => code == 'bn' ? 'অ্যাপের থিম ও মোড' : (code == 'hi' ? 'ऐप थीम और स्वरूप' : 'APPEARANCE & THEME');
  String get backupAndRestoreHeader => code == 'bn' ? 'ডাটা ব্যাকআপ ও রিস্টোর' : (code == 'hi' ? 'डेटा बैकअप व रीस्टोर' : 'LOCAL BACKUP & RESTORE');
  String get appearanceThemeTitle => code == 'bn' ? 'অ্যাপের থিম ও মোড' : (code == 'hi' ? 'ऐप थीम और स्वरूप' : 'App Theme & Appearance');
  String get appearanceThemeSub => code == 'bn'
      ? 'ক্রিস্টাল লাইট বা অবসিডিয়ান ডার্ক মোড বেছে নিন।'
      : (code == 'hi' ? 'क्रिस्टल लाइट या ऑब्सीडियन डार्क मोड चुनें।' : 'Choose between Crystal Light or Obsidian Dark mode.');
  String get deviceLocalBackupTitle => code == 'bn' ? 'ডিভাইস লোকাল ব্যাকআপ' : (code == 'hi' ? 'डिवाइस लोकल बैकअप' : 'Device Local Backup');
  String get deviceLocalBackupSub => code == 'bn'
      ? '১০০% অফলাইন ও সুরক্ষিত। সম্পূর্ণ ডাটা আপনার ফোনে সেভ থাকবে।'
      : (code == 'hi' ? '100% ऑफलाइन और सुरक्षित। पूरा डेटा आपके फोन में रहेगा।' : '100% offline & secure. Complete data stays safely on your phone.');
  String latestBackupDate(String formatted) => code == 'bn' ? 'সর্বশেষ ব্যাকআপ: $formatted' : (code == 'hi' ? 'अंतिम बैकअप: $formatted' : 'Last backup: $formatted');
  String get noBackupFound => code == 'bn' ? 'কোনো ব্যাকআপ ফাইল সেভ করা নেই' : (code == 'hi' ? 'कोई बैकअप फ़ाइल सुरक्षित नहीं है' : 'No local backup found yet');
  String get exportBackupBtn => code == 'bn' ? 'ব্যাকআপ এক্সপোর্ট' : (code == 'hi' ? 'बैकअप निर्यात' : 'Export Backup');
  String get restoreBackupBtn => code == 'bn' ? 'ব্যাকআপ রিস্টোর' : (code == 'hi' ? 'बैकअप रीस्टोर' : 'Restore Backup');
  String get restoreBackupConfirmTitle => code == 'bn' ? 'ব্যাকআপ রিস্টোর করবেন?' : (code == 'hi' ? 'बैकअप रीस्टोर करें?' : 'Restore Backup?');
  String get restoreBackupConfirmDesc => code == 'bn'
      ? 'ডিভাইসের ফাইল স্টোরেজ থেকে আপনার MediRemind JSON ব্যাকআপ ফাইল নির্বাচন করুন। আপনার ওষুধ, প্রোফাইল এবং শিডিউল রিস্টোর হবে।'
      : (code == 'hi'
          ? 'स्टोरेज से अपनी MediRemind JSON बैकअप फ़ाइल चुनें। आपकी दवाएं, प्रोफाइल और शेड्यूल रीस्टोर हो जाएंगे।'
          : 'Select your MediRemind JSON backup file from device storage. Your medicines, profiles, and schedules will be restored.');
  String get selectFileBtn => code == 'bn' ? 'ফাইল সিলেক্ট করুন' : (code == 'hi' ? 'फ़ाइल चुनें' : 'Select File');

  // ==================== REPORTS & ANALYTICS ====================
  String get adherenceReportTitle => code == 'bn' ? 'মেডিসিন অনুপালন রিপোর্ট' : (code == 'hi' ? 'दवा अनुपालन रिपोर्ट' : 'Medication Adherence');
  String get weeklyPeriod => code == 'bn' ? 'সাপ্তাহিক' : (code == 'hi' ? 'साप्ताहिक' : 'Weekly');
  String get monthlyPeriod => code == 'bn' ? 'মাসিক' : (code == 'hi' ? 'मासिक' : 'Monthly');
  String get yearlyPeriod => code == 'bn' ? 'বার্ষিক' : (code == 'hi' ? 'वार्षिक' : 'Yearly');
  String get adherenceRateLabel => code == 'bn' ? 'অনুপালনের হার' : (code == 'hi' ? 'अनुपालन दर' : 'Adherence Rate');
  String get inProgressLabel => code == 'bn' ? 'চলমান' : (code == 'hi' ? 'प्रगति में' : 'In Progress');
  String get pendingCompletionLabel => code == 'bn' ? 'দিন শেষে যুক্ত হবে' : (code == 'hi' ? 'दिन के अंत में जुड़ेगा' : 'Pending completion');
  String get noDosesLabel => code == 'bn' ? 'কোনো ওষুধ নেই' : (code == 'hi' ? 'कोई खुराक नहीं' : 'No Doses');
  String get forPeriodLabel => code == 'bn' ? 'এই সময়ের জন্য' : (code == 'hi' ? 'इस अवधि के लिए' : 'For period');
  String get historicalReportsFinalize => code == 'bn'
      ? 'আজকের ওষুধ চক্র শেষ হলে রিপোর্ট এখানে চূড়ান্ত হবে।'
      : (code == 'hi' ? 'आज का दवा चक्र पूरा होने पर रिपोर्ट यहां अंतिम रूप लेगी।' : 'Historical reports finalize as daily cycles complete.');
  String get noMedDataForPeriod => code == 'bn'
      ? 'এই সময়ের জন্য কোনো ওষুধের তথ্য নেই।'
      : (code == 'hi' ? 'इस अवधि के लिए कोई दवा डेटा नहीं है।' : 'No medication data for this period.');
  String scheduledDosesTakenCount(int taken, int total) {
    final tStr = formatNumber(taken);
    final totStr = formatNumber(total);
    if (code == 'bn') return '$totStrটি নির্ধারিত ওষুধের মধ্যে $tStrটি নেওয়া হয়েছে';
    if (code == 'hi') return '$totStr निर्धारित दवाओं में से $tStr ली गईं';
    return '$taken of $total scheduled doses taken';
  }
  String get missedOrSkipped => code == 'bn' ? 'মিস / বাদ' : (code == 'hi' ? 'छूटी / छोड़ी' : 'Missed');
  String get totalDue => code == 'bn' ? 'মোট সম্পন্ন' : (code == 'hi' ? 'कुल देय' : 'Total Due');
  String get dailyAdherenceRatio => code == 'bn' ? 'দৈনিক গ্রহণের অনুপাত' : (code == 'hi' ? 'दैनिक सेवन अनुपात' : 'Daily Adherence');
  String get monthlyTrend => code == 'bn' ? 'মাসিক ট্রেন্ড' : (code == 'hi' ? 'मासिक रुझान' : 'Monthly Trend');
  String get yearlyTrend => code == 'bn' ? 'বার্ষিক ট্রেন্ড' : (code == 'hi' ? 'वार्षिक रुझान' : 'Yearly Trend');
  String get tapBarForDetails => code == 'bn' ? 'বারে ট্যাপ করে বিস্তারিত দেখুন' : (code == 'hi' ? 'विवरण देखने के लिए बार पर टैप करें' : 'Tap bar for details');
  String get medicationConsistency => code == 'bn' ? 'ওষুধ গ্রহণের ধারাবাহিকতা' : (code == 'hi' ? 'दवा लेने की निरंतरता' : 'Medication Consistency');
  String streakSummaryText(int current, int best) {
    final curStr = formatNumber(current);
    final bstStr = formatNumber(best);
    if (code == 'bn') return 'বর্তমান স্ট্রিক: $curStr দিন  ·  সেরা: $bstStr দিন';
    if (code == 'hi') return 'वर्तमान स्ट्रीक: $curStr दिन  ·  सर्वश्रेष्ठ: $bstStr दिन';
    return 'Current streak: $curStr days  ·  Best: $bstStr days';
  }
  String get noMedicinesInCabinet => code == 'bn' ? 'ওষুধ তালিকায় কোনো ওষুধ নেই' : (code == 'hi' ? 'दवा सूची में कोई दवा नहीं है' : 'No medicines in cabinet');
  String get noMedicinesInCabinetDesc => code == 'bn'
      ? 'দৈনিক ওষুধ গ্রহণ রেকর্ড করতে এবং রিপোর্ট দেখতে ওষুধ যুক্ত করুন।'
      : (code == 'hi' ? 'दैनिक दवा सेवन रिकॉर्ड करने व रिपोर्ट देखने के लिए दवाएं जोड़ें।' : 'Add medicines to track daily doses and visualize health reports.');
  String get sevenDayTracker => code == 'bn' ? 'সাপ্তাহিক ক্যালেন্ডার ট্র্যাকার' : (code == 'hi' ? 'साप्ताहिक कैलेंडर ट्रैकर' : '7-Day Week Tracker');
  String get tapPastDayForReport => code == 'bn' ? 'আগের দিনে ট্যাপ করে রিপোর্ট দেখুন' : (code == 'hi' ? 'रिपोर्ट देखने के लिए पिछले दिन पर टैप करें' : 'Tap past day for report');
  String get pastDayReport => code == 'bn' ? 'পূর্ববর্তী দিনের রিপোর্ট' : (code == 'hi' ? 'पिछले दिन की रिपोर्ट' : 'Past Day Report');
  String get archivedLabel => code == 'bn' ? 'সংরক্ষিত' : (code == 'hi' ? 'संग्रहीत' : 'Archived');
  String get totalLabel => code == 'bn' ? 'মোট ওষুধ' : (code == 'hi' ? 'कुल दवाएं' : 'Total');
  String get adherenceLabel => code == 'bn' ? 'অনুপালন' : (code == 'hi' ? 'अनुपालन' : 'Adherence');
  String get noMedsScheduledDate => code == 'bn' ? 'এই দিনে কোনো ওষুধ নির্ধারিত ছিল না' : (code == 'hi' ? 'इस तारीख को कोई दवा निर्धारित नहीं थी' : 'No medicines were scheduled on this date');
  String get allMedsTaken100 => code == 'bn'
      ? '১০০% অনুপালন সম্পন্ন! সব ওষুধ নেওয়া হয়েছে।'
      : (code == 'hi' ? '100% पूरा हुआ! सभी निर्धारित दवाएं ली गईं।' : '100% Complete! All scheduled medicines were taken.');
  String partiallyCompletedText(int taken, int total, int missed) {
    final tStr = formatNumber(taken);
    final totStr = formatNumber(total);
    final mStr = formatNumber(missed);
    if (code == 'bn') return 'আংশিক সম্পন্ন: $totStrটির মধ্যে $tStrটি নেওয়া হয়েছে, $mStrটি মিস হয়েছে।';
    if (code == 'hi') return 'आंशिक पूर्ण: $totStr में से $tStr ली गईं, $mStr छूट गईं।';
    return 'Partially completed: $tStr of $totStr taken, $mStr missed.';
  }
  String allMedsMissedText(int missed) {
    final mStr = formatNumber(missed);
    if (code == 'bn') return 'সব ওষুধ মিস হয়েছে ($mStrটি ওষুধ নেওয়া হয়নি)।';
    if (code == 'hi') return 'सभी दवाएं छूट गईं ($mStr दवाएं नहीं ली गईं)।';
    return 'All medicines were missed on this day ($mStr missed).';
  }
  String get medicationDetailsList => code == 'bn' ? 'ওষুধের বিস্তারিত তালিকা' : (code == 'hi' ? 'दवाओं की विस्तृत सूची' : 'Medication Details');
  String get futureDate => code == 'bn' ? 'ভবিষ্যতের তারিখ' : (code == 'hi' ? 'भविष्य की तारीख' : 'Future date');
  String get noScheduledDoses => code == 'bn' ? 'কোনো ওষুধ নির্ধারিত নেই' : (code == 'hi' ? 'कोई दवा निर्धारित नहीं' : 'No scheduled doses');
  String dosesTakenOngoing(int taken, int total) {
    final tStr = formatNumber(taken);
    final totStr = formatNumber(total);
    if (code == 'bn') return '$tStr/$totStr নেওয়া হয়েছে (চলমান)';
    if (code == 'hi') return '$tStr/$totStr ली गईं (जारी)';
    return '$tStr/$totStr taken (ongoing)';
  }
  String dosesTakenWithPercent(int taken, int total, int pct) {
    final tStr = formatNumber(taken);
    final totStr = formatNumber(total);
    final pStr = formatNumber(pct);
    if (code == 'bn') return '$tStr/$totStr নেওয়া হয়েছে ($pStr%)';
    if (code == 'hi') return '$tStr/$totStr ली गईं ($pStr%)';
    return '$tStr/$totStr taken ($pStr%)';
  }
  String get dayInspectionHeading => code == 'bn' ? 'তারিখের ওষুধের বিবরণ' : (code == 'hi' ? 'तारीख का दवा विवरण' : 'Day Dose Inspection');
  String get allDoneShort => code == 'bn' ? 'সব নেওয়া' : (code == 'hi' ? 'सभी पूर्ण' : 'All Done');
  String missedCountShort(int count) {
    final numStr = formatNumber(count);
    if (code == 'bn') return '$numStrটি মিস';
    if (code == 'hi') return '$numStr छूटी';
    return '$numStr Missed';
  }
  String get scheduledShort => code == 'bn' ? 'নির্ধারিত' : (code == 'hi' ? 'निर्धारित' : 'Scheduled');
  String get scheduledSchedule => code == 'bn' ? 'বাকি শিডিউল' : (code == 'hi' ? 'शेष शेड्यूल' : 'Scheduled');
  String get pastLabel => code == 'bn' ? 'অতীত' : (code == 'hi' ? 'पिछला' : 'Past');

  // ==================== ADD / EDIT / CABINET ====================
  String get quickStockSelect => code == 'bn' ? 'কুইক স্টক সিলেক্ট করুন:' : (code == 'hi' ? 'त्वरित चयन:' : 'Quick Select:');
  String get stockRefillTitle => code == 'bn' ? 'স্টক ও রিফিল ট্র্যাকিং' : (code == 'hi' ? 'स्टॉक व रीफ़िल ट्रैकिंग' : 'STOCK & REFILL');
  String get howManyMedsHave => code == 'bn' ? 'আপনার কাছে কতগুলো ওষুধ আছে?' : (code == 'hi' ? 'दवा का वर्तमान स्टॉक कितना है?' : 'How much stock do you have?');
  String get autoCalculateCourse => code == 'bn' ? 'কোর্স অনুযায়ী স্বয়ংক্রিয় হিসাব' : (code == 'hi' ? 'कोर्स अनुसार स्वचालित गणना' : 'Smart Course Calculation');
  String get whenRefillAlertPrompt => code == 'bn' ? 'কতটিতে নামলে রিফিল সতর্কতা চান?' : (code == 'hi' ? 'रीफिल अलर्ट कितने पर चाहिए?' : 'Refill alert when below:');
  String get fiftyPercentAutoAlert => code == 'bn' ? '৫০% স্টক বাকি থাকলে স্বয়ংক্রিয় এলার্ট' : (code == 'hi' ? '50% स्टॉक बचने पर अलर्ट' : 'Triggers alert at 50% stock');
  String get fiftyPercentAuto => code == 'bn' ? '৫০% অটো' : (code == 'hi' ? '50% ऑटो' : '50% Auto');
  String get setAtFiftyPercent => code == 'bn' ? '৫০% এ সেট' : (code == 'hi' ? '50% पर सेट' : 'Set 50%');
  String get confirmStockAndSetReminders => code == 'bn' ? 'স্টক নিশ্চিত করুন ও রিমাইন্ডার সেট করুন' : (code == 'hi' ? 'स्टॉक पुष्टि करें और रिमाइंडर सेट करें' : 'Confirm Stock & Set Reminders');
  String get skipStockForNow => code == 'bn' ? 'এখন স্টক দেব না (পরে কার্ড থেকে দেব)' : (code == 'hi' ? 'अभी स्टॉक छोड़ें (बाद में जोड़ें)' : 'Skip stock for now (0 stock)');
  String get startDateHeader => code == 'bn' ? 'শুরুর তারিখ' : (code == 'hi' ? 'शुरुआती तारीख' : 'Start Date');
  String get ongoingTreatmentNoEndDate => code == 'bn' ? 'চলমান চিকিৎসা (কোর্সের নির্দিষ্ট মেয়াদ নেই)' : (code == 'hi' ? 'चल रहा इलाज (कोई समाप्ति तारीख नहीं)' : 'Ongoing treatment (No end date)');
  String get pleaseSelectCourseOrOngoing => code == 'bn' ? 'যেকোনো একটি কোর্স বা চলমান অপশন বাছুন *' : (code == 'hi' ? 'कृपया एक कोर्स या चालू विकल्प चुनें *' : 'Please select a course or ongoing *');
  String get customTime => code == 'bn' ? 'কাস্টম সময়' : (code == 'hi' ? 'कस्टम समय' : 'Custom Time');
  String get tapToSetFoodRoutinePrompt => code == 'bn'
      ? 'সকাল, দুপুর, বিকাল, সন্ধ্যা বা রাত্রিতে ট্যাপ করে খাবারের আগে বা পরে সেট করুন'
      : (code == 'hi' ? 'सुबह, दोपहर, शाम या रात पर टैप करके भोजन से पहले या बाद सेट करें' : 'Tap morning, lunch, afternoon, evening, or night to set before/after meal');
  String get quickAddMode => code == 'bn' ? '⚡ সুপার-ফাস্ট ওষুধ যোগ' : (code == 'hi' ? '⚡ त्वरित दवा जोड़ें' : '⚡ Quick Add Mode');
  String get quickAddModeSub => code == 'bn'
      ? 'স্টক সংখ্যা, ওষুধের ছবি, এক্সপায়ারি ডেট ও নোট যেকোনো সময় কার্ডের "Info & Stock" অপশন থেকে আপডেট করতে পারবেন।'
      : (code == 'hi' ? 'स्टॉक संख्या, फोटो, समाप्ति तारीख व नोट्स बाद में कार्ड के "Info & Stock" से अपडेट कर सकते हैं।' : 'Stock count, photo, expiry date, and notes can be updated anytime from the medicine card.');
  String deleteMedicinePrompt(String name) => code == 'bn' ? 'আপনি কি নিশ্চিত যে "$name" মুছে ফেলতে চান?' : (code == 'hi' ? 'क्या आप वाकई "$name" को हटाना चाहते हैं?' : 'Are you sure you want to delete "$name"?');
  String get enterMedicineNamePrompt => code == 'bn' ? 'ওষুধের নাম লিখুন' : (code == 'hi' ? 'दवा का नाम दर्ज करें' : 'Enter medicine name');
  String get enterDosePrompt => code == 'bn' ? 'ডোজ উল্লেখ করুন' : (code == 'hi' ? 'खुराक दर्ज करें' : 'Dose');
  String fillRequiredFieldsPrompt(String missingList) => code == 'bn' ? 'প্রয়োজনীয় তথ্য পূরণ করুন: $missingList' : (code == 'hi' ? 'कृपया आवश्यक जानकारी भरें: $missingList' : 'Please fill required fields: $missingList');
  String get noTimeSelectedYet => code == 'bn' ? 'কোনো সময় এখনও নির্বাচন করা হয়নি' : (code == 'hi' ? 'अभी कोई समय नहीं चुना गया' : 'No time selected yet');
  String get tapTimeToSetSchedule => code == 'bn' ? 'ওপরে সকাল, দুপুর, বিকাল, সন্ধ্যা বা রাত্রিতে ট্যাপ করে সময় সেট করুন' : (code == 'hi' ? 'ऊपर सुबह, दोपहर, शाम या रात पर टैप करके समय सेट करें' : 'Tap morning, lunch, afternoon, evening, or night above to set time');
  String get dailyRoutineAndDosage => code == 'bn' ? 'ওষুধ খাওয়ার দৈনন্দিন নিয়ম ও মাপ' : (code == 'hi' ? 'दवा लेने का दैनिक नियम व मात्रा' : 'Daily Routine & Dosage');
  String timeSlotsCount(int count) {
    final numStr = formatNumber(count);
    if (code == 'bn') return '$numStrটি সময়';
    if (code == 'hi') return '$numStr समय';
    return '$count timings';
  }
  String get tenStripsLabel => code == 'bn' ? '১০টি (১ পাতা)' : (code == 'hi' ? '10 (1 पत्ता)' : '10 (1 strip)');
  String get twentyStripsLabel => code == 'bn' ? '২০টি (২ পাতা)' : (code == 'hi' ? '20 (2 पत्ते)' : '20 (2 strips)');
  String get thirtyUnitsLabel => code == 'bn' ? '৩০টি' : (code == 'hi' ? '30 इकाइयाँ' : '30 units');
  String proposedCourseCount(dynamic count) {
    final cStr = formatNumber(count);
    if (code == 'bn') return 'প্রস্তাবিত কোর্স: $cStrটি';
    if (code == 'hi') return 'प्रस्तावित कोर्स: $cStr';
    return 'Recommended: $count units';
  }
  String halfCourseCount(dynamic count) {
    final cStr = formatNumber(count);
    if (code == 'bn') return 'অর্ধেক: $cStrটি';
    if (code == 'hi') return 'आधा कोर्स: $cStr';
    return 'Half Course: $count';
  }
  String oneMonthCount(dynamic count) {
    final cStr = formatNumber(count);
    if (code == 'bn') return '১ মাস: $cStrটি';
    if (code == 'hi') return '1 महीना: $cStr';
    return '1 Month: $count';
  }
  String get prescriptionCopiedSnackbar => code == 'bn' ? '📋 ওষুধের প্রেসক্রিপশন ক্লিপবোর্ডে কপি হয়েছে!' : (code == 'hi' ? '📋 पर्चा क्लिपबोर्ड पर कॉपी हो गया!' : '📋 Prescription copied to clipboard!');
  String deleteReminderConfirm(String medName, String time) => code == 'bn' ? '$medName এর $time এর অ্যালার্ম কি মুছে ফেলতে চান?' : (code == 'hi' ? 'क्या आप $medName का $time वाला अलार्म हटाना चाहते हैं?' : 'Are you sure you want to delete the $time alarm for $medName?');
  String get deleteReminderTitle => code == 'bn' ? 'সময় মুছবেন?' : (code == 'hi' ? 'अलार्म हटाएं?' : 'Delete Reminder Time?');
  String get deleteTimeTooltip => code == 'bn' ? 'সময় মুছুন' : (code == 'hi' ? 'समय हटाएं' : 'Delete Time');
  String get deleteBtn => code == 'bn' ? 'মুছুন' : (code == 'hi' ? 'हटाएं' : 'Delete');
  String get deleteFutureRemindersAndHistoryWarning => code == 'bn'
      ? 'এটি এর ভবিষ্যৎ সকল রিমাইন্ডার এবং ওষুধের ইতিহাস মুছে ফেলবে।'
      : (code == 'hi' ? 'यह भविष्य के सभी रिमाइंडर और दवा का इतिहास हटा देगा।' : 'This will remove all upcoming reminders and dose history for this medicine.');
  String get resetBtn => code == 'bn' ? 'রিসেট' : (code == 'hi' ? 'रीसेट' : 'Reset');

  // Alarm Screen
  String get doseTime => code == 'bn' ? 'ওষুধের সময়' : (code == 'hi' ? 'दवा का समय' : 'Dose Reminder');

  // Cabinet Tabs
  String get activeLabel => code == 'bn' ? 'সক্রিয়' : (code == 'hi' ? 'सक्रिय' : 'Active');
  String get pausedLabel => code == 'bn' ? 'স্থগিত' : (code == 'hi' ? 'रोकी गई' : 'Paused');
  String get outOfStockLabel => code == 'bn' ? 'স্টক শেষ' : (code == 'hi' ? 'स्टॉक खत्म' : 'Out of stock');
  String get viewDetails => code == 'bn' ? 'বিস্তারিত তথ্য' : (code == 'hi' ? 'विवरण' : 'Details');
  String leftStockCount(int count) {
    final numStr = formatNumber(count);
    if (code == 'bn') return '$numStrটি বাকি';
    if (code == 'hi') return '$numStr शेष';
    return '$count left';
  }

  // Export Presets
  String get last7Days => code == 'bn' ? 'গত ৭ দিন' : (code == 'hi' ? 'पिछले 7 दिन' : 'Last 7 Days');
  String get last14Days => code == 'bn' ? 'গত ১৪ দিন' : (code == 'hi' ? 'पिछले 14 दिन' : 'Last 14 Days');
  String get thisMonth => code == 'bn' ? 'এই মাস' : (code == 'hi' ? 'इस महीने' : 'This Month');
  String get last30Days => code == 'bn' ? 'গত ৩০ দিন' : (code == 'hi' ? 'पिछले 30 दिन' : 'Last 30 Days');
  String get customRange => code == 'bn' ? 'কাস্টম রেঞ্জ' : (code == 'hi' ? 'कस्टम रेंज' : 'Custom Range');
  String get deselectAll => code == 'bn' ? 'সব বাতিল' : (code == 'hi' ? 'सभी अचयनित करें' : 'Deselect All');
  String get noActiveMedsAvailable => code == 'bn' ? 'কোনো সক্রিয় ওষুধ নেই' : (code == 'hi' ? 'कोई सक्रिय दवा उपलब्ध नहीं' : 'No active medicines available');
  // ==================== ADD / EDIT MEDICINE & STOCK ====================
  String calcFormulaOngoing(int dailyDose, int calculatedStock) {
    final dStr = formatNumber(dailyDose);
    final cStr = formatNumber(calculatedStock);
    if (code == 'bn') return 'নিয়মিত ওষুধ • ৩০ দিনের স্টক (দিনে $dStr বার = $cStrটি ওষুধ)';
    if (code == 'hi') return 'नियमित दवा • 30 दिन का स्टॉक (दिन में $dStr बार = $cStr दवा)';
    return 'Ongoing treatment • 30-day supply ($dailyDose times daily = $calculatedStock units)';
  }
  String calcFormulaCourse(int courseDays, int dailyDose, int calculatedStock) {
    final cDaysStr = formatNumber(courseDays);
    final dStr = formatNumber(dailyDose);
    final cStr = formatNumber(calculatedStock);
    if (code == 'bn') return '$cDaysStr দিনের কোর্স × দিনে $dStr বার = $cStrটি ওষুধের স্বয়ংক্রিয় হিসাব';
    if (code == 'hi') return '$cDaysStr दिन का कोर्स × दिन में $dStr बार = $cStr दवा की स्वचालित गणना';
    return '$courseDays days course × $dailyDose times daily = $calculatedStock units calculated';
  }
  String alertInfoTextRefill(int threshold) {
    final tStr = formatNumber(threshold);
    if (code == 'bn') return '🔔 ৫০% রিফিল এলার্ট: $tStrটি ওষুধ বাকি থাকলে সতর্কবার্তা আসবে';
    if (code == 'hi') return '🔔 50% रीफिल अलर्ट: $tStr दवा बचने पर अलर्ट आएगा';
    return '🔔 50% Refill Alert: Notified when remaining stock reaches $threshold units';
  }
  String get quickSelectLabel => code == 'bn' ? 'কুইক স্টক সিলেক্ট করুন:' : (code == 'hi' ? 'त्वरित स्टॉक चुनें:' : 'Quick Select:');
  String deleteConfirmMedicine(String name) => code == 'bn' ? 'আপনি কি নিশ্চিত যে "$name" মুছে ফেলতে চান?' : (code == 'hi' ? 'क्या आप वाकई "$name" को हटाना चाहते हैं?' : 'Are you sure you want to delete "$name"?');
  String get newMedicinePrompt => code == 'bn' ? 'ওষুধের নাম লিখুন' : (code == 'hi' ? 'दवा का नाम दर्ज करें' : 'New Medicine');
  String get fieldMedicineName => code == 'bn' ? 'ওষুধের নাম' : (code == 'hi' ? 'दवा का नाम' : 'Medicine name');
  String get fieldDosage => code == 'bn' ? 'ডোজ' : (code == 'hi' ? 'खुराक' : 'Dosage');
  String get fieldTreatmentCourse => code == 'bn' ? 'চিকিৎসার মেয়াদ/কোর্স' : (code == 'hi' ? 'उपचार अवधि/कोर्स' : 'Treatment course');
  String get fieldTakingRoutine => code == 'bn' ? 'খাওয়ার সময়/রুটিন' : (code == 'hi' ? 'दवा समय/रूटीन' : 'Taking routine');
  String get noTimingSelectedYet => code == 'bn' ? 'কোনো সময় এখনও নির্বাচন করা হয়নি' : (code == 'hi' ? 'कोई समय अभी तक नहीं चुना गया' : 'No Timing Selected Yet');
  String get tapAnySlotAbovePrompt => code == 'bn' ? 'ওপরে সকাল, দুপুর, বিকাল, সন্ধ্যা বা রাত্রিতে ট্যাপ করে সময় সেট করুন' : (code == 'hi' ? 'समय सेट करने के लिए ऊपर किसी स्लॉट पर टैप करें' : 'Tap any slot above to set routine time');

  // ==================== TIME SLOT MODAL & ROUTINES ====================
  String get mealDescBeforeLunch => code == 'bn' ? 'খাবারের আগে' : (code == 'hi' ? 'भोजन से पहले' : 'Before lunch');
  String get mealDescAfterLunch => code == 'bn' ? 'খাবারের পরে' : (code == 'hi' ? 'भोजन के बाद' : 'After lunch');
  String get mealDescBeforeSnacks => code == 'bn' ? 'নাস্তার আগে' : (code == 'hi' ? 'नाश्ते से पहले' : 'Before snacks');
  String get mealDescAfterSnacks => code == 'bn' ? 'নাস্তার পরে' : (code == 'hi' ? 'नाश्ते के बाद' : 'After snacks');
  String get mealDescBedtime => code == 'bn' ? 'ঘুমানোর আগে' : (code == 'hi' ? 'सोने से पहले' : 'Bedtime');
  String get mealDescBeforeDinner => code == 'bn' ? 'খাবারের আগে' : (code == 'hi' ? 'रात के खाने से पहले' : 'Before dinner');
  String get mealDescAfterDinner => code == 'bn' ? 'খাবারের পরে' : (code == 'hi' ? 'रात के खाने के बाद' : 'After dinner');

  String get morningTimingTitle => code == 'bn' ? 'সকালের ওষুধের সময় ও নিয়ম' : (code == 'hi' ? 'सुबह की दवा का समय और नियम' : 'Morning Dose Timing');
  String get lunchTimingTitle => code == 'bn' ? 'দুপুরের ওষুধের সময় ও নিয়ম' : (code == 'hi' ? 'दोपहर की दवा का समय और नियम' : 'Lunch Dose Timing');
  String get afternoonTimingTitle => code == 'bn' ? 'বিকালের ওষুধের সময় ও নিয়ম' : (code == 'hi' ? 'दोपहर बाद की दवा का समय और नियम' : 'Afternoon Dose Timing');
  String get eveningTimingTitle => code == 'bn' ? 'সন্ধ্যার ওষুধের সময় ও নিয়ম' : (code == 'hi' ? 'शाम की दवा का समय और नियम' : 'Evening Dose Timing');
  String get nightTimingTitle => code == 'bn' ? 'রাতের ওষুধের সময় ও নিয়ম' : (code == 'hi' ? 'रात की दवा का समय और नियम' : 'Night Dose Timing');

  String get optBeforeBreakfastLabel => code == 'bn' ? 'সকালের নাস্তার আগে' : (code == 'hi' ? 'नाश्ते से पहले' : 'Before Breakfast');
  String get optBeforeBreakfastSub => code == 'bn' ? 'সকালের নাস্তার ৩০ মিনিট আগে' : (code == 'hi' ? 'नाश्ते से 30 मिनट पहले' : '30 min before breakfast');
  String get optAfterBreakfastLabel => code == 'bn' ? 'সকালের নাস্তার পরে' : (code == 'hi' ? 'नाश्ते के बाद' : 'After Breakfast');
  String get optAfterBreakfastSub => code == 'bn' ? 'সকালের নাস্তার ৩০ মিনিটের মধ্যে' : (code == 'hi' ? 'नाश्ते के 30 मिनट के भीतर' : 'Within 30 min after breakfast');
  String get optEmptyStomachLabel => code == 'bn' ? 'খালি পেটে' : (code == 'hi' ? 'खाली पेट' : 'Empty Stomach');
  String get optEmptyStomachSub => code == 'bn' ? 'সকালে ঘুম থেকে উঠে ১ গ্লাস পানিসহ' : (code == 'hi' ? 'सुबह उठकर 1 गिलास पानी के साथ' : 'Right after waking up with water');

  String get optBeforeLunchLabel => code == 'bn' ? 'দুপুরের খাবারের আগে' : (code == 'hi' ? 'दोपहर भोजन से पहले' : 'Before Lunch');
  String get optBeforeLunchSub => code == 'bn' ? 'দুপুরের খাওয়ার ৩০ মিনিট আগে' : (code == 'hi' ? 'दोपहर भोजन से 30 मिनट पहले' : '30 min before lunch');
  String get optAfterLunchLabel => code == 'bn' ? 'দুপুরের খাবারের পরে' : (code == 'hi' ? 'दोपहर भोजन के बाद' : 'After Lunch');
  String get optAfterLunchSub => code == 'bn' ? 'দুপুরের খাওয়ার ৩০ মিনিটের মধ্যে' : (code == 'hi' ? 'दोपहर भोजन के 30 मिनट के भीतर' : 'Within 30 min after lunch');
  String get optWithMealLabel => code == 'bn' ? 'খাবারের সাথে' : (code == 'hi' ? 'भोजन के साथ' : 'With Meal');
  String get optWithMealSub => code == 'bn' ? 'দুপুরের খাবার খাওয়ার সাথে' : (code == 'hi' ? 'दोपहर भोजन के साथ' : 'While having lunch');

  String get optBeforeSnacksLabel => code == 'bn' ? 'নাস্তার আগে' : (code == 'hi' ? 'नाश्ते से पहले' : 'Before Snacks');
  String get optBeforeSnacksSub => code == 'bn' ? 'বিকালের নাস্তা বা চা খাওয়ার আগে' : (code == 'hi' ? 'नाश्ते या चाय से पहले' : 'Before afternoon snacks');
  String get optAfterSnacksLabel => code == 'bn' ? 'নাস্তার পরে' : (code == 'hi' ? 'नाश्ते के बाद' : 'After Snacks');
  String get optAfterSnacksSub => code == 'bn' ? 'বিকালের নাস্তা বা চা খাওয়ার পর' : (code == 'hi' ? 'नाश्ते या चाय के बाद' : 'After afternoon snacks');
  String get optAnytimeAfternoonLabel => code == 'bn' ? 'বিকালের যে কোনো সময়' : (code == 'hi' ? 'दोपहर बाद कभी भी' : 'Anytime Afternoon');
  String get optAnytimeAfternoonSub => code == 'bn' ? 'বিকালের যে কোনো সময়' : (code == 'hi' ? 'दोपहर बाद के समय में' : 'Anytime during afternoon');

  String get optBeforeEveningSnacksLabel => code == 'bn' ? 'সন্ধ্যার নাস্তার আগে' : (code == 'hi' ? 'शाम के नाश्ते से पहले' : 'Before Evening Snacks');
  String get optBeforeEveningSnacksSub => code == 'bn' ? 'সন্ধ্যার নাস্তা বা চা খাওয়ার ৩০ মিনিট আগে' : (code == 'hi' ? 'शाम के नाश्ते से 30 मिनट पहले' : '30 min before evening snacks');
  String get optAfterEveningSnacksLabel => code == 'bn' ? 'সন্ধ্যার নাস্তার পরে' : (code == 'hi' ? 'शाम के नाश्ते के बाद' : 'After Evening Snacks');
  String get optAfterEveningSnacksSub => code == 'bn' ? 'সন্ধ্যার নাস্তা বা চা খাওয়ার ৩০ মিনিটের মধ্যে' : (code == 'hi' ? 'शाम के नाश्ते के 30 मिनट के भीतर' : 'Within 30 min after evening snacks');
  String get optAnytimeEveningLabel => code == 'bn' ? 'সন্ধ্যার যে কোনো সময়' : (code == 'hi' ? 'शाम को कभी भी' : 'Anytime Evening');
  String get optAnytimeEveningSub => code == 'bn' ? 'সন্ধ্যার যে কোনো সুবিধাজনক সময়' : (code == 'hi' ? 'शाम के किसी भी समय' : 'Anytime during evening hours');

  String get optBeforeDinnerLabel => code == 'bn' ? 'রাতের খাবারের আগে' : (code == 'hi' ? 'रात के खाने से पहले' : 'Before Dinner');
  String get optBeforeDinnerSub => code == 'bn' ? 'রাতের খাওয়ার ৩০ মিনিট আগে' : (code == 'hi' ? 'रात के खाने से 30 मिनट पहले' : '30 min before dinner');
  String get optAfterDinnerLabel => code == 'bn' ? 'রাতের খাবারের পরে' : (code == 'hi' ? 'रात के खाने के बाद' : 'After Dinner');
  String get optAfterDinnerSub => code == 'bn' ? 'রাতের খাওয়ার ৩০ মিনিটের মধ্যে' : (code == 'hi' ? 'रात के खाने के 30 मिनट के भीतर' : 'Within 30 min after dinner');
  String get optBedtimeLabel => code == 'bn' ? 'ঘুমানোর আগে' : (code == 'hi' ? 'सोने से पहले' : 'At Bedtime');
  String get optBedtimeSub => code == 'bn' ? 'রাতে ঘুমানোর ঠিক আগে' : (code == 'hi' ? 'रात को सोने से ठीक पहले' : 'Right before sleeping');

  String get chooseFoodTimingPrompt => code == 'bn' ? 'ওষুধ খাওয়ার নিয়ম বেছে নিন' : (code == 'hi' ? 'दवा लेने का नियम चुनें' : 'Choose food timing & instruction');
  String get alarmTimePrefix => code == 'bn' ? 'অ্যালার্মের সময়:' : (code == 'hi' ? 'अलार्म का समय:' : 'Alarm Time:');
  String get removeBtn => code == 'bn' ? 'মুছুন' : (code == 'hi' ? 'हटाएं' : 'Remove');
  String get updateReminderBtn => code == 'bn' ? 'সময় আপডেট করুন' : (code == 'hi' ? 'समय अपडेट करें' : 'Update Reminder');
  String get confirmReminderBtn => code == 'bn' ? 'রিমাইন্ডার সেট করুন' : (code == 'hi' ? 'रिमाइंडर सेट करें' : 'Confirm Reminder');


  String get customCourseDurationDialogTitle => code == 'bn' ? 'কাস্টম কোর্সের মেয়াদ' : (code == 'hi' ? 'कस्टम कोर्स अवधि' : 'Custom Course Duration');
  String get howManyDaysMedicinePrompt => code == 'bn' ? 'কত দিন ওষুধটি চলবে?' : (code == 'hi' ? 'यह दवा कितने दिन चलेगी?' : 'How many days should this medicine be taken?');
  String get daysSuffix => code == 'bn' ? 'দিন' : (code == 'hi' ? 'दिन' : 'Days');
  String get pickEndDateCalendar => code == 'bn' ? 'ক্যালেন্ডার থেকে শেষ তারিখ বাছুন' : (code == 'hi' ? 'कैलेंडर से अंतिम तिथि चुनें' : 'Pick end date from calendar');
  String get tapToSetSlot => code == 'bn' ? 'সেট করুন' : (code == 'hi' ? 'सेट करें' : 'Tap to set');
  String get mealDescBeforeBreakfast => code == 'bn' ? 'খাবারের আগে' : (code == 'hi' ? 'नाश्ते से पहले' : 'Before breakfast');
  String get mealDescAfterBreakfast => code == 'bn' ? 'খাবারের পরে' : (code == 'hi' ? 'नाश्ते के बाद' : 'After breakfast');


  // Types
  String get typeTablet => code == 'bn' ? 'ট্যাবলেট' : (code == 'hi' ? 'टैबलेट' : 'Tablet');
  String get typeSyrup => code == 'bn' ? 'সিরাপ' : (code == 'hi' ? 'सिरप' : 'Syrup');
  String get typeCapsule => code == 'bn' ? 'ক্যাপসুল' : (code == 'hi' ? 'कैप्सूल' : 'Capsule');
  String get typeDrops => code == 'bn' ? 'ড্রপ' : (code == 'hi' ? 'ड्रॉप' : 'Drops');
  String get typeInhaler => code == 'bn' ? 'ইনহেলার' : (code == 'hi' ? 'इन्हेलर' : 'Inhaler');

  // Alarm action buttons
  String get takeDoseAction => code == 'bn' ? 'ওষুধ নিয়েছি' : (code == 'hi' ? 'दवा ले ली' : 'Take Dose');
  String get snooze10mAction => code == 'bn' ? '১০ মিনিট পর' : (code == 'hi' ? '१० मिनट बाद' : 'Snooze 10m');
  String get completed => code == 'bn' ? 'সম্পন্ন' : (code == 'hi' ? 'पूर्ण' : 'Completed');

  // Notification Badges
  String get badgeTaken => code == 'bn' ? 'নেওয়া হয়েছে' : (code == 'hi' ? 'ली गई' : 'Taken');
  String get badgeSkipped => code == 'bn' ? 'বাদ দেওয়া হয়েছে' : (code == 'hi' ? 'छोड़ी गई' : 'Skipped');
  String get badgeSnoozed => code == 'bn' ? 'স্থগিত' : (code == 'hi' ? 'स्नूज़' : 'Snoozed');
  String get badgeMissed => code == 'bn' ? 'ছুটে গেছে' : (code == 'hi' ? 'छूट गई' : 'Missed');
  String get badgeRefill => code == 'bn' ? 'রিফিল' : (code == 'hi' ? 'रीफिल' : 'Refill');
  String get badgeLowStock => code == 'bn' ? 'কম স্টক' : (code == 'hi' ? 'कम स्टॉक' : 'Low Stock');
  String get badgeAdded => code == 'bn' ? 'যোগ করা হয়েছে' : (code == 'hi' ? 'जोड़ी गई' : 'Added');
  String get badgeUpdated => code == 'bn' ? 'আপডেট' : (code == 'hi' ? 'अपडेट' : 'Updated');
  String get badgeAlarm => code == 'bn' ? 'অ্যালার্ম' : (code == 'hi' ? 'अलार्म' : 'Alarm');

  String notifLowStockWarningTitle(String name) => code == 'bn' ? 'কম স্টক সতর্কতা: $name' : (code == 'hi' ? 'कम स्टॉक चेतावनी: $name' : 'Low Stock Alert: $name');
  String notifLowStockWarningMsg(dynamic stock, [dynamic unit]) {
    final sStr = formatNumber(stock);
    final uStr = unit != null ? ' $unit' : '';
    if (code == 'bn') return 'বর্তমান মজুদ মাত্র $sStr$uStr। দ্রুত রিফিল করুন।';
    if (code == 'hi') return 'वर्तमान स्टॉक केवल $sStr$uStr। कृपया रीफिल करें।';
    return 'Current stock only $stock$uStr. Please refill soon.';
  }

  // Date Formatting Methods
  String formatFullDate(DateTime dt) {
    if (code == 'bn') {
      const weekdays = ['সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'];
      const months = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
      final weekday = weekdays[dt.weekday - 1];
      final month = months[dt.month - 1];
      return '$weekday, ${formatNumber(dt.day)} $month ${formatNumber(dt.year)}';
    } else if (code == 'hi') {
      const weekdays = ['सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'];
      const months = ['जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'];
      final weekday = weekdays[dt.weekday - 1];
      final month = months[dt.month - 1];
      return '$weekday, ${formatNumber(dt.day)} $month ${formatNumber(dt.year)}';
    }
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final weekday = weekdays[dt.weekday - 1];
    final month = months[dt.month - 1];
    return '$weekday, ${dt.day} $month ${dt.year}';
  }

  String formatDateRange(DateTime start, DateTime end) {
    if (code == 'bn') {
      const monthsShort = ['জানু', 'ফেব্রু', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'];
      final m1 = monthsShort[start.month - 1];
      final m2 = monthsShort[end.month - 1];
      return '${formatNumber(start.day)} $m1 – ${formatNumber(end.day)} $m2 ${formatNumber(end.year)}';
    } else if (code == 'hi') {
      const monthsShort = ['जन', 'फ़र', 'मार्च', 'अप्रै', 'मई', 'जून', 'जुला', 'अग', 'सितं', 'अक्टू', 'नव', 'दिसं'];
      final m1 = monthsShort[start.month - 1];
      final m2 = monthsShort[end.month - 1];
      return '${formatNumber(start.day)} $m1 – ${formatNumber(end.day)} $m2 ${formatNumber(end.year)}';
    }
    const monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final m1 = monthsShort[start.month - 1];
    final m2 = monthsShort[end.month - 1];
    return '${start.day} $m1 – ${end.day} $m2 ${end.year}';
  }

  String formatWeekdayShort(int weekday) {
    if (code == 'bn') {
      const w = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহঃ', 'শুক্র', 'শনি', 'রবি'];
      return w[(weekday - 1) % 7];
    } else if (code == 'hi') {
      const w = ['सोम', 'मंगल', 'बुध', 'गुरु', 'शुक्र', 'शनि', 'रवि'];
      return w[(weekday - 1) % 7];
    }
    const w = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return w[(weekday - 1) % 7];
  }

  // Stock, Refill, and Badges
  String get livePreviewBadge => code == 'bn' ? 'লাইভ প্রিভিউ' : (code == 'hi' ? 'लाइव पूर्वावलोकन' : 'LIVE 3D PREVIEW');
  String get stockRemainingLabel => code == 'bn' ? 'অবশিষ্ট স্টক' : (code == 'hi' ? 'शेष स्टॉक' : 'Stock Remaining');
  String get lowStockWarningLabel => code == 'bn' ? 'কম স্টক সতর্কতা' : (code == 'hi' ? 'कम स्टॉक चेतावनी' : 'Low Stock Warning');
  String unitsLeftText(dynamic count, String unit) {
    final cStr = formatNumber(count);
    if (code == 'bn') return '$cStr $unit বাকি';
    if (code == 'hi') return '$cStr $unit शेष';
    return '$count $unit left';
  }
  String get refillBtn => code == 'bn' ? '+ রিফিল' : (code == 'hi' ? '+ रीफिल' : '+ Refill');
  String get editBtn => code == 'bn' ? 'এডিট' : (code == 'hi' ? 'संपादित' : 'Edit');
  String get infoAndStockBtn => code == 'bn' ? 'তথ্য ও স্টক' : (code == 'hi' ? 'जानकारी व स्टॉक' : 'Info & Stock');
  String get pauseReminders => code == 'bn' ? 'রিমাইন্ডার স্থগিত করুন' : (code == 'hi' ? 'रिमाइंडर रोकें' : 'Pause Reminders');
  String get resumeReminders => code == 'bn' ? 'রিমাইন্ডার চালু করুন' : (code == 'hi' ? 'रिमाइंडर चालू करें' : 'Resume Reminders');
  String get refillOrUpdateStock => code == 'bn' ? 'স্টক রিফিল / আপডেট' : (code == 'hi' ? 'स्टॉक रीफिल / अपडेट' : 'Refill / Update Stock');
  String get duplicate => code == 'bn' ? 'ডুপ্লিকেট' : (code == 'hi' ? 'डुप्लिकेट' : 'Duplicate');

  // Streak & Slot Take/Skip
  String dayStreakText(dynamic streak) {
    final sStr = formatNumber(streak);
    if (code == 'bn') return '$sStr-দিনের স্ট্রিক! চালিয়ে যান!';
    if (code == 'hi') return '$sStr-दिन का स्ट्रीक! जारी रखें!';
    return '$streak-Day Streak! Keep going!';
  }
  String slotTakeCount(dynamic count) {
    final cStr = formatNumber(count);
    if (code == 'bn') return '$cStrটি নেওয়া';
    if (code == 'hi') return '$cStr ली गई';
    return '$count Take';
  }
  String slotSkipCount(dynamic count) {
    final cStr = formatNumber(count);
    if (code == 'bn') return '$cStrটি বাদ';
    if (code == 'hi') return '$cStr छोड़ी';
    return '$count Skip';
  }

  String get dailyAdherenceBadge => code == 'bn' ? 'দৈনিক অনুপালন' : (code == 'hi' ? 'दैनिक अनुपालन' : 'DAILY ADHERENCE');

  String getMonthName(int month) {
    if (code == 'bn') {
      const months = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
      return months[(month - 1).clamp(0, 11)];
    } else if (code == 'hi') {
      const months = ['जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'];
      return months[(month - 1).clamp(0, 11)];
    }
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    return months[(month - 1).clamp(0, 11)];
  }

  // Reminder Controls & Alarms
  String get reminderSoundTitle => code == 'bn' ? 'রিমাইন্ডার সাউন্ড' : (code == 'hi' ? 'रिमाइंडर ध्वनि' : 'Reminder Sound');
  String get reminderSoundDesc => code == 'bn'
      ? 'নির্ধারিত ওষুধের সময় শ্রবণযোগ্য সতর্কবার্তা বাজান'
      : (code == 'hi' ? 'निर्धारित दवा के समय श्रव्य चेतावनी बजाएं' : 'Play auditory alert during scheduled dose reminders');
  String get alarmSoundTitle => code == 'bn' ? 'অ্যালার্ম সাউন্ড' : (code == 'hi' ? 'अलार्म साउंड' : 'Alarm Sound');
  String get alarmSoundDesc => code == 'bn'
      ? 'ওষুধের অনুস্মারকে বাজার জন্য পছন্দের রিংটোন নির্বাচন করুন'
      : (code == 'hi' ? 'दवा के रिमाइंडर पर बजने वाली ध्वनि चुनें' : 'Choose the tone that plays for medicine reminders');
  String get chooseAlarmSoundTitle => code == 'bn' ? 'অ্যালার্ম সাউন্ড নির্বাচন করুন' : (code == 'hi' ? 'अलार्म साउंड चुनें' : 'Select Alarm Sound');
  String get tapToPreviewSound => code == 'bn' ? 'সাউন্ড শুনতে ট্যাপ করুন' : (code == 'hi' ? 'सुनने के लिए टैপ करें' : 'Tap to preview sound');
  String get soundGentleChime => code == 'bn' ? 'শান্ত চাইম (ডিফল্ট)' : (code == 'hi' ? 'शांत चाइम (डिफ़ॉल्ट)' : 'Gentle Chime (Default)');
  String get soundDigitalAlarm => code == 'bn' ? 'ডিজিটাল অ্যালার্ম' : (code == 'hi' ? 'डिजिटल अलार्म' : 'Digital Alarm');
  String get soundMorningMarimba => code == 'bn' ? 'প্রভাত মারিম্বা' : (code == 'hi' ? 'प्रभात मारिम्बा' : 'Morning Marimba');
  String get soundPeacefulBell => code == 'bn' ? 'প্রশান্ত ঘণ্টা' : (code == 'hi' ? 'शांत घंटी' : 'Peaceful Bell');
  String get soundRadarPulse => code == 'bn' ? 'রাডার পালস' : (code == 'hi' ? 'रडार पल्स' : 'Radar Pulse');
  String alarmSoundName(String soundId) {
    switch (soundId) {
      case 'gentle_chime': return soundGentleChime;
      case 'digital_alarm': return soundDigitalAlarm;
      case 'morning_marimba': return soundMorningMarimba;
      case 'peaceful_bell': return soundPeacefulBell;
      case 'radar_pulse': return soundRadarPulse;
      default: return soundGentleChime;
    }
  }
  String get vibrationTitle => code == 'bn' ? 'কম্পন (ভাইব্রেশন)' : (code == 'hi' ? 'कंपन (वाइब्रेशन)' : 'Vibration');
  String get vibrationDesc => code == 'bn'
      ? 'ওষুধের অ্যালার্ম বাজার সময় ফোনটি কম্পিত করুন'
      : (code == 'hi' ? 'दवा का अलार्म बजने पर फोन में कंपन करें' : 'Vibrate phone when a medication alarm rings');
  String get defaultSnoozeTitle => code == 'bn' ? 'ডিফল্ট স্নুজ' : (code == 'hi' ? 'डिफ़ॉल्ट स्नूज़' : 'Default Snooze');
  String get defaultSnoozeDesc => code == 'bn' ? 'স্নুজে ট্যাপ করার পর পুনরায় বাজার ব্যবধান' : (code == 'hi' ? 'स्नूज़ दबाने पर अलार्म का अंतराल' : 'Interval when tapping Snooze');
  String get minShort => code == 'bn' ? 'মি.' : (code == 'hi' ? 'मि.' : 'min');
  String get reminderStyleTitle => code == 'bn' ? 'রিমাইন্ডার ধরন' : (code == 'hi' ? 'रिमाइंडर शैली' : 'Reminder Style');
  String get reminderStyleDesc => code == 'bn'
      ? 'স্থায়ী ফুল অ্যালার্ম অথবা স্ট্যান্ডার্ড নোটিফিকেশন এলার্ট'
      : (code == 'hi' ? 'लगातार पूर्ण अलार्म या सामान्य सूचना अलर्ट' : 'Persistent full alarm or standard notification alert');
  String get languageHeader => code == 'bn' ? 'ভাষা নির্বাচন' : (code == 'hi' ? 'भाषा चुनें' : 'LANGUAGE');

  // Settings & System Sections
  String get dataAndPrivacyHeader => code == 'bn' ? 'ডাটা ও গোপনীয়তা' : (code == 'hi' ? 'डेटा और गोपनीयता' : 'DATA & PRIVACY');
  String get clearHistoryTitle => code == 'bn' ? 'ইনটেক ইতিহাস মুছুন' : (code == 'hi' ? 'सेवन इतिहास साफ़ करें' : 'Clear Intake History');
  String get clearHistorySubtitle => code == 'bn' ? 'ওষুধ না মুছে অতীতের ডোজ রেকর্ড রিসেট করুন' : (code == 'hi' ? 'दवा हटाए बिना पिछले खुराक रिकॉर्ड रीसेट करें' : 'Reset past dose logs without removing medicines');
  String get deleteAllDataTitle => code == 'bn' ? 'সব মেডি-রিমাইন্ড ডাটা মুছুন' : (code == 'hi' ? 'सभी डेटा हटाएं' : 'Delete All MediRemind Data');
  String get deleteAllDataSubtitle => code == 'bn' ? 'ফোনের সব ওষুধ, অ্যালার্ম ও ইতিহাস স্থায়ীভাবে মুছে ফেলুন' : (code == 'hi' ? 'सभी स्थानीय दवाएं, अलार्म और इतिहास स्थायी रूप से हटाएं' : 'Permanently erase all local medicines, alarms, and history');
  String get aboutAndTrustHeader => code == 'bn' ? 'পরিচিতি ও সুরক্ষা' : (code == 'hi' ? 'परिचय और सुरक्षा' : 'ABOUT & TRUST');
  String get safeMedicationCompanion => code == 'bn' ? 'v1.0.0 · নিরাপদ ওষুধ সঙ্গী' : (code == 'hi' ? 'v1.0.0 · सुरक्षित दवा साथी' : 'v1.0.0 · Safe Medication Companion');
  String get aboutDisclaimer => code == 'bn'
      ? 'মেডি-রিমাইন্ড হলো ব্যক্তিগত ওষুধ ব্যবস্থাপনা ও সময়সূচী অনুসরণের একটি টুল। এটি চিকিৎসকের পরামর্শের বিকল্প নয়।'
      : (code == 'hi'
          ? 'मेडी-रिमाइंडर एक व्यक्तिगत दवा प्रबंधन और अनुसूची ट्रैकिंग साधन है। यह पेशेवर चिकित्सा सलाह का विकल्प नहीं है।'
          : 'MediRemind is a personal medication management and schedule tracking utility. It is not intended to diagnose, treat, or replace professional medical advice.');
  String get replayOnboarding => code == 'bn' ? 'ওয়েলকাম ও অনবোর্ডিং গাইড পুনরায় দেখুন' : (code == 'hi' ? 'स्वागत और ऑनबोर्डिंग गाइड दोबारा देखें' : 'Replay Welcome & Onboarding Guide');
  String get founderRole => code == 'bn' ? 'প্রধান ডেভেলপার ও ইউআই/ইউএক্স ডিজাইনার / প্রতিষ্ঠাতা' : (code == 'hi' ? 'मुख्य डेवलपर और यूआई/यूएक्स डिज़ाइनर / संस्थापक' : 'Lead Developer & UI/UX Designer / Founder & Creator');
  String get manageFamilyMembers => code == 'bn' ? 'পরিবারের সদস্যদের পরিচালনা করুন' : (code == 'hi' ? 'परिवार के सदस्यों का प्रबंधन' : 'Manage Family Members');
  String get remindersAndAlarmsHeader => code == 'bn' ? 'রিমাইন্ডার ও অ্যালার্ম' : (code == 'hi' ? 'रिमाइंडर और अलार्म' : 'REMINDERS & ALARMS');
  String get systemPermissionsHeader => code == 'bn' ? 'সিস্টেম অনুমতিসমূহ' : (code == 'hi' ? 'सिस्टम अनुमतियां' : 'SYSTEM PERMISSIONS');
  String get permissionsRequiredTitle => code == 'bn' ? 'অনুমতি প্রয়োজন' : (code == 'hi' ? 'अनुमतियां आवश्यक' : 'Permissions Required');
  String get permissionsRequiredSubtitle => code == 'bn' ? 'অ্যালার্ম নির্ভুলভাবে বাজানোর জন্য অনুমতি প্রদান করুন' : (code == 'hi' ? 'सटीक अलार्म के लिए अनुमतियां प्रदान करें' : 'Grant permissions to guarantee alarms fire accurately.');
  String get fixAllBtn => code == 'bn' ? 'সব ঠিক করুন' : (code == 'hi' ? 'सभी ठीक करें' : 'Fix All');
  String get notifPermissionTitle => code == 'bn' ? 'নোটিফিকেশন অনুমতি' : (code == 'hi' ? 'सूचना अनुमति' : 'Notification Permission');
  String get notifPermissionDesc => code == 'bn' ? 'মেডি-রিমাইন্ডকে ওষুধের রিমাইন্ডার সতর্কতা দেখানোর অনুমতি দেয়।' : (code == 'hi' ? 'मेडी-रिमाइंडर को दवा रिमाइंडर अलर्ट दिखाने की अनुमति देता है।' : 'Allows MediRemind to show medicine reminder alerts.');
  String get exactAlarmTitle => code == 'bn' ? 'সঠিক অ্যালার্ম অনুমতি' : (code == 'hi' ? 'सटीक अलार्म अनुमति' : 'Exact Alarm Permission');
  String get exactAlarmDesc => code == 'bn' ? 'নির্ধারিত ডোজ অ্যালার্ম যেন সঠিক মিনিটে বাজে তা নিশ্চিত করে।' : (code == 'hi' ? 'सुनिश्चित करता है कि निर्धारित अलार्म सही मिनट पर बजे।' : 'Ensures scheduled dose alarms trigger on the exact minute.');
  String get batteryOptimizationTitle => code == 'bn' ? 'ব্যাটারি অপ্টিমাইজেশন' : (code == 'hi' ? 'बैटरी अनुकूलन' : 'Battery Optimization');
  String get batteryOptimizationDesc => code == 'bn' ? 'অ্যান্ড্রয়েড সিস্টেমকে ব্যাকগ্রাউন্ড ডোজ অ্যালার্ম বিলম্ব করা থেকে বিরত রাখে।' : (code == 'hi' ? 'एंड्रॉइड सिस्टम को बैकग्राउंड अलार्म में देरी करने से रोकता है।' : 'Prevents Android system from delaying background dose alarms.');
  String get standardAlert => code == 'bn' ? 'সাধারণ সতর্কতা' : (code == 'hi' ? 'सामान्य अलर्ट' : 'Standard Alert');
  String get persistentAlarm => code == 'bn' ? 'স্থায়ী অ্যালার্ম' : (code == 'hi' ? 'लगातार अलार्म' : 'Persistent Alarm');
  String get clearHistoryDialogTitle => code == 'bn' ? 'ইনটেক ইতিহাস মুছে ফেলবেন?' : (code == 'hi' ? 'क्या सेवन इतिहास साफ़ करें?' : 'Clear Intake History?');
  String get clearHistoryDialogContent => code == 'bn'
      ? 'এটি অতীতের সমস্ত ডোজ লগ এবং গ্রহণের চার্ট রিসেট করে শূন্য করে দেবে। আপনার ওষুধের সময়সূচী সক্রিয় থাকবে।\n\nআপনি কি নিশ্চিত যে ইতিহাস সাফ করতে চান?'
      : (code == 'hi'
          ? 'यह पिछले सभी खुराक लॉग और चार्ट को शून्य कर देगा। आपकी दवा की अनुसूची सक्रिय रहेगी।\n\nक्या आप वाकई इतिहास साफ़ करना चाहते हैं?'
          : 'This will reset all past dose logs and adherence charts to zero. Your medicine schedule will remain active.\n\nAre you sure you want to clear history?');
  String get deleteAllDialogTitle => code == 'bn' ? 'সমস্ত ডাটা মুছে ফেলবেন?' : (code == 'hi' ? 'क्या सभी डेटा हटाएं?' : 'Delete All Data?');
  String get deleteAllDialogContent => code == 'bn'
      ? 'এটি স্থায়ীভাবে মুছে ফেলবে:\n• ক্যাবিনেটের সমস্ত ওষুধ\n• সমস্ত নির্ধারিত রিমাইন্ডার অ্যালার্ম\n• সম্পূর্ণ ডোজ গ্রহণ ও অনুসরণের ইতিহাস\n• কাস্টম পারিবারিক প্রোফাইল\n\nএই ক্রিয়াটি ফিরিয়ে নেওয়া যাবে না।'
      : (code == 'hi'
          ? 'यह स्थायी रूप से हटा देगा:\n• कैबिनेट की सभी दवाएं\n• सभी निर्धारित रिमाइंडर अलार्म\n• पूरा खुराक इतिहास\n• परिवार के प्रोफाइल\n\nइस क्रिया को वापस नहीं लाया जा सकता।'
          : 'This will permanently delete:\n• All medicines in cabinet\n• All scheduled reminder alarms\n• Complete intake and adherence history\n• Custom family profiles\n\nThis action cannot be undone.');
  String get deleteEverythingBtn => code == 'bn' ? 'সবকিছু মুছে ফেলুন' : (code == 'hi' ? 'सब कुछ हटाएं' : 'Delete Everything');
  String get allDataErasedMsg => code == 'bn' ? 'মেডি-রিমাইন্ডের সমস্ত লোকাল ডাটা মুছে ফেলা হয়েছে।' : (code == 'hi' ? 'सभी स्थानीय डेटा हटा दिया गया है।' : 'All local MediRemind data has been erased.');

  // Medicine Details & Extra Labels
  String get active => code == 'bn' ? 'সক্রিয়' : (code == 'hi' ? 'सक्रिय' : 'Active');
  String get inactive => code == 'bn' ? 'নিষ্ক্রিয়' : (code == 'hi' ? 'निष्क्रिय' : 'Inactive');
  String get category => code == 'bn' ? 'ক্যাটাগরি' : (code == 'hi' ? 'श्रेणी' : 'Category');
  String get frequency => code == 'bn' ? 'ফ্রিকোয়েন্সি' : (code == 'hi' ? 'आवृत्ति' : 'Frequency');
  String get timesPerDay => code == 'bn' ? 'বার/দিন' : (code == 'hi' ? 'बार/दिन' : 'times/day');
  String get time => code == 'bn' ? 'সময়' : (code == 'hi' ? 'समय' : 'Time');
  String get startDate => code == 'bn' ? 'শুরুর তারিখ' : (code == 'hi' ? 'आरंभ तिथि' : 'Start Date');
  String get notes => code == 'bn' ? 'নোটস' : (code == 'hi' ? 'नोट्स' : 'Notes');
  String get stock => code == 'bn' ? 'স্টক' : (code == 'hi' ? 'स्टॉक' : 'Stock');
  String get edit => code == 'bn' ? 'সম্পাদনা' : (code == 'hi' ? 'संपादित करें' : 'Edit');
  String get editMedicineDetails => code == 'bn' ? 'ওষুধের তথ্য সম্পাদনা' : (code == 'hi' ? 'दवा का विवरण संपादित करें' : 'Edit Medicine Details');
  String get viewHistory => code == 'bn' ? 'ইতিহাস দেখুন' : (code == 'hi' ? 'इतिहास देखें' : 'View History');
  String get sharePrescription => code == 'bn' ? 'প্রেসক্রিপশন শেয়ার করুন' : (code == 'hi' ? 'पर्चा साझा करें' : 'Share Prescription');
  String get deleteMedicineConfirm => code == 'bn' ? 'আপনি কি নিশ্চিত এই ওষুধটি মুছে ফেলতে চান?' : (code == 'hi' ? 'क्या आप वाकई इस दवा को हटाना चाहते हैं?' : 'Are you sure you want to delete this medicine?');
}


