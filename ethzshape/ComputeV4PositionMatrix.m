% Compute pairwise co-related position matrix of V4 features.
%   v4: column 1-9 is used; 7-9 for adjacency measure;
%   x: relative x position;
%   y: relative y position;
%   s: log relative scale;
%   d: relative distance (end-point distance, or, adjacency);
%   a: relative direction in atan2(y,x).
%   Relative means to divide by the scale of the row-indexed base feature.
function [x,y,s,d,a] = ComputeV4PositionMatrix(v4)
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
