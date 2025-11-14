/// A simple, type-safe template engine built to be familiar to Dart developers.
///
/// Supports variable substitution, property access, method calls,
/// list and map indexing, and custom functions.
library;

export 'src/conversion.dart'
    show
        SilhouetteBoolConversion,
        SilhouetteDoubleConversion,
        SilhouetteIntConversion,
        SilhouetteListConversion,
        SilhouetteMapConversion,
        SilhouetteObjectConversion,
        SilhouetteSetConversion,
        SilhouetteStringConversion;
export 'src/engine.dart' show TemplateEngine;
export 'src/exceptions.dart'
    show SilhouetteException, UnknownKeyException, UnknownPropertyException;
export 'src/template.dart' show CompiledTemplate;
export 'src/value.dart'
    show
        SilhouetteArguments,
        SilhouetteBool,
        SilhouetteDouble,
        SilhouetteEquatable,
        SilhouetteFunction,
        SilhouetteIdentifier,
        SilhouetteIndexable,
        SilhouetteInt,
        SilhouetteList,
        SilhouetteMap,
        SilhouetteNull,
        SilhouetteNumber,
        SilhouetteObject,
        SilhouetteSet,
        SilhouetteString,
        SilhouetteValue;
