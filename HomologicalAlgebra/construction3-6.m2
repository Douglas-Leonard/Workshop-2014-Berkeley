--natural map from a module to its double dual courtesy of Frank Moore
restart
bidualityMap = M -> (
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
     if g >= max P then return P
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

-- take a complex concentrated in non-negative degrees and augment
-- the cokernel of the differential in degree 1
augmentChainComplex = method(TypicalValue => ChainComplex)
augmentChainComplex (ChainComplex) := Q -> (
     augQ := new ChainComplex;
     augQ.ring = Q.ring;
     N := coker Q.dd_1 ;
--     augQ.dd_1 = map(N, Q_1,id_(Q_1)); fails; wrong indexing
     augQ.dd_(0) = map(N, Q_0,id_(Q_0));
--     augQ.dd_(-1) = inducedMap(R^0, N, id_(cover N)); 
--     the degree -1 differential is already made to be 0 via the previous 
--     construction
     for i from 1 to max Q do (
	  augQ.dd_i = Q.dd_i
	  );
     augQ
)

-- this example is making no sense
-- The map created by hand composes just fine,
-- but the map created using the resolution won't compose
R = QQ[x]/ideal(x^3)
M = coker matrix {{x^2}}
C_1 = map(M,R^1,id_(R^1)) --I thought this should be -id_(R^1), but when I recreated
--the resolution the map was positive
A = map(M,M,matrix{{x}})
D = resolution M
D' = augmentChainComplex(D)
A*C_1 -- this composes
A*(D'.dd_0) -- this doesn't compose
C_1 == D'.dd_0 -- this returns true
C_1 === D'.dd_0 --this returns false



R = QQ[x,y,z]
M = coker matrix {{x*y*z}}
C = resolution(M, LengthLimit => 5)
--Q = resolution(M, LengthLimit => 5)
D = augmentChainComplex C     

-- given a map between modules, lift the map to a chain map between
-- the resolutions
liftModuleMap = method(TypicalValue => ChainComplexMap)
liftModuleMap (ChainComplex, ChainComplex, Matrix) := (Q,P,A) -> (
     Q' := (augmentChainComplex Q)[-1];
     P' := (augmentChainComplex P)[-1];
     tempLift := (extend(Q', P',A))[1]; -- yields "maps not composible"
     tempLift_0 = 0*tempLift_0;
     tempLift
     )

R = QQ[x]/ideal(x^3)
M = coker matrix {{x^2}}
C = resolution M
A = map(M,M,matrix{{x}})
C' = augmentChainComplex(C)[-1]
target A == C'_0 and source A == C'_0
liftModuleMap(C,C,A)
P = C
Q = C

-- CompleteResolution = new Type of MutableHashTable
-- globalAssignment CompleteResolution

-- what follow is version 0.1 of construction 3.6 from Avramov & Martsinkovsky
-- later versions will turn the construction into an object of the type
-- CompleteResolution
construction = method(TypicalValue => ChainComplexMap 
--     ,Options => {LengthLimit => "3"}
)
construction (ZZ, Module) := (g, M) -> (
--    n = (opts.LengthLimit);
     n = g+2--;
     P = resolution(M, LengthLimit => max(n,g+2))--;  -- ditto
     Pd = dual P--;
     G = omega(g, P)--;
     Gd = dual G--;
     L = resolution(Gd, LengthLimit => max(g+2, n))--; -- check that max works
     Ld = dual L--;
     toLiftFirstFactor = map(image(Pd.dd_(-g+1)), omega(1-g, Pd), id_(Pd_(1-g)))--;  
     K = kernel(Pd.dd_(-g))--;
     I = image(Pd.dd_(-g+1))--;
     h = gens K--;
     phi = Pd.dd_(-g+1)//h--;
     toLiftSecondFactor = map (K, I, phi)--;
     kappa = toLiftSecondFactor * toLiftFirstFactor--;
     Pt = truncateComplex(g, P)--;
     Ptd = dual Pt--;
     Q = Ptd[-(g-1)]--;
--     psi = (kappa * gens source kappa ) // gens Gd 
     kappaLifted = extend(L, Q, kappa)--; BROKEN !!!
     w = map(G, P_g, id_(P_g))--;
     d = bidualitymap(G)--;
     lambda = map(HH_0(L), L_0, id_(L_0))--;
     lambdaDual = dual lambda--;
     
     cRes = id_(resolution (ring M)^0)--;
     
     --Jason's portion
     for j from (g-1-max(g+2, n)) to g-1 do (
	  cRes.target_j = P_j--;
	  cRes.target.dd_j = P.dd_j--;
	  cRes.source_j = Ld_(g-1-j)--;
	  cRes.source.dd_j = Ld_(g-1-j)--;
	  cRes_j = kappaLifted_(g-1-j)--;
	  )--;     
     --Kat's portion
     for i from g+1 to max(g+2,n) do (
	  cRes.source.dd_i=P.dd_i--;
	  cRes.target.dd_i=P.dd_i--;
	  cRes_i=id_(P_i)--;
	  )--;
     
     --for portion in middle (i.e. the degree g part)
     cRes.target.dd_g=P.dd_i--;
     cRes.source.dd_g=lambdaDaul*d*w--;
     cRes_g=id_(P_g)--;
     cRes
     )
     
     
--restart 
kk = ZZ/101    
R = kk[x,y,z]
S = R/ideal (x*y*z)
M = coker map(S^1, , {gens S})
g = 2
n = 2
construction(2,K)


C = resolution(R^1)
K = id_C
M = coker matrix {{x,y,z}}
C = resolution M
D = C[1]

     
     
