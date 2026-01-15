import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'package:qr_generator_and_scanner/data/scan_history_store.dart';
import 'package:qr_generator_and_scanner/ui/theme/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ScanHistoryEntry> _filter(List<ScanHistoryEntry> entries) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return entries;

    return entries.where((e) => e.value.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final store = ScanHistoryProvider.of(context);
    final entries = _filter(store.entries);
    final favorites = _filter(store.favorites);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            onPressed: store.entries.isEmpty
                ? null
                : () async {
                    await store.clear();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('History cleared')),
                    );
                  },
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Search your scans & generated codes...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: store.entries.isEmpty
                    ? _EmptyState(
                        onScan: () => Navigator.pushNamed(context, '/scan'),
                        onCreate: () => Navigator.pushNamed(context, '/create'),
                      )
                    : ListView(
                        children: [
                          if (favorites.isNotEmpty) ...[
                            _SectionHeader(title: 'Favorites'),
                            const SizedBox(height: 8),
                            ...favorites.map(
                              (e) => _HistoryTile(
                                entry: e,
                                onToggleFavorite: () => store.toggleFavorite(e.id),
                                onCopy: () async {
                                  await Clipboard.setData(
                                    ClipboardData(text: e.value),
                                  );
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Copied')),
                                  );
                                },
                                onShare: () => SharePlus.instance.share(
                                  ShareParams(text: e.value),
                                ),
                                onDelete: () => store.remove(e.id),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          _SectionHeader(title: 'All'),
                          const SizedBox(height: 8),
                          ...entries.map(
                            (e) => _HistoryTile(
                              entry: e,
                              onToggleFavorite: () => store.toggleFavorite(e.id),
                              onCopy: () async {
                                await Clipboard.setData(
                                  ClipboardData(text: e.value),
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied')),
                                );
                              },
                              onShare: () => SharePlus.instance.share(
                                ShareParams(text: e.value),
                              ),
                              onDelete: () => store.remove(e.id),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: AppTextStyles.titleMedium(context).copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ScanHistoryEntry entry;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.entry,
    required this.onToggleFavorite,
    required this.onCopy,
    required this.onShare,
    required this.onDelete,
  });

  IconData get _typeIcon {
    switch (entry.type) {
      case ScanHistoryEntryType.scanned:
        return Icons.qr_code_scanner_rounded;
      case ScanHistoryEntryType.generated:
        return Icons.qr_code_2_rounded;
    }
  }

  String get _typeLabel {
    switch (entry.type) {
      case ScanHistoryEntryType.scanned:
        return 'Scanned';
      case ScanHistoryEntryType.generated:
        return 'Generated';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: AppBorderRadius.medium,
                  ),
                  child: Icon(
                    _typeIcon,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabel,
                        style: AppTextStyles.labelMedium(context).copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMedium(context).copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    entry.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: entry.isFavorite
                        ? AppColors.warning
                        : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: AppColors.error,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onScan;
  final VoidCallback onCreate;

  const _EmptyState({
    required this.onScan,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppBorderRadius.xlarge,
              ),
              child: const Icon(
                Icons.history_rounded,
                color: Colors.white,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No history yet',
              style: AppTextStyles.titleLarge(context).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your scanned and generated QR content will show up here.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium(context).copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCreate,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text('Create'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Scan'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
