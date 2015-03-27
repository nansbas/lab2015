function [model, input] = LearnV4(model, input, rect, ratio, learnrate)
    inrect = (input(:,5)>=rect(1) & input(:,5)<=rect(3) & input(:,6)>=rect(2) & input(:,6)<=rect(4));
    input = input(inrect,:);
    ry = rect(4) - rect(2);
    rx = (rect(3) - rect(1)) / ratio;
    input(:,4) = input(:,4) / sqrt(rx*ry);
    input(:,5) = (input(:,5)-rect(1)) / rx;
    input(:,6) = (input(:,6)-rect(2)) / ry;
    input = [input; input(:,[2,1,3:6,11:14,7:10])];
    mm = repmat(reshape(model(:,1:11),[size(model,1),1,11]),[1,size(input,1),1]);
    ms = repmat(reshape(model(:,12:22),[size(model,1),1,11]),[1,size(input,1),1]);
    mi = repmat(reshape(input(:,4:14),[1,size(input,1),11]),[size(model,1),1,1]);
    [sim,idx] = Max2(exp(-sum(((mm - mi).^2)./ms, 3)));
    input = input(idx, :);
    sim = sim .* input(:,3) / max(input(:,3));
    sim = repmat(sim,[1,11]);
    diff = input(:,4:14) - model(:,1:11);
    model(:,1:11) = model(:,1:11) + (sim.*diff)*learnrate;
    diff = diff.^2 - model(:,12:22);
    model(:,12:22) = model(:,12:22)*(1-learnrate) + (sim.*diff)*learnrate;
end