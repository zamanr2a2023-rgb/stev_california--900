import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/constants/api_control/global_api.dart' show api;
import 'package:renizo/features/cabinet/data/cabinet_static_addons.dart';
import 'package:renizo/features/cabinet/data/provider_cabinet_api.dart';
import 'package:renizo/features/cabinet/models/cabinet_request_detail_model.dart';

String _resolveCabinetPhotoUrl(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return t;
  final parsed = Uri.tryParse(t);
  if (parsed != null &&
      parsed.hasScheme &&
      (parsed.scheme == 'http' || parsed.scheme == 'https')) {
    return t;
  }
  final origin = Uri.parse(api).origin;
  if (t.startsWith('/')) return '$origin$t';
  return '$origin/$t';
}

/// Parses dollar input to cents (e.g. 8500 or 8500.50 -> 850050).
int parseDollarsToCents(String input) {
  final cleaned = input.replaceAll(RegExp(r'[^\d.]'), '');
  if (cleaned.isEmpty) throw FormatException('Enter an amount');
  final v = double.tryParse(cleaned);
  if (v == null) throw FormatException('Invalid amount');
  return (v * 100).round();
}

String _addonLabel(String key) {
  for (final a in kCabinetStaticAddons) {
    if (a.value == key) return a.label;
  }
  return key.replaceAll('_', ' ');
}

/// Provider workflow — `GET /cabinet-requests/:id`, PATCH review-status + quote.
class ProviderCabinetDetailScreen extends StatefulWidget {
  const ProviderCabinetDetailScreen({
    super.key,
    required this.requestId,
    required this.onBack,
    required this.onOpenBooking,
  });

  final String requestId;
  final VoidCallback onBack;
  final void Function(String bookingId) onOpenBooking;

  @override
  State<ProviderCabinetDetailScreen> createState() =>
      _ProviderCabinetDetailScreenState();
}

class _ProviderCabinetDetailScreenState extends State<ProviderCabinetDetailScreen> {
  static const Color _bg = Color(0xFF2384F4);
  static const Color _navy = Color(0xFF003E93);
  static const Color _sheetBg = Color(0xFFF1F5F9);
  static const Color _cardFg = Color(0xFF0F172A);
  static const Color _muted = Color(0xFF64748B);

  CabinetRequestDetail? _detail;
  Object? _error;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await fetchProviderCabinetDetail(widget.requestId);
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  Future<void> _patchStatus(String status, {String? visitNotes, String? reason}) async {
    setState(() => _busy = true);
    try {
      await patchCabinetReviewStatus(
        requestId: widget.requestId,
        status: status,
        visitNotes: visitNotes,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated: $status')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _navyDialogInputDecoration(String hint, {int maxLines = 1}) {
    final r = BorderRadius.circular(12.r);
    final dim = Colors.white.withValues(alpha: 0.28);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.45),
        fontSize: 14.sp,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.1),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: maxLines > 1 ? 12.h : 14.h),
      border: OutlineInputBorder(borderRadius: r, borderSide: BorderSide(color: dim)),
      enabledBorder: OutlineInputBorder(borderRadius: r, borderSide: BorderSide(color: dim)),
      focusedBorder: OutlineInputBorder(
        borderRadius: r,
        borderSide: const BorderSide(color: Colors.white, width: 1.25),
      ),
    );
  }

  TextStyle get _navyDialogFieldStyle =>
      TextStyle(fontSize: 15.sp, color: Colors.white, fontWeight: FontWeight.w400);

  Future<bool?> _showNavyDialog({
    required String title,
    String? subtitle,
    required Widget content,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Continue',
    bool destructiveConfirm = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => Dialog(
        backgroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
        ),
        insetPadding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 20.h),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 22.h, 20.w, 18.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                SizedBox(height: 8.h),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white.withValues(alpha: 0.76),
                    height: 1.4,
                  ),
                ),
              ],
              SizedBox(height: 18.h),
              content,
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.88),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text(
                        cancelLabel,
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            destructiveConfirm ? const Color(0xFFDC2626) : Colors.white,
                        foregroundColor: destructiveConfirm ? Colors.white : _navy,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                      ),
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

  Future<void> _showQuoteDialog() async {
    final amountCtrl = TextEditingController();
    final scopeCtrl = TextEditingController();
    final visitCtrl = TextEditingController();
    final ok = await _showNavyDialog(
      title: 'Send quote',
      subtitle: 'Amount in Canadian dollars. Scope and visit notes are optional.',
      confirmLabel: 'Send',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Amount (CAD)',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            SizedBox(height: 6.h),
            TextField(
              controller: amountCtrl,
              style: _navyDialogFieldStyle,
              cursorColor: Colors.white,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _navyDialogInputDecoration('e.g. 8500'),
            ),
            SizedBox(height: 14.h),
            Text(
              'Scope note',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            SizedBox(height: 6.h),
            TextField(
              controller: scopeCtrl,
              style: _navyDialogFieldStyle,
              cursorColor: Colors.white,
              maxLines: 2,
              decoration: _navyDialogInputDecoration("What's included", maxLines: 2),
            ),
            SizedBox(height: 14.h),
            Text(
              'Visit notes (optional)',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            SizedBox(height: 6.h),
            TextField(
              controller: visitCtrl,
              style: _navyDialogFieldStyle,
              cursorColor: Colors.white,
              maxLines: 2,
              decoration: _navyDialogInputDecoration('Optional', maxLines: 2),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    int cents;
    try {
      cents = parseDollarsToCents(amountCtrl.text);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await patchCabinetQuote(
        requestId: widget.requestId,
        amountCents: cents,
        currency: 'CAD',
        scopeNote: scopeCtrl.text.trim().isEmpty ? null : scopeCtrl.text.trim(),
        visitNotes: visitCtrl.text.trim().isEmpty ? null : visitCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote sent')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmReject() async {
    final c = TextEditingController();
    final ok = await _showNavyDialog(
      title: 'Reject request',
      subtitle: 'The customer will see your reason.',
      cancelLabel: 'Cancel',
      confirmLabel: 'Reject',
      destructiveConfirm: true,
      content: TextField(
        controller: c,
        style: _navyDialogFieldStyle,
        cursorColor: Colors.white,
        maxLines: 3,
        decoration: _navyDialogInputDecoration('Reason', maxLines: 3),
      ),
    );
    if (ok != true || !mounted) return;
    await _patchStatus('rejected', reason: c.text.trim().isEmpty ? 'Rejected' : c.text.trim());
  }

  Future<void> _siteVisitNotes() async {
    final c = TextEditingController();
    final ok = await _showNavyDialog(
      title: 'Site visit pending',
      subtitle: 'Optional notes for the customer or your records.',
      confirmLabel: 'Continue',
      content: TextField(
        controller: c,
        style: _navyDialogFieldStyle,
        cursorColor: Colors.white,
        maxLines: 4,
        decoration: _navyDialogInputDecoration('Visit notes (optional)', maxLines: 4),
      ),
    );
    if (ok != true || !mounted) return;
    await _patchStatus(
      'site_visit_pending',
      visitNotes: c.text.trim().isEmpty ? null : c.text.trim(),
    );
  }

  bool get _canAct {
    final s = _detail?.status.toLowerCase() ?? '';
    return !['rejected', 'cancelled', 'converted'].contains(s);
  }

  String _formatVisitAddress(CabinetRequestDetail d) {
    final parts = <String>[];
    void add(String? x) {
      final t = x?.trim() ?? '';
      if (t.isNotEmpty) parts.add(t);
    }

    add(d.visitAddressLine1);
    add(d.visitAddressLine2);
    add(d.city);
    add(d.postalCode);
    add(d.townName);
    return parts.isEmpty ? '—' : parts.join(', ');
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
              padding: EdgeInsets.fromLTRB(8.w, 4.h, 16.w, 12.h),
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
                  Expanded(
                    child: Text(
                      'Cabinet request',
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (_busy)
                    SizedBox(
                      width: 22.w,
                      height: 22.w,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _sheetBg,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(22.r),
                    topRight: Radius.circular(22.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: _navy));
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
                style: TextStyle(color: _cardFg, fontSize: 14.sp),
              ),
              SizedBox(height: 16.h),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final d = _detail!;
    return RefreshIndicator(
      color: _navy,
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
        children: [
          _statusBadge(d.status),
          SizedBox(height: 14.h),
          _cardSection(
            'Customer',
            [
              if (d.customerName != null && d.customerName!.isNotEmpty)
                _bodyLine(d.customerName!),
              if (d.customerPhone != null && d.customerPhone!.isNotEmpty)
                _bodyLine('Phone: ${d.customerPhone}'),
            ],
          ),
          if (d.serviceName != null && d.serviceName!.isNotEmpty)
            _cardSection('Service', [_bodyLine(d.serviceName!)]),
          _cardSection('Visit address', [_bodyLine(_formatVisitAddress(d))]),
          if (d.timeline != null && d.timeline!.isNotEmpty)
            _cardSection('Timeline', [_bodyLine(d.timeline!)]),
          if (d.notes != null && d.notes!.isNotEmpty)
            _cardSection(
              'Note',
              [_bodyLine(d.notes!)],
              highlight: true,
            ),
          if (d.style != null && d.style!.isNotEmpty)
            _cardSection('Style', [_bodyLine(d.style!)]),
          if (d.selectedAddons.isNotEmpty)
            _cardSection(
              'Add-ons',
              d.selectedAddons.map((a) => _bodyLine(_addonLabel(a))).toList(),
            ),
          if (d.visitNotes != null && d.visitNotes!.isNotEmpty)
            _cardSection('Visit notes', [_bodyLine(d.visitNotes!)]),
          if (d.quote != null)
            _cardSection(
              'Quote',
              [
                _bodyLine(
                  '\$${(d.quote!.amountCents / 100).toStringAsFixed(2)} ${d.quote!.currency}',
                  bold: true,
                ),
                if (d.quote!.scopeNote != null &&
                    d.quote!.scopeNote!.isNotEmpty)
                  _bodyLine(d.quote!.scopeNote!),
              ],
            ),
          if (d.photos.isNotEmpty)
            _cardSection(
              'Photos',
              [
                SizedBox(
                  height: 104.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: d.photos.length,
                    separatorBuilder: (_, __) => SizedBox(width: 10.w),
                    itemBuilder: (context, i) {
                      final url = _resolveCabinetPhotoUrl(d.photos[i]);
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12.r),
                        child: SizedBox(
                          width: 100.w,
                          height: 100.h,
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: const Color(0xFFE2E8F0),
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 24.w,
                                height: 24.w,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _navy,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => ColoredBox(
                              color: const Color(0xFFE2E8F0),
                              child: Icon(Icons.broken_image_outlined, size: 28.sp),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          if (d.bookingId != null && d.bookingId!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 4.h, bottom: 8.h),
              child: FilledButton.icon(
                onPressed: () => widget.onOpenBooking(d.bookingId!),
                style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open booking'),
              ),
            ),
          if (_canAct) ...[
            Padding(
              padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
              child: Text(
                'Next steps',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: _muted,
                ),
              ),
            ),
            ..._actionButtons(d),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final s = status.toLowerCase();
    late Color bg;
    late Color fg;
    late Color bd;
    if (s.contains('cancel')) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      bd = const Color(0xFFFECACA);
    } else if (s.contains('convert')) {
      bg = const Color(0xFFD1FAE5);
      fg = const Color(0xFF065F46);
      bd = const Color(0xFFA7F3D0);
    } else if (s.contains('quote')) {
      bg = const Color(0xFFE0E7FF);
      fg = const Color(0xFF3730A3);
      bd = const Color(0xFFC7D2FE);
    } else if (s.contains('reject')) {
      bg = const Color(0xFFFEE2E2);
      fg = const Color(0xFF991B1B);
      bd = const Color(0xFFFECACA);
    } else if (s.contains('review') || s.contains('visit')) {
      bg = const Color(0xFFFFEDD5);
      fg = const Color(0xFFC2410C);
      bd = const Color(0xFFFED7AA);
    } else {
      bg = const Color(0xFFDBEAFE);
      fg = const Color(0xFF1E40AF);
      bd = const Color(0xFFBFDBFE);
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: bd),
        ),
        child: Text(
          status.replaceAll('_', ' ').toUpperCase(),
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            color: fg,
            letterSpacing: 0.45,
          ),
        ),
      ),
    );
  }

  Widget _cardSection(
    String title,
    List<Widget> children, {
    bool highlight = false,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: _muted,
              ),
            ),
            SizedBox(height: 8.h),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _bodyLine(String text, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: _cardFg,
          height: 1.45,
        ),
      ),
    );
  }

  List<Widget> _actionButtons(CabinetRequestDetail d) {
    final s = d.status.toLowerCase();
    final out = <Widget>[];

    Widget pad(Widget w) => Padding(
          padding: EdgeInsets.only(bottom: 10.h),
          child: w,
        );

    void addPrimary(String label, VoidCallback onTap) {
      out.add(
        pad(
          FilledButton(
            onPressed: _busy ? null : onTap,
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(label, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    void addDestructive(String label, VoidCallback onTap) {
      out.add(
        pad(
          OutlinedButton(
            onPressed: _busy ? null : onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFB91C1C),
              side: const BorderSide(color: Color(0xFFF87171)),
              minimumSize: Size(double.infinity, 50.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Text(label, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    if (s == 'submitted') {
      addPrimary('Start review', () => _patchStatus('under_review'));
    }
    if (s == 'under_review') {
      addPrimary('Mark site visit pending', _siteVisitNotes);
      addDestructive('Reject request', _confirmReject);
    }
    if (s == 'site_visit_pending') {
      addPrimary('Send quote', _showQuoteDialog);
      addDestructive('Reject request', _confirmReject);
    }
    if (s == 'quoted') {
      out.add(
        pad(
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.hourglass_empty, size: 20.sp, color: _muted),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Waiting for the customer to accept your quote.',
                    style: TextStyle(fontSize: 14.sp, color: _cardFg, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return out;
  }
}
