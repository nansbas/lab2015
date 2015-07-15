function [c,l,n,d] = ClusterV4Feature(c, ethzv4, mode)
  x = [];
  for i = 1:length(ethzv4.sample)
    k = ethzv4.sample{i};
    x = cat(1, x, ethzv4.files(k(1)).v4(k(2:length(k)),1:6));
  end
  [c,l1,n,d] = Cluster(c(:,1:6), x);
  j = 1;
  for i = 1:length(ethzv4.sample)
    k = ethzv4.sample{i};
    range = j:j+length(k)-2;
    if exist('mode','var') && (strcmp(mode,'label') || strcmp(mode,'drawlabel'))
      l1(range) = FeaturePosition(ethzv4.model.label, l1(range));
    end
    if exist('mode','var') && (strcmp(mode,'draw') || strcmp(mode,'drawlabel'))
      v4 = x(range,:);
      v4(:,9) = l1(range);
      FindV4Feature('draw', v4);
      saveas(gcf,['temp/label-',num2str(i),'.png']);
      close gcf;
    end
    l{i} = [k(1), l1(range)'];
    j = j + length(k) - 1;
  end
end

% Get feature position according to feature cluster label. 
function p = FeaturePosition(label, f)
  p = f;
  i = 1;
  j = 1;
  while i <= length(f) && j <= length(label)
    if ismember(f(i), label{j})
      p(i) = j;
      i = i + 1;
    end
    j = j + 1;
  end
end

% Cluster V4 features with k-means.
function [c,l,n,d] = Cluster(c, x)
  x = NormalizeV4(x);
  c = NormalizeV4(c);
  d1 = DiffMatrix(x(:,1:2), c(:,1:2), 2);
  d2 = DiffMatrix(x(:,3:4), c(:,1:2), 2);
  da = DiffMatrix(x(:,5), c(:,5), 1);
  db = DiffMatrix(x(:,6), c(:,6), 1);
  dmu = MuDiff(da, db);
  da = DiffMatrix(-x(:,5), c(:,5), 1);
  db = DiffMatrix(-x(:,6), c(:,6), 1);
  dmu2 = MuDiff(da, db);
  reverse = (d2 < d1);
  dmu(reverse) = dmu2(reverse);
  d1(reverse) = d2(reverse);
  d = d1/2 + dmu;
  [md, l] = min(d, [], 2);
  n = ones(1,size(c,1));
  d = zeros(1,size(c,1));
  for i = 1:size(x,1)
    if reverse(i,l(i))
      x(i,1:4) = x(i,[3,4,1,2]);
      x(i,5:6) = -x(i,5:6);
    end
    n(l(i)) = n(l(i)) + 1;
    c(l(i),1:6) = c(l(i),1:6) + x(i,1:6);
    if md(i) > d(l(i))
      d(l(i)) = md(i);
    end
  end
  for i = 1:size(c,1)
    c(i,1:6) = c(i,1:6) / n(i);
  end
  c = NormalizeV4(c);
  n = n - 1;
end

% Normalize V4 feature.
function v = NormalizeV4(v)
  v(:,1:4) = v(:,1:4)*[1,0,-1,0;0,1,0,-1;-1,0,1,0;0,-1,0,1];
  v(:,1:4) = v(:,1:4)./repmat(sqrt(sum(v(:,1:2).^2,2)),1,4);
end

% Compute difference matrix of two set of row vectors of specified width.
function f = DiffMatrix(rows1, rows2, width)
  if width == 1
    f = abs(repmat(rows1(:,1),1,size(rows2,1)) - repmat(rows2(:,1)',size(rows1,1),1));
  else
    f = zeros(size(rows1,1),size(rows2,1));
    for i = 1:width
      d = repmat(rows1(:,i),1,size(rows2,1)) - repmat(rows2(:,i)',size(rows1,1),1);
      f = f + d.^2;
    end
    f = sqrt(f);
  end
end

% Calculate difference of features for parameters a, b.
function f = MuDiff(a,b)
  f = 0.4*(a.^2)+16/15*(b.^2)+1.2*(a.*b);
end