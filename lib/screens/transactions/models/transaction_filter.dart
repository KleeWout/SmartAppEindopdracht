
class TransactionFilter {
  String searchTerm;
  double? minAmount;
  double? maxAmount;
  DateTime? startDate;
  DateTime? endDate;
  List<String> categories;
  List<String> merchants;
  List<String> groups;

  TransactionFilter({
    this.searchTerm = '',
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
    List<String>? categories,
    List<String>? merchants,
    List<String>? groups,
  }) : // Initialize with new modifiable lists
       this.categories = categories ?? [],
       this.merchants = merchants ?? [],
       this.groups = groups ?? [];

  bool get hasFilter {
    return searchTerm.isNotEmpty ||
        minAmount != null ||
        maxAmount != null ||
        startDate != null ||
        endDate != null ||
        categories.isNotEmpty ||
        merchants.isNotEmpty ||
        groups.isNotEmpty;
  }

  // Clear all filters
  void clear() {
    searchTerm = '';
    minAmount = null;
    maxAmount = null;
    startDate = null;
    endDate = null;
    categories = [];
    merchants = [];
    groups = [];
  }

  // Create a copy with updated values
  TransactionFilter copyWith({
    String? searchTerm,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    List<String>? merchants,
    List<String>? groups,
  }) {
    return TransactionFilter(
      searchTerm: searchTerm ?? this.searchTerm,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      // Create new modifiable lists when copying
      categories:
          categories != null
              ? List<String>.from(categories)
              : List<String>.from(this.categories),
      merchants:
          merchants != null
              ? List<String>.from(merchants)
              : List<String>.from(this.merchants),
      groups:
          groups != null
              ? List<String>.from(groups)
              : List<String>.from(this.groups),
    );
  }
}
