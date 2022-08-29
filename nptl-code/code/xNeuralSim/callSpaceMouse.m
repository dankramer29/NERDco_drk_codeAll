function [x,y,z,p,r,w]=callSpaceMouse()
      rho=sqrt(3)*80;
%     X=v(1); Y=v(2);
%         pt = get(0,'PointerLocation'); % get mouse position on screen
%         ptX = pt(1,1); % x mouse pos
%         ptY = pt(1,2); % y mouse pos
%         X = (ptX-S.screen(3)*.5)/S.screen(3)*2; 
%         Y = (ptY-S.screen(4)*.5)/S.screen(4)*2;
    v=Mouse3D('get');
% 	v.pos=rand(1,3)*rho;
% 	v.rot=rand(1,3);
    x=(v.pos(1)/rho);
    y=(v.pos(2)/rho);
    z=(v.pos(3)/rho);   
    p=v.rot(1);r=v.rot(3);w=(v.rot(2));
end