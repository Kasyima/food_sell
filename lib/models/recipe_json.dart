class Recipe {
  final String uri;
  final String label;

  Recipe({
    required this.label,
    required this.uri,
  });

/*In fromJson(), you grab data from the JSON map variable json and convert
it to arguments you pass to the Recipe constructor. */
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      label: json['label'],
      uri: json['uri'],
    );
  }
// In toJson(), you construct a map using the JSON field names.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'uri': uri,
      'label': label,
    };
  }
}
