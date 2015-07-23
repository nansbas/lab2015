ethzv4 = [];
[rf,out] = MakeSimpleRF(9,0:5:175,[6,6]);
for i = 1:12
  for j = 1:length(ethz(i).files)
    fprintf('Run on image %d:%d:%s ... ... ', i, j, ethz(i).files(j).name);
    img = ethz(i).files(j).image;
    [out,ori,ridge] = SimpleCell(img, rf);
    [map,lines] = FindLine(ridge, ori, 0.8, 20);
    f = FindV4Feature(lines, 0.05, 20);
    ethzv4(i).files(j).v4 = f;
    ethzv4(i).files(j).lines = lines;
    rect = ethz(i).files(j).groundtruth;
    ethzv4(i).files(j).groundtruth = rect;
    ethzv4(i).files(j).name = ethz(i).files(j).name;
    rect(:,3:4) = rect(:,3:4) - rect(:,1:2);
    fprintf('OK\n');
  end
end
for i=1:12
  [c,dist,label,maxZero,x,y,s,d,a,n] = LearnV4ShapeModel(ethzv4(i).files);
  ethzv4(i).cluster.c = c;
  ethzv4(i).cluster.d = dist;
  ethzv4(i).model.label = label;
  ethzv4(i).model.maxZero = maxZero;
  ethzv4(i).model.x = x;
  ethzv4(i).model.y = y;
  ethzv4(i).model.s = s;
  ethzv4(i).model.d = d;
  ethzv4(i).model.a = a;
  ethzv4(i).model.n = n;
end
%% Run detection.
%{
for i=[4,5]
  runCat = i;
  result = [];
  for j=1:length(ethzv4(i).files)
    [r,jj]=FindV4ModelInImage(ethzv4(runCat).cluster,ethzv4(runCat).model,ethzv4(i).files(j));
    if i~=runCat && ~isempty(jj)
      jj(:,7) = 0;
    end
    if ~isempty(jj)
      jj = [repmat(i,size(jj,1),1),repmat(j,size(jj,1),1),jj];
    end
    result=[result;jj];
    fprintf('ok: %d, %d\n', i, j);
  end
  ethzv4(i).result = result;
end
allpos = [44,55,91,66,33];
[~,idx] = sort(result(:,8)/max(result(:,8))-result(:,7));
r = result(idx,:);
for i = 1:size(r,1)
  r(i,1) = sum(r(1:i,9)<=0.1)/255;
  r(i,2) = sum(r(1:i,9)>0.1)/allpos(runCat);
end
[~,idx] = unique(r(:,1));
idx2 = 1;
for i = 2:length(idx)
  idx2 = [idx2, idx(i)-1, idx(i)];
end
idx2 = [idx2, size(r,1)];
r = r(idx2,1:2);
close all
plot(r(:,1),r(:,2));
%}
%% Find where can set empty label.
%{
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
%}
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
