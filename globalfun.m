function y = globalfun(x)

global c6 c5 c4 c3 c2 c1
%c1 = 0; c2 = 0; c3 = 0; c4 = 0; c5 = 0; c6 = 0;  

y = c1*x.^5 + c2*x.^4 + c3*x.^3 + c4*x.^2 + c5*x.^1 + c6;
