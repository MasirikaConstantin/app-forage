import 'package:flutter/material.dart';

import '../models/app_parameter.dart';
import '../widgets/app_scope.dart';
import '../widgets/decorated_background.dart';
import '../widgets/fade_slide_in.dart';

class ParametersScreen extends StatefulWidget {
  const ParametersScreen({super.key});

  @override
  State<ParametersScreen> createState() => _ParametersScreenState();
}

class _ParametersScreenState extends State<ParametersScreen> {
  bool _isLoading = false;
  List<AppParameter> _parameters = <AppParameter>[];
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
    });
    try {
      final items = await AppScope.of(context).fetchParameters();
      if (!mounted) return;
      setState(() {
        _parameters = items;
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

  Future<void> _openCreate() async {
    final created = await showDialog<AppParameter>(
      context: context,
      builder: (context) => const _ParameterFormDialog(),
    );
    if (created != null) {
      setState(() {
        _parameters = <AppParameter>[created, ..._parameters];
      });
    }
  }

  Future<void> _openEdit(AppParameter parameter) async {
    final updated = await showDialog<AppParameter>(
      context: context,
      builder: (context) => _ParameterFormDialog(parameter: parameter),
    );
    if (updated != null) {
      setState(() {
        final index =
            _parameters.indexWhere((item) => item.id == updated.id);
        if (index == -1) {
          _parameters = <AppParameter>[updated, ..._parameters];
        } else {
          _parameters = List<AppParameter>.from(_parameters)
            ..[index] = updated;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = theme.colorScheme.surface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurations'),
      ),
      body: DecoratedBackground(
        gradientColors: <Color>[background],
        accents: const <Widget>[],
        child: Stack(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                FadeSlideIn(
                  child: Text(
                    'Configurations',
                    style: theme.textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Parametres du forage et du prix du metre cube.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: _parameters.isEmpty
                      ? (_isLoading
                          ? const _LoadingState()
                          : const _EmptyState())
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final width = constraints.maxWidth;
                            final computed = (width / 300).floor();
                            final crossAxisCount = computed.clamp(1, 3);
                            const mainAxisExtent = 110.0;

                            return GridView.builder(
                              padding: EdgeInsets.zero,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: mainAxisExtent,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                              itemCount: _parameters.length,
                              itemBuilder: (context, index) {
                                final param = _parameters[index];
                                return FadeSlideIn(
                                  delay: Duration(milliseconds: 30 * index),
                                  child: _ParameterCard(
                                    parameter: param,
                                    onTap: () => _openEdit(param),
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
                  onPressed: _isLoading ? null : _openCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParameterCard extends StatelessWidget {
  const _ParameterCard({
    required this.parameter,
    required this.onTap,
  });

  final AppParameter parameter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = parameter.active
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      parameter.keyName.isEmpty ? '-' : parameter.keyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                parameter.value.isEmpty ? '-' : parameter.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                parameter.description.isEmpty ? '-' : parameter.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParameterFormDialog extends StatefulWidget {
  const _ParameterFormDialog({this.parameter});

  final AppParameter? parameter;

  @override
  State<_ParameterFormDialog> createState() => _ParameterFormDialogState();
}

class _ParameterFormDialogState extends State<_ParameterFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _active = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final parameter = widget.parameter;
    if (parameter != null) {
      _keyController.text = parameter.keyName;
      _valueController.text = parameter.value;
      _descriptionController.text = parameter.description;
      _active = parameter.active;
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      final param = AppParameter(
        id: widget.parameter?.id ?? '',
        keyName: _keyController.text.trim(),
        value: _valueController.text.trim(),
        description: _descriptionController.text.trim(),
        active: _active,
      );
      final created = widget.parameter == null
          ? await AppScope.of(context).createParameter(param)
          : await AppScope.of(context).updateParameter(param);
      if (mounted) {
        Navigator.of(context).pop(created);
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
      title: Text(
        widget.parameter == null ? 'Nouveau parametre' : 'Modifier parametre',
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: _keyController,
                  decoration: const InputDecoration(
                    labelText: 'Cle',
                    helperText: 'Ex: Prix M3 (prix du metre cube)',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entrez une cle';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valueController,
                  decoration: const InputDecoration(labelText: 'Valeur'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Entrez une valeur';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
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
              : Text(widget.parameter == null ? 'Enregistrer' : 'Modifier'),
        ),
      ],
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
          Text('Chargement des parametres...'),
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
              const Icon(Icons.settings_outlined, size: 40),
              const SizedBox(height: 8),
              Text(
                'Aucun parametre disponible.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
