import std;

void main() {
    Nullable!int x = 5;
    Nullable!int none = Nullable!int.init;
    auto chained = x  
        .and_then((int v) => v * 3)
        .and_then((int v) => nullable(v + 1));
    
    writeln(chained); // Nullable(15)

    
    auto fallback1 = or_else!(int)(none, () => 100);
    writeln(fallback1); // Output: Nullable(100)

    // Fallback returning a Nullable!int directly
    auto fallback2 = or_else!(int)(none, () => nullable(200));
    writeln(fallback2); // Output: Nullable(200)
}

Nullable!T and_then(T, U)(Nullable!U val, T delegate(U) func) {
    if (val.isNull()) return Nullable!T.init;

    static if (is(ReturnTypeOf!func == Nullable!T)) {
        return func(val.get());
    } else {
        return nullable(func(val.get()));
    }
}

Nullable!T or_else(T)(Nullable!T val, T delegate() fallback) {
    if (!val.isNull()) return val;
    return nullable(fallback());
}

Nullable!T or_else(T)(Nullable!T val, Nullable!T delegate() fallback) {
    if (!val.isNull()) return val;
    return fallback();
}


/*
import std.typecons;
import std.functional;

// `map`: Transforms the value inside Nullable if present
T map(T, U)(Nullable!U opt, T delegate(U) func) {
    return opt.isNull ? Nullable!T.init : Nullable!T(func(opt.get));
}

// `mapOr`: Like `map`, but returns a default value if None
T mapOr(T, U)(Nullable!U opt, T defaultValue, T delegate(U) func) {
    return opt.isNull ? defaultValue : func(opt.get);
}

// `mapOrElse`: Like `mapOr`, but computes the default value lazily
T mapOrElse(T, U)(Nullable!U opt, T delegate() defaultFunc, T delegate(U) func) {
    return opt.isNull ? defaultFunc() : func(opt.get);
}

// `andThen`: Chains computations if the value is present
Nullable!T andThen(T, U)(Nullable!U opt, Nullable!T delegate(U) func) {
    return opt.isNull ? Nullable!T.init : func(opt.get);
}

// `orElse`: Provides a fallback value if None
Nullable!T orElse(T)(Nullable!T opt, Nullable!T delegate() fallback) {
    return opt.isNull ? fallback() : opt;
}

// `unwrapOr`: Returns the contained value or a default
T unwrapOr(T)(Nullable!T opt, T defaultValue) {
    return opt.isNull ? defaultValue : opt.get;
}

// `unwrapOrElse`: Returns the contained value or computes a default
T unwrapOrElse(T)(Nullable!T opt, T delegate() defaultFunc) {
    return opt.isNull ? defaultFunc() : opt.get;
}

// Example Usage
void main() {
    Nullable!int x = 5;
    Nullable!int none = Nullable!int.init;

    // Using `map`
    auto doubled = map!(int, int)(x, (v) => v * 2);
    writeln(doubled); // Nullable(10)

    // Using `mapOr`
    int result1 = mapOr!(int, int)(none, 42, (v) => v * 2);
    writeln(result1); // 42

    // Using `mapOrElse`
    int result2 = mapOrElse!(int, int)(none, () => 99, (v) => v * 3);
    writeln(result2); // 99

    // Using `andThen`
    auto chained = andThen!(int, int)(x, (v) => Nullable!int(v * 3));
    writeln(chained); // Nullable(15)

    // Using `orElse`
    auto fallback = orElse!(int)(none, () => Nullable!int(100));
    writeln(fallback); // Nullable(100)

    // Using `unwrapOr`
    writeln(unwrapOr!(int)(none, 200)); // 200

    // Using `unwrapOrElse`
    writeln(unwrapOrElse!(int)(none, () => 300)); // 300
}
*/