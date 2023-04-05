function calib_config = import_OcamCalib3D_config(fname)
tic
fid = fopen(fname);

%First three lines are introduction line
tline = fgets(fid);
tline = fgets(fid);
tline = fgets(fid);

%FFT_specific_settings
tline = fgets(fid);

%FFT_id
tline = fgets(fid);
calib_config.FFT_id = fscanf(fid, '%s\n', 1);

%this_file_name
tline = fgets(fid);
calib_config.this_file_name = fscanf(fid, '%s\n', 1);

%scan_reference_obc_file
tline = fgets(fid);
calib_config.scan_reference_obc_file = fscanf(fid, '%s\n', 1);

%cross_reference_txt_file
tline = fgets(fid);
calib_config.cross_reference_txt_file = fscanf(fid, '%s\n', 1);

%maxDotsLeftRight
tline = fgets(fid);
calib_config.maxDotsLeftRight = str2double(fscanf(fid, '%s\n', 1));

%maxDotsUpperLower
tline = fgets(fid);
calib_config.maxDotsUpperLower = str2double(fscanf(fid, '%s\n', 1));

%camera_type_specific_settings
tline = fgets(fid);

%principal_plane_offset_mm
tline = fgets(fid);
calib_config.principal_plane_offset = str2double(fscanf(fid, '%s\n', 1));

%pixel_pitch_x_mm
tline = fgets(fid);
calib_config.pixel_pitch_mm = str2double(fscanf(fid, '%s\n', 1)); % pixel pitch in x is defined as just pixel_pitch_mm

%pixel_pitch_y_mm
tline = fgets(fid);
calib_config.pixel_pitch_y_mm = str2double(fscanf(fid, '%s\n', 1)); % pixel pitch in y is defined as just pixel_pitch_y_mm

%polynomial_Image2World
tline = fgets(fid);
N = str2num(fscanf(fid, '%s\n', 1));
for i = 1:N
    calib_config.Poly_Image2World(i) = str2double(fscanf(fid, '%s\n', 1));
end

%polynomial_World2Image
tline = fgets(fid);
N = str2num(fscanf(fid, '%s\n', 1));
for i = 1:N
    calib_config.Poly_World2Image(i) = str2double(fscanf(fid, '%s\n', 1));
end

%field_of_view_radians
tline = fgets(fid);
calib_config.field_of_view = str2double(fscanf(fid, '%s\n', 1));

%size_of_sensor_mm_pi
tline = fgets(fid);
calib_config.size_of_sensor = str2double(fscanf(fid, '%s\n', 1));

%image_processing_settings
tline = fgets(fid);

%CenterDotsAreaThreshold_pixels
tline = fgets(fid);
calib_config.CenterDotsAreaThreshold(1) = str2double(fscanf(fid, '%s\n', 1));
calib_config.CenterDotsAreaThreshold(2) = str2double(fscanf(fid, '%s\n', 1));

%DotAreaThreshold_pixels
tline = fgets(fid);
calib_config.DotAreaThreshold(1) = str2double(fscanf(fid, '%s\n', 1));
calib_config.DotAreaThreshold(2) = str2double(fscanf(fid, '%s\n', 1));

%DistanceThreshold_pixels range [10 30]
tline = fgets(fid);
calib_config.DistanceThreshold = str2double(fscanf(fid, '%s\n', 1));

%BorderThreshold_pixels range [12 20]
tline = fgets(fid);
calib_config.BorderThreshold = str2double(fscanf(fid, '%s\n', 1));

%EdgeThreshold_imfindcircles_scaler range [0 1]
tline = fgets(fid);
calib_config.EdgeThreshold = str2double(fscanf(fid, '%s\n', 1));

%Radius_range_imfindcircles_pixels
tline = fgets(fid);
calib_config.Radius_range_imfindcircles(1) = str2double(fscanf(fid, '%s\n', 1));
calib_config.Radius_range_imfindcircles(2) = str2double(fscanf(fid, '%s\n', 1));

%Gaussian_filter_size range [3 7]
tline = fgets(fid);
calib_config.Gaussian_filter_size = str2double(fscanf(fid, '%s\n', 1));

%median_filter_size range [3 7]
tline = fgets(fid);
calib_config.median_filter_size = str2double(fscanf(fid, '%s\n', 1));

%MacBethChart_mask_value
tline = fgets(fid);
calib_config.MacBethChart_mask_value(1) = str2double(fscanf(fid, '%s\n', 1));
calib_config.MacBethChart_mask_value(2) = str2double(fscanf(fid, '%s\n', 1));
calib_config.MacBethChart_mask_value(3) = str2double(fscanf(fid, '%s\n', 1));

%Average_reprojection_error
tline = fgets(fid);
calib_config.Average_reprojection_error_threshold = str2double(fscanf(fid, '%s\n', 1));

%Maximal_pixelwise_error
tline = fgets(fid);
calib_config.Maximal_pixelwise_error_threshold = str2double(fscanf(fid, '%s\n', 1));

%RMSE_in_distortion_polynomials
tline = fgets(fid);
calib_config.RMSE_in_distortion_polynomials_threshold = str2double(fscanf(fid, '%s\n', 1));

%Estimated_camera_translation
tline = fgets(fid);
calib_config.Estimated_camera_translation_threshold = str2double(fscanf(fid, '%s\n', 1));


fclose(fid);
toc

end

