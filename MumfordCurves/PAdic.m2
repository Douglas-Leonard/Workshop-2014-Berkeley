newPackage(
     "PAdic",
     Version => "0.1", 
     Date => "Jan 9, 2013",
     Authors => {{Name => "Nathan Ilten", 
	       Email => "nilten@math.berkeley.edu", 
	       HomePage => "http://http://math.berkeley.edu/~nilten/"},
          {Name => "Ralph Morrison",
	       Email => "morrison@math.berkeley.edu",
	       HomePage => "http://math.berkeley.edu/~ralph42/"},
	  {Name => "Qingchun Ren",
	       Email => "qingchun.ren@gmail.com",
	       HomePage => "http://math.berkeley.edu/~qingchun/"}
          },
     Headline => "a package for p-adic numbers",
     DebuggingMode => true
     )


---------------------------------------------------------------------------
-- COPYRIGHT NOTICE:
--
-- Copyright 2014 Nathan Owen Ilten, Ralph Morrison, and Qingchun Ren
--
--
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--
---------------------------------------------------------------------------




export {PAdicField,
     prime,
     PAdicFieldElement,
     valuation,
     relativePrecision,
     pAdicField,
     QQQ,
     toPAdicFieldElement,
     PAdicMatrix,
     pAdicMatrix,
     henselApproximation
     }

PAdicFields = new MutableHashTable -- save created PAdicFields here

---------------------------------------------
-- New types
---------------------------------------------

PAdicField = new Type of InexactField
PAdicFieldElement = new Type of HashTable
PAdicMatrix = new Type of MutableHashTable

---------------------------------------------
-- Creating PAdicFields
---------------------------------------------

new PAdicField from List := (PAdicField, inits) -> new PAdicField of PAdicFieldElement from new HashTable from inits

net PAdicField := A->"QQQ_"|toString(A#prime)

QQQ=new ScriptedFunctor
QQQ#subscript=i->(pAdicField i)

pAdicField = method()
pAdicField ZZ:=(p)->(
     if not isPrime p then error(toString(p)|" is not a prime!");
     if PAdicFields#?p then return PAdicFields#p;
     R := ZZ;
     A := new PAdicField from {(symbol prime) => p};
     PAdicFields#p=A;
     A
)

---------------------------------------------
-- non-exported auxilliary functions
---------------------------------------------

pValuation := method()
pValuation(ZZ,ZZ) := (n,p)->(
     b := n;
     v := 0;
     while b%p==0 do (
	  b = b//p;
	  v = v+1;
	  );
     v
     );

pValuation(QQ,ZZ) := (r,p)->(pValuation(numerator(r),p)-pValuation(denominator(r),p));

coarse := method();
coarse(PAdicFieldElement,ZZ) := (a,prec) -> (
     newPrecision := min(prec,precision a);
     newKeys := select(a#"expansion"_0,i->(i<newPrecision));
     newValues := for i in 0..#newKeys-1 list a#"expansion"_1#i;
     new (class a) from {"precision"=>newPrecision,
	  "expansion"=>{newKeys,newValues}}
     )

computeCarryingOver := (aKeys,aValues,prec,A) -> (
     	  p:=A#prime;
	  newKeys := ();
	  newValues := ();
	  carryingOver := 0;
	  aPointer := 0;
	  while (aPointer<#aKeys and aKeys#aPointer<prec) do (
	       currentKey := aKeys#aPointer;
	       currentValue := aValues#aPointer+carryingOver;
	       carryingOver = 0;
	       while currentValue!=0 do (
	     	    q := currentValue%p;
		    currentValue = (currentValue-q)//p;
		    if q!=0 then (
		         newKeys = (newKeys,currentKey);
		         newValues = (newValues,q);
		         );
		    currentKey = currentKey+1;
		    if (currentKey>=prec or 
		         ((aPointer+1<#aKeys) and 
                              (currentKey>=aKeys#(aPointer+1)))) then (
		         carryingOver = currentValue;
		         break;
		         );
	     	    );
	       aPointer = aPointer+1;
	       );
	  new A from {"precision"=>prec,
	       "expansion"=>{toList deepSplice newKeys,
		    toList deepSplice newValues}}
	  )

---------------------------------------------
-- Creating PAdicFieldElements
---------------------------------------------

toPAdicFieldElement = method()
toPAdicFieldElement (List,PAdicField) := (L,S) -> (
   n:=#L;
   local expans;
   if all(L,i->i==0) then expans={{},{}}    
   else expans=entries transpose matrix select(apply(n,i->{i,L_i}),j->not j_1==0);
   new S from {"precision"=>n,"expansion"=>expans}
   )
toPAdicFieldElement(ZZ,ZZ,PAdicField) := (n,prec,S) -> (
     computeCarryingOver({0},{n},prec,S)
     );
toPAdicFieldElement(QQ,ZZ,PAdicField) := (r,prec,S) -> (
     n := numerator r;
     d := denominator r;
     if d==1 then (
	  toPAdicFieldElement(n,prec,S)
	  ) else (
     	  p := S.prime;
     	  nVal := pValuation(n,p);
     	  dVal := pValuation(d,p);
     	  rVal := nVal-dVal;
     	  newRelativePrecision := prec-rVal;
     	  nPAdic := toPAdicFieldElement(n,nVal+newRelativePrecision,S);
     	  dPAdic := toPAdicFieldElement(d,dVal+newRelativePrecision,S);
     	  nPAdic/dPAdic
	  )
     );

---------------------------------------------
-- Methods for PAdicFieldElements
---------------------------------------------


net PAdicFieldElement := a->(expans:=a#"expansion";
  p:=(class a)#prime;
  keylist:=expans_0;
  ((horizontalJoin apply(#keylist,i->
  net(expans_1_i)|"*"|net p|
  (net keylist_i)^1|"+"))
|"O("|net p|(net(precision a))^1|")"))

toString PAdicFieldElement := a->(expans:=a#"expansion";
  p:=(class a)#prime;
  keylist:=expans_0;
  ((concatenate apply(#keylist,i->
  toString(expans_1_i)|"*"|toString p|"^"|
  (toString keylist_i)|"+"))
|"O("|toString p|"^"|(toString(precision a))|")"))


precision PAdicFieldElement := a->a#"precision";

valuation = method()
valuation PAdicFieldElement := a->(if #(a#"expansion"_0)>0 then return min a#"expansion"_0;
	  infinity);

relativePrecision = method()
relativePrecision PAdicFieldElement:= a -> (
	  if #(a#"expansion"_0)==0 then 0 else (precision a)-(valuation a));

PAdicFieldElement + PAdicFieldElement := (a,b) -> (
	  if not (class b)===(class a) then error "Elements must be in same PAdicField";
	  newPrecision := min(a#"precision",b#"precision");
          aKeys := a#"expansion"_0;
          aValues := a#"expansion"_1;
	  aTable := new HashTable from for i in 0..#aKeys-1 list (
	       if aKeys#i<newPrecision then {aKeys#i,aValues#i} else continue);
	  bKeys := b#"expansion"_0;
	  bValues := b#"expansion"_1;
	  bTable := new HashTable from for i in 0..#bKeys-1 list (
	       if bKeys#i<newPrecision then {bKeys#i,bValues#i} else continue);
	  s := merge(aTable,bTable,plus);
	  newKeys := sort keys s;
	  newValues := for i in newKeys list s#i;
	  computeCarryingOver(newKeys,newValues,newPrecision,class a)
	  )
     
PAdicFieldElement * PAdicFieldElement := (a,b)->(
	  if not (class b)===(class a) then error "Elements must be in same PAdicField";
	  newPrecision := min(precision a+min(precision b,valuation b),
     	    precision b+min(precision a,valuation a));
  aKeys := a#"expansion"_0;
  aValues := a#"expansion"_1;
  aTable := new HashTable from for i in 0..#aKeys-1 list {aKeys#i,aValues#i};
  bKeys := b#"expansion"_0;
  bValues := b#"expansion"_1;
  bTable := new HashTable from for i in 0..#bKeys-1 list {bKeys#i,bValues#i};
  combineFunction := (aKey,bKey)-> (
       s := aKey+bKey;
       if (s<newPrecision) then s else continue
       );
  prod := combine(aTable,bTable,combineFunction,times,plus);
  newKeys := sort keys prod;
  newValues := for i in newKeys list prod#i;
  computeCarryingOver(newKeys,newValues,newPrecision,class a)
  )


toPAdicInverse = method ()
toPAdicInverse(List,PAdicField):= (L,A) -> (
     	  p:=A#prime;
	  n:=#L;
	  i:=1;
	  b := new IndexedVariableTable;
	  s := new IndexedVariableTable;
	  b_0=(sub(1/sub(L_0,ZZ/p),ZZ)+p)%p; s_0=-1; S:={b_0};
	  while i<n do(
		   s_i=s_(i-1)+sum(0..i-1, j-> L_j*b_(i-1-j))*p^(i-1); 
		   b_i=(sub(-sub((s_i/p^i)+sum(1..i,j->L_j*b_(i-j)),ZZ/p)/sub(L_0,ZZ/p),ZZ)+p)%p;
		   S=append(S,b_i);
		   i=i+1);
	  S
	  )

inverse PAdicFieldElement := a->(
      A:=class a;
      if valuation(a)==infinity then (
	   error "You cannot divide by 0!";
	   );
      v := valuation(a);
      a = a<<(-v);
       i:=0;
       L:={};
       local c;
       while i<precision(a)
	 do(if member(i,a#"expansion"_0) 
	       then c=a#"expansion"_1#(position(a#"expansion"_0,j->j==i)) 
	       else c=0;
	    L=append(L,c);
	    i=i+1);
     toPAdicFieldElement(toPAdicInverse(L,A),A)<<(-v)
      )

 +PAdicFieldElement := a->a

 -PAdicFieldElement := a->(
      newValues := for i in a#"expansion"_1 list -i;
      computeCarryingOver(a#"expansion"_0,newValues,a#"precision",class a)
      )

 PAdicFieldElement - PAdicFieldElement:= (a,b)->(a+(-b))

 PAdicFieldElement / PAdicFieldElement:= (a,b)->(a*inverse(b))

 PAdicFieldElement ^ ZZ := (a,n)->(
      if n>=0 then (
	   m := 1;
	   c := a;
	   while n>0 do (
		if n%2==1 then m = m*c;
		n = n//2;
		c = c*c;
		);
	   m
	   ) else (
	   inverse(a^(-n))
	   )
      )

 PAdicFieldElement + ZZ := (a,n)->(
      b := toPAdicFieldElement(n,precision a,class a);
      a+b
      )

 ZZ + PAdicFieldElement := (n,a)->a+n

 PAdicFieldElement - ZZ := (a,n)->a+(-n)

 ZZ - PAdicFieldElement := (n,a)->(-a)+n

 PAdicFieldElement * ZZ := (a,n)->(
      p:=(class a)#prime;
      if n==0 then 0 else (
	   v := pValuation(n,p);
	   b := toPAdicFieldElement(n,v+relativePrecision a,class a);
	   a*b
	   )
      )
 
 ZZ * PAdicFieldElement := (n,a)->a*n
 
PAdicFieldElement / ZZ := (a,n)->(
     p:=(class a)#prime;
     if n==0 then (
	  error "You cannot divide by zero!";
	  ) else (
	  v := pValuation(n,p);
	  b := toPAdicFieldElement(n,v+max(1,relativePrecision a),class a);
	  a/b
	  )
     )

ZZ / PAdicFieldElement := (n,a)->n*inverse(a)

PAdicFieldElement + QQ := (a,r)->(
     b := toPAdicFieldElement(r,precision a,class a);
     a+b
     )

QQ + PAdicFieldElement := (r,a)->a+r

PAdicFieldElement - QQ := (a,r)->a+(-r)

QQ - PAdicFieldElement := (r,a)->(-a)+r

PAdicFieldElement * QQ := (a,r)->a*numerator(r)/denominator(r)

QQ * PAdicFieldElement := (r,a)->a*r

PAdicFieldElement / QQ := (a,r)->a/numerator(r)*denominator(r)

QQ / PAdicFieldElement := (r,a)->inverse(a)*numerator(r)/denominator(r)

PAdicFieldElement == PAdicFieldElement := (a,b) -> (
     if not class a === class b then return false;
     if precision a < precision b then (
	  a === coarse(b,precision a)
	  ) else if precision a > precision b then (
	  b === coarse(a,precision b)
	  ) else (
	  a === b
	  )
     )

PAdicFieldElement == ZZ := (a,n) -> (
     b := toPAdicFieldElement(n,precision a,class a);
     a === b
     )

ZZ == PAdicFieldElement := (n,a) -> a==n

PAdicFieldElement == QQ := (a,r) -> (
     b := toPAdicFieldElement(r,precision a,class a);
     a === b
     )

QQ == PAdicFieldElement := (r,a) -> a==r

PAdicFieldElement << ZZ := (a,n) -> (
     newPrecision := a#"precision"+n;
     newKeys := for i in a#"expansion"_0 list i+n;
     new (class a) from {"precision"=>newPrecision,
	  "expansion"=>{newKeys,a#"expansion"_1}}
     )

---------------------------------------------
-- Matrix stuff
---------------------------------------------

pAdicMatrix = method()
pAdicMatrix List := L -> (
   if #L == 0 then error "Expected a nonempty list.";
   if not isTable L then error "Expected a rectangular matrix.";
   rows := #L;
   cols := #(L#0);
   -- all entries must be in same pAdic field
   types := L // flatten / class // unique;
   if #types != 1 then error "Expected a table of either PAdicFieldElements over the same ring or PAdicMatrices.";
   local retVal;
   if ancestor(PAdicFieldElement,types#0) then (
      retVal = new PAdicMatrix from hashTable {
                                            (symbol matrix, L),
                                   	    (symbol cache, new CacheTable from {})};
    
   )
   else if types#0 === PAdicMatrix then (
      -- this block of code handles a matrix of matrices and creates a large matrix from that
      blockEntries := applyTable(L, entries);
      -- this is a hash table with the sizes of the matrices in the matrix
      sizeHash := new HashTable from flatten apply(rows, i -> apply(cols, j -> (i,j) => (#(blockEntries#i#j), #(blockEntries#i#j#0))));
      -- make sure the blocks are of the right size, and all matrices are defined over same ring.
      if not all(rows, i -> #(unique apply(select(pairs sizeHash, (e,m) -> e#0 == i), (e,m) -> m#0)) == 1) then
         error "Expected all matrices in a row to have the same number of rows.";
      if not all(cols, j -> #(unique apply(select(pairs sizeHash, (e,m) -> e#1 == j), (e,m) -> m#1)) == 1) then
         error "Expected all matrices in a column to have the same number of columns.";
      -- now we may perform the conversion.
      newEntries := flatten for i from 0 to rows-1 list
                            for k from 0 to (sizeHash#(i,0))#0-1 list (
                               flatten for j from 0 to cols-1 list
                                       for l from 0 to (sizeHash#(0,j))#1-1 list blockEntries#i#j#k#l
                            );
      retVal = new PAdicMatrix from hashTable {
	                                    (symbol matrix, newEntries),
                                   	    (symbol cache, new CacheTable from {})};
   );
   retVal
)


PAdicMatrix * PAdicMatrix := (M,N) -> (
   colsM := length first M.matrix;
   rowsN := length N.matrix;
   if colsM != rowsN then error "Maps not composable.";
   rowsM := length M.matrix;
   colsN := length first N.matrix;
   local prod;
   prod = pAdicMatrix table(toList (0..(rowsM-1)), toList (0..(colsN-1)), (i,j) -> sum(0..(colsM-1), k -> ((M.matrix)#i#k)*((N.matrix)#k#j)));
   prod
   )


PAdicMatrix ^ ZZ := (M,n) -> product toList (n:M)

PAdicMatrix + PAdicMatrix := (M,N) -> (
   colsM := length first M.matrix;
   rowsN := length N.matrix;
   rowsM := length M.matrix;
   colsN := length first N.matrix;
   if colsM != colsN or rowsM != rowsN then error "Matrices not the same shape.";
   MpN := pAdicMatrix apply(toList(0..(rowsM-1)), i -> apply(toList(0..(colsM-1)), j -> M.matrix#i#j + N.matrix#i#j));
   MpN
)


entries PAdicMatrix := M -> M.matrix
transpose PAdicMatrix := M -> (
    Mtrans := pAdicMatrix transpose M.matrix;
    Mtrans
)

net PAdicMatrix := M -> net expression M
expression PAdicMatrix := M -> MatrixExpression applyTable(M.matrix, expression)

---------------------------------------------
-- Hensel approximation
---------------------------------------------

henselApproximation = method()
henselApproximation (RingElement,ZZ,ZZ,ZZ) := (f,r,n,p) ->  (
	x:=(ring f)_0;
	f':=diff(x,f);
	g:= a->sum(1..(degree(f))_0, j->coefficient(x^j,f)*a^j)+coefficient(x^0,f);
	g':= a->sum(1..(degree(f'))_0, j->coefficient(x^j,f')*a^j)+coefficient(x^0,f');
	if not sub(g(r),ZZ/p) == sub(0,ZZ/p) then error "The starting value is not a root";
	if sub(g'(r),ZZ/p) == sub(0,ZZ/p) then error "This is a double root";
	local s; s=toPAdicFieldElement(r,n,QQQ_p); i:=0;
	while i<n+1 do (s=s-(g(s)/g'(s));i=i+1);
	s)

---------------------------------------------
-- Documentation
---------------------------------------------

beginDocumentation()

document {
     Key => PAdic,
     Headline => "a package for p-adic numbers",
     PARA{
    "This package facilitates basic computations with p-adic numbers, including
    arithmetic and a simple form of Hensel lifting."}}

document {
     Key =>PAdicField,
     Headline=> "a new type of InexactField used for p-adic fields",
     PARA{"A ",TT "PAdicField"," is a new type of ",TO InexactField," 
	  used for p-adic fields. When a new ",TT "PAdicField"," is created,
	  it is stored for future reference."},
     PARA{"A new ",TT "PAdicField"," may be created with ",TO QQQ,"."}
     }


document {
     Key =>QQQ,
     Headline=> "a scripted functor for creating p-adic fields",
     PARA{TT "QQQ"," is ",ofClass ScriptedFunctor," used for creating p-adic
	  fields. ",TT "QQQ_p"," refers to the field of p-adic numbers, where
	  p is a prime. ",TT "QQQ"," is a synonym for ",TO pAdicField,"."},
     EXAMPLE {"QQQ_7"}
          }

document {
     Key =>pAdicField,
     Inputs => {"p" => ofClass ZZ},
     Outputs => {"A" => ofClass PAdicField},
     Usage => "A=pAdicField(p)",
     Headline=> "a method for creating p-adic fields",
     PARA{TT "pAdicField"," creates ",ofClass PAdicField," with
	  respect to the prime ",TT "p","." },
     EXAMPLE {"pAdicField(7)"}
     }

document {
     Key =>henselApproximation,
     Inputs => {"f" => ofClass RingElement,"r" => ofClass ZZ,"n" => ofClass ZZ,"p" => ofClass ZZ},
     Outputs => {"s" => ofClass PAdicFieldElement},
     Usage => "s=henselApproximation(f,r,n,p)",
     Headline=> "a method for approximating p-adic roots",
     PARA{TT "henselApproximation"," approximates to precision ",TT "n"," a ",TT "p","-adic root of a polynomial
	  ",TT "f"," congruent to ",TT "r mod p",".  The polynomial must have integer coefficients, 
	  and ",TT "r"," 
	  must be a simple root of ",TT "f mod p","." },
     EXAMPLE {"ZZ[x];",
	  "a=henselApproximation(x^2+1,3,6,5)",
	  "a^2+1==0"}
     }




document {
     Key =>{valuation,(valuation,PAdicFieldElement)},
     Inputs => {"x" => ofClass PAdicFieldElement},
     Outputs => {"n" => ofClass ZZ},
     Usage => "n=valuation(x)",
     Headline=> "calculates the valuation of a p-adic number",
     PARA{TT "valuation"," returns the exponent of the smallest
	  power of p in the p-adic representation of ",TT "x"," for
	  which the coefficient is non-zero."},
     EXAMPLE {"x=toPAdicFieldElement(36/98,5,QQQ_7)",
	  "valuation x"}
     }

document {
     Key =>{relativePrecision,(relativePrecision,PAdicFieldElement)},
     Inputs => {"x" => ofClass PAdicFieldElement},
     Outputs => {"n" => ofClass ZZ},
     Usage => "n=valuation(x)",
     Headline=> "calculates the valuation of a p-adic number",
     PARA{TT "relativePrecision"," returns the difference of the
	   ",TO precision," and the ",TO valuation," of ",TT "x",", unless
	   all coefficients are zero, in which case zero is returned."},
     EXAMPLE {"x=toPAdicFieldElement(36/98,5,QQQ_7)",
	  "relativePrecision x"} 
     }

document {
     Key =>(precision,PAdicFieldElement),
     Inputs => {"x" => ofClass PAdicFieldElement},
     Outputs => {"n" => ofClass ZZ},
     Usage => "n=precision(x)",
     Headline=> "calculates the precision of a p-adic number",
     PARA{TT "precision"," returns the exponent of the smallest
	  power of p in the p-adic representation of ",TT "x"," for
	  which the coefficient is unknown."},
     EXAMPLE {"x=toPAdicFieldElement(36/98,5,QQQ_7)",
	  "precision x"}           
     }

document {
     Key =>PAdicFieldElement,
     Headline=> "type of elements found in a PAdicField",
     PARA{"A ",TT "PAdicFieldElement"," is ",ofClass HashTable," representing
	  an element of some ",TO PAdicField,". The key ",TT toString("precision"),"
	   stores an integer representing the ",TO precision," of the element. The
	   key ",TT toString("expansion")," stores ",ofClass List," whose first 
	   element is a list of the exponents of p which appear, and the second
	   element is a list of the corresponding coefficients."}
     }


----------------------------
--Package test cases
----------------------------

TEST ///
assert(QQQ_3===QQQ_3);
assert(QQQ_3=!=QQQ_5);
///

TEST ///
a := toPAdicFieldElement({1,2,3,4,5},QQQ_7);
assert(a#"precision"==5);
assert(a#"expansion"_0=={0,1,2,3,4});
assert(a#"expansion"_1=={1,2,3,4,5});
b := toPAdicFieldElement({3,0,0,3,0,0},QQQ_7);
assert(b#"precision"==6);
assert(b#"expansion"_0=={0,3});
assert(b#"expansion"_1=={3,3});
c := toPAdicFieldElement({0,0,0},QQQ_7);
assert(c#"precision"==3);
assert(c#"expansion"_0=={});
assert(c#"expansion"_1=={});
///

TEST ///
a := toPAdicFieldElement({1,2,3,4,5},QQQ_7);
b := toPAdicFieldElement({1,2,3,4,5},QQQ_7);
c := toPAdicFieldElement({1,2,3,4,5,0},QQQ_7);
d := toPAdicFieldElement({1,2,3,4,5,1},QQQ_7);
assert(a==b);
assert(a===b);
assert(a==c);
assert(a=!=c);
assert(a==d);
assert(c!=d);
assert(not a!=b);
assert(not a=!=b);
assert(not a!=c);
assert(not a===c);
assert(not a!=d);
assert(not c==d);
///

TEST ///
a := toPAdicFieldElement({1,2,3,4,5},QQQ_7);
assert(a==1+2*7+3*7^2+4*7^3+5*7^4);
assert(1+2*7+3*7^2+4*7^3+5*7^4+348*7^23==a);
assert(a!=1+2*7+3*7^2+4*7^3+4*7^4);
///

TEST ///
a := toPAdicFieldElement({1,2,3,4,5},QQQ_7);
b := toPAdicFieldElement(1+2*7+3*7^2+4*7^3+5*7^4,5,QQQ_7);
assert(a==b);
assert(1+2*7+3*7^2+4*7^3+5*7^4==a);
c := toPAdicFieldElement({0,0,0,0,0},QQQ_7);
d := toPAdicFieldElement(0,5,QQQ_7);
assert(c==d);
assert(0==c);
e := toPAdicFieldElement({6,6,6,6,6},QQQ_7);
f := toPAdicFieldElement(-1,5,QQQ_7);
assert(e==f);
assert(-1==e);
///

TEST ///
a := toPAdicFieldElement(123456789,10,QQQ_7);
b := toPAdicFieldElement(987654321,15,QQQ_7);
assert(a+b==123456789+987654321);
assert((+a)==(+123456789));
assert((-a)==(-123456789));
assert(a-b==123456789-987654321);
assert(a*b==123456789*987654321);
c := toPAdicFieldElement(0,8,QQQ_7);
assert(c+c==0);
assert(c+a==a);
assert(-c==c);
assert(a-c==a);
assert(c-a==-a);
assert(a*c==0);
///

TEST ///
a := toPAdicFieldElement(123456789,10,QQQ_7);
assert(a^0==1);
assert(a^1==a);
assert(a^2==a*a);
assert(a^10==123456789^10);
c := toPAdicFieldElement(0,8,QQQ_7);
assert(c^0==1);
assert(c^10==0);
///

TEST ///
a := toPAdicFieldElement(-123,10,QQQ_7);
b := toPAdicFieldElement(246,15,QQQ_7);
c := toPAdicFieldElement(0,8,QQQ_7);
assert(b/a==-2);
assert(inverse(inverse(b))==b);
assert(c/a==0);
///

TEST ///
a := toPAdicFieldElement(1/2,10,QQQ_7);
b := toPAdicFieldElement(1/7,15,QQQ_7);
c := toPAdicFieldElement(0,8,QQQ_7);
assert(a==1/2);
assert(a!=1/7);
assert(b==1/7);
assert(0/1==c);
assert(not a!=1/2);
assert(not a==1/7);
assert(not b!=1/7);
assert(not 0/1!=c);
///

TEST ///
a := toPAdicFieldElement(1/2,10,QQQ_7);
b := toPAdicFieldElement(1/7,15,QQQ_7);
c := toPAdicFieldElement(0,8,QQQ_7);
assert(a*2==1);
assert(b*7==1);
assert((1/3+a)*6==5);
assert((a-b)*14==5);
assert((1/2)*b/a==b);
assert((1/49)/b/b==1);
assert((c+1/2)==a);
assert(c*132*123*134/1234==0);
///

TEST ///
a := toPAdicFieldElement(3,0,QQQ_7);
assert(a#"expansion"_0=={});
///

TEST ///
a := toPAdicFieldElement(-123,10,QQQ_7);
assert(precision a==10);
assert(valuation a==0);
assert(relativePrecision a==10);
b := toPAdicFieldElement(23*7,10,QQQ_7);
assert(precision b==10);
assert(valuation b==1);
assert(relativePrecision b==9);
c := toPAdicFieldElement(0,10,QQQ_7);
assert(precision c==10);
assert(valuation c==infinity);
assert(relativePrecision c==0);
///

TEST ///
a := toPAdicFieldElement(-123,10,QQQ_7);
b := toPAdicFieldElement(23*7,7,QQQ_7);
assert(precision(a+b)==min(precision a,precision b));
assert(precision(-a)==precision(a));
assert(precision(a-b)==min(precision a,precision b));
assert(relativePrecision(a*b)==min(relativePrecision(a),relativePrecision(b)));
assert(relativePrecision(inverse(a))==relativePrecision(a));
assert(relativePrecision(a/b)==min(relativePrecision(a),relativePrecision(b)));
assert(relativePrecision(b^10)==relativePrecision(b));
assert(precision(3489723-b)==precision(b));
assert(relativePrecision(3243523/b)==relativePrecision(b));
///

TEST ///
a := toPAdicFieldElement(-123,10,QQQ_7);
assert((a<<1)==a*7);
assert((a<<15)!=0);
assert(((a<<23)<<(-23))==a);
///

TEST ///
a := toPAdicFieldElement(123456789,10,QQQ_7);
assert(a^10*a^(-10)==1);
assert(a^3*a^7/a^4*a^(-5)==a);
///

TEST ///
R := ZZ[x];
a := henselApproximation(x^2+1,3,6,5);
assert(precision a==6);
assert(a#"expansion"_1#0==3);
assert(a^2+1==0);
b := henselApproximation(x^2+6*x+5,0,6,5);
assert(b==-5);
c := henselApproximation(x^3-7,3,6,5);
assert(precision c==6);
assert(c#"expansion"_1#0==3);
assert(c^3==7);
///

TEST ///
a11 := toPAdicFieldElement(1,5,QQQ_3);
a12 := toPAdicFieldElement(2,5,QQQ_3);
a21 := toPAdicFieldElement(3,5,QQQ_3);
a22 := toPAdicFieldElement(4,5,QQQ_3);
b11 := toPAdicFieldElement(5,5,QQQ_3);
b12 := toPAdicFieldElement(6,5,QQQ_3);
b21 := toPAdicFieldElement(7,5,QQQ_3);
b22 := toPAdicFieldElement(8,5,QQQ_3);
A := pAdicMatrix {{a11,a12},{a21,a22}};
B := pAdicMatrix {{b11,b12},{b21,b22}};
assert(entries(A+B)=={{a11+b11,a12+b12},{a21+b21,a22+b22}});
assert(entries(transpose(A))=={{a11,a21},{a12,a22}});
assert(entries(A*B)=={{a11*b11+a12*b21,a11*b12+a12*b22},{a21*b11+a22*b21,a21*b12+a22*b22}});
///

TEST ///
a11 := toPAdicFieldElement(1,5,QQQ_3);
a12 := toPAdicFieldElement(2,5,QQQ_3);
a21 := toPAdicFieldElement(3,5,QQQ_3);
a22 := toPAdicFieldElement(4,5,QQQ_3);
A := pAdicMatrix {{a11,a12},{a21,a22}};
assert(entries(A^1)==entries(A));
assert(entries(A^5)==entries(A*A*A*A*A));
///

end

----------------------------
--Friday Demonstration
----------------------------
restart
load "~/Workshop-2014-Berkeley/MumfordCurves/pAdic.m2"

--for any p have field QQQ_p

QQQ_23

--can make p-adics from rationals:
x=toPAdicFieldElement(1,100,QQQ_23)
y=toPAdicFieldElement(-345,5,QQQ_23)
z=toPAdicFieldElement(-345,6,QQQ_23)

y==z
y===z


w=toPAdicFieldElement(17/(4*23^5),30,QQQ_23)
precision w
valuation w


--addition, subtraction, multiplication, and division
y*w
y*z
y-w
y/w

--QQQ_23 only gets created once!
ZZ[s]===ZZ[s]
QQQ_27===QQQ_27

--basic matrix operations
M=pAdicMatrix {{x,y},{z,w*z}}
M+M
M*M
M^5






----------------------------
--Qingchun's testing area
----------------------------

restart
loadPackage "pAdic"
ZZ[x]
henselApproximation(x^2+1,2,3,5)
Q3 = pAdicField(3)
x = toPAdicFieldElement({1,2,0,1,0},Q3);
y = toPAdicFieldElement(0,3,Q3);
z = toPAdicFieldElement(10,10,Q3);
w = toPAdicFieldElement(1/2,5,Q3);
a = toPAdicFieldElement(10,100,Q3)
assert(x+y==y+x);
assert(a^100*a^(-100)==1);
assert(14/w*w==14);
assert(1/6+w-1/2+1/3==w);
assert((6/9)*w/(1/3)==w+w);
end

----------------------------
--Nathan's testing area
----------------------------
restart
loadPackage "pAdic"


x=toPAdicFieldElement({1,2,2,2},QQQ_3)

A=pAdicMatrix {{x,x}}
B=pAdicMatrix {{x},{x}}
C=pAdicMatrix {{A},{A}}
C^2

peek (A*B)
peek oo
class x
QQQ_3


x=toPAdicFieldElement({1,0,0,0,0,0},QQQ_3)
inverse x

Q3
QQQ_3===Q3
x-x

x=toPAdicFieldElement({0,0,0,0,0,0},Q3)

valuation x
precision x
relativePrecision x
valuation x
f=x


ZZ[y]
f=y^2+y^6
jacobian f
help jacobian
diff(y,f)
help diff

--------------------------------
--Ralph's finding inverses area
--------------------------------

--Let's say we want to find the inverse of a=a_0+a_1*p+a_2*p^2+... up to the 6th p-adic place.
--In this example we'll take p=7.  It's a coincidence that p=7 and we're taking i<7, since
--i goes up desired precision +1, which happens to be 6+1=7.
 R=ZZ; p=7; a_0=6; a_1=0; a_2=3; a_3=1; a_4=1; a_5=5; a_6=5; S=R/p;
i=1; b_0=(sub(1/sub(a_0,S),R)+p)%p; s_0=-1; 
while i<7 do(s_i=s_(i-1)+sum(0..i-1, j-> a_j*b_(i-1-j))*p^(i-1);
b_i=(sub(-sub((s_i/p^i)+sum(1..i,j->a_j*b_(i-j)),S)/sub(a_0,S),R)+p)%p;i=i+1)

--Running the code computes b_0, b_1,..., which gives a^-1=b=b_0+b_1*p+b_2*p^2+...
--This is finding inverses from just lists:
 toPAdicInverse = method ()
 
 toPAdicInverse List := L -> (
	       n=#L;
	       i=1; b_0=(sub(1/sub(L_0,ZZ/p),ZZ)+p)%p; s_0=-1; S={b_0};
	       while i<n do(
			s_i=s_(i-1)+sum(0..i-1, j-> L_j*b_(i-1-j))*p^(i-1); 
	       		b_i=(sub(-sub((s_i/p^i)+sum(1..i,j->L_j*b_(i-j)),ZZ/p)/sub(L_0,ZZ/p),ZZ)+p)%p;
			S=append(S,b_i);
			i=i+1);
	       S
	       )
--Hensel code rough draft
henselApproximation = method()
henselApproximation (ZZ[x],ZZ,ZZ,ZZ) := (f,r,n,p) ->  (
	x:=(ring f)_0;
	f':=diff(x,f); print f';
	g:= a->sum(0..(degree(f))_0, j->coefficient(x^j,f)*a^j);
	g':= a->sum(0..(degree(f'))_0, j->coefficient(x^j,f')*a^j);
	local s; s=toPAdicFieldElement(r,n,QQQ_p); i=0;
	while i<n+1 do ( print i; s=s-(g(s)/g'(s));i=i+1);
	s)
