enum WindowSizeClass { compact, medium, expanded }

abstract final class AppBreakpoints {
  static const compact = 600.0;
  static const expanded = 840.0;

  static WindowSizeClass of(double width) {
    if (width < compact) return WindowSizeClass.compact;
    if (width < expanded) return WindowSizeClass.medium;
    return WindowSizeClass.expanded;
  }
}
