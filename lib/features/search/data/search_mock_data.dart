/// Search screen mock data – mirrors just_tsx_code mockData.ts (PROVIDERS, SERVICE_CATEGORIES with townIds).
library;

class SearchCategory {
  const SearchCategory({
    required this.id,
    required this.name,
    required this.townIds,
  });
  final String id;
  final String name;
  final List<String> townIds;
}

class SearchProvider {
  const SearchProvider({
    required this.id,
    required this.name,
    required this.avatar,
    required this.rating,
    required this.reviewCount,
    required this.categoryId,
    required this.townIds,
    required this.distance,
    required this.responseTime,
  });
  final String id;
  final String name;
  final String avatar;
  final double rating;
  final int reviewCount;
  final String categoryId;
  final List<String> townIds;
  final String distance;
  final String responseTime;
}

/// Same 8 categories as React mockData.ts SERVICE_CATEGORIES.
const List<SearchCategory> searchCategories = [
  SearchCategory(id: 'residential-cleaning', name: 'Residential Cleaning', townIds: ['1', '2', '3', '4']),
  SearchCategory(id: 'commercial-cleaning', name: 'Commercial Cleaning', townIds: ['1', '2', '3', '4']),
  SearchCategory(id: 'contract-cleaning', name: 'Contract Cleaning', townIds: ['1', '2', '3']),
  SearchCategory(id: 'floor-waxing', name: 'Floor Waxing', townIds: ['1', '2', '4']),
  SearchCategory(id: 'pressure-washing', name: 'Pressure Washing', townIds: ['2', '3', '4']),
  SearchCategory(id: 'grass-cutting', name: 'Grass Cutting', townIds: ['1', '3', '4']),
  SearchCategory(id: 'snow-removal', name: 'Snow Removal', townIds: ['1', '2', '3']),
  SearchCategory(id: 'laundry', name: 'Laundry', townIds: ['1', '2', '4']),
];

/// Same 5 providers as React mockData.ts PROVIDERS.
const List<SearchProvider> searchProviders = [
  SearchProvider(
    id: '1',
    name: 'Sparkle Clean Services',
    avatar: '',
    rating: 5.0,
    reviewCount: 314,
    categoryId: 'residential-cleaning',
    townIds: ['1', '2', '4'],
    distance: '4.1 mi',
    responseTime: 'Usually responds in 1 hour',
  ),
  SearchProvider(
    id: '2',
    name: 'Pro Office Cleaners',
    avatar: '',
    rating: 4.8,
    reviewCount: 127,
    categoryId: 'commercial-cleaning',
    townIds: ['1', '2', '3'],
    distance: '2.3 mi',
    responseTime: 'Usually responds in 1 hour',
  ),
  SearchProvider(
    id: '3',
    name: 'Premium Pressure Wash',
    avatar: '',
    rating: 4.9,
    reviewCount: 203,
    categoryId: 'pressure-washing',
    townIds: ['2', '3', '4'],
    distance: '3.7 mi',
    responseTime: 'Usually responds in 2 hours',
  ),
  SearchProvider(
    id: '4',
    name: 'Green Lawn Care',
    avatar: '',
    rating: 4.7,
    reviewCount: 89,
    categoryId: 'grass-cutting',
    townIds: ['1', '3', '4'],
    distance: '1.2 mi',
    responseTime: 'Usually responds in 30 minutes',
  ),
  SearchProvider(
    id: '5',
    name: 'Quick Laundry Pro',
    avatar: '',
    rating: 4.6,
    reviewCount: 156,
    categoryId: 'laundry',
    townIds: ['1', '2', '4'],
    distance: '5.8 mi',
    responseTime: 'Usually responds in 3 hours',
  ),
];

String? categoryNameForId(String categoryId) {
  for (final c in searchCategories) {
    if (c.id == categoryId) return c.name;
  }
  return null;
}
