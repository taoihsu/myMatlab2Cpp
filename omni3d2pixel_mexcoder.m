function [x,y] = omni3d2pixel_mexcoder(ss, xx, width, height)%#codegen
coder.inline('never')

global c6 c5 c4 c3 c2 c1
c1 = 0;
c2 = 0;
c3 = 0;
c4 = 0;
c5 = 0;
c6 = 0;  




%convert 3D coordinates vector into 2D pixel coordinates

%These three lines overcome problem when xx = [0,0,+-1]
ind0 = find((xx(1,:)==0 & xx(2,:)==0));
xx(1,ind0) = eps;
xx(2,ind0) = eps;

m = xx(3,:)./sqrt(xx(1,:).^2+xx(2,:).^2);
%figure(3)
%plot3(xx(1,:), xx(2,:), xx(3,:), 'b*');

rho= zeros(length(m));
poly_coef = ss(end:-1:1);
poly_coef_tmp = poly_coef;

%poly_coef_tmp'
%testM = m(1:10);
%testM'

for j = 1:length(m)
    poly_coef_tmp(end-1) = poly_coef(end-1)-m(j);
    

% %     % Using roots to find roots of polynomial poly_coef_tmp which will be
% %     % used in fzero routine as initial value. Becuase in amtlb Coder for
% %     % code generation, roots gives different results in MEX files.
% %     rhoTmp = roots(poly_coef_tmp); % roots is the bottleneck in timing, takes most of the computation time
% %     res = rhoTmp(find(imag(rhoTmp)==0 & rhoTmp>0));% & rhoTmp<height ));    %obrand
% %     res = real(res); % Make res to be real values for code generation compatibility
% %     if isempty(res) %| length(res)>1    %obrand
% %         rho(j) = NaN;
% %     elseif length(res)>1    %obrand
% %         rho(j) = min(res);    %obrand
% %     else
% %         rho(j) = res;
% %     end
% %     % We just need res for initializing fzero function
    
     
    % Following way of using fzero is not supported in code generation
    %     fun = @(x) c(1)*x.^5 + c(2)*x.^4 + c(3)*x.^3 + c(4)*x.^2 + c(5)*x.^1 + c(6);
    %     x0 = c(6);
    %     resFzero = fzero(fun,x0);
    % Instead try using global variable method

    % Following way of using fzero is supported in code generation but
    % still not the same results as roots !!!
    c = poly_coef_tmp;
    c1 = c(1); c2 = c(2); c3 = c(3); c4 = c(4); c5 = c(5); c6 = c(6);  
    x0 = c6; % Setting up the initial value to c6
    %x0 = res(1); % Setting up the initial value from roots function, res(1) instead of simply res becuase code generation requires fixed size variable on rhs
    resFzero = fzero(@globalfun,x0);
    rho(j) = resFzero;

    %res-resFzero
    %res = resFzero;   

    
end

%testRho = rho(1:5);
%testRho'
%g = @() roots(poly_coef_tmp);
%fprintf(1,'\nTime consumed in roots:%f',timeit(g));

x = zeros(1,length(m));
y = zeros(1,length(m));
for j = 1:length(m)
    x(1,j) = xx(1,j)./sqrt(xx(1,j).^2+xx(2,j)^2)*rho(j) ;
    y(1,j) = xx(2,j)./sqrt(xx(1,j).^2+xx(2,j)^2)*rho(j) ;
end
    
%x = xx(1,:)./sqrt(xx(1,:).^2+xx(2,:).^2).*rho ;
%y = xx(2,:)./sqrt(xx(1,:).^2+xx(2,:).^2).*rho ;










