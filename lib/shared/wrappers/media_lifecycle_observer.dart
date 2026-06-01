import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/bloc/media_bloc.dart';

/// Re-checks media permissions when the user returns from system settings.
class MediaLifecycleObserver extends StatefulWidget {
  const MediaLifecycleObserver({super.key, required this.child});

  final Widget child;

  @override
  State<MediaLifecycleObserver> createState() => _MediaLifecycleObserverState();
}

class _MediaLifecycleObserverState extends State<MediaLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;

    final mediaState = context.read<MediaBloc>().state;
    if (!mediaState.isPermissionGranted && !mediaState.isLoading) {
      context.read<MediaBloc>().add(LoadMediaEvent());
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
