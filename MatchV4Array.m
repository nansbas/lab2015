function f = MatchV4Array(arr1, arr2)
  f = DirectMatchV4Array(arr1, arr2);
end

function f = DirectMatchV4Array(arr1, arr2)
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
      if i > 1 && (mcs(i-1,j)>mcs(i,j) || (mcs(i-1,j)==mcs(i,j) && avgDiff(i-1,j)<avgDiff(i.j)))
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