abstract interface class ConnectivityService {
  Future<bool> canReach(String baseUrl);
}
