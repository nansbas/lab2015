function [x,y,s,d,a,n] = LearnV4ShapeModel(ethzv4)
  n = length(ethzv4.model.label);
  x = NewArray(n);
  y = NewArray(n);
  s = NewArray(n);
  d = NewArray(n);
  a = zeros(n,n,2); % mean, err
  n = zeros(n,n,1); % counter
  for i = 1:length(ethzv4.sample.index)
    k = ethzv4.sample.index{i};
    l = ethzv4.sample.label{i};
    v4 = ethzv4.files(k(1)).v4(k(2:length(k)),:);
    [x1,y1,s1,d1] = ComputePositionMatrix(v4);
    for j = 1:size(v4,1)
      for k = 1:size(v4,1)
        if j == k, continue; end
        lj = l(j+1);
        lk = l(k+1);
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
  for i = 1:length(ethzv4.sample.index)
    k = ethzv4.sample.index{i};
    l = ethzv4.sample.label{i};
    v4 = ethzv4.files(k(1)).v4(k(2:length(k)),:);
    [x1,y1,s1,d1,a1] = ComputePositionMatrix(v4);
    for j = 1:size(v4,1)
      for k = 1:size(v4,1)
        if j == k, continue; end
        lj = l(j+1);
        lk = l(k+1);
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

% Compute pairwise co-related position matrix of V4 features.
%   x: relative x position;
%   y: relative y position;
%   s: log relative scale;
%   d: relative distance (end-point distance, or, adjacency);
%   a: relative direction in atan2(y,x).
%   Relative means to divide by the scale of the row-indexed base feature.
function [x,y,s,d,a] = ComputePositionMatrix(v4)
  v4(:,10:12) = ComputePeakPointAndScale(v4);
  x = DiffMatrix(v4(:,10), v4(:,10), 1);
  y = DiffMatrix(v4(:,11), v4(:,11), 1);
  s = repmat(v4(:,12), 1, size(v4,1));
  x = x ./ s;
  y = y ./ s;
  d(:,:,1) = DiffMatrix(v4(:,1:2),v4(:,1:2),2);
  d(:,:,2) = DiffMatrix(v4(:,1:2),v4(:,3:4),2);
  d(:,:,3) = DiffMatrix(v4(:,3:4),v4(:,1:2),2);
  d(:,:,4) = DiffMatrix(v4(:,3:4),v4(:,3:4),2);
  d = min(d,[],3) ./ s;
  s = repmat(v4(:,12)', size(v4,1), 1) ./ s; 
  adj = (((DiffMatrix(v4(:,7),v4(:,7),1)>=0 & DiffMatrix(v4(:,8),v4(:,7),1)<=0) | ...
    (DiffMatrix(v4(:,7),v4(:,8),1)>=0 & DiffMatrix(v4(:,8),v4(:,8),1)<=0)) & ...
    DiffMatrix(v4(:,9), v4(:,9), 1) == 0);
  d(adj) = 0;
  s = log(s);
  a = atan2(y, x);
end

% Compute the middle peak point of V4 features.
function f = ComputePeakPointAndScale(v4)
  ab = sum(v4(:,5:6),2);
  ee = ones(size(v4,1),1);
  f(:,1) = sum(v4(:,1:4).*[ee,ab,ee,-ab],2)/2;
  f(:,2) = sum(v4(:,1:4).*[-ab,ee,ab,ee],2)/2;
  f(:,3) = sqrt(sum((v4(:,1:4)*[0.5,0;0,0.5;-0.5,0;0,-0.5]).^2,2));
end

% Compute difference matrix of two set of row vectors of specified width.
function f = DiffMatrix(rows1, rows2, width)
  if width == 1
    f = -repmat(rows1(:,1),1,size(rows2,1)) + repmat(rows2(:,1)',size(rows1,1),1);
  else
    f = zeros(size(rows1,1),size(rows2,1));
    for i = 1:width
      d = repmat(rows1(:,i),1,size(rows2,1)) - repmat(rows2(:,i)',size(rows1,1),1);
      f = f + d.^2;
    end
    f = sqrt(f);
  end
end

% Initialize array (mean, err, max, min).
function f = NewArray(n)
  f = zeros(n,n,4);
  f(:,:,3) = -inf;
  f(:,:,4) = inf;
end

