enum AutomationState {
  idle,
  openingPortal,
  waitingForPage,
  detectingSession,
  waitingForLogin,
  navigating,
  fillingClient,
  fillingConditions,
  fillingProducts,
  uploadingFiles,
  validating,
  waitingForManualReview,
  submitting,
  detectingResult,
  completed,
  cancelling,
  cancelled,
  failed,
}

extension AutomationStateLabel on AutomationState {
  String get label => switch (this) {
    AutomationState.idle => 'En espera',
    AutomationState.openingPortal => 'Abriendo Automy',
    AutomationState.waitingForPage => 'Esperando página',
    AutomationState.detectingSession => 'Detectando sesión',
    AutomationState.waitingForLogin => 'Esperando inicio de sesión',
    AutomationState.navigating => 'Navegando',
    AutomationState.fillingClient => 'Completando cliente',
    AutomationState.fillingConditions => 'Completando condiciones',
    AutomationState.fillingProducts => 'Completando productos',
    AutomationState.uploadingFiles => 'Adjuntando archivos',
    AutomationState.validating => 'Validando formulario',
    AutomationState.waitingForManualReview => 'Esperando revisión manual',
    AutomationState.submitting => 'Enviando',
    AutomationState.detectingResult => 'Detectando resultado',
    AutomationState.completed => 'Completado',
    AutomationState.cancelling => 'Cancelando',
    AutomationState.cancelled => 'Cancelado',
    AutomationState.failed => 'Fallido',
  };

  bool get isTerminal => switch (this) {
    AutomationState.completed ||
    AutomationState.cancelled ||
    AutomationState.failed => true,
    _ => false,
  };
}

final class AutomationStateChange {
  const AutomationStateChange({
    required this.previous,
    required this.current,
    required this.timestamp,
    required this.message,
    required this.progress,
    this.error,
  });

  final AutomationState previous;
  final AutomationState current;
  final DateTime timestamp;
  final String message;
  final double progress;
  final String? error;
}
