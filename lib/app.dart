import 'package:aura/core/imports/core_imports.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final current = _buildMaterialApp(context);
    return ScreenUtilWrapper(
      child: StateWrapper(child: current),
    );
  }

  Widget _buildMaterialApp(BuildContext context) {
    return MaterialApp.router(
      title: 'aura',
      debugShowCheckedModeBanner: false,
      theme: buildDarkTheme(primaryColorHex: '#00F1FE'),
      routerConfig: appRouter,
      builder: (context, child) => child!,
    );
  }
}
