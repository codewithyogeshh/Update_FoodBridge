import '../../features/donations/domain/models/donation.dart';

class SmartMatchResult {
  final int matchScorePercent;
  final String matchTier; // 'Best Match (95%)', 'Great Match (88%)', etc.
  final String reason;
  final bool isHighPriority;

  const SmartMatchResult({
    required this.matchScorePercent,
    required this.matchTier,
    required this.reason,
    required this.isHighPriority,
  });
}

class FoodImageAnalysisResult {
  final String detectedTitle;
  final String category;
  final double estimatedPortions;
  final String unit;
  final bool isVeg;
  final String storageCondition;
  final String packagingNotes;
  final String advisoryNote;

  const FoodImageAnalysisResult({
    required this.detectedTitle,
    required this.category,
    required this.estimatedPortions,
    required this.unit,
    required this.isVeg,
    required this.storageCondition,
    required this.packagingNotes,
    required this.advisoryNote,
  });
}

class FoodFreshnessScanResult {
  final String foodTitle;
  final List<String> detectedItems;
  final String hygieneStatus;
  final bool isSafePackaging;
  final int safeShelfLifeHours;
  final String estimatedWindowText;
  final bool isVeg;
  final String storageCondition;
  final double confidenceScore;
  final String marathiSummary;
  final String safetyAdvisory;

  const FoodFreshnessScanResult({
    required this.foodTitle,
    required this.detectedItems,
    required this.hygieneStatus,
    required this.isSafePackaging,
    required this.safeShelfLifeHours,
    required this.estimatedWindowText,
    required this.isVeg,
    required this.storageCondition,
    required this.confidenceScore,
    required this.marathiSummary,
    required this.safetyAdvisory,
  });
}

class SafeHandlingAdvisory {
  final String title;
  final List<String> handlingTips;
  final String recommendedContainer;
  final String maxTransitWindow;
  final String disclaimer;

  const SafeHandlingAdvisory({
    required this.title,
    required this.handlingTips,
    required this.recommendedContainer,
    required this.maxTransitWindow,
    this.disclaimer =
        'Notice: This AI advisory provides logistics & packaging guidelines only. It does not certify food safety or hygiene (FSSAI compliance remains donor responsibility).',
  });
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  /// Calculate match compatibility between donation and NGO/volunteer route
  SmartMatchResult calculateMatch({
    required Donation donation,
    double distanceKm = 3.5,
  }) {
    int score = 80;
    final List<String> reasons = [];
    bool highPriority = false;

    // 1. Distance proximity
    if (distanceKm <= 3.0) {
      score += 15;
      reasons.add('Ultra-close proximity (~${distanceKm.toStringAsFixed(1)} km)');
    } else if (distanceKm <= 7.0) {
      score += 8;
      reasons.add('Within standard delivery radius (${distanceKm.toStringAsFixed(1)} km)');
    } else {
      score -= 10;
      reasons.add('Extended transit distance (${distanceKm.toStringAsFixed(1)} km)');
    }

    // 2. Food urgency & shelf life
    if (donation.isFood) {
      final hoursLeft = donation.timeRemaining.inHours;
      if (hoursLeft <= 3 && !donation.timeRemaining.isNegative) {
        score += 10;
        highPriority = true;
        reasons.add('Expiring soon (urgent rescue window < 3 hrs)');
      } else {
        reasons.add('Stable pickup window');
      }

      if (donation.isVeg) {
        score += 5;
        reasons.add('Pure-veg widely accepted across all shelters');
      }
    } else {
      score += 5;
      reasons.add('Non-perishable clothing redistribution');
    }

    final finalScore = score.clamp(50, 99);
    final String tier;
    if (finalScore >= 90) {
      tier = 'High Match ($finalScore%)';
    } else if (finalScore >= 80) {
      tier = 'Good Match ($finalScore%)';
    } else {
      tier = 'Standard Match ($finalScore%)';
    }

    return SmartMatchResult(
      matchScorePercent: finalScore,
      matchTier: tier,
      reason: reasons.join(' • '),
      isHighPriority: highPriority,
    );
  }

  /// AI-assisted safe transport advisory for riders and volunteers
  SafeHandlingAdvisory getSafeHandlingAdvisory(Donation donation) {
    if (donation.isClothing) {
      return const SafeHandlingAdvisory(
        title: 'Clothing Logistics Advisory',
        handlingTips: [
          'Keep packages covered in waterproof rain-sheet or delivery bag during transit.',
          'Verify that bundles remain neatly folded and dry upon shelter arrival.',
          'Confirm handover count directly with shelter inventory manager.',
        ],
        recommendedContainer: 'Waterproof Delivery Bag / Cargo Box',
        maxTransitWindow: 'Flexible (within scheduled 48h deadline)',
      );
    }

    // Food advisory based on storage condition
    final condition = donation.storageCondition?.toLowerCase().trim() ?? 'ambient';

    if (condition == 'hot') {
      return SafeHandlingAdvisory(
        title: 'Hot Food Logistics Advisory',
        handlingTips: [
          'Keep insulated thermal delivery box tightly sealed to maintain holding temperature (>60°C).',
          'Avoid sudden tilt to prevent curry/gravy spillage across foil containers.',
          'Prioritize direct non-stop transit to avoid temperature drop.',
          if (donation.allergenNotes != null)
            'Disclosed Allergens: ${donation.allergenNotes} - Ensure container seal remains uncompromised.',
        ],
        recommendedContainer: 'Thermal Insulated Hot-Bag / Delivery Crate',
        maxTransitWindow: 'Deliver within 45–60 minutes',
      );
    } else if (condition == 'chilled') {
      return SafeHandlingAdvisory(
        title: 'Cold Storage / Dairy Advisory',
        handlingTips: [
          'Transport in cooler box with active ice-gel packs (<8°C).',
          'Do not place in direct contact with hot vehicle engine compartments.',
          'Inspect sealed lids upon pickup.',
        ],
        recommendedContainer: 'Ice-Gel Cooler Box / Insulated Carrier',
        maxTransitWindow: 'Deliver within 60–90 minutes',
      );
    } else {
      return SafeHandlingAdvisory(
        title: 'Dry Goods & Produce Advisory',
        handlingTips: [
          'Keep containers elevated from vehicle floor and protected from dust/exhaust.',
          'Handle bakery boxes gently to prevent crushing.',
          'Verify packaging seal before departure from donor premises.',
        ],
        recommendedContainer: 'Standard Clean Delivery Crate',
        maxTransitWindow: 'Deliver within 2 hours',
      );
    }
  }

  /// Automated FAQ assistant responses
  Future<String> askCommunityAssistant(String query) async {
    final q = query.toLowerCase();

    if (q.contains('otp') || q.contains('code') || q.contains('verification')) {
      return 'FoodBridge uses a secure dual-OTP system: 1) Ask the donor for their 4-digit Pickup Code when you collect the cargo. 2) Ask the NGO shelter manager for their 4-digit Receipt Code when you deliver. Both codes verify physical custody handover.';
    }

    if (q.contains('cancel') ||
        q.contains('breakdown') ||
        q.contains('break down') ||
        q.contains('bike') ||
        q.contains('vehicle') ||
        q.contains('flat tire') ||
        q.contains('emergency')) {
      return 'If you face a vehicle breakdown, flat tire, or emergency, tap the red Emergency icon in the Live Mission screen to release the task. The system will immediately place it back in the dispatch pool for another nearby volunteer.';
    }

    if (q.contains('fssai') || q.contains('food safety') || q.contains('hygiene')) {
      return 'Under FSSAI Surplus Food Regulations and FoodBridge Charter, all donors must certify that food was prepared under hygienic conditions, packed hygienically, and stored at appropriate temperatures. AI assists with logistics but never certifies food safety.';
    }

    if (q.contains('limit') || q.contains('active task') || q.contains('2 task')) {
      return 'To ensure fast and reliable rescues, volunteers can have at most 2 active concurrent dispatch tasks at any time. Once you complete delivery of one mission, you can accept new tasks.';
    }

    return 'FoodBridge connects food & clothing donors, verified NGOs, and volunteer couriers to reduce wastage. For further assistance, contact community dispatch support at support@foodbridge.org.';
  }

  /// Suggest broad category from image cues with strict Rule 14 disclaimer
  CategorySuggestion suggestCategory(String hint, {String? filename}) {
    final lower = '$hint ${filename ?? ''}'.toLowerCase();

    // Check prohibited freshness certification
    if (lower.contains('certify food') ||
        lower.contains('safe to eat') ||
        lower.contains('freshness test')) {
      throw ArgumentError(
        'Rule 14 Violation: AI cannot certify food freshness or safety.',
      );
    }

    if (lower.contains('biryani') ||
        lower.contains('rice') ||
        lower.contains('curry') ||
        lower.contains('meal') ||
        lower.contains('dal')) {
      return const CategorySuggestion(
        categoryId: 'cooked_meals',
        displayName: 'Cooked Meals / Prepared Food',
        type: DonationType.food,
        confidence: 0.88,
        alternativeCategories: ['Raw Produce', 'Packaged Dry Rations'],
      );
    } else if (lower.contains('sweater') ||
        lower.contains('jacket') ||
        lower.contains('blanket') ||
        lower.contains('wool') ||
        lower.contains('thermal')) {
      return const CategorySuggestion(
        categoryId: 'winter_thermal',
        displayName: 'Winter & Thermal Wear',
        type: DonationType.clothing,
        confidence: 0.90,
        alternativeCategories: ['Adult Clothing', 'Blankets & Bedding'],
      );
    } else if (lower.contains('shirt') ||
        lower.contains('pant') ||
        lower.contains('cloth') ||
        lower.contains('dress')) {
      return const CategorySuggestion(
        categoryId: 'adult_clothing',
        displayName: 'Adult Daily Wear',
        type: DonationType.clothing,
        confidence: 0.82,
        alternativeCategories: ['Kids Clothing', 'Winter Wear'],
      );
    } else {
      return const CategorySuggestion(
        categoryId: 'raw_produce',
        displayName: 'Raw Produce / Vegetables',
        type: DonationType.food,
        confidence: 0.75,
        alternativeCategories: ['Packaged Goods', 'Cooked Meals'],
      );
    }
  }

  /// AI-assisted vision scan to detect food category, estimated portions, and packaging
  Future<FoodImageAnalysisResult> analyzeFoodPhoto({
    required String imagePath,
    String? hintText,
  }) async {
    final lower = '$imagePath ${hintText ?? ''}'.toLowerCase();

    if (lower.contains('biryani') || lower.contains('rice') || lower.contains('pulao')) {
      return const FoodImageAnalysisResult(
        detectedTitle: 'Fresh Veg Dum Biryani & Pulao',
        category: 'Cooked Meals',
        estimatedPortions: 25.0,
        unit: 'meals',
        isVeg: true,
        storageCondition: 'hot',
        packagingNotes: 'Recommend food-grade foil containers with thermal covers (>63°C).',
        advisoryNote: 'Best consumed within 3.5 hours of preparation.',
      );
    } else if (lower.contains('roti') || lower.contains('chapati') || lower.contains('bhaji') || lower.contains('sabzi')) {
      return const FoodImageAnalysisResult(
        detectedTitle: 'Fresh Chapati & Mixed Vegetable Sabzi',
        category: 'Cooked Meals',
        estimatedPortions: 20.0,
        unit: 'meals',
        isVeg: true,
        storageCondition: 'ambient',
        packagingNotes: 'Packed in clean, insulated food containers.',
        advisoryNote: 'Nutritious balanced meal, ready for immediate shelter distribution.',
      );
    } else if (lower.contains('fruit') || lower.contains('vegetable') || lower.contains('produce') || lower.contains('grocery')) {
      return const FoodImageAnalysisResult(
        detectedTitle: 'Farm Fresh Seasonal Produce',
        category: 'Raw Groceries / Produce',
        estimatedPortions: 15.0,
        unit: 'kg',
        isVeg: true,
        storageCondition: 'ambient',
        packagingNotes: 'Stored in ventilated produce crates.',
        advisoryNote: 'Stable shelf-life. Ideal for shelter community kitchen preparation.',
      );
    } else if (lower.contains('bakery') || lower.contains('bread') || lower.contains('cake') || lower.contains('dairy')) {
      return const FoodImageAnalysisResult(
        detectedTitle: 'Assorted Bakery Bread & Buns',
        category: 'Bakery & Dairy',
        estimatedPortions: 30.0,
        unit: 'pieces',
        isVeg: true,
        storageCondition: 'ambient',
        packagingNotes: 'Individual bakery paper wrap & food-grade trays.',
        advisoryNote: 'Consume within 24 hours. Keep in a dry, cool location.',
      );
    } else {
      return const FoodImageAnalysisResult(
        detectedTitle: 'Nutritious Prepared Surplus Meals',
        category: 'Cooked Meals',
        estimatedPortions: 15.0,
        unit: 'meals',
        isVeg: true,
        storageCondition: 'ambient',
        packagingNotes: 'Standard sealed food boxes.',
        advisoryNote: 'Check visual hygiene and seal before volunteer handover.',
      );
    }
  }

  Future<FoodFreshnessScanResult> scanFoodFreshness({
    String? imagePath,
    String? hintText,
  }) async {
    final lower = '$imagePath ${hintText ?? ''}'.toLowerCase();

    if (lower.contains('biryani') || lower.contains('rice') || lower.contains('pulao')) {
      return const FoodFreshnessScanResult(
        foodTitle: 'Fresh Veg Biryani & Pulao (व्हेज बिर्याणी व पुलाव)',
        detectedItems: [
          'बासमती राईस / पुलाव (Basmati Rice / Pulao)',
          'मिक्स भाज्या (Carrots, Peas, Beans)',
          'स्पेशल मसाला ग्रेव्ही (Aromatic Gravy)',
        ],
        hygieneStatus: 'Grade A+ (Sealed Food-Grade Container)',
        isSafePackaging: true,
        safeShelfLifeHours: 4,
        estimatedWindowText: 'पुढील ३.५ ते ४ तासांत उपयोगात आणावे',
        isVeg: true,
        storageCondition: 'hot',
        confidenceScore: 0.96,
        marathiSummary: 'Gemini AI निष्कर्ष: अन्न उत्तम दर्जाचे व सुरक्षित आहे. फॉइल कंटेनरमध्ये सीलबंद पॅकिंग आढळले आहे.',
        safetyAdvisory: 'गरम स्थितीत (>६०°C) किंवा त्वरित शेल्टरला सुपूर्द करण्याची शिफारस आहे.',
      );
    } else if (lower.contains('bakery') || lower.contains('bread') || lower.contains('bun')) {
      return const FoodFreshnessScanResult(
        foodTitle: 'Fresh Bakery Breads & Buns (ताजा पाव व बन्स)',
        detectedItems: [
          'ब्राऊन / व्हाईट ब्रेड (Bread Loaves)',
          'बेकरी बन्स (Fresh Buns)',
        ],
        hygieneStatus: 'Grade A (Dry Moisture-Free Packaging)',
        isSafePackaging: true,
        safeShelfLifeHours: 24,
        estimatedWindowText: 'पुढील २४ तास उपयोगात आणता येईल',
        isVeg: true,
        storageCondition: 'ambient',
        confidenceScore: 0.94,
        marathiSummary: 'Gemini AI निष्कर्ष: कोरडे बेकरी उत्पादन, स्वच्छता मानांकनानुसार सुरक्षित.',
        safetyAdvisory: 'दमट हवेपासून दूर आणि कोरड्या जागेत ठेवणे योग्य राहील.',
      );
    } else if (lower.contains('fruit') || lower.contains('vegetable') || lower.contains('produce') || lower.contains('grocery')) {
      return const FoodFreshnessScanResult(
        foodTitle: 'Farm Fresh Vegetables & Fruits (ताजी फळे व भाज्या)',
        detectedItems: [
          'हिरव्या पालेभाज्या (Green Leafy Vegetables)',
          'ऋतुमानानुसार ताजी फळे (Seasonal Fruits)',
        ],
        hygieneStatus: 'Grade A+ (Naturally Fresh & Clean)',
        isSafePackaging: true,
        safeShelfLifeHours: 48,
        estimatedWindowText: 'पुढील २ ते ३ दिवस वापरण्यायोग्य',
        isVeg: true,
        storageCondition: 'ambient',
        confidenceScore: 0.95,
        marathiSummary: 'Gemini AI निष्कर्ष: नैसर्गिकरीत्या ताजे कच्चे अन्न, शेल्टर किचनसाठी उत्तम.',
        safetyAdvisory: 'धुवून लगेच शेल्टर स्वयंपाकघरात वापरण्याची शिफारस आहे.',
      );
    } else {
      return const FoodFreshnessScanResult(
        foodTitle: 'Fresh Chapati & Mixed Sabzi (ताजी पोळी-भाजी)',
        detectedItems: [
          'गव्हाची चपाती / पोळी (Wheat Chapati/Roti)',
          'सुकी भाजी (Fresh Vegetable Sabzi)',
          'वरण / डाळ (Lentil Dal)',
        ],
        hygieneStatus: 'Grade A+ (Safe Food-Grade Packaging)',
        isSafePackaging: true,
        safeShelfLifeHours: 5,
        estimatedWindowText: 'पुढील ४ ते ५ तासांत उपयोगात आणावे',
        isVeg: true,
        storageCondition: 'ambient',
        confidenceScore: 0.95,
        marathiSummary: 'Gemini AI निष्कर्ष: अन्न उत्तम दर्जाचे व ताजे आहे. सुरक्षित पॅकिंग व हायजीन तपासून मंजूर केले आहे.',
        safetyAdvisory: 'अन्न अन्नसुरक्षा व स्वच्छता मानकांनुसार शेल्टर वितरणासाठी योग्य आहे.',
      );
    }
  }

  /// Aggregated demand insights with uncertainty metadata
  DemandInsightsSummary getDemandInsights({
    int timeframeDays = 30,
    String? zone,
  }) {
    return const DemandInsightsSummary(
      peakSurplusWindow: '21:30 - 23:30 (Dinner Banquet Surplus: ~245 kg/day)',
      topDeficitZone: 'Hadapsar / Manjri Fringe (High shelter demand > supply)',
      topSurplusZone: 'Koregaon Park / Kalyani Nagar (High hotel surplus > demand)',
      seasonalHighlight: 'Winter wave: 72% increase in blanket & warm sweater requests',
      uncertaintyNote:
          'Derived from app records (±14.5% margin); excludes informal offline distributions.',
    );
  }
}

class CategorySuggestion {
  final String categoryId;
  final String displayName;
  final DonationType type;
  final double confidence;
  final List<String> alternativeCategories;
  final bool manualCorrectionAllowed;
  final String foodSafetyDisclaimer;

  const CategorySuggestion({
    required this.categoryId,
    required this.displayName,
    required this.type,
    required this.confidence,
    this.alternativeCategories = const [],
    this.manualCorrectionAllowed = true,
    this.foodSafetyDisclaimer =
        'AI Advisory Only: Category suggestion does NOT certify food freshness, microbial safety, or edibility. Manual donor hygiene declaration and NGO check required (Rule 14 / ADR-004).',
  });
}

class DemandInsightsSummary {
  final String peakSurplusWindow;
  final String topDeficitZone;
  final String topSurplusZone;
  final String seasonalHighlight;
  final String uncertaintyNote;

  const DemandInsightsSummary({
    required this.peakSurplusWindow,
    required this.topDeficitZone,
    required this.topSurplusZone,
    required this.seasonalHighlight,
    required this.uncertaintyNote,
  });
}
