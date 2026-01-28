import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/reading.dart';
import '../models/subscriber.dart';
import '../widgets/app_scope.dart';
import '../widgets/decorated_background.dart';
import '../widgets/fade_slide_in.dart';
import 'reading_detail_screen.dart';
import 'reading_create_screen.dart';

class ReadingsScreen extends StatefulWidget {
  const ReadingsScreen({super.key});

  @override
  State<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends State<ReadingsScreen> {
  String? _subscriberId;
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _isLoading = false;
  bool _bootstrapped = false;
  List<Reading> _readings = <Reading>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).syncSubscribers(force: true);
      _loadReadings();
    });
  }

  Future<void> _loadReadings() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
    final store = AppScope.of(context);
    try {
      final items = await store.fetchReadings(
        abonneId: _subscriberId,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
      );
      if (!mounted) return;
      setState(() {
        _readings = items;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDateFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2019),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'CD'),
    );
    if (picked == null) return;
    setState(() {
      _dateFrom = picked;
    });
  }

  Future<void> _pickDateTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2019),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'CD'),
    );
    if (picked == null) return;
    setState(() {
      _dateTo = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.of(context);
    final theme = Theme.of(context);
    final background = theme.colorScheme.surface;
    final subscribers = store.subscribers;
    final subscriberNames = <String, String>{
      for (final subscriber in subscribers) subscriber.id: subscriber.fullName,
    };

    return DecoratedBackground(
      gradientColors: <Color>[background],
      accents: const <Widget>[],
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              FadeSlideIn(
                child: Text(
                  'Releves',
                  style: theme.textTheme.headlineMedium,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Consultez les index des abonnes.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final fieldWidth = isWide ? 260.0 : constraints.maxWidth;
                  final dateWidth = isWide ? 200.0 : constraints.maxWidth;
                  final buttonWidth = isWide ? 160.0 : constraints.maxWidth;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      SizedBox(
                        width: fieldWidth,
                        child: DropdownButtonFormField<String?>(
                          value: subscribers.any((s) => s.id == _subscriberId)
                              ? _subscriberId
                              : null,
                          isExpanded: true,
                          menuMaxHeight: 360,
                          items: <DropdownMenuItem<String?>>[
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Tous les abonnes'),
                            ),
                            ...subscribers.map(
                              (subscriber) => DropdownMenuItem<String?>(
                                value: subscriber.id,
                                child: Text(
                                  subscriber.fullName.isEmpty
                                      ? subscriber.id
                                      : subscriber.fullName,
                    ),
                  ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _subscriberId = value;
                            });
                          },
                          decoration: const InputDecoration(
                            labelText: 'Abonne',
                          ),
                        ),
                      ),
                      SizedBox(
                        width: dateWidth,
                        child: _DateField(
                          label: 'Du',
                          value: _dateFrom,
                          onTap: _pickDateFrom,
                          onClear: _dateFrom == null
                              ? null
                              : () {
                                  setState(() {
                                    _dateFrom = null;
                                  });
                                },
                        ),
                      ),
                      SizedBox(
                        width: dateWidth,
                        child: _DateField(
                          label: 'Au',
                          value: _dateTo,
                          onTap: _pickDateTo,
                          onClear: _dateTo == null
                              ? null
                              : () {
                                  setState(() {
                                    _dateTo = null;
                                  });
                                },
                        ),
                      ),
                      SizedBox(
                        width: buttonWidth,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _loadReadings,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.filter_alt_outlined),
                          label: const Text('Filtrer'),
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _readings.isEmpty
                    ? (_isLoading
                        ? const _LoadingState()
                        : const _EmptyState())
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final computed = (width / 280).floor();
                          final crossAxisCount = computed.clamp(1, 3);
                          const mainAxisExtent = 96.0;

                          return GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              mainAxisExtent: mainAxisExtent,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _readings.length,
                            itemBuilder: (context, index) {
                              final reading = _readings[index];
                              final name =
                                  subscriberNames[reading.subscriberId] ??
                                      reading.subscriberId;
                              return FadeSlideIn(
                                delay: Duration(milliseconds: 30 * index),
                                child: _ReadingCard(
                                  reading: reading,
                                  subscriberName: name,
                                  onTap: () => _openDetails(reading.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: FloatingActionButton.extended(
                onPressed: _isLoading
                    ? null
                    : () async {
                        final created = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (context) =>
                                const ReadingCreateScreen(),
                          ),
                        );
                        if (created == true) {
                          _loadReadings();
                        }
                      },
                icon: const Icon(Icons.add),
                label: const Text('Nouveau'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetails(String readingId) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReadingDetailScreen(readingId: readingId),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy', 'fr_CD');
    final display = value == null ? '-' : formatter.format(value!);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear == null
              ? const Icon(Icons.calendar_today_outlined, size: 18)
              : IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
        ),
        child: Text(display),
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({
    required this.reading,
    required this.subscriberName,
    required this.onTap,
  });

  final Reading reading;
  final String subscriberName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM/yyyy');
    final number = NumberFormat('#,##0.##');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.water_drop_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      subscriberName.isEmpty ? '-' : subscriberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatter.format(reading.date),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                number.format(reading.indexValue),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Chargement des releves...'),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.water_drop_outlined, size: 40),
              const SizedBox(height: 8),
              Text(
                'Aucun releve trouve.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
