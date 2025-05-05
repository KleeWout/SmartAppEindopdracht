/// A model representing a group of users who share expenses
///
/// Groups allow users to track shared expenses and assign receipt items to members.
class Group {
  final String id;
  final String name;
  final bool isFavorite;
  final String? imageUrl; // Added for group profile image

  Group({
    required this.id,
    required this.name,
    this.isFavorite = false,
    this.imageUrl, // Optional image URL
  });

  /// Creates a Group from a Firestore document map
  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      isFavorite: map['isFavorite'] ?? false,
      imageUrl: map['imageUrl'], // Get image URL from map
    );
  }

  /// Converts this group to a map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isFavorite': isFavorite,
      'imageUrl': imageUrl, // Include image URL in map
    };
  }

  /// Creates a copy of this group with specified fields replaced
  Group copyWith({
    String? id,
    String? name,
    bool? isFavorite,
    String? imageUrl, // Added to copyWith
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      isFavorite: isFavorite ?? this.isFavorite,
      imageUrl: imageUrl ?? this.imageUrl, // Pass through imageUrl
    );
  }
}
