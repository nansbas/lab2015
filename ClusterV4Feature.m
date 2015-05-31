function [f,p] = ClusterV4Feature(f, p, sample, posFactor)
  assigned = zeros(1,size(f,1));
  idx = 1:size(f,1);
  newf = [];
  newp = [];
  x = sample(:,[1,3]);
  y = sample(:,[2,4]);
  minX = min(x(:));
  minY = min(y(:));
  maxX = max(x(:));
  maxY = max(y(:));
  pos = [sample(:,1:4),ones(size(sample,1),1)] ...
    * [0.5,0; 0,0.5; 0.5,0; 0,0.5; -minX,-minY] * [1/(maxX-minX),0;0,1/(maxY-minY)];
  if isempty(p)
    p = zeros(size(f,1),2);
  end
  sample(:,1:4) = sample(:,1:4)*[1,0,-1,0;0,1,0,-1;-1,0,1,0;0,-1,0,1];
  sample(:,1:4) = sample(:,1:4)./repmat(sqrt(sum(sample(:,1:2).^2,2)),1,4);
  for i = 1:size(sample,1)
    if isnan(sample(i,1)); continue; end
    k = -1;
    minDiff = 0;
    for j = idx(~assigned)
      d1 = (sample(i,1)-f(j,1))^2+(sample(i,2)-f(j,2))^2;
      d2 = (sample(i,1)-f(j,3))^2+(sample(i,2)-f(j,4))^2;
      if d1 <= d2
        d = d1 + MuDiff(sample(i,5)-f(j,5),sample(i,6)-f(j,6));
      else
        d = d2 + MuDiff(sample(i,5)+f(j,5),sample(i,6)+f(j,6));
      end
      d = d + posFactor*sum((pos(i,1:2)-p(j,1:2)).^2);
      if d < 0.2 && (k == -1 || d < minDiff)
        minDiff = d;
        k = j;
        swap = (d1 > d2);
      end
    end
    if k > 0
      assigned(k) = 1;
      if swap
        s = sample(i,[3,4,1,2,5,6]).*[1,1,1,1,-1,-1];
      else
        s = sample(i,1:6);
      end
      f(k,1:6) = (f(k,1:6)*f(k,7) + s) / (f(k,7)+1);
      p(k,1:2) = (p(k,1:2)*f(k,7) + pos(i,1:2)) / (f(k,7)+1);
      f(k,7) = f(k,7) + 1;
      f(k,1:4) = f(k,1:4)/sqrt(f(k,1)*f(k,1)+f(k,2)*f(k,2));
    else
      newf = cat(1, newf, [sample(i,1:6),1]);
      newp = cat(1, newp, pos(i,1:2));
    end
  end
  f = [f;newf];
  p = [p;newp];
end


function f = MuDiff(a,b)
  f = 0.4*a*a+16/15*b*b+1.2*a*b;
end