% Match two V4 feature arrays.
%   arr1 and arr2 is two V4 feature arrays, each feature in a row. arr1 is
%   treated as a model/template, which is circulated and reversed to find
%   the best match to arr2.
%   line1 and line2 is the corresponding lines, each point in a row.
%   The return values mcs is the maximal common sub-array of features.
%   avgDiff is the average difference between the line points of matched
%   features. cs is the index of matched features. tran is the transform to
%   map line1 to line2. It is assumed that the transform involves only
%   transition and scaling.
function [mcs,avgDiff,cs,tran] = MatchV4Array(arr1, line1, arr2, line2)
  mcs = [];
  avgDiff = [];
  cs = {};
  tran = {};
  j = 1;
  for i = 1:size(arr1,1);
    idx = [i:size(arr1,1),1:i-1];
    [m,d,c,t] = DirectMatch(arr1(idx,:),line1,arr2,line2);
    if ~isempty(c) && m > 0
      c(:,1) = idx(c(:,1));
      mcs(j) = m;
      avgDiff(j) = d;
      cs{j} = c;
      tran{j} = t;
      j = j + 1;
    end
    [m,d,c,t] = DirectMatch(ReverseV4Array(arr1(idx,:),size(line1,1)),flipud(line1),arr2,line2);
    idx = fliplr(idx);
    if ~isempty(c) && m > 0
      c(:,1) = idx(c(:,1));
      mcs(j) = m;
      avgDiff(j) = d;
      cs{j} = c;
      tran{j} = t;
      j = j + 1;
    end
  end
  if j > 1
    idx = (mcs == max(mcs));
    minDiff = min(avgDiff(idx));
    idx = idx & (avgDiff == minDiff);
    seq = 1:(j-1);
    seq = seq(idx);
    seq = seq(1);
    mcs = mcs(seq);
    avgDiff = avgDiff(seq);
    cs = cs{seq};
    tran = tran{seq};
  else
    mcs = 0;
    avgDiff = Inf;
    cs = [];
    tran = [];
  end
end

% Reverse an array of V4 features.
function arr = ReverseV4Array(arr, len)
  arr = flipud(arr);
  arr(:,1:4) = arr(:,[3,4,1,2]);
  arr(:,5:6) = -arr(:,5:6);
  arr(:,7:8) = len - arr(:,[8,7]) + 1;
end

% Direct match two arrays of V4 features using a dynamic programming
% approach, similar to free-space-diagram.
function [m,d,c,t] = DirectMatch(arr1, l1, arr2, l2)
  a1 = NormalizeV4(arr1);
  a2 = NormalizeV4(arr2);
  m = zeros(size(a1,1),size(a2,1));
  d = zeros(size(a1,1),size(a2,1));
  c = cell(size(a1,1),size(a2,1));
  t = cell(size(a1,1),size(a2,1));
  for i = 1:size(a1,1)
    for j = 1:size(a2,1)
      if j > 1 && (m(i,j-1)>m(i,j) || (m(i,j-1)==m(i,j) && d(i,j-1)<d(i,j)))
        m(i,j) = m(i,j-1);
        d(i,j) = d(i,j-1);
        c{i,j} = c{i,j-1};
        t{i,j} = t{i,j-1};
      end
      if i > 1 && (m(i-1,j)>m(i,j) || (m(i-1,j)==m(i,j) && d(i-1,j)<d(i,j)))
        m(i,j) = m(i-1,j);
        d(i,j) = d(i-1,j);
        c{i,j} = c{i-1,j};
        t{i,j} = t{i-1,j};
      end
      v4diff = DiffV4(a1(i,:),a2(j,:));
      if v4diff < 0.2
        if i > 1 && j > 1
          m1 = m(i-1,j-1) + 1;
          s1 = [c{i-1,j-1};i,j];
        else
          m1 = 1;
          s1 = [i,j];
        end
        [ldiff,tran] = DiffLine(l1,a1(s1(:,1),7:8),l2,a2(s1(:,2),7:8));
        if ldiff < 160 && (m1>m(i,j) || (m1==m(i,j) && ldiff<d(i,j)))
          m(i,j) = m1;
          d(i,j) = ldiff;
          c{i,j} = s1;
          t{i,j} = tran;
        end
      end
    end
  end
  m = m(size(arr1,1),size(arr2,1));
  d = d(size(arr1,1),size(arr2,1));
  c = c{size(arr1,1),size(arr2,1)};
  t = t{size(arr1,1),size(arr2,1)};
end

% Calculate difference between lines.
% l is line and r is range. l1 can be cyclic.
% The mapping of line points is aligned with the mid-point of each feature.
function [d,t] = DiffLine(l1, r1, l2, r2)
  nl1 = [];
  nl2 = [];
  for i = 0:size(r1,1)
    step = 5;
    if i == 0
      u1 = [r1(1,1),(r1(1,1)+r1(1,2))/2];
      u2 = [r2(1,1),(r2(1,1)+r2(1,2))/2];
    elseif i == size(r1,1)
      u1 = [(r1(i,1)+r1(i,2))/2,r1(i,2)];
      u2 = [(r2(i,1)+r2(i,2))/2,r2(i,2)];
    else
      u1 = [(r1(i,1)+r1(i,2))/2,(r1(i+1,1)+r1(i+1,2))/2];
      u2 = [(r2(i,1)+r2(i,2))/2,(r2(i+1,1)+r2(i+1,2))/2];
      step = 10;
    end
    u1 = round(u1);
    u2 = round(u2);
    u2 = u2(1):((u2(2)-u2(1))/step):u2(2);
    u2 = round(u2(1:step));
    if u1(2) < u1(1), u1(2) = u1(2) + size(l1,1); end
    u1 = u1(1):((u1(2)-u1(1))/step):u1(2);
    u1 = round(u1(1:step));
    u1(u1>size(l1,1)) = u1(u1>size(l1,1)) - size(l1,1);
    nl1 = cat(1, nl1, l1(u1,:));
    nl2 = cat(1, nl2, l2(u2,:));
  end
  l1 = nl1(:,1:2);
  l2 = nl2(:,1:2);
  %plot(l1(:,1),l1(:,2),l2(:,1),l2(:,2));
  Ax = l1;
  Ax(:,2) = 1;
  tx = (Ax'*Ax)^(-1)*Ax'*l2(:,1);
  Ay = l1;
  Ay(:,1) = 1;
  ty = (Ay'*Ay)^(-1)*Ay'*l2(:,2);
  t = [tx';ty(2),ty(1)];
  dx = mean(((l2(:,1)-tx(2))/tx(1)-l1(:,1)).^2);
  dy = mean(((l2(:,2)-ty(1))/ty(2)-l1(:,2)).^2);
  d = sqrt(dx + dy);
end

% Normalize V4 feature.
function v = NormalizeV4(v)
  v(:,1:4) = v(:,1:4)*[1,0,-1,0;0,1,0,-1;-1,0,1,0;0,-1,0,1];
  v(:,1:4) = v(:,1:4)./repmat(sqrt(sum(v(:,1:2).^2,2)),1,4);
end

% Calculate V4 feature difference. Both features should be normalized.
function f = DiffV4(v1, v2)
  dv = v1 - v2;
  f = dv(1)^2 + dv(2)^2 + MuDiff(dv(5),dv(6));
end

% Calculate difference of features for parameters a, b.
function f = MuDiff(a,b)
  f = 0.4*a*a+16/15*b*b+1.2*a*b;
end
