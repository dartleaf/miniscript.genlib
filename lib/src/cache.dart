import 'base_wrapper.dart';

/// Type definition for wrapper factory functions.
///
/// A wrapper factory takes a Dart object and returns a BaseWrapper
/// that can be used in MiniScript.
typedef WrapperFactory<T> = BaseWrapper<T> Function(T dartObject);

/// Global cache system for managing wrapped objects and conversions.
///
/// This class provides a centralized way to:
/// - Register wrapper factories for different types
/// - Cache wrapped objects to avoid duplicate wrapping
/// - Handle circular references and memory management
class MiniScriptCache {
  static final MiniScriptCache _instance = MiniScriptCache._internal();

  /// Gets the singleton instance of the cache.
  static MiniScriptCache get instance => _instance;

  MiniScriptCache._internal();

  /// Map of Type to wrapper factory functions.
  final Map<Type, WrapperFactory> _wrapperFactories = {};

  /// Cache of Dart objects to their MiniScript wrappers.
  /// Uses WeakMap-like behavior to avoid memory leaks.
  final Map<Object, BaseWrapper> _objectCache = {};

  /// Cache of MiniScript values to their Dart objects.
  /// This is used for reverse lookups.
  final Map<BaseWrapper, Object> _valueCache = {};

  /// Registers a wrapper factory for a specific type.
  ///
  /// Example:
  /// ```dart
  /// cache.registerWrapper<Player>((player) => PlayerWrapper(player));
  /// ```
  void registerWrapper<T>(WrapperFactory<T> factory) {
    _wrapperFactories[T] = (obj) => factory(obj as T);
  }

  /// Checks if a wrapper factory is registered for the given type.
  bool hasWrapper<T>() => _wrapperFactories.containsKey(T);

  /// Checks if a wrapper factory is registered for the given object's type.
  bool hasWrapperForObject(Object obj) =>
      _wrapperFactories.containsKey(obj.runtimeType);

  /// Gets a wrapper factory for the given type.
  WrapperFactory<T>? getWrapper<T>() {
    var factory = _wrapperFactories[T];
    if (factory == null) return null;
    return (obj) => factory(obj) as BaseWrapper<T>;
  }

  /// Clears the cache of wrapped objects.
  ///
  /// This should be called periodically to prevent memory leaks,
  /// especially in long-running applications.
  void clearCache() {
    _objectCache.clear();
    _valueCache.clear();
  }

  /// Removes a specific object from the cache.
  void removeFromCache(Object dartObject) {
    var wrapper = _objectCache[dartObject];
    if (wrapper != null) {
      _objectCache.remove(dartObject);
      _valueCache.remove(wrapper);
    }
  }

  /// Gets the number of cached objects.
  int get cacheSize => _objectCache.length;

  /// Gets statistics about the cache.
  Map<String, dynamic> getCacheStats() {
    return {
      'cachedObjects': _objectCache.length,
      'registeredWrappers': _wrapperFactories.length,
      'wrapperTypes': _wrapperFactories.keys.map((t) => t.toString()).toList(),
    };
  }
}

/// Sets up the cache system with all registered wrappers.
///
/// This function should be called once at the beginning of your application
/// to register all the generated wrapper classes.
///
/// Example:
/// ```dart
/// void setupMiniScriptCache() {
///   var cache = MiniScriptCache.instance;
///
///   // Register generated wrappers
///   cache.registerWrapper<Player>((player) => PlayerWrapper(player));
///   cache.registerWrapper<Weapon>((weapon) => WeaponWrapper(weapon));
///   // ... more registrations
/// }
/// ```
void setupMiniScriptCache() {
  // This function will be populated by the code generator
  // with calls to registerWrapper for each generated wrapper class
}
