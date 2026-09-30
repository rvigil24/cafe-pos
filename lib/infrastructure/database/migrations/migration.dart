class Migration {
  const Migration({required this.version, required this.sql});

  final int version;
  final String sql;
}
