% Wallis Filter Implementation
% Dated : Jan 24 2007
%--------------------------------------------------------------------------
% gw(x,y) = g(x,y)r1 + r0
% with : 
%      r1 = c sf / (c sg + sf/c)
%      r0 = b mf + (1 - b - r1) mg
%      
%      gw(x,y) = Filtered image
%      g(x,y)  = Original image
%      r0 = Additive parameter
%      r1 = Multiplicative parametere
%      mg = Mean of original image
%      sg = Standard deviation of original image
%      mf = target value of Mean
%      sf = Target value of Standard Deviation
%      c  = Contrast expansion constant
%      b  = Brightness forcing function
%      TYPICAL VALUES Reference: eth16078_Diss_Li_Zhang.pdf, page 67
%      mf = 2048.0; % not working in our case
%      sf = 850.0;  % not working in our case
%      b  = 0.6;  % should be a very large value for no change
%      c  = 0.75; % should be a large (2-3) value for no change
%--------------------------------------------------------------------------

%   Change history
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%   Copyright (C) 2014 Magna Electronics Europe GmbH & Co. KG
%
%   Author: Jagmal Singh - email: Jagmal.Singh@magna.de
%
%   May 2015
%   All fprintf occurances have been commeted.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

function newim = wallis(image,mf,sf,b,c)

%fprintf('\n...Wallis Filter START\n');


if isa(image,'uint16');
    check =1;    
    %fprintf('...Image data read in uint16 format \n');
end
if isa(image,'uint8');
    check =2;    
    %fprintf('...Image data read in uint8 format \n');
end

if ~isa(image,'double'); % Confirm double
    newim = double(image);
    %fprintf('...Image converted to double \n');
else
    newim = image;
end

mg = mean2(newim);
%fprintf('...Mean of original image %g \n',mg);
%fprintf('...Target Mean Value %g \n',mf);
sg = std2(newim);
%fprintf('...Standard Deviation of original image %g \n',sg);
%fprintf('...Target Standard Deviation value %g \n',sf);

r1 = c*sf / (c*sg + sf/c); 
%fprintf('...Multiplicative parameter r1 %g \n',r1);
r0 = b*mf+(1 - b - r1)*mg; 
%fprintf('...Additive parameter r0 %g \n',r0);


sz = size(image);
for i = 1 : sz(1)
    for j = 1 : sz(2)
        newim(i,j) = newim(i,j)*r1 + r0;       
    end
end

if check == 1
    newim = uint16(newim);    
    %fprintf('...Image converted back to uint16 \n');
end
if check == 2
    newim = uint8(newim);    
    %fprintf('...Image converted back to uint8 \n');
end

%fprintf('...Wallis Filter END\n');
