abstract final class ApiEndpoints {
  static const login = '/auth/login';
  static const clients = '/clients';
  static const products = '/products';
  static const executions = '/executions';
  static const history = '/history';

  static String execution(String id) => '/executions/$id';
  static String historyRecord(String id) => '/history/$id';
}
