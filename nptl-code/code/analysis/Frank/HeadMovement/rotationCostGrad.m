function [ grad ] = rotationCostGrad( x, target_unroll, data_unroll )
    grad = (-2*(target_unroll - data_unroll*x(:))'*data_unroll);
    grad = reshape(grad, [2 2]);
end

