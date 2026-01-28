import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/subscriber.dart';
import '../widgets/app_scope.dart';

class ReadingCreateScreen extends StatefulWidget {
  const ReadingCreateScreen({super.key});

  @override
  State<ReadingCreateScreen> createState() => _ReadingCreateScreenState();
}

class _ReadingCreateScreenState extends State<ReadingCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _indexController = TextEditingController();
  String? _subscriberId;
  DateTime _date = DateTime.now();
  bool _isSaving = false;
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).syncSubscribers(force: true);
    });
  }

  @override
  void dispose() {
    _indexController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2019),
      lastDate: DateTime(2100),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selectionnez un abonne')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final indexValue = double.tryParse(_indexController.text.trim()) ?? 0;
    try {
      await AppScope.of(context).createReading(
        abonneId: subscriberId,
        date: _date,
        indexValue: indexValue,
      );
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $error')),
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
    final formatter = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouveau releve'),
      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Abonne',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Selectionnez un abonne';
                        }
                        return null;
                      },
                    ),
                    if (subscribers.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Aucun abonne synchronise disponible.',
                        ),
                      ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date du releve',
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
                      decoration: const InputDecoration(
                        labelText: 'Index',
                      ),
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
