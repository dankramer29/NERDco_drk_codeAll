function out = NDrotationMatrix(N,planeX, planeY,thetaRadians)

out = eye(N);
out(planeX,planeX) = cos(thetaRadians);
out(planeY,planeY) = cos(thetaRadians);
out(planeX,planeY) = -sin(thetaRadians);
out(planeY,planeX) = sin(thetaRadians);