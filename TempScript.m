%% Find where can set empty label.
for i = [1,2,4,5]
  n = length(ethzv4(i).model.label);
  ignoreAfter = zeros(n,n);
  for j = 1:length(ethzv4(i).sample.label)
    k = ethzv4(i).sample.label{j};
    k(1) = 0;
    k = [k,n+1];
    for p = 2:length(k)
      for q = (k(p-1)+1):(k(p)-1)
        ignoreAfter(q,k(p-1)+1) = 1;
      end
    end
  end
  ethzv4(i).model.ignoreAfter = ignoreAfter;
end
%% Check label and cluster consistent.
%{
for i=[1,2,4,5]
 for j=1:length(ethzv4(i).sample.index)
  k=ethzv4(i).sample.index{j};
  for m=2:length(k)
   cl=ethzv4(i).sample.cluster{j}(m);
   la=ethzv4(i).sample.label{j}(m);
   if ~ismember(cl, ethzv4(i).model.label{la})
    fprintf('! warning: %d,%d,%d\n', i,j,m);
   end
  end
 end
end
%}