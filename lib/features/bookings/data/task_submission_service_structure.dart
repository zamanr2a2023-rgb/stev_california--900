/// Service structure for task submission – mirrors just_tsx_code serviceStructure.ts.
library;

class TaskSubSection {
  const TaskSubSection({required this.id, required this.name, this.basePrice});
  final String id;
  final String name;
  final double? basePrice;
}

class TaskAddOn {
  const TaskAddOn({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;
}

class TaskServiceStructure {
  const TaskServiceStructure({
    required this.categoryId,
    required this.categoryName,
    required this.subSections,
    required this.addOns,
  });
  final String categoryId;
  final String categoryName;
  final List<TaskSubSection> subSections;
  final List<TaskAddOn> addOns;
}

/// Same data as React SERVICE_STRUCTURES.
final List<TaskServiceStructure> taskServiceStructures = [
  TaskServiceStructure(
    categoryId: 'cat1',
    categoryName: 'Residential Cleaning',
    subSections: const [
      TaskSubSection(id: 'regular-cleaning', name: 'Regular Cleaning', basePrice: 80),
      TaskSubSection(id: 'deep-cleaning', name: 'Deep Cleaning', basePrice: 150),
      TaskSubSection(id: 'move-in-out', name: 'Move-In / Move-Out', basePrice: 200),
    ],
    addOns: const [
      TaskAddOn(id: 'inside-fridge', name: 'Inside fridge', price: 25),
      TaskAddOn(id: 'inside-oven', name: 'Inside oven', price: 30),
      TaskAddOn(id: 'inside-cabinets', name: 'Inside cabinets', price: 40),
      TaskAddOn(id: 'window-cleaning', name: 'Window cleaning', price: 35),
      TaskAddOn(id: 'balcony', name: 'Balcony', price: 20),
      TaskAddOn(id: 'extra-rooms', name: 'Extra rooms', price: 50),
      TaskAddOn(id: 'extra-bathrooms', name: 'Extra bathrooms', price: 40),
    ],
  ),
  TaskServiceStructure(
    categoryId: 'cat2',
    categoryName: 'Commercial Cleaning',
    subSections: const [
      TaskSubSection(id: 'office-cleaning', name: 'Office Cleaning', basePrice: 120),
      TaskSubSection(id: 'shop-store-cleaning', name: 'Shop / Store Cleaning', basePrice: 150),
    ],
    addOns: const [
      TaskAddOn(id: 'carpet-shampoo', name: 'Carpet shampoo', price: 60),
      TaskAddOn(id: 'window-cleaning', name: 'Window cleaning', price: 45),
      TaskAddOn(id: 'trash-removal', name: 'Trash removal', price: 30),
      TaskAddOn(id: 'after-hours-service', name: 'After-hours service', price: 50),
    ],
  ),
  TaskServiceStructure(
    categoryId: 'cat3',
    categoryName: 'Contract Cleaning',
    subSections: const [
      TaskSubSection(id: 'daily', name: 'Daily', basePrice: 500),
      TaskSubSection(id: 'weekly', name: 'Weekly', basePrice: 300),
      TaskSubSection(id: 'monthly', name: 'Monthly', basePrice: 800),
    ],
    addOns: const [
      TaskAddOn(id: 'weekend-service', name: 'Weekend service', price: 100),
      TaskAddOn(id: 'early-morning-late-night', name: 'Early morning / late night', price: 75),
      TaskAddOn(id: 'extra-rooms', name: 'Extra rooms', price: 150),
    ],
  ),
  TaskServiceStructure(
    categoryId: 'cat4',
    categoryName: 'Floor Waxing',
    subSections: const [
      TaskSubSection(id: 'residential', name: 'Residential', basePrice: 100),
      TaskSubSection(id: 'commercial', name: 'Commercial', basePrice: 200),
    ],
    addOns: const [
      TaskAddOn(id: 'strip-old-wax', name: 'Strip old wax', price: 50),
      TaskAddOn(id: 'extra-polish', name: 'Extra polish', price: 40),
      TaskAddOn(id: 'stairs', name: 'Stairs', price: 60),
    ],
  ),
  TaskServiceStructure(
    categoryId: 'cat5',
    categoryName: 'Pressure Washing',
    subSections: const [
      TaskSubSection(id: 'driveways', name: 'Driveways', basePrice: 80),
      TaskSubSection(id: 'patios', name: 'Patios', basePrice: 70),
      TaskSubSection(id: 'sidewalks', name: 'Sidewalks', basePrice: 60),
      TaskSubSection(id: 'building-exterior', name: 'Building exterior', basePrice: 150),
    ],
    addOns: const [
      TaskAddOn(id: 'oil-stain-removal', name: 'Oil stain removal', price: 40),
      TaskAddOn(id: 'fence', name: 'Fence', price: 50),
      TaskAddOn(id: 'deck', name: 'Deck', price: 60),
      TaskAddOn(id: 'garage-floor', name: 'Garage floor', price: 45),
    ],
  ),
  TaskServiceStructure(
    categoryId: 'cat6',
    categoryName: 'Grass Cutting',
    subSections: const [
      TaskSubSection(id: 'small-yard', name: 'Small yard', basePrice: 40),
      TaskSubSection(id: 'medium-yard', name: 'Medium yard', basePrice: 60),
      TaskSubSection(id: 'large-yard', name: 'Large yard', basePrice: 90),
    ],
    addOns: const [
      TaskAddOn(id: 'edge-trimming', name: 'Edge trimming', price: 15),
      TaskAddOn(id: 'weed-removal', name: 'Weed removal', price: 25),
      TaskAddOn(id: 'leaf-cleanup', name: 'Leaf cleanup', price: 30),
      TaskAddOn(id: 'waste-removal', name: 'Waste removal', price: 20),
    ],
  ),
  TaskServiceStructure(
    categoryId: 'cat7',
    categoryName: 'Snow Removal',
    subSections: const [
      TaskSubSection(id: 'driveways', name: 'Driveways', basePrice: 50),
      TaskSubSection(id: 'walkways', name: 'Walkways', basePrice: 35),
      TaskSubSection(id: 'commercial-lots', name: 'Commercial lots', basePrice: 150),
    ],
    addOns: const [
      TaskAddOn(id: 'ice-treatment', name: 'Ice treatment', price: 30),
      TaskAddOn(id: 'roof-snow', name: 'Roof snow', price: 100),
      TaskAddOn(id: 'emergency-same-day', name: 'Emergency same-day', price: 75),
    ],
  ),
  TaskServiceStructure(
    categoryId: 'cat8',
    categoryName: 'Laundry',
    subSections: const [
      TaskSubSection(id: 'wash-dry', name: 'Wash & Dry', basePrice: 30),
      TaskSubSection(id: 'wash-dry-fold', name: 'Wash, Dry & Fold', basePrice: 45),
      TaskSubSection(id: 'ironing', name: 'Ironing', basePrice: 50),
    ],
    addOns: const [
      TaskAddOn(id: 'express', name: 'Express', price: 20),
      TaskAddOn(id: 'delicate', name: 'Delicate', price: 15),
      TaskAddOn(id: 'bedding', name: 'Bedding', price: 25),
    ],
  ),
];

TaskServiceStructure? getTaskServiceStructure(String categoryId) {
  try {
    return taskServiceStructures.firstWhere((s) => s.categoryId == categoryId);
  } catch (_) {
    return null;
  }
}
