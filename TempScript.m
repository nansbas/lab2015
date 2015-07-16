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