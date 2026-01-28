import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/app_parameter.dart';
import '../models/reading.dart';
import '../widgets/app_scope.dart';

class ReadingDetailScreen extends StatefulWidget {
  const ReadingDetailScreen({super.key, required this.readingId});

  final String readingId;

  @override
  State<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends State<ReadingDetailScreen> {
  Reading? _reading;
  bool _isLoading = true;
  String? _error;
  bool _bootstrapped = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final reading = await AppScope.of(context).fetchReading(widget.readingId);
      if (!mounted) return;
      setState(() {
        _reading = reading;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Details releve'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Imprimer',
            icon: const Icon(Icons.print_outlined),
            onPressed: _reading == null ? null : () => _printReading(context),
          ),
          IconButton(
            tooltip: 'Modifier',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _handleEdit(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : _reading == null
                    ? _ErrorState(
                        message: 'Releve introuvable.',
                        onRetry: _load,
                      )
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        children: <Widget>[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'Index: ${_reading!.indexValue.toStringAsFixed(2)}',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Cumul: ${_reading!.cumulativeIndex?.toStringAsFixed(2) ?? '-'}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _InfoGrid(reading: _reading!),
                          const SizedBox(height: 12),
                          _FacturationsSection(
                            reading: _reading!,
                            onCreate: () => _openFacturationDialog(context),
                            onDelete: (facturation) =>
                                _confirmDeleteFacturation(context, facturation),
                          ),
                        ],
                      ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return DateFormat('dd/MM/yyyy', 'fr_CD').format(value.toLocal());
  }

  String _formatDateTime(DateTime value) {
    return DateFormat('dd/MM/yyyy HH:mm', 'fr_CD').format(value.toLocal());
  }

  Future<void> _printReading(BuildContext context) async {
    final reading = _reading;
    if (reading == null) return;

    final money = NumberFormat('#,##0.##', 'fr_CD');
    final dateShort = DateFormat('dd/MM/yyyy', 'fr_CD');
    final dateTime = DateFormat('dd/MM/yyyy HH:mm', 'fr_CD');
    final doc = pw.Document();

    final subscriberName = reading.subscriberName?.isNotEmpty == true
        ? reading.subscriberName!
        : '-';
    final subscriberEmail = reading.subscriberEmail?.isNotEmpty == true
        ? reading.subscriberEmail!
        : '-';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                'Forage RAYMOND MACHUMU',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Contact : ..............'),
              pw.Text('Adresse : ..............'),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),
              pw.Text(
                'Abonne',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Nom: $subscriberName'),
              pw.Text('Email: $subscriberEmail'),
              pw.SizedBox(height: 12),
              pw.Text(
                'Releve',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Date: ${dateShort.format(reading.date.toLocal())}'),
              pw.Text('Index: ${reading.indexValue.toStringAsFixed(2)}'),
              pw.Text(
                'Cumul: ${reading.cumulativeIndex?.toStringAsFixed(2) ?? '-'}',
              ),
              pw.Text('Cree le: ${dateTime.format(reading.createdAt.toLocal())}'),
              pw.SizedBox(height: 12),
              pw.Text(
                'Facturations',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              if (reading.facturations.isEmpty)
                pw.Text('Aucune facturation')
              else
                pw.Table.fromTextArray(
                  headers: <String>[
                    'Periode',
                    'Montant',
                    'Devise',
                    'Prix M3',
                    'Consommation',
                    'Paye',
                  ],
                  data: reading.facturations.map((facturation) {
                    return <String>[
                      facturation.period.isEmpty ? '-' : facturation.period,
                      money.format(facturation.totalAmount),
                      facturation.currency,
                      money.format(facturation.pricePerM3),
                      money.format(facturation.consumptionM3),
                      facturation.isPaid ? 'Oui' : 'Non',
                    ];
                  }).toList(),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                  ),
                  cellStyle: const pw.TextStyle(fontSize: 9),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey300),
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
    );
  }

  Future<void> _openFacturationDialog(BuildContext context) async {
    final reading = _reading;
    if (reading == null) return;
    final created = await showDialog<Facturation>(
      context: context,
      builder: (context) => _FacturationFormDialog(readingId: reading.id),
    );
    if (created != null && mounted) {
      setState(() {
        final updated = Reading(
          id: reading.id,
          subscriberId: reading.subscriberId,
          createdBy: reading.createdBy,
          date: reading.date,
          indexValue: reading.indexValue,
          createdAt: reading.createdAt,
          updatedAt: reading.updatedAt,
          cumulativeIndex: reading.cumulativeIndex,
          facturationCount:
              (reading.facturationCount ?? reading.facturations.length) + 1,
          subscriberName: reading.subscriberName,
          createdByName: reading.createdByName,
          createdByAvatarUrl: reading.createdByAvatarUrl,
          facturationPeriod: reading.facturationPeriod,
          facturationAmount: reading.facturationAmount,
          pricePerM3: reading.pricePerM3,
          consumptionM3: reading.consumptionM3,
          isPaid: reading.isPaid,
          facturations: <Facturation>[created, ...reading.facturations],
        );
        _reading = updated;
      });
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    final reading = _reading;
    if (reading == null) return;
    final hasBlockingFacturation = reading.facturations.any((facturation) {
      return facturation.isActive ?? true;
    });
    if (hasBlockingFacturation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Supprimez la facturation avant de modifier le releve.',
          ),
        ),
      );
      return;
    }

    final updated = await showDialog<Reading>(
      context: context,
      builder: (context) => _ReadingEditDialog(reading: reading),
    );
    if (updated != null && mounted) {
      setState(() {
        _reading = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Releve modifie.')),
      );
    }
  }

  Future<void> _confirmDeleteFacturation(
    BuildContext context,
    Facturation facturation,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer facturation'),
          content: const Text('Voulez-vous supprimer cette facturation ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );
    if (result != true) return;
    try {
      await AppScope.of(context).deleteFacturation(facturation.id);
      if (!mounted) return;
      setState(() {
        final reading = _reading;
        if (reading == null) return;
        final updatedCount =
            (reading.facturationCount ?? reading.facturations.length) - 1;
        _reading = Reading(
          id: reading.id,
          subscriberId: reading.subscriberId,
          createdBy: reading.createdBy,
          date: reading.date,
          indexValue: reading.indexValue,
          createdAt: reading.createdAt,
          updatedAt: reading.updatedAt,
          cumulativeIndex: reading.cumulativeIndex,
          facturationCount: updatedCount < 0 ? 0 : updatedCount,
          subscriberName: reading.subscriberName,
          createdByName: reading.createdByName,
          createdByAvatarUrl: reading.createdByAvatarUrl,
          facturationPeriod: reading.facturationPeriod,
          facturationAmount: reading.facturationAmount,
          pricePerM3: reading.pricePerM3,
          consumptionM3: reading.consumptionM3,
          isPaid: reading.isPaid,
          facturations: reading.facturations
              .where((item) => item.id != facturation.id)
              .toList(),
        );
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Facturation supprimee.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $error')),
      );
    }
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.reading});

  final Reading reading;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat('#,##0.##', 'fr_CD');
    final tiles = <Widget>[
      _InfoTile(
        label: 'Abonne',
        value: reading.subscriberName?.isNotEmpty == true
            ? reading.subscriberName!
            : '-',
        icon: Icons.person_outline,
      ),
      
      _InfoTile(
        label: 'Date du releve',
        value: DateFormat('dd/MM/yyyy', 'fr_CD').format(reading.date.toLocal()),
        icon: Icons.calendar_today_outlined,
      ),
      _InfoTile(
        label: 'Cree par',
        value: reading.createdByName?.isNotEmpty == true
            ? reading.createdByName!
            : '-',
        icon: Icons.badge_outlined,
      ),
      
      _InfoTile(
        label: 'Cree le',
        value: DateFormat('dd/MM/yyyy HH:mm', 'fr_CD')
            .format(reading.createdAt.toLocal()),
        icon: Icons.access_time,
      ),
      _InfoTile(
        label: 'Periode',
        value: reading.facturationPeriod ?? '-',
        icon: Icons.event_note_outlined,
      ),
      _InfoTile(
        label: 'Montant total',
        value: reading.facturationAmount == null
            ? '-'
            : money.format(reading.facturationAmount),
        icon: Icons.payments_outlined,
      ),
      _InfoTile(
        label: 'Prix M3',
        value: reading.pricePerM3 == null
            ? '-'
            : money.format(reading.pricePerM3),
        icon: Icons.water_drop_outlined,
      ),
      _InfoTile(
        label: 'Consommation (m3)',
        value: reading.consumptionM3 == null
            ? '-'
            : money.format(reading.consumptionM3),
        icon: Icons.bar_chart_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (!isWide) {
          return Column(children: tiles);
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 96,
            crossAxisSpacing: 16,
            mainAxisSpacing: 12,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) => tiles[index],
        );
      },
    );
  }
}

class _FacturationsSection extends StatelessWidget {
  const _FacturationsSection({
    required this.reading,
    required this.onCreate,
    required this.onDelete,
  });

  final Reading reading;
  final VoidCallback onCreate;
  final void Function(Facturation) onDelete;

  @override
  Widget build(BuildContext context) {
    final facturations = reading.facturations;
    final theme = Theme.of(context);
    if (facturations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Facturations',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text('Aucune facturation pour ce releve.'),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Creer une facturation'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Facturations',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            if (!isWide) {
              return Column(
                children: facturations
                    .map((facturation) =>
                        _FacturationCard(facturation, onDelete))
                    .toList(),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 190,
                crossAxisSpacing: 16,
                mainAxisSpacing: 12,
              ),
              itemCount: facturations.length,
              itemBuilder: (context, index) {
                return _FacturationCard(facturations[index], onDelete);
              },
            );
          },
        ),
      ],
    );
  }
}

class _FacturationCard extends StatelessWidget {
  const _FacturationCard(this.facturation, this.onDelete);

  final Facturation facturation;
  final void Function(Facturation) onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat('#,##0.##', 'fr_CD');
    final date =
        DateFormat('dd/MM/yyyy', 'fr_CD').format(facturation.createdAt.toLocal());
    final statusText = facturation.isPaid ? 'Paye' : 'Impayee';
    final statusColor = facturation.isPaid
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    facturation.period.isEmpty ? '-' : facturation.period,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Montant: ${money.format(facturation.totalAmount)} ${facturation.currency}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Prix M3: ${money.format(facturation.pricePerM3)} ${facturation.currency}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              'Consommation: ${money.format(facturation.consumptionM3)} m3',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              'Cree le $date',
              style: theme.textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onDelete(facturation),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Supprimer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadingEditDialog extends StatefulWidget {
  const _ReadingEditDialog({required this.reading});

  final Reading reading;

  @override
  State<_ReadingEditDialog> createState() => _ReadingEditDialogState();
}

class _ReadingEditDialogState extends State<_ReadingEditDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _indexController = TextEditingController();
  late DateTime _date;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _indexController.text = widget.reading.indexValue.toString();
    _date = widget.reading.date;
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
    setState(() {
      _isSaving = true;
    });
    final indexValue = double.tryParse(_indexController.text.trim()) ?? 0;
    try {
      final updated = await AppScope.of(context).updateReading(
        readingId: widget.reading.id,
        date: _date,
        indexValue: indexValue,
      );
      if (mounted) {
        Navigator.of(context).pop(updated);
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
    final formatter = DateFormat('dd/MM/yyyy', 'fr_CD');
    return AlertDialog(
      title: const Text('Modifier releve'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Date'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(formatter.format(_date)),
                      const Icon(Icons.calendar_today_outlined, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
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
    );
  }
}

class _FacturationFormDialog extends StatefulWidget {
  const _FacturationFormDialog({required this.readingId});

  final String readingId;

  @override
  State<_FacturationFormDialog> createState() => _FacturationFormDialogState();
}

class _FacturationFormDialogState extends State<_FacturationFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _currency = 'CDF';
  bool _isPaid = true;
  bool _isSaving = false;
  bool _isLoadingParams = false;
  bool _bootstrapped = false;
  String? _loadError;
  List<AppParameter> _parameters = <AppParameter>[];
  AppParameter? _selectedParameter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bootstrapped) return;
    _bootstrapped = true;
    _loadParameters();
  }

  Future<void> _loadParameters() async {
    setState(() {
      _isLoadingParams = true;
      _loadError = null;
    });
    try {
      final params = await AppScope.of(context).fetchParameters();
      final active = params.where((param) => param.active).toList();
      if (!mounted) return;
      setState(() {
        _parameters = active;
        _selectedParameter = active.isNotEmpty ? active.first : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingParams = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    final parameter = _selectedParameter;
    if (parameter == null) return;
    setState(() {
      _isSaving = true;
    });
    final price = double.tryParse(parameter.value.replaceAll(',', '.')) ?? 0;
    try {
      final facturation = await AppScope.of(context).createFacturation(
        readingId: widget.readingId,
        pricePerM3: price,
        currency: _currency,
        isPaid: _isPaid,
      );
      if (mounted) {
        Navigator.of(context).pop(facturation);
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
    return AlertDialog(
      title: const Text('Nouvelle facturation'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_isLoadingParams)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: CircularProgressIndicator(),
                )
              else if (_loadError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_loadError!),
                ),
              DropdownButtonFormField<AppParameter>(
                value: _parameters.contains(_selectedParameter)
                    ? _selectedParameter
                    : null,
                isExpanded: true,
                items: _parameters
                    .map(
                      (param) => DropdownMenuItem<AppParameter>(
                        value: param,
                        child: Text('${param.keyName}: ${param.value}'),
                      ),
                    )
                    .toList(),
                onChanged: _isLoadingParams
                    ? null
                    : (value) {
                        setState(() {
                          _selectedParameter = value;
                        });
                      },
                decoration: const InputDecoration(labelText: 'Prix M3'),
                validator: (value) {
                  if (value == null) {
                    return 'Selectionnez un prix';
                  }
                  final parsed =
                      double.tryParse(value.value.replaceAll(',', '.'));
                  if (parsed == null) {
                    return 'Valeur invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _currency,
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'CDF', child: Text('CDF')),
                  DropdownMenuItem(value: 'USD', child: Text('USD')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _currency = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Devise'),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isPaid,
                onChanged: (value) {
                  setState(() {
                    _isPaid = value;
                  });
                },
                title: const Text('Paye'),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed:
              _isSaving || _isLoadingParams ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSaving || _isLoadingParams ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.warning_amber_outlined, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
