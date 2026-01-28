import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/subscriber.dart';
import '../widgets/app_scope.dart';

class SubscriberCreateScreen extends StatefulWidget {
  const SubscriberCreateScreen({super.key});

  @override
  State<SubscriberCreateScreen> createState() => _SubscriberCreateScreenState();
}

class _SubscriberCreateScreenState extends State<SubscriberCreateScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _professionController = TextEditingController();
  bool _active = true;
  DateTime _dateNaissance = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateNaissance,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _dateNaissance = picked;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
    });
    final store = AppScope.of(context);
    final fullName =
        '${_nomController.text.trim()} ${_prenomController.text.trim()}'.trim();
    try {
      await store.addSubscriber(
        Subscriber(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          fullName: fullName,
          email: _emailController.text.trim(),
          phone: _telephoneController.text.trim(),
          location: _adresseController.text.trim(),
          plan: _professionController.text.trim(),
          active: _active,
          startDate: _dateNaissance,
          monthlyFee: 0,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Abonne enregistre')),
        );
        Navigator.of(context).pop();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistrement en local')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvel abonne')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final contentWidth = width >= 900 ? 820.0 : width;
            final twoCols = width >= 800;

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentWidth),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: <Widget>[
                      if (twoCols)
                        _RowFields(
                          left: _FieldBox(
                            child: TextFormField(
                              controller: _nomController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(labelText: 'Nom'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Entrez le nom';
                                }
                                return null;
                              },
                            ),
                          ),
                          right: _FieldBox(
                            child: TextFormField(
                              controller: _prenomController,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  const InputDecoration(labelText: 'Prenom'),
                              validator: (_) => null,
                            ),
                          ),
                        )
                      else
                        TextFormField(
                          controller: _nomController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Nom'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Entrez le nom';
                            }
                            return null;
                          },
                        ),
                      if (!twoCols) const SizedBox(height: 12),
                      if (!twoCols)
                        TextFormField(
                          controller: _prenomController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Prenom'),
                          validator: (_) => null,
                        ),
                      const SizedBox(height: 12),
                      if (twoCols)
                        _RowFields(
                          left: _FieldBox(
                            child: TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  const InputDecoration(labelText: 'Email'),
                              validator: (_) => null,
                            ),
                          ),
                          right: _FieldBox(
                            child: TextFormField(
                              controller: _telephoneController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  const InputDecoration(labelText: 'Telephone'),
                              validator: (_) => null,
                            ),
                          ),
                        )
                      else ...<Widget>[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _telephoneController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          decoration:
                              const InputDecoration(labelText: 'Telephone'),
                          validator: (_) => null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (twoCols)
                        _RowFields(
                          left: _FieldBox(
                            child: TextFormField(
                              controller: _adresseController,
                              textInputAction: TextInputAction.next,
                              decoration:
                                  const InputDecoration(labelText: 'Adresse'),
                              validator: (_) => null,
                            ),
                          ),
                          right: _FieldBox(
                            child: TextFormField(
                              controller: _professionController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Profession',
                              ),
                              validator: (_) => null,
                            ),
                          ),
                        )
                      else ...<Widget>[
                        TextFormField(
                          controller: _adresseController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(labelText: 'Adresse'),
                          validator: (_) => null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _professionController,
                          textInputAction: TextInputAction.next,
                          decoration:
                              const InputDecoration(labelText: 'Profession'),
                          validator: (_) => null,
                        ),
                      ],
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: InputDecorator(
                          decoration:
                              const InputDecoration(labelText: 'Date naissance'),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(formatter.format(_dateNaissance)),
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
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
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
            );
          },
        ),
      ),
    );
  }
}

class _RowFields extends StatelessWidget {
  const _RowFields({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _FieldBox extends StatelessWidget {
  const _FieldBox({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        child,
        const SizedBox(height: 12),
      ],
    );
  }
}
