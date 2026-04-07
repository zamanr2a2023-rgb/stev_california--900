import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/features/home/models/customer_home_models.dart';

/// Top Rated Providers section – renders providers from API data.
/// If [providers] is empty the widget hides itself (SizedBox.shrink).
class FeaturedProvidersWidget extends StatelessWidget {
  const FeaturedProvidersWidget({
    super.key,
    required this.providers,
    required this.onSelectProvider,
    this.lightHeader = false,
    /// When set, only the first [maxCount] providers are shown (e.g. top 4).
    this.maxCount,
  });

  final List<ProviderCardModel> providers;
  final void Function(ProviderCardModel provider) onSelectProvider;
  final bool lightHeader;
  final int? maxCount;

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) return const SizedBox.shrink();

    final visible = maxCount != null && providers.length > maxCount!
        ? providers.sublist(0, maxCount!)
        : providers;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 22.sp,
                color: lightHeader ? AllColor.white : AllColor.foreground,
              ),
              SizedBox(width: 8.w),
              Text(
                'Top Rated Providers',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: lightHeader ? AllColor.white : AllColor.foreground,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'Highly recommended in your area',
            style: TextStyle(
              fontSize: 14.sp,
              color: lightHeader
                  ? AllColor.white.withOpacity(0.9)
                  : AllColor.mutedForeground,
            ),
          ),
          SizedBox(height: 16.h),
          ...List.generate(visible.length, (index) {
            final provider = visible[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _ProviderCard(
                provider: provider,
                isFirst: index == 0,
                onTap: () => onSelectProvider(provider),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ─── Provider Card ───────────────────────────────────────────────────────────

class _ProviderCard extends StatefulWidget {
  const _ProviderCard({
    required this.provider,
    required this.isFirst,
    required this.onTap,
  });

  final ProviderCardModel provider;
  final bool isFirst;
  final VoidCallback onTap;

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _imageError = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.provider;
    final initial = p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';

    return Material(
      color: AllColor.white,
      borderRadius: BorderRadius.circular(16.r),
      elevation: 2,
      shadowColor: AllColor.primary.withOpacity(0.1),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: const Color(0xFFF3F4F6)),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Container(
                      width: 64.w,
                      height: 64.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AllColor.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF408AF1), Color(0xFF5ca3f5)],
                            ),
                          ),
                          child: p.imageUrl.isNotEmpty && !_imageError
                              ? CachedNetworkImage(
                                  imageUrl: p.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Center(
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.w600,
                                        color: AllColor.white,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (_, __, ___) {
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (mounted) {
                                        setState(() => _imageError = true);
                                      }
                                    });
                                    return Center(
                                      child: Text(
                                        initial,
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.w600,
                                          color: AllColor.white,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Center(
                                  child: Text(
                                    initial,
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AllColor.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: 32.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: AllColor.foreground,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Row(
                              children: [
                                Icon(Icons.star,
                                    size: 16.sp,
                                    color: const Color(0xFFFBBF24)),
                                SizedBox(width: 4.w),
                                Text(
                                  p.avgRating.toStringAsFixed(1),
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AllColor.foreground,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '•',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AllColor.mutedForeground,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Text(
                                  '${p.reviewsCount} reviews',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AllColor.mutedForeground,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Subtle overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF408AF1).withOpacity(0.03),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.isFirst)
                Positioned(
                  top: 12.h,
                  right: 12.w,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                      ),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.emoji_events,
                            size: 14.sp, color: AllColor.white),
                        SizedBox(width: 4.w),
                        Text(
                          '#1',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AllColor.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
