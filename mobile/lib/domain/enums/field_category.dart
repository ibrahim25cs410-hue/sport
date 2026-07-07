enum FieldCategory {
  fiveVfive('5v5'),
  sevenVseven('7v7'),
  elevenVeleven('11v11'),
  indoor('indoor'),
  outdoor('outdoor');

  const FieldCategory(this.value);
  final String value;

  static FieldCategory fromString(String? raw) => FieldCategory.values.firstWhere(
        (c) => c.value == raw,
        orElse: () => FieldCategory.fiveVfive,
      );
}
