class MockUser {
  const MockUser({
    required this.name,
    required this.email,
    required this.skinType,
    required this.goal,
    required this.concerns,
  });

  final String name;
  final String email;
  final String skinType;
  final String goal;
  final List<String> concerns;
}

class MockMetric {
  const MockMetric(this.label, this.value, this.trend);

  final String label;
  final String value;
  final String trend;
}

class AnalysisMetric {
  const AnalysisMetric(this.label, this.value);

  final String label;
  final int value;
}

class AnalysisResult {
  const AnalysisResult({
    required this.skinType,
    required this.confidence,
    required this.concerns,
    required this.metrics,
    required this.recommendation,
    required this.score,
    this.imageUrl,
  });

  final String skinType;
  final int confidence;
  final List<String> concerns;
  final List<AnalysisMetric> metrics;
  final String recommendation;
  final int score;
  final String? imageUrl;
}

class RoutineStep {
  const RoutineStep({
    required this.category,
    required this.productName,
    required this.brand,
    required this.price,
    required this.instruction,
    this.warning,
    this.imageUrl,
  });

  final String category;
  final String productName;
  final String brand;
  final String price;
  final String instruction;
  final String? warning;
  final String? imageUrl;
}

class ProgressLog {
  const ProgressLog({
    required this.date,
    required this.skinFeeling,
    required this.acneLevel,
    required this.hydration,
  });

  final String date;
  final String skinFeeling;
  final String acneLevel;
  final String hydration;
}

class AdminMetric {
  const AdminMetric(this.label, this.value);

  final String label;
  final String value;
}

class MockSkinData {
  static const user = MockUser(
    name: 'Linh Nguyen',
    email: 'linh@skinsync.app',
    skinType: 'Combination',
    goal: 'Calm redness and strengthen barrier',
    concerns: ['Acne', 'Dryness', 'Redness'],
  );

  static const landingStats = [
    MockMetric('Users', '50K+', 'Growing every week'),
    MockMetric('Profiles analyzed', '2400+', 'AI scans completed'),
    MockMetric('Routine generated', '18K+', 'Personalized plans'),
    MockMetric('Satisfaction', '4.9/5', 'Premium support'),
  ];

  static const analysis = AnalysisResult(
    skinType: 'Combination Skin',
    confidence: 87,
    concerns: ['Acne', 'Dryness', 'Redness'],
    metrics: [
      AnalysisMetric('Hydration', 72),
      AnalysisMetric('Oil Balance', 45),
      AnalysisMetric('Texture', 83),
      AnalysisMetric('Pores', 58),
    ],
    recommendation: 'Keep the routine gentle, repair the barrier, and introduce actives slowly.',
    score: 82,
    imageUrl: 'https://images.unsplash.com/photo-1590110348915-993aca51ea03?w=900',
  );

  static const morningRoutine = [
    RoutineStep(
      category: 'Cleanser',
      productName: 'Gentle Cloud Cleanser',
      brand: 'SkinSync Lab',
      price: '\$22',
      instruction: 'Massage on damp skin for 60 seconds, then rinse with lukewarm water.',
      imageUrl: 'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=500',
    ),
    RoutineStep(
      category: 'Serum',
      productName: 'Balance Niacinamide Serum',
      brand: 'SkinSync Lab',
      price: '\$36',
      instruction: 'Apply 2-3 drops across cheeks and forehead before moisturizer.',
    ),
    RoutineStep(
      category: 'Moisturizer',
      productName: 'Barrier Comfort Cream',
      brand: 'SkinSync Lab',
      price: '\$32',
      instruction: 'Seal hydration with a thin layer, focusing on dry areas.',
    ),
    RoutineStep(
      category: 'Sunscreen',
      productName: 'Daily Veil SPF 50',
      brand: 'SkinSync Lab',
      price: '\$28',
      instruction: 'Finish with two finger lengths of sunscreen before leaving indoors.',
      warning: 'Avoid layering with exfoliating acids in the same morning if your skin feels irritated.',
    ),
  ];

  static const eveningRoutine = [
    RoutineStep(
      category: 'Cleanser',
      productName: 'Gentle Cloud Cleanser',
      brand: 'SkinSync Lab',
      price: '\$22',
      instruction: 'Double cleanse when wearing makeup or sunscreen.',
    ),
    RoutineStep(
      category: 'Treatment',
      productName: 'Calm & Clear Spot Gel',
      brand: 'SkinSync Lab',
      price: '\$24',
      instruction: 'Apply to active breakouts only after cleansing.',
      warning: 'Do not combine with retinol on the same night.',
    ),
    RoutineStep(
      category: 'Moisturizer',
      productName: 'Barrier Comfort Cream',
      brand: 'SkinSync Lab',
      price: '\$32',
      instruction: 'Use a richer layer at night to support recovery.',
    ),
  ];

  static const progressLogs = [
    ProgressLog(date: 'Mon, Jun 08', skinFeeling: 'Calm', acneLevel: '2/5', hydration: '4/5'),
    ProgressLog(date: 'Tue, Jun 09', skinFeeling: 'Balanced', acneLevel: '2/5', hydration: '4/5'),
    ProgressLog(date: 'Wed, Jun 10', skinFeeling: 'Slight redness', acneLevel: '3/5', hydration: '3/5'),
  ];

  static const adminMetrics = [
    AdminMetric('Total users', '12,480'),
    AdminMetric('Active users', '7,920'),
    AdminMetric('Products', '486'),
    AdminMetric('AI analyses', '31,204'),
  ];

  static const quizSkinTypes = [
    'Oily',
    'Dry',
    'Combination',
    'Sensitive',
  ];

  static const quizConcerns = [
    'Acne',
    'Redness',
    'Dark Spots',
    'Dryness',
  ];

  static const budgets = [
    'Budget-friendly',
    'Mid-range',
    'Premium',
  ];
}
