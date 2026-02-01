import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_parameter.dart';
import '../widgets/app_scope.dart';

class ReadingCreateScreen extends StatefulWidget {
  const ReadingCreateScreen({super.key});

  @override
  State<ReadingCreateScreen> createState() => _ReadingCreateScreenState();
}

class _ReadingCreateScreenState extends State<ReadingCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _indexController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _subscriberId;
  String? _parameterId;
  DateTime _date = DateTime.now();
  bool _isPaid = true;
  bool _isSaving = false;
  bool _isLoadingParams = true;
  List<AppParameter> _parameters = <AppParameter>[];
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingParams = true;
    });
    try {
      final store = AppScope.of(context);
      await store.syncSubscribers(force: true);
      final params = await store.fetchParameters();
      if (!mounted) return;
      setState(() {
        _parameters = params.where((p) => p.active).toList();
      });
    } catch (error) {
      debugPrint('Error loading params: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingParams = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _indexController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2019),
      lastDate: DateTime(2100),
      locale: const Locale('fr', 'CD'),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    final subscriberId = _subscriberId;
    if (subscriberId == null || subscriberId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sélectionnez un abonné')));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final indexValue = double.tryParse(_indexController.text.trim()) ?? 0;
    final prixM3 = double.tryParse(_priceController.text.trim()) ?? 0;

    try {
      final reading = await AppScope.of(context).createReading(
        abonneId: subscriberId,
        date: _date,
        indexValue: indexValue,
        prixM3: prixM3,
        isPaid: _isPaid,
      );
      if (mounted) {
        Navigator.of(context).pop(reading);
      }
    } catch (error) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: theme.colorScheme.onError),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error.toString(),
                    style: TextStyle(color: theme.colorScheme.onError),
                  ),
                ),
              ],
            ),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscribers = AppScope.of(context).subscribers;
    final formatter = DateFormat('EEEE d MMMM yyyy', 'fr_CD');
    final moneyFormatter = NumberFormat('#,##0.##', 'fr_CD');

    return Scaffold(
      appBar: AppBar(title: const Text('Nouveau relevé')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      value: subscribers.any((s) => s.id == _subscriberId)
                          ? _subscriberId
                          : null,
                      isExpanded: true,
                      menuMaxHeight: 360,
                      items: subscribers.map((subscriber) {
                        final name = subscriber.fullName.isEmpty
                            ? subscriber.id
                            : subscriber.fullName;
                        return DropdownMenuItem<String>(
                          value: subscriber.id,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _subscriberId = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Abonné'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sélectionnez un abonné';
                        }
                        return null;
                      },
                    ),
                    if (subscribers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Aucun abonné synchronisé disponible.'),
                      ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _parameterId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Paramètre (Prix M3)',
                        hintText: 'Sélectionnez un paramètre',
                      ),
                      items: _parameters.map((p) {
                        final val = double.tryParse(p.value) ?? 0;
                        return DropdownMenuItem<String>(
                          value: p.id,
                          child: Text(
                            '${p.keyName} (${moneyFormatter.format(val)} CDF)',
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _parameterId = value;
                          final param = _parameters.firstWhere(
                            (p) => p.id == value,
                          );
                          _priceController.text = param.value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Sélectionnez un paramètre';
                        }
                        return null;
                      },
                    ),
                    if (_isLoadingParams)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(),
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prix par M3',
                        hintText: '0.00',
                        suffixText: 'CDF',
                      ),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) return 'Entrez un prix';
                        if (double.tryParse(trimmed) == null)
                          return 'Valeur invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date du relevé',
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(formatter.format(_date)),
                            const Icon(Icons.calendar_today_outlined, size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _indexController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Index'),
                      validator: (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) {
                          return 'Entrez un index';
                        }
                        if (double.tryParse(trimmed) == null) {
                          return 'Valeur invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Est payé'),
                      subtitle: const Text('Le relevé est déjà payé'),
                      value: _isPaid,
                      onChanged: (value) {
                        setState(() {
                          _isPaid = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Enregistrer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
