import 'package:flutter/material.dart';

import 'finance_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await FinanceStore.load();
  runApp(PulseFinanceApp(store: store));
}
