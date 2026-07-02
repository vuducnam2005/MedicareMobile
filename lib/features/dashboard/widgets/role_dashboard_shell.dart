import 'package:flutter/material.dart';

class RoleDashboardMenuItem {
  const RoleDashboardMenuItem({
    required this.title,
    required this.icon,
    required this.index,
    required this.section,
  });

  final String title;
  final IconData icon;
  final int index;
  final String section;
}

class RoleDashboardShell extends StatelessWidget {
  const RoleDashboardShell({
    super.key,
    required this.scaffoldKey,
    required this.title,
    required this.userName,
    required this.roleLabel,
    required this.primaryColor,
    required this.menuItems,
    required this.selectedIndex,
    required this.onMenuSelected,
    required this.onLogout,
    required this.body,
    PreferredSizeWidget? appBar,
    Widget? drawer,
    this.bottomNavigationBar,
    this.onRefresh,
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.roleSubtitle,
    this.avatarIcon,
    this.isLoading = false,
    this.appBarActions,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;
  final String title;
  final String userName;
  final String roleLabel;
  final String? roleSubtitle;
  final Color primaryColor;
  final Color backgroundColor;
  final List<RoleDashboardMenuItem> menuItems;
  final int selectedIndex;
  final ValueChanged<int> onMenuSelected;
  final VoidCallback onLogout;
  final VoidCallback? onRefresh;
  final Widget body;
  final Widget? bottomNavigationBar;
  final IconData? avatarIcon;
  final bool isLoading;
  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0.5,
        actions: [
          if (appBarActions != null) ...appBarActions!,
          if (onRefresh != null)
            IconButton(
              tooltip: 'Làm mới',
              icon: Icon(Icons.refresh_rounded, color: primaryColor),
              onPressed: onRefresh,
            ),
        ],
      ),
      drawer: _RoleDashboardDrawer(
        userName: userName,
        roleLabel: roleLabel,
        roleSubtitle: roleSubtitle,
        primaryColor: primaryColor,
        avatarIcon: avatarIcon,
        menuItems: menuItems,
        selectedIndex: selectedIndex,
        onMenuSelected: onMenuSelected,
        onLogout: onLogout,
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: primaryColor))
            : body,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class _RoleDashboardDrawer extends StatelessWidget {
  const _RoleDashboardDrawer({
    required this.userName,
    required this.roleLabel,
    required this.primaryColor,
    required this.menuItems,
    required this.selectedIndex,
    required this.onMenuSelected,
    required this.onLogout,
    this.roleSubtitle,
    this.avatarIcon,
  });

  final String userName;
  final String roleLabel;
  final String? roleSubtitle;
  final Color primaryColor;
  final IconData? avatarIcon;
  final List<RoleDashboardMenuItem> menuItems;
  final int selectedIndex;
  final ValueChanged<int> onMenuSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final groupedItems = <String, List<RoleDashboardMenuItem>>{};
    for (final item in menuItems) {
      groupedItems.putIfAbsent(item.section, () => []).add(item);
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, _lighten(primaryColor)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  child: avatarIcon == null
                      ? Text(
                          _initials(userName),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )
                      : Icon(avatarIcon, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 12),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (roleSubtitle != null && roleSubtitle!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    roleSubtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.82),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleLabel.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final entry in groupedItems.entries) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  ...entry.value.map(
                    (item) => _RoleDashboardMenuTile(
                      item: item,
                      selected: selectedIndex == item.index,
                      primaryColor: primaryColor,
                      onTap: () {
                        onMenuSelected(item.index);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.redAccent,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () {
              Navigator.pop(ctx);
              onLogout();
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static Color _lighten(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + 0.12).clamp(0.0, 1.0)).toColor();
  }
}

class _RoleDashboardMenuTile extends StatelessWidget {
  const _RoleDashboardMenuTile({
    required this.item,
    required this.selected,
    required this.primaryColor,
    required this.onTap,
  });

  final RoleDashboardMenuItem item;
  final bool selected;
  final Color primaryColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? primaryColor.withOpacity(0.10) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        minLeadingWidth: 24,
        leading: Icon(
          item.icon,
          color: selected ? primaryColor : Colors.grey.shade600,
          size: 22,
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? primaryColor : Colors.grey.shade800,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
