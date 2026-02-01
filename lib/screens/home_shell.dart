import 'package:flutter/material.dart';

import '../widgets/app_scope.dart';
import 'account_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'parameters_screen.dart';
import 'readings_screen.dart';
import 'subscribers_screen.dart';
import 'users_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  static const routeName = '/';

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = _navItems();
    final pages = <Widget>[
      const HomeScreen(),
      const UsersScreen(),
      const SubscribersScreen(),
      const ReadingsScreen(),
      const AccountScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Scaffold(
          appBar: AppBar(
            title: Text(items[_index].title),
            actions: <Widget>[
              IconButton(
                tooltip: 'Parametres',
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => _openParameters(context),
              ),
              IconButton(
                tooltip: 'Deconnexion',
                icon: const Icon(Icons.logout),
                onPressed: _confirmLogout,
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            children: <Widget>[
              if (isWide)
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (value) {
                    setState(() {
                      _index = value;
                    });
                  },
                  backgroundColor: theme.colorScheme.surface,
                  labelType: NavigationRailLabelType.all,
                  destinations: items
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          label: Text(item.title),
                        ),
                      )
                      .toList(),
                ),
              Expanded(child: pages[_index]),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : SafeArea(
                  top: false,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: BottomNavigationBar(
                      type: BottomNavigationBarType.fixed,
                      currentIndex: _index,
                      selectedItemColor: theme.colorScheme.primary,
                      unselectedItemColor: theme.colorScheme.onSurface
                          .withValues(alpha: 0.6),
                      backgroundColor: theme.colorScheme.surface,
                      showUnselectedLabels: true,
                      onTap: (value) {
                        setState(() {
                          _index = value;
                        });
                      },
                      items: items
                          .map(
                            (item) => BottomNavigationBarItem(
                              icon: Icon(item.icon),
                              label: item.title,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
        );
      },
    );
  }

  List<_NavItem> _navItems() {
    return const <_NavItem>[
      _NavItem(title: 'Accueil', icon: Icons.home_outlined),
      _NavItem(title: 'Utilisateurs', icon: Icons.people_outline),
      _NavItem(title: 'Abonnés', icon: Icons.water_drop_outlined),
      _NavItem(title: 'Relevés', icon: Icons.list_alt_outlined),
      _NavItem(title: 'Compte', icon: Icons.person_outline),
    ];
  }

  Future<void> _confirmLogout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Se deconnecter'),
          content: const Text('Voulez-vous quitter votre session ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Quitter'),
            ),
          ],
        );
      },
    );

    if (result == true && mounted) {
      await AppScope.of(context).clearAuthToken();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
    }
  }

  Future<void> _openParameters(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const ParametersScreen()),
    );
  }
}

class _NavItem {
  const _NavItem({required this.title, required this.icon});

  final String title;
  final IconData icon;
}
