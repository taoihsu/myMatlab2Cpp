% Pre-processing of image data
% Dated 04 Feb 2008
% This fucntion pre-processes second image data on the basis of mean and standard
% deviation values obtained from first image data
% input :  image1    = first image data array
%          image2    = second image data array
% output : image1    = first image data array - pre processed
%          image2    = second image data array - pre processed

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

function [image1, image2] = preprocess(image1,image2)

%fprintf('\n...Pre-processing START\n');

if ~isa(image1,'double'); % Confirm double
    newim = double(image1);
    %fprintf('...Image converted to double \n');
else
    newim = image1;
end

mean_image1 = mean2(newim);
%fprintf('...Mean of first image %g \n',mean_image1);
stand_dev_image1 = std2(newim);
%fprintf('...Standard Deviation of first image %g \n',stand_dev_image1);

image2 = wallis(image2,mean_image1,stand_dev_image1,0.6,3.75);
image1 = image1;

%fprintf('\n...Pre-processing ENDS\n');