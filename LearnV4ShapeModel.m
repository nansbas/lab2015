% Learn V4 Shape Model.
%   files: struct-array with `v4`, `groundtruth`.
function [c,dist,label,maxZero,x,y,s,d,a,n] = LearnV4ShapeModel(files)
  % label positive samples.
  fprintf('label sample v4 features ... ... ');
  [c,label] = LabelSampleV4Feature(files);
  maxZero = max(sum(label(:,3:size(label,2))==0,2));
  fprintf('ok\n');
  % clustering.
  x = GetAllLabeledFeatures(files, label);
  for i = 1:20
    fprintf('clustering ... ... ');
    [c1,l,~,d,~] = ClusterV4Feature(c, x);
    fprintf(' mean(err) = %f\n', mean(d));
    if i > 1 && mean(d) >= mean(d0), break; end
    c0 = c;
    d0 = d;
    l0 = l;
    c = c1;
  end
  c = c0;
  dist = d0;
  % align cluster label and position label.
  label = cell(1,size(label,2)-2);
  for i = 1:length(l0)
    if ~ismember(l0(i),label{x(i,10)})
      label{x(i,10)} = cat(2, label{x(i,10)}, l0(i));
    end
  end
  % learn position model.
  v4 = x;
  [x,y,s,d,a,n] = LearnPositionModel(v4(:,1:9), v4(:,10), v4(:,11), length(label));
end

% Get all labeled features.
function f = GetAllLabeledFeatures(files, label)
  f = [];
  lsize = size(label,2);
  for i = 1:size(label,1)
    fidx = label(i,2);
    idx = 1:(lsize - 2);
    v4idx = label(i,3:lsize);
    idx = idx(v4idx ~= 0);
    v4idx = v4idx(v4idx ~= 0);
    v4 = files(fidx).v4(v4idx,1:9);
    v4(:,10) = idx;
    v4(:,11) = i;
    f = cat(1, f, v4);
  end
end

function [x,y,s,d,a,n] = LearnPositionModel(allv4, label, sampleIdx, nLabel)
  n = nLabel;
  x = NewArray(n);
  y = NewArray(n);
  s = NewArray(n);
  d = NewArray(n);
  a = zeros(n,n,2); % mean, err
  n = zeros(n,n,1); % counter
  for i = 1:max(sampleIdx)
    l = label(sampleIdx == i);
    v4 = allv4(sampleIdx == i, :);
    [x1,y1,s1,d1] = ComputeV4PositionMatrix(v4);
    for j = 1:size(v4,1)
      for k = 1:size(v4,1)
        if j == k, continue; end
        lj = l(j);
        lk = l(k);
        x(lj,lk,1) = x(lj,lk,1) + x1(j,k);
        y(lj,lk,1) = y(lj,lk,1) + y1(j,k);
        s(lj,lk,1) = s(lj,lk,1) + s1(j,k);
        d(lj,lk,1) = d(lj,lk,1) + d1(j,k);
        n(lj,lk) = n(lj,lk) + 1;
        a(lj,lk,1) = a(lj,lk,1) + x1(j,k)/sqrt(x1(j,k)^2+y1(j,k)^2);
        a(lj,lk,2) = a(lj,lk,2) + y1(j,k)/sqrt(x1(j,k)^2+y1(j,k)^2);
        if x1(j,k)>x(lj,lk,3), x(lj,lk,3)=x1(j,k); end
        if y1(j,k)>y(lj,lk,3), y(lj,lk,3)=y1(j,k); end
        if s1(j,k)>s(lj,lk,3), s(lj,lk,3)=s1(j,k); end
        if d1(j,k)>d(lj,lk,3), d(lj,lk,3)=d1(j,k); end
        if x1(j,k)<x(lj,lk,4), x(lj,lk,4)=x1(j,k); end
        if y1(j,k)<y(lj,lk,4), y(lj,lk,4)=y1(j,k); end
        if s1(j,k)<s(lj,lk,4), s(lj,lk,4)=s1(j,k); end
        if d1(j,k)<d(lj,lk,4), d(lj,lk,4)=d1(j,k); end
      end
    end
  end
  temp = x(:,:,1); temp(n>0) = temp(n>0) ./ n(n>0); x(:,:,1) = temp;
  temp = y(:,:,1); temp(n>0) = temp(n>0) ./ n(n>0); y(:,:,1) = temp;
  temp = s(:,:,1); temp(n>0) = temp(n>0) ./ n(n>0); s(:,:,1) = temp;
  temp = d(:,:,1); temp(n>0) = temp(n>0) ./ n(n>0); d(:,:,1) = temp;
  a(:,:,1) = atan2(a(:,:,2),a(:,:,1));
  a(:,:,2) = 0;
  for i = 1:max(sampleIdx)
    l = label(sampleIdx == i);
    v4 = allv4(sampleIdx == i, :);
    [x1,y1,s1,d1,a1] = ComputeV4PositionMatrix(v4);
    for j = 1:size(v4,1)
      for k = 1:size(v4,1)
        if j == k, continue; end
        lj = l(j);
        lk = l(k);
        x(lj,lk,2) = x(lj,lk,2) + (x(lj,lk,1)-x1(j,k))^2;
        y(lj,lk,2) = y(lj,lk,2) + (y(lj,lk,1)-y1(j,k))^2;
        s(lj,lk,2) = s(lj,lk,2) + (s(lj,lk,1)-s1(j,k))^2;
        d(lj,lk,2) = d(lj,lk,2) + (d(lj,lk,1)-d1(j,k))^2;
        da = abs(a1(j,k) - a(lj,lk,1));
        if da > 2*pi, da = da - 2*pi; end
        if da > pi, da = 2*pi - da; end
        if da > a(lj,lk,2), a(lj,lk,2) = da; end
      end
    end
  end
  temp = x(:,:,2); temp(n>0) = temp(n>0) ./ n(n>0); x(:,:,2) = sqrt(temp);
  temp = y(:,:,2); temp(n>0) = temp(n>0) ./ n(n>0); y(:,:,2) = sqrt(temp);
  temp = s(:,:,2); temp(n>0) = temp(n>0) ./ n(n>0); s(:,:,2) = sqrt(temp);
  temp = d(:,:,2); temp(n>0) = temp(n>0) ./ n(n>0); d(:,:,2) = sqrt(temp);
end

% Initialize array (mean, err, max, min).
function f = NewArray(n)
  f = zeros(n,n,4);
  f(:,:,3) = -inf;
  f(:,:,4) = inf;
end
