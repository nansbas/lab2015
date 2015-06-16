function [mcs,avgDiff,cs,tran] = MatchV4Array(arr1, line1, arr2, line2)
  mcs = [];
  avgDiff = [];
  cs = {};
  tran = {};
  j = 1;
  for i = 1:size(arr1,1);
    idx = [i:size(arr1,1),1:i-1];
    [m,d,c,t] = DirectMatch(arr1(idx,:),line1,arr2,line2);
    c(:,1) = idx(c(:,1));
    mcs(j) = m;
    avgDiff(j) = d;
    cs{j} = c;
    tran{j} = t;
    j = j + 1;
    [m,d,c,t] = DirectMatch(ReverseV4Array(arr1(idx,:)),flipud(line1),arr2,line2);
    idx = fliplr(idx);
    c(:,1) = idx(c(:,1));
    mcs(j) = m;
    avgDiff(j) = d;
    cs{j} = c;
    tran{j} = t;
    j = j + 1;
  end
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
end

% Reverse an array of V4 features.
function arr = ReverseV4Array(arr, len)
  arr = flipud(arr);
  arr(:,1:4) = arr(:,[3,4,1,2]);
  arr(:,5:6) = -arr(:,5:6);
  arr(:,7:8) = len - arr(:,[8,7]) + 1;
end

function [m,d,c,t] = DirectMatch(arr1, l1, arr2, l2)
  a1 = NormalizeV4(arr1);
  a2 = NormalizeV4(arr2);
  m = zeros(size(a1,1),size(a2,1));
  d = zeros(size(a1,1),size(a2,1));
  lastPair = zeros(size(a1,1),size(a2,1),2);
  startPoint = zeros(size(a1,1),size(a2,1),4);
  for i = 1:size(a1,1)
    for j = 1:size(a2,1)
      if j > 1 && (m(i,j-1)>m(i,j) || (m(i,j-1)==m(i,j) && d(i,j-1)<d(i,j)))
        m(i,j) = m(i,j-1);
        d(i,j) = d(i,j-1);
        lastPair(i,j,:) = lastPair(i,j-1,:);
        startPoint(i,j,:) = startPoint(i,j-1,:);
      end
      if i > 1 && (m(i-1,j)>m(i,j) || (m(i-1,j)==m(i,j) && d(i-1,j)<d(i,j)))
        m(i,j) = m(i-1,j);
        d(i,j) = d(i-1,j);
        lastPair(i,j,:) = lastPair(i-1,j,:);
        startPoint(i,j,:) = startPoint(i-1,j,:);
      end
      v4diff = DiffV4(a1(i,:),a2(j,:));
      if v4diff < 0.2
        if i > 1 && j > 1
          m1 = m(i-1,j-1) + 1;
          s1 = startPoint(i-1,j-1,:);
          if (s1(1)==0 && s1(2)==0), s1(1:2) = [a1(i,7),a2(j,7)]; end
          s1(3:4) = [a1(i,8),a2(j,8)];
        else
          m1 = 1;
          s1 = [a1(i,7),a2(j,7),a1(i,8),a2(j,8)];
        end
        [ldiff,temp] = DiffLine(l1,[s1(1),s1(3)],l2,[s1(2),s1(4)]);
        if ldiff < 10 && (m1>m(i,j) || (m1==m(i,j) && ldiff<d(i,j)))
          m(i,j) = m1;
          d(i,j) = ldiff;
          lastPair(i,j,:) = [i,j];
          startPoint(i,j,:) = s1;
        end
      end
    end
  end
  c = [];
  i = size(arr1,1);
  j = size(arr2,1);
  while i > 0 && j > 0
    if i == lastPair(i,j,1) && j == lastPair(i,j,2)
      c = cat(1,[i,j],c);
      i = i - 1;
      j = j - 1;
    else
      i = lastPair(i,j,:);
      j = i(2);
      i = i(1);
    end
  end
  m = m(size(arr1,1),size(arr2,1));
  s1 = startPoint(size(arr1,1),size(arr2,1),:);
  [d,t] = DiffLine(l1,[s1(1),s1(3)],l2,[s1(2),s1(4)]);
end

% Calculate difference between lines.
% l is line and r is range. l1 can be cyclic.
function [d,t] = DiffLine(l1, r1, l2, r2)
  if r1(1) > r1(2)
    l1 = l1([r1(1):size(l1,1),1:r1(2)],1:2);
  else
    l1 = l1(r1(1):r1(2),1:2);
  end
  l2 = l2(r2(1):r2(2),1:2);
  q1 = 1:((size(l1,1)-1)/100):size(l1,1);
  q2 = 1:((size(l2,1)-1)/100):size(l2,1);
  l1 = interp1(l1, q1(1:100));
  l2 = interp1(l2, q2(1:100));
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