/// Weight estimation database
/// Contains density, typical dimensions, and weight ranges for common objects
/// Used when ML model detects an object category

class ObjectWeightData {
  final String label;
  final String displayName;
  final String displayNameHindi;
  final double minWeight; // grams
  final double maxWeight; // grams
  final double avgWeight; // grams
  final String unit;
  final String category;
  final String icon;
  final double confidenceMultiplier;

  const ObjectWeightData({
    required this.label,
    required this.displayName,
    required this.displayNameHindi,
    required this.minWeight,
    required this.maxWeight,
    required this.avgWeight,
    this.unit = 'g',
    required this.category,
    required this.icon,
    this.confidenceMultiplier = 1.0,
  });

  double get avgWeightKg => avgWeight / 1000;
  double get minWeightKg => minWeight / 1000;
  double get maxWeightKg => maxWeight / 1000;

  String get formattedAvgWeight {
    if (avgWeight >= 1000) {
      return '${(avgWeight / 1000).toStringAsFixed(2)} kg';
    }
    return '${avgWeight.toStringAsFixed(0)} g';
  }

  String get formattedRange {
    String formatVal(double v) =>
        v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}kg' : '${v.toStringAsFixed(0)}g';
    return '${formatVal(minWeight)} – ${formatVal(maxWeight)}';
  }
}

class WeightDatabase {
  static const Map<String, ObjectWeightData> objects = {
    // ── FRUITS ──────────────────────────────────────────────
    'apple': ObjectWeightData(
      label: 'apple',
      displayName: 'Apple',
      displayNameHindi: 'सेब',
      minWeight: 100,
      maxWeight: 300,
      avgWeight: 182,
      category: 'fruit',
      icon: '🍎',
      confidenceMultiplier: 0.95,
    ),
    'banana': ObjectWeightData(
      label: 'banana',
      displayName: 'Banana',
      displayNameHindi: 'केला',
      minWeight: 80,
      maxWeight: 200,
      avgWeight: 118,
      category: 'fruit',
      icon: '🍌',
      confidenceMultiplier: 0.93,
    ),
    'orange': ObjectWeightData(
      label: 'orange',
      displayName: 'Orange',
      displayNameHindi: 'संतरा',
      minWeight: 130,
      maxWeight: 350,
      avgWeight: 200,
      category: 'fruit',
      icon: '🍊',
      confidenceMultiplier: 0.92,
    ),
    'mango': ObjectWeightData(
      label: 'mango',
      displayName: 'Mango',
      displayNameHindi: 'आम',
      minWeight: 150,
      maxWeight: 500,
      avgWeight: 300,
      category: 'fruit',
      icon: '🥭',
      confidenceMultiplier: 0.90,
    ),
    'grapes': ObjectWeightData(
      label: 'grapes',
      displayName: 'Grapes (bunch)',
      displayNameHindi: 'अंगूर',
      minWeight: 200,
      maxWeight: 800,
      avgWeight: 400,
      category: 'fruit',
      icon: '🍇',
      confidenceMultiplier: 0.85,
    ),
    'watermelon': ObjectWeightData(
      label: 'watermelon',
      displayName: 'Watermelon',
      displayNameHindi: 'तरबूज',
      minWeight: 2000,
      maxWeight: 10000,
      avgWeight: 5000,
      category: 'fruit',
      icon: '🍉',
      confidenceMultiplier: 0.80,
    ),
    'lemon': ObjectWeightData(
      label: 'lemon',
      displayName: 'Lemon',
      displayNameHindi: 'नींबू',
      minWeight: 50,
      maxWeight: 120,
      avgWeight: 84,
      category: 'fruit',
      icon: '🍋',
      confidenceMultiplier: 0.91,
    ),
    'pineapple': ObjectWeightData(
      label: 'pineapple',
      displayName: 'Pineapple',
      displayNameHindi: 'अनानास',
      minWeight: 700,
      maxWeight: 2000,
      avgWeight: 900,
      category: 'fruit',
      icon: '🍍',
      confidenceMultiplier: 0.88,
    ),
    'coconut': ObjectWeightData(
      label: 'coconut',
      displayName: 'Coconut',
      displayNameHindi: 'नारियल',
      minWeight: 400,
      maxWeight: 1500,
      avgWeight: 650,
      category: 'fruit',
      icon: '🥥',
      confidenceMultiplier: 0.87,
    ),

    // ── VEGETABLES ──────────────────────────────────────────
    'tomato': ObjectWeightData(
      label: 'tomato',
      displayName: 'Tomato',
      displayNameHindi: 'टमाटर',
      minWeight: 80,
      maxWeight: 300,
      avgWeight: 150,
      category: 'vegetable',
      icon: '🍅',
      confidenceMultiplier: 0.93,
    ),
    'potato': ObjectWeightData(
      label: 'potato',
      displayName: 'Potato',
      displayNameHindi: 'आलू',
      minWeight: 100,
      maxWeight: 400,
      avgWeight: 200,
      category: 'vegetable',
      icon: '🥔',
      confidenceMultiplier: 0.91,
    ),
    'onion': ObjectWeightData(
      label: 'onion',
      displayName: 'Onion',
      displayNameHindi: 'प्याज',
      minWeight: 100,
      maxWeight: 300,
      avgWeight: 175,
      category: 'vegetable',
      icon: '🧅',
      confidenceMultiplier: 0.90,
    ),
    'broccoli': ObjectWeightData(
      label: 'broccoli',
      displayName: 'Broccoli',
      displayNameHindi: 'ब्रोकोली',
      minWeight: 200,
      maxWeight: 600,
      avgWeight: 370,
      category: 'vegetable',
      icon: '🥦',
      confidenceMultiplier: 0.88,
    ),
    'carrot': ObjectWeightData(
      label: 'carrot',
      displayName: 'Carrot',
      displayNameHindi: 'गाजर',
      minWeight: 50,
      maxWeight: 200,
      avgWeight: 100,
      category: 'vegetable',
      icon: '🥕',
      confidenceMultiplier: 0.90,
    ),

    // ── ELECTRONICS ─────────────────────────────────────────
    'cell phone': ObjectWeightData(
      label: 'cell phone',
      displayName: 'Smartphone',
      displayNameHindi: 'स्मार्टफोन',
      minWeight: 130,
      maxWeight: 260,
      avgWeight: 180,
      category: 'electronics',
      icon: '📱',
      confidenceMultiplier: 0.95,
    ),
    'laptop': ObjectWeightData(
      label: 'laptop',
      displayName: 'Laptop',
      displayNameHindi: 'लैपटॉप',
      minWeight: 900,
      maxWeight: 3500,
      avgWeight: 1800,
      category: 'electronics',
      icon: '💻',
      confidenceMultiplier: 0.88,
    ),
    'keyboard': ObjectWeightData(
      label: 'keyboard',
      displayName: 'Keyboard',
      displayNameHindi: 'कीबोर्ड',
      minWeight: 400,
      maxWeight: 2000,
      avgWeight: 800,
      category: 'electronics',
      icon: '⌨️',
      confidenceMultiplier: 0.85,
    ),
    'mouse': ObjectWeightData(
      label: 'mouse',
      displayName: 'Computer Mouse',
      displayNameHindi: 'माउस',
      minWeight: 60,
      maxWeight: 180,
      avgWeight: 100,
      category: 'electronics',
      icon: '🖱️',
      confidenceMultiplier: 0.90,
    ),
    'remote control': ObjectWeightData(
      label: 'remote control',
      displayName: 'Remote Control',
      displayNameHindi: 'रिमोट',
      minWeight: 80,
      maxWeight: 200,
      avgWeight: 130,
      category: 'electronics',
      icon: '📺',
      confidenceMultiplier: 0.87,
    ),

    // ── FOOD ITEMS ──────────────────────────────────────────
    'pizza': ObjectWeightData(
      label: 'pizza',
      displayName: 'Pizza (slice)',
      displayNameHindi: 'पिज्जा',
      minWeight: 100,
      maxWeight: 300,
      avgWeight: 180,
      category: 'food',
      icon: '🍕',
      confidenceMultiplier: 0.82,
    ),
    'hamburger': ObjectWeightData(
      label: 'hamburger',
      displayName: 'Burger',
      displayNameHindi: 'बर्गर',
      minWeight: 150,
      maxWeight: 400,
      avgWeight: 230,
      category: 'food',
      icon: '🍔',
      confidenceMultiplier: 0.82,
    ),
    'bread': ObjectWeightData(
      label: 'bread',
      displayName: 'Bread Loaf',
      displayNameHindi: 'ब्रेड',
      minWeight: 300,
      maxWeight: 800,
      avgWeight: 500,
      category: 'food',
      icon: '🍞',
      confidenceMultiplier: 0.85,
    ),
    'cake': ObjectWeightData(
      label: 'cake',
      displayName: 'Cake',
      displayNameHindi: 'केक',
      minWeight: 300,
      maxWeight: 2000,
      avgWeight: 800,
      category: 'food',
      icon: '🎂',
      confidenceMultiplier: 0.80,
    ),
    'egg': ObjectWeightData(
      label: 'egg',
      displayName: 'Egg',
      displayNameHindi: 'अंडा',
      minWeight: 45,
      maxWeight: 80,
      avgWeight: 60,
      category: 'food',
      icon: '🥚',
      confidenceMultiplier: 0.96,
    ),

    // ── CONTAINERS & BOTTLES ────────────────────────────────
    'bottle': ObjectWeightData(
      label: 'bottle',
      displayName: 'Water Bottle (full)',
      displayNameHindi: 'पानी की बोतल',
      minWeight: 300,
      maxWeight: 1500,
      avgWeight: 750,
      category: 'container',
      icon: '🍶',
      confidenceMultiplier: 0.85,
    ),
    'cup': ObjectWeightData(
      label: 'cup',
      displayName: 'Cup',
      displayNameHindi: 'कप',
      minWeight: 100,
      maxWeight: 400,
      avgWeight: 200,
      category: 'container',
      icon: '☕',
      confidenceMultiplier: 0.83,
    ),
    'bowl': ObjectWeightData(
      label: 'bowl',
      displayName: 'Bowl',
      displayNameHindi: 'कटोरा',
      minWeight: 150,
      maxWeight: 600,
      avgWeight: 300,
      category: 'container',
      icon: '🥣',
      confidenceMultiplier: 0.82,
    ),

    // ── BOOKS & STATIONERY ──────────────────────────────────
    'book': ObjectWeightData(
      label: 'book',
      displayName: 'Book',
      displayNameHindi: 'किताब',
      minWeight: 150,
      maxWeight: 1200,
      avgWeight: 450,
      category: 'stationery',
      icon: '📚',
      confidenceMultiplier: 0.88,
    ),

    // ── SPORTS ──────────────────────────────────────────────
    'sports ball': ObjectWeightData(
      label: 'sports ball',
      displayName: 'Ball',
      displayNameHindi: 'गेंद',
      minWeight: 40,
      maxWeight: 600,
      avgWeight: 280,
      category: 'sports',
      icon: '⚽',
      confidenceMultiplier: 0.85,
    ),

    // ── ANIMALS ─────────────────────────────────────────────
    'cat': ObjectWeightData(
      label: 'cat',
      displayName: 'Cat',
      displayNameHindi: 'बिल्ली',
      minWeight: 2500,
      maxWeight: 6000,
      avgWeight: 4000,
      category: 'animal',
      icon: '🐱',
      confidenceMultiplier: 0.75,
    ),
    'dog': ObjectWeightData(
      label: 'dog',
      displayName: 'Dog',
      displayNameHindi: 'कुत्ता',
      minWeight: 2000,
      maxWeight: 80000,
      avgWeight: 20000,
      category: 'animal',
      icon: '🐕',
      confidenceMultiplier: 0.70,
    ),
  };

  /// Find best match for detected label
  static ObjectWeightData? findMatch(String detectedLabel) {
    final lower = detectedLabel.toLowerCase().trim();

    // Direct match
    if (objects.containsKey(lower)) return objects[lower];

    // Partial match
    for (final entry in objects.entries) {
      if (lower.contains(entry.key) || entry.key.contains(lower)) {
        return entry.value;
      }
    }

    // Keyword search
    final keywords = lower.split(' ');
    for (final keyword in keywords) {
      if (keyword.length > 3) {
        for (final entry in objects.entries) {
          if (entry.key.contains(keyword)) return entry.value;
        }
      }
    }

    return null;
  }

  static List<ObjectWeightData> get allObjects => objects.values.toList();
  
  static List<ObjectWeightData> getByCategory(String cat) =>
      objects.values.where((o) => o.category == cat).toList();
}
