### SI Units

A rudimenrary implementation of SI units, using rational exponents.

Base units are aliased to `T`, `L`, `M`, `I`, `Θ`, `N`, `J`.

Usage example:

```d
alias Speed = typeof(L()/T());
alias Acc = typeof(Speed()/T());
alias Area = typeof(L().pow!2());
alias Force = typeof(M() * Acc());
alias Pressure = typeof(Force() / Area());
alias Energy = typeof(Force() * L());

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
```