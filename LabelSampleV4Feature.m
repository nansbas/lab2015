% Lable V4 features in positive sample images.
%   files: struct-array with `v4`, `groundtruth`.
%   nposition: number of positions.
%   initModel: initial model from template.
%   Function returns cluster centers and labels for each groundtruth.
%   label: each row start with row-index, file-index, followed by V4
%   feature index corresponding to each position label. Zero for no
%   corresponding feature.
function [c,label] = LabelSampleV4Feature(files, nposition, initModel)
  x = ExtractNormalisedV4WithMask(files);
  % cluster and label data.
  c = ClusterFeatures(initModel, x, nposition, [6,6], 1);
  label = LabelFeatures(c, x, [6,6], 1);
  % draw result.
  %
  nposition = size(c,1);
  for i = 1:length(x)
    idx = label(i,3:nposition+2);
    idx = idx(idx~=0);
    if isempty(idx), continue; end
    FindV4Feature('draw', files(x{i}(1,14)).v4(idx,:));
    saveas(gcf, ['temp/test-',num2str(i),'.png']);
    close(gcf);
  end
  %}
end

% Label features.
function f = LabelFeatures(c, x, positionFact, threshold)
  n = size(c,1);
  f = zeros(length(x),n+2);
  f(:,1) = 1:length(x);
  for i = 1:length(x)
    f(i,2) = x{i}(1,14);
    label = AssignFeatureLabel(c, x{i}, positionFact, threshold);
    for j = 1:length(label)
      if label(j) ~= 0
        f(i,label(j)+2) = x{i}(j,13);
      end
    end
  end
end

% Cluster features.
function c = ClusterFeatures(c, x, nposition, positionFact, threshold)
  n = size(c,1);
  cx = cell(1,n);
  for i = 1:length(x)
    [label,~,r] = AssignFeatureLabel(c, x{i}, positionFact, threshold);
    for j = 1:length(label)
      v4 = x{i}(j,1:12);
      if label(j) ~= 0
        if r(j)
          v4(1:4) = v4([3,4,1,2]);
          v4(5:6) = -v4(5:6);
        end
        cx{label(j)} = cat(1, cx{label(j)}, v4);
      else
        n = n + 1;
        cx{n} = v4;
      end
    end
  end
  count = zeros(1,n);
  for i = 1:n
    count(i) = size(cx{i},1);
    if count(i) < 1, continue; end
    c(i,1:12) = mean(cx{i},1);
  end
  [~,idx] = sort(count, 'descend');
  c = c(idx,:);
  c = NormalizeV4(c);
  c = c(1:min(nposition,n),:);
end

% Assign features with cluster label.
% Function returns label (zero for not labeled), distance to cluster
% center, and whether features are reversed.
function [xlabel, dist, r] = AssignFeatureLabel(c, x, positionFact, threshold)
  if isempty(c)
    xlabel = zeros(1,size(x,1));
    dist = zeros(1,size(x,1));
    r = zeros(1,size(x,1));
    return
  end
  d1 = DiffMatrix(x(:,1:2), c(:,1:2), [1,1]);
  d2 = DiffMatrix(x(:,3:4), c(:,1:2), [1,1]);
  da = DiffMatrix(x(:,5), c(:,5), 1);
  db = DiffMatrix(x(:,6), c(:,6), 1);
  dmu = MuDiff(da, db);
  da = DiffMatrix(-x(:,5), c(:,5), 1);
  db = DiffMatrix(-x(:,6), c(:,6), 1);
  dmu2 = MuDiff(da, db);
  reverse = (d2 < d1);
  dmu(reverse) = dmu2(reverse);
  d1(reverse) = d2(reverse);
  d = d1/2 + dmu + DiffMatrix(x(:,10:11), c(:,10:11), positionFact.^2); % 2.3856 = max(d1/2+dmu)/sqrt(2).
  [cidx,xidx] = meshgrid(1:size(c,1),1:size(x,1));
  [~,idx] = sort(d(:));
  cused = zeros(1,size(c,1));
  xlabel = zeros(1,size(x,1));
  dist = zeros(1,size(x,1));
  r = zeros(1,size(x,1));
  for i = idx'
    ci = cidx(i);
    xi = xidx(i);
    if d(xi,ci) > threshold, break; end
    if cused(ci) == 0 && xlabel(xi) == 0
      cused(ci) = 1;
      xlabel(xi) = ci;
      dist(xi) = d(xi,ci);
      r(xi) = reverse(xi,ci);
    end
  end
end

% Extract positive samples with mask.
% Normalise V4 feature; put position and scale at columns 10:12.
% Put v4 index and file index at columns 13,14.
function f = ExtractNormalisedV4WithMask(files)
  n = 1;
  f = {};
  for i = 1:length(files)
    v4 = files(i).v4;
    v4(:,10:12) = ComputePeakPointAndScale(v4);
    v4(:,13) = 1:size(v4,1);
    v4(:,14) = i;
    if isfield(files(i),'mask')
      mask = files(i).mask;
      [x,y] = meshgrid(1:size(mask,2),1:size(mask,1));
      mask = [x(mask),y(mask)];
    end
    for j = 1:size(files(i).groundtruth,1)
      gt = files(i).groundtruth(j,:);
      ingt = (v4(:,1) <= gt(3) & v4(:,1) >= gt(1) & v4(:,2) <= gt(4) & v4(:,2) >= gt(2)) ...
        | (v4(:,3) <= gt(3) & v4(:,3) >= gt(1) & v4(:,4) <= gt(4) & v4(:,4) >= gt(2)) ...
        | (v4(:,10) <= gt(3) & v4(:,10) >= gt(1) & v4(:,11) <= gt(4) & v4(:,11) >= gt(2));
      v4gt = v4(ingt,:);
      if isfield(files(i),'mask')
        d = zeros(size(v4gt,1),3);
        d(:,1) = min(DiffMatrix(v4gt(:,1:2), mask, [1,1]),[],2);
        d(:,2) = min(DiffMatrix(v4gt(:,3:4), mask, [1,1]),[],2);
        d(:,3) = min(DiffMatrix(v4gt(:,10:11), mask, [1,1]),[],2);
        d = max(d,[],2);
        v4gt = v4gt(d<8,:);
      end
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
  if length(width) == 1
    f = width * abs(repmat(rows1(:,1),1,size(rows2,1)) - repmat(rows2(:,1)',size(rows1,1),1));
  else
    f = zeros(size(rows1,1),size(rows2,1));
    for i = 1:length(width)
      d = repmat(rows1(:,i),1,size(rows2,1)) - repmat(rows2(:,i)',size(rows1,1),1);
      f = f + d.^2 * width(i);
    end
    f = sqrt(f);
  end
end
