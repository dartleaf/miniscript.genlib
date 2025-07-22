import 'package:miniscript/miniscript.dart';
import 'package:miniscriptgenlib/src/cache.dart';
import 'package:miniscriptgenlib/src/base_wrapper.dart';

class DartFunction {
  final Function(List<dynamic>) function;
  final List<String> params;

  DartFunction(this.function, this.params);
}

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

  static Value? Function(List<Value?> args) wrapFunction(
    Context context,
    Value? Function(Interpreter interpreter, List<Value?> args) function,
  ) {
    return (List<Value?> args) {
      final interpreter = context.interpreter!;
      return function(interpreter, args);
    };
  }

  static dynamic wrapDynamic(Context context, dynamic value) {
    if (value is Function) {
      return wrapFunction(
        context,
        value as Value? Function(Interpreter interpreter, List<Value?> args),
      );
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

    if (dartValue is DartFunction) {
      return dartToValueFunction(dartValue);
    }

    final wrapper = MiniScriptCache.instance.getWrapper<T>();

    if (wrapper == null) {
      throw UnsupportedError('Unsupported type: ${dartValue.runtimeType}');
    }

    return wrapper.call(dartValue);
  }

  static ValFunction dartToValueFunction(DartFunction dartFunction) {
    final fn = Intrinsic.create("\$_");
    fn.name = dartFunction.hashCode.toString();
    for (final name in dartFunction.params) {
      fn.addParam(name);
    }
    fn.code = (context, [partialResult]) {
      final args = [];
      for (final name in dartFunction.params) {
        args.add(context.getLocal(name));
      }
      return IntrinsicResult(dartFunction.function(args));
    };
    return fn.getFunc();
  }

  static Value? Function(Context context, List<Value?> args)
  valueToDartFunction(ValFunction function) {
    return (Context context, List<Value?> args) {
      final interpreter = context.interpreter!;
      interpreter.setGlobalValue("\$_call", function);
      interpreter.setGlobalValue("\$_args", ValList(args));

      String argText = "";

      for (int i = 0; i < args.length; i++) {
        argText += "\$_args[$i], ";
      }

      interpreter.repl("globals.\$_ret = \$_call $argText");
      return interpreter.getGlobalValue("\$_ret");
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

    if (value is ValFunction) {
      return valueToDartFunction(value);
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
}
