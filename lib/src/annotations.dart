/// Annotation to mark a class as visible to MiniScript.
///
/// When applied to a class, all public properties and methods
/// will be accessible from MiniScript unless explicitly hidden
/// with the [@hide] annotation.
///
/// Example:
/// ```dart
/// @visible
/// class Player {
///   String name;
///   int score;
///
///   @hide
///   String _privateData;
/// }
/// ```
class Visible {
  const Visible();
}

/// Annotation to hide a property or method from MiniScript.
///
/// When applied to a class member, it will not be accessible
/// from MiniScript even if the class is marked as [@visible].
///
/// Example:
/// ```dart
/// @visible
/// class Player {
///   String name;        // visible
///   int score;          // visible
///
///   @hide
///   String password;    // hidden
/// }
/// ```
class Hide {
  const Hide();
}

/// Shorthand constant for [@Visible] annotation
const visible = Visible();

/// Shorthand constant for [@Hide] annotation
const hide = Hide();
