clear all
%clc

Camera.lens_identifier = '185H_LVDS'; % For Ford
%Camera.lens_identifier = '190H_LVDS'; % For Chrysler
%Camera.lens_identifier ='Zurich2_HD'; % for PSA
Camera.lens_identifier ='Zurich2_Lite_25';  % for PSA
%Camera.lens_identifier ='Zurich2_Lite_30'  % for PSA

if(strcmp(Camera.lens_identifier, '185H_LVDS'))
    %Camera.image_fname = 'C:\_mks\40008\KP03_ProductEngineering\55_Software\40_Algorithms\10_IC\release\DLLs\IntriCalib\dotNET_framework\example_supporting_files\Ford.bmp';
    %Camera.config_fname = 'C:\_mks\40008\KP03_ProductEngineering\55_Software\40_Algorithms\10_IC\release\DLLs\IntriCalib\dotNET_framework\example_supporting_files\Ford_OCamCalib3D_config.txt';
    Camera.image_fname = 'C:\FFT\outofmemory\715AD014781606_Intial Alignment Image_N#4_11_29_38.bmp';
    Camera.config_fname = 'C:\FFT\Intrinsic_Support_Files\Ford_OCamCalib3D_config.txt';
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
    Camera.config_fname = 'C:\FFT\PS_Files\PSA_OCamCalib3D_config.txt'
end
if(strcmp(Camera.lens_identifier, 'Zurich2_Lite_25'))
    %Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\20 Lite -25um\1802001704464_Nr07.bmp' 
    %Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\FullRezLITE\174721_test.bmp' 
    %Camera.image_fname = 'C:\Users\James\Desktop\Tests 2019-05-09 ECU Tests\PSA_Lite_02_295_m05_Right_FFT.bmp' 
    %Camera.image_fname = 'C:\FFT\FromZJG\185275AB\Average_reprojection_error_Limit_2.12249166239316\275AB000230069_Focus Image_N#_08_56_09.jpg'
    %Camera.image_fname = 'C:\FFT\FromZJG\Validation Apr-21\332AA010630522\332AA010630522_Intial Alignment Image_N#_09_54_30.jpg'
    Camera.image_fname = 'C:\FFT\FromZJG\185255AB\Average_reprojection_error_Limit_1.84562982375111\255AB001130003_Focus Image_N#_02_20_06.jpg'
    Camera.image_fname = 'C:\FFT\FromZJG\newFails\185256AB\256AB000230632_Focus Image_N#_03_56_39.jpg';
    %C:\FFT\Customer samples 2019-11-08\Lite\part1\1902002325304.bmp' 
    %Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\LiteImages\1802001704094.bmp'
    %Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\20 Lite -25um\1802001704386_Nr13.bmp'
    %Camera.config_fname = 'C:\FFT\PSA_B2.2_supportFiles\PSA_25_OCamCalib3D_config.txt'
    %Camera.config_fname = 'C:\FFT\FromZJG\Intrinsic_Support_Files\Ford_OCamCalib3D_config.txt'
    Camera.config_fname = 'C:\FFT\PSA_B2.2_supportFiles\PSA_25_OCamCalib3D_config.txt'
end
if(strcmp(Camera.lens_identifier, 'Zurich2_Lite_30'))
    Camera.image_fname = 'C:\FFT\PSA_B2.2_supportFiles\Lite -30um\1802001704182.bmp'
    Camera.config_fname = 'C:\FFT\PSA_B2.2_supportFiles\PSA_25_OCamCalib3D_config.txt'
end

    


Camera.roundtableOffset_x   = '0';
Camera.roundtableOffset_y   = '0';
Camera.roundtableOffset_z   = '0';
Camera.left_dot_x           = '9999';%'561';
Camera.left_dot_y           = '9999';%'399';
Camera.right_dot_x          = '9999';%'727';
Camera.right_dot_y          = '9999';%'399';
Camera.Debug                = '1';

tic

Camera.roundtable_offset = [0,0,0];
% Camera.leftDot = [561, 399];
% Camera.rightDot = [727, 399];
Camera.debug = 1;

%Parameters = IntriCalibMEE(Camera)

IntriCalibMEE_EXE(Camera.image_fname, Camera.config_fname, Camera.lens_identifier,...
                  Camera.roundtableOffset_x, Camera.roundtableOffset_y, Camera.roundtableOffset_z,...
                  Camera.left_dot_x, Camera.left_dot_y,...
                  Camera.right_dot_x, Camera.right_dot_y,...
                  Camera.Debug)


toc


