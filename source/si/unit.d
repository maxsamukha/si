/**
    SI units.

    Authors: Max Samukha (maxsamukha@gmail.com)
    License: MIT
 */
module si.unit;

import
    core.attribute,
    std.traits,
    std.format,
    std.meta,
    std.conv,
    std.math,
    std.numeric;

/**
    Basic rational type.
 */
struct Q
{
    int num;
    uint den = 1;

    alias This = typeof(this);

    this(int num, uint den = 1)
    {
        this.num = num;
        this.den = den;
    }

    This reduce() const
    {
        const int div = gcd(num, den);
        return This(num / div, den / div);
    }

    This inverse() const
    {
        const n = num >> 31;
        return This(den - (n & (den << 1)), num - (n & (num << 1)));
    }
    
    bool opEquals(This other) const
    {
        return num * other.den == other.num * den;
    }

    int opCmp(This other) const
    {
        return num * other.den - other.num * den;
    }

    This opBinary(string op)(This other) const
    if (op == "+" || op == "-")
    {
        return This(mixin("num * other.den ", op, " other.num * den"),
            den * other.den).reduce();
    }

    This opBinary(string op)(This other) const
    if (op == "*")
    {
        return This(num * other.num, den * other.den).reduce();
    }

    This opBinary(string op: "/")(This other) const => this * other.inverse();

    This opUnary(string op: "-")() const => This(-num, den);

    bool opCast(T: bool)() const => num != 0;

    T opCast(T: double)() const => cast(T)num / den;

    string toString() const
    {
        string result = to!string(num);
        if (den != 1)
            result ~= "/" ~ to!string(den);
        return result;
    }
}

unittest
{   
    assert(Q().reduce() is Q());
    assert(-Q(1) == Q(-1));
    assert(Q(0, 2).reduce() is Q(0, 1));
    assert(Q(2, 0).reduce() is Q(1, 0));
    assert(Q(2, 4).reduce() is Q(1, 2));
    assert(Q(-2, 4).reduce() is Q(-1, 2));

    assert(Q(0, 0).inverse() == Q(0, 0));
    assert(Q().inverse() is Q(1, 0));
    assert(Q(2, 4).inverse() is Q(4, 2));
    assert(Q(-2, 4).inverse() is Q(-4, 2));

    assert(Q(1, 2) + Q(2, 3) == Q(7, 6));
    assert(Q(1, 2) - Q(2, 3) == Q(-1, 6));

    assert(Q(1, 2) == Q(2, 4));
    assert(Q(1, 2) < Q(2, 3));
    assert(Q(-1, 2) > Q(-2, 3));

    assert(Q(1, 2) * Q(2, 3) == Q(1, 3));
    assert(Q(1, 2) / Q(3, 2) == Q(1, 3));

    assert(Q(1) != Q(-1));
}

/**
 */
struct Dims
{
    enum symbols = ["T", "L", "M", "I", "Θ", "N", "J"];
    
    Q[symbols.length] values;
    alias this = values;

    static Dims opCall(Q time = 0, Q length = 0, Q mass = 0, Q current = 0,
        Q temperature = 0, Q substance = 0, Q lumIntensity = 0)
    {
        return opCall([__traits(parameters)]);
    }

    static Dims opCall(int time, int length = 0, int mass = 0, int current = 0,
        int temperature = 0, int substance = 0, int lumIntensity = 0)
    {
        auto argToQ(alias arg)() => Q(arg);
        return Dims(staticMap!(argToQ, __traits(parameters)));
    }
    
    static Dims opCall(typeof(Dims.values) values)
    {
        Dims result;
        result.values = values;
        return result;
    }

    // A workaround for "array operations require destination".
    Dims opBinary(string op)(Dims other) const
    {
        Dims result;
        result[] = mixin("this[] ", op, "other[]");
        return result;
    }

    // ditto
    Dims opBinary(string op)(Q other) const
    {
        Dims result;
        result[] = mixin("this[] ", op, "other");
        return result;
    }

    // ditto
    Dims opUnary(string op)() const
    {
        Dims result;
        result[] = mixin(op, "this[]");
        return result;
    }

    string toString() const
    {   
        string result;
        foreach (i, e; this.values)
        {
            if (e)
            {
                result ~= symbols[i];
                if (e != Q(1))
                    result ~= e.toString;
            }
        }
        return result;
    }
}

/**
 */
enum bool isUnit(T) = is(T: Unit!dims, Dims dims);

/**
 */
struct Unit(Dims dims_)
{
    double value = 0;

    alias dims = dims_;
    alias This = typeof(this);

    alias Pow(Q e) = Unit!(dims * e);
    alias Pow(int e) = Pow!(Q(e));
    alias Sqrt() = Pow!(Q(1, 2));
    alias Inverse = Pow!(-1);

    enum dimsString = dims.toString();

    This opBinary(string op, U)(U other) const
    if (isUnit!U && dims == U.dims && (op == "+" || op == "-"))
    {
        return This(mixin("value ", op, " other.value"));
    }

    auto opBinary(string op, U)(U other) const
    if (isUnit!U && (op == "*" || op == "/"))
    {
        return Unit!(mixin("dims ", (op == "*" ? "+" : "-"), " U.dims"))(mixin("value ", op, " other.value"));
    }

    This opBinary(string op)(double other) const
    if (op == "+" || op == "-" || op == "*" || op == "/")
    {
        return mixin("This(value ", op, " other)");
    }

    template opBinaryRight(string op)
    if (op == "+" || op == "*")
    {
        alias opBinaryRight = opBinary!op;
    }

    This opUnary(string op: "-")() const => This(-value);

    This opBinaryRight(string op: "-")(double other) const => This(other - value);

    Inverse opBinaryRight(string op: "/")(double other) const => Inverse(other / value);

    Pow!e pow(Q e)() const => typeof(return)(value^^cast(double)e);
    
    Pow!(Q(e)) pow(int e)() const => pow!(Q(e));

    Sqrt!() sqrt() const => typeof(return)(.sqrt(value));

    Inverse inverse() const => 1 / this;

    string toString() => text(value, dimsString);
}

/**
 */
alias UnitAt(size_t index, Q power = Q(1)) = Unit!({ Dims dims; dims[index] = power; return dims; }());

// Aliases for the base units
static foreach (i; 0..Dims.values.length)
    mixin("alias ", Dims.symbols[i], " = UnitAt!(", i, ");");

unittest
{
    alias Speed = typeof(L()/T());
    alias Acc = typeof(Speed()/T());
    alias Area = typeof(L().pow!2());
    alias Force = typeof(M() * Acc());
    alias Pressure = typeof(Force() / Area());
    alias Energy = typeof(Force() * L());

    assert(-L(1) == L(-1));
    assert(L(1) + L(1) == L(2));
    assert(L(3) - L(1) == L(2));
    assert(2 + L(4) == L(6));
    assert(L(6) - 2 == L(4));
    assert(6 - L(2) == L(4));
    assert(L(4) + 2 == L(6));
    assert(L(2) * 3 == L(6));
    assert(3 * L(2) == L(6));
    assert(1 / L(2) == L.Inverse(1.0 / 2));
    assert(L(4) / 2 == L(2));
    assert(L(10) / T(2) == Speed(5));
    assert(Speed(4) / T(2) == Acc(2));
    assert(M(2) * Acc(3) == Force(6));
    assert(Force(6) / Area(2) == Pressure(3));
    assert(Force(3) * L(2) == Energy(6));

    Energy k = M(2) * L(4).pow!2 / T(2).pow!2;
    assert((4 * k / M(2)).sqrt == Speed(4));

    T t = 2 * PI * (L(4) / Acc(9.8)).sqrt;
    assert(t.value.isClose(2 * PI * sqrt(4 / 9.8)));
}

