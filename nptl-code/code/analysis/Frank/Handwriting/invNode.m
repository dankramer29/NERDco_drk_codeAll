function [ outAll ] = invNode( inp, inpNodes, inpGain )
    theta = linspace(0,2*pi,size(inpNodes,1)+1);
    theta = theta(1:size(inpNodes,1));
    outputNodes = [cos(theta)', sin(theta)'].*(1./inpGain);

    outAll = zeros(size(inp,1),2);

    for x=1:size(inp,1)
        dist = sum((inpNodes-inp(x,:)/norm(inp(x,:))).^2,2);
        weight = 1./dist.^(1/2);
        weight = weight / sum(weight);
        out = outputNodes.*weight*norm(inp(x,:));
        outAll(x,:) = sum(out);
    end
end

