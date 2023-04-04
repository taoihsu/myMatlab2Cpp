function [err, stderr, MSE, intrinsicBox2Dreprojected]=reprojectpoints(calib_data, loud)
fast = calib_data.fast; % fast = 1 will use inline "roots" function of Matlab in omni3d2pixel_fast, fast = 0 will use calling inbuilt Matlab function roots in omni3d2pixel_slow

M = [calib_data.Xt, calib_data.Yt, calib_data.Zt];

M(:,4)=1;
%M(:,3)=1;

ss = calib_data.ocam_model.ss;
c = calib_data.ocam_model.c;
d = calib_data.ocam_model.d;
e = calib_data.ocam_model.e;
xc = calib_data.ocam_model.xc;
yc = calib_data.ocam_model.yc;
width = calib_data.ocam_model.width;
height = calib_data.ocam_model.height;

Mc=[];
Xpp=[];
Ypp=[];
count=0;
MSE=0;
for i=calib_data.ima_proc
    count=count+1;
    Mc=calib_data.RRfin(:,:,i)*M';

        if(fast==1)
        [xp,yp]=omni3d2pixel_fast(ss, Mc, width, height); % Faster because "inline" roots is called
        %[xp,yp]=omni3d2pixel_mexcoder_mex32(ss, Mc, width, height); % Very fast becuase mex is called and "fzero" is used instead of "roots" for mex generation, 32 bit compilation
        %[xp,yp]=omni3d2pixel_mexcoder_mex64(ss, Mc, width, height); % Very fast becuase mex is called and "fzero" is used instead of "roots" for mex generation, 32 bit compilation
        %[xp,yp]=omni3d2pixel_fast_mex(ss, Mc, width, height); % Super fast (but WRONG) becuase mex is called and within that "roots" function, so WRONG results also
    end
    %if(fast==0)
        %[xp,yp]=omni3d2pixel_slow(ss, Mc, width, height); % its slow but may be more error checks in inbuilts function roots, instead of "inline" roots
    %end

    
    xp=xp*c + yp*d + xc;
    yp=xp*e + yp + yc;    
    
    %m=world2cam(Mc, calib_data.ocam_model);
    %xp=m(1,:);
    %yp=m(2,:);
    
    sqerr= (calib_data.Xp_abs(:,:,i)-xp').^2+(calib_data.Yp_abs(:,:,i)-yp').^2;
    
    err(count)=mean(sqrt(sqerr));
    stderr(count)=std(sqrt(sqerr));
    MSE=MSE+sum(sqerr);

    sqerrX= (calib_data.Xp_abs(:,:,i)-xp').^2;
            maxX = max(max(abs(calib_data.Xp_abs(:,:,i)-xp')));
            minX = min(min(abs(calib_data.Xp_abs(:,:,i)-xp')));
    errX(count) = mean(sqrt(sqerrX));
    stderrX(count)=std(sqrt(sqerrX));
    
    sqerrY= (calib_data.Yp_abs(:,:,i)-yp').^2;
            maxY = max(max(abs(calib_data.Yp_abs(:,:,i)-yp')));
            minY = min(min(abs(calib_data.Yp_abs(:,:,i)-yp')));
    errY(count) = mean(sqrt(sqerrY));
    stderrY(count)=std(sqrt(sqerrY));
    
    intrinsicBox2Dreprojected(:,:,i) = [xp', yp'];
  
      
end



if(loud)
    fprintf(1,'\nAverage reprojection error [pixels]: %3.2f +/- %3.2f',err(1),stderr(1));
    fprintf(1,'\nMaximal pixelwise reprojection error [x, y]: [%3.5f, %3.5f]', maxX, maxY);
    fprintf(1,'\nMinimal pixelwise reprojection error [x, y]: [%3.5f, %3.5f]', minX, minY);
    fprintf(1,'\nSum of squared errors: %f\n',MSE);
end

err = [err(1), errX(1), errY(1), maxX, minX, maxY, minY];
stderr = [stderr(1), stderrX(1), stderrY(1)];
