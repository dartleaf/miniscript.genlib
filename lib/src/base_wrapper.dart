import 'package:miniscript/miniscript.dart';

/// Base class for all MiniScript-wrapped Dart objects.
///
/// This class extends ValMap to provide MiniScript integration for Dart objects.
/// The original Dart object is stored in userData for easy access.
abstract class BaseWrapper<T> extends ValMap<T> {
  /// Creates a new wrapper around the given Dart object.
  ///
  /// The [dartObject] will be stored in userData and can be accessed
  /// via the [dartValue] getter.
  BaseWrapper(T dartObject) {
    userData = dartObject;

    // Set up evalOverride to intercept property access
    evalOverride = (key, valuePointer) {
      if (key is ValString) {
        var property = getProperty(key.value);
        if (property != null) {
          valuePointer.value = property;
          return true;
        }
      }
      return false;
    };

    // Set up assignOverride to intercept property assignment
    assignOverride = (key, value) {
      if (key is ValString) {
        return setProperty(key.value, value);
      }
      return false;
    };
  }

  /// Gets the original Dart object that this wrapper represents.
  T get dartValue => userData!;

  /// Gets a property value from the wrapped object.
  ///
  /// This method should be overridden by generated classes to provide
  /// proper property access to the underlying Dart object.
  ///
  /// Returns null if the property doesn't exist or is hidden.
  Value? getProperty(String propertyName);

  /// Sets a property value on the wrapped object.
  ///
  /// This method should be overridden by generated classes to provide
  /// proper property assignment to the underlying Dart object.
  ///
  /// Returns true if the property was set successfully, false otherwise.
  bool setProperty(String propertyName, Value? value);

  /// Gets a list of all visible property names.
  ///
  /// This method should be overridden by generated classes to return
  /// the names of all properties that are visible to MiniScript.
  List<String> getPropertyNames();

  @override
  Value? lookup(Value? key, ValuePointer<Value> valueFoundIn) {
    // First check if it's a string key (property access)
    if (key is ValString) {
      var property = getProperty(key.value);
      if (property != null) {
        valueFoundIn.value = property;
        return property;
      }
    }

    // Fall back to normal map lookup
    return super.lookup(key, valueFoundIn);
  }

  @override
  void setElem(Value? index, Value? value) {
    // Handle string key assignment (property setting)
    if (index is ValString) {
      if (setProperty(index.value, value)) {
        return; // Property was handled
      }
    }

    // Fall back to normal map assignment
    super.setElem(index, value);
  }

  @override
  String toString() {
    return toStringWithVM();
  }

  @override
  String toStringWithVM([vm]) {
    return '${dartValue.runtimeType}(${dartValue.toString()})';
  }

  @override
  bool boolValue() {
    return true; // Objects are always truthy
  }

  @override
  int intValue() {
    return 1; // Objects convert to 1 as integer
  }

  @override
  double doubleValue() {
    return 1.0; // Objects convert to 1.0 as double
  }
}
