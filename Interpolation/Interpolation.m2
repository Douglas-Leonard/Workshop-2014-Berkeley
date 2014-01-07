polynomialInterpolation = method ()
polynomialInterpolation (List,PolynomialRing) := RingElement => (L,R) -> (
	if #gens R != 1 then error "must be a single variable polynomial ring";
	n := #L;
	y := for k from 0 to n-1 list (L_k)_1;
	x := for k from 0 to n-1 list (L_k)_0;
	p := for j from 0 to n-1 list (
		y_j * product(0..(j-1) | (j+1) .. (n-1), k -> (t - x_k) / (x_j - x_k))
		);
	sum(p)
)
polynomialInterpolation (List) := RingElements => L -> guessPolynomial(L, QQ[t])

rationalInterpolation = method ()
rationalInterpolation (List, PolynomialRing) := RingElement => (L,R) -> (
	if #gens R != 1 then error "must be a single variable polynomial ring";
	QQ[t];
	n := #L;
	y := for k from 0 to n-1 list (L_k)_1;
	x := for k from 0 to n-1 list (L_k)_0;
	(sum(1..(n-2), j -> ((-1)^j * y_j)/(t-x_j)) + 1/2 * (y_0)/(t-x_0) + 1/2 * ((-1)^(n-1) * y_(n-1))/(t-x_(n-1))) / 
		(sum(1..(n-2), j -> ((-1)^j)/(t-x_j)) + 1/2 * ((-1)^0)/(t-x_0) + 1/2 * ((-1)^(n-1))/(t-x_(n-1)))
)
rationalInterpolation (List) := RingElement => L -> rationalInterpolation(L, QQ[t])
