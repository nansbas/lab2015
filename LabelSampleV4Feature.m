% Lable V4 features in positive sample images.
%   files: struct-array with `v4`, `groundtruth`.
%   Function returns cluster centers and labels for each groundtruth.
%   label: each row start with row-index, file-index, followed by V4
%   feature index corresponding to each label from 1-14. Zero for no
%   corresponding feature.
function [c,label] = LabelSampleV4Feature(files)
  x = NormaliseV4ComputePositionScale(files);
  % sort v4 sets in ascending order of size.
  len = [];
  for i = 1:length(x)
    len(i) = size(x{i},1);
  end
  [~,idx] = sort(len);
  for i = 1:length(idx)
    x1{i} = x{idx(i)};
  end
  % run clustering 8 times.
  c = [];
  for i = 1:8
    [c,~,count,~] = ClusterFeatures(c, x1);
  end
  % take the biggest 14 clusters.
  [~,idx] = sort(count, 'descend');
  c = c(idx,:);
  c = c(1:14,:);
  % label all v4 sets.
  label = zeros(length(x),16);
  for i = 1:length(x)
    [xlabel,~,~] = AssignFeatureLabel(c,x{i});
    for j = 1:length(xlabel)
      if xlabel(j) ~= 0
        label(i,xlabel(j) + 2) = x{i}(j,13);
      end
    end
    label(i,1) = i;
    label(i,2) = x{i}(1,14);
    % idx = label(i,label(i,:)~=0);
    % FindV4Feature('draw', files(x{i}(1,14)).v4(idx,:));
    % saveas(gcf, ['temp/test-',num2str(i),'.png']);
    % close(gcf);
  end
end

% Cluster features.
function [c, label, count, cover] = ClusterFeatures(c, x)
  n = size(c,1);
  count = zeros(1,n);
  cx = cell(1,n);
  cover = [];
  for i = 1:length(x)
    [xlabel,~,r] = AssignFeatureLabel(c,x{i});
    for j = 1:length(xlabel)
      if xlabel(j) ~= 0
        v4 = x{i}(j,:);
        if r(j)
          v4(1:4) = v4([3,4,1,2]);
          v4(5:6) = -v4(5:6);
        end
        cx{xlabel(j)} = cat(1, cx{xlabel(j)}, v4);
        count(xlabel(j)) = count(xlabel(j)) + 1;
      else
        n = n + 1;
        cx{n} = x{i}(j,:);
        count(n) = 1;
        xlabel(j) = n;
        c = cat(1, c, x{i}(j,:));
      end
      cover(xlabel(j),i) = 1;
    end
    label{i} = xlabel;
  end
  for i = 1:n
    if count(n) < 1, continue; end
    c(i,:) = mean(cx{i},1);
  end
  c = NormalizeV4(c);
end

% Assign features with cluster label.
% Function returns label (zero for not labeled), distance to cluster
% center, and whether features are reversed.
function [xlabel, dist, r] = AssignFeatureLabel(c, x)
  if isempty(c)
    xlabel = zeros(1,size(x,1));
    dist = zeros(1,size(x,1));
    r = zeros(1,size(x,1));
    return
  end
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
  d = d1/2 + dmu + DiffMatrix(x(:,10:11), c(:,10:11), 2) * 2.3856;
  [cidx,xidx] = meshgrid(1:size(c,1),1:size(x,1));
  [~,idx] = sort(d(:));
  cused = zeros(1,size(c,1));
  xlabel = zeros(1,size(x,1));
  dist = zeros(1,size(x,1));
  r = zeros(1,size(x,1));
  for i = idx'
    ci = cidx(i);
    xi = xidx(i);
    if d(xi,ci) > 1, break; end
    if cused(ci) == 0 && xlabel(xi) == 0
      cused(ci) = 1;
      xlabel(xi) = ci;
      dist(xi) = d(xi,ci);
      r(xi) = reverse(xi,ci);
    end
  end
end

% Extract positive samples.
% Normalise V4 feature; put position and scale at columns 10:12.
function f = NormaliseV4ComputePositionScale(files)
  n = 1;
  f = {};
  for i = 1:length(files)
    v4 = files(i).v4;
    v4(:,10:12) = ComputePeakPointAndScale(v4);
    v4(:,13) = 1:size(v4,1);
    v4(:,14) = i;
    for j = 1:size(files(i).groundtruth,1)
      gt = files(i).groundtruth(j,:);
      ingt = (v4(:,1) <= gt(3) & v4(:,1) >= gt(1) & v4(:,2) <= gt(4) & v4(:,2) >= gt(2)) ...
        | (v4(:,3) <= gt(3) & v4(:,3) >= gt(1) & v4(:,4) <= gt(4) & v4(:,4) >= gt(2)) ...
        | (v4(:,10) <= gt(3) & v4(:,10) >= gt(1) & v4(:,11) <= gt(4) & v4(:,11) >= gt(2));
      v4gt = v4(ingt,:);
      v4gt = NormalizeV4(v4gt);
      v4gt(:,10:11) = (v4gt(:,10:11) - repmat(gt(1:2), size(v4gt,1),1)) * [1/(gt(3)-gt(1)),0;0,1/(gt(4)-gt(2))];
      v4gt(:,12) = v4gt(:,12) / sqrt((gt(4)-gt(2))*(gt(3)-gt(1)));
      f{n} = v4gt;
      n = n + 1;
    end
  end
end

% Compute the middle peak point of V4 features.
function f = ComputePeakPointAndScale(v4)
  ab = sum(v4(:,5:6),2);
  ee = ones(size(v4,1),1);
  f(:,1) = sum(v4(:,1:4).*[ee,ab,ee,-ab],2)/2;
  f(:,2) = sum(v4(:,1:4).*[-ab,ee,ab,ee],2)/2;
  f(:,3) = sqrt(sum((v4(:,1:4)*[0.5,0;0,0.5;-0.5,0;0,-0.5]).^2,2));
end

% Normalize V4 feature.
function v = NormalizeV4(v)
  v(:,1:4) = v(:,1:4)*[1,0,-1,0;0,1,0,-1;-1,0,1,0;0,-1,0,1];
  v(:,1:4) = v(:,1:4)./repmat(sqrt(sum(v(:,1:2).^2,2)),1,4);
end

% Calculate difference of features for parameters a, b.
function f = MuDiff(a,b)
  f = 0.4*(a.^2)+16/15*(b.^2)+1.2*(a.*b);
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
