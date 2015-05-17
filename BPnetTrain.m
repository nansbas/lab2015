function [net,out] = BPnetTrain(net, input, output, rate)
  const = ones(1,size(input,2));
  in{1} = [input; const];
  for i = 1:length(net)
    in{i+1} = [sigmoid(net{i} * in{i}); const];
  end
  out = in{i+1};
  out = out(1:size(out,1)-1,:);
  if exist('output','var') 
    for i = length(net):-1:1
      if i == length(net)
        err = output - out;
        fprintf('BP training error: %f\n', mean(abs(err(:))));
      else
        err = net{i+1}' * err;
        err = err(1:size(err,1)-1,:);
      end
      net{i} = net{i} + err * in{i}' * rate;
    end
  end
end

function y = sigmoid(x)
  y = (exp(-x*10)+1).^(-1);
end