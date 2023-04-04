function [x,y] = omni3d2pixel_fast(ss, xx, width, height)


%convert 3D coordinates vector into 2D pixel coordinates

%These three lines overcome problem when xx = [0,0,+-1]
ind0 = find((xx(1,:)==0 & xx(2,:)==0));
xx(1,ind0) = eps;
xx(2,ind0) = eps;

m = xx(3,:)./sqrt(xx(1,:).^2+xx(2,:).^2);
poly_coef = ss(end:-1:1);
poly_coef_tmp = poly_coef;


rho = zeros(1,length(m));

for j = 1:length(m)
    poly_coef_tmp(end-1) = poly_coef(end-1)-m(j);
    
    % "inline" roots starts
             d = poly_coef_tmp(2:end)./poly_coef_tmp(1);
             %%%while any(isinf(d))% Prevent relatively small leading coefficients from introducing Inf by removing them.
             %%%    poly_coef_tmp = poly_coef_tmp(2:end);
             %%%    d = poly_coef_tmp(2:end)./poly_coef_tmp(1);
             %%%end
             a = diag(ones(1,length(poly_coef_tmp)-2,class(poly_coef_tmp)),-1);
             a(1,:) = -d;
             rhoTmp = eig(a);
    % "inline" roots end
    
    
    
    % Comment upper "inline" code and uncomment lower line, if you want to 
    % have assurance of correct results but slower speed
    % rhoTmp = roots(poly_coef_tmp); % roots is the bottleneck in timing, takes most of the computation time
    
   
    %res = rhoTmp(find(imag(rhoTmp)==0 & rhoTmp>0));% & rhoTmp<height ));    %obrand
    res = rhoTmp(imag(rhoTmp)==0 & rhoTmp>0);% & rhoTmp<height ));    %obrand
    res = real(res);
    
    if isempty(res) %| length(res)>1    %obrand
        rho(j) = NaN;
    elseif length(res)>1    %obrand
        rho(j) = min(res);    %obrand
    else
        rho(j) = res;
    end
end


    
x = xx(1,:)./sqrt(xx(1,:).^2+xx(2,:).^2).*rho ;
y = xx(2,:)./sqrt(xx(1,:).^2+xx(2,:).^2).*rho ;










