/// Town model – aligned with "just for confirm the color." domain/models.ts
library;
// class Town {
//   const Town({
//     required this.id,
//     required this.name,
//     required this.state,
//     this.enabled = true,
//     this.zipCodes,
//   });
//
//   final String id;
//   final String name;
//   final String state;
//   final bool enabled;
//   final List<String>? zipCodes;
//
//   static fromJson(Map<String, dynamic> e) {}
// }

// New model and API Intagetion
class Town {
  final String id;
  final String name;
  final String state; // UI-তে আছে বলে রেখে দিলাম (API না দিলে empty থাকবে)
  final bool isActive;

  const Town({
    required this.id,
    required this.name,
    this.state = '',
    this.isActive = true,
  });

  factory Town.fromJson(Map<String, dynamic> json) {
    return Town(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      state: (json['state'] ?? '').toString(),
      isActive: (json['isActive'] ?? true) == true,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "state": state,
    "isActive": isActive,
  };
}
