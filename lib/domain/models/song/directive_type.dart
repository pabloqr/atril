/// The structural region in which a directive is inserted by source editors.
enum DirectiveLocation { header, body, none }

/// A directive understood by Atril's current ChordPro subset.
///
/// Each value records its preferred [location]. Unrecognized names are mapped
/// to [unknown] so source-oriented code can preserve them without treating them
/// as supported metadata.
enum DirectiveType {
  title(DirectiveLocation.header),
  artist(DirectiveLocation.header),
  key(DirectiveLocation.header),
  capo(DirectiveLocation.header),
  comment(DirectiveLocation.body),

  unknown(DirectiveLocation.none);

  //------------------------------------------------------------------------------------------------------------------//

  /// Creates a directive type associated with [location].
  const DirectiveType(this.location);

  /// The structural region used when inserting this directive.
  final DirectiveLocation location;

  //------------------------------------------------------------------------------------------------------------------//

  /// Case-sensitive lookup by canonical lowercase directive name.
  static final lookup = Map<String, DirectiveType>.unmodifiable({for (final type in values) type.name: type});

  //------------------------------------------------------------------------------------------------------------------//

  /// The canonical ordering index for header directives.
  ///
  /// Returns `-1` for directives that do not belong to the ordered header.
  int get order => _headerOrder.indexOf(this);

  // bool get multiInstance => location == DirectiveLocation.body;

  //------------------------------------------------------------------------------------------------------------------//

  static const _headerOrder = [title, artist, key, capo];
}
