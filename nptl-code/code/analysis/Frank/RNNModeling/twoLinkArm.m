%%
%equations follow "Fuzzy sliding?mode control of a human arm in the sagittal
%plane with optimal trajectory" Ardakani et al 2018
m1 = 1.8645719999999999;
m2 = 1.5343150000000001;

L1g = 0.18049599999999999;
L2g = 0.181479;

I1 = 0.013193;
I2 = 0.020062;

L1 = 0.29039999999999999;
L2 = 0.23558999999999999;

M11_f1 = m1*L1g + I1 + m2*(L2g^2 + L1^2) + I2;
M11_f2 = 2*m2*L1*L2g;
M12_f1 = m2*L2g^2 + I2;
M12_f2 = m2*L1*L2g;
M22_f1 = m2*L2g^2 + I2;

g = 9.81;
cViscosity = 0.1;

shoLimit = [-90, 180]*(pi/180);
elbLimit = [0, 130]*(pi/180);
limitRanges = [shoLimit; elbLimit];
limitStiffness = 20*(180/pi);
limitTransition = 10*(pi/180);
limitDamping = 0.25*(180/pi);

%%
%test rigid body dynamics for two link arm with gravity
x0 = [-4.58; 89.38; 0; 0]*(pi/180);

dt = 0.002;
nSteps = round(10*(1/dt));

xTraj = zeros(nSteps, 4);
xTraj(1,:) = x0;

for n=2:nSteps
    xc = xTraj(n-1,:)';
    c2 = cos(xc(2));
    s2 = sin(xc(2));
    s1 = sin(xc(1));
    s12 = sin(xc(1)+xc(2));

    M = [M11_f1 + M11_f2*c2, M12_f1 + M12_f2*c2;
        M12_f1 + M12_f2*c2, M22_f1];
    C = [-m2*L1*L2g*(2*xc(3)*xc(4)+xc(4)^2)*s2 + cViscosity*xc(3);
            m2*L1*L2g*xc(3)^2*s2 + cViscosity*xc(4)];
    G = [(m1*L1g+m2*L1)*g*s1 + m2*g*L2g*s12;
        m2*g*L2g*s12];

    %joint limit forces
    limitTrq = zeros(2,1);
    for jntIdx = 1:2
        if xc(jntIdx)<limitRanges(jntIdx,1)
            %lower limit exceeded
            violationSize = limitRanges(jntIdx,1)-xc(jntIdx);
            if xc(jntIdx)>(limitRanges(jntIdx,1)-limitTransition)
                %in the transition region
                transitionStiffness = limitStiffness*(limitRanges(jntIdx,1)-xc(jntIdx))/limitTransition;
            else
                %out of transition region
                transitionStiffness = limitStiffness;
            end
            limitTrq(jntIdx) = transitionStiffness*violationSize - limitDamping*xc(2+jntIdx);

        elseif xc(jntIdx)>limitRanges(jntIdx,2)
            %upper limit exceeded
            violationSize = limitRanges(jntIdx,2)-xc(jntIdx);
            if xc(jntIdx)<(limitRanges(jntIdx,2)+limitTransition)
                %in the transition region
                transitionStiffness = limitStiffness*(xc(jntIdx)-limitRanges(jntIdx,2))/limitTransition;
            else
                %out of transition region
                transitionStiffness = limitStiffness;
            end
            limitTrq(jntIdx) = transitionStiffness*violationSize - limitDamping*xc(2+jntIdx);
        end
    end

    cTrq = [0; 0];
    accel = M\(-C-G+limitTrq+cTrq);

    xTraj(n,3:4) = xc(3:4) + accel*dt;
    xTraj(n,1:2) = xc(1:2) + xc(3:4)*dt;
end