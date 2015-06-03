function [mcs,avgDiff,cs,joinArr] = MatchV4Array(arr1, arr2)
  [m1,d1,s1] = DirectMatchV4Array(arr1, arr2);
  [m2,d2,s2] = DirectMatchV4Array(arr1, ReverseV4Array(arr2));
  if m1 > m2 || (m1 == m2 && d1 < d2)
    mcs = m1; avgDiff = d1; cs = s1;
    joinArr = JoinV4Array(arr1, arr2, cs);
  else
    mcs = m2; avgDiff = d2; cs = s2;
    joinArr = JoinV4Array(arr1, ReverseV4Array(arr2), cs);
    idx = size(arr2,1):-1:1; cs(:,2) = idx(cs(:,2));
  end
end

function arr = ReverseV4Array(arr)
  arr = flipud(arr);
  arr(:,1:4) = arr(:,[3,4,1,2]);
  arr(:,5:6) = -arr(:,5:6);
end

function arr = JoinV4Array(arr1, arr2, cs)
  arr1 = NormalizeV4(arr1);
  arr2 = NormalizeV4(arr2);
  arr = [];
  for i = 0:size(cs,1)
    if i > 0
      j = (arr1(cs(i,1),:)+arr2(cs(i,2),:))/2;
      arr = cat(1, arr, NormalizeV4(j));
    end
    if i == 0
      l1 = 1;
      l2 = 1;
    else
      l1 = cs(i,1)+1;
      l2 = cs(i,2)+1;
    end
    if i < size(cs,1)
      r1 = cs(i+1,1)-1;
      r2 = cs(i+1,2)-1;
    else
      r1 = size(arr1,1);
      r2 = size(arr2,1);
    end
    if r1-l1 > r2-l2
      arr = cat(1, arr, arr1(l1:r1,:));
    else
      arr = cat(1, arr, arr2(l2:r2,:));
    end
  end
end

function [mcs,avgDiff,cs] = DirectMatchV4Array(arr1, arr2)
  arr1 = NormalizeV4(arr1);
  arr2 = NormalizeV4(arr2);
  diff = zeros(size(arr1,1),size(arr2,1));
  avgDiff = zeros(size(arr1,1),size(arr2,1));
  mcs = zeros(size(arr1,1),size(arr2,1));
  path = zeros(size(arr1,1),size(arr2,1));
  for i = 1:size(arr1,1)
    for j = 1:size(arr2,1)
      diff(i,j) = DiffV4(arr1(i,:),arr2(j,:));
    end
  end
  for i = 1:size(arr1,1)
    for j = 1:size(arr2,1)
      if j > 1 && (mcs(i,j-1)>mcs(i,j) || (mcs(i,j-1)==mcs(i,j) && avgDiff(i,j-1)<avgDiff(i,j)))
        path(i,j) = 1; % from left
        mcs(i,j) = mcs(i,j-1);
        avgDiff(i,j) = avgDiff(i,j-1);
      end
      if i > 1 && (mcs(i-1,j)>mcs(i,j) || (mcs(i-1,j)==mcs(i,j) && avgDiff(i-1,j)<avgDiff(i,j)))
        path(i,j) = 2; % from top
        mcs(i,j) = mcs(i-1,j);
        avgDiff(i,j) = avgDiff(i-1,j);
      end
      if diff(i,j)<0.2
        if i > 1 && j > 1
          newMcs = mcs(i-1,j-1) + 1;
          newAvgDiff = (avgDiff(i-1,j-1)*mcs(i-1,j-1)+diff(i,j))/newMcs;
        else
          newMcs = 1;
          newAvgDiff = diff(i,j);
        end
        if newMcs > mcs(i,j) || (newMcs == mcs(i,j) && newAvgDiff < avgDiff(i,j))
          mcs(i,j) = newMcs;
          avgDiff(i,j) = newAvgDiff;
          path(i,j) = 3; % through this
        end
      end
    end
  end
  cs = [];
  i = size(arr1,1);
  j = size(arr2,1);
  while i > 0 && j > 0
    if path(i,j) == 1
      j = j - 1;
    elseif path(i,j) == 2
      i = i - 1;
    elseif path(i,j) == 3
      cs = cat(1,[i,j],cs);
      i = i - 1;
      j = j - 1;
    else
      break
    end
  end
  mcs = mcs(size(arr1,1),size(arr2,1));
  avgDiff = avgDiff(size(arr1,1),size(arr2,1));
end

function v = NormalizeV4(v)
  v(:,1:4) = v(:,1:4)*[1,0,-1,0;0,1,0,-1;-1,0,1,0;0,-1,0,1];
  v(:,1:4) = v(:,1:4)./repmat(sqrt(sum(v(:,1:2).^2,2)),1,4);
end

function f = DiffV4(v1, v2)
  dv = v1 - v2;
  f = dv(1)^2 + dv(2)^2 + MuDiff(dv(5),dv(6));
end

function f = MuDiff(a,b)
  f = 0.4*a*a+16/15*b*b+1.2*a*b;
end
