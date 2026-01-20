import 'package:flutter/material.dart';
import 'package:petday/features/admin/configuracoes/configuracoes_page.dart';
import 'package:petday/features/admin/home/dashboard_admin_page.dart';
import 'package:petday/features/admin/home_admin_page.dart';

import 'responsive_layout.dart';

/* =========================================================
   Funções de navegação padrão
========================================================= */

void goToHome(BuildContext context) {
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) => const HomeAdminPage(),
    ),
    (route) => false,
  );
}

void goToDashboard(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DashboardAdminPage(),
    ),
  );
}

/* =========================================================
   ADMIN LAYOUT
========================================================= */

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
        title: title,
      ),
    );
  }
}

/* =======================
   MOBILE
======================= */

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

/* =======================
   DESKTOP
======================= */

class _AdminDesktopLayout extends StatelessWidget {
  final Widget content;
  final String title;

  const _AdminDesktopLayout({
    required this.content,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const _AdminSidebar(),
          Expanded(
            child: Column(
              children: [
                _AdminDesktopHeader(title: title),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: content,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminDesktopHeader extends StatelessWidget {
  final String title;

  const _AdminDesktopHeader({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/* =======================
   SIDEBAR (DESKTOP)
======================= */

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      color: Colors.teal.shade50,
      child: ListView(
        children: [
          const SizedBox(height: 24),
          const _SidebarHeader(),
          const SizedBox(height: 24),

          _MenuItem(
            Icons.home,
            'Home',
            onTap: () => goToHome(context),
          ),

          _MenuItem(
            Icons.bar_chart,
            'Vagas',
            onTap: () => goToDashboard(context),
          ),

          _MenuItem(
            Icons.settings,
            'Configurações',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConfiguracoesPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/* =======================
   DRAWER (MOBILE)
======================= */

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            child: Text(
              'PetDay',
              style: TextStyle(fontSize: 22),
            ),
          ),

          _MenuItem(
            Icons.home,
            'Home',
            onTap: () {
              Navigator.pop(context);
              goToHome(context);
            },
          ),

          _MenuItem(
            Icons.bar_chart,
            'Vagas',
            onTap: () {
              Navigator.pop(context);
              goToDashboard(context);
            },
          ),

          _MenuItem(
            Icons.settings,
            'Configurações',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ConfiguracoesPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/* =======================
   COMPONENTES
======================= */

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
  final VoidCallback onTap;

  const _MenuItem(
    this.icon,
    this.label, {
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
