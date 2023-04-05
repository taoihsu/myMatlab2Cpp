function [thta_z, thta_y, thta_x]=EulerAnglesFromR(R)
%Calculate the Euler angles of the real camera.
thta_y  = asind(R(3,1));
thta_z = atand(-(R(2,1)/R(1,1)));
thta_x = (atand(-R(3,2)/R(3,3)));

