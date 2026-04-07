import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/features/cabinet/logic/my_cabinet_requests_provider.dart';
import 'package:renizo/features/cabinet/models/cabinet_request_model.dart';
import 'package:renizo/features/cabinet/screens/cabinet_detail_screen.dart';

/// "My Cabinet" — `GET /cabinet-requests/me`; cards match home design (image 2).
class MyCabinetSection extends ConsumerWidget {
  const MyCabinetSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myCabinetRequestsProvider);

    return async.when(
      loading: () => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Center(
          child: SizedBox(
            width: 28.w,
            height: 28.w,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: AllColor.white,
            ),
          ),
        ),
      ),
      error: (e, _) => Padding(
        padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
        child: Text(
          'Could not load My Cabinet',
          style: TextStyle(
            fontSize: 13.sp,
            color: AllColor.white.withOpacity(0.85),
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                SizedBox(height: 8.h),
                Text(
                  'No cabinet requests yet. Tap Requests Cabinet to create one.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AllColor.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              SizedBox(height: 12.h),
              ...items.map(
                (r) => _CabinetRow(
                  item: r,
                  onTap: () {
                    Navigator.of(context)
                        .push<void>(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            CabinetDetailScreen(requestId: r.id),
                      ),
                    )
                        .then((_) {
                      ref.invalidate(myCabinetRequestsProvider);
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _header() {
    return Row(
      children: [
        Icon(Icons.kitchen_outlined, size: 22.sp, color: AllColor.white),
        SizedBox(width: 8.w),
        Text(
          'My Cabinet',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AllColor.white,
          ),
        ),
      ],
    );
  }
}

class _CabinetRow extends StatelessWidget {
  const _CabinetRow({
    required this.item,
    required this.onTap,
  });

  final CabinetRequestListItem item;
  final VoidCallback onTap;

  static const Color _navy = Color(0xFF003E93);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: AllColor.white,
        borderRadius: BorderRadius.circular(16.r),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.status.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: _navy,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (item.timeline != null &&
                          item.timeline!.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          item.timeline!,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AllColor.mutedForeground,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (item.style != null && item.style!.isNotEmpty) ...[
                        SizedBox(height: 6.h),
                        Text(
                          item.style!,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AllColor.mutedForeground,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Icon(
                    Icons.chevron_right,
                    color: AllColor.mutedForeground,
                    size: 22.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
