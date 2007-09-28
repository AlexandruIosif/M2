--		Copyright 1996-2006 by Daniel R. Grayson and Michael E. Stillman

QuotientRing = new Type of EngineRing
QuotientRing.synonym = "quotient ring"
ideal QuotientRing := R -> R.ideal
isQuotientRing = method(TypicalValue => Boolean)
monoid QuotientRing := o -> R -> R.monoid
isQuotientRing Ring := R -> false
isQuotientRing QuotientRing := R -> true
coefficientRing QuotientRing := (cacheValue coefficientRing) (R -> coefficientRing ambient R)
options QuotientRing := R -> options ambient R
isQuotientOf = method(TypicalValue => Boolean)
isQuotientOf(Ring,Ring) := (R,S) -> false
isQuotientOf(Ring,QuotientRing) := (R,S) -> R === ambient S or isQuotientOf(R,ambient S)
isQuotientOf(Type,Ring) := (X,S) -> false
isQuotientOf(Type,QuotientRing) := (X,S) -> instance(ambient S,X) or isQuotientOf(X,ambient S)
degreeLength QuotientRing := S -> degreeLength ambient S
vars QuotientRing := (cacheValue vars) (S -> map(S^1,, table (1, numgens S, (i,j) -> S_j)))
numgens QuotientRing := (cacheValue numgens) (S -> numgens ambient S)
pretty := relns -> (
     s := toSequence flatten entries relns;
     if #s === 1 then s = first s;
     s)
toExternalString QuotientRing := S -> toString expression S
toString QuotientRing := S -> toExternalString S
random QuotientRing := opts -> S -> (
     if S.baseRings === {ZZ} then (random char S)_S
     else notImplemented())
expression QuotientRing := S -> new Divide from { expression ambient S, expression pretty S.relations }
tex QuotientRing := S -> "$" | texMath S | "$"
texMath QuotientRing := S -> texMath new Divide from { last S.baseRings, pretty S.relations }
describe QuotientRing := R -> net expression R
net QuotientRing := S -> if ReverseDictionary#?S then toString ReverseDictionary#S else net expression S
ambient PolynomialRing := R -> R
ambient QuotientRing := Ring => (cacheValue ambient) (R -> last R.baseRings)
degrees QuotientRing := R -> degrees ambient R
isHomogeneous QuotientRing := (cacheValue isHomogeneous) (R -> isHomogeneous ambient R and isHomogeneous R.relations)
isSkewCommutative QuotientRing := R -> isSkewCommutative ambient R

Ring / Module := QuotientRing => (R,I) -> (
     if ambient I != R^1 or I.?relations
     then error ("expected ", toString I, " to be an ideal of ", toString R);
     R / ideal I)

savedQuotients := new MutableHashTable

liftZZmodQQ := (r,S) -> (
     needsPackage "LLLBases";
     v := (value getGlobalSymbol "LLL") syz matrix {{-1,lift(r,ZZ),char ring r}};
     v_(0,0) / v_(1,0))

ZZquotient := (R,I) -> (
     gensI := generators I;
     if ring gensI =!= ZZ then error "expected an ideal of ZZ";
     n := gcd flatten entries gensI;
     if n < 0 then n = -n;
     if n === 0 then ZZ
     else if savedQuotients#?n 
     then savedQuotients#n
     else (
	  if n > 32767 then error "large characteristics not implemented yet";
	  if n > 1 and not isPrime n
	  then error "ZZ/n not implemented yet for composite n";
	  S := new QuotientRing from rawZZp n;
	  S.cache = new CacheTable;
	  S.isBasic = true;
	  S.ideal = I;
	  S.baseRings = {R};
     	  commonEngineRingInitializations S;
	  S.relations = gensI;
	  S.isCommutative = true;
	  S.presentation = matrix{{n}};
	  S.order = S.char = n;
	  S.dim = 0;					    -- n != 0 and n!= 1
	  expression S := x -> expression rawToInteger raw x;
	  fraction(S,S) := S / S := (x,y) -> x//y;
	  S.frac = S;		  -- ZZ/n with n PRIME!
	  savedQuotients#n = S;
	  lift(S,QQ) := liftZZmodQQ;
	  S))

Ring / Ideal := QuotientRing => (R,I) -> I.cache.QuotientRing = (
     if ring I =!= R then error "expected ideal of the same ring";
     if I.cache.?QuotientRing then return I.cache.QuotientRing;
     if I == 0 then return R;
     if R === ZZ then return ZZquotient(R,I);
     error "can't form quotient of this ring";
     )

predecessors := method()
predecessors Ring := R -> {R}
predecessors QuotientRing := R -> append(predecessors last R.baseRings, R)

EngineRing / Ideal := QuotientRing => (R,I) -> I.cache.QuotientRing = (
     if ring I =!= R then error "expected ideal of the same ring";
     if I.cache.?QuotientRing then return I.cache.QuotientRing;
     if I == 0 then return R;
     -- recall that ZZ is NOT an engine ring.
     A := R;
     while class A === QuotientRing do A = last A.baseRings;
     gensI := generators I;
     gensgbI := generators gb gensI;
     S := new QuotientRing from rawQuotientRing(raw R, raw gensgbI);
     S#"raw creation log" = Bag { FunctionApplication {rawQuotientRing, (raw R, raw gensgbI)} };
     S.cache = new CacheTable;
     S.basering = R.basering;
     S.flatmonoid = R.flatmonoid;
     S.numallvars = R.numallvars;
     S.ideal = I;
     S.baseRings = append(R.baseRings,R);
     commonEngineRingInitializations S;
     S.relations = gensI;
     S.isCommutative = R.isCommutative;
     if R.?SkewCommutative then S.SkewCommutative = R.SkewCommutative;
     S.generators = apply(generators S, m -> promote(m,S));
     if R.?generatorSymbols then S.generatorSymbols = R.generatorSymbols;
     if R.?generatorExpressions then S.generatorExpressions = R.generatorExpressions;
     if R.?indexStrings then S.indexStrings = applyValues(R.indexStrings, x -> promote(x,S));
     if R.?indexSymbols then S.indexSymbols = applyValues(R.indexSymbols, x -> promote(x,S));
     expression S := lookup(expression,R);
     S.use = x -> (
--	  try monoid S;
--	  if S.?monoid then (
--	       M := S.monoid;
--	       M + M := (m,n) -> S#1 * m + S#1 * n;
--	       M - M := (m,n) -> S#1 * m - S#1 * n;
--	       - M := m -> (- S#1) * m;
--	       scan(S.baseRings, A -> (
--		    A + M := (i,m) -> promote(i, S) + m;
--		    M + A := (m,i) -> m + promote(i, S);
--		    A - M := (i,m) -> promote(i, S) - m;
--		    M - A := (m,i) -> m - promote(i, S);
--		    A * M := (i,m) -> promote(i, S) * m;
--		    M * A := (m,i) -> m * promote(i, S);
--		    ));
--	       );
	  );
     runHooks(R,QuotientRingHook,S);
     S)

Ring / ZZ := (R,f) -> R / ideal f_R

Ring / RingElement := QuotientRing => (R,f) -> (
     if ring f =!= R then error "expected element of the same ring";
     R / ideal f)

Ring / List := Ring / Sequence := QuotientRing => (R,f) -> R / ideal matrix (R, {toList f})

presentation QuotientRing := Matrix => R -> (
     if R.?presentation then R.presentation else R.presentation = (
	  S := ambient R;
	  f := generators ideal R;
	  while class S === QuotientRing do (		    -- untested code
	       f = lift(f,ambient S) | generators ideal S;
	       S = ambient S;
	       );
	  f
	  )
     )

presentation PolynomialRing := R -> map(R^1,R^0,0)

presentation(QuotientRing,QuotientRing) := 
presentation(PolynomialRing,QuotientRing) := 
presentation(QuotientRing,PolynomialRing) := 
presentation(PolynomialRing,PolynomialRing) := (R,S) -> (
     if not (R === S or isQuotientOf(R,S)) then error "expected ring and a quotient ring of it";
     v := map(R^1,R^0,0);
     while S =!= R do (
	  v = v | lift(S.relations,R);
	  S = last S.baseRings;
	  );
     v)

codim PolynomialRing := opts -> R -> 0
codim QuotientRing := opts -> (R) -> codim( cokernel presentation R, opts)
dim QuotientRing := (R) -> (
     if isField R then 0
     else if R.?SkewCommutative then notImplemented()
     else dim ultimate(ambient,R) - codim R
     )

hilbertSeries QuotientRing := options -> (S) -> hilbertSeries(cokernel presentation S,options)
monoid QuotientRing := o -> (cacheValue monoid) (S -> monoid ambient S)
degreesRing QuotientRing := (cacheValue degreesRing) (S -> degreesRing ambient S)
QuotientRing_String := (S,s) -> if S#?s then S#s else (
     R := ultimate(ambient, S);
     S#s = promote(R_s, S))

generators QuotientRing := opts -> (S) -> (
     if opts.CoefficientRing === S then {}
     else apply(generators(ambient S,opts), m -> promote(m,S)))
char QuotientRing := (stashValue symbol char) ((S) -> (
     p := char ambient S;
     if p == 1 then return 1;
     if isPrime p or member(QQ,S.baseRings) then return if S == 0 then 1 else p;
     relns := presentation S;
     if relns == 0 then return char ring relns;
     if coefficientRing S =!= ZZ then notImplemented();
     g := generators gb relns;
     if g == 0 then return char ring g;
     m := g_(0,0);
     if liftable(m,ZZ) then lift(m,ZZ) else 0))
singularLocus(Ring) := QuotientRing => (R) -> (
     f := presentation R;
     A := ring f;
     A / (ideal f + minors(codim(R,Generic=>true), jacobian presentation R)))

singularLocus(Ideal) := QuotientRing => (I) -> singularLocus(ring I / I)

toField = method()
toField Ring := R -> (
     if R.?Engine and R.Engine then (
	  rawDeclareField raw R;
	  R / R := (x,y) -> x * y^-1;
	  )
     else notImplemented();
     R)

toField FractionField := F -> error "toField: fraction field is already a field"

getNonUnit = R -> if R.?Engine and R.Engine then (
     r := rawGetNonUnit raw R;
     if r != 0 then new R from r)

-- Local Variables:
-- compile-command: "make -C $M2BUILDDIR/Macaulay2/m2 "
-- End:
