import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../theme/app_colors.dart';

class ShoppingListsScreen extends StatelessWidget {
  const ShoppingListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Einkaufslisten'),
        centerTitle: true,
      ),
      body: appState.lists.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: appState.lists.length,
              itemBuilder: (context, index) {
                final list = appState.lists[index];
                final isActive = list.id == appState.activeList?.id;

                return Card(
                  elevation: isActive ? 3 : 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isActive
                        ? BorderSide(color: AppColors.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: isActive
                          ? AppColors.primary
                          : AppColors.surfaceHigh,
                      child: Icon(
                        Icons.shopping_cart,
                        color: isActive ? AppColors.onPrimary : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      list.name,
                      style: TextStyle(
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${list.itemCount} Artikel · €${list.total.toStringAsFixed(2)}',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showRenameDialog(context, appState, list.id, list.name),
                        ),
                        if (appState.lists.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                            onPressed: () => _showDeleteConfirmation(context, appState, list.id, list.name),
                          ),
                      ],
                    ),
                    onTap: () async {
                      await appState.switchList(list.id);
                      if (context.mounted) Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, appState),
        icon: const Icon(Icons.add),
        label: const Text('Neue Liste'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, AppState appState) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neue Einkaufsliste'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name der Liste'),
          onSubmitted: (_) => _createList(context, appState, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => _createList(context, appState, controller.text),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  void _createList(BuildContext context, AppState appState, String name) {
    if (name.trim().isEmpty) return;
    appState.createList(name.trim());
    Navigator.pop(context); // schließt Dialog
    Navigator.pop(context); // schließt ShoppingListsScreen → ShoppingListScreen zeigt neue Liste
  }

  void _showRenameDialog(BuildContext context, AppState appState, String id, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liste umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Neuer Name'),
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              appState.renameList(id, controller.text.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                appState.renameList(id, controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppState appState, String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liste löschen?'),
        content: Text('"$name" wird unwiderruflich gelöscht.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              appState.deleteList(id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
