import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/constants/api_control/global_api.dart' show api;
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/features/bookings/screens/booking_details_screen.dart';
import 'package:renizo/features/cabinet/data/cabinet_requests_api.dart';
import 'package:renizo/features/cabinet/logic/my_cabinet_requests_provider.dart';
import 'package:renizo/features/cabinet/models/cabinet_request_detail_model.dart';

/// Full URL for photo paths like `/uploads/...` from GET /cabinet-requests/:id.
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

/// `GET /cabinet-requests/:id` with accept quote + cancel per CABINET_REQUEST_POSTMAN_GUIDE.
class CabinetDetailScreen extends ConsumerStatefulWidget {
  const CabinetDetailScreen({
    super.key,
    required this.requestId,
  });

  final String requestId;

  @override
  ConsumerState<CabinetDetailScreen> createState() =>
      _CabinetDetailScreenState();
}

class _CabinetDetailScreenState extends ConsumerState<CabinetDetailScreen> {
  static const Color _bgBlue = Color(0xFF2384F4);
  static const Color _navy = Color(0xFF003E93);

  CabinetRequestDetail? _detail;
  Object? _error;
  bool _loading = true;
  bool _actionBusy = false;

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
      final d = await fetchCabinetRequestDetail(widget.requestId);
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

  Future<void> _acceptQuote() async {
    final detail = _detail;
    if (detail == null || !detail.canAcceptQuote) return;

    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !mounted) return;

    final local = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final iso = local.toUtc().toIso8601String();

    setState(() => _actionBusy = true);
    try {
      await acceptCabinetQuote(
        requestId: widget.requestId,
        scheduledAtIsoUtc: iso,
      );
      if (!mounted) return;
      ref.invalidate(myCabinetRequestsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quote accepted — booking created')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _cancelRequest() async {
    final detail = _detail;
    if (detail == null || !detail.canCancel) return;

    final controller = TextEditingController();
    try {
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.45),
        builder: (ctx) {
          final accentBlue = const Color(0xFF408AF1);
          final fieldFill = const Color(0xFFF3F4F6);
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
            child: Container(
              constraints: BoxConstraints(maxWidth: 400.w),
              decoration: BoxDecoration(
                color: AllColor.white,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(22.w, 22.h, 22.w, 18.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Cancel request',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: AllColor.foreground,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Optional — share a short reason. You can leave this blank.',
                      style: TextStyle(
                        fontSize: 13.sp,
                        height: 1.35,
                        color: AllColor.mutedForeground,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    TextField(
                      controller: controller,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      style: TextStyle(
                        fontSize: 15.sp,
                        height: 1.4,
                        color: AllColor.foreground,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Reason (optional)',
                        hintStyle: TextStyle(
                          color: AllColor.mutedForeground,
                          fontSize: 15.sp,
                        ),
                        filled: true,
                        fillColor: fieldFill,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 18.w,
                          vertical: 16.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide(
                            color: Colors.black.withOpacity(0.04),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.r),
                          borderSide: BorderSide(color: accentBlue, width: 1.5),
                        ),
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          style: TextButton.styleFrom(
                            foregroundColor: accentBlue,
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 10.h,
                            ),
                          ),
                          child: Text(
                            'Back',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(
                            backgroundColor: _navy,
                            foregroundColor: AllColor.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: 22.w,
                              vertical: 14.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999.r),
                            ),
                          ),
                          child: Text(
                            'Cancel request',
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
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
        },
      );
      if (ok != true || !mounted) return;

      setState(() => _actionBusy = true);
      try {
        await cancelCabinetRequest(
          requestId: widget.requestId,
          reason: controller.text.trim().isEmpty
              ? 'Cancelled by customer'
              : controller.text.trim(),
        );
        if (!mounted) return;
        ref.invalidate(myCabinetRequestsProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      } finally {
        if (mounted) setState(() => _actionBusy = false);
      }
    } finally {
      controller.dispose();
    }
  }

  void _openBooking() {
    final id = _detail?.bookingId;
    if (id == null || id.isEmpty) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => BookingDetailsScreen(
          bookingId: id,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlue,
      appBar: AppBar(
        backgroundColor: _bgBlue,
        foregroundColor: AllColor.white,
        elevation: 0,
        title: const Text('Cabinet request'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AllColor.white))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error.toString().replaceFirst('Exception: ', ''),
                          style: TextStyle(color: AllColor.white, fontSize: 14.sp),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 16.h),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _detail!;
    final busy = _actionBusy;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _whiteCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                if (d.timeline != null && d.timeline!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    d.timeline!,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: AllColor.mutedForeground,
                    ),
                  ),
                ],
                if (d.style != null && d.style!.isNotEmpty) ...[
                  SizedBox(height: 8.h),
                  Text(
                    d.style!,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AllColor.mutedForeground,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (d.customerPhone != null && d.customerPhone!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _label('Phone'),
            _whiteCard(
              child: Text(
                d.customerPhone!,
                style: TextStyle(fontSize: 15.sp, color: AllColor.foreground),
              ),
            ),
          ],
          if (d.notes != null && d.notes!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _label('Notes'),
            _whiteCard(
              child: Text(
                d.notes!,
                style: TextStyle(
                  fontSize: 15.sp,
                  height: 1.45,
                  color: AllColor.foreground,
                ),
              ),
            ),
          ],
          if (_hasAddress(d)) ...[
            SizedBox(height: 12.h),
            _label('Visit address'),
            _whiteCard(
              child: Text(
                [
                  d.visitAddressLine1,
                  d.visitAddressLine2,
                  d.city,
                  d.postalCode,
                ]
                    .whereType<String>()
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .join('\n'),
                style: TextStyle(fontSize: 15.sp, color: AllColor.foreground),
              ),
            ),
          ],
          if (d.quote != null) ...[
            SizedBox(height: 12.h),
            _label('Quote'),
            _whiteCard(
              child: Builder(
                builder: (context) {
                  final q = d.quote!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${q.currency} ${q.amountMajor.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                        ),
                      ),
                      if (q.scopeNote != null && q.scopeNote!.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          q.scopeNote!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AllColor.foreground,
                            height: 1.4,
                          ),
                        ),
                      ],
                      if (q.visitNotes != null && q.visitNotes!.isNotEmpty) ...[
                        SizedBox(height: 8.h),
                        Text(
                          q.visitNotes!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AllColor.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
          if (d.photos.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _label('Photos'),
            SizedBox(
              height: 108.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: d.photos.length,
                separatorBuilder: (_, __) => SizedBox(width: 10.w),
                itemBuilder: (context, i) {
                  final resolved = _resolveCabinetPhotoUrl(d.photos[i]);
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: SizedBox(
                      width: 100.w,
                      height: 100.h,
                      child: CachedNetworkImage(
                        imageUrl: resolved,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AllColor.white.withOpacity(0.2),
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 24.w,
                            height: 24.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AllColor.white,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => ColoredBox(
                          color: AllColor.white.withOpacity(0.15),
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: AllColor.white.withOpacity(0.8),
                            size: 32.sp,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          SizedBox(height: 20.h),
          if (d.canAcceptQuote)
            _primaryButton(
              label: 'Accept quote',
              onPressed: busy ? null : _acceptQuote,
              busy: busy,
            ),
          if (d.canCancel) ...[
            SizedBox(height: 12.h),
            OutlinedButton(
              onPressed: busy ? null : _cancelRequest,
              style: OutlinedButton.styleFrom(
                foregroundColor: AllColor.white,
                side: const BorderSide(color: AllColor.white),
                padding: EdgeInsets.symmetric(vertical: 14.h),
              ),
              child: Text(
                'Cancel request',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ],
          if (d.status == 'converted' &&
              d.bookingId != null &&
              d.bookingId!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            _primaryButton(
              label: 'View booking',
              onPressed: busy ? null : _openBooking,
              busy: false,
            ),
          ],
        ],
      ),
    );
  }

  bool _hasAddress(CabinetRequestDetail d) {
    return [
      d.visitAddressLine1,
      d.city,
      d.postalCode,
    ].any((e) => (e ?? '').trim().isNotEmpty);
  }

  Widget _label(String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        label,
        style: TextStyle(
          color: AllColor.white,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AllColor.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool busy,
  }) {
    return Material(
      color: _navy,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          alignment: Alignment.center,
          child: busy
              ? SizedBox(
                  height: 22.h,
                  width: 22.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AllColor.white,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AllColor.white,
                  ),
                ),
        ),
      ),
    );
  }
}
