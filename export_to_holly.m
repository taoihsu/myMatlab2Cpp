function export_to_holly(Parameters, calib_config)


fid = fopen('IntrinsicParameters.txt', 'w');


formatOut = 'mm_dd_yyyy';
DateTestWasRun = datestr(now,formatOut);
fprintf(fid,'DateTestWasRun= %s\n', DateTestWasRun);

c = clock;
hOUR = c(4);
mINUTES = c(5);
fprintf(fid,'TimeTestWasRun= %d:%d\n', hOUR, mINUTES);

switch Parameters.sucess
    case 0
        fprintf(fid,'IntrinsicParameters_sucess= False \n');
    case 1
        fprintf(fid,'IntrinsicParameters_sucess= True \n');
end        

fprintf(fid,'eeprom_map_revision_major= 1\n');
fprintf(fid,'eeprom_map_revision_minor= 0\n');

fprintf(fid,'Intrinsic_algo_revision_major= 2\n');
fprintf(fid,'Intrinsic_algo_revision_minor= 3\n');

fprintf(fid,'IntrinsicParameters_image_size_width=');
fprintf(fid,'%d \n',Parameters.image_size(1));
fprintf(fid,'IntrinsicParameters_image_size_height=');
fprintf(fid,'%d \n',Parameters.image_size(2));

fprintf(fid,'IntrinsicParameters_principal_point_X=');
fprintf(fid,'%d \n',Parameters.principal_point(1));
fprintf(fid,'IntrinsicParameters_principal_point_Y=');
fprintf(fid,'%d \n',Parameters.principal_point(2));

fprintf(fid,'IntrinsicParameters_pixel_size_X=');
fprintf(fid,'%d \n',Parameters.pixel_size(1));
fprintf(fid,'IntrinsicParameters_pixel_size_Y=');
fprintf(fid,'%d \n',Parameters.pixel_size(2));

fprintf(fid,'IntrinsicParameters_field_of_view=');
fprintf(fid,'%d \n',Parameters.field_of_view);
fprintf(fid,'IntrinsicParameters_effective_focal_length=');
fprintf(fid,'%d \n',Parameters.effective_focal_length);


fprintf(fid,'IntrinsicParameters_Poly_Image2World_a0=');
fprintf(fid,'%e \n',Parameters.Poly_Image2World(1));
fprintf(fid,'IntrinsicParameters_Poly_Image2World_a1=');
fprintf(fid,'%e \n',Parameters.Poly_Image2World(2));
fprintf(fid,'IntrinsicParameters_Poly_Image2World_a2=');
fprintf(fid,'%e \n',Parameters.Poly_Image2World(3));
fprintf(fid,'IntrinsicParameters_Poly_Image2World_a3=');
fprintf(fid,'%e \n',Parameters.Poly_Image2World(4));
fprintf(fid,'IntrinsicParameters_Poly_Image2World_a4=');
fprintf(fid,'%e \n',Parameters.Poly_Image2World(5));
fprintf(fid,'IntrinsicParameters_Poly_Image2World_a5=');
fprintf(fid,'%e \n',Parameters.Poly_Image2World(6));

fprintf(fid,'IntrinsicParameters_Poly_World2Image_a0=');
fprintf(fid,'%e \n',Parameters.Poly_World2Image(1));
fprintf(fid,'IntrinsicParameters_Poly_World2Image_a1=');
fprintf(fid,'%e \n',Parameters.Poly_World2Image(2));
fprintf(fid,'IntrinsicParameters_Poly_World2Image_a2=');
fprintf(fid,'%e \n',Parameters.Poly_World2Image(3));
fprintf(fid,'IntrinsicParameters_Poly_World2Image_a3=');
fprintf(fid,'%e \n',Parameters.Poly_World2Image(4));
fprintf(fid,'IntrinsicParameters_Poly_World2Image_a4=');
fprintf(fid,'%e \n',Parameters.Poly_World2Image(5));
fprintf(fid,'IntrinsicParameters_Poly_World2Image_a5=');
fprintf(fid,'%e \n',Parameters.Poly_World2Image(6));

fprintf(fid,'Additional_error_measures\n');
fprintf(fid,'Average_reprojection_error=');
fprintf(fid,'%e \n',Parameters.err(1));
fprintf(fid,'Reprojection_error_X=');
fprintf(fid,'%e \n',Parameters.err(2));
fprintf(fid,'Reprojection_error_Y=');
fprintf(fid,'%e \n',Parameters.err(3));
fprintf(fid,'Std_average_reprojection_error=');
fprintf(fid,'%e \n',Parameters.err(4));
fprintf(fid,'Std_reprojection_error_X=');
fprintf(fid,'%e \n',Parameters.err(5));
fprintf(fid,'Std_reprojection_error_Y=');
fprintf(fid,'%e \n',Parameters.err(6));
fprintf(fid,'Maximal_pixelwise_error_X=');
fprintf(fid,'%e \n',Parameters.pixelwise_err(1));
fprintf(fid,'Minimal_pixelwise_error_X=');
fprintf(fid,'%e \n',Parameters.pixelwise_err(2));
fprintf(fid,'Maximal_pixelwise_error_Y=');
fprintf(fid,'%e \n',Parameters.pixelwise_err(3));
fprintf(fid,'Minimal_pixelwise_error_Y=');
fprintf(fid,'%e \n',Parameters.pixelwise_err(4));
fprintf(fid,'RMSE_Poly_I2W=');
fprintf(fid,'%e \n',Parameters.RMSE(1));
fprintf(fid,'RMSE_Poly_W2I=');
fprintf(fid,'%e \n',Parameters.RMSE(2));
fprintf(fid,'Camera_translation_X=');
fprintf(fid,'%e \n',Parameters.Cam_translations(1));
fprintf(fid,'Camera_translation_Y=');
fprintf(fid,'%e \n',Parameters.Cam_translations(2));

fprintf(fid,'Average_reprojection_error_Limit=');
fprintf(fid,'%f \n',calib_config.Average_reprojection_error_threshold);
fprintf(fid,'Maximal_pixelwise_error_Limit=');
fprintf(fid,'%f \n',calib_config.Maximal_pixelwise_error_threshold);
fprintf(fid,'RMSE_in_distortion_polynomials_Limit=');
fprintf(fid,'%f \n',calib_config.RMSE_in_distortion_polynomials_threshold);
fprintf(fid,'Estimated_camera_translation_Limit=');
fprintf(fid,'%f \n',calib_config.Estimated_camera_translation_threshold);

%Date	Time		

fclose(fid);

fid = fopen('Intrinsic Data Values Verification.CSV', 'a');

formatOut = 'mm_dd_yyyy';
DateTestWasRun = datestr(now,formatOut);
fprintf(fid,'%s, ', DateTestWasRun);

c = clock;
hOUR = c(4);
mINUTES = c(5);
fprintf(fid,'%d:%d, ', hOUR, mINUTES);

       
%Magna Number	
fprintf(fid,'0, ');
%Serial Number	
fprintf(fid,'0, ');
%AEI Serial Number
fprintf(fid,'0, ');
%Magna Serial Number
[filepath,name,ext] = fileparts(calib_config.image_fname);
fprintf(fid,'%s, ',name);
%Intrinsic Param Result
 switch Parameters.sucess
     case 0
         fprintf(fid,'False, ');
     case 1
         fprintf(fid,'True, ');
 end 

%TestData Pass or Fail
  fprintf(fid,' , ');
%Nest Number	Algorithm Rev					
fprintf(fid,'0, ');
fprintf(fid,'2.2, ');

%Image Width	
fprintf(fid,'%d, ',Parameters.image_size(1));
%Image Height
fprintf(fid,'%d, ',Parameters.image_size(2));
	
%PPX
fprintf(fid,'%d, ',Parameters.principal_point(1));
%PPY
fprintf(fid,'%d, ',Parameters.principal_point(2));
%PixelSizeX	
fprintf(fid,'%d, ',Parameters.pixel_size(1));
%PixelSizeY
fprintf(fid,'%d, ',Parameters.pixel_size(2));

%FOV	
fprintf(fid,'%d, ',Parameters.field_of_view);

%Eff_Focal_Len
fprintf(fid,'%d, ',Parameters.effective_focal_length);

%Poly_Image2Worlda0							
fprintf(fid,'%e, ',Parameters.Poly_Image2World(1));
%Poly_Image2Worlda1
fprintf(fid,'%e, ',Parameters.Poly_Image2World(2));
%Poly_Image2Worlda2
fprintf(fid,'%e, ',Parameters.Poly_Image2World(3));
%Poly_Image2Worlda3
fprintf(fid,'%e, ',Parameters.Poly_Image2World(4));
%Poly_Image2Worlda4
fprintf(fid,'%e, ',Parameters.Poly_Image2World(5));
%Poly_Image2Worlda5
fprintf(fid,'%e, ',Parameters.Poly_Image2World(6));

%Poly_World2Imagea0
fprintf(fid,'%e, ',Parameters.Poly_World2Image(1));
%Poly_World2Imagea1
fprintf(fid,'%e, ',Parameters.Poly_World2Image(2));
%Poly_World2Imagea2
fprintf(fid,'%e, ',Parameters.Poly_World2Image(3));
%Poly_World2Imagea3;
fprintf(fid,'%e, ',Parameters.Poly_World2Image(4));
%Poly_World2Imagea4
fprintf(fid,'%e, ',Parameters.Poly_World2Image(5));
%Poly_World2Imagea5
fprintf(fid,'%e, ',Parameters.Poly_World2Image(6));
%Average_reprojection_error						
%fprintf(fid,'Additional_error_measures\n');
%fprintf(fid,'Average_reprojection_error=');
fprintf(fid,'%e, ',Parameters.err(1));
%Reprojection_error_X
fprintf(fid,'%e, ',Parameters.err(2));
%Reprojection_error_Y
fprintf(fid,'%e, ',Parameters.err(3));
%Std_average_reprojection_error
fprintf(fid,'%e, ',Parameters.err(4));
%Std_reprojection_error_X
fprintf(fid,'%e, ',Parameters.err(5));
%Std_reprojection_error_Y
fprintf(fid,'%e, ',Parameters.err(6));
%Maximal_pixelwise_error_X
fprintf(fid,'%e, ',Parameters.pixelwise_err(1));
%Minimal_pixelwise_error_X
fprintf(fid,'%e, ',Parameters.pixelwise_err(2));
%Maximal_pixelwise_error_Y
fprintf(fid,'%e, ',Parameters.pixelwise_err(3));
%Minimal_pixelwise_error_Y
fprintf(fid,'%e, ',Parameters.pixelwise_err(4));
%RMSE_Poly_I2W
fprintf(fid,'%e, ',Parameters.RMSE(1));
%RMSE_Poly_W2I
fprintf(fid,'%e, ',Parameters.RMSE(2));
%Camera_translation_X
fprintf(fid,'%e, ',Parameters.Cam_translations(1));
%Camera_translation_Y
fprintf(fid,'%e, ',Parameters.Cam_translations(2));
%Fixture_Specific_Z_Offset
fprintf(fid,' , ');
%LVDS_Box_Brightness_Setting
fprintf(fid,' , ');
%TL_Light_Level
fprintf(fid,' , ');
%TR_Light_Level
fprintf(fid,' , ');
%BL_Light_Level
fprintf(fid,' , ');
%BR_Light_Level
fprintf(fid,' , ');
%BC_Light_Level
fprintf(fid,' , ');
%TC_Light_Level
fprintf(fid,' ,\n ');

%fprintf(fid,'Average_reprojection_error_Limit=');
%fprintf(fid,'%f \n',calib_config.Average_reprojection_error_threshold);
%fprintf(fid,'Maximal_pixelwise_error_Limit=');
%fprintf(fid,'%f \n',calib_config.Maximal_pixelwise_error_threshold);
%fprintf(fid,'RMSE_in_distortion_polynomials_Limit=');
%fprintf(fid,'%f \n',calib_config.RMSE_in_distortion_polynomials_threshold);
%fprintf(fid,'Estimated_camera_translation_Limit=');
%fprintf(fid,'%f \n',calib_config.Estimated_camera_translation_threshold);

fclose(fid);
end

