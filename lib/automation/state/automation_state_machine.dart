import '../engine/automation_exception.dart';
import 'automation_state.dart';

final class AutomationStateMachine {
  AutomationStateMachine({this.current = AutomationState.idle});

  AutomationState current;

  static const _allowed = <AutomationState, Set<AutomationState>>{
    AutomationState.idle: {
      AutomationState.openingPortal,
      AutomationState.cancelled,
      AutomationState.failed,
    },
    AutomationState.openingPortal: {
      AutomationState.waitingForPage,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.waitingForPage: {
      AutomationState.detectingSession,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.detectingSession: {
      AutomationState.waitingForLogin,
      AutomationState.navigating,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.waitingForLogin: {
      AutomationState.detectingSession,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.navigating: {
      AutomationState.fillingClient,
      AutomationState.waitingForManualReview,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.fillingClient: {
      AutomationState.validating,
      AutomationState.waitingForManualReview,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.fillingConditions: {
      AutomationState.fillingProducts,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.fillingProducts: {
      AutomationState.uploadingFiles,
      AutomationState.validating,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.uploadingFiles: {
      AutomationState.validating,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.validating: {
      AutomationState.waitingForManualReview,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.waitingForManualReview: {
      AutomationState.detectingResult,
      AutomationState.cancelling,
      AutomationState.failed,
    },
    AutomationState.submitting: {
      AutomationState.detectingResult,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.detectingResult: {
      AutomationState.completed,
      AutomationState.waitingForManualReview,
      AutomationState.failed,
      AutomationState.cancelling,
    },
    AutomationState.completed: {},
    AutomationState.cancelling: {AutomationState.cancelled},
    AutomationState.cancelled: {},
    AutomationState.failed: {},
  };

  AutomationStateChange transitionTo(
    AutomationState next, {
    required String message,
    required double progress,
    String? error,
  }) {
    if (!(_allowed[current] ?? const {}).contains(next)) {
      throw AutomationException(
        'Transición no permitida: ${current.name} → ${next.name}.',
        code: 'INVALID_STATE_TRANSITION',
      );
    }
    final previous = current;
    current = next;
    return AutomationStateChange(
      previous: previous,
      current: next,
      timestamp: DateTime.now(),
      message: message,
      progress: progress.clamp(0, 1).toDouble(),
      error: error,
    );
  }
}
