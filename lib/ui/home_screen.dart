// lib/ui/home_screen.dart
import 'package:flutter/material.dart';
import 'package:qr_generator_and_scanner/data/scan_history_store.dart';
import 'package:qr_generator_and_scanner/ui/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = ScanHistoryProvider.of(context);
    final entries = store.entries;
    final generatedCount =
        entries.where((e) => e.type == ScanHistoryEntryType.generated).length;
    final scannedCount =
        entries.where((e) => e.type == ScanHistoryEntryType.scanned).length;
    final favoritesCount = store.favorites.length;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome,',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Rakhan ',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          Text(
                            'Ataya',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              fontFamily: 'Manrope',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppBorderRadius.full,
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'RA',
                          style: AppTextStyles.labelLarge(context).copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppBorderRadius.full,
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () =>
                              Navigator.pushNamed(context, '/settings'),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Stats Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius: AppBorderRadius.xlarge,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(
                      value: generatedCount.toString(),
                      label: 'Generated',
                      icon: Icons.qr_code_2_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    _StatItem(
                      value: scannedCount.toString(),
                      label: 'Scanned',
                      icon: Icons.qr_code_scanner_rounded,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.2),
                    ),
                    _StatItem(
                      value: favoritesCount.toString(),
                      label: 'Favorites',
                      icon: Icons.star_rounded,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/scan'),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Scan'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/create'),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Create'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/history'),
                    child: const Text('View all'),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Menu Grid
              Expanded(
                child: ListView(
                  children: [
                    Row(
                      children: const [
                        Expanded(
                          child: _MenuCard(
                            icon: Icons.history_rounded,
                            title: 'History',
                            subtitle: 'Scans & creates',
                            color: AppColors.primary,
                            route: '/history',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _MenuCard(
                            icon: Icons.star_rounded,
                            title: 'Favorites',
                            subtitle: 'Saved items',
                            color: AppColors.warning,
                            route: '/history',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Expanded(
                          child: _MenuCard(
                            icon: Icons.qr_code_scanner_rounded,
                            title: 'Scan QR',
                            subtitle: 'Camera scanner',
                            color: AppColors.info,
                            route: '/scan',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _MenuCard(
                            icon: Icons.add_circle_outline_rounded,
                            title: 'Create QR',
                            subtitle: 'Make new code',
                            color: AppColors.primaryDark,
                            route: '/create',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Recent',
                      style: AppTextStyles.titleMedium(context).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (entries.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: AppBorderRadius.large,
                          border: Border.all(color: AppColors.outlineVariant),
                        ),
                        child: Text(
                          'No recent activity yet. Start scanning or creating a QR code.',
                          style: AppTextStyles.bodyMedium(context).copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...entries.take(3).map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _RecentTile(entry: e),
                            ),
                          ),
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

class _RecentTile extends StatelessWidget {
  final ScanHistoryEntry entry;

  const _RecentTile({required this.entry});

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
    final created = entry.createdAt.toLocal().toString().split('.').first;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/history'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.large,
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [AppShadows.small],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: AppBorderRadius.large,
              ),
              child: Icon(
                _typeIcon,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _typeLabel,
                        style: AppTextStyles.labelMedium(context).copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          created,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.labelMedium(context).copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route.isNotEmpty
          ? () => Navigator.pushNamed(context, route)
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppBorderRadius.large,
          border: Border.all(color: AppColors.outlineVariant),
          boxShadow: [AppShadows.small],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: AppBorderRadius.large,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}