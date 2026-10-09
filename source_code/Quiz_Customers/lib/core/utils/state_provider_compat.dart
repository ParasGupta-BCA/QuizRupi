import 'package:flutter_riverpod/flutter_riverpod.dart';

class StateController<T> extends Notifier<T> {
  final T Function(Ref) _create;
  StateController(this._create);

  @override
  T build() => _create(ref);

  @override
  T get state => super.state;

  @override
  set state(T value) => super.state = value;
}

NotifierProvider<StateController<T>, T> StateProvider<T>(T Function(Ref ref) create) {
  return NotifierProvider<StateController<T>, T>(() => StateController<T>(create));
}
