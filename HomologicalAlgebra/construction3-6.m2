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

     
     
