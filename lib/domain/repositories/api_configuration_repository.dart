abstract interface class ApiConfigurationRepository {
  Future<String> getBaseUrl();
  Future<void> setBaseUrl(String value);
}
