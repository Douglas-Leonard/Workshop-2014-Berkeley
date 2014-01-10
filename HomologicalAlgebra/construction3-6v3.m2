--natural map from a module to its double dual courtesy of Frank Moore
bidualityMap = method()
bidualityMap := M -> (
   R := ring M;
   Md := Hom(M,R^1);
   Mdd := Hom(Md,R^1);
   W := coker relations Mdd;
   gensMdd := map(W,source gens Mdd,gens Mdd);
   tempMap := matrix apply(numgens M, i -> 
       {map(R^1,Md,matrix {apply(numgens Md, j ->
            (homomorphism Md_{j})*(M_{i}))},Degree=>(degrees M)_i)});
   retVal := map(Mdd,M,(transpose matrix tempMap) // gensMdd);
   retVal
   )

-- find the nth syzygy of a chain complex; the cokernel of the (n+1)'st
-- differential
omega = method()
omega(ZZ,ChainComplex) := (n,C) -> (
     coker C.dd_(n + 1)
)

-- code by Kat to truncate a chain complex; all components of the complex
-- in degrees >= g will be made to 0.
truncateComplex = method()
truncateComplex(ZZ,ChainComplex) := (g,P) -> (
     if g > max P then return P
--     if g <= min P then return image(0*id_P)
     else (
	  K:=new ChainComplex;
	  K.ring=P.ring;
	  for i from min P+1 to max P do (
	       if i < g then K.dd_i=P.dd_i;
	       );
	  return K
	  )
)

--from a module, build and augment a resolution of the module
augmentChainComplex = 
     method(TypicalValue => ChainComplex, Options => {LengthLimit =>2}
	  )
augmentChainComplex (Module) := opts -> M -> (
     Q := resolution(M, LengthLimit => opts.LengthLimit);
     augQ := Q;
     augQ.dd_(0) = map(M, Q_0,id_(Q_0));
     augQ
)

-- given a map between modules, lift the map to a chain map between
-- the resolutions
liftModuleMap = method(TypicalValue => ChainComplexMap)
liftModuleMap (Module, Module, Matrix) := (N,M,A) -> (
     Q := (augmentChainComplex N)[-1];
     P := (augmentChainComplex M)[-1];
     tempLift := (extend(Q,P,A))[1]; 
--     tempLift_0 = 0*tempLift_0;
     tempLift
     )

--version 3 is below, implementing a better way of constructing
--the final chain complex map from the constructed pieces.
constructionV3 = 
method(TypicalValue => ChainComplex
     , Options => {LengthLimit => 2}
     )
constructionV3 (ZZ,Module):= 
     opts -> 
     (g,M) -> (
     if g <= 0
     then error "expected g>0 for a syzygy of positive degree";
     n:= opts.LengthLimit;
     P := resolution(M, LengthLimit=>max(n,g+2));
--     P := resolution(M, LengthLimit=>g+2);
     G := omega(g,P);
     Pd := dual P;
     toLiftFirstFactor := map(image(Pd.dd_(-g+1)), omega(1-g, Pd), id_(Pd_(1-g)));
     K := kernel(Pd.dd_(-g));
     I := image(Pd.dd_(-g+1));
     h := gens K;
     phi := Pd.dd_(-g+1)//h;
     toLiftSecondFactor := map (K, I, phi);
     kappa := toLiftSecondFactor * toLiftFirstFactor;
--     Pt := truncateComplex(g, P);
--     Ptd := dual Pt;
--     Q := Ptd[-(g-1)];
     kappaLifted = liftModuleMap(kappa.target,kappa.source,kappa);
     w := map(G, P_g, id_(P_g));
     d := bidualityMap(G);
     Gd := dual G;
     L := resolution(Gd, LengthLimit => max(g+2, n));
     Ld := dual L;
--     L := resolution(Gd, LengthLimit => g+2);
    lambda := map(Gd, L_0, id_(L_0));
    lambdaDual := dual lambda; -- now implemented in M2 1.6
--here are the significant changes to version 3;
--build the source of the chain complex map
    S := new ChainComplex;
    -- put in the ring
    S.ring = M.ring;
    --put in the modules
    for i from (g-1-max(g+2,n)) to g-1 do (
	S_i = Ld_(-g+1+i); 
	);
    for i from g to max(g+2,n) do (
	S_i = P_i;
	);
   -- S_g = P_g;
    --put in the differentials
    for i from (g-1-max(g+2,n)) to g-1 do (
	S.dd_i = Ld.dd_(-g+1+i);
	);   
    for i from g+1 to max(g+2,n) do (
    	S.dd_i = P.dd_i;	
    	);
    S.dd_g = lambdaDual*d*w;
 --build the target of the chain complex map
--actually this is already built as it is P    
--build the maps between the source and target;
    --name the maps consistently
    for i from (g-1-max(g+2,n)) to g-1 do(
	f_i = dual kappaLifted_(-g+1+i);
	);
    for i from g to max(g+2,n) do (
	f_i = id_(P_i);
	);

--output P, S, and f_i as a hash table
output := new MutableHashTable;
output.ff = new MutableHashTable;
output.source = S;
output.target = P;
for i from (g-1-max(g+2,n)) to max(g+2,n) do (
    output.ff#i = f_i
    );
output
    --make the chain complex map    
--    cRes := map (P,S,i-> f_i); 
--    cRes
    )

buildMaps = method()
buildMaps(ZZ) := j -> (
    mapsList := ();
    if (j > max(g+2,n) 	or j< (g-1)-max(g+2,n)) 
    then error "integer out of bounds";
    for i from (g-1-max(g+2,n)) to max(g+2,n) do (
    if i == j then mapsList = append(mapsList, f_i)
    else mapsList = append(mapsList, null);
    );
    mapsList
    )
buildComplex = method()
buildComplex(ZZ) := t -> (
    mapsList := buildMaps(t);
    C = map(P,S,i -> mapsList_(i+(g-1+1)));
    C
    )
sign = method()
sign(ZZ) := j -> (
    if j >= 0 then return 1 else return (-1))

end
--------Test Code----------
restart
load "construction3-6v3.m2"
R = QQ[x,y,z]/ideal(x*y*z)
M = coker map(R^1,,{gens R})
g = 3
n = 5
M = coker vars R
C = constructionV3(g,M)
--This code here checks if the source and target of the f_i maps are what they should be
for i from (g-1-max(g+2,n)) to max(g+2,n) do (
      print (i, source f_i === S_i, target f_i === P_i)
      )
--a less strict test;
for i from (g-1-max(g+2,n)) to max(g+2,n) do (
      print (i, source f_i == S_i, target f_i == P_i)
      )  

mapsList = ()
for i from (g-1-max(g+2,n)) to max(g+2,n) do (
    mapsList = append(mapsList,-(sign i)*(id_(R^1))))
--    mapsList = append(mapsList,id_(R^(1))))
mapsList
P = chainComplex(mapsList)[g]
