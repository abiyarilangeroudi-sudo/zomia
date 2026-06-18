class BusinessCategoryOption {
  const BusinessCategoryOption({required this.value, required this.label});

  final String value;
  final String label;
}

const businessCategoryOptions = [
  BusinessCategoryOption(value: 'cafe', label: 'Cafe'),
  BusinessCategoryOption(value: 'restaurant', label: 'Restaurant'),
  BusinessCategoryOption(value: 'bakery', label: 'Bakery'),
  BusinessCategoryOption(value: 'retail', label: 'Retail'),
  BusinessCategoryOption(value: 'beauty_wellness', label: 'Beauty & Wellness'),
  BusinessCategoryOption(value: 'fitness', label: 'Fitness'),
  BusinessCategoryOption(value: 'entertainment', label: 'Entertainment'),
  BusinessCategoryOption(value: 'services', label: 'Services'),
  BusinessCategoryOption(value: 'barbershops', label: 'Barbershops'),
  BusinessCategoryOption(value: 'other', label: 'Other'),
];
