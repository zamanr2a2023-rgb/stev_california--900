/// Cabinet request `selectedAddons` keys (JSON array of strings) — matches backend / Postman.
class CabinetStaticAddon {
  const CabinetStaticAddon({
    required this.label,
    required this.value,
  });

  /// UI label
  final String label;

  /// Value sent in `selectedAddons` (snake_case)
  final String value;
}

/// Static add-ons for POST /cabinet-requests `selectedAddons` field.
const List<CabinetStaticAddon> kCabinetStaticAddons = [
  CabinetStaticAddon(label: 'Soft-close hinges', value: 'soft_close'),
  CabinetStaticAddon(label: 'Premium hardware', value: 'hardware'),
  CabinetStaticAddon(label: 'Custom paint finish', value: 'paint_finish'),
  CabinetStaticAddon(label: 'Pull-out drawers', value: 'pull_out_drawers'),
  CabinetStaticAddon(label: 'Lazy Susan', value: 'lazy_susan'),
  CabinetStaticAddon(label: 'Crown molding', value: 'crown_molding'),
  CabinetStaticAddon(
    label: 'Under-cabinet lighting',
    value: 'under_cabinet_lighting',
  ),
];
