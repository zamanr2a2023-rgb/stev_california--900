import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:renizo/core/constants/api_control/provider_api.dart';
import 'package:renizo/core/constants/color_control/all_color.dart';
import 'package:renizo/core/models/service_category.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/cabinet/data/cabinet_requests_api.dart';
import 'package:renizo/features/cabinet/data/cabinet_static_addons.dart';
import 'package:renizo/features/cabinet/logic/my_cabinet_requests_provider.dart';

/// Create flow for `POST /cabinet-requests` (multipart).
class CabinetRequestScreen extends ConsumerStatefulWidget {
  const CabinetRequestScreen({
    super.key,
    required this.selectedTownId,
  });

  static const String routeName = '/cabinet-request';

  final String selectedTownId;

  @override
  ConsumerState<CabinetRequestScreen> createState() =>
      _CabinetRequestScreenState();
}

class _CabinetRequestScreenState extends ConsumerState<CabinetRequestScreen> {
  static const Color _bgBlue = Color(0xFF2384F4);
  static const Color _buttonBlue = Color(0xFF003E93);

  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _line1Ctrl = TextEditingController();
  final _line2Ctrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  final _styleOtherCtrl = TextEditingController();

  bool _loadingServices = true;
  String? _servicesError;

  String _serviceId = '';
  String _timeline = 'Within 1 month';
  String _styleChoice = 'Shaker';
  final Set<String> _selectedAddonIds = {};
  final List<XFile> _photos = [];

  bool _submitting = false;

  static const _timelines = [
    'Within 2 weeks',
    'Within 1 month',
    'Within 3 months',
    'Flexible',
  ];

  static const _styles = ['Shaker', 'Modern', 'Traditional', 'Other'];

  /// Backend: `photos must contain 1 to 6 items`
  static const int _kMinPhotos = 1;
  static const int _kMaxPhotos = 6;

  /// UI only — no dropdown; `serviceId` still comes from catalog for the API.
  static const String _kStaticServiceLabel = 'Kitchen cabinet';

  bool get _isValid {
    if (widget.selectedTownId.isEmpty || _serviceId.isEmpty) return false;
    if (_phoneCtrl.text.trim().isEmpty) return false;
    if (_line1Ctrl.text.trim().isEmpty ||
        _cityCtrl.text.trim().isEmpty ||
        _postalCtrl.text.trim().isEmpty) {
      return false;
    }
    if (_styleChoice == 'Other' && _styleOtherCtrl.text.trim().isEmpty) {
      return false;
    }
    if (_photos.length < _kMinPhotos || _photos.length > _kMaxPhotos) {
      return false;
    }
    return true;
  }

  String get _resolvedStyle =>
      _styleChoice == 'Other' ? _styleOtherCtrl.text.trim() : _styleChoice;

  @override
  void initState() {
    super.initState();
    _loadCatalogServices();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    _line1Ctrl.dispose();
    _line2Ctrl.dispose();
    _cityCtrl.dispose();
    _postalCtrl.dispose();
    _styleOtherCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalogServices() async {
    setState(() {
      _loadingServices = true;
      _servicesError = null;
    });
    try {
      final token = await AuthLocalStorage.getToken();
      final res = await http.get(
        Uri.parse(ProviderApi.catalogServices),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.toString().isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );
      dynamic decoded;
      try {
        decoded = jsonDecode(res.body);
      } catch (_) {
        throw Exception('Invalid response from server');
      }
      if (res.statusCode >= 400) {
        final msg = (decoded is Map<String, dynamic>)
            ? decoded['message']?.toString()
            : null;
        throw Exception(msg ?? 'Failed to load services');
      }
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }
      final data = decoded['data'];
      if (data is! List) {
        throw Exception('Unexpected response format');
      }
      String s(dynamic v) => (v ?? '').toString();
      final services = data
          .whereType<Map>()
          .map((e) {
            final map = e.cast<String, dynamic>();
            final isActive =
                map['isActive'] == null ? true : map['isActive'] == true;
            return ServiceCategory(
              id: s(map['_id']).isNotEmpty ? s(map['_id']) : s(map['id']),
              name: s(map['name']),
              icon: s(map['iconUrl']),
              description: s(map['description']),
              enabled: isActive,
            );
          })
          .where((c) => c.enabled)
          .toList();

      // Cabinet request API expects a cabinet service — do not list laundry etc.
      final cabinetServices = services.where((c) {
        return c.name.toLowerCase().contains('cabinet');
      }).toList();

      if (cabinetServices.isEmpty) {
        throw Exception(
          'No cabinet service in catalog. Add a service whose name includes '
          '"Cabinet" (e.g. Custom Kitchen Cabinets).',
        );
      }

      // Prefer "kitchen" + "cabinet" in the name when multiple cabinet services exist.
      ServiceCategory? preferred;
      for (final c in cabinetServices) {
        final n = c.name.toLowerCase();
        if (n.contains('kitchen') && n.contains('cabinet')) {
          preferred = c;
          break;
        }
      }
      preferred ??= cabinetServices.first;
      final resolvedId = preferred.id;

      if (mounted) {
        setState(() {
          _serviceId = resolvedId;
          _loadingServices = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _servicesError = e.toString().replaceFirst('Exception: ', '');
          _loadingServices = false;
        });
      }
    }
  }

  Future<void> _pickPhotos() async {
    if (!mounted) return;
    if (_photos.length >= _kMaxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum $_kMaxPhotos photos allowed'),
        ),
      );
      return;
    }
    final picker = ImagePicker();
    final list = await picker.pickMultiImage(imageQuality: 85);
    if (list.isEmpty || !mounted) return;

    final remaining = _kMaxPhotos - _photos.length;
    final toAdd = list.length > remaining ? list.take(remaining).toList() : list;

    setState(() => _photos.addAll(toAdd));

    if (list.length > remaining && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            remaining > 0
                ? 'Only $_kMaxPhotos photos total — added $remaining'
                : 'Maximum $_kMaxPhotos photos allowed',
          ),
        ),
      );
    }
  }

  void _clearPhotos() {
    setState(() => _photos.clear());
  }

  Future<void> _submit() async {
    if (!_isValid || _submitting) return;
    setState(() => _submitting = true);
    try {
      final photoParts = <CabinetPhotoPart>[];
      for (var i = 0; i < _photos.length; i++) {
        final x = _photos[i];
        final bytes = await x.readAsBytes();
        final name =
            x.name.trim().isNotEmpty ? x.name.trim() : 'photo_$i.jpg';
        photoParts.add((bytes: bytes, filename: name));
      }

      await createCabinetRequest(
        townId: widget.selectedTownId,
        serviceId: _serviceId,
        customerPhone: _phoneCtrl.text.trim(),
        timeline: _timeline,
        notes: _notesCtrl.text.trim(),
        style: _resolvedStyle,
        selectedAddonIds: _selectedAddonIds.toList(),
        visitAddress: {
          'line1': _line1Ctrl.text.trim(),
          'line2': _line2Ctrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'postalCode': _postalCtrl.text.trim(),
        },
        photos: photoParts,
      );
      if (!mounted) return;
      ref.invalidate(myCabinetRequestsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cabinet request submitted')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final townMissing = widget.selectedTownId.isEmpty;

    return Scaffold(
      backgroundColor: _bgBlue,
      appBar: AppBar(
        backgroundColor: _bgBlue,
        foregroundColor: AllColor.white,
        elevation: 0,
        title: const Text('Request cabinet'),
      ),
      body: _loadingServices
          ? const Center(
              child: CircularProgressIndicator(color: AllColor.white),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (townMissing)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12.h),
                      child: Text(
                        'Select a town from the home screen first.',
                        style: TextStyle(
                          color: AllColor.white.withOpacity(0.95),
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  if (_servicesError != null)
                    Text(
                      _servicesError!,
                      style: TextStyle(color: Colors.red.shade100, fontSize: 13.sp),
                    ),
                  _fieldLabel('Service'),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
                    decoration: BoxDecoration(
                      color: AllColor.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      _kStaticServiceLabel,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w500,
                        color: AllColor.foreground,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _fieldLabel('Phone'),
                  _whiteField(_phoneCtrl,
                      hint: '+1 …', keyboardType: TextInputType.phone),
                  SizedBox(height: 16.h),
                  _fieldLabel('Timeline'),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: AllColor.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _timeline,
                        items: _timelines
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _timeline = v);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _fieldLabel('Style'),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    decoration: BoxDecoration(
                      color: AllColor.white,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _styleChoice,
                        items: _styles
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _styleChoice = v);
                        },
                      ),
                    ),
                  ),
                  if (_styleChoice == 'Other') ...[
                    SizedBox(height: 12.h),
                    _whiteField(_styleOtherCtrl, hint: 'Describe style'),
                  ],
                  SizedBox(height: 16.h),
                  _fieldLabel('Visit address'),
                  _whiteField(_line1Ctrl, hint: 'Line 1'),
                  SizedBox(height: 8.h),
                  _whiteField(_line2Ctrl, hint: 'Line 2 (optional)'),
                  SizedBox(height: 8.h),
                  _whiteField(_cityCtrl, hint: 'City'),
                  SizedBox(height: 8.h),
                  _whiteField(_postalCtrl, hint: 'Postal code'),
                  SizedBox(height: 16.h),
                  _fieldLabel('Notes'),
                  _notesDetailsField(),
                  SizedBox(height: 16.h),
                  _fieldLabel('Add-ons'),
                  Text(
                    'Optional — values match API (e.g. soft_close, hardware).',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AllColor.white.withOpacity(0.85),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  ...kCabinetStaticAddons.map((a) {
                    final checked = _selectedAddonIds.contains(a.value);
                    return CheckboxListTile(
                      value: checked,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedAddonIds.add(a.value);
                          } else {
                            _selectedAddonIds.remove(a.value);
                          }
                        });
                      },
                      title: Text(
                        a.label,
                        style: TextStyle(
                          color: AllColor.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      subtitle: Text(
                        a.value,
                        style: TextStyle(
                          color: AllColor.white.withOpacity(0.65),
                          fontSize: 11.sp,
                        ),
                      ),
                      activeColor: AllColor.white,
                      checkColor: _buttonBlue,
                      tileColor: AllColor.white.withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    );
                  }),
                  SizedBox(height: 8.h),
                  _fieldLabel('Photos (required)'),
                  Text(
                    'Minimum $_kMinPhotos and maximum $_kMaxPhotos photos (required by the server).',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AllColor.white.withOpacity(0.88),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  OutlinedButton.icon(
                    onPressed: _pickPhotos,
                    icon: const Icon(Icons.photo_library_outlined,
                        color: AllColor.white),
                    label: Text(
                      _photos.isEmpty
                          ? 'Add photos'
                          : '${_photos.length} / $_kMaxPhotos photo(s)',
                      style: const TextStyle(color: AllColor.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AllColor.white),
                    ),
                  ),
                  if (_photos.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: _clearPhotos,
                        child: Text(
                          'Clear photos',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: AllColor.white.withOpacity(0.95),
                            decoration: TextDecoration.underline,
                            decorationColor: AllColor.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 24.h),
                  Material(
                    color: _buttonBlue,
                    borderRadius: BorderRadius.circular(16.r),
                    child: InkWell(
                      onTap: townMissing || !_isValid || _submitting
                          ? null
                          : _submit,
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        alignment: Alignment.center,
                        child: _submitting
                            ? SizedBox(
                                height: 22.h,
                                width: 22.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AllColor.white,
                                ),
                              )
                            : Text(
                                'Submit request',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AllColor.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Text(
        text,
        style: TextStyle(
          color: AllColor.white,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
    );
  }

  Widget _whiteField(
    TextEditingController c, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: c,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 15.sp, color: AllColor.foreground),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AllColor.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  /// Multiline “Details…” area — taller, top-aligned, readable hint.
  static const Color _notesHint = Color(0xFF9CA3AF);
  static const Color _notesFocusBorder = Color(0xFF408AF1);

  Widget _notesDetailsField() {
    return Material(
      color: AllColor.white,
      borderRadius: BorderRadius.circular(12.r),
      clipBehavior: Clip.antiAlias,
      child: TextField(
        controller: _notesCtrl,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        textAlignVertical: TextAlignVertical.top,
        minLines: 5,
        maxLines: 10,
        style: TextStyle(
          fontSize: 15.sp,
          height: 1.45,
          color: AllColor.foreground,
        ),
        cursorColor: _notesFocusBorder,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Details...',
          hintStyle: TextStyle(
            color: _notesHint,
            fontSize: 15.sp,
            height: 1.45,
          ),
          filled: true,
          fillColor: AllColor.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: _notesFocusBorder, width: 1.5),
          ),
          contentPadding: EdgeInsets.fromLTRB(14.w, 14.h, 14.w, 16.h),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
