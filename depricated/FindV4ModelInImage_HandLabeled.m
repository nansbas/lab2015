function [result,judge] = FindV4ModelInImage(cluster, model, image)
  [~,label,~,dist] = ClusterV4Feature(cluster.c, image.v4, 'cluster');
  for i = 1:length(cluster.d)
    label(label == i & dist > cluster.d(i)) = 0;
  end
  [x,y,s,d,a] = LearnV4ShapeModel(image.v4, 'compute');
  result = {};
  current = zeros(3,length(model.label)) - 1;
  i = 1;
  while i > 0
    if i > size(current,2)
      result = UpdateResult(result, current);
      i = i - 1;
      continue;
    end
    current(1,i) = current(1,i) + 1;
    if current(1,i) == 0
      if model.ignoreAfter(i, LastNonZero(current(1,1:i-1))+1) ...
        && sum(current(1,1:i-1)~=0) + length(model.label) - i >= model.minLength
        i = i + 1;
      end
    elseif current(1,i) > length(label)
      current(1,i) = -1;
      i = i - 1;
    elseif ismember(label(current(1,i)), model.label{i})
      epsilon = 0;
      ok = 1;
      i1 = current(1,i);
      for j = 1:i-1
        j1 = current(1,j);
        if j1 == 0, continue; end
        if model.n(i,j) < 1 || model.n(j,i) < 1 ...
          || x(i1,j1) > model.x(i,j,3) + epsilon * model.x(i,j,2) || x(i1,j1) < model.x(i,j,4) - epsilon * model.x(i,j,2) ...
          || y(i1,j1) > model.y(i,j,3) + epsilon * model.y(i,j,2) || y(i1,j1) < model.y(i,j,4) - epsilon * model.y(i,j,2) ...
          || s(i1,j1) > model.s(i,j,3) + epsilon * model.s(i,j,2) || s(i1,j1) < model.s(i,j,4) - epsilon * model.s(i,j,2) ...
          || d(i1,j1) > model.d(i,j,3) + epsilon * model.d(i,j,2) || d(i1,j1) < model.d(i,j,4) - epsilon * model.d(i,j,2) ...
          || x(j1,i1) > model.x(j,i,3) + epsilon * model.x(j,i,2) || x(j1,i1) < model.x(j,i,4) - epsilon * model.x(j,i,2) ...
          || y(j1,i1) > model.y(j,i,3) + epsilon * model.y(j,i,2) || y(j1,i1) < model.y(j,i,4) - epsilon * model.y(j,i,2) ...
          || s(j1,i1) > model.s(j,i,3) + epsilon * model.s(j,i,2) || s(j1,i1) < model.s(j,i,4) - epsilon * model.s(j,i,2) ...
          || d(j1,i1) > model.d(j,i,3) + epsilon * model.d(j,i,2) || d(j1,i1) < model.d(j,i,4) - epsilon * model.d(j,i,2) ...
          ok = 0;
          break;
        end
        da = abs(a(i1,j1) - model.a(i,j,1));
        if da > 2*pi, da = da - 2*pi; end
        if da > pi, da = 2*pi - da; end
        if da > model.a(i,j,2)
          ok = 0;
          break;
        end
        da = abs(a(j1,i1) - model.a(j,i,1));
        if da > 2*pi, da = da - 2*pi; end
        if da > pi, da = 2*pi - da; end
        if da > model.a(j,i,2)
          ok = 0;
          break;
        end
      end
      if ok
        current(2,i) = label(current(1,i));
        current(3,i) = dist(current(1,i));
        i = i + 1;
      end
    end
  end
  judge = JudgeResult(result, image.v4, image.groundtruth);
end

% Judge result.
function f = JudgeResult(result, v4, groundtruth)
  v4(:,10:12) = ComputePeakPointAndScale(v4);
  f = [];
  for i = 1:length(result)
    r = result{i};
    r = r(:, r(1,:)~=0);
    p = [v4(r(1,:),1:2);v4(r(1,:),3:4);v4(r(1,:),10:11)];
    rect = [min(p(:,1)),min(p(:,2)),max(p(:,1)),max(p(:,2))];
    [overlap,idx] = RectOverlap(rect, groundtruth);
    ignoreThis = 0;
    for j = 1:size(f,1)
      if RectOverlap(rect, f(j,1:4)) > 0
        if size(r,2) > f(j,5) || (size(r,2) == f(j,5) && mean(r(3,:)) < f(j,6))
          f(j,:) = [rect, size(r,2), mean(r(3,:)), overlap, idx];
        end
        ignoreThis = 1;
        break;
      end
      if f(j,8) == idx
        if overlap > f(j,7)
          f(j,:) = [rect, size(r,2), mean(r(3,:)), overlap, idx];
        end
        ignoreThis = 1;
        break;
      end
    end
    if ~ignoreThis
      f = [f; rect, size(r,2), mean(r(3,:)), overlap, idx];
    end
  end
end

% Update result.
function f = UpdateResult(result, current)
  for i = 1:length(result)
    if IsBetterResult(result{i}, current)
      f = result;
      return
    end
  end
  f = {};
  n = 1;
  for i = 1:length(result)
    if ~IsBetterResult(current, result{i})
      f{n} = result{i};
      n = n + 1;
    end
  end
  f{n} = current;
end

% Test if r1 is better result than r2.
function f = IsBetterResult(r1, r2)
  r1 = r1(:,r1(1,:)~=0);
  r2 = r2(:,r2(1,:)~=0);
  r1len = size(r1,2);
  r2len = size(r2,2);
  if r1len < r2len || sum(ismember(r2(1,:),r1(1,:))) < r2len
    f = 0;
  elseif r1len > r2len
    f = 1;
  else
    f = mean(r1(3,:)) < mean(r2(3,:));
  end
end

% Get the index of the last non-zero element, 0 if empty or all zero.
function f = LastNonZero(x)
  f = 0;
  for i = length(x):-1:1
    if x(i) ~= 0
      f = i;
      break;
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
