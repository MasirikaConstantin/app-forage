import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/subscriber.dart';
import '../widgets/app_scope.dart';

Future<void> showSubscriberFormDialog(BuildContext context,
    {Subscriber? subscriber}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => SubscriberFormDialog(subscriber: subscriber),
  );
}

class SubscriberFormDialog extends StatefulWidget {
  const SubscriberFormDialog({super.key, this.subscriber});

  final Subscriber? subscriber;

  @override
  State<SubscriberFormDialog> createState() => _SubscriberFormDialogState();
}

class _SubscriberFormDialogState extends State<SubscriberFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _locationController;
  TextEditingController? _professionController;
  late bool _active;
  late DateTime _startDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.subscriber?.fullName ?? '');
    _emailController =
        TextEditingController(text: widget.subscriber?.email ?? '');
    _phoneController =
        TextEditingController(text: widget.subscriber?.phone ?? '');
    _locationController =
        TextEditingController(text: widget.subscriber?.location ?? '');
    _professionController =
        TextEditingController(text: widget.subscriber?.plan ?? '');
    _active = widget.subscriber?.active ?? true;
    _startDate = widget.subscriber?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _professionController?.dispose();
    super.dispose();
  }

  TextEditingController _ensureProfessionController() {
    return _professionController ??= TextEditingController(
      text: widget.subscriber?.plan ?? '',
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });
    final store = AppScope.of(context);
    final professionController = _ensureProfessionController();

    try {
      if (widget.subscriber == null) {
        await store.addSubscriber(
          Subscriber(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          location: _locationController.text.trim(),
          plan: professionController.text.trim(),
          active: _active,
          startDate: _startDate,
          monthlyFee: 0,
        ),
      );
      } else {
        await store.updateSubscriber(
          widget.subscriber!.copyWith(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          location: _locationController.text.trim(),
          plan: professionController.text.trim(),
          active: _active,
          startDate: _startDate,
          monthlyFee: widget.subscriber!.monthlyFee,
        ),
      );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2019),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: Text(widget.subscriber == null ? 'Nouvel abonne' : 'Modifier abonne'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entrez un nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) return null;
                    if (!trimmed.contains('@')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Telephone'),
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(labelText: 'Localisation'),
                  validator: (value) {
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _ensureProfessionController(),
                  decoration: const InputDecoration(labelText: 'Profession'),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date de debut'),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(formatter.format(_startDate)),
                        const Icon(Icons.calendar_today_outlined, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _active,
                  onChanged: (value) {
                    setState(() {
                      _active = value;
                    });
                  },
                  title: const Text('Actif'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
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
              : Text(widget.subscriber == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
      surfaceTintColor: theme.colorScheme.surface,
    );
  }
}
