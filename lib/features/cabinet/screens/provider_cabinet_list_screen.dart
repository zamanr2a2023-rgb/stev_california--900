import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/features/cabinet/data/provider_cabinet_api.dart';
import 'package:renizo/features/cabinet/models/provider_cabinet_list_item.dart';

/// Assigned cabinet queue — `GET /cabinet-requests`.
class ProviderCabinetListScreen extends StatefulWidget {
  const ProviderCabinetListScreen({
    super.key,
    required this.onBack,
    required this.onSelectRequest,
  });

  final VoidCallback onBack;
  final void Function(String requestId) onSelectRequest;

  @override
  State<ProviderCabinetListScreen> createState() =>
      _ProviderCabinetListScreenState();
}

class _ProviderCabinetListScreenState extends State<ProviderCabinetListScreen> {
  static const Color _bg = Color(0xFF2384F4);
  static const Color _navy = Color(0xFF003E93);

  final List<ProviderCabinetListItem> _items = [];
  bool _loading = true;
  Object? _error;
  String? _filterStatus;
  int _nextPage = 1;
  bool _hasMore = false;
  bool _loadingMore = false;

  /// No `submitted` / "New" — providers don't receive that queue from the API.
  static const List<String> _filterKeys = [
    '',
    'under_review',
    'site_visit_pending',
    'quoted',
    'rejected',
    'cancelled',
    'converted',
  ];

  @override
  void initState() {
    super.initState();
    _load(refresh: true);
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _nextPage = 1;
        if (_filterStatus == 'submitted') _filterStatus = null;
      });
    }
    try {
      final page = refresh ? 1 : _nextPage;
      final r = await fetchProviderCabinetRequests(
        status: _filterStatus,
        page: page,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        if (refresh) {
          _items
            ..clear()
            ..addAll(r.items);
        } else {
          _items.addAll(r.items);
        }
        _hasMore = r.hasMore;
        if (r.items.isNotEmpty) {
          _nextPage = page + 1;
        }
        _loading = false;
        _error = null;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    try {
      final r = await fetchProviderCabinetRequests(
        status: _filterStatus,
        page: _nextPage,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(r.items);
        _hasMore = r.hasMore;
        if (r.items.isNotEmpty) _nextPage++;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Short labels so chips stay readable (ChoiceChip + M3 theme caused blank pills on some devices).
  String _filterLabelShort(String key) {
    switch (key) {
      case '':
        return 'All';
      case 'under_review':
        return 'Review';
      case 'site_visit_pending':
        return 'Visit';
      case 'quoted':
        return 'Quoted';
      case 'rejected':
        return 'Declined';
      case 'cancelled':
        return 'Cancelled';
      case 'converted':
        return 'Done';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 4.h, 16.w, 8.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22.sp),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.12),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    'Cabinet requests',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 46.h,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                scrollDirection: Axis.horizontal,
                itemCount: _filterKeys.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, i) {
                  final key = _filterKeys[i];
                  final selected = (key.isEmpty && _filterStatus == null) ||
                      (key.isNotEmpty && _filterStatus == key);
                  final label = _filterLabelShort(key);
                  return Center(
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(999.r),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _filterStatus = key.isEmpty ? null : key;
                          });
                          _load(refresh: true);
                        },
                        borderRadius: BorderRadius.circular(999.r),
                        splashColor: Colors.white.withValues(alpha: 0.18),
                        highlightColor: Colors.white.withValues(alpha: 0.08),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: selected
                                ? _navy
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999.r),
                            border: Border.all(
                              color: selected
                                  ? _navy
                                  : Colors.white.withValues(alpha: 0.45),
                              width: 1,
                            ),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 9.h,
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14.sp),
              ),
              SizedBox(height: 16.h),
              TextButton(
                onPressed: () => _load(refresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Container(
        width: double.infinity,
        color: _bg,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Text(
              'No cabinet requests in this filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 15.sp,
              ),
            ),
          ),
        ),
      );
    }
    return Container(
      width: double.infinity,
      color: _bg,
      child: RefreshIndicator(
      color: Colors.white,
      onRefresh: () => _load(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.metrics.pixels > n.metrics.maxScrollExtent - 200) {
            _loadMore();
          }
          return false;
        },
        child: ListView.builder(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
          itemCount: _items.length + (_loadingMore ? 1 : 0),
          itemBuilder: (context, i) {
            if (i >= _items.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            }
            final item = _items[i];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _CabinetRowCard(
                item: item,
                onTap: () => widget.onSelectRequest(item.id),
              ),
            );
          },
        ),
      ),
    ),
    );
  }
}

String _formatCabinetDate(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  final dt = DateTime.tryParse(raw);
  if (dt == null) return raw;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

class _CabinetRowCard extends StatelessWidget {
  const _CabinetRowCard(
      {required this.item, required this.onTap});

  final ProviderCabinetListItem item;
  final VoidCallback onTap;

  static ({Color bg, Color fg, Color border}) _colors(String status) {
    final s = status.toLowerCase();
    if (s.contains('cancel')) {
      return (
        bg: const Color(0xFFFEE2E2),
        fg: const Color(0xFF991B1B),
        border: const Color(0xFFFECACA),
      );
    }
    if (s.contains('convert')) {
      return (
        bg: const Color(0xFFD1FAE5),
        fg: const Color(0xFF065F46),
        border: const Color(0xFFA7F3D0),
      );
    }
    if (s.contains('quote')) {
      return (
        bg: const Color(0xFFE0E7FF),
        fg: const Color(0xFF3730A3),
        border: const Color(0xFFC7D2FE),
      );
    }
    if (s.contains('reject')) {
      return (
        bg: const Color(0xFFFEE2E2),
        fg: const Color(0xFF991B1B),
        border: const Color(0xFFFECACA),
      );
    }
    if (s.contains('review') ||
        s == 'submitted' ||
        s.contains('visit') ||
        (s.contains('pending') && !s.contains('payment'))) {
      return (
        bg: const Color(0xFFEFF6FF),
        fg: const Color(0xFF1D4ED8),
        border: const Color(0xFFBFDBFE),
      );
    }
    return (
      bg: const Color(0xFFF1F5F9),
      fg: const Color(0xFF475569),
      border: const Color(0xFFE2E8F0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _colors(item.status);
    final dateLabel = _formatCabinetDate(item.createdAt);

    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: c.bg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: c.border.withValues(alpha: 0.65), width: 1),
                    ),
                    child: Text(
                      item.status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: const Color(0xFF94A3B8),
                    size: 22.sp,
                  ),
                ],
              ),
              if (item.customerName != null && item.customerName!.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Text(
                  item.customerName!,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
              SizedBox(height: 6.h),
              Text(
                [
                  if (item.serviceName != null && item.serviceName!.isNotEmpty)
                    item.serviceName,
                  if (item.townName != null && item.townName!.isNotEmpty)
                    item.townName,
                ].whereType<String>().join(' · '),
                style: TextStyle(fontSize: 13.sp, color: const Color(0xFF475569), height: 1.3),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 12.w,
                runSpacing: 6.h,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_outlined, size: 15.sp, color: const Color(0xFF64748B)),
                      SizedBox(width: 4.w),
                      Text(
                        '${item.photoCount} photos',
                        style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  if (dateLabel.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 15.sp, color: const Color(0xFF64748B)),
                        SizedBox(width: 4.w),
                        Text(
                          dateLabel,
                          style: TextStyle(fontSize: 12.sp, color: const Color(0xFF64748B)),
                        ),
                      ],
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
