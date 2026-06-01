import '../../core/imports/imports.dart';
import '../../core/bloc/media_bloc.dart';
import 'media_lifecycle_observer.dart';

/// A wrapper to initialize the chosen State Management library.
class StateWrapper extends StatelessWidget {
  final Widget child;

  const StateWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MediaBloc>(create: (_) => MediaBloc()..add(LoadMediaEvent())),
      ],
      child: MediaLifecycleObserver(child: child),
    );
  }
}
