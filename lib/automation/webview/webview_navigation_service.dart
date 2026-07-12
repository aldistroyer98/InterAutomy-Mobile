import '../../core/security/webview_security_policy.dart';

enum NavigationPermission { allow, blockInWebView }

final class WebViewNavigationService {
  const WebViewNavigationService(this.policy);

  final WebViewSecurityPolicy policy;

  NavigationPermission evaluate(Uri uri) => policy.isAllowedUri(uri)
      ? NavigationPermission.allow
      : NavigationPermission.blockInWebView;
}
