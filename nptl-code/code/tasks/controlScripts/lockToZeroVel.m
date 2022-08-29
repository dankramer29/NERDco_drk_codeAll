% Sets bias to zero so output velocity is zero.
preLockGain =  getModelParam('gain'); 
setModelParam( 'gain', zeros( size( preLockGain ) ) );
fprintf('Locking velocity gain to 0. Use ''unlockZeroVel'' to unlock\n');

%
% Sergey Stavisky 1 February 2018