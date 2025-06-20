import 'package:flutter/widgets.dart';

class ValidationNotification extends Notification {
  ValidationNotification(this.hash, this.valid);
  final int hash;
  final bool valid;

  @override
  String toString() {
    return 'ValidationNotification($hash, $valid)';
  }
}

class ValidationNotifier extends ChangeNotifier {
  bool valid = false;

  void update(bool value) {
    if (value != valid) {
      valid = value;
      notifyListeners();
    }
  }
}

class _FormValidationNotificationScope extends InheritedWidget {
  const _FormValidationNotificationScope({
    required super.child,
    required this.notifier,
  });

  final ValidationNotifier notifier;

  static ValidationNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_FormValidationNotificationScope>()!
        .notifier;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) {
    return false;
  }
}

class FormValidationBuilder extends StatefulWidget {
  const FormValidationBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, bool valid) builder;

  @override
  State<FormValidationBuilder> createState() => _FormValidationBuilderState();
}

class _FormValidationBuilderState extends State<FormValidationBuilder> {
  @override
  Widget build(BuildContext context) {
    final notifier = _FormValidationNotificationScope.of(context);
    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) {
        return widget.builder(context, notifier.valid);
      },
    );
  }
}

class FormValidationListener extends StatefulWidget {
  const FormValidationListener({
    super.key,
    required this.child,
    this.onChanged,
  });

  final Widget child;
  final ValueChanged<bool>? onChanged;

  @override
  State<FormValidationListener> createState() => _FormValidationListenerState();
}

class _FormValidationListenerState extends State<FormValidationListener> {
  final ValidationNotifier notifer = ValidationNotifier();
  final set = <ValidationNotification>{};
  bool? lastState;
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ValidationNotification>(
      onNotification: (notification) {
        set.removeWhere((n) {
          return n.hash == notification.hash;
        });

        set.add(notification);
        final valid = set.every((e) => e.valid);

        if (valid == lastState) return true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          notifer.update(valid);
        });
        lastState = valid;
        return true;
      },
      child: _FormValidationNotificationScope(
        notifier: notifer,
        child: widget.child,
      ),
    );
  }
}

class AppForm extends Form {
  AppForm({
    required Widget child,
    super.autovalidateMode,
    super.canPop,
    super.key,
    super.onChanged,
    super.onPopInvokedWithResult,
  }) : super(child: FormValidationListener(child: child));
}
