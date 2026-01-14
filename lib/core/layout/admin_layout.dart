import 'package:flutter/material.dart';
import 'responsive_layout.dart';

class AdminLayout extends StatelessWidget {
  final Widget content;
  final String title;

  const AdminLayout({
    required this.content,
    this.title = 'PetDay • Admin',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _AdminMobileLayout(
        content: content,
        title: title,
      ),
      desktop: _AdminDesktopLayout(
        content: content,
      ),
    );
  }
}

/* ======= MOBILE ======= */
class _AdminMobileLayout extends StatelessWidget {
  final Widget content;
  final String title;

  const _AdminMobileLayout({
    required this.content,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      drawer: const _AdminDrawer(),
      body: content,
    );
  }
}



/* ======= DESKTOP ======= */
class _AdminDesktopLayout extends StatelessWidget {
  final Widget content;

  const _AdminDesktopLayout({
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _AdminSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: content,
            ),
          ),
        ],
      ),
    );
  }
}


/* ======= SIDEBAR ======= */
class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.teal.shade50,
      child: ListView(
        children: const [
          SizedBox(height: 24),
          _SidebarHeader(),
          SizedBox(height: 24),
          _MenuItem(Icons.today, 'Hoje'),
          _MenuItem(Icons.event, 'Agenda'),
          _MenuItem(Icons.pets, 'Pets'),
          _MenuItem(Icons.list_alt, 'Reservas'),
          _MenuItem(Icons.settings, 'Configurações'),
        ],
      ),
    );
  }
}


/* ======= DRAWER ======= */
class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const [
          DrawerHeader(
            child: Text(
              'PetDay',
              style: TextStyle(fontSize: 22),
            ),
          ),
          _MenuItem(Icons.today, 'Hoje'),
          _MenuItem(Icons.event, 'Agenda'),
          _MenuItem(Icons.pets, 'Pets'),
          _MenuItem(Icons.list_alt, 'Reservas'),
          _MenuItem(Icons.settings, 'Configurações'),
        ],
      ),
    );
  }
}


/* ======= COMPONENTES ======= */
class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'PetDay',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}


class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: () {
        // navegação depois
      },
    );
  }
}