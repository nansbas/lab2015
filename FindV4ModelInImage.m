function result = FindV4ModelInImage(cluster, model, image)
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
      if model.ignoreAfter(i, LastNonZero(current(1,1:i-1))+1)
        i = i + 1;
      end
    elseif current(1,i) > length(label)
      current(1,i) = -1;
      i = i - 1;
    elseif ismember(label(current(1,i)), model.label{i})
      ok = 1;
      i1 = current(1,i);
      for j = 1:i-1
        j1 = current(1,j);
        if j1 == 0, continue; end
        if model.n(i,j) < 1 || model.n(j,i) < 1 ...
          || x(i1,j1) > model.x(i,j,3) || x(i1,j1) < model.x(i,j,4) ...
          || y(i1,j1) > model.y(i,j,3) || y(i1,j1) < model.y(i,j,4) ...
          || s(i1,j1) > model.s(i,j,3) || s(i1,j1) < model.s(i,j,4) ...
          || d(i1,j1) > model.d(i,j,3) || d(i1,j1) < model.d(i,j,4) ...
          || x(j1,i1) > model.x(j,i,3) || x(j1,i1) < model.x(j,i,4) ...
          || y(j1,i1) > model.y(j,i,3) || y(j1,i1) < model.y(j,i,4) ...
          || s(j1,i1) > model.s(j,i,3) || s(j1,i1) < model.s(j,i,4) ...
          || d(j1,i1) > model.d(j,i,3) || d(j1,i1) < model.d(j,i,4) ...
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