import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:renizo/core/constants/api_control/provider_api.dart';
import 'package:renizo/core/models/service_category.dart';
import 'package:renizo/core/utils/auth_local_storage.dart';
import 'package:renizo/features/bookings/logic/booking_quote_logic.dart';
import 'package:renizo/features/bookings/screens/seller_matching_screen.dart';

/// Task submission form – full conversion from React TaskSubmission.tsx.
/// Create Booking: service type, sub-section, add-ons, date, time, address, notes.
class TaskSubmissionScreen extends StatefulWidget {
  const TaskSubmissionScreen({
    super.key,
    required this.selectedTownId,
    this.initialCategoryId,
    this.onSubmit,
  });

  static const String routeName = '/task-submission';

  final String selectedTownId;
  /// If set (e.g. from search), this service/category is pre-selected.
  final String? initialCategoryId;
  /// Called with form data when user taps "Find Available Providers".
  final void Function(TaskSubmissionFormData data)? onSubmit;

  @override
  State<TaskSubmissionScreen> createState() => _TaskSubmissionScreenState();
}

class _DropdownOption {
  const _DropdownOption(this.value, this.label);
  final String value;
  final String label;
}

class TaskSubmissionFormData {
  TaskSubmissionFormData({
    required this.categoryId,
    required this.subSectionId,
    this.addOnId,
    required this.date,
    required this.time,
    required this.address,
    this.notes,
  });
  final String categoryId;
  final String subSectionId;
  final String? addOnId;
  final String date;
  final String time;
  final String address;
  final String? notes;
}

class _TaskSubmissionScreenState extends State<TaskSubmissionScreen> {
  List<ServiceCategory> _categories = [];
  bool _loadingCategories = true;
  String? _categoriesError;
  List<_ApiSubSection> _subSections = [];
  bool _loadingSubSections = false;
  String? _subSectionsError;
  List<_ApiAddOn> _addOns = [];
  bool _loadingAddOns = false;
  String? _addOnsError;
  final List<String> _timeOptions = [
    'Morning (8AM - 12PM)',
    'Noon (12PM - 3PM)',
    'Afternoon (3PM - 6PM)',
  ];

  String _categoryId = '';
  String _subSectionId = '';
  String _addOnId = '';
  String _date = '';
  String _time = '';
  String _address = '';
  String _notes = '';

  static const Color _bgBlue = Color(0xFF2384F4);
  static const Color _buttonBlue = Color(0xFF003E93);
  static const Color _focusBlue = Color(0xFF408AF1);
  /// Dropdown overlay – dark blue-grey with white text and checkmark for selected (matches design).
  static const Color _dropdownMenuBg = Color(0xFF2C3E50);

  bool get _isFormValid {
    final subSectionOk =
        !_loadingSubSections && (_subSections.isEmpty || _subSectionId.isNotEmpty);
    return _categoryId.isNotEmpty &&
        subSectionOk &&
        _date.isNotEmpty &&
        _time.isNotEmpty &&
        _address.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadCatalogServices();
  }

  Future<void> _loadCatalogServices() async {
    setState(() {
      _loadingCategories = true;
      _categoriesError = null;
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
            final isActive = map['isActive'] == null ? true : map['isActive'] == true;
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

      if (mounted) {
        setState(() {
          _categories = services;
          _loadingCategories = false;
        });
        final initialId = widget.initialCategoryId;
        if (initialId != null &&
            initialId.isNotEmpty &&
            services.any((c) => c.id == initialId)) {
          setState(() => _categoryId = initialId);
          _loadSubSections(initialId);
          _loadAddOns(initialId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categories = [];
          _categoriesError = e.toString().replaceFirst('Exception: ', '');
          _loadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadSubSections(String serviceId) async {
    setState(() {
      _loadingSubSections = true;
      _subSectionsError = null;
      _subSections = [];
      _subSectionId = '';
    });
    try {
      final token = await AuthLocalStorage.getToken();
      final res = await http.get(
        ProviderApi.catalogSubSectionsUri(serviceId),
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
        throw Exception(msg ?? 'Failed to load sub-sections');
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }

      final data = decoded['data'];
      if (data is! List) {
        throw Exception('Unexpected response format');
      }

      final items = data
          .whereType<Map>()
          .map((e) => _ApiSubSection.fromJson(e.cast<String, dynamic>()))
          .where((s) => s.isActive)
          .toList();

      if (mounted) {
        setState(() {
          _subSections = items;
          _loadingSubSections = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _subSections = [];
          _subSectionsError = e.toString().replaceFirst('Exception: ', '');
          _loadingSubSections = false;
        });
      }
    }
  }

  Future<void> _loadAddOns(String serviceId) async {
    setState(() {
      _loadingAddOns = true;
      _addOnsError = null;
      _addOns = [];
      _addOnId = '';
    });
    try {
      final token = await AuthLocalStorage.getToken();
      final res = await http.get(
        ProviderApi.catalogAddonsUri(serviceId),
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
        throw Exception(msg ?? 'Failed to load add-ons');
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }

      final data = decoded['data'];
      if (data is! List) {
        throw Exception('Unexpected response format');
      }

      final items = data
          .whereType<Map>()
          .map((e) => _ApiAddOn.fromJson(e.cast<String, dynamic>()))
          .where((a) => a.isActive)
          .toList();

      if (mounted) {
        setState(() {
          _addOns = items;
          _loadingAddOns = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addOns = [];
          _addOnsError = e.toString().replaceFirst('Exception: ', '');
          _loadingAddOns = false;
        });
      }
    }
  }

  String _formatDisplayDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    final parts = dateStr.split('-');
    if (parts.length != 3) return dateStr;
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    final date = DateTime(year, month, day);
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final weekday = days[date.weekday % 7];
    return '$weekday, ${months[date.month - 1]} $day, $year';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _date = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  /// Builds ISO datetime for API from date + time slot (e.g. Morning -> 10:00).
  String _scheduledAtISO() {
    if (_date.isEmpty) return '';
    final timeHour = _time.contains('Morning') ? '10' : _time.contains('Noon') ? '13' : '16';
    return '${_date}T$timeHour:00:00.000Z';
  }

  Future<void> _submit() async {
    if (!_isFormValid) return;
    final resolvedSubSectionId =
        _subSectionId.isNotEmpty ? _subSectionId : _categoryId;
    final data = TaskSubmissionFormData(
      categoryId: _categoryId,
      subSectionId: resolvedSubSectionId,
      addOnId: _addOnId.isEmpty ? null : _addOnId,
      date: _date,
      time: _time,
      address: _address,
      notes: _notes.isEmpty ? null : _notes,
    );
    widget.onSubmit?.call(data);

    if (!mounted) return;
    double estimatedAmount = 0;
    try {
      final quote = await fetchBookingQuote(
        townId: widget.selectedTownId,
        serviceId: _categoryId,
        subsectionId: resolvedSubSectionId,
        addonIds: _addOnId.isEmpty ? const [] : [_addOnId],
      );
      estimatedAmount = quote.totalAmount;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Price quote failed: ${e.toString().replaceFirst('Exception: ', '')}',
            ),
          ),
        );
      }
    }
    final bookingId = 'booking_${DateTime.now().millisecondsSinceEpoch}';
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => SellerMatchingScreen(
          categoryId: _categoryId,
          selectedTownId: widget.selectedTownId,
          bookingId: bookingId,
          searchSubsectionId: resolvedSubSectionId,
          searchAddonIds: _addOnId.isEmpty ? const [] : [_addOnId],
          searchScheduledAtISO: _scheduledAtISO(),
          searchAddress: _address,
          searchNotes: _notes.isEmpty ? null : _notes,
          estimatedAmount: estimatedAmount > 0 ? estimatedAmount : 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildServiceTypeDropdown(),
                    if (_categoryId.isNotEmpty) ...[
                      SizedBox(height: 24.h),
                      _buildSubSectionDropdown(),
                    ],
                    if (_categoryId.isNotEmpty) ...[
                      SizedBox(height: 24.h),
                      _buildAddOnDropdown(),
                    ],
                    SizedBox(height: 24.h),
                    _buildDateField(),
                    SizedBox(height: 24.h),
                    _buildTimeDropdown(),
                    SizedBox(height: 24.h),
                    _buildAddressField(),
                    SizedBox(height: 24.h),
                    _buildNotesField(),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: _bgBlue,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.chevron_left, size: 24.sp, color: Colors.white),
              label: Text('Back', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white)),
            ),
          ),
          Text(
            'Create Booking',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tell us what you need help with',
            style: TextStyle(fontSize: 14.sp, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String iconName, String text, {bool required = true, bool optional = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Icon(_iconFor(iconName), size: 20.sp, color: Colors.white),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.white),
          ),
          if (required) Text(' *', style: TextStyle(fontSize: 16.sp, color: Colors.red.shade300)),
          if (optional) Text(' (Optional)', style: TextStyle(fontSize: 14.sp, color: Colors.white70)),
        ],
      ),
    );
  }

  IconData _iconFor(String name) {
    switch (name) {
      case 'Sparkles': return Icons.auto_awesome;
      case 'Package': return Icons.inventory_2_outlined;
      case 'Plus': return Icons.add;
      case 'Calendar': return Icons.calendar_today;
      case 'Clock': return Icons.access_time;
      case 'MapPin': return Icons.location_on_outlined;
      case 'FileText': return Icons.description_outlined;
      default: return Icons.circle_outlined;
    }
  }

  Widget _buildServiceTypeDropdown() {
    final options =
        _categories.map((c) => _DropdownOption(c.id, c.name)).toList();
    final hint = _loadingCategories
        ? 'Loading services...'
        : (_categories.isEmpty ? 'No services available' : 'Select a service');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Sparkles', 'Service Type'),
        _dropdown(
          value: _categoryId,
          hint: hint,
          options: options,
          onChanged: (v) {
            setState(() {
              _categoryId = v ?? '';
              _subSectionId = '';
              _addOnId = '';
              _subSections = [];
              _subSectionsError = null;
              _addOns = [];
              _addOnsError = null;
            });
            if (v != null && v.isNotEmpty) {
              _loadSubSections(v);
              _loadAddOns(v);
            }
          },
        ),
        if (_categoriesError != null) ...[
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  _categoriesError!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
              TextButton(
                onPressed: _loadCatalogServices,
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSubSectionDropdown() {
    if (_categoryId.isEmpty) return const SizedBox.shrink();
    if (_loadingSubSections) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Package', 'Service Sub-section'),
          _disabledDropdown('Loading sub-sections...'),
        ],
      );
    }
    if (_subSections.isEmpty) {
      if (_subSectionsError == null) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Package', 'Service Sub-section'),
          _disabledDropdown('No sub-sections available'),
          SizedBox(height: 6.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  _subSectionsError!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _loadSubSections(_categoryId),
                child: const Text('Retry'),
              ),
            ],
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Package', 'Service Sub-section'),
        _dropdown(
          value: _subSectionId,
          hint: 'Select sub-section',
          options:
              _subSections.map((s) => _DropdownOption(s.id, s.name)).toList(),
          onChanged: (v) => setState(() => _subSectionId = v ?? ''),
        ),
      ],
    );
  }

  Widget _buildAddOnDropdown() {
    if (_categoryId.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Plus', 'Add-Ons', required: false, optional: true),
        if (_loadingAddOns)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h),
            child: Row(
              children: [
                SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12.w),
                Text('Loading add-ons...', style: TextStyle(fontSize: 14.sp, color: Colors.grey)),
              ],
            ),
          )
        else if (_addOnsError != null)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _addOnsError!,
                    style: TextStyle(fontSize: 13.sp, color: Colors.red.shade700),
                  ),
                ),
                TextButton(
                  onPressed: () => _loadAddOns(_categoryId),
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        else
          _dropdown(
            value: _addOnId,
            hint: 'No add-ons',
            allowEmptyValue: true,
            options: [
              const _DropdownOption('', 'No add-ons'),
              ..._addOns.map((a) => _DropdownOption(a.id, a.name)),
            ],
            onChanged: (v) => setState(() => _addOnId = v ?? ''),
          ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Calendar', 'Preferred Date'),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _date.isEmpty ? 'Select a date' : _formatDisplayDate(_date),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: _date.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.calendar_today, size: 20.sp, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Clock', 'Preferred Time'),
        _dropdown(
          value: _time,
          hint: 'Select a time',
          options: _timeOptions.map((t) => _DropdownOption(t, t)).toList(),
          onChanged: (v) => setState(() => _time = v ?? ''),
        ),
      ],
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('MapPin', 'Service Address'),
        TextField(
          onChanged: (v) => setState(() => _address = v),
          decoration: InputDecoration(
            hintText: 'Enter your address',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: _focusBlue, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('FileText', 'Additional Notes', required: false, optional: true),
        TextField(
          onChanged: (v) => setState(() => _notes = v),
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe the issue or any special requirements...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16.r), borderSide: const BorderSide(color: _focusBlue, width: 2)),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String value,
    required String hint,
    required List<_DropdownOption> options,
    required ValueChanged<String?> onChanged,
    bool allowEmptyValue = false,
  }) {
    final menuItems = options.map((opt) {
      final isSelected = opt.value == value;
      return DropdownMenuItem<String>(
        value: opt.value,
        child: Row(
          children: [
            Expanded(
              child: Text(
                opt.label,
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isSelected) Icon(Icons.check, color: Colors.white, size: 22.sp),
          ],
        ),
      );
    }).toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: (value.isEmpty && !allowEmptyValue) ? null : value,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade700, fontSize: 16.sp)),
          isExpanded: true,
          dropdownColor: _dropdownMenuBg,
          borderRadius: BorderRadius.circular(16.r),
          selectedItemBuilder: (context) => options.map((opt) => Align(
            alignment: Alignment.centerLeft,
            child: Text(
              opt.label,
              style: TextStyle(color: Colors.black, fontSize: 16.sp),
              overflow: TextOverflow.ellipsis,
            ),
          )).toList(),
          items: menuItems,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _disabledDropdown(String hint) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.7,
        child: _dropdown(
          value: '',
          hint: hint,
          options: const [],
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: _bgBlue,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isFormValid ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _buttonBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _buttonBlue.withOpacity(0.5),
              padding: EdgeInsets.symmetric(vertical: 16.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              elevation: 8,
              shadowColor: _buttonBlue.withOpacity(0.3),
            ),
            child: Text('Find Available Providers', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }
}

class _ApiSubSection {
  final String id;
  final String name;
  final bool isActive;

  const _ApiSubSection({
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory _ApiSubSection.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    final id = s(json['_id']).isNotEmpty ? s(json['_id']) : s(json['id']);
    final isActive = json['isActive'] == null ? true : json['isActive'] == true;
    return _ApiSubSection(
      id: id,
      name: s(json['name']),
      isActive: isActive,
    );
  }
}

class _ApiAddOn {
  final String id;
  final String name;
  final String description;
  final bool isActive;

  const _ApiAddOn({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
  });

  factory _ApiAddOn.fromJson(Map<String, dynamic> json) {
    String s(dynamic v) => (v ?? '').toString();
    final id = s(json['_id']).isNotEmpty ? s(json['_id']) : s(json['id']);
    final isActive = json['isActive'] == null ? true : json['isActive'] == true;
    return _ApiAddOn(
      id: id,
      name: s(json['name']),
      description: s(json['description']),
      isActive: isActive,
    );
  }
}
