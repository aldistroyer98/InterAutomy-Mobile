final class SelectorDefinition {
  const SelectorDefinition({
    required this.key,
    required this.alternatives,
    required this.description,
    required this.expectedPage,
    required this.required,
    required this.version,
  });

  final String key;
  final List<String> alternatives;
  final String description;
  final String expectedPage;
  final bool required;
  final String version;
}
