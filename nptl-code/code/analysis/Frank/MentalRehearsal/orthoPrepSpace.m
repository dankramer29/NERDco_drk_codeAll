function [ x ] = orthoPrepSpace( featureAverages, nPrep, nMov, prepIdx, movIdx )
    %feature averages is N x C x T (N features, C conditions, T time steps)
    %nPrep and nMov are the number of prep and move dimensions
    %prepIdx are the time indices for prep, movIdx are the time indices for
    %movement
    
    nChans = size(featureAverages,1);
    nCon = size(featureAverages,2);
    dim_n = nChans;
    dim_p = nPrep + nMov;

    manifold = stiefelfactory(dim_n, dim_p);
    problem.M = manifold;

    % Define the problem cost function and its gradient.
    fa = featureAverages;
    fa = fa - repmat(nanmean(fa, 2),[1,nCon,1]);

    tmp = squeeze(fa(:,:,prepIdx));
    tmp = reshape(tmp, nChans, [])';
    C_prep = cov(tmp);
    S_prep = svd(C_prep);
    sum_s_prep = sum(S_prep(1:nPrep));

    tmp = squeeze(fa(:,:,movIdx));
    tmp = reshape(tmp, nChans, [])';
    C_mov = cov(tmp);
    S_mov = svd(C_mov);
    sum_s_mov = sum(S_mov(1:nMov));

    p_sel = [eye(nPrep); zeros(nMov, nPrep)];
    m_sel = [zeros(nPrep, nMov); eye(nMov)];

    problem.cost  = @(x) -0.5*(trace((x*p_sel)'*C_prep*(x*p_sel))/sum_s_prep + ...
        trace((x*m_sel)'*C_mov*(x*m_sel))/sum_s_mov);

    problem.egrad = @(x) (-0.5/sum_s_prep)*(C_prep*x*(p_sel*p_sel') + C_prep'*x*(p_sel*p_sel')) + ...
        (-0.5/sum_s_mov)*(C_mov*x*(m_sel*m_sel') + C_mov'*x*(m_sel*m_sel'));

    %problem.ehess = @(x, xdot) -2*A*xdot;

    % Numerically check gradient and Hessian consistency.
    %figure;
    %checkgradient(problem);
    %figure;
    %checkhessian(problem);

    % Solve.
    [x, xcost, info] = trustregions(problem);
end

