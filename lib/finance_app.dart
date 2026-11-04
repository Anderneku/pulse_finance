import 'dart:convert';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _background = Color(0xFF0B0B0D);
const _surface = Color(0xFF18181B);
const _surfaceRaised = Color(0xFF202024);
const _stroke = Color(0xFF2A2A30);
const _muted = Color(0xFF92929E);
const _green = Color(0xFF00C995);
const _red = Color(0xFFFF496B);

const _paletteColors = <String, Color>{
  'Violet Nova': Color(0xFFB343FF),
  'Cyber Emerald': Color(0xFF00C995),
  'Solar Amber': Color(0xFFFFA600),
  'Cyan Frost': Color(0xFF00BBD4),
  'Crimson Velvet': Color(0xFFF23963),
  'Zinc Pure': Color(0xFFF4F4F5),
};

const _starterCategories = <String>[
  'Food & Cafeteria',
  'Clothing & Laundry',
  'Personal Effects',
  'Books & Academics',
  'Hostel & Housing',
  'Transport & Shuttle',
  'Tech & Internet',
  'Entertainment',
  'Health & Pharmacy',
  'Allowance & Income',
];

const _currencies = <String, String>{
  'NGN': '₦',
  'USD': '\$',
  'GBP': '£',
  'EUR': '€',
};

class FinanceEntry {
  FinanceEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.income,
    this.method = 'POS Payment',
    this.notes = '',
  });

  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime date;
  final bool income;
  final String method;
  final String notes;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'amount': amount,
    'date': date.toIso8601String(),
    'income': income,
    'method': method,
    'notes': notes,
  };

  factory FinanceEntry.fromJson(Map<String, dynamic> json) => FinanceEntry(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    amount: (json['amount'] as num).toDouble(),
    date: DateTime.parse(json['date'] as String),
    income: json['income'] as bool? ?? false,
    method: json['method'] as String? ?? 'POS Payment',
    notes: json['notes'] as String? ?? '',
  );
}

class FinanceSettings {
  FinanceSettings({
    this.allowance = 150000,
    this.cycle = 'Monthly',
    required this.cycleStart,
    int? cycleAnchorDay,
    this.currency = 'NGN',
    this.palette = 'Violet Nova',
    this.dailyLimitEnabled = true,
    double? dailyLimit,
    this.autoRefill = true,
    this.thresholdAlert = true,
    this.overspendGuard = true,
    this.name = 'Chukuneku Nwanwene',
    this.university = 'Covenant University',
    this.major = 'Computer Science & Software',
    List<String>? categories,
  }) : cycleAnchorDay = cycleAnchorDay ?? cycleStart.day,
       dailyLimit = dailyLimit ?? allowance / 30,
       categories = categories ?? List.of(_starterCategories);

  double allowance;
  String cycle;
  DateTime cycleStart;
  int cycleAnchorDay;
  String currency;
  String palette;
  bool dailyLimitEnabled;
  double dailyLimit;
  bool autoRefill;
  bool thresholdAlert;
  bool overspendGuard;
  String name;
  String university;
  String major;
  List<String> categories;

  Map<String, Object?> toJson() => {
    'allowance': allowance,
    'cycle': cycle,
    'cycleStart': cycleStart.toIso8601String(),
    'cycleAnchorDay': cycleAnchorDay,
    'currency': currency,
    'palette': palette,
    'dailyLimitEnabled': dailyLimitEnabled,
    'dailyLimit': dailyLimit,
    'autoRefill': autoRefill,
    'thresholdAlert': thresholdAlert,
    'overspendGuard': overspendGuard,
    'name': name,
    'university': university,
    'major': major,
    'categories': categories,
  };

  factory FinanceSettings.fromJson(Map<String, dynamic> json) =>
      FinanceSettings(
        allowance: (json['allowance'] as num?)?.toDouble() ?? 150000,
        cycle: json['cycle'] as String? ?? 'Monthly',
        cycleStart:
            DateTime.tryParse(json['cycleStart'] as String? ?? '') ??
            DateTime.now(),
        cycleAnchorDay: json['cycleAnchorDay'] as int?,
        currency: json['currency'] as String? ?? 'NGN',
        palette: json['palette'] as String? ?? 'Violet Nova',
        dailyLimitEnabled: json['dailyLimitEnabled'] as bool? ?? true,
        dailyLimit: (json['dailyLimit'] as num?)?.toDouble(),
        autoRefill: json['autoRefill'] as bool? ?? true,
        thresholdAlert: json['thresholdAlert'] as bool? ?? true,
        overspendGuard: json['overspendGuard'] as bool? ?? true,
        name: json['name'] as String? ?? 'Student',
        university: json['university'] as String? ?? '',
        major: json['major'] as String? ?? '',
        categories: (json['categories'] as List<dynamic>?)?.cast<String>(),
      );
}

class FinanceStore extends ChangeNotifier {
  FinanceStore({
    FinanceSettings? settings,
    List<FinanceEntry>? entries,
    this.tutorialPending = false,
  }) : settings =
           settings ??
           FinanceSettings(
             cycleStart: DateTime(DateTime.now().year, DateTime.now().month),
           ),
       entries = entries ?? _demoEntries(DateTime.now());

  static const _storageKey = 'pulse_finance_data_v1';
  static const _tutorialKey = 'pulse_finance_tutorial_completed_v1';
  FinanceSettings settings;
  List<FinanceEntry> entries;
  bool tutorialPending;
  bool _persistEnabled = false;

  static List<FinanceEntry> _demoEntries(DateTime now) {
    final firstOfMonth = DateTime(now.year, now.month, 1);
    return [
      FinanceEntry(
        id: 'demo-credit',
        title: 'Allowance top-up',
        category: 'Allowance & Income',
        amount: 20000,
        date: firstOfMonth,
        income: true,
      ),
      FinanceEntry(
        id: 'demo-jersey',
        title: 'Jersey',
        category: 'Personal Effects',
        amount: 12500,
        date: firstOfMonth,
        income: false,
      ),
      FinanceEntry(
        id: 'demo-glasses',
        title: 'Glasses',
        category: 'Personal Effects',
        amount: 17000,
        date: firstOfMonth,
        income: false,
      ),
    ];
  }

  static Future<FinanceStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    final store = saved == null
        ? FinanceStore()
        : FinanceStore.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    store.tutorialPending = !(prefs.getBool(_tutorialKey) ?? false);
    store._persistEnabled = true;
    await store.advanceAllowanceCycle(DateTime.now());
    await store._save();
    return store;
  }

  factory FinanceStore.fromJson(Map<String, dynamic> json) {
    return FinanceStore(
      settings: FinanceSettings.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
      entries: (json['entries'] as List<dynamic>)
          .map((item) => FinanceEntry.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'settings': settings.toJson(),
    'entries': entries.map((entry) => entry.toJson()).toList(),
  };

  Future<void> _save() async {
    if (_persistEnabled) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(toJson()));
    }
  }

  Future<void> completeTutorial() async {
    tutorialPending = false;
    if (!_persistEnabled) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialKey, true);
  }

  Future<void> advanceAllowanceCycle(DateTime now) async {
    if (!settings.autoRefill) return;
    final today = DateTime(now.year, now.month, now.day);
    var changed = false;
    while (!today.isBefore(_dateOnly(_nextRefill))) {
      settings.cycleStart = _dateOnly(_nextRefill);
      changed = true;
    }
    if (changed) {
      await _save();
      notifyListeners();
    }
  }

  DateTime get _nextRefill {
    if (settings.cycle == 'Weekly') {
      return DateTime(
        settings.cycleStart.year,
        settings.cycleStart.month,
        settings.cycleStart.day + 7,
      );
    }
    final nextMonth = DateTime(
      settings.cycleStart.year,
      settings.cycleStart.month + 1,
      1,
    );
    final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    return DateTime(
      nextMonth.year,
      nextMonth.month,
      math.min(settings.cycleAnchorDay, lastDay),
    );
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  Future<void> addEntry(FinanceEntry entry) async {
    entries = [entry, ...entries];
    await _save();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    entries = entries.where((entry) => entry.id != id).toList();
    await _save();
    notifyListeners();
  }

  Future<void> updateSettings(FinanceSettings updated) async {
    settings = updated;
    await advanceAllowanceCycle(DateTime.now());
    await _save();
    notifyListeners();
  }

  Future<void> updateCycle(String cycle) async {
    settings.cycle = cycle;
    settings.cycleStart = DateTime.now();
    settings.cycleAnchorDay = settings.cycleStart.day;
    settings.dailyLimit = settings.allowance / (cycle == 'Weekly' ? 7 : 30);
    await _save();
    notifyListeners();
  }

  Future<void> importJson(Map<String, dynamic> json) async {
    final imported = FinanceStore.fromJson(json);
    settings = imported.settings;
    entries = imported.entries;
    await advanceAllowanceCycle(DateTime.now());
    await _save();
    notifyListeners();
  }

  Future<void> resetDemoData() async {
    final now = DateTime.now();
    settings = FinanceSettings(cycleStart: DateTime(now.year, now.month));
    entries = _demoEntries(DateTime.now());
    await _save();
    notifyListeners();
  }

  List<FinanceEntry> entriesInMonth(DateTime month) => entries
      .where(
        (entry) =>
            entry.date.year == month.year && entry.date.month == month.month,
      )
      .toList();

  List<FinanceEntry> entriesInCycle() => entries
      .where((entry) => !entry.date.isBefore(settings.cycleStart))
      .toList();

  double get cycleIncome => entriesInCycle()
      .where((entry) => entry.income)
      .fold(0, (total, entry) => total + entry.amount);
  double get cycleSpend => entriesInCycle()
      .where((entry) => !entry.income)
      .fold(0, (total, entry) => total + entry.amount);
  double get remaining => settings.allowance + cycleIncome - cycleSpend;
  double get currentDaySpend {
    final today = DateTime.now();
    return entries
        .where(
          (entry) =>
              !entry.income &&
              entry.date.year == today.year &&
              entry.date.month == today.month &&
              entry.date.day == today.day,
        )
        .fold(0, (total, entry) => total + entry.amount);
  }

  int get overspentDays {
    return overspentDaysInMonth(DateTime.now());
  }

  int overspentDaysInMonth(DateTime month) {
    if (!settings.dailyLimitEnabled || !settings.overspendGuard) return 0;
    final daily = <DateTime, double>{};
    for (final entry in entriesInMonth(month)) {
      if (entry.income) continue;
      final day = DateTime(entry.date.year, entry.date.month, entry.date.day);
      daily[day] = (daily[day] ?? 0) + entry.amount;
    }
    return daily.values.where((value) => value > settings.dailyLimit).length;
  }

  double get monthOutflow =>
      entriesInMonth(DateTime.now())
          .where((entry) => !entry.income)
          .fold(0, (total, entry) => total + entry.amount);

  double outflowInMonth(DateTime month) =>
      entriesInMonth(month)
          .where((entry) => !entry.income)
          .fold(0, (total, entry) => total + entry.amount);
}

class PulseFinanceApp extends StatelessWidget {
  const PulseFinanceApp({super.key, required this.store});
  final FinanceStore store;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final accent =
          _paletteColors[store.settings.palette] ?? _paletteColors.values.first;
      return MaterialApp(
        title: 'Pulse Finance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: _background,
          colorScheme: const ColorScheme.dark(
            surface: _surface,
            primary: Color(0xFFB343FF),
            secondary: _green,
            error: _red,
          ).copyWith(primary: accent),
          useMaterial3: true,
          fontFamily: 'Inter',
          textTheme: ThemeData.dark().textTheme.apply(
            fontFamily: 'Inter',
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF121214),
            hintStyle: const TextStyle(color: Color(0xFF5F5F69), fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _stroke),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _stroke),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: accent),
            ),
          ),
        ),
        home: FinanceHome(store: store),
      );
    },
  );
}

String money(double value, FinanceSettings settings, {bool compact = false}) {
  final rounded = value.round();
  final digits = rounded.abs().toString();
  final grouped = digits.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+$)'),
    (match) => '${match[1]},',
  );
  final symbol = _currencies[settings.currency] ?? '₦';
  return '${rounded < 0 ? '-' : ''}$symbol${compact && rounded.abs() >= 1000000 ? '${(rounded / 1000000).toStringAsFixed(1)}m' : grouped}';
}

String _monthLabel(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.year}';
const _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

class FinanceHome extends StatefulWidget {
  const FinanceHome({super.key, required this.store});
  final FinanceStore store;

  @override
  State<FinanceHome> createState() => _FinanceHomeState();
}

class _FinanceHomeState extends State<FinanceHome> with WidgetsBindingObserver {
  int _tab = 0;
  DateTime _month = DateTime.now();
  String _query = '';
  String _filterCategory = 'All Categories';
  late final TextEditingController _allowanceController;
  late final TextEditingController _dailyLimitController;
  late final TextEditingController _nameController;
  late final TextEditingController _universityController;
  late final TextEditingController _majorController;

  FinanceStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncSettingsControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && store.tutorialPending) _showTutorial();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAllowanceCycle();
    }
  }

  Future<void> _refreshAllowanceCycle() async {
    try {
      await store.advanceAllowanceCycle(DateTime.now());
    } catch (error) {
      if (mounted) _message('Could not refresh allowance cycle: $error');
    }
  }

  void _syncSettingsControllers() {
    final settings = store.settings;
    _allowanceController = TextEditingController(
      text: settings.allowance.toStringAsFixed(0),
    );
    _dailyLimitController = TextEditingController(
      text: settings.dailyLimit.toStringAsFixed(0),
    );
    _nameController = TextEditingController(text: settings.name);
    _universityController = TextEditingController(text: settings.university);
    _majorController = TextEditingController(text: settings.major);
  }

  void _resetSettingsControllers() {
    _allowanceController.text = store.settings.allowance.toStringAsFixed(0);
    _dailyLimitController.text = store.settings.dailyLimit.toStringAsFixed(0);
    _nameController.text = store.settings.name;
    _universityController.text = store.settings.university;
    _majorController.text = store.settings.major;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _allowanceController.dispose();
    _dailyLimitController.dispose();
    _nameController.dispose();
    _universityController.dispose();
    _majorController.dispose();
    super.dispose();
  }

  void _goTo(int tab) => setState(() => _tab = tab);

  Future<void> _showTutorial() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const TutorialCarousel(),
    );
    try {
      await store.completeTutorial();
    } catch (error) {
      if (mounted) _message('Could not save tutorial preference: $error');
    }
  }

  Future<void> _showEntry({bool income = false}) async {
    final entry = await showModalBottomSheet<FinanceEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EntrySheet(store: store, initialIncome: income),
    );
    if (entry != null) {
      try {
        await store.addEntry(entry);
        if (mounted) _message('${entry.income ? 'Income' : 'Expense'} saved');
      } catch (error) {
        if (mounted) _message('Could not save transaction: $error');
      }
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final pages = [
      _dashboard(),
      _expenses(),
      _calendar(),
      _analytics(),
      _settings(),
    ];
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (wide)
              _NavigationPanel(selected: _tab, onSelect: _goTo, store: store),
            Expanded(
              child: Column(
                children: [
                  _TopBar(
                    month: _month,
                    settings: store.settings,
                    remaining: store.remaining,
                    onMonthChanged: (delta) => setState(() {
                      _month = DateTime(_month.year, _month.month + delta);
                    }),
                    onAdd: () => _showEntry(),
                  ),
                  Expanded(
                    child: IndexedStack(index: _tab, children: pages),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: _goTo,
              backgroundColor: _surface,
              indicatorColor:
                  (_paletteColors[store.settings.palette] ?? Colors.purple)
                      .withValues(alpha: .18),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Expenses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: 'Calendar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_rounded),
                  label: 'Analytics',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: 'Settings',
                ),
              ],
            ),
      floatingActionButton: !wide && _tab != 4
          ? FloatingActionButton(
              onPressed: () => _showEntry(),
              backgroundColor: _paletteColors[store.settings.palette],
              foregroundColor: Colors.white,
              child: const Icon(Icons.add_rounded),
            )
          : null,
    );
  }

  Widget _dashboard() => _page(
    title: 'Overview',
    subtitle: 'A clear view of your allowance, spending, and savings.',
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final cols = constraints.maxWidth > 900
              ? 3
              : (constraints.maxWidth > 560 ? 2 : 1);
          final cards = [
            _SummaryCard(
              label: '${store.settings.cycle.toUpperCase()} ALLOWANCE',
              value: money(store.remaining, store.settings),
              detail:
                  'of ${money(store.settings.allowance, store.settings)} remaining',
              icon: Icons.account_balance_wallet_outlined,
              progress: store.settings.allowance <= 0
                  ? 0
                  : (store.remaining / store.settings.allowance)
                        .clamp(0, 1)
                        .toDouble(),
            ),
            _SummaryCard(
              label: 'TODAY\'S SPENDING',
              value: money(store.currentDaySpend, store.settings),
              detail: store.settings.dailyLimitEnabled
                  ? '${money((store.settings.dailyLimit - store.currentDaySpend).clamp(0, double.infinity), store.settings)} left of daily limit'
                  : 'Daily limit is turned off',
              icon: Icons.speed_rounded,
              progress: store.settings.dailyLimit <= 0
                  ? 0
                  : (store.currentDaySpend / store.settings.dailyLimit)
                        .clamp(0, 1)
                        .toDouble(),
              color:
                  store.settings.dailyLimitEnabled &&
                      store.settings.overspendGuard &&
                      store.currentDaySpend > store.settings.dailyLimit
                  ? _red
                  : _green,
            ),
            _SummaryCard(
              label: 'CYCLE SAVINGS',
              value: money(store.remaining, store.settings),
              detail:
                  '${store.settings.cycle} cycle · ${store.overspentDays} overspent days this month',
              icon: Icons.savings_outlined,
              color: _green,
            ),
          ];
          return _responsiveCards(cards, cols);
        },
      ),
      _sectionCard(
        header: 'Recent transactions',
        trailing: TextButton(
          onPressed: () => _goTo(1),
          child: const Text('See all'),
        ),
        child: _transactionList(store.entries.take(5).toList()),
      ),
      _tipCard(
        icon: Icons.auto_awesome_outlined,
        title: 'Your allowance at a glance',
        body:
            'Your ${store.settings.cycle.toLowerCase()} allowance refills automatically. '
            'You have spent ${money(store.cycleSpend, store.settings)} in this cycle.',
      ),
    ],
  );

  Widget _expenses() {
    final monthEntries = store.entriesInMonth(_month);
    final visible = monthEntries.where((entry) {
      final matchesText = '${entry.title} ${entry.category} ${entry.method}'
          .toLowerCase()
          .contains(_query.toLowerCase());
      final matchesCategory =
          _filterCategory == 'All Categories' ||
          entry.category == _filterCategory;
      return matchesText && matchesCategory;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
    return _page(
      title: 'Expenses log',
      subtitle: 'Track and manage your spending and allowance credits.',
      trailing: Wrap(
        spacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () => _exportCsv(),
            icon: const Icon(Icons.ios_share_rounded, size: 16),
            label: const Text('CSV'),
          ),
          FilledButton.icon(
            onPressed: () => _showEntry(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ],
      ),
      children: [
        _tipCard(
          icon: Icons.swipe_left_alt_rounded,
          title: 'Quick tip: swipe to delete',
          body: 'Swipe a transaction from right to left to remove it.',
        ),
        _sectionCard(
          header: _monthLabel(_month),
          trailing: Text(
            '${money(store.outflowInMonth(_month), store.settings)} spent',
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search transactions',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _filterCategory,
                    dropdownColor: _surfaceRaised,
                    underline: const SizedBox.shrink(),
                    items: ['All Categories', ...store.settings.categories]
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _filterCategory = value ?? 'All Categories';
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _transactionList(visible, allowDelete: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _calendar() {
    final first = DateTime(_month.year, _month.month, 1);
    final offset = first.weekday % 7;
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = ((offset + days + 6) ~/ 7) * 7;
    final byDay = <int, List<FinanceEntry>>{};
    for (final entry in store.entriesInMonth(_month)) {
      byDay.putIfAbsent(entry.date.day, () => []).add(entry);
    }
    return _page(
      title: 'Spending calendar',
      subtitle: 'Explore your daily spending and allowance credits.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => setState(
              () => _month = DateTime(_month.year, _month.month - 1),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(
            _monthLabel(_month),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          IconButton(
            onPressed: () => setState(
              () => _month = DateTime(_month.year, _month.month + 1),
            ),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      children: [
        _responsiveCards([
          _MetricCard(
            label: 'Month outflow',
            value: money(store.outflowInMonth(_month), store.settings),
            color: _paletteColors[store.settings.palette]!,
          ),
          _MetricCard(
            label: 'Daily average',
            value: money(
              store.outflowInMonth(_month) /
                  (_month.year == DateTime.now().year &&
                          _month.month == DateTime.now().month
                      ? DateTime.now().day
                      : DateTime(_month.year, _month.month + 1, 0).day),
              store.settings,
            ),
            color: _green,
          ),
          _MetricCard(
            label: 'Overspent days',
            value: '${store.overspentDaysInMonth(_month)}',
            color: _red,
          ),
        ], MediaQuery.sizeOf(context).width > 800 ? 3 : 1),
        _sectionCard(
          header: _monthLabel(_month),
          child: Column(
            children: [
              Row(
                children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT']
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              day,
                              style: TextStyle(
                                color: _muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final day = index - offset + 1;
                  if (day < 1 || day > days) return const SizedBox.shrink();
                  final entries = byDay[day] ?? [];
                  final spend = entries
                      .where((entry) => !entry.income)
                      .fold(0.0, (sum, entry) => sum + entry.amount);
                  final income = entries
                      .where((entry) => entry.income)
                      .fold(0.0, (sum, entry) => sum + entry.amount);
                  final isToday =
                      _month.year == DateTime.now().year &&
                      _month.month == DateTime.now().month &&
                      day == DateTime.now().day;
                  return InkWell(
                    onTap: () => _showDayEntries(
                      DateTime(_month.year, _month.month, day),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isToday ? _surfaceRaised : Colors.transparent,
                        border: Border.all(
                          color: isToday
                              ? _paletteColors[store.settings.palette]!
                              : _stroke,
                        ),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$day',
                            style: TextStyle(
                              fontSize: 12,
                              color: isToday
                                  ? _paletteColors[store.settings.palette]
                                  : Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (spend > 0)
                            Text(
                              money(spend, store.settings, compact: true),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                color:
                                    store.settings.dailyLimitEnabled &&
                                        store.settings.overspendGuard &&
                                        spend > store.settings.dailyLimit
                                    ? _red
                                    : _muted,
                              ),
                            ),
                          if (income > 0)
                            const Icon(
                              Icons.arrow_downward_rounded,
                              size: 10,
                              color: _green,
                            ),
                          if (entries.isEmpty)
                            const Text(
                              'No spend',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 8,
                                color: Color(0xFF666671),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _analytics() {
    final entries = store
        .entriesInMonth(_month)
        .where((entry) => !entry.income)
        .toList();
    final monthOutflow = store.outflowInMonth(_month);
    final categories = <String, double>{};
    for (final entry in entries) {
      categories[entry.category] =
          (categories[entry.category] ?? 0) + entry.amount;
    }
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxCategory = sorted.isEmpty ? 1.0 : sorted.first.value;
    final daily = <int, double>{};
    for (final entry in entries) {
      daily[entry.date.day] = (daily[entry.date.day] ?? 0) + entry.amount;
    }
    final maxDay = math.max(
      1.0,
      daily.values.fold(0.0, (max, amount) => math.max(max, amount)),
    );
    final daysElapsed =
        _month.year == DateTime.now().year &&
            _month.month == DateTime.now().month
        ? DateTime.now().day
        : DateTime(_month.year, _month.month + 1, 0).day;
    final average = monthOutflow / math.max(1, daysElapsed);
    return _page(
      title: 'Analytics overview',
      subtitle: 'Understand your spending patterns and allowance runway.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => setState(
              () => _month = DateTime(_month.year, _month.month - 1),
            ),
            icon: const Icon(Icons.chevron_left),
          ),
          Text(_monthLabel(_month), style: const TextStyle(fontSize: 12)),
          IconButton(
            onPressed: () => setState(
              () => _month = DateTime(_month.year, _month.month + 1),
            ),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      children: [
        _responsiveCards([
          _MetricCard(
            label: 'Total monthly outflow',
            value: money(monthOutflow, store.settings),
            color: _paletteColors[store.settings.palette]!,
          ),
          _MetricCard(
            label: 'Average per day',
            value: money(average, store.settings),
            color: _green,
          ),
          _MetricCard(
            label: 'Remaining allowance',
            value: money(store.remaining, store.settings),
            color: _green,
          ),
        ], MediaQuery.sizeOf(context).width > 850 ? 3 : 1),
        LayoutBuilder(
          builder: (context, constraints) {
            final chart = _sectionCard(
              header: 'Spending velocity',
              trailing: const Text(
                'Daily spending',
                style: TextStyle(color: _muted, fontSize: 11),
              ),
              child: SizedBox(
                height: 210,
                child: CustomPaint(
                  painter: _SpendingChart(
                    daily: daily,
                    days: DateTime(_month.year, _month.month + 1, 0).day,
                    maxValue: maxDay,
                    color: _paletteColors[store.settings.palette]!,
                    limit:
                        store.settings.dailyLimitEnabled &&
                            store.settings.overspendGuard
                        ? store.settings.dailyLimit
                        : 0,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            );
            final allocation = _sectionCard(
              header: 'Category allocation',
              child: sorted.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(22),
                      child: Text(
                        'Add expenses to see your category breakdown.',
                        style: TextStyle(color: _muted),
                      ),
                    )
                  : Column(
                      children: sorted
                          .take(8)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.key,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      Text(
                                        money(item.value, store.settings),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: _muted,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${(monthOutflow <= 0 ? 0 : item.value / monthOutflow * 100).round()}%',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: LinearProgressIndicator(
                                      value: item.value / maxCategory,
                                      minHeight: 6,
                                      color:
                                          _paletteColors[store
                                              .settings
                                              .palette],
                                      backgroundColor: _stroke,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            );
            if (constraints.maxWidth > 850) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: chart),
                  const SizedBox(width: 14),
                  Expanded(flex: 2, child: allocation),
                ],
              );
            }
            return Column(children: [chart, allocation]);
          },
        ),
        _tipCard(
          icon: Icons.insights_rounded,
          title: 'Spending insights',
          body: store.overspentDays == 0
              ? 'You are within your daily allowance on every recorded day this month.'
              : 'You exceeded your daily target on ${store.overspentDays} day(s). '
                    'Review your categories to make the rest of the cycle count.',
        ),
      ],
    );
  }

  Widget _settings() {
    final settings = store.settings;
    return _page(
      title: 'Settings',
      subtitle: 'Configure your allowance cycle, categories, and profile.',
      children: [
        _sectionCard(
          header: 'Getting started',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.menu_book_outlined),
            title: const Text('How to use Pulse Finance'),
            subtitle: const Text('Replay the quick, swipeable app tour.'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _showTutorial,
          ),
        ),
        _sectionCard(
          header: 'Accent palette',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _paletteColors.entries
                .map(
                  (palette) => ChoiceChip(
                    label: Text(palette.key),
                    selected: settings.palette == palette.key,
                    selectedColor: palette.value.withValues(alpha: .25),
                    avatar: CircleAvatar(
                      backgroundColor: palette.value,
                      radius: 7,
                    ),
                    onSelected: (_) =>
                        _changeSettings(settings..palette = palette.key),
                  ),
                )
                .toList(),
          ),
        ),
        _sectionCard(
          header: 'Allowance configuration',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel('ALLOWANCE AMOUNT'),
              TextField(
                controller: _allowanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: '${_currencies[settings.currency]} ',
                ),
              ),
              const SizedBox(height: 12),
              _fieldLabel('REFILL CYCLE'),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Weekly', label: Text('Weekly')),
                  ButtonSegment(value: 'Monthly', label: Text('Monthly')),
                ],
                selected: {settings.cycle},
                onSelectionChanged: (selection) async {
                  try {
                    await store.updateCycle(selection.first);
                    if (mounted) {
                      _message('Allowance cycle updated');
                    }
                  } catch (error) {
                    if (mounted) {
                      _message('Could not update allowance cycle: $error');
                    }
                  }
                },
              ),
              const SizedBox(height: 12),
              _fieldLabel('CURRENCY'),
              Wrap(
                spacing: 8,
                children: _currencies.entries
                    .map(
                      (currency) => ChoiceChip(
                        label: Text('${currency.key} (${currency.value})'),
                        selected: settings.currency == currency.key,
                        onSelected: (_) =>
                            _changeSettings(settings..currency = currency.key),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              _fieldLabel('DAILY SPENDING LIMIT'),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dailyLimitController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: settings.dailyLimitEnabled,
                    onChanged: (value) =>
                        _changeSettings(settings..dailyLimitEnabled = value),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  final allowance = double.tryParse(_allowanceController.text);
                  final limit = double.tryParse(_dailyLimitController.text);
                  if (allowance == null ||
                      allowance <= 0 ||
                      limit == null ||
                      limit < 0) {
                    _message('Enter a valid allowance and daily limit.');
                    return;
                  }
                  settings.allowance = allowance;
                  settings.dailyLimit = limit;
                  if (await _changeSettings(settings) && mounted) {
                    _message('Allowance settings saved');
                  }
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save allowance settings'),
              ),
            ],
          ),
        ),
        _sectionCard(
          header: 'Automation & daily rules',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Automatic allowance refill'),
                subtitle: Text(
                  'Refills ${settings.cycle.toLowerCase()} from your allowance baseline.',
                ),
                value: settings.autoRefill,
                onChanged: (value) =>
                    _changeSettings(settings..autoRefill = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('80% allowance threshold alert'),
                subtitle: const Text(
                  'Show an alert when cycle spending reaches 80%.',
                ),
                value: settings.thresholdAlert,
                onChanged: (value) =>
                    _changeSettings(settings..thresholdAlert = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Daily limit overspend guard'),
                subtitle: const Text(
                  'Highlight spending above your daily target.',
                ),
                value: settings.overspendGuard,
                onChanged: (value) =>
                    _changeSettings(settings..overspendGuard = value),
              ),
              OutlinedButton.icon(
                onPressed: () => _showEntry(income: true),
                icon: const Icon(Icons.add_card_rounded, color: _green),
                label: const Text('Credit allowance now'),
              ),
            ],
          ),
        ),
        _sectionCard(
          header: 'Expense categories',
          trailing: IconButton(
            onPressed: _addCategory,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add category',
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: settings.categories
                .map(
                  (category) => InputChip(
                    label: Text(category, style: const TextStyle(fontSize: 11)),
                    onDeleted: category == 'Allowance & Income'
                        ? null
                        : () => _deleteCategory(category),
                  ),
                )
                .toList(),
          ),
        ),
        _sectionCard(
          header: 'Student profile',
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _universityController,
                decoration: const InputDecoration(
                  labelText: 'University / campus',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _majorController,
                decoration: const InputDecoration(labelText: 'Academic major'),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: () {
                    settings
                      ..name = _nameController.text.trim()
                      ..university = _universityController.text.trim()
                      ..major = _majorController.text.trim();
                    _changeSettings(settings).then((saved) {
                      if (saved && mounted) _message('Profile saved');
                    });
                  },
                  child: const Text('Save profile'),
                ),
              ),
            ],
          ),
        ),
        _sectionCard(
          header: 'Backup & data management',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _exportJson,
                icon: const Icon(Icons.ios_share),
                label: const Text('Export JSON'),
              ),
              OutlinedButton.icon(
                onPressed: _importJson,
                icon: const Icon(Icons.file_open_outlined),
                label: const Text('Import JSON'),
              ),
              OutlinedButton.icon(
                onPressed: _exportCsv,
                icon: const Icon(Icons.table_view_outlined),
                label: const Text('Export CSV'),
              ),
              TextButton(
                onPressed: _confirmReset,
                child: const Text(
                  'Reset demo data',
                  style: TextStyle(color: _red),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<bool> _changeSettings(FinanceSettings settings) async {
    try {
      await store.updateSettings(settings);
      return true;
    } catch (error) {
      if (mounted) _message('Could not save settings: $error');
      return false;
    }
  }

  Future<void> _addCategory() async {
    final controller = TextEditingController();
    final category = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Category name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (category == null || category.isEmpty) return;
    if (store.settings.categories.contains(category)) {
      _message('That category already exists.');
      return;
    }
    store.settings.categories.add(category);
    await _changeSettings(store.settings);
  }

  Future<void> _deleteCategory(String category) async {
    final expenseCategories = store.settings.categories
        .where((item) => item != 'Allowance & Income')
        .toList();
    if (expenseCategories.length <= 1) {
      _message('Keep at least one expense category.');
      return;
    }
    store.settings.categories.remove(category);
    await _changeSettings(store.settings);
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'This replaces your current transactions and settings with the sample setup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await store.resetDemoData();
        _resetSettingsControllers();
        _message('Demo data restored');
      } catch (error) {
        _message('Could not reset demo data: $error');
      }
    }
  }

  Future<void> _exportJson() async {
    await _shareText(
      jsonEncode(store.toJson()),
      'pulse-finance-backup.json',
      'application/json',
    );
  }

  Future<void> _exportCsv() async {
    final buffer = StringBuffer(
      'Date,Description,Category,Type,Amount,Payment Method,Notes\n',
    );
    for (final entry in store.entriesInMonth(_month)) {
      String quote(String value) => '"${value.replaceAll('"', '""')}"';
      buffer.writeln(
        [
          quote(entry.date.toIso8601String().split('T').first),
          quote(entry.title),
          quote(entry.category),
          entry.income ? 'Income' : 'Expense',
          entry.amount.toStringAsFixed(2),
          quote(entry.method),
          quote(entry.notes),
        ].join(','),
      );
    }
    await _shareText(
      buffer.toString(),
      'pulse-finance-${_month.year}-${_month.month}.csv',
      'text/csv',
    );
  }

  Future<void> _shareText(String text, String name, String mimeType) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              Uint8List.fromList(utf8.encode(text)),
              name: name,
              mimeType: mimeType,
            ),
          ],
          fileNameOverrides: [name],
          subject: name,
        ),
      );
    } catch (error) {
      if (mounted) _message('Could not export data: $error');
    }
  }

  Future<void> _importJson() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null) return;
      final bytes = await result.readAsBytes();
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic> ||
          decoded['settings'] is! Map<String, dynamic> ||
          decoded['entries'] is! List) {
        _message('This file is not a valid Pulse Finance backup.');
        return;
      }
      await store.importJson(decoded);
      _resetSettingsControllers();
      if (mounted) _message('Backup imported');
    } on FormatException catch (error) {
      _message('Invalid JSON backup: ${error.message}');
    } catch (error) {
      _message('Could not import backup: $error');
    }
  }

  Widget _page({
    required String title,
    required String subtitle,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 26 : 16, 22, wide ? 26 : 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1240),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  const SizedBox(height: 20),
                  ...children.map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard({
    required String header,
    required Widget child,
    Widget? trailing,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _stroke),
    ),
    child: Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  header,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    ),
  );

  Widget _responsiveCards(List<Widget> cards, int columns) {
    if (columns == 1) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: card,
              ),
            )
            .toList(),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 12 * (columns - 1)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards
              .map((card) => SizedBox(width: width, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _transactionList(
    List<FinanceEntry> entries, {
    bool allowDelete = false,
  }) {
    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'No transactions found.',
            style: TextStyle(color: _muted),
          ),
        ),
      );
    }
    return Column(
      children: entries
          .map(
            (entry) => Dismissible(
              key: ValueKey(entry.id),
              direction: allowDelete
                  ? DismissDirection.endToStart
                  : DismissDirection.none,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: _red.withValues(alpha: .18),
                child: const Icon(Icons.delete_outline, color: _red),
              ),
              onDismissed: (_) => store.deleteEntry(entry.id),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _stroke)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color:
                            (entry.income
                                    ? _green
                                    : _paletteColors[store.settings.palette]!)
                                .withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(
                        entry.income
                            ? Icons.south_west_rounded
                            : Icons.sell_outlined,
                        color: entry.income
                            ? _green
                            : _paletteColors[store.settings.palette],
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${entry.category} · ${_formatDate(entry.date)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: _muted, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.income ? '+' : '-'}${money(entry.amount, store.settings)}',
                      style: TextStyle(
                        color: entry.income ? _green : Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _tipCard({
    required IconData icon,
    required String title,
    required String body,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          (_paletteColors[store.settings.palette] ?? Colors.purple).withValues(
            alpha: .15,
          ),
          _surface,
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _stroke),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _paletteColors[store.settings.palette], size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                body,
                style: const TextStyle(
                  color: _muted,
                  height: 1.45,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _fieldLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: .5,
      ),
    ),
  );

  String _formatDate(DateTime date) =>
      '${_monthNames[date.month - 1].substring(0, 3)} ${date.day}, ${date.year}';

  Future<void> _showDayEntries(DateTime date) async {
    final entries = store.entries
        .where(
          (entry) =>
              entry.date.year == date.year &&
              entry.date.month == date.month &&
              entry.date.day == date.day,
        )
        .toList();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDate(date),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _transactionList(entries),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showEntry();
                },
                icon: const Icon(Icons.add),
                label: const Text('Add transaction'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationPanel extends StatelessWidget {
  const _NavigationPanel({
    required this.selected,
    required this.onSelect,
    required this.store,
  });
  final int selected;
  final ValueChanged<int> onSelect;
  final FinanceStore store;

  static const _items = [
    (Icons.grid_view_rounded, 'Dashboard'),
    (Icons.receipt_long_outlined, 'Expenses'),
    (Icons.calendar_month_outlined, 'Calendar'),
    (Icons.bar_chart_rounded, 'Analytics'),
    (Icons.settings_outlined, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    color: _surface,
    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (_paletteColors[store.settings.palette] ?? Colors.purple)
                    .withValues(alpha: .17),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: _paletteColors[store.settings.palette],
              ),
            ),
            const SizedBox(width: 9),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pulse Finance',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  Text(
                    'University Tracker',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _muted, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        ...List.generate(_items.length, (index) {
          final item = _items[index];
          final active = selected == index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                selected: active,
                selectedTileColor: _surfaceRaised,
                leading: Icon(
                  item.$1,
                  size: 19,
                  color: active
                      ? _paletteColors[store.settings.palette]
                      : _muted,
                ),
                title: Text(
                  item.$2,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                onTap: () => onSelect(index),
              ),
            ),
          );
        }),
        const Spacer(),
        _SummaryCard(
          label: 'TODAY\'S LIMIT',
          value: money(store.currentDaySpend, store.settings),
          detail:
              '${money((store.settings.dailyLimit - store.currentDaySpend).clamp(0, double.infinity), store.settings)} left today',
          icon: Icons.speed_rounded,
          progress: store.settings.dailyLimit <= 0
              ? 0
              : (store.currentDaySpend / store.settings.dailyLimit)
                    .clamp(0, 1)
                    .toDouble(),
          color: _green,
          compact: true,
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _stroke),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _surfaceRaised,
                child: Text(
                  store.settings.name.isEmpty
                      ? 'PF'
                      : store.settings.name.substring(0, 1).toUpperCase(),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  store.settings.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.month,
    required this.settings,
    required this.remaining,
    required this.onMonthChanged,
    required this.onAdd,
  });
  final DateTime month;
  final FinanceSettings settings;
  final double remaining;
  final ValueChanged<int> onMonthChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1200;
    return Container(
      height: 58,
      padding: EdgeInsets.symmetric(horizontal: wide ? 22 : 14),
      decoration: const BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _stroke)),
      ),
      child: Row(
        children: [
          if (wide) ...[
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Pulse Finance',
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ] else
            Text(
              _monthLabel(month),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          const Spacer(),
          if (wide) ...[
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => onMonthChanged(-1),
              icon: const Icon(Icons.chevron_left, size: 18),
            ),
            Text(
              _monthLabel(month),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () => onMonthChanged(1),
              icon: const Icon(Icons.chevron_right, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              '${settings.cycle} allowance · ${money(remaining, settings)}',
              style: const TextStyle(
                color: _green,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (wide)
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 17),
              label: const Text('New entry'),
            )
          else
            IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    this.progress,
    this.color,
    this.compact = false,
  });
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final double? progress;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 13 : 17),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    letterSpacing: .55,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                icon,
                color: accent.withValues(alpha: .8),
                size: compact ? 14 : 19,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 18 : 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
          if (progress != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress!.clamp(0, 1),
                minHeight: 5,
                color: accent,
                backgroundColor: _stroke,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _stroke),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: _muted, fontSize: 10)),
        const SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: color,
            fontSize: 18,
          ),
        ),
      ],
    ),
  );
}

class TutorialCarousel extends StatefulWidget {
  const TutorialCarousel({super.key});

  @override
  State<TutorialCarousel> createState() => _TutorialCarouselState();
}

class _TutorialCarouselState extends State<TutorialCarousel> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (
      icon: Icons.account_balance_wallet_outlined,
      title: 'Your allowance at a glance',
      description: 'The Dashboard shows what remains, how much you spent today, and your recent transactions.',
    ),
    (
      icon: Icons.add_card_rounded,
      title: 'Log spending or add money',
      description: 'Tap + to record an expense, or switch to Income to credit your allowance. Add a category, date, and payment method.',
    ),
    (
      icon: Icons.swipe_left_alt_rounded,
      title: 'Swipe left to delete',
      description: 'In Expenses, swipe a transaction from right to left to remove it. The red delete icon appears behind the row.',
    ),
    (
      icon: Icons.calendar_month_outlined,
      title: 'Explore and make it yours',
      description: 'Use Calendar and Analytics to spot patterns. In Settings, choose a weekly or monthly auto-refill cycle, set your currency, and customize categories.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page == _slides.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Dialog(
      backgroundColor: _surface,
      insetPadding: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: _stroke),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'A quick tour',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close tutorial',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              SizedBox(
                height: 340,
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (page) => setState(() => _page = page),
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _TutorialSlide(
                      icon: slide.icon,
                      title: slide.title,
                      description: slide.description,
                      accent: accent,
                      showSwipeExample: index == 2,
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: index == _page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: index == _page
                          ? accent
                          : _muted.withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(_page == _slides.length - 1 ? 'Close' : 'Skip'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _next,
                    child: Text(
                      _page == _slides.length - 1 ? 'Get started' : 'Next',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialSlide extends StatelessWidget {
  const _TutorialSlide({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.showSwipeExample,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final bool showSwipeExample;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Column(
      children: [
        Container(
          width: double.infinity,
          height: 154,
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _stroke),
          ),
          child: showSwipeExample
              ? _SwipeTutorialExample(accent: accent)
              : Center(
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: .15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 36, color: accent),
                  ),
                ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 9),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontSize: 13, height: 1.5),
        ),
      ],
    ),
  );
}

class _SwipeTutorialExample extends StatelessWidget {
  const _SwipeTutorialExample({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.receipt_long_outlined, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campus lunch',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Food & Cafeteria',
                    style: TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Text(
              '-₦2,500',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 17),
        Row(
          children: [
            const Spacer(),
            const Icon(Icons.swipe_left_rounded, color: _muted, size: 19),
            const SizedBox(width: 6),
            const Text(
              'SWIPE LEFT',
              style: TextStyle(
                color: _muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Row(
                children: [
                  Icon(Icons.delete_outline_rounded, color: _red, size: 16),
                  SizedBox(width: 5),
                  Text('Delete', style: TextStyle(color: _red, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class EntrySheet extends StatefulWidget {
  const EntrySheet({
    super.key,
    required this.store,
    this.initialIncome = false,
  });
  final FinanceStore store;
  final bool initialIncome;

  @override
  State<EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<EntrySheet> {
  late bool _income = widget.initialIncome;
  late String _category = _income
      ? 'Allowance & Income'
      : widget.store.settings.categories.first;
  String _method = 'POS Payment';
  DateTime _date = DateTime.now();
  final _amount = TextEditingController();
  final _title = TextEditingController();
  final _notes = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amount.dispose();
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.store.settings;
    final categories = settings.categories;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .92,
        ),
        decoration: const BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _stroke,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _income
                                  ? 'Add allowance / income'
                                  : 'Record new expense',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _income
                                  ? 'Credit your allowance balance'
                                  : 'Deduct directly from your allowance',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: false, label: Text('Expense')),
                      ButtonSegment(value: true, label: Text('Income')),
                    ],
                    selected: {_income},
                    onSelectionChanged: (selection) => setState(() {
                      _income = selection.first;
                      if (_income) {
                        _category = 'Allowance & Income';
                      } else if (_category == 'Allowance & Income' ||
                          !categories.contains(_category)) {
                        _category = categories.firstWhere(
                          (category) => category != 'Allowance & Income',
                          orElse: () => categories.first,
                        );
                      }
                    }),
                  ),
                  const SizedBox(height: 16),
                  _label('AMOUNT (${settings.currency})'),
                  TextFormField(
                    controller: _amount,
                    autofocus: false,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: InputDecoration(
                      prefixText: '${_currencies[settings.currency]} ',
                      hintText: '0',
                      hintStyle: const TextStyle(fontSize: 20),
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Enter an amount greater than zero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: [500, 1000, 2500, 5000, 10000, 20000]
                        .map(
                          (value) => ActionChip(
                            label: Text(
                              '+${money(value.toDouble(), settings)}',
                              style: const TextStyle(fontSize: 10),
                            ),
                            onPressed: () => _amount.text = value.toString(),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                  _label('DESCRIPTION / ITEM NAME'),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Campus cafeteria lunch',
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Add a description'
                        : null,
                  ),
                  if (!_income) ...[
                    const SizedBox(height: 14),
                    _label('CATEGORY'),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      items: categories
                          .where((category) => category != 'Allowance & Income')
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _category = value ?? _category),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('DATE'),
                            OutlinedButton.icon(
                              onPressed: _selectDate,
                              icon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                              ),
                              label: Text(
                                '${_date.day}/${_date.month}/${_date.year}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label('PAYMENT METHOD'),
                            DropdownButtonFormField<String>(
                              initialValue: _method,
                              items:
                                  const [
                                        'POS Payment',
                                        'Cash',
                                        'Bank transfer',
                                        'Card',
                                        'Other',
                                      ]
                                      .map(
                                        (method) => DropdownMenuItem(
                                          value: method,
                                          child: Text(method),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) =>
                                  setState(() => _method = value ?? _method),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _label('NOTES (OPTIONAL)'),
                  TextField(
                    controller: _notes,
                    decoration: const InputDecoration(hintText: 'Add a note'),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: _income
                          ? FilledButton.styleFrom(
                              backgroundColor: _green,
                              foregroundColor: Colors.black,
                            )
                          : null,
                      onPressed: _save,
                      child: Text(
                        _income ? 'Credit allowance' : 'Save expense',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        color: _muted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (date != null) setState(() => _date = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final entry = FinanceEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      category: _income ? 'Allowance & Income' : _category,
      amount: double.parse(_amount.text),
      date: _date,
      income: _income,
      method: _method,
      notes: _notes.text.trim(),
    );
    Navigator.pop(context, entry);
  }
}

class _SpendingChart extends CustomPainter {
  _SpendingChart({
    required this.daily,
    required this.days,
    required this.maxValue,
    required this.color,
    required this.limit,
  });

  final Map<int, double> daily;
  final int days;
  final double maxValue;
  final Color color;
  final double limit;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 36.0;
    const right = 10.0;
    const top = 14.0;
    const bottom = 24.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final grid = Paint()
      ..color = _stroke
      ..strokeWidth = 1;
    final label = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i <= 3; i++) {
      final y = chart.top + chart.height * i / 3;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
    }
    if (limit > 0) {
      final limitY =
          chart.bottom - (limit / maxValue).clamp(0, 1) * chart.height;
      final dashPaint = Paint()
        ..color = _red
        ..strokeWidth = 1;
      for (var x = chart.left; x < chart.right; x += 8) {
        canvas.drawLine(
          Offset(x, limitY),
          Offset(math.min(x + 4, chart.right), limitY),
          dashPaint,
        );
      }
    }
    final path = Path();
    final points = <Offset>[];
    for (var day = 1; day <= days; day++) {
      final x = chart.left + (day - 1) / math.max(1, days - 1) * chart.width;
      final y = chart.bottom - (daily[day] ?? 0) / maxValue * chart.height;
      final point = Offset(x, y);
      points.add(point);
      if (day == 1) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
    for (final point in points.where((point) => point.dy < chart.bottom)) {
      canvas.drawCircle(point, 3, Paint()..color = color);
    }
    for (final index in [0, 3, 6, 9, 12, 15, 18, 21, 24, 27]) {
      if (index >= days) continue;
      label.text = TextSpan(
        text: 'D${index + 1}',
        style: const TextStyle(color: _muted, fontSize: 8),
      );
      label.layout();
      final x =
          chart.left +
          index / math.max(1, days - 1) * chart.width -
          label.width / 2;
      label.paint(canvas, Offset(x, chart.bottom + 5));
    }
  }

  @override
  bool shouldRepaint(covariant _SpendingChart oldDelegate) =>
      oldDelegate.daily != daily ||
      oldDelegate.days != days ||
      oldDelegate.maxValue != maxValue ||
      oldDelegate.color != color ||
      oldDelegate.limit != limit;
}
