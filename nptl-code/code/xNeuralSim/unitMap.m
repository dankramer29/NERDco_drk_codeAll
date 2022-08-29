function N=unitMap(sel,nch)

% Should allow users to choose presets or randoms. Does not yet
    % AAS 05 27 11
    if strcmpi(sel,'Sphere') % spherical shell
        theta=rand(1,nch)*2*pi;
        phi=rand(1,nch)*2*pi;
        N(1,:)=sin(theta).*cos(phi);
        N(2,:)=sin(theta).*sin(phi);
        N(3,:)=cos(theta);
    elseif strcmpi(sel,'r') % random within unit sphere
        % THIS SHOULD NEVER BE USED.
        theta=rand(1,nch)*2*pi;
        phi=rand(1,nch)*2*pi;
        r=rand(1,nch);
        N(1,:)=r.*sin(theta).*cos(phi);
        N(2,:)=r.*sin(theta).*sin(phi);
        N(3,:)=r.*cos(theta);
    elseif strcmpi(sel,'Cube') % cube (side length 1.155)
        coords=repmat([1 1 1],[8 1]).*...
            ((dec2bin(0:7,3)-'0')-.5)*2*1.155/2;
        N(1:3,:)=repmat(coords',[1 floor(nch/8)]);
    elseif strcmpi(sel,'Centered') % centered
        N(1:3,:)=zeros(3,nch);
    elseif strcmpi(sel,'Dodecahedron') % dodecahedron (side length 0.714)
        phi=(1+sqrt(5))/2;
        coords=[repmat([1 1 1],[8 1]).*...
            ((dec2bin(0:7)-'0')-.5)*2;
            repmat([0 1/phi phi],[4 1]).*...
            [ones(4,1) ((dec2bin(0:3,2)-'0')-.5)*2];
            repmat([1/phi phi 0],[4 1]).*...
            [((dec2bin(0:3,2)-'0')-.5)*2 ones(4,1)];
            repmat([1/phi 0 phi],[4 1]).*...
            [1 0 1; 1 0 -1; -1 0 1; -1 0 -1]]/sqrt(3);
        N(1:3,:)=[repmat(coords',[1 floor(nch/20)])...
            zeros(3,mod(nch,20))];
    elseif strcmpi(sel,'Icosahedron') % icosahedron (side length 0.714)
        phi=(1+sqrt(5))/2;
        coords=[repmat([0 1/phi phi],[4 1]).*...
            [ones(4,1) ((dec2bin(0:3,2)-'0')-.5)*2];
            repmat([1/phi phi 0],[4 1]).*...
            [((dec2bin(0:3,2)-'0')-.5)*2 ones(4,1)];
            repmat([1/phi 0 phi],[4 1]).*...
            [1 0 1; 1 0 -1; -1 0 1; -1 0 -1]];
                N(1:3,:)=[repmat(coords',[1 floor(nch/12)])...
            zeros(3,mod(nch,12))]/1.902;
    else N=zeros(3,nch);
    end
    N(4,1:nch)=2*rand(1,nch)-1;
    N(5:7,:)=N(1:3,randperm(nch));
end