clear all
%clc
Camera.lens_identifier ='Berlin_LITE';

if(strcmp(Camera.lens_identifier, 'Berlin_LITE'))

    Camera.config_fname = 'C:\FFT\Tests_2023_02_08_Tokio_Lite_4x\ScanReference\3MP_OCamCalib3D_config.txt'

end
    Camera.config_fname = 'C:\FFT\Tests_2023_02_08_Tokio_Lite_4x\ScanReference\3MP_OCamCalib3D_config.txt' 

Camera.roundtableOffset_x   = '0';
Camera.roundtableOffset_y   = '0';
Camera.roundtableOffset_z   = '0';

%3MP
    Camera.left_dot_x           = '844';
   Camera.left_dot_y           = '779';
   Camera.right_dot_x          = '1094';
   Camera.right_dot_y          = '782';

Camera.Debug                = '1';



Camera.roundtable_offset = [0,0,0];

Camera.debug = 0;

%Parameters = IntriCalibMEE(Camera)

myDir = 'C:\FFT\Tests_2023_02_08_Tokio_Lite_4x\myfile';

myFiles = dir(fullfile(myDir,'*.bmp')); %gets all wav files in struct

for k = 1:1 %length(myFiles)

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



