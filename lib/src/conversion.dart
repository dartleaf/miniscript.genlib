import 'package:miniscript/miniscript.dart';
import 'package:miniscriptgenlib/src/cache.dart';
import 'package:miniscriptgenlib/src/base_wrapper.dart';

/// Static utility class for type conversions between Dart and MiniScript.
///
/// This is the single source of truth for all conversions in the system.
/// All other classes should delegate to these methods.
class ConversionUtils {
  ConversionUtils._(); // Private constructor to prevent instantiation

  static dynamic hardConvert<T>(dynamic value) {
    if (T == bool) {
      if (value is double || value is int) {
        return value == 1;
      }
    }

    return value;
  }

  /// Converts a Dart object to a MiniScript Value.
  ///
  /// This is the main conversion method that handles all Dart -> MiniScript
  /// conversions including primitives, collections, and null values.
  /// For custom objects, returns null (should be handled by cache system).
  static Value? dartToValue<T>(T dartValue, {bool force = true}) {
    if (dartValue == null) {
      return ValNull.instance;
    }

    if (dartValue is String) {
      return ValString(dartValue);
    }

    if (dartValue is int) {
      return ValNumber(dartValue.toDouble());
    }
    if (dartValue is double) {
      return ValNumber(dartValue);
    }

    if (dartValue is bool) {
      return ValNumber(dartValue ? 1.0 : 0.0);
    }

    if (dartValue is List<Value>) {
      return ValList(dartValue);
    }

    if (dartValue is Map<Value?, Value?>) {
      return ValMap(Dictionary(dartValue));
    }

    if (dartValue is Dictionary) {
      return ValMap(dartValue);
    }

    if (force) {
      if (dartValue is List) {
        return ValList(
          dartValue.map((e) => dartToValue(e, force: true)).toList(),
        );
      }

      if (dartValue is Map) {
        return ValMap(
          Dictionary(
            dartValue.map((k, v) => MapEntry(dartToValue(k), dartToValue(v))),
          ),
        );
      }
    }

    final wrapper = MiniScriptCache.instance.getWrapper<T>();

    if (wrapper == null) {
      throw UnsupportedError('Unsupported type: ${dartValue.runtimeType}');
    }

    return wrapper.call(dartValue);
  }

  static Value? Function(Interpreter interpreter, List<Value?> args)
  valueToDartFunction(ValFunction function) {
    return (Interpreter interpreter, List<Value?> args) {
      final context = Context([]);
      if (interpreter.vm != null) {
        context.parent = interpreter.vm!.globalContext;
      }

      for (final line in context.code) {
        line.evaluate(context);
      }

      return context.resultStorage;
    };
  }

  /// Converts a MiniScript Value to a Dart object.
  ///
  /// This is the main conversion method that handles all MiniScript -> Dart
  /// conversions including primitives, collections, wrappers, and null values.
  static dynamic valueToDart<T extends Value>(T? value, {bool force = true}) {
    if (value == null || value is ValNull) {
      return null;
    }

    if (value is ValString) {
      return value.value;
    }

    if (value is ValNumber) {
      return value.value;
    }

    if (value is ValFunction) {
      return valueToDartFunction(value);
    }

    // Handle BaseWrapper objects - import handled via late binding
    if (value is BaseWrapper) {
      // Use reflection-like approach to get userData
      try {
        final userData = (value as ValMap).userData;
        return userData;
      } catch (e) {
        // Fallback if userData access fails
        return value;
      }
    }

    if (force) {
      if (value is ValList) {
        // Recursively convert each element to Dart
        return value.values.map((e) => valueToDart(e, force: true)).toList();
      }

      if (value is ValMap) {
        // Recursively convert each key and value to Dart
        final realMap = value.map.realMap;
        return realMap.map(
          (k, v) => MapEntry(
            valueToDart(k, force: true),
            valueToDart(v, force: true),
          ),
        );
      }
    } else {
      if (value is ValMap) {
        return value.map.realMap;
      }

      if (value is ValList) {
        return value.values;
      }
    }

    // For other types, return as-is
    return value;
  }

  /// Gets the type name of a MiniScript Value as a string.
  static String getTypeName(Value? value) {
    if (value == null || value is ValNull) {
      return 'null';
    }

    if (value is ValString) {
      return 'string';
    }

    if (value is ValNumber) {
      return 'number';
    }

    if (value is ValList) {
      return 'list';
    }

    if (value is ValMap) {
      if (value.runtimeType.toString().contains('BaseWrapper')) {
        try {
          final userData = (value as dynamic).userData;
          return 'object(${userData.runtimeType})';
        } catch (e) {
          return 'object';
        }
      }
      return 'map';
    }

    return value.runtimeType.toString();
  }
}
