import 'package:flutter/material.dart';
import '../models/pdf_model.dart';
import '../services/pdf_service.dart';
import '../services/admin_pdf_service.dart';

class AdminManageItemsScreen extends StatefulWidget {
  const AdminManageItemsScreen({super.key});

  @override
  State<AdminManageItemsScreen> createState() =>
      _AdminManageItemsScreenState();
}

class _AdminManageItemsScreenState extends State<AdminManageItemsScreen> {
  final PdfService _pdfService = PdfService();
  final AdminPdfService _adminService = AdminPdfService();

  List<PdfModel> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _loading = true);

    try {
      final items = await _pdfService.fetchPdfs();

      if (!mounted) return;

      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> _editItem(PdfModel item) async {
    final titleController = TextEditingController(text: item.title);
    final descriptionController =
        TextEditingController(text: item.description);
    final priceController =
        TextEditingController(text: item.price.toString());
    final categoryController =
        TextEditingController(text: item.category);
    final fileUrlController =
        TextEditingController(text: item.fileUrl);

    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Item'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration:
                            const InputDecoration(labelText: 'Title'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a title'
                                : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                      ),
                      TextFormField(
                        controller: priceController,
                        decoration:
                            const InputDecoration(labelText: 'Price'),
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final price = double.tryParse(
                            value?.trim() ?? '',
                          );

                          if (price == null || price < 0) {
                            return 'Enter a valid price';
                          }

                          return null;
                        },
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration:
                            const InputDecoration(labelText: 'Category'),
                      ),
                      TextFormField(
                        controller: fileUrlController,
                        decoration:
                            const InputDecoration(labelText: 'File URL'),
                        maxLines: 2,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a file URL'
                                : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() => saving = true);

                          try {
                            await _adminService.updatePdf(
                              id: item.id,
                              title: titleController.text.trim(),
                              description:
                                  descriptionController.text.trim(),
                              price: double.parse(
                                priceController.text.trim(),
                              ),
                              category: categoryController.text.trim(),
                              fileUrl: fileUrlController.text.trim(),
                            );

                            if (!dialogContext.mounted) return;

                            Navigator.pop(dialogContext, true);
                          } catch (e) {
                            setDialogState(() => saving = false);

                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    categoryController.dispose();
    fileUrlController.dispose();

    if (result == true && mounted) {
      await _loadItems();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );
    }
  }

  Future<void> _deleteItem(PdfModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Item?'),
          content: Text(
            'Are you sure you want to delete "${item.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _adminService.deletePdf(item.id);

      if (!mounted) return;

      setState(() {
        _items.removeWhere((existing) => existing.id == item.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Items'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadItems,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text('No items available'),
                )
              : RefreshIndicator(
                  onRefresh: _loadItems,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];

                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.description),
                          ),
                          title: Text(item.title),
                          subtitle: Text(
                            '${item.category} • ${item.price.toStringAsFixed(2)} Birr',
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editItem(item);
                              } else if (value == 'delete') {
                                _deleteItem(item);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
