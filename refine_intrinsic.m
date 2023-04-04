%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%   Copyright (C) 2006 DAVIDE SCARAMUZZA
%   
%   Author: Davide Scaramuzza - email: davsca@tiscali.it
%   
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%   
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%   
%   You should have received a copy of the GNU General Public License
%   along with this program; if not, write to the Free Software
%   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
%   USA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%   Change history
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
%   Copyright (C) 2014 Magna Electronics Europe GmbH & Co. KG
%
%   Author: Jagmal Singh - email: Jagmal.Singh@magna.de
%
%   September 2014
%   This program is modified version of Scaramuzza's prova3.m which now
%   incorporates 3D calibration points with known coordinates instead
%   of chessboard-like pattern.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

function err=refine_intrinsic(x,xc,yc,ss,RRfin, ima_proc,Xp_abs,Yp_abs,M, width, height)

a=x(1);
b=x(2);
%c=x(3);
%d=x(4);
%e=x(5);

%ssc=x(6:end);
ssc=x(3:end);

M(:,4)=1;

Mc=[];
Xpp=[];
Ypp=[];
for i=ima_proc
    Mc=[Mc, RRfin(:,:,i)*M'];
    Xpp=[Xpp;Xp_abs(:,:,i)];
    Ypp=[Ypp;Yp_abs(:,:,i)];
end

[xp1,yp1]=omni3d2pixel(ss.*ssc',Mc, width, height);

c = 1;
d = 0;
e = 0;

xp=xp1*c + yp1*d + xc*a;     
yp=xp1*e + yp1 + yc*b;       

err=sqrt( (Xpp-xp').^2+(Ypp-yp').^2 );




