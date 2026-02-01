import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
        title: const Text('Détails relevé'),
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
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: _reading == null ? null : () => _handleDelete(context),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _ErrorState(message: _error!, onRetry: _load)
            : _reading == null
            ? _ErrorState(message: 'Relevé introuvable.', onRetry: _load)
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
                    onUpdateStatus: _handleUpdateStatus,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _printReading(BuildContext context) async {
    final reading = _reading;
    if (reading == null) return;

    final money = NumberFormat('#,##0.##', 'fr_CD');
    final dateShort = DateFormat('EEEE d MMMM yyyy', 'fr_CD');
    final dateTime = DateFormat('EEEE d MMMM yyyy HH:mm', 'fr_CD');
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
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.only(bottom: 16),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 2, color: PdfColors.blue900),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Forage RAYMOND MACHUMU',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Facture de consommation d\'eau',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Subscriber Info
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Abonné',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Nom: ',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          subscriberName,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Row(
                      children: [
                        pw.Text(
                          'Email: ',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                        pw.Text(
                          subscriberEmail,
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Reading Info
              pw.Text(
                'Relevé',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Date: ${dateShort.format(reading.date.toLocal())}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Index: ${reading.indexValue.toStringAsFixed(2)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Cumul: ${reading.cumulativeIndex?.toStringAsFixed(2) ?? '-'}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Facturation
              pw.Text(
                'Facturation',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 8),
              if (reading.facturation == null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(4),
                    ),
                  ),
                  child: pw.Text(
                    'Aucune facturation',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                )
              else
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Table.fromTextArray(
                      headers: <String>[
                        'Période',
                        'Montant (FC)',
                        'Prix M3 (FC)',
                        'Consommation (m³)',
                        'Payé',
                      ],
                      data: <List<String>>[
                        <String>[
                          reading.facturation!.period.isEmpty
                              ? '-'
                              : reading.facturation!.period,
                          money.format(reading.facturation!.totalAmount),
                          money.format(reading.facturation!.pricePerM3),
                          money.format(reading.facturation!.consumptionM3),
                          reading.facturation!.isPaid ? 'Oui' : 'Non',
                        ],
                      ],
                      border: pw.TableBorder.all(color: PdfColors.grey400),
                      cellAlignment: pw.Alignment.centerLeft,
                      headerStyle: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                        color: PdfColors.white,
                      ),
                      cellStyle: const pw.TextStyle(fontSize: 10),
                      headerDecoration: const pw.BoxDecoration(
                        color: PdfColors.blue900,
                      ),
                      cellPadding: const pw.EdgeInsets.all(8),
                      headerPadding: const pw.EdgeInsets.all(8),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Créé le: ${dateTime.format(reading.createdAt.toLocal())}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  Future<void> _handleDelete(BuildContext context) async {
    final reading = _reading;
    if (reading == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Supprimer relevé'),
          content: const Text(
            'Voulez-vous vraiment supprimer ce relevé ? Cette action est irréversible.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
              ),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await AppScope.of(context).deleteReading(reading.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Relevé supprimé.')));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
    }
  }

  Future<void> _handleEdit(BuildContext context) async {
    final reading = _reading;
    if (reading == null) return;
    if (reading.facturation?.isActive ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Supprimez la facturation avant de modifier le relevé.',
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Relevé modifié.')));
    }
  }

  Future<void> _handleUpdateStatus(Facturation facturation, bool isPaid) async {
    if (!mounted) return;
    // Optimistic update or wait for API success?
    // Let's wait for API success but update locally instead of full reload.

    try {
      await AppScope.of(
        context,
      ).updateFacturationStatus(facturation.id, isPaid);
      if (!mounted) return;

      setState(() {
        _reading = _reading?.copyWith(
          facturation: facturation.copyWith(isPaid: isPaid),
          isPaid: isPaid, // Reading also has isPaid field
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statut de paiement mis à jour.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        // No loading state to toggle off, but we show error
        _error = error.toString();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur: $error')));
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
        label: 'Abonné',
        value: reading.subscriberName?.isNotEmpty == true
            ? reading.subscriberName!
            : '-',
        icon: Icons.person_outline,
      ),
      _InfoTile(
        label: 'Date du relevé',
        value: DateFormat(
          'EEEE d MMMM yyyy',
          'fr_CD',
        ).format(reading.date.toLocal()),
        icon: Icons.calendar_today_outlined,
      ),
      _InfoTile(
        label: 'Créé par',
        value: reading.createdByName?.isNotEmpty == true
            ? reading.createdByName!
            : '-',
        icon: Icons.badge_outlined,
      ),
      _InfoTile(
        label: 'Créé le',
        value: DateFormat(
          'EEEE d MMMM yyyy HH:mm',
          'fr_CD',
        ).format(reading.createdAt.toLocal()),
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
            : '${money.format(reading.facturationAmount)} CDF',
        icon: Icons.payments_outlined,
      ),
      _InfoTile(
        label: 'Prix M3',
        value: reading.pricePerM3 == null
            ? '-'
            : '${money.format(reading.pricePerM3)} CDF',
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
    required this.onUpdateStatus,
  });

  final Reading reading;
  final void Function(Facturation, bool) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final facturation = reading.facturation;
    final theme = Theme.of(context);

    if (facturation == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Facturation', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text('Aucune facturation pour ce relevé.'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Facturation', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _FacturationCard(
          facturation: facturation,
          onUpdateStatus: onUpdateStatus,
        ),
      ],
    );
  }
}

class _FacturationCard extends StatelessWidget {
  const _FacturationCard({
    required this.facturation,
    required this.onUpdateStatus,
  });

  final Facturation facturation;
  final void Function(Facturation, bool) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = NumberFormat('#,##0.##', 'fr_CD');
    final date = DateFormat(
      'EEEE d MMMM yyyy',
      'fr_CD',
    ).format(facturation.createdAt.toLocal());
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
            Text('Créé le $date', style: theme.textTheme.bodySmall),
            const Divider(),
            SwitchListTile(
              title: const Text('Est payé'),
              subtitle: Text(
                facturation.isPaid ? 'Payé' : 'Impayée',
                style: TextStyle(
                  color: facturation.isPaid
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              value: facturation.isPaid,
              onChanged: (value) => onUpdateStatus(facturation, value),
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
      title: const Text('Modifier relevé'),
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, this.icon});

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(label, style: theme.textTheme.bodySmall),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline, size: 48, color: Colors.orange),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
