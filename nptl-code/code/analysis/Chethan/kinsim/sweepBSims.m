bks = {'beata','frank','cp'};
thresh =  [0.0871 0.1948    0.3373    0.5187    0.6949    0.8368];


simtype = {'uniform','path'};
simnames = {'simUniform.mat','simPath.mat'};

numsims = 10;

for nsim = 1%:2
    clear res
    load(simnames{nsim})
    for nb = numel(bks)
        for nt = 1:numel(thresh)
            %if nsim ==1
            %    numsims = 3;
            %else
            %end
            for nn = 1:numsims
                tic;
                ts = thresh(nt);
                fprintf('running %i, %i, trial %i\n',nb,nt,nn);
                out=runKinSim(bks{nb},simtype{nsim},ts);
                if ~exist('res','var')
                    res = out;
                else
                    res(nb,nt,nn) = out;
                end
                toc;
            end
        end
    end
    
    save(simnames{nsim}, 'res', '-v7.3')
end