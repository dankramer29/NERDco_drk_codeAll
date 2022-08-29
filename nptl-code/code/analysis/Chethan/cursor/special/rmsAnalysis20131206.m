if ~exist('R','var')
    R1 = loadvar('/net/derivative/R/t6/t6.2013.12.06/R_7.mat','R');
    R2 = loadvar('/net/derivative/R/t6/t6.2013.12.06/R_7.mat','R');
    R = vertcat(R1,R2);
    clear R1 R2;
end

rmss = zeros(10,10);
rms = channelRMS(R);

[enum, xpos, ypos] = CerebusToCurly(1:96);

for nc = 1:length(enum)
    rmss(xpos(nc)+1,ypos(nc)+1) = rms(enum(nc));
end

figure(1);clf;
imagesc(rmss);
colorbar;


