/* FoodBridge — interactive web demo.
   Mirrors the Flutter app in github.com/codewithyogeshh/Update_FoodBridge:
   4 role views, safety charter, dual-OTP custody and the donation lifecycle.
   All data below is simulated locally (localStorage); no database is connected. */

const STORE_KEY = "foodbridge-demo-v3";

const I18N = {
  en: {
    tagline: "Share more. Waste less. Bridge the need.",
    sub: "Surplus food & essentials, redistributed in real time",
    home: "Home",
    profile: "Profile",
    hello: "Hello",
    goodMorning: "Good morning",
    goodAfternoon: "Good afternoon",
    goodEvening: "Good evening",
    welcomeBack: "Welcome back",
    signSub: "Sign in to continue, or pick a demo profile to explore a role.",
    quickSelect: "Choose a profile",
    emailLabel: "Email address",
    passwordLabel: "Password",
    forgot: "Forgot password?",
    signInAs: "Sign in as",
    noAccount: "New to FoodBridge?",
    register: "Create an account",
    demoNote: "Demo build — every record is simulated on this device. No live database is connected.",
    signIn: "Sign in",
    chooseProfile: "Quick demo access",
    credentials: "Credentials are pre-filled for this demo.",
    trustFssai: "FSSAI aligned",
    trustVerified: "Verified partners",
    trustOtp: "2-step OTP custody",
    charterTitle: "Platform & Safety Charter",
    charterSub: "A short read before you start. These rules keep every handover safe and dignified.",
    agree1: "I agree to the FoodBridge terms, FSSAI food-safety guidelines and the community privacy charter.",
    agree2: "I will treat every donor, volunteer, shelter partner and beneficiary with dignity and respect.",
    accept: "Accept & continue",
    decline: "Decline & sign out",
    roleDonor: "Donor",
    roleNgo: "NGO",
    roleVolunteer: "Volunteer",
    roleAdmin: "Admin",
    roleDonorDesc: "Restaurants, caterers & families",
    roleNgoDesc: "Shelters & verified NGOs",
    roleVolunteerDesc: "Riders & pickup partners",
    roleAdminDesc: "Platform operations",
    donorDashboard: "Donor Dashboard",
    ngoPortal: "NGO Portal",
    volunteerDispatch: "Volunteer Dispatch",
    adminConsole: "Admin Console",
    notifications: "Notifications",
    profileTitle: "Profile & Settings",
    donateFoodTitle: "Donate food surplus",
    donateClothesTitle: "Donate clothes",
    createDonation: "Create a donation",
    donateFood: "Donate surplus food",
    donateFoodSub: "Cooked meals, groceries, bakery",
    donateClothes: "Donate clothes",
    donateClothesSub: "Clean, wearable essentials",
    myDonations: "My donations",
    viewAll: "View all",
    newDonation: "New donation",
    available: "Available",
    accepted: "Accepted",
    assigned: "Rider assigned",
    inTransit: "In transit",
    delivered: "Delivered",
    claims: "Claims",
    distributions: "Distributed",
    verification: "Verification",
    pending: "pending",
    allDonations: "All",
    surplusFood: "Food",
    clothing: "Clothes",
    expiringSoon: "Closing soon",
    availableNear: "Available near you",
    listings: "listings",
    claimDonation: "Claim this donation",
    claimed: "Claimed",
    yourClaims: "Your claims",
    deliveryPinShare: "Delivery PIN — share with the rider",
    motorcycle: "Motorcycle dispatcher",
    active: "Active",
    online: "Online",
    offline: "Offline",
    availableDispatches: "Available dispatches",
    noDispatches: "Nothing here right now. New listings appear the moment a donor posts.",
    acceptDispatch: "Accept dispatch",
    enterPickup: "Enter pickup PIN",
    enterDelivery: "Enter delivery PIN",
    inTransitNow: "In transit — deliver now",
    missions: "Missions completed",
    rating: "Rating",
    foodRescue: "Food rescue",
    match: "Match",
    collectBy: "Collect by",
    handling: "Handling",
    overview: "Overview",
    ngoApprovals: "Approvals",
    users: "Users",
    complaints: "Complaints",
    audit: "Audit log",
    analyticsNote: "All analytics are computed live from the demo records.",
    totalListings: "Total listings",
    foodRescues: "Food rescues",
    clothingItems: "Clothing items",
    deliveriesMade: "Deliveries made",
    verifiedNgos: "Verified NGOs",
    activeRiders: "Active riders",
    lifecycle: "Live donation lifecycle",
    items: "items",
    markAllRead: "Mark all read",
    allFilter: "All",
    unread: "Unread",
    switchRole: "Switch role view",
    preferences: "Preferences",
    darkMode: "Dark theme",
    darkModeSub: "Softer charcoal, easier at night",
    language: "Language",
    chooseLanguage: "Choose your language",
    chooseLanguageSub: "The whole demo switches instantly — no page reload.",
    langSaved: "Language updated",
    signOut: "Sign out",
    verifiedShelter: "Verified shelter NGO",
    tapVerify: "View verification",
    darpan: "Darpan",
    fssai: "FSSAI licence",
    published: "Donation published to the network",
    claimedMsg: "Donation claimed — the delivery PIN is now unlocked",
    acceptedMsg: "Dispatch accepted — collect the goods, then verify the pickup PIN",
    pickupMsg: "Pickup verified — the order is in transit",
    deliveredMsg: "Delivery confirmed. Thank you for bridging the need.",
    wrongPin: "That PIN is incorrect. Use the code shown to the other party.",
    verifyPickupTitle: "Verify pickup PIN",
    verifyDeliveryTitle: "Confirm delivery PIN",
    pinHint: "Enter the 4-digit PIN held by the other party.",
    confirm: "Confirm",
    cancel: "Cancel",
    detail: "Donation details",
    pickupArea: "Pickup area",
    category: "Category",
    deadline: "Collection deadline",
    custody: "Dual-OTP custody",
    pickupOtp: "Pickup OTP",
    deliveryOtp: "Delivery OTP",
    posted: "Posted",
    quantity: "Quantity",
    unit: "Unit",
    publishedOn: "Published",
    photo: "Photo",
    selectPhoto: "Choose a cover",
    foodCategory: "Food category",
    cookedMeals: "Cooked meals",
    rawProduce: "Groceries & produce",
    bakery: "Bakery & dairy",
    packaged: "Packaged & dry goods",
    foodName: "Title",
    foodNamePh: "e.g. 50 boxes of veg pulao & dal tadka",
    desc: "Description & packaging notes",
    descPh: "e.g. Cooked for a corporate lunch, sealed in foil trays.",
    quantityPh: "e.g. 50",
    dietType: "Diet",
    pureVeg: "Pure veg",
    nonVeg: "Non-veg",
    holding: "Holding condition",
    hotHolding: "Hot-held (>63°C)",
    ambient: "Ambient room temp",
    chilled: "Chilled (<5°C)",
    publishFood: "Publish food listing",
    clothingTitle: "Donate clean clothing",
    clothingSub: "Washed, wearable items for verified local shelters.",
    condition: "Condition",
    target: "For",
    publishClothes: "Publish clothing listing",
    back: "Back",
    impactTitle: "Your impact",
    mealsShared: "Meals shared",
    kgRescued: "kg rescued",
    familiesReached: "Families reached",
    verifiedDonor: "Verified donor",
    memberSince: "Member since 2024",
    support: "Help & support",
    version: "Version 2.0 · demo build",
    pickup: "Pickup",
    dropoff: "Drop-off",
    distance: "distance",
    eta: "ETA",
    min: "min",
    route: "Route",
    statusMix: "Listing status",
    recentActivity: "Recent activity",
    pendingApprovals: "Pending approvals",
    openTickets: "Open tickets",
    health: "On-time handovers",
    thisWeek: "this week",
    awaitingReview: "Darpan and FSSAI documents uploaded — awaiting review",
    approve: "Approve",
    approvedMsg: "NGO approved — verification badge issued",
    noApprovals: "No pending approvals. Every partner is verified.",
    complaintTitle: "Delayed pickup reported",
    complaintBody: "Ticket #CMP-104 · the collect-by deadline passed for 60 fruit hampers. The rider was reassigned.",
    log1: "Rohit Kulkarni accepted dispatch for 60 assorted fruit & snack hampers",
    log2: "Asha Children Foundation claimed 40 chapati & paneer bhurji combos",
    log3: "FSSAI licence of Symbiosis Campus Cafeteria verified by the admin team",
    log4: "Delivery OTP 9917 verified — 30 home-style veg thali boxes delivered",
    unitMeals: "meals",
    unitPieces: "pieces",
    todayAt: "Today, {t}",
    tomorrowAt: "Tomorrow, {t}",
    publishErr: "Add a title and a quantity first.",
    closesIn: "Closes",
    sortSoonest: "Soonest first",
    quickActions: "Quick actions",
    recentDonations: "Recent donations",
    activeRoute: "Active route",
    noClaims: "Claim a listing to see it here.",
    secure: "Encrypted handover",
    statusOpen: "Open",
    ntClaimedT: "Donation claimed",
    ntClaimedB: "{name} claimed {title}.",
    ntDispatchT: "Volunteer dispatched",
    ntDispatchB: "{name} accepted the dispatch for {title}.",
    ntPickupT: "Goods picked up",
    ntPickupB: "Pickup OTP verified for {title}. The rider is on the way.",
    ntNewT: "New donation available",
    ntNewB: "{name} listed {title} in {area}.",
    ntDeliveredT: "Delivery confirmed",
    ntDeliveredB: "{title} reached {name}.",
    ntApprovedT: "Partner approved",
    ntApprovedB: "{name} passed Darpan and FSSAI verification.",
    ch1T: "Food safety & hygiene (FSSAI)",
    ch1B: "Surplus food must be freshly prepared, untainted, held at safe temperatures (hot above 60°C, chilled below 5°C) and collected before its deadline. A visual check never replaces safety certification.",
    ch2T: "Clean clothing standards",
    ch2B: "Garments, winterwear and blankets must be washed, sanitised, dry and wearable. Torn, stained or unusable items are not accepted.",
    ch3T: "Zero commercialisation",
    ch3B: "Donations are 100% free and meant only for vulnerable communities and shelter residents. Selling, bartering or monetising a donation is not allowed.",
    ch4T: "Privacy & masked locations",
    ch4B: "A donor's exact street address stays masked until an authorised volunteer or verified shelter accepts the dispatch.",
    ch5T: "Dispatch & two-leg OTP",
    ch5B: "Pickup and delivery each need a 4-digit PIN held by the donor and the shelter. A delivery cannot close without both.",
  },
  mr: {
    tagline: "अधिक शेअर करा. कमी वाया घालवा. गरज जोडा.",
    sub: "अतिरिक्त अन्न व जीवनावश्यक वस्तूंचे रिअल-टाइम पुनर्वितरण",
    home: "होम",
    profile: "प्रोफाइल",
    hello: "नमस्कार",
    goodMorning: "सुप्रभात",
    goodAfternoon: "शुभ दुपार",
    goodEvening: "शुभ संध्याकाळ",
    welcomeBack: "परत स्वागत आहे",
    signSub: "पुढे जाण्यासाठी साइन इन करा किंवा भूमिका पाहण्यासाठी डेमो प्रोफाइल निवडा.",
    quickSelect: "प्रोफाइल निवडा",
    emailLabel: "ईमेल पत्ता",
    passwordLabel: "पासवर्ड",
    forgot: "पासवर्ड विसरलात?",
    signInAs: "या रूपात साइन इन",
    noAccount: "FoodBridge वर नवीन आहात?",
    register: "खाते तयार करा",
    demoNote: "डेमो आवृत्ती — सर्व नोंदी याच डिव्हाइसवर सिम्युलेटेड आहेत. थेट डेटाबेस जोडलेला नाही.",
    signIn: "साइन इन",
    chooseProfile: "झटपट डेमो प्रवेश",
    credentials: "या डेमोसाठी माहिती आधीच भरलेली आहे.",
    trustFssai: "FSSAI नियमांशी सुसंगत",
    trustVerified: "पडताळलेले भागीदार",
    trustOtp: "२-टप्प्यांची ओटीपी सुपूर्दगी",
    charterTitle: "प्लॅटफॉर्म व सुरक्षा अधिकारपत्र",
    charterSub: "सुरुवातीपूर्वी थोडं वाचा. हे नियम प्रत्येक सुपूर्दगी सुरक्षित व सन्मानाने ठेवतात.",
    agree1: "मी FoodBridge अटी, FSSAI अन्न-सुरक्षा नियम व गोपनीयता अधिकारपत्रास संमती देतो.",
    agree2: "मी प्रत्येक दानकर्ता, स्वयंसेवक, निवारा भागीदार व लाभार्थ्याशी सन्मानाने वागेन.",
    accept: "स्वीकारा व पुढे जा",
    decline: "नाकारा व साइन आउट",
    roleDonor: "दानकर्ता",
    roleNgo: "एनजीओ",
    roleVolunteer: "स्वयंसेवक",
    roleAdmin: "ॲडमिन",
    roleDonorDesc: "रेस्टॉरंट, केटरर व कुटुंबे",
    roleNgoDesc: "निवारा गृहे व पडताळलेले एनजीओ",
    roleVolunteerDesc: "रायडर व पिकअप भागीदार",
    roleAdminDesc: "प्लॅटफॉर्म परिचालन",
    donorDashboard: "दानकर्ता डॅशबोर्ड",
    ngoPortal: "एनजीओ पोर्टल",
    volunteerDispatch: "स्वयंसेवक डिस्पॅच",
    adminConsole: "ॲडमिन कन्सोल",
    notifications: "सूचना",
    profileTitle: "प्रोफाइल व सेटिंग्ज",
    donateFoodTitle: "अतिरिक्त अन्न दान",
    donateClothesTitle: "कपडे दान",
    createDonation: "दान तयार करा",
    donateFood: "अतिरिक्त अन्न दान करा",
    donateFoodSub: "शिजवलेले जेवण, किराणा, बेकरी",
    donateClothes: "कपडे दान करा",
    donateClothesSub: "स्वच्छ, वापरण्यायोग्य वस्तू",
    myDonations: "माझी दाने",
    viewAll: "सर्व पहा",
    newDonation: "नवीन दान",
    available: "उपलब्ध",
    accepted: "स्वीकारले",
    assigned: "रायडर नेमला",
    inTransit: "वाटेत",
    delivered: "पूर्ण",
    claims: "दावे",
    distributions: "वाटप",
    verification: "पडताळणी",
    pending: "प्रलंबित",
    allDonations: "सर्व",
    surplusFood: "अन्न",
    clothing: "कपडे",
    expiringSoon: "लवकर संपणारे",
    availableNear: "जवळ उपलब्ध",
    listings: "नोंदी",
    claimDonation: "हे दान स्वीकारा",
    claimed: "स्वीकारले",
    yourClaims: "तुमचे दावे",
    deliveryPinShare: "डिलिव्हरी पिन — रायडरला द्या",
    motorcycle: "मोटरसायकल डिस्पॅचर",
    active: "सक्रिय",
    online: "ऑनलाइन",
    offline: "ऑफलाइन",
    availableDispatches: "उपलब्ध डिस्पॅच",
    noDispatches: "सध्या येथे काही नाही. दानकर्त्याने नोंद केल्याक्षणी नवीन नोंदी दिसतील.",
    acceptDispatch: "डिस्पॅच स्वीकारा",
    enterPickup: "पिकअप पिन टाका",
    enterDelivery: "डिलिव्हरी पिन टाका",
    inTransitNow: "वाटेत — आता पोहोचवा",
    missions: "पूर्ण मोहिमा",
    rating: "रेटिंग",
    foodRescue: "अन्न बचाव",
    match: "जुळणी",
    collectBy: "संकलन",
    handling: "हाताळणी",
    overview: "आढावा",
    ngoApprovals: "मंजुरी",
    users: "वापरकर्ते",
    complaints: "तक्रारी",
    audit: "ऑडिट लॉग",
    analyticsNote: "सर्व आकडे डेमो नोंदींवरून थेट मोजले जातात.",
    totalListings: "एकूण नोंदी",
    foodRescues: "अन्न बचाव",
    clothingItems: "कपडे",
    deliveriesMade: "पूर्ण डिलिव्हरी",
    verifiedNgos: "पडताळलेले एनजीओ",
    activeRiders: "सक्रिय रायडर",
    lifecycle: "थेट दान जीवनचक्र",
    items: "नोंदी",
    markAllRead: "सर्व वाचले",
    allFilter: "सर्व",
    unread: "न वाचलेले",
    switchRole: "भूमिका बदला",
    preferences: "प्राधान्ये",
    darkMode: "डार्क थीम",
    darkModeSub: "मऊ काळोख, रात्री डोळ्यांना सोपा",
    language: "भाषा",
    chooseLanguage: "तुमची भाषा निवडा",
    chooseLanguageSub: "संपूर्ण डेमो लगेच बदलेल — पेज रीलोड न करता.",
    langSaved: "भाषा बदलली",
    signOut: "साइन आउट",
    verifiedShelter: "पडताळलेले निवारा एनजीओ",
    tapVerify: "पडताळणी पहा",
    darpan: "दर्पण",
    fssai: "FSSAI परवाना",
    published: "दान नेटवर्कवर प्रकाशित झाले",
    claimedMsg: "दान स्वीकारले — डिलिव्हरी पिन आता उघडला",
    acceptedMsg: "डिस्पॅच स्वीकारला — वस्तू घ्या आणि पिकअप पिन पडताळा",
    pickupMsg: "पिकअप पडताळला — ऑर्डर आता वाटेत आहे",
    deliveredMsg: "डिलिव्हरी निश्चित. गरज जोडल्याबद्दल धन्यवाद.",
    wrongPin: "पिन चुकीचा आहे. दुसऱ्या व्यक्तीला दाखवलेला पिन वापरा.",
    verifyPickupTitle: "पिकअप पिन पडताळा",
    verifyDeliveryTitle: "डिलिव्हरी पिन निश्चित करा",
    pinHint: "दुसऱ्या व्यक्तीकडील ४-अंकी पिन टाका.",
    confirm: "निश्चित करा",
    cancel: "रद्द",
    detail: "दानाचा तपशील",
    pickupArea: "पिकअप परिसर",
    category: "प्रकार",
    deadline: "संकलन अंतिम वेळ",
    custody: "दुहेरी-ओटीपी सुपूर्दगी",
    pickupOtp: "पिकअप ओटीपी",
    deliveryOtp: "डिलिव्हरी ओटीपी",
    posted: "नोंदवले",
    quantity: "प्रमाण",
    unit: "एकक",
    publishedOn: "प्रकाशित",
    photo: "फोटो",
    selectPhoto: "कव्हर निवडा",
    foodCategory: "अन्न प्रकार",
    cookedMeals: "शिजवलेले जेवण",
    rawProduce: "किराणा व भाजी",
    bakery: "बेकरी व दूध",
    packaged: "पॅकबंद व कोरडे",
    foodName: "शीर्षक",
    foodNamePh: "उदा. ५० बॉक्स व्हेज पुलाव व डाळ तडका",
    desc: "वर्णन व पॅकेजिंग नोंद",
    descPh: "उदा. कॉर्पोरेट लंचसाठी शिजवलेले, फॉइल ट्रेमध्ये सीलबंद.",
    quantityPh: "उदा. ५०",
    dietType: "आहार",
    pureVeg: "शुद्ध व्हेज",
    nonVeg: "नॉन-व्हेज",
    holding: "साठवण स्थिती",
    hotHolding: "गरम (>६३°C)",
    ambient: "सामान्य तापमान",
    chilled: "थंड (<५°C)",
    publishFood: "अन्न नोंद प्रकाशित करा",
    clothingTitle: "स्वच्छ कपडे दान करा",
    clothingSub: "पडताळलेल्या स्थानिक निवाऱ्यांसाठी धुतलेली, वापरण्यायोग्य वस्तू.",
    condition: "स्थिती",
    target: "कोणासाठी",
    publishClothes: "कपडे नोंद प्रकाशित करा",
    back: "मागे",
    impactTitle: "तुमचा प्रभाव",
    mealsShared: "जेवण शेअर",
    kgRescued: "किलो वाचवले",
    familiesReached: "कुटुंबांपर्यंत",
    verifiedDonor: "पडताळलेला दानकर्ता",
    memberSince: "२०२४ पासून सदस्य",
    support: "मदत व सहाय्य",
    version: "आवृत्ती २.० · डेमो",
    pickup: "पिकअप",
    dropoff: "ड्रॉप-ऑफ",
    distance: "अंतर",
    eta: "अंदाजे वेळ",
    min: "मिनिटे",
    route: "मार्ग",
    statusMix: "नोंदींची स्थिती",
    recentActivity: "अलीकडील घडामोडी",
    pendingApprovals: "प्रलंबित मंजुरी",
    openTickets: "खुल्या तक्रारी",
    health: "वेळेवर सुपूर्दगी",
    thisWeek: "या आठवड्यात",
    awaitingReview: "दर्पण व FSSAI कागदपत्रे अपलोड — पडताळणी प्रलंबित",
    approve: "मंजूर करा",
    approvedMsg: "एनजीओ मंजूर — पडताळणी बिल्ला दिला",
    noApprovals: "प्रलंबित मंजुरी नाही. सर्व भागीदार पडताळलेले आहेत.",
    complaintTitle: "उशिरा पिकअपची तक्रार",
    complaintBody: "तक्रार #CMP-104 · ६० फळ हॅम्परची संकलन अंतिम वेळ संपली. रायडर बदलला.",
    log1: "रोहित कुलकर्णीने ६० फळ व स्नॅक हॅम्परचा डिस्पॅच स्वीकारला",
    log2: "आशा चिल्ड्रन फाउंडेशनने ४० चपाती व पनीर भुर्जी कॉम्बो स्वीकारले",
    log3: "सिम्बायोसिस कॅम्पस कॅफेटेरियाचा FSSAI परवाना ॲडमिन टीमने पडताळला",
    log4: "डिलिव्हरी ओटीपी ९९१७ पडताळला — ३० घरगुती व्हेज थाळी बॉक्स पोहोचले",
    unitMeals: "जेवण",
    unitPieces: "तुकडे",
    todayAt: "आज, {t}",
    tomorrowAt: "उद्या, {t}",
    publishErr: "आधी शीर्षक व प्रमाण भरा.",
    closesIn: "संपण्याची वेळ",
    sortSoonest: "लवकर संपणारे आधी",
    quickActions: "झटपट कृती",
    recentDonations: "अलीकडील दाने",
    activeRoute: "सक्रिय मार्ग",
    noClaims: "येथे दिसण्यासाठी एखादी नोंद स्वीकारा.",
    secure: "सुरक्षित सुपूर्दगी",
    statusOpen: "खुले",
    ntClaimedT: "दान स्वीकारले",
    ntClaimedB: "{name} ने {title} स्वीकारले.",
    ntDispatchT: "स्वयंसेवक रवाना",
    ntDispatchB: "{name} ने {title} चा डिस्पॅच स्वीकारला.",
    ntPickupT: "वस्तू पिकअप झाल्या",
    ntPickupB: "{title} साठी पिकअप ओटीपी पडताळला. रायडर वाटेत आहे.",
    ntNewT: "नवीन दान उपलब्ध",
    ntNewB: "{name} ने {area} मध्ये {title} नोंदवले.",
    ntDeliveredT: "डिलिव्हरी निश्चित",
    ntDeliveredB: "{title} {name} पर्यंत पोहोचले.",
    ntApprovedT: "भागीदार मंजूर",
    ntApprovedB: "{name} ने दर्पण व FSSAI पडताळणी पूर्ण केली.",
    ch1T: "अन्न सुरक्षा व स्वच्छता (FSSAI)",
    ch1B: "अतिरिक्त अन्न ताजे शिजवलेले, दूषित नसलेले, सुरक्षित तापमानात (गरम ६०°C पेक्षा जास्त, थंड ५°C पेक्षा कमी) ठेवलेले व अंतिम वेळेपूर्वी गोळा केलेले असावे. केवळ पाहणी सुरक्षा प्रमाणपत्राची जागा घेऊ शकत नाही.",
    ch2T: "स्वच्छ कपड्यांचे मानक",
    ch2B: "कपडे, हिवाळी वस्त्र व चादरी धुतलेले, निर्जंतुक, कोरडे व वापरण्यायोग्य असावेत. फाटलेले, डाग असलेले किंवा निरुपयोगी वस्तू स्वीकारल्या जात नाहीत.",
    ch3T: "शून्य व्यापारीकरण",
    ch3B: "दान केलेल्या वस्तू १००% मोफत आणि केवळ गरजू समुदाय व निवारा रहिवाशांसाठी आहेत. त्यांची विक्री, बदली किंवा व्यावसायिक वापर करण्यास परवानगी नाही.",
    ch4T: "गोपनीयता व लपवलेले पत्ते",
    ch4B: "अधिकृत स्वयंसेवक किंवा पडताळलेल्या निवाऱ्याने डिस्पॅच स्वीकारेपर्यंत दानकर्त्याचा नेमका पत्ता लपवलेला असतो.",
    ch5T: "डिस्पॅच व दुहेरी ओटीपी",
    ch5B: "पिकअप व डिलिव्हरीसाठी अनुक्रमे दानकर्ता व निवाऱ्याकडील ४-अंकी पिन आवश्यक आहे. दोन्ही शिवाय डिलिव्हरी पूर्ण होत नाही.",
  },
  hi: {
    tagline: "ज़्यादा साझा करें. कम बर्बाद करें. ज़रूरत जोड़ें.",
    sub: "अतिरिक्त भोजन और ज़रूरी सामान का रीयल-टाइम पुनर्वितरण",
    home: "होम",
    profile: "प्रोफ़ाइल",
    hello: "नमस्ते",
    goodMorning: "सुप्रभात",
    goodAfternoon: "नमस्कार",
    goodEvening: "शुभ संध्या",
    welcomeBack: "फिर से स्वागत है",
    signSub: "आगे बढ़ने के लिए साइन इन करें, या कोई भूमिका देखने के लिए डेमो प्रोफ़ाइल चुनें।",
    quickSelect: "प्रोफ़ाइल चुनें",
    emailLabel: "ईमेल पता",
    passwordLabel: "पासवर्ड",
    forgot: "पासवर्ड भूल गए?",
    signInAs: "इस रूप में साइन इन",
    noAccount: "FoodBridge पर नए हैं?",
    register: "खाता बनाएँ",
    demoNote: "डेमो संस्करण — सारे रिकॉर्ड इसी डिवाइस पर सिम्युलेटेड हैं। कोई लाइव डेटाबेस जुड़ा नहीं है।",
    signIn: "साइन इन",
    chooseProfile: "तुरंत डेमो प्रवेश",
    credentials: "इस डेमो के लिए जानकारी पहले से भरी है।",
    trustFssai: "FSSAI नियमों के अनुरूप",
    trustVerified: "सत्यापित साझेदार",
    trustOtp: "2-चरणीय OTP सुपुर्दगी",
    charterTitle: "प्लेटफ़ॉर्म और सुरक्षा चार्टर",
    charterSub: "शुरू करने से पहले थोड़ा पढ़ें। ये नियम हर सुपुर्दगी को सुरक्षित और सम्मानजनक रखते हैं।",
    agree1: "मैं FoodBridge की शर्तें, FSSAI खाद्य-सुरक्षा नियम और गोपनीयता चार्टर स्वीकार करता/करती हूँ।",
    agree2: "मैं हर दानकर्ता, स्वयंसेवक, आश्रय साझेदार और लाभार्थी से सम्मान से बात करूँगा/करूँगी।",
    accept: "स्वीकारें और आगे बढ़ें",
    decline: "मना करें और साइन आउट",
    roleDonor: "दानकर्ता",
    roleNgo: "एनजीओ",
    roleVolunteer: "स्वयंसेवक",
    roleAdmin: "एडमिन",
    roleDonorDesc: "रेस्टोरेंट, केटरर और परिवार",
    roleNgoDesc: "आश्रय गृह और सत्यापित एनजीओ",
    roleVolunteerDesc: "राइडर और पिकअप साझेदार",
    roleAdminDesc: "प्लेटफ़ॉर्म संचालन",
    donorDashboard: "दानकर्ता डैशबोर्ड",
    ngoPortal: "एनजीओ पोर्टल",
    volunteerDispatch: "स्वयंसेवक डिस्पैच",
    adminConsole: "एडमिन कंसोल",
    notifications: "सूचनाएँ",
    profileTitle: "प्रोफ़ाइल और सेटिंग्स",
    donateFoodTitle: "अतिरिक्त भोजन दान",
    donateClothesTitle: "कपड़े दान करें",
    createDonation: "दान बनाएँ",
    donateFood: "अतिरिक्त भोजन दान करें",
    donateFoodSub: "पका भोजन, किराना, बेकरी",
    donateClothes: "कपड़े दान करें",
    donateClothesSub: "साफ़, पहनने योग्य सामान",
    myDonations: "मेरे दान",
    viewAll: "सभी देखें",
    newDonation: "नया दान",
    available: "उपलब्ध",
    accepted: "स्वीकृत",
    assigned: "राइडर नियुक्त",
    inTransit: "रास्ते में",
    delivered: "पहुँच गया",
    claims: "दावे",
    distributions: "वितरण",
    verification: "सत्यापन",
    pending: "लंबित",
    allDonations: "सभी",
    surplusFood: "भोजन",
    clothing: "कपड़े",
    expiringSoon: "जल्द बंद होने वाले",
    availableNear: "आपके पास उपलब्ध",
    listings: "लिस्टिंग",
    claimDonation: "यह दान लें",
    claimed: "स्वीकृत",
    yourClaims: "आपके दावे",
    deliveryPinShare: "डिलीवरी पिन — राइडर को दें",
    motorcycle: "मोटरसाइकल डिस्पैचर",
    active: "सक्रिय",
    online: "ऑनलाइन",
    offline: "ऑफ़लाइन",
    availableDispatches: "उपलब्ध डिस्पैच",
    noDispatches: "अभी यहाँ कुछ नहीं है। दानकर्ता के पोस्ट करते ही नई लिस्टिंग दिखेगी।",
    acceptDispatch: "डिस्पैच स्वीकारें",
    enterPickup: "पिकअप पिन डालें",
    enterDelivery: "डिलीवरी पिन डालें",
    inTransitNow: "रास्ते में — अब पहुँचाएँ",
    missions: "पूर्ण मिशन",
    rating: "रेटिंग",
    foodRescue: "भोजन बचाव",
    match: "मिलान",
    collectBy: "संग्रह",
    handling: "रखरखाव",
    overview: "अवलोकन",
    ngoApprovals: "मंजूरी",
    users: "उपयोगकर्ता",
    complaints: "शिकायतें",
    audit: "ऑडिट लॉग",
    analyticsNote: "सारे आँकड़े डेमो रिकॉर्ड से लाइव निकाले जाते हैं।",
    totalListings: "कुल लिस्टिंग",
    foodRescues: "भोजन बचाव",
    clothingItems: "कपड़े",
    deliveriesMade: "पूरी डिलीवरी",
    verifiedNgos: "सत्यापित एनजीओ",
    activeRiders: "सक्रिय राइडर",
    lifecycle: "लाइव दान जीवनचक्र",
    items: "आइटम",
    markAllRead: "सभी पढ़े चिह्नित करें",
    allFilter: "सभी",
    unread: "अपठित",
    switchRole: "भूमिका बदलें",
    preferences: "प्राथमिकताएँ",
    darkMode: "डार्क थीम",
    darkModeSub: "मुलायम काला रंग, रात में आँखों के लिए आसान",
    language: "भाषा",
    chooseLanguage: "अपनी भाषा चुनें",
    chooseLanguageSub: "पूरा डेमो तुरंत बदल जाएगा — पेज रीलोड किए बिना।",
    langSaved: "भाषा बदल गई",
    signOut: "साइन आउट",
    verifiedShelter: "सत्यापित आश्रय एनजीओ",
    tapVerify: "सत्यापन देखें",
    darpan: "दर्पण",
    fssai: "FSSAI लाइसेंस",
    published: "दान नेटवर्क पर प्रकाशित हुआ",
    claimedMsg: "दान स्वीकृत — डिलीवरी पिन अब खुल गया",
    acceptedMsg: "डिस्पैच स्वीकृत — सामान लें और पिकअप पिन सत्यापित करें",
    pickupMsg: "पिकअप सत्यापित — ऑर्डर रास्ते में है",
    deliveredMsg: "डिलीवरी पक्की। ज़रूरत जोड़ने के लिए धन्यवाद।",
    wrongPin: "पिन गलत है। दूसरे व्यक्ति को दिखाया गया पिन डालें।",
    verifyPickupTitle: "पिकअप पिन सत्यापित करें",
    verifyDeliveryTitle: "डिलीवरी पिन की पुष्टि करें",
    pinHint: "दूसरे व्यक्ति के पास का 4-अंकीय पिन डालें।",
    confirm: "पुष्टि करें",
    cancel: "रद्द करें",
    detail: "दान का विवरण",
    pickupArea: "पिकअप क्षेत्र",
    category: "श्रेणी",
    deadline: "संग्रह की अंतिम समय",
    custody: "दोहरी-OTP सुपुर्दगी",
    pickupOtp: "पिकअप OTP",
    deliveryOtp: "डिलीवरी OTP",
    posted: "पोस्ट किया",
    quantity: "मात्रा",
    unit: "इकाई",
    publishedOn: "प्रकाशित",
    photo: "फ़ोटो",
    selectPhoto: "कवर चुनें",
    foodCategory: "भोजन श्रेणी",
    cookedMeals: "पका भोजन",
    rawProduce: "किराना और सब्ज़ी",
    bakery: "बेकरी और डेयरी",
    packaged: "पैकेट और सूखा सामान",
    foodName: "शीर्षक",
    foodNamePh: "जैसे 50 बॉक्स वेज पुलाव और दाल तड़का",
    desc: "विवरण और पैकेजिंग नोट",
    descPh: "जैसे कॉर्पोरेट लंच के लिए पकाया, फ़ॉइल ट्रे में सीलबंद।",
    quantityPh: "जैसे 50",
    dietType: "आहार",
    pureVeg: "शुद्ध शाकाहारी",
    nonVeg: "मांसाहारी",
    holding: "रखने की स्थिति",
    hotHolding: "गरम (>63°C)",
    ambient: "सामान्य तापमान",
    chilled: "ठंडा (<5°C)",
    publishFood: "भोजन लिस्टिंग प्रकाशित करें",
    clothingTitle: "साफ़ कपड़े दान करें",
    clothingSub: "सत्यापित स्थानीय आश्रयों के लिए धुले, पहनने योग्य कपड़े।",
    condition: "स्थिति",
    target: "किसके लिए",
    publishClothes: "कपड़े की लिस्टिंग प्रकाशित करें",
    back: "पीछे",
    impactTitle: "आपका प्रभाव",
    mealsShared: "भोजन साझा",
    kgRescued: "किलो बचाया",
    familiesReached: "परिवार तक",
    verifiedDonor: "सत्यापित दानकर्ता",
    memberSince: "2024 से सदस्य",
    support: "मदद और सहायता",
    version: "संस्करण 2.0 · डेमो",
    pickup: "पिकअप",
    dropoff: "ड्रॉप-ऑफ़",
    distance: "दूरी",
    eta: "अनुमानित समय",
    min: "मिनट",
    route: "रास्ता",
    statusMix: "लिस्टिंग की स्थिति",
    recentActivity: "हाल की गतिविधि",
    pendingApprovals: "लंबित मंजूरी",
    openTickets: "खुली शिकायतें",
    health: "समय पर सुपुर्दगी",
    thisWeek: "इस हफ़्ते",
    awaitingReview: "दर्पण और FSSAI दस्तावेज़ अपलोड — समीक्षा लंबित",
    approve: "मंज़ूर करें",
    approvedMsg: "एनजीओ मंज़ूर — सत्यापन बैज जारी",
    noApprovals: "कोई लंबित मंजूरी नहीं। सभी साझेदार सत्यापित हैं।",
    complaintTitle: "देर से पिकअप की शिकायत",
    complaintBody: "शिकायत #CMP-104 · 60 फल हैम्पर की संग्रह समय-सीमा बीत गई। राइडर बदला गया।",
    log1: "रोहित कुलकर्णी ने 60 फल और स्नैक हैम्पर का डिस्पैच स्वीकारा",
    log2: "आशा चिल्ड्रन फ़ाउंडेशन ने 40 चपाती और पनीर भुर्जी कॉम्बो लिए",
    log3: "सिम्बायोसिस कैंपस कैफ़ेटेरिया का FSSAI लाइसेंस एडमिन टीम ने सत्यापित किया",
    log4: "डिलीवरी OTP 9917 सत्यापित — 30 घर जैसे वेज थाली बॉक्स पहुँचे",
    unitMeals: "भोजन",
    unitPieces: "पीस",
    todayAt: "आज, {t}",
    tomorrowAt: "कल, {t}",
    publishErr: "पहले शीर्षक और मात्रा भरें।",
    closesIn: "बंद होने का समय",
    sortSoonest: "जल्द बंद होने वाले पहले",
    quickActions: "तुरंत काम",
    recentDonations: "हाल के दान",
    activeRoute: "सक्रिय रास्ता",
    noClaims: "यहाँ दिखाने के लिए कोई लिस्टिंग लें।",
    secure: "सुरक्षित सुपुर्दगी",
    statusOpen: "खुला",
    ntClaimedT: "दान स्वीकृत",
    ntClaimedB: "{name} ने {title} लिया।",
    ntDispatchT: "स्वयंसेवक रवाना",
    ntDispatchB: "{name} ने {title} का डिस्पैच स्वीकारा।",
    ntPickupT: "सामान उठाया गया",
    ntPickupB: "{title} के लिए पिकअप OTP सत्यापित। राइडर रास्ते में है।",
    ntNewT: "नया दान उपलब्ध",
    ntNewB: "{name} ने {area} में {title} पोस्ट किया।",
    ntDeliveredT: "डिलीवरी पक्की",
    ntDeliveredB: "{title} {name} तक पहुँचा।",
    ntApprovedT: "साझेदार मंज़ूर",
    ntApprovedB: "{name} ने दर्पण और FSSAI सत्यापन पूरा किया।",
    ch1T: "खाद्य सुरक्षा और स्वच्छता (FSSAI)",
    ch1B: "अतिरिक्त भोजन ताज़ा पका, दूषित रहित, सुरक्षित तापमान पर (गरम 60°C से ऊपर, ठंडा 5°C से नीचे) और समय-सीमा से पहले उठाया गया होना चाहिए। सिर्फ़ देखकर जाँच सुरक्षा प्रमाणन की जगह नहीं ले सकती।",
    ch2T: "साफ़ कपड़ों के मानक",
    ch2B: "कपड़े, सर्दियों के कपड़े और कंबल धुले, कीटाणुरहित, सूखे और पहनने योग्य होने चाहिए। फटे, दाग़दार या बेकार सामान स्वीकार नहीं किया जाता।",
    ch3T: "शून्य व्यावसायीकरण",
    ch3B: "दान किया गया सामान 100% मुफ़्त है और केवल ज़रूरतमंद समुदायों और आश्रय निवासियों के लिए है। उसे बेचना, बदलना या उससे कमाना मना है।",
    ch4T: "निजता और छिपे पते",
    ch4B: "दानकर्ता का सटीक पता तब तक छिपा रहता है जब तक अधिकृत स्वयंसेवक या सत्यापित आश्रय डिस्पैच स्वीकार न करे।",
    ch5T: "डिस्पैच और दोहरी OTP",
    ch5B: "पिकअप और डिलीवरी के लिए क्रमशः दानकर्ता और आश्रय के पास का 4-अंकीय पिन ज़रूरी है। दोनों के बिना डिलीवरी पूरी नहीं होती।",
  },
};

/* Localized demo records — proper nouns (people, businesses) stay as they are. */
const DATA_I18N = {
  mr: {
    d1: { title: "५० व्हेज बिर्याणी मील बॉक्स", area: "कॅम्प, पुणे", category: "शिजवलेले जेवण", diet: "शुद्ध व्हेज", holding: "गरम ठेवलेले (>६३°C)", notes: "कॉर्पोरेट लंचसाठी ताजे शिजवलेले. फॉइल ट्रेमध्ये सीलबंद." },
    d2: { title: "३५ पोहे व उपमा न्याहारी पॅकेट", area: "कॅम्प, पुणे", category: "शिजवलेले जेवण", diet: "शुद्ध व्हेज", holding: "सामान्य तापमान", notes: "फूड-ग्रेड पेपर बॉक्समध्ये पॅक, अजूनही गरम." },
    d3: { title: "२५ हिवाळी जॅकेट व लोकरीच्या चादरी", area: "कॅम्प, पुणे", category: "स्वच्छ वापरण्यायोग्य वस्तू", condition: "सौम्य वापरलेले", target: "मुले", notes: "धुतलेले, निर्जंतुक, कोरडे व कार्टनमध्ये पॅक." },
    d4: { title: "४० चपाती व पनीर भुर्जी कॉम्बो", area: "कॅम्प, पुणे", category: "शिजवलेले जेवण", diet: "शुद्ध व्हेज", holding: "गरम ठेवलेले (>६३°C)", notes: "निवाऱ्यासाठी सीलबंद डब्यांमध्ये पॅक." },
    d5: { title: "६० फळ व स्नॅक हॅम्पर", area: "कोरेगाव पार्क, पुणे", category: "पॅकबंद व कोरडे", diet: "शुद्ध व्हेज", holding: "सामान्य तापमान", notes: "बँक्वेट काउंटरवरील सीलबंद हॅम्पर." },
    d6: { title: "३० घरगुती व्हेज थाळी बॉक्स", area: "डेक्कन, पुणे", category: "शिजवलेले जेवण", diet: "शुद्ध व्हेज", holding: "गरम ठेवलेले (>६३°C)", notes: "निवाऱ्याच्या किचनकडे सुपूर्द केले." },
    d7: { title: "२० शाळेचे गणवेश संच", area: "कोथरूड, पुणे", category: "स्वच्छ वापरण्यायोग्य वस्तू", condition: "नव्यासारखे", target: "मुले", notes: "इस्त्री करून नव्या सत्रासाठी पॅक." },
  },
  hi: {
    d1: { title: "50 वेज बिरयानी मील बॉक्स", area: "कैंप, पुणे", category: "पका भोजन", diet: "शुद्ध शाकाहारी", holding: "गरम रखा (>63°C)", notes: "कॉर्पोरेट लंच के लिए ताज़ा पकाया। फ़ॉइल ट्रे में सीलबंद।" },
    d2: { title: "35 पोहा और उपमा नाश्ता पैकेट", area: "कैंप, पुणे", category: "पका भोजन", diet: "शुद्ध शाकाहारी", holding: "सामान्य तापमान", notes: "फ़ूड-ग्रेड पेपर बॉक्स में पैक, अब भी गरम।" },
    d3: { title: "25 सर्दियों की जैकेट और ऊनी कंबल", area: "कैंप, पुणे", category: "साफ़ पहनने योग्य सामान", condition: "हल्का इस्तेमाल", target: "बच्चे", notes: "धुले, कीटाणुरहित, सूखे और कार्टन में पैक।" },
    d4: { title: "40 चपाती और पनीर भुर्जी कॉम्बो", area: "कैंप, पुणे", category: "पका भोजन", diet: "शुद्ध शाकाहारी", holding: "गरम रखा (>63°C)", notes: "आश्रय के लिए सीलबंद डिब्बों में पैक।" },
    d5: { title: "60 फल और स्नैक हैम्पर", area: "कोरेगाँव पार्क, पुणे", category: "पैकेट और सूखा सामान", diet: "शुद्ध शाकाहारी", holding: "सामान्य तापमान", notes: "बैंक्वेट काउंटर के सीलबंद हैम्पर।" },
    d6: { title: "30 घर जैसे वेज थाली बॉक्स", area: "डेक्कन, पुणे", category: "पका भोजन", diet: "शुद्ध शाकाहारी", holding: "गरम रखा (>63°C)", notes: "आश्रय की रसोई को सौंपा गया।" },
    d7: { title: "20 स्कूल यूनिफ़ॉर्म सेट", area: "कोथरूड, पुणे", category: "साफ़ पहनने योग्य सामान", condition: "नए जैसे", target: "बच्चे", notes: "इस्त्री करके नए सत्र के लिए पैक।" },
  },
};

const ROLES = {
  donor: {
    name: "Vikram Joshi", org: "The Green Leaf Bistro", email: "donor@foodbridge.org",
    phone: "+91 98200 12345", initial: "V", icon: "bowl", key: "donorDashboard",
  },
  ngo: {
    name: "Sunita Rao", org: "Asha Children Foundation", email: "ngo@foodbridge.org",
    phone: "+91 98220 44551", initial: "S", icon: "building", key: "ngoPortal",
    darpan: "MH/2019/0219482", fssai: "11522998000123",
  },
  volunteer: {
    name: "Yogesh Chavan", org: "Motorcycle Dispatcher", email: "volunteer@foodbridge.org",
    phone: "+91 74988 55751", initial: "Y", icon: "bike", key: "volunteerDispatch",
  },
  admin: {
    name: "Neha Deshmukh", org: "Platform Administrator", email: "admin@foodbridge.org",
    phone: "+91 90110 22334", initial: "N", icon: "shield", key: "adminConsole",
  },
};

const SEED = [
  { id: "d1", title: "50 Veg Biryani Meal Boxes", kind: "food", qty: 50, unit: "meals",
    donor: "The Green Leaf Bistro", area: "Camp, Pune", distance: "3.8 km", status: "available",
    pickupOtp: "8247", deliveryOtp: "4606", deadline: "10:55 AM", category: "Cooked Meals",
    diet: "Pure Veg", holding: "Hot-Holding (>63°C)",
    notes: "Freshly cooked for corporate lunch. Sealed in foil meal trays." },
  { id: "d2", title: "35 Poha & Upma Breakfast Packets", kind: "food", qty: 35, unit: "meals",
    donor: "Symbiosis Campus Cafeteria", area: "Camp, Pune", distance: "3.8 km", status: "available",
    pickupOtp: "1070", deliveryOtp: "1605", deadline: "11:55 AM", category: "Cooked Meals",
    diet: "Pure Veg", holding: "Ambient Room Temp",
    notes: "Packed in food-grade paper boxes, still warm." },
  { id: "d3", title: "25 Winter Jackets & Woolen Blankets", kind: "clothes", qty: 25, unit: "pieces",
    donor: "Rahul & Meera Sharma", area: "Camp, Pune", distance: "3.8 km", status: "available",
    pickupOtp: "5521", deliveryOtp: "3390", deadline: "07:55 AM",
    category: "Clean Wearable Essentials", condition: "Gently Used", target: "Kids",
    notes: "Washed, sanitized, dry and packed in cartons." },
  { id: "d4", title: "40 Chapati & Paneer Bhurji Combos", kind: "food", qty: 40, unit: "meals",
    donor: "The Green Leaf Bistro", area: "Camp, Pune", distance: "3.8 km", status: "claimed",
    claimedBy: "Asha Children Foundation", pickupOtp: "6142", deliveryOtp: "7781",
    deadline: "11:17 AM", category: "Cooked Meals", diet: "Pure Veg",
    holding: "Hot-Holding (>63°C)", notes: "Packed in sealed tiffins for the shelter." },
  { id: "d5", title: "60 Assorted Fruit & Snack Hampers", kind: "food", qty: 60, unit: "meals",
    donor: "Grand Hyatt Convention", area: "Koregaon Park, Pune", distance: "5.2 km", status: "assigned",
    claimedBy: "Asha Children Foundation", rider: "Rohit Kulkarni", pickupOtp: "2093",
    deliveryOtp: "8845", deadline: "12:30 PM", category: "Packaged / Dry Goods",
    diet: "Pure Veg", holding: "Ambient Room Temp", notes: "Sealed hampers from the banquet counter." },
  { id: "d6", title: "30 Home-Style Veg Thali Boxes", kind: "food", qty: 30, unit: "meals",
    donor: "Annapurna Caterers", area: "Deccan, Pune", distance: "4.1 km", status: "distributed",
    claimedBy: "Asha Children Foundation", rider: "Yogesh Chavan", pickupOtp: "3301",
    deliveryOtp: "9917", deadline: "—", category: "Cooked Meals", diet: "Pure Veg",
    holding: "Hot-Holding (>63°C)", notes: "Handed over to the shelter kitchen." },
  { id: "d7", title: "20 School Uniform Sets", kind: "clothes", qty: 20, unit: "pieces",
    donor: "Chavan Family", area: "Kothrud, Pune", distance: "6.0 km", status: "distributed",
    claimedBy: "Asha Children Foundation", rider: "Yogesh Chavan", pickupOtp: "7712",
    deliveryOtp: "4419", deadline: "—", category: "Clean Wearable Essentials",
    condition: "Like New", target: "Kids", notes: "Ironed and packed for the new term." },
];

const SEED_NOTIFS = [
  { id: "n1", icon: "handshake", titleKey: "ntClaimedT", bodyKey: "ntClaimedB",
    params: { name: "Asha Children Foundation", titleId: "d1" },
    time: "07:51 AM", unread: true, tone: "green" },
  { id: "n2", icon: "bike", titleKey: "ntDispatchT", bodyKey: "ntDispatchB",
    params: { name: "Rohit Kulkarni", titleId: "d5" },
    time: "07:38 AM", unread: true, tone: "green" },
  { id: "n3", icon: "package", titleKey: "ntPickupT", bodyKey: "ntPickupB",
    params: { titleId: "d4" },
    time: "07:14 AM", unread: false, tone: "blue" },
  { id: "n4", icon: "bowl", titleKey: "ntNewT", bodyKey: "ntNewB",
    params: { name: "The Green Leaf Bistro", titleId: "d1", areaId: "d1" },
    time: "06:56 AM", unread: false, tone: "amber" },
];

/* Minimal line-icon set — hand-drawn geometry, no icon font or emoji. */
const ICONS = {
  home: '<path d="M4 11.4 12 4.2l8 7.2V20a1 1 0 0 1-1 1h-4.4v-5.6H9.4V21H5a1 1 0 0 1-1-1z"/>',
  bell: '<path d="M6.2 9.4a5.8 5.8 0 0 1 11.6 0c0 3.6 1.2 4.9 1.9 5.7.3.4 0 1-.5 1H4.8c-.5 0-.8-.6-.5-1 .7-.8 1.9-2.1 1.9-5.7z"/><path d="M9.8 19.4a2.4 2.4 0 0 0 4.4 0"/>',
  user: '<circle cx="12" cy="8.2" r="3.6"/><path d="M4.8 20.2c.4-3.6 3.4-5.6 7.2-5.6s6.8 2 7.2 5.6"/>',
  sun: '<circle cx="12" cy="12" r="4"/><path d="M12 2.6v2M12 19.4v2M2.6 12h2M19.4 12h2M5.4 5.4l1.4 1.4M17.2 17.2l1.4 1.4M18.6 5.4l-1.4 1.4M6.8 17.2l-1.4 1.4"/>',
  moon: '<path d="M20.3 14.6A8.6 8.6 0 0 1 9.4 3.7a8.6 8.6 0 1 0 10.9 10.9z"/>',
  globe: '<circle cx="12" cy="12" r="8.6"/><path d="M3.6 12h16.8M12 3.4c2.4 2.4 3.6 5.3 3.6 8.6S14.4 18.2 12 20.6c-2.4-2.4-3.6-5.3-3.6-8.6S9.6 5.8 12 3.4z"/>',
  chevronLeft: '<path d="M14.5 5.5 8 12l6.5 6.5"/>',
  chevronRight: '<path d="M9.5 5.5 16 12l-6.5 6.5"/>',
  bowl: '<path d="M3.4 11.2h17.2c-.4 4.6-3.9 7.5-8.6 7.5s-8.2-2.9-8.6-7.5z"/><path d="M9 7.8c0-1.4 1.4-1.8 1.4-3.2M13.8 7.8c0-1.4 1.4-1.8 1.4-3.2"/>',
  shirt: '<path d="M8.4 3.6 4 6l1.6 4 2.2-.9V20a.8.8 0 0 0 .8.8h6.8a.8.8 0 0 0 .8-.8v-10.9l2.2.9L20 6l-4.4-2.4-1.5 1.1a2.6 2.6 0 0 1-4.2 0z"/>',
  package: '<path d="M12 3.4 3.8 7.6v8.8L12 20.6l8.2-4.2V7.6z"/><path d="M3.8 7.6 12 11.8l8.2-4.2M12 11.8v8.8"/>',
  check: '<path d="M5 12.6 9.4 17 19 6.6"/>',
  shield: '<path d="M12 3.2 19 6v5.8c0 4.4-2.9 7.3-7 8.9-4.1-1.6-7-4.5-7-8.9V6z"/><path d="m9 12 2.2 2.2L15.4 10"/>',
  bike: '<circle cx="5.5" cy="17.2" r="2.9"/><circle cx="18.5" cy="17.2" r="2.9"/><path d="M8.4 17.2h5.2l2.3-5.4 2.6 5.4M13.6 17.2 10 8.4h3.2M8.6 8.4h3.6"/>',
  building: '<path d="M4.6 20.6V5.4a.9.9 0 0 1 .9-.9h8.4a.9.9 0 0 1 .9.9v15.2M14.8 10h3.7a.9.9 0 0 1 .9.9v9.7"/><path d="M3 20.6h18M7.8 8.4h4M7.8 12h4M7.8 15.6h4"/>',
  clock: '<circle cx="12" cy="12" r="8.4"/><path d="M12 7.4V12l3 1.8"/>',
  star: '<path d="m12 4 2.4 4.9 5.4.8-3.9 3.8.9 5.4-4.8-2.6-4.8 2.6.9-5.4L4.2 9.7l5.4-.8z"/>',
  pin: '<path d="M12 21s6.6-6 6.6-10.6a6.6 6.6 0 1 0-13.2 0C5.4 15 12 21 12 21z"/><circle cx="12" cy="10.2" r="2.4"/>',
  plus: '<path d="M12 5v14M5 12h14"/>',
  x: '<path d="M6.4 6.4l11.2 11.2M17.6 6.4 6.4 17.6"/>',
  truck: '<path d="M3.4 6.6h10.2v9.2H3.4zM13.6 10h4l3 3v2.8h-7z"/><circle cx="7.2" cy="18" r="1.8"/><circle cx="17.4" cy="18" r="1.8"/>',
  users: '<circle cx="9.2" cy="8.4" r="3.2"/><path d="M3 19.4c.3-3.1 2.9-4.9 6.2-4.9s5.9 1.8 6.2 4.9"/><path d="M16.2 5.6a3 3 0 0 1 0 5.7M17.6 14.9c1.9.4 3.2 1.7 3.4 3.8"/>',
  file: '<path d="M13.4 3.4H6.8a1 1 0 0 0-1 1v15.2a1 1 0 0 0 1 1h10.4a1 1 0 0 0 1-1V8.2z"/><path d="M13.4 3.4v4.8h4.8M8.6 12.4h6.8M8.6 16h4.6"/>',
  alert: '<path d="M12 4.2 21 19.8H3z"/><path d="M12 9.6v4.2M12 17.2h.01"/>',
  logout: '<path d="M15 12H4M8.4 8 4.4 12l4 4M13.6 4.4H19a1 1 0 0 1 1 1v13.2a1 1 0 0 1-1 1h-5.4"/>',
  leaf: '<path d="M4.6 19.4C4.6 11.6 10.6 5.6 19.8 4.6c1 9.2-5 15.2-12.8 15.2z"/><path d="M4.6 19.4c3.2-4.6 6.8-7.4 11.2-9"/>',
  handshake: '<path d="M3.4 12.6 6.8 9l3.6 1.8 2-1.6 2.2 1.6L18 9l2.6 3.6"/><path d="M6.8 9V6.6h10.4V9M6.8 14.4l2.6 2.6 2.6-2.6 2.4 1.8"/>',
  wallet: '<path d="M4.2 7.6A2 2 0 0 1 6.2 5.6h11.6A2 2 0 0 1 19.8 7.6v10.8a2 2 0 0 1-2 2H6.2a2 2 0 0 1-2-2z"/><path d="M4.2 10.4h15.6M15.2 14.6h2"/>',
  search: '<circle cx="10.8" cy="10.8" r="6.4"/><path d="m15.6 15.6 4 4"/>',
  spark: '<path d="M12 3.6 13.8 9l5.4 1.8-5.4 1.8L12 18l-1.8-5.4L4.8 10.8 10.2 9z"/>',
  arrow: '<path d="M4.4 12h15M13.8 6.4 19.4 12l-5.6 5.6"/>',
};
function ic(name, cls) {
  const body = ICONS[name] || ICONS.spark;
  return `<svg class="ic-svg ${cls || ""}" viewBox="0 0 24 24" aria-hidden="true">${body}</svg>`;
}

/* ---------------- state ---------------- */
function freshState() {
  return {
    donations: JSON.parse(JSON.stringify(SEED)),
    notifs: JSON.parse(JSON.stringify(SEED_NOTIFS)),
    lang: "en", theme: "light", role: null, tab: "home",
    route: null, activeDonation: null, sheet: null,
    adminTab: "overview", ngoFilter: "all", notifFilter: "all",
    charter: {}, online: true, tasks: 41, rating: "5.0",
    impact: { meals: 1280, kg: 96, families: 340 },
    orgApprovals: ["Pune Food Bank (NGO)", "Roti Ghar Trust (Caterer)"],
  };
}

function load() {
  try {
    const raw = localStorage.getItem(STORE_KEY);
    if (raw) {
      const s = JSON.parse(raw);
      if (s && Array.isArray(s.donations)) return Object.assign(freshState(), s);
    }
  } catch (_) {}
  return freshState();
}

let state = load();
const t = (k) => {
  const lang = I18N[state.lang] || I18N.en;
  return lang[k] != null ? lang[k] : (I18N.en[k] != null ? I18N.en[k] : k);
};
const fmt = (s, p) => String(s).replace(/\{(\w+)\}/g, (m, k) => (p && p[k] != null ? p[k] : m));
const save = () => { try { localStorage.setItem(STORE_KEY, JSON.stringify(state)); } catch (_) {} };
const esc = (v) => String(v == null ? "" : v).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]));
const byId = (id) => state.donations.find((d) => d.id === id);
const roleLabel = (k) => t(k === "donor" ? "roleDonor" : k === "ngo" ? "roleNgo" : k === "volunteer" ? "roleVolunteer" : "roleAdmin");

/* demo text lookup: localized when a translation exists, source text otherwise */
const dfield = (d, field) => {
  const m = (DATA_I18N[state.lang] || {})[d.id];
  return (m && m[field] != null) ? m[field] : (d[field] || "");
};
const qtyLabel = (d) => `${d.qty} ${d.unit === "pieces" ? t("unitPieces") : t("unitMeals")}`;

function counts() {
  const c = { all: state.donations.length, available: 0, claimed: 0, assigned: 0, in_transit: 0, distributed: 0 };
  state.donations.forEach((d) => { c[d.status] = (c[d.status] || 0) + 1; });
  return c;
}

function statusPill(d) {
  const map = {
    available: ["amber", t("available")],
    claimed: ["green", t("accepted")],
    assigned: ["purple", t("assigned")],
    in_transit: ["blue", t("inTransit")],
    distributed: ["grey", t("delivered")],
  };
  const [cls, label] = map[d.status] || ["grey", d.status];
  return `<span class="pill ${cls}">${label}</span>`;
}

const kindIcon = (d) => (d.kind === "clothes" ? "shirt" : "bowl");
const notifTitle = (n) => (n.titleKey ? t(n.titleKey) : n.title);
function notifBody(n) {
  if (!n.bodyKey) return n.body;
  const p = Object.assign({}, n.params);
  if (p.titleId) {
    const d = byId(p.titleId);
    if (d) p.title = dfield(d, "title");
  }
  if (p.areaId) {
    const d = byId(p.areaId);
    if (d) p.area = dfield(d, "area");
  }
  return fmt(t(n.bodyKey), p);
}

function pushNotif(icon, titleKey, bodyKey, params, tone) {
  const time = new Date().toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })
    .replace(/\b(am|pm)\b/i, (m) => m.toUpperCase());
  state.notifs.unshift({ id: "n" + Date.now(), icon, titleKey, bodyKey, params, time, unread: true, tone });
}

/* ---------------- render ---------------- */
let lastViewKey = "";

function viewKey() {
  return [state.role, state.tab, state.route, state.activeDonation, state.adminTab,
    state.ngoFilter, state.notifFilter, state.sheet ? `${state.sheet.type}:${state.sheet.id || ""}` : "", state.lang, state.theme]
    .join("|");
}

function render() {
  document.documentElement.dataset.theme = state.theme;
  document.documentElement.lang = state.lang;
  const app = document.getElementById("app");
  if (!state.role) { app.innerHTML = loginView(); return; }

  const nav = [
    { id: "home", ic: "home" },
    { id: "notifications", ic: "bell" },
    { id: "profile", ic: "user" },
  ].map((n) => `<button class="tab ${state.tab === n.id && !state.route ? "active" : ""}" data-act="tab" data-tab="${n.id}" aria-label="${t(n.id)}">
      <span class="ic">${ic(n.ic)}</span><span>${t(n.id)}</span>
    </button>`).join("");

  app.innerHTML = `
    ${topbarView()}
    <div class="scroll" id="scroll">${state.route ? routeView() : bodyView()}</div>
    ${state.tab === "home" && !state.route && state.role === "donor" ? `<button class="fab" data-act="route" data-route="donate-food">${ic("plus", "sm")} ${t("newDonation")}</button>` : ""}
    <nav class="tabbar">${nav}</nav>
    ${!state.charter[state.role] ? charterView() : ""}
    ${state.sheet ? sheetView() : ""}
    <div class="toast" id="toast"></div>`;

  const key = viewKey();
  const changed = key !== lastViewKey;
  lastViewKey = key;
  const scroller = document.getElementById("scroll");
  if (scroller && changed) {
    scroller.scrollTop = 0;
    scroller.classList.add("view-in");
    clearTimeout(window.__viewTimer);
    window.__viewTimer = setTimeout(() => scroller.classList.remove("view-in"), 620);
  }
}

const LANG_META = [["en", "English", "English"], ["mr", "मराठी", "Marathi"], ["hi", "हिंदी", "Hindi"]];

function topbarView() {
  const r = ROLES[state.role];
  let title = t(r.key);
  if (state.route === "donate-food") title = t("donateFoodTitle");
  if (state.route === "donate-clothes") title = t("donateClothesTitle");
  if (state.route === "detail") title = t("detail");
  if (!state.route && state.tab === "notifications") title = t("notifications");
  if (!state.route && state.tab === "profile") title = t("profileTitle");
  const unread = state.notifs.filter((n) => n.unread).length;

  return `
    <header class="topbar">
      ${state.route ? `<button class="icon-btn" data-act="back" aria-label="${t("back")}">${ic("chevronLeft")}</button>` : ""}
      <div class="grow">
        ${state.route ? "" : `<div class="eyebrow">${roleLabel(state.role)} · FoodBridge</div>`}
        <h1 class="title">${title}</h1>
      </div>
      <button class="icon-btn lang-btn" data-act="sheet-lang" title="${t("language")}" aria-label="${t("language")}">${state.lang.toUpperCase()}</button>
      <button class="icon-btn" data-act="theme" title="${t("darkMode")}" aria-label="${t("darkMode")}">${ic(state.theme === "dark" ? "sun" : "moon")}</button>
      <button class="icon-btn" data-act="tab" data-tab="notifications" title="${t("notifications")}" style="position:relative">${ic("bell")}
        ${unread ? `<span class="badge">${unread}</span>` : ""}
      </button>
      <button class="avatar sm" data-act="tab" data-tab="profile" aria-label="${t("profileTitle")}">${r.initial}</button>
    </header>`;
}

function bodyView() {
  if (state.tab === "notifications") return notificationsView();
  if (state.tab === "profile") return profileView();
  if (state.role === "donor") return donorHome();
  if (state.role === "ngo") return ngoHome();
  if (state.role === "volunteer") return volunteerHome();
  return adminHome();
}

function routeView() {
  if (state.route === "donate-food") return donateFoodView();
  if (state.route === "donate-clothes") return donateClothesView();
  return detailView(byId(state.activeDonation));
}

function langSwitch(compact) {
  return `<div class="lang-switch ${compact ? "compact" : ""}" role="group" aria-label="${t("language")}">
    ${LANG_META.map(([code, label, en]) => `<button data-act="set-lang" data-lang="${code}" class="${state.lang === code ? "active" : ""}" title="${en}">${label}</button>`).join("")}
  </div>`;
}

/* ---------------- login + charter ---------------- */
function loginView() {
  return `
  <div class="login">
    <div class="login-top">
      <div class="brand">
        <div class="brand-mark">${bridgeMark()}</div>
        <div>
          <h1 class="brand-name">FoodBridge</h1>
          <p class="brand-sub">${t("sub")}</p>
        </div>
      </div>
      <div class="row" style="gap:8px">
        <button class="icon-btn" data-act="theme" aria-label="${t("darkMode")}">${ic(state.theme === "dark" ? "sun" : "moon")}</button>
      </div>
    </div>

    <div class="login-hero">
      <h2 class="login-title">${t("welcomeBack")}</h2>
      <p class="login-lead">${t("signSub")}</p>
      <div class="trust-row">
        <span>${ic("shield", "xs")} ${t("trustFssai")}</span>
        <span>${ic("check", "xs")} ${t("trustVerified")}</span>
        <span>${ic("pin", "xs")} ${t("trustOtp")}</span>
      </div>
    </div>

    <div class="lang-switch-wrap">
      <span class="tiny muted">${t("language")}</span>
      ${langSwitch()}
    </div>

    <div>
      <div class="group-label" style="margin:0 0 8px">${t("chooseProfile")}</div>
      <div class="role-grid">
        ${Object.keys(ROLES).map((k) => `<button class="role-card ${k === "donor" ? "active" : ""}" data-act="login" data-role="${k}">
          <span class="ri">${ic(ROLES[k].icon)}</span>
          <b>${roleLabel(k)}</b>
          <span>${t("role" + (k === "donor" ? "Donor" : k === "ngo" ? "Ngo" : k === "volunteer" ? "Volunteer" : "Admin") + "Desc")}</span>
        </button>`).join("")}
      </div>
    </div>

    <div class="field"><label>${t("emailLabel")}</label>
      <input id="login-email" value="donor@foodbridge.org" autocomplete="off" />
    </div>
    <div class="field"><label>${t("passwordLabel")}</label>
      <input id="login-password" type="password" value="Password123!" autocomplete="off" />
      <div style="text-align:right"><a class="link small" href="#" data-act="noop">${t("forgot")}</a></div>
    </div>

    <button class="btn block" data-act="login" data-role="donor">${t("signIn")}</button>
    <p class="hint">${t("noAccount")} <a class="link" href="#" data-act="noop">${t("register")}</a></p>
    <p class="hint demo-note">${ic("shield", "xs")} ${t("demoNote")}</p>
  </div>`;
}

const CHARTER = [
  { n: 1, ic: "bowl" },
  { n: 2, ic: "shirt" },
  { n: 3, ic: "wallet" },
  { n: 4, ic: "pin" },
  { n: 5, ic: "bike" },
];

function charterView() {
  return `
  <div class="overlay center">
    <div class="charter card">
      <div class="charter-head">
        <div class="charter-icon">${ic("shield")}</div>
        <div>
          <h3>${t("charterTitle")}</h3>
          <p class="small muted" style="margin:3px 0 0">${t("charterSub")}</p>
        </div>
      </div>
      <div class="charter-list">
        ${CHARTER.map((c) => `
          <div class="charter-row">
            <div class="charter-row-ic">${ic(c.ic, "sm")}</div>
            <div><b>${c.n}. ${t("ch" + c.n + "T")}</b><p>${t("ch" + c.n + "B")}</p></div>
          </div>`).join("")}
      </div>
      <label class="check"><input type="checkbox" id="chk1" /> <span>${t("agree1")}</span></label>
      <label class="check"><input type="checkbox" id="chk2" /> <span>${t("agree2")}</span></label>
      <div class="charter-actions">
        <button class="link danger" data-act="charter-decline">${t("decline")}</button>
        <button class="btn" data-act="charter-accept" disabled>${t("accept")}</button>
      </div>
    </div>
  </div>`;
}

function sheetView() {
  if (state.sheet.type === "lang") {
    return `
    <div class="overlay">
      <div class="sheet">
        <div class="sheet-head"><h3>${t("chooseLanguage")}</h3><button class="icon-btn" data-act="sheet-close" aria-label="${t("cancel")}">${ic("x", "sm")}</button></div>
        <p class="small muted" style="margin:0 0 14px">${t("chooseLanguageSub")}</p>
        <div class="lang-list">
          ${LANG_META.map(([code, label, en]) => `<button class="lang-opt ${state.lang === code ? "active" : ""}" data-act="set-lang" data-lang="${code}">
            <b>${label}</b><span>${en}</span>${state.lang === code ? ic("check", "sm") : ""}
          </button>`).join("")}
        </div>
      </div>
    </div>`;
  }
  const s = state.sheet;
  const d = byId(s.id);
  const isPickup = s.type === "pickup";
  return `
  <div class="overlay">
    <div class="sheet">
      <h3>${isPickup ? t("verifyPickupTitle") : t("verifyDeliveryTitle")}</h3>
      <p class="small muted" style="margin:0 0 14px">${esc(d ? dfield(d, "title") : "")} · ${t("pinHint")}</p>
      <input class="pin-input" id="pin" inputmode="numeric" maxlength="4" placeholder="••••" autocomplete="one-time-code" />
      <p class="err" id="pin-err" hidden>${t("wrongPin")}</p>
      <div class="row" style="margin-top:16px;gap:10px">
        <button class="btn ghost grow" data-act="sheet-close">${t("cancel")}</button>
        <button class="btn grow" data-act="pin-submit" data-type="${s.type}" data-id="${s.id}">${t("confirm")}</button>
      </div>
    </div>
  </div>`;
}

/* ---------------- donor ---------------- */
function greeting() {
  const h = new Date().getHours();
  return t(h < 12 ? "goodMorning" : h < 17 ? "goodAfternoon" : "goodEvening");
}

function donorHome() {
  const mine = state.donations.filter((d) => d.donor === ROLES.donor.org);
  const live = mine.filter((d) => d.status !== "distributed").length;
  const imp = state.impact;
  return `
    <div class="hero-card">
      <div class="hero-top">
        <span class="hero-tag">${roleLabel("donor")}</span>
        <span class="hero-badge">${ic("check", "xs")} ${t("verifiedDonor")}</span>
      </div>
      <h3>${greeting()}, ${ROLES.donor.name.split(" ")[0]}</h3>
      <p>${ROLES.donor.org}${live ? ` · ${live} ${t("active").toLowerCase()}` : ""}<br>${t("tagline")}</p>
      <div class="hero-impact">
        <div><b>${imp.meals.toLocaleString("en-IN")}</b><span>${t("mealsShared")}</span></div>
        <div><b>${imp.kg}</b><span>${t("kgRescued")}</span></div>
        <div><b>${imp.families}</b><span>${t("familiesReached")}</span></div>
      </div>
    </div>

    <div class="section-title"><span class="dot"></span>${t("createDonation")}</div>
    <div class="donate-grid">
      <button class="donate-btn" data-act="route" data-route="donate-food">
        <span class="donate-ic food">${ic("bowl")}</span>
        <b>${t("donateFood")}</b>
        <span>${t("donateFoodSub")}</span>
      </button>
      <button class="donate-btn" data-act="route" data-route="donate-clothes">
        <span class="donate-ic cloth">${ic("shirt")}</span>
        <b>${t("donateClothes")}</b>
        <span>${t("donateClothesSub")}</span>
      </button>
    </div>

    <div class="section-title">
      <span class="dot"></span>${t("myDonations")} (${mine.length})
      <span style="flex:1"></span>
      <span class="small muted">${t("viewAll")}</span>
    </div>
    <div class="list">
      ${mine.map(donationRow).join("")}
    </div>
    <div style="height:56px"></div>`;
}

/* ---------------- NGO ---------------- */
function ngoHome() {
  const available = state.donations.filter((d) => d.status === "available");
  const claims = state.donations.filter((d) => d.claimedBy === ROLES.ngo.org);
  const distributed = claims.filter((d) => d.status === "distributed").length;
  const filters = [
    ["all", `${t("allDonations")} (${available.length})`],
    ["food", t("surplusFood")],
    ["clothes", t("clothing")],
    ["soon", t("expiringSoon")],
  ];
  let list = available;
  if (state.ngoFilter === "food") list = available.filter((d) => d.kind === "food");
  if (state.ngoFilter === "clothes") list = available.filter((d) => d.kind === "clothes");
  if (state.ngoFilter === "soon") list = available.slice().slice(0, 2);

  return `
    <div class="verify-card">
      <div class="verify-left">
        <div class="verify-ic">${ic("shield", "sm")}</div>
        <div>
          <b>${ROLES.ngo.org}</b>
          <span>${t("darpan")} ${ROLES.ngo.darpan} · ${t("verifiedShelter")}</span>
        </div>
      </div>
      <span class="chev">${ic("chevronRight", "sm")}</span>
    </div>

    <div class="stat-grid">
      <div class="stat"><div class="ic green">${ic("file")}</div><b>${claims.length}</b><span>${t("claims")}</span></div>
      <div class="stat"><div class="ic amber">${ic("truck")}</div><b>${distributed}</b><span>${t("distributions")}</span></div>
      <div class="stat"><div class="ic green">${ic("shield")}</div><b>0</b><span>${t("verification")} ${t("pending")}</span></div>
    </div>

    <div class="chip-row" style="margin-top:16px">
      ${filters.map(([k, label]) => `<button class="chip ${state.ngoFilter === k ? "active" : ""}" data-act="ngo-filter" data-filter="${k}">${label}</button>`).join("")}
    </div>

    <div class="section-title"><span class="dot"></span>${t("availableNear")}
      <span style="flex:1"></span><span class="small muted">${list.length} ${t("listings")}</span></div>
    <div class="list">
      ${list.length ? list.map((d) => `
        <div class="card ngo-row">
          <div class="d-row-head">
            <div class="d-thumb ${d.kind === "clothes" ? "cloth" : ""}">${ic(kindIcon(d))}</div>
            <div class="d-main">
              <div class="row between" style="gap:8px;align-items:flex-start">
                <b>${esc(dfield(d, "title"))}</b>
                <span class="qty-tag">${qtyLabel(d)}</span>
              </div>
              <div class="meta">${esc(d.donor)} · ${esc(dfield(d, "area"))} · ${d.distance}</div>
            </div>
          </div>
          <div class="ngo-row-foot">
            <span class="deadline ${d.kind === "clothes" ? "amber" : ""}">${ic("clock", "xs")} ${t("closesIn")} ${esc(d.deadline)}</span>
            <span class="tiny muted">${ic("pin", "xs")} ${t("secure")}</span>
          </div>
          <button class="btn block" data-act="claim" data-id="${d.id}">${t("claimDonation")}</button>
        </div>`).join("") : `<div class="empty">${t("noDispatches")}</div>`}
    </div>

    <div class="section-title">${t("yourClaims")} (${claims.length})</div>
    <div class="list">
      ${claims.length ? claims.map((d) => `
        <div class="claim-card" data-act="open" data-id="${d.id}">
          <div class="row between">
            <b class="small">${esc(dfield(d, "title"))}</b>
            ${statusPill(d)}
          </div>
          ${d.status === "claimed" ? `<div class="pin-strip"><span>${t("deliveryPinShare")}</span><b>${d.deliveryOtp}</b></div>` : ""}
          <div class="small muted">${esc(d.donor)} → ${ROLES.ngo.org}</div>
        </div>`).join("") : `<div class="empty">${t("noClaims")}</div>`}
    </div>`;
}

/* ---------------- volunteer ---------------- */
function volunteerHome() {
  const open = state.donations.filter((d) => ["claimed", "assigned", "in_transit"].includes(d.status));
  const live = state.donations.find((d) => d.status === "in_transit") || state.donations.find((d) => d.status === "assigned");
  return `
    <div class="rider-strip">
      <div class="row" style="gap:10px">
        <span class="rider-ic">${ic("bike")}</span>
        <div><b>${t("motorcycle")}</b><div class="tiny muted">${ROLES.volunteer.name}</div></div>
      </div>
      <div class="row" style="gap:8px">
        <button class="toggle ${state.online ? "on" : ""}" data-act="online" role="switch" aria-checked="${state.online}" aria-label="${t("online")}"><span></span></button>
        <span class="tiny strong ${state.online ? "text-green" : "muted"}">${state.online ? t("online") : t("offline")}</span>
      </div>
    </div>

    <div class="stat-grid two">
      <div class="stat"><div class="ic green">${ic("check")}</div><b>${state.tasks}</b><span>${t("missions")}</span></div>
      <div class="stat"><div class="ic amber">${ic("star")}</div><b>${state.rating}</b><span>${t("rating")}</span></div>
    </div>

    ${live ? `
    <div class="section-title"><span class="dot"></span>${t("activeRoute")}</div>
    <div class="card route-card">
      <div class="route-head">
        <span class="tag ${live.kind === "clothes" ? "amber" : "green"}">${t(live.kind === "clothes" ? "clothing" : "foodRescue")}</span>
        ${statusPill(live)}
        <span style="flex:1"></span>
        <span class="tiny muted">${live.distance}</span>
      </div>
      <div class="route">
        <div class="route-rail"><span class="rp a"></span><span class="rp-line"></span><span class="rp b"></span></div>
        <div class="route-body">
          <div class="route-point"><span class="tiny muted">${t("pickup")}</span><b>${esc(live.donor)}</b><span class="tiny muted">${esc(dfield(live, "area"))}</span></div>
          <div class="route-point"><span class="tiny muted">${t("dropoff")}</span><b>${esc(live.claimedBy || ROLES.ngo.org)}</b><span class="tiny muted">${t("eta")} 12 ${t("min")}</span></div>
        </div>
      </div>
      ${live.status === "in_transit" ? `<button class="btn block" data-act="sheet" data-type="delivery" data-id="${live.id}">${t("enterDelivery")}</button>` : ""}
    </div>` : ""}

    <div class="section-title"><span class="dot"></span>${t("availableDispatches")} (${open.length})</div>
    <div class="list">
      ${open.length ? open.map((d) => `
        <div class="dispatch-card">
          <div class="dispatch-top">
            <span class="tag ${d.kind === "clothes" ? "amber" : "green"}">${t(d.kind === "clothes" ? "clothing" : "foodRescue")}</span>
            <span class="tag soft">${t("match")} ${88 + (d.qty % 11)}%</span>
            <span style="flex:1"></span>
            <span class="tiny deadline">${ic("clock", "xs")} ${esc(d.deadline)}</span>
          </div>
          <b class="dispatch-title">${esc(dfield(d, "title"))}</b>
          <div class="small muted">${esc(d.donor)} → ${esc(d.claimedBy || ROLES.ngo.org)} · ${esc(dfield(d, "area"))}</div>
          <div class="small muted" style="margin-top:4px">${t("handling")}: <b>${esc(dfield(d, "holding") || d.condition || "Ambient")}</b>${d.diet ? ` · <span class="veg-dot">${esc(dfield(d, "diet"))}</span>` : d.target ? ` · ${esc(dfield(d, "target"))}` : ""}</div>
          <div class="dispatch-foot">
            ${statusPill(d)}
            ${d.status === "assigned" ? `<button class="btn sm" data-act="sheet" data-type="pickup" data-id="${d.id}">${t("enterPickup")}</button>` : ""}
            ${d.status === "in_transit" ? `<button class="btn sm" data-act="sheet" data-type="delivery" data-id="${d.id}">${t("enterDelivery")}</button>` : ""}
            ${d.status === "claimed" ? `<button class="btn sm" data-act="accept" data-id="${d.id}">${t("acceptDispatch")}</button>` : ""}
          </div>
        </div>`).join("") : `<div class="empty">${t("noDispatches")}</div>`}
    </div>`;
}

/* ---------------- admin ---------------- */
function adminHome() {
  const c = counts();
  const tabs = [["overview", t("overview")], ["ngo", t("ngoApprovals")], ["users", t("users")], ["complaints", t("complaints")], ["audit", t("audit")]];
  let inner = "";

  if (state.adminTab === "overview") {
    const metrics = [
      [c.all, t("totalListings"), "package", "green"],
      [state.donations.filter((d) => d.kind === "food").length, t("foodRescues"), "bowl", "green"],
      [state.donations.filter((d) => d.kind === "clothes").length, t("clothingItems"), "shirt", "amber"],
      [c.distributed, t("deliveriesMade"), "truck", "green"],
      [2, t("verifiedNgos"), "building", "green"],
      [1, t("activeRiders"), "bike", "amber"],
    ];
    const statusRows = [
      ["available", c.available, "amber"],
      ["accepted", c.claimed, "green"],
      ["assigned", c.assigned, "purple"],
      ["inTransit", c.in_transit, "blue"],
      ["delivered", c.distributed, "grey"],
    ];
    const max = Math.max(1, ...statusRows.map((r) => r[1]));
    inner = `
      <div class="note-strip">${ic("shield", "xs")} ${t("analyticsNote")}</div>
      <div class="metric-grid">
        ${metrics.map(([v, l, icon, tone]) => `<div class="metric ${tone}">
          <div class="row between"><span class="metric-ic">${ic(icon)}</span><b>${v}</b></div>
          <span>${l}</span>
        </div>`).join("")}
      </div>

      <div class="section-title"><span class="dot"></span>${t("statusMix")}</div>
      <div class="card chart-card">
        ${statusRows.map(([label, n, tone]) => `<div class="chart-row">
          <span class="chart-label">${t(label)}</span>
          <span class="chart-track"><span class="chart-fill ${tone}" style="width:${n ? Math.max(6, (n / max) * 100) : 0}%"></span></span>
          <b>${n}</b>
        </div>`).join("")}
      </div>

      <div class="section-title"><span class="dot"></span>${t("lifecycle")}
        <span style="flex:1"></span><span class="small muted">${c.all} ${t("items")}</span></div>
      <div class="list">
        ${state.donations.map((d) => `
          <button class="d-row" data-act="open" data-id="${d.id}">
            <div class="d-thumb ${d.kind === "clothes" ? "cloth" : ""}">${ic(kindIcon(d))}</div>
            <div class="d-main">
              <b>${esc(dfield(d, "title"))}</b>
              <div class="meta">${esc(d.donor)} · ${statusPill(d)}</div>
            </div>
            <span class="chev">${ic("chevronRight", "sm")}</span>
          </button>`).join("")}
      </div>`;
  } else if (state.adminTab === "ngo") {
    inner = `<div class="list" style="margin-top:14px">
      ${state.orgApprovals.length ? state.orgApprovals.map((org) => `
        <div class="card admin-row">
          <div><b>${esc(org)}</b><div class="small muted">${t("awaitingReview")}</div></div>
          <button class="btn sm" data-act="approve" data-org="${esc(org)}">${t("approve")}</button>
        </div>`).join("") : `<div class="empty">${t("noApprovals")}</div>`}
    </div>`;
  } else if (state.adminTab === "users") {
    inner = `<div class="list" style="margin-top:14px">
      ${Object.keys(ROLES).map((k) => `
        <div class="card admin-row">
          <div class="row" style="gap:10px"><span class="mini-av">${ROLES[k].initial}</span>
            <div><b>${ROLES[k].name}</b><div class="small muted">${ROLES[k].email} · ${roleLabel(k)}</div></div>
          </div>
          <span class="pill green">${t("active")}</span>
        </div>`).join("")}
    </div>`;
  } else if (state.adminTab === "complaints") {
    inner = `<div class="list" style="margin-top:14px">
      <div class="card admin-row">
        <div><b>${t("complaintTitle")}</b><div class="small muted">${t("complaintBody")}</div></div>
        <span class="pill amber">${t("statusOpen")}</span>
      </div>
    </div>`;
  } else {
    inner = `<div class="list" style="margin-top:14px">
      ${[t("log1"), t("log2"), t("log3"), t("log4")].map((line, i) => `
        <div class="card admin-row">
          <div class="row" style="gap:10px"><span class="log-dot ${i % 2 ? "amber" : ""}"></span><div class="small">${line}</div></div>
        </div>`).join("")}
    </div>`;
  }

  return `
    <div class="admin-tabs">
      ${tabs.map(([k, label]) => `<button class="admin-tab ${state.adminTab === k ? "active" : ""}" data-act="admin-tab" data-tab="${k}">${label}</button>`).join("")}
    </div>
    ${inner}`;
}

/* ---------------- notifications ---------------- */
function notificationsView() {
  const unread = state.notifs.filter((n) => n.unread).length;
  const list = state.notifFilter === "unread" ? state.notifs.filter((n) => n.unread) : state.notifs;
  return `
    <div class="row between" style="margin-top:4px">
      <div class="chip-row">
        <button class="chip ${state.notifFilter === "all" ? "active" : ""}" data-act="notif-filter" data-filter="all">${t("allFilter")} (${state.notifs.length})</button>
        <button class="chip ${state.notifFilter === "unread" ? "active" : ""}" data-act="notif-filter" data-filter="unread">${t("unread")} (${unread})</button>
      </div>
      <button class="link small" data-act="mark-read">${t("markAllRead")}</button>
    </div>
    <div class="list" style="margin-top:14px">
      ${list.length ? list.map((n) => `
        <div class="notif ${n.unread ? "unread" : ""}">
          <div class="notif-ic tone-${n.tone}">${ic(n.icon)}</div>
          <div class="notif-main">
            <b>${esc(notifTitle(n))}</b>
            <p>${esc(notifBody(n))}</p>
          </div>
          <div class="notif-meta">${esc(n.time)}${n.unread ? `<span class="unread-dot"></span>` : ""}</div>
        </div>`).join("") : `<div class="empty">${t("noDispatches")}</div>`}
    </div>`;
}

/* ---------------- profile ---------------- */
function profileView() {
  const r = ROLES[state.role];
  const roles = ["donor", "ngo", "volunteer", "admin"];
  return `
    <div class="card profile-card">
      <div class="avatar">${r.initial}</div>
      <div class="grow">
        <b>${r.name}</b>
        <span>${roleLabel(state.role)}${state.role === "donor" ? ` · ${r.org}` : state.role === "ngo" ? ` · ${ROLES.ngo.darpan}` : ""}</span>
        <span>${t("memberSince")} · ${r.phone}</span>
      </div>
    </div>

    <div class="group-label">${t("switchRole")}</div>
    <div class="card list-card">
      ${roles.map((k) => `<button class="setting ${state.role === k ? "current" : ""}" data-act="switch-role" data-role="${k}">
        <span class="ic">${ic(ROLES[k].icon)}</span>
        <span class="grow"><b>${roleLabel(k)}</b><span class="block-sub small muted">${t("role" + (k === "donor" ? "Donor" : k === "ngo" ? "Ngo" : k === "volunteer" ? "Volunteer" : "Admin") + "Desc")}</span></span>
        ${state.role === k ? `<span class="tiny">${t("active")}</span>` : ""}${ic("chevronRight", "sm")}
      </button>`).join("")}
    </div>

    <div class="group-label">${t("preferences")}</div>
    <div class="card list-card">
      <button class="setting" data-act="theme">
        <span class="ic">${ic(state.theme === "dark" ? "moon" : "sun")}</span>
        <span class="grow">${t("darkMode")}<span class="small muted block-sub">${t("darkModeSub")}</span></span>
        <span class="toggle ${state.theme === "dark" ? "on" : ""}" aria-hidden="true"><span></span></span>
      </button>
      <div class="setting" style="cursor:default">
        <span class="ic">${ic("globe")}</span><span class="grow">${t("language")}</span>
        ${langSwitch(true)}
      </div>
    </div>

    <button class="btn ghost block danger-text" data-act="logout" style="margin-top:18px">${ic("logout", "sm")} ${t("signOut")}</button>
    <p class="hint" style="margin-top:14px">${t("version")}</p>
    <p class="hint" style="margin-top:4px">${t("demoNote")}</p>`;
}

/* ---------------- detail ---------------- */
function detailView(d) {
  if (!d) return `<div class="empty">—</div>`;
  const steps = [["available", t("posted")], ["claimed", t("accepted")], ["assigned", t("assigned")], ["in_transit", t("inTransit")], ["distributed", t("delivered")]];
  const order = ["available", "claimed", "assigned", "in_transit", "distributed"];
  const idx = order.indexOf(d.status);
  const canClaim = state.role === "ngo" && d.status === "available";
  const canAccept = state.role === "volunteer" && d.status === "claimed" && d.claimedBy === ROLES.ngo.org;
  const canPickup = state.role === "volunteer" && d.status === "assigned";
  const canDeliver = state.role === "volunteer" && d.status === "in_transit";
  const showPickupPin = state.role === "donor" && d.donor === ROLES.donor.org;
  const showDeliveryPin = state.role === "ngo" && d.claimedBy === ROLES.ngo.org;

  return `
    <div class="detail-head">
      <div class="row between">
        <span class="tag ${d.kind === "clothes" ? "amber" : "green"}">${ic(kindIcon(d), "xs")} ${t(d.kind === "clothes" ? "clothing" : "surplusFood")}</span>
        ${statusPill(d)}
      </div>
      <h2>${esc(dfield(d, "title"))}</h2>
      <p class="small muted" style="margin:0">${esc(d.donor)} → ${esc(d.claimedBy || "—")}</p>
    </div>

    <div class="timeline">
      ${steps.map(([k, label], i) => `<div class="tl-step ${i <= idx ? "done" : ""}">
        <span class="tl-dot"></span><span class="tl-label">${label}</span></div>`).join("")}
    </div>

    <div class="card kv">
      <div class="row between"><span class="k">${t("quantity")}</span><span class="v">${qtyLabel(d)}</span></div>
      <div class="row between"><span class="k">${t("pickupArea")}</span><span class="v">${esc(dfield(d, "area"))}</span></div>
      <div class="row between"><span class="k">${t("category")}</span><span class="v">${esc(dfield(d, "category"))}</span></div>
      ${d.diet ? `<div class="row between"><span class="k">${t("dietType")}</span><span class="v">${esc(dfield(d, "diet"))}</span></div>` : ""}
      ${d.holding ? `<div class="row between"><span class="k">${t("handling")}</span><span class="v">${esc(dfield(d, "holding"))}</span></div>` : ""}
      ${d.condition ? `<div class="row between"><span class="k">${t("condition")}</span><span class="v">${esc(dfield(d, "condition"))}</span></div>` : ""}
      ${d.status === "distributed" ? "" : `<div class="row between"><span class="k">${t("deadline")}</span><span class="v">${esc(d.deadline)}</span></div>`}
      ${d.notes ? `<div class="row between"><span class="k">${t("desc")}</span><span class="v" style="text-align:right;max-width:60%">${esc(dfield(d, "notes"))}</span></div>` : ""}
    </div>

    ${showPickupPin ? `<div class="pin-strip big"><span>${t("pickupOtp")}</span><b>${d.pickupOtp}</b></div>` : ""}
    ${showDeliveryPin ? `<div class="pin-strip big"><span>${t("deliveryOtp")}</span><b>${d.deliveryOtp}</b></div>` : ""}

    ${canClaim ? `<button class="btn block" style="margin-top:14px" data-act="claim" data-id="${d.id}">${t("claimDonation")}</button>` : ""}
    ${canAccept ? `<button class="btn block" style="margin-top:14px" data-act="accept" data-id="${d.id}">${t("acceptDispatch")}</button>` : ""}
    ${canPickup ? `<button class="btn block" style="margin-top:14px" data-act="sheet" data-type="pickup" data-id="${d.id}">${t("enterPickup")}</button>` : ""}
    ${canDeliver ? `<button class="btn block" style="margin-top:14px" data-act="sheet" data-type="delivery" data-id="${d.id}">${t("enterDelivery")}</button>` : ""}
    <p class="hint" style="margin-top:14px">${t("demoNote")}</p>`;
}

/* ---------------- donation rows / forms ---------------- */
function donationRow(d) {
  return `<button class="d-row" data-act="open" data-id="${d.id}">
    <div class="d-thumb ${d.kind === "clothes" ? "cloth" : ""}">${ic(kindIcon(d))}</div>
    <div class="d-main">
      <b>${esc(dfield(d, "title"))}</b>
      <div class="meta">${qtyLabel(d)} · ${esc(dfield(d, "area"))}</div>
      ${d.status === "distributed" ? "" : `<div class="meta">${t("collectBy")} ${esc(d.deadline)}</div>`}
    </div>
    <div class="d-right">${statusPill(d)}<span class="chev">${ic("chevronRight", "sm")}</span></div>
  </button>`;
}

function donateFoodView() {
  const photos = ["bowl", "package", "leaf"];
  return `
    <div class="form">
      <p class="small muted" style="margin:2px 2px 0">${t("donateFoodSub")}</p>

      <div class="field"><label>${t("photo")}</label>
        <div class="photo-strip">
          ${photos.map((p, i) => `<button class="photo ${i === 0 ? "active" : ""}" data-act="pick-photo" aria-label="${p}">${ic(p)}</button>`).join("")}
          <span class="small muted">${t("selectPhoto")}</span>
        </div>
      </div>

      <div class="field"><label>${t("foodCategory")}</label>
        <div class="chip-row">
          ${[t("cookedMeals"), t("rawProduce"), t("bakery"), t("packaged")].map((c, i) => `<button class="chip ${i === 0 ? "active" : ""}" data-act="pick-cat">${c}</button>`).join("")}
        </div>
      </div>

      <div class="field"><label>${t("foodName")}</label>
        <input id="f-title" placeholder="${t("foodNamePh")}" /></div>

      <div class="field"><label>${t("desc")}</label>
        <textarea id="f-notes" rows="3" placeholder="${t("descPh")}"></textarea></div>

      <div class="row" style="gap:10px">
        <div class="field grow"><label>${t("quantity")}</label>
          <input id="f-qty" inputmode="numeric" placeholder="${t("quantityPh")}" /></div>
        <div class="field" style="width:112px"><label>${t("unit")}</label>
          <select id="f-unit"><option value="meals">${t("unitMeals")}</option><option value="pieces">${t("unitPieces")}</option></select></div>
      </div>

      <div class="field"><label>${t("dietType")}</label>
        <div class="chip-row">
          <button class="chip active" data-act="pick-diet">${t("pureVeg")}</button>
          <button class="chip" data-act="pick-diet">${t("nonVeg")}</button>
        </div>
      </div>

      <div class="field"><label>${t("holding")}</label>
        <div class="chip-row">
          <button class="chip active" data-act="pick-hold">${t("hotHolding")}</button>
          <button class="chip" data-act="pick-hold">${t("ambient")}</button>
          <button class="chip" data-act="pick-hold">${t("chilled")}</button>
        </div>
      </div>

      <button class="btn block" data-act="publish-food">${t("publishFood")}</button>
      <p class="hint">${t("demoNote")}</p>
    </div>`;
}

function donateClothesView() {
  const conds = ["Brand New", "Like New", "Gently Used"];
  const targets = ["Kids", "Adults", "All Ages"];
  return `
    <div class="form">
      <p class="small muted" style="margin:2px 2px 0">${t("clothingSub")}</p>

      <div class="field"><label>${t("photo")}</label>
        <div class="photo-strip">
          ${["shirt", "package", "leaf"].map((p, i) => `<button class="photo ${i === 0 ? "active" : ""}" data-act="pick-photo" aria-label="${p}">${ic(p)}</button>`).join("")}
          <span class="small muted">${t("selectPhoto")}</span>
        </div>
      </div>

      <div class="field"><label>${t("foodName")}</label>
        <input id="c-title" placeholder="${t("foodNamePh")}" /></div>

      <div class="field"><label>${t("desc")}</label>
        <textarea id="c-notes" rows="3" placeholder="${t("descPh")}"></textarea></div>

      <div class="row" style="gap:10px">
        <div class="field grow"><label>${t("quantity")}</label><input id="c-qty" inputmode="numeric" placeholder="${t("quantityPh")}" /></div>
        <div class="field" style="width:112px"><label>${t("unit")}</label><select id="c-unit"><option value="pieces">${t("unitPieces")}</option><option value="meals">${t("unitMeals")}</option></select></div>
      </div>

      <div class="field"><label>${t("condition")}</label>
        <div class="chip-row">
          ${conds.map((c, i) => `<button class="chip ${i === 2 ? "active" : ""}" data-act="pick-cond">${c}</button>`).join("")}
        </div>
      </div>

      <div class="field"><label>${t("target")}</label>
        <div class="chip-row">
          ${targets.map((c, i) => `<button class="chip ${i === 1 ? "active" : ""}" data-act="pick-target">${c}</button>`).join("")}
        </div>
      </div>

      <button class="btn block" data-act="publish-clothes">${t("publishClothes")}</button>
      <p class="hint">${t("demoNote")}</p>
    </div>`;
}

/* ---------------- actions ---------------- */
function toast(msg) {
  const box = document.getElementById("toast");
  if (!box) return;
  box.textContent = msg;
  box.classList.add("show");
  clearTimeout(window.__toastTimer);
  window.__toastTimer = setTimeout(() => box.classList.remove("show"), 2600);
}

function randomPin() { return String(1000 + Math.floor(Math.random() * 9000)); }

function login(role) {
  state.role = role;
  state.tab = "home";
  state.route = null;
  state.activeDonation = null;
  state.sheet = null;
  save();
  render();
  if (!state.charter[role]) {
    const accept = document.querySelector('[data-act="charter-accept"]');
    if (accept) accept.disabled = true;
  }
}

document.addEventListener("change", (e) => {
  if (e.target && (e.target.id === "chk1" || e.target.id === "chk2")) {
    const a = document.getElementById("chk1");
    const b = document.getElementById("chk2");
    const btn = document.querySelector('[data-act="charter-accept"]');
    if (btn) btn.disabled = !(a && a.checked && b && b.checked);
  }
});

document.addEventListener("click", (e) => {
  const node = e.target.closest("[data-act]");
  if (!node) return;
  const act = node.dataset.act;
  if (node.tagName === "A") e.preventDefault();

  if (act === "noop") return;
  if (act === "login") { login(node.dataset.role); return; }
  if (act === "charter-accept") {
    const c1 = document.getElementById("chk1");
    const c2 = document.getElementById("chk2");
    if (!(c1 && c2 && c1.checked && c2.checked)) { toast(t("agree1")); return; }
    state.charter[state.role] = true;
    save();
    render();
    return;
  }
  if (act === "charter-decline" || act === "logout") {
    const keep = { lang: state.lang, theme: state.theme, donations: state.donations, notifs: state.notifs, impact: state.impact };
    state = Object.assign(freshState(), keep);
    save();
    render();
    return;
  }
  if (act === "theme") {
    document.documentElement.classList.add("theme-fading");
    state.theme = state.theme === "dark" ? "light" : "dark";
    save(); render();
    clearTimeout(window.__themeTimer);
    window.__themeTimer = setTimeout(() => document.documentElement.classList.remove("theme-fading"), 420);
    return;
  }
  if (act === "set-lang") {
    state.lang = node.dataset.lang;
    state.sheet = null;
    save(); render(); toast(t("langSaved"));
    return;
  }
  if (act === "sheet-lang") { state.sheet = { type: "lang" }; save(); render(); return; }
  if (act === "tab") { state.tab = node.dataset.tab; state.route = null; save(); render(); return; }
  if (act === "route") { state.route = node.dataset.route; state.tab = "home"; save(); render(); return; }
  if (act === "back" || act === "sheet-close") { state.route = null; state.sheet = null; save(); render(); return; }
  if (act === "open") { state.activeDonation = node.dataset.id; state.route = "detail"; save(); render(); return; }
  if (act === "online") { state.online = !state.online; save(); render(); return; }
  if (act === "admin-tab") { state.adminTab = node.dataset.tab; save(); render(); return; }
  if (act === "ngo-filter") { state.ngoFilter = node.dataset.filter; save(); render(); return; }
  if (act === "notif-filter") { state.notifFilter = node.dataset.filter; save(); render(); return; }
  if (act === "mark-read") { state.notifs.forEach((n) => { n.unread = false; }); save(); render(); return; }
  if (act === "switch-role") {
    state.role = node.dataset.role;
    state.tab = "home"; state.route = null; state.activeDonation = null;
    save(); render(); return;
  }
  if (act === "approve") {
    const name = node.dataset.org;
    state.orgApprovals = state.orgApprovals.filter((o) => o !== name);
    pushNotif("shield", "ntApprovedT", "ntApprovedB", { name }, "green");
    save(); render(); toast(t("approvedMsg")); return;
  }

  if (act === "claim") {
    const d = byId(node.dataset.id);
    if (d) {
      d.status = "claimed";
      d.claimedBy = ROLES.ngo.org;
      pushNotif("handshake", "ntClaimedT", "ntClaimedB", { name: ROLES.ngo.org, title: dfield(d, "title") }, "green");
      save(); render(); toast(t("claimedMsg"));
    }
    return;
  }
  if (act === "accept") {
    const d = byId(node.dataset.id);
    if (d) {
      d.status = "assigned";
      d.rider = ROLES.volunteer.name;
      pushNotif("bike", "ntDispatchT", "ntDispatchB", { name: ROLES.volunteer.name, title: dfield(d, "title") }, "green");
      save(); render(); toast(t("acceptedMsg"));
    }
    return;
  }
  if (act === "sheet") {
    state.sheet = { type: node.dataset.type, id: node.dataset.id };
    save(); render();
    const pin = document.getElementById("pin");
    if (pin) pin.focus();
    return;
  }
  if (act === "pin-submit") {
    const d = byId(node.dataset.id);
    const input = document.getElementById("pin");
    const err = document.getElementById("pin-err");
    const value = (input ? input.value : "").trim();
    if (!d) return;
    const expected = node.dataset.type === "pickup" ? d.pickupOtp : d.deliveryOtp;
    if (value !== expected) {
      if (err) err.hidden = false;
      if (input) input.value = "";
      return;
    }
    let msg;
    if (node.dataset.type === "pickup") {
      d.status = "in_transit";
      pushNotif("package", "ntPickupT", "ntPickupB", { title: dfield(d, "title") }, "blue");
      msg = t("pickupMsg");
    } else {
      d.status = "distributed";
      d.deadline = "—";
      state.tasks += 1;
      state.impact.families += 4;
      pushNotif("check", "ntDeliveredT", "ntDeliveredB", { name: d.claimedBy || ROLES.ngo.org, title: dfield(d, "title") }, "green");
      msg = t("deliveredMsg");
    }
    state.sheet = null;
    save(); render(); toast(msg);
    return;
  }

  if (act === "pick-photo" || act === "pick-cat" || act === "pick-diet" || act === "pick-hold" || act === "pick-cond" || act === "pick-target") {
    const parent = node.parentElement;
    if (parent) parent.querySelectorAll(".chip, .photo").forEach((b) => b.classList.remove("active"));
    node.classList.add("active");
    return;
  }

  if (act === "publish-food") {
    const title = (document.getElementById("f-title") || {}).value || "";
    const qty = parseInt((document.getElementById("f-qty") || {}).value || "0", 10);
    if (!title.trim() || !qty) { toast(t("publishErr")); return; }
    const activeChip = document.querySelectorAll(".form .chip-row .chip.active");
    const diet = activeChip.length > 0 ? activeChip[activeChip.length - 2].textContent.trim() : t("pureVeg");
    const holdingChip = activeChip.length > 0 ? activeChip[activeChip.length - 1].textContent.trim() : t("ambient");
    state.donations.unshift({
      id: "d" + Date.now(), title: title.trim(), kind: "food", qty,
      unit: (document.getElementById("f-unit") || {}).value || "meals",
      donor: ROLES.donor.org, area: "Camp, Pune", distance: "0.0 km", status: "available",
      pickupOtp: randomPin(), deliveryOtp: randomPin(),
      deadline: fmt(t("todayAt"), { t: "9:00 PM" }), category: "Cooked Meals", diet,
      holding: holdingChip,
      notes: (document.getElementById("f-notes") || {}).value || "",
    });
    state.impact.meals += qty;
    state.route = null; state.tab = "home"; save(); render(); toast(t("published"));
    return;
  }

  if (act === "publish-clothes") {
    const title = (document.getElementById("c-title") || {}).value || "";
    const qty = parseInt((document.getElementById("c-qty") || {}).value || "0", 10);
    if (!title.trim() || !qty) { toast(t("publishErr")); return; }
    state.donations.unshift({
      id: "d" + Date.now(), title: title.trim(), kind: "clothes", qty,
      unit: (document.getElementById("c-unit") || {}).value || "pieces",
      donor: ROLES.donor.org, area: "Camp, Pune", distance: "0.0 km", status: "available",
      pickupOtp: randomPin(), deliveryOtp: randomPin(),
      deadline: fmt(t("tomorrowAt"), { t: "12:00 PM" }), category: "Clean Wearable Essentials",
      condition: "Gently Used", target: "Adults",
      notes: (document.getElementById("c-notes") || {}).value || "",
    });
    state.route = null; state.tab = "home"; save(); render(); toast(t("published"));
    return;
  }
});

document.addEventListener("keydown", (e) => {
  if (e.key === "Enter" && e.target && e.target.id === "pin") {
    const btn = document.querySelector('[data-act="pin-submit"]');
    if (btn) btn.click();
  }
});

function bridgeMark() {
  return `<svg width="30" height="30" viewBox="0 0 32 32" fill="none" aria-hidden="true">
    <path d="M4 20c0-6 5-10 12-10s12 4 12 10" stroke="#fff" stroke-width="2.6" stroke-linecap="round"/>
    <path d="M2 20h28" stroke="#fff" stroke-width="2.6" stroke-linecap="round"/>
    <path d="M9 20v6M16 20v8M23 20v6" stroke="#fff" stroke-width="2.4" stroke-linecap="round"/>
    <circle cx="16" cy="6" r="2.4" fill="#fff"/>
  </svg>`;
}

render();
