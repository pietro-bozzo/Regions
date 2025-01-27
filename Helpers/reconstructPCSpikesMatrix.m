function [Z, pc, explainedVariance] = reconstructPCSpikesMatrix(spikesMatrix, opt)
arguments
    spikesMatrix
    opt.pc = NaN
    opt.var = 0.5
    opt.first = true
end
    mu = mean(spikesMatrix);
    centeredSpikesData = spikesMatrix - mu;
    covar = cov(centeredSpikesData);

    [eigenvectors,eigenvalues] = eig(covar);
    [eigenvalues,i] = sort(diag(eigenvalues),'descend');
    eigenvectors = eigenvectors(:,i);
    
    explainedVariance = cumsum(eigenvalues)/sum(eigenvalues);
    if isnan(opt.pc)
        threshold = explainedVariance >= opt.var;
        pc = find(threshold, 1);
    else
        pc = opt.pc;
    end

    if opt.first
        pcs = 1:pc;
    else
        pcs = pc+1:size(centeredSpikesData, 2);
    end

    V = eigenvectors(:,pcs);
    P = V * (V');
    
    Z = centeredSpikesData * P + mu;
end