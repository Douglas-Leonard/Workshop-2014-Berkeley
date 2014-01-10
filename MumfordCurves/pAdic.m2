PAdicFields = new MutableHashTable

PAdicField = new Type of InexactField
PAdicFieldElement = new Type of HashTable

new PAdicField from List := (PAdicField, inits) -> new PAdicField of PAdicFieldElement from new HashTable from inits

net PAdicField := A->"QQQ_"|toString(A#prime)

valuation = method()
relativePrecision = method()

pAdicField = method()
pAdicField ZZ:=(p)->(
     if PAdicFields#?p then return PAdicFields#p;
     R := ZZ;
     A := new PAdicField from {(symbol prime) => p};
     precision A := a->a#"precision";
     valuation A := a->(if #a#"expansion">0 then return min a#"expansion"_0;
	  infinity);
     relativePrecision A:= a -> (precision a)-(valuation a);
     net A := a->(expans:=a#"expansion";
	  keylist:=expans_0;
       	  ((concatenate apply(#keylist,i->
		  toString(expans_1_i)|"*"|toString p|"^"
		  |toString keylist_i|"+"))
		|"O("|toString p|"^"|toString(precision a)|")"));
     computeCarryingOver := (aKeys,aValues,prec) -> (
	  newKeys := ();
	  newValues := ();
	  carryingOver := 0_R;
	  aPointer := 0;
	  while (aPointer<#aKeys and aKeys#aPointer<=prec) do (
	       currentKey := aKeys#aPointer;
	       currentValue := aValues#aPointer+carryingOver;
	       carryingOver = 0_R;
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
	  );
     new A from Sequence := (A',a) -> (
	  computeCarryingOver(a#0,a#1,a#2)
	  );
     A + A := (a,b) -> (
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
	  computeCarryingOver(newKeys,newValues,newPrecision)
	  );
     A * A := (a,b)->(
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
	  computeCarryingOver(newKeys,newValues,newPrecision)
	  );
     toPAdicInverse := method ();
     toPAdicInverse List := L -> (
	       n=#L;
	       i=1; b_0=(sub(1/sub(L_0,ZZ/p),ZZ)+p)%p; s_0=-1; S={b_0};
	       while i<n do(
			s_i=s_(i-1)+sum(0..i-1, j-> L_j*b_(i-1-j))*p^(i-1); 
	       		b_i=(sub(-sub((s_i/p^i)+sum(1..i,j->L_j*b_(i-j)),ZZ/p)/sub(L_0,ZZ/p),ZZ)+p)%p;
			S=append(S,b_i);
			i=i+1);
	       S
	       );
     inverse A := a->(
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
         toPAdicFieldElement(toPAdicInverse(L),A)<<(-v)
	  );
     +A := a->a;
     -A := a->(
	  newValues := for i in a#"expansion"_1 list -i;
	  computeCarryingOver(a#"expansion"_0,newValues,a#"precision")
	  );
     A - A:= (a,b)->(a+(-b));
     A / A:= (a,b)->(a*inverse(b));
     A ^ ZZ := (a,n) ->(local c; c=1; i:=0;
	  if n>-1 
	  then while i<n do(c=c*a;i=i+1) else while i<abs(n) do(c=c*inverse(a);i=i+1);
	  c);
     A + ZZ := (a,n)->(
	  b := toPAdicFieldElement(n,precision a,A);
	  a+b
	  );
     ZZ + A := (n,a)->a+n;
     A - ZZ := (a,n)->a+(-n);
     ZZ - A := (n,a)->(-a)+n;
     pValuation := n->(
	  b := n;
	  v := 0;
          while b%p==0 do (
	       b = b//p;
	       v = v+1;
	       );
	  v
	  );
     A * ZZ := (a,n)->(
	  if n==0 then 0 else (
	       v := pValuation(n);
	       b := toPAdicFieldElement(n,v+relativePrecision a,A);
	       a*b
	       )
	  );
     ZZ * A := (n,a)->a*n;
     coarse := method();
     coarse(A,ZZ) := (a,prec) -> (
	  newPrecision := min(prec,precision a);
	  newKeys := select(a#"expansion"_0,i->(i<newPrecision));
	  newValues := for i in 0..#newKeys-1 list a#"expansion"_1#i;
	  new A from {"precision"=>newPrecision,
	       "expansion"=>{newKeys,newValues}}
	  );
     A == A := (a,b) -> (
	  if precision a < precision b then (
	       a === coarse(b,precision a)
	       ) else if precision a > precision b then (
	       b === coarse(a,precision b)
	       ) else (
	       a === b
	       )
	  );
     A == ZZ := (a,n) -> (
	  b := toPAdicFieldElement(n,precision a,A);
	  a === b
	  );
     ZZ == A := (n,a) -> a==n;
     A << ZZ := (a,n) -> (
	  newPrecision := a#"precision"+n;
	  newKeys := for i in a#"expansion"_0 list i+n;
	  new A from {"precision"=>newPrecision,
	       "expansion"=>{newKeys,a#"expansion"_1}}
	  );
     PAdicFields#p=A;
     A
)



QQQ=new ScriptedFunctor
QQQ#subscript=i->(pAdicField i)



-- PAdicField Elements are hashtables with following keys:
-- precision (value ZZ)
-- expansion (hashtable, two entries: exponents, coefficients)




toPAdicFieldElement = method()

toPAdicFieldElement (List,PAdicField) := (L,S) -> (
   n:=#L;
   local expans;
   if all(L,i->i==0) then expans={{},{}}    
   else expans=entries transpose matrix select(apply(n,i->{i,L_i}),j->not j_1==0);
   new S from {"precision"=>n,"expansion"=>expans}
   )
toPAdicFieldElement(ZZ,ZZ,PAdicField) := (n,prec,S) -> (
     new S from ({0},{n},prec)
     );



PAdicMatrix = new Type of MutableHashTable

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

end
----------------------------
--Qingchun's testing area
----------------------------
restart
load "/Users/qingchun/Desktop/M2Berkeley/Workshop-2014-Berkeley/MumfordCurves/pAdic.m2"
Q3 = pAdicField(3)
x = toPAdicFieldElement({1,2,0,1,0},Q3);
y = toPAdicFieldElement(0,3,Q3);
z = toPAdicFieldElement(10,10,Q3);
print(x<<3);
print(y<<15);
print(x<<(-5));
print(x+x)
print(x*x)
print(x+y)
print(x*y)
print(y*y)
print(x+1)
print((1-x)+x)
print(82*x)
end

----------------------------
--Nathan's testing area
----------------------------
restart
load "~/Workshop-2014-Berkeley/MumfordCurves/pAdic.m2"

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
