clear all
%clc

%Camera.lens_identifier = '185H_LVDS'; % For Ford
%Camera.lens_identifier = '190H_LVDS'; % For Chrysler
%Camera.lens_identifier ='Zurich2_HD'; % for PSA
%Camera.lens_identifier ='Berlin_LITE'; % for PSA

%Camera.lens_identifier ='Zurich_HD'; % for PSA
%Camera.lens_identifier ='Zurich2_Lite_30'  % for PSA
%Camera.lens_identifier ='Zurich2_Lite_25'  % for PSA
%Camera.lens_identifier ='China'  % for PSA
%Camera.lens_identifier ='FCA_ZF'
Camera.lens_identifier ='Berlin_LITE';
%Camera.lens_identifier ='TOYOTA'

if(strcmp(Camera.lens_identifier, '185H_LVDS'))
%     Camera.image_fname = 'C:\_mks\40008\KP03_ProductEngineering\55_Software\40_Algorithms\10_IC\release\DLLs\IntriCalib\dotNET_framework\example_supporting_files\Ford.bmp';
%     Camera.config_fname = 'C:\_mks\40008\KP03_ProductEngineering\55_Software\40_Algorithms\10_IC\release\DLLs\IntriCalib\dotNET_framework\example_supporting_files\Ford_OCamCalib3D_config.txt';
%     Camera.image_fname = 'C:\FFT\FromZJG\185256AB\Good parts\256AB000230315_Focus Image_N#_12_52_49.jpg';%ok
    Camera.config_fname = 'C:\FFT\FromZJG\Intrinsic_Support_Files\Ford_OCamCalib3D_config.txt'
end
if(strcmp(Camera.lens_identifier, '190H_LVDS'))
    %Camera.image_fname = 'C:\mks\40008\KP03_ProductEngineering\55_Software\40_Algorithms\10_IC\release\DLLs\IntriCalib\dotNET_framework\example_supporting_files\Chrysler.bmp';
    %Camera.image_fname = 'C:\SAILAUF\331AA122353445_Focus Image_N#_02_48_01.bmp';
    %Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\LiteImages\1802001704094.bmp'
    Camera.image_fname = 'C:\Users\James\Desktop\PrinciplePointData\Chrysler PPY Greater with Focus Image\331AG908151588_Focus Image_N#1_01_18_18.bmp';
    
    %Camera.config_fname = 'C:\mks\40008\KP03_ProductEngineering\55_Software\40_Algorithms\10_IC\release\DLLs\IntriCalib\dotNET_framework\example_supporting_files\Chrysler_OCamCalib3D_config.txt';
    %Camera.config_fname = 'C:\_mks\40008\KP03_ProductEngineering\55_Software\40_Algorithms\10_IC\tools\MagnaIC\src\config_files\Chrysler_OCamCalib3D_config_FFT_holly_gl1.txt';
    Camera.config_fname = 'C:\FFT\PS_Files\PSA_OCamCalib3D_config.txt'
end
if(strcmp(Camera.lens_identifier, 'Zurich2_HD'))
    Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\HD -30um\FFT mode\1802001704503_FaA.bmp'
    Camera.config_fname = 'C:\FFT\FromZJG\Z4_fails\IntrinsicSupport_FCA-Z4\PSA_OCamCalib3D_config.txt'
end

if(strcmp(Camera.lens_identifier, 'Berlin_LITE'))
%     Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\HD -30um\FFT mode\1802001704503_FaA.bmp'
    %Camera.config_fname = 'C:\FFT\Berlin\ScanReference\Berlin_OCamCalib3D_config.txt'
    Camera.config_fname = 'C:\FFT\Tests_2023_02_08_Tokio_Lite_4x\ScanReference\3MP_OCamCalib3D_config.txt'
    %from Holly
       % Camera.config_fname = 'C:\FFT\Berlin\Fisker_SVS\BerlinAT303_OCamCalib3D_config.txt'
    %Camera.config_fname = 'C:\FFT\Berlin\Fisker_SVS\BerlinAT303_OCamCalib3D_config_Trial.txt'
end

if(strcmp(Camera.lens_identifier, 'Zurich_HD'))
    Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\HD -30um\FFT mode\1802001704503_FaA.bmp'
    Camera.config_fname = 'C:\FFT\FromZJG\Z4_fails\IntrinsicSupport_FCA-Z4\Chrysler_Z4_OCamCalib3D_config.txt'
end


if(strcmp(Camera.lens_identifier, 'China'))
    Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\HD -30um\FFT mode\1802001704503_FaA.bmp'
    Camera.config_fname = 'C:\FFT\FromZJG\Sept_2020\Chrysler\Chrysler_Z4_OCamCalib3D_config.txt'
    %Camera.config_fname = 'C:\FFT\FromZJG\Sept_2020\Ford\Ford_OCamCalib3D_config.txt'
    Camera.lens_identifier = 'Zurich_HD';
end

if(strcmp(Camera.lens_identifier, 'Zurich2_Lite_25'))
    %Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\20 Lite -25um\1802001704464_Nr07.bmp' 
    %Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\FullRezLITE\174721_test.bmp' 
    %Camera.image_fname = 'C:\Users\James\Desktop\Tests 2019-05-09 ECU Tests\PSA_Lite_02_295_m05_Right_FFT.bmp' 
    Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\2019-05-24 Delta DV CL07\Post\2019029930178.bmp' 
    %Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\LiteImages\1802001704094.bmp'
    %Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\20 Lite -25um\1802001704386_Nr13.bmp'
    %Camera.config_fname = 'C:\FFT\PSA_B2.2_supportFiles\PSA_25_OCamCalib3D_config.txt'
    Camera.config_fname = 'C:\FFT\PSA_B2.2_supportFiles\PSA_25_OCamCalib3D_config.txt'
    %Camera.config_fname = 'C:\FFT\FromZJG\Intrinsic_Support_Files\Ford_OCamCalib3D_config.txt'
    %Camera.config_fname = 'C:\FFT\PSA_B2.2_supportFiles\Berlin_25_OCamCalib3D_config.txt'
    
    %Camera.config_fname = 'C:\FFT\Toyota2\New\Toyota_OCamCalib3D_config.txt'
    Camera.lens_identifier = 'Zurich_HD';
    
end
if(strcmp(Camera.lens_identifier, 'Zurich2_Lite_30'))
    Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\Lite -30um\1802001704182.bmp'
    Camera.config_fname = 'C:\FFT\PSA_B2.2_supportFiles\PSA_25_OCamCalib3D_config.txt'
end

if(strcmp(Camera.lens_identifier, 'FCA_ZF'))
    Camera.image_fname = 'C:\FFT\FCA_Fail\1802001704182.bmp'
    %Camera.config_fname = 'C:\FFT\FCA_Fail\Chrysler_Z4_OCamCalib3D_config.txt'
    Camera.config_fname = 'C:\FFT\FCA_Fail\Chrysler_OCamCalib3D_config.txt'
    Camera.lens_identifier = 'Zurich_HD';
end

if(strcmp(Camera.lens_identifier, 'TOYOTA'))
    Camera.image_fname = 'C:\FFT\FCA_Fail\1802001704182.bmp'
    %old setup
    Camera.config_fname = 'C:\FFT\Toyota_Fail\October\Toyota_OCamCalib3D_config.txt'
    
    %new setup
    %Camera.config_fname = 'C:\FFT\New_Toyota_Fail\Toyota_OCamCalib3D_config.txt'
    
    Camera.config_fname = 'C:\FFT\Toyota_Fail_Aug_2nd\Marc_Failed\Toyota_OCamCalib3D_config.txt'
    Camera.lens_identifier = 'TBH';
end


   % Camera.config_fname = 'C:\FFT\Tests_2023_02_08_Tokio_Lite_4x\ScanReference\3MP_OCamCalib3D_config.txt'
    



%Camera.config_fname = 'C:\FFT\Ultra2Intrinsics\OLD_DLL\Toyota_OCamCalib3D_config.txt';
%Camera.lens_identifier = '190H_LVDS';

Camera.roundtableOffset_x   = '0';
Camera.roundtableOffset_y   = '0';
Camera.roundtableOffset_z   = '0';
% Camera.left_dot_x           = '553';
% Camera.left_dot_y           = '477';
% Camera.right_dot_x          = '721';
% Camera.right_dot_y          = '477';


% Camera.left_dot_x           = '9999';
% Camera.left_dot_y           = '9999';
% Camera.right_dot_x          = '9999';
% Camera.right_dot_y          = '9999';
%3MP
    Camera.left_dot_x           = '844';
   Camera.left_dot_y           = '779';
   Camera.right_dot_x          = '1094';
   Camera.right_dot_y          = '782';

%Fisker HDR
  %Camera.left_dot_x           = '840';
  %Camera.left_dot_y           = '540';
  %Camera.right_dot_x          = '1090';
  %Camera.right_dot_y          = '540';

%%Fisker SDR
%   Camera.left_dot_x           = '900';
%   Camera.left_dot_y           = '640';
%   Camera.right_dot_x          = '1156';
%   Camera.right_dot_y          = '640';
  
  %%Fisker real setup
%     Camera.left_dot_x           = '840';
%     Camera.left_dot_y           = '620';
%     Camera.right_dot_x          = '1090';
%     Camera.right_dot_y          = '620';
  
%     %%Berlin DT big real setup
%   Camera.left_dot_x           = '830';
%   Camera.left_dot_y           = '638';
%   Camera.right_dot_x          = '1080';
%   Camera.right_dot_y          = '638';
   
  
  %PSA Sailauf
%   Camera.left_dot_x         = '548';
% Camera.left_dot_y           = '480';
% Camera.right_dot_x          = '733';
% Camera.right_dot_y          = '480';
 %berlin Sailuf
%     Camera.left_dot_x           = '841';
%    Camera.left_dot_y           = '644';
%    Camera.right_dot_x          = '1089';
%    Camera.right_dot_y          = '638';

%3MP
    Camera.left_dot_x           = '844';
   Camera.left_dot_y           = '779';
   Camera.right_dot_x          = '1094';
   Camera.right_dot_y          = '782';

%  Camera.left_dot_x           = '561';
% Camera.left_dot_y           = '399';
% Camera.right_dot_x          = '727';
% Camera.right_dot_y          = '399';

Camera.Debug                = '1';

tic
%Camera.config_fname = 'C:\FFT\Toyota_Fail_Aug_2nd\Toyota_OCamCalib3D_config.txt'
Camera.roundtable_offset = [0,0,0];
%Camera.leftDot = [9999, 9999];
%Camera.rightDot = [9999, 9999];
Camera.debug = 0;

%Parameters = IntriCalibMEE(Camera)
myDir = 'C:\FFT\Tests_2023_02_08_Tokio_Lite_4x\20230208 4x';
%C:\FFT\Tests 2020-03-18 customer samples';%
%myDir = 'C:\FFT\Tests_2023_02_08_Tokio_Lite_4x\myfile';
%myDir = 'C:\FFT\FromZJG\**\';
%myDir = uigetdir; %gets directory
myFiles = dir(fullfile(myDir,'*.bmp')); %gets all wav files in struct
%myFiles = dir(fullfile(myDir,'*.jpg')); %gets all wav files in struct
for k = 1:length(myFiles)
  baseFileName = myFiles(k).name;
  baseDir = myFiles(k).folder;
  Camera.image_fname = fullfile(baseDir, baseFileName);
  fprintf(1, 'Now reading %s\n', Camera.image_fname);
 IntriCalibMEE_EXE(Camera.image_fname, Camera.config_fname, Camera.lens_identifier,...
                   Camera.roundtableOffset_x, Camera.roundtableOffset_y, Camera.roundtableOffset_z,...
                   Camera.left_dot_x, Camera.left_dot_y,...
                   Camera.right_dot_x, Camera.right_dot_y,...
                   Camera.Debug)
end
toc


