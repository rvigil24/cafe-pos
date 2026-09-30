class AppSettings {
  const AppSettings({
    required this.businessName,
    required this.timezone,
    required this.lastOrderNumber,
  });

  final String businessName;
  final String timezone;
  final int lastOrderNumber;
}
