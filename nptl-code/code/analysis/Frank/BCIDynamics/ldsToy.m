nDim = 3;
W = zeros(nDim);
for x = 1:nDim
    W(x,x) = 0.0;
    if x<nDim
        W(x,x+1) = 1.0;
    end
end
W(end,1) = 1.0;

%%
x0 = zeros(nDim,1);
x0(end) = 1;

x0 = randn(nDim,1);

nSteps = 100;
state = zeros(nDim, nSteps);
state(:,1) = x0;

for n=1:(nSteps-1)
    state(:,n+1) = W*state(:,n);
end

%%
[V,D] = eig(W);
eigenValues = diag(D);

ep = V'*x0;
eds = zeros(nDim, nSteps);
eds(:,1) = ep;
for n=1:(nSteps-1)
    eds(:,n+1) = eds(:,n).*eigenValues;
end

realState = real(V*eds);

%%
delT = 0.05;
A = [1-delT^2, delT;
    -delT, 1;];
[V,D] = eig(A);

x0 = [1; 0];
nSteps = 300;
state = zeros(2, nSteps);
state(:,1) = x0;

for n=1:(nSteps-1)
    state(:,n+1) = A*state(:,n);
end

%%
nDim = 3;
A = randn(nDim);
for x=1:nDim
    A(x,x) = A(x,x) + 5;
end

[U,S,V] = svd(A);
A = U*V';
A = A * 0.99;

[V,D] = eig(A);

x0 = randn(nDim,1);
nSteps = 300;
state = zeros(nDim, nSteps);
state(:,1) = x0;

for n=1:(nSteps-1)
    state(:,n+1) = A*state(:,n);
end

figure
plot3(state(1,:), state(2,:), state(3,:));

%%
nDim = 4;
A = randn(nDim);
for x=1:nDim
    A(x,x) = A(x,x) + 10;
end

[U,S,V] = svd(A);
A = U*V';
A = A * 1.0;

[V,D] = eig(A);

x0 = randn(nDim,1);
nSteps = 300;
state = zeros(nDim, nSteps);
state(:,1) = x0;

for n=1:(nSteps-1)
    state(:,n+1) = A*state(:,n);
end

figure
plot(state(1,:));

figure
plot(state(1,:), state(2,:));

figure
plot3(state(1,:), state(2,:), state(3,:));
