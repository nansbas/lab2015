function f = MatchV4inImage(model, image, noCycleMode)
  if ~exist('noCycleMode','var'), noCycleMode = 'cycle'; end
  lines = image.lines;
  v4set = image.v4;
  v4set(:,10:11) = ComputeV4MidPoint(v4set);
  for i = 1:length(lines)
    r = rand();
    g = rand();
    b = rand();
    for j = 1:size(lines{i})
      img(lines{i}(j,2),lines{i}(j,1),1) = r;
      img(lines{i}(j,2),lines{i}(j,1),2) = g;
      img(lines{i}(j,2),lines{i}(j,1),3) = b;
    end
  end
  img = 1 - img;
  imshow(img);
  hold on
  v4setidx = 1:size(v4set,1);
  f = [];
  for i = 1:length(lines)
    v4 = v4set(v4set(:,9)==i,:);
    v4idx = v4setidx(v4set(:,9)==i);
    if isempty(v4), continue; end
    [m,d,c,t] = MatchV4Array(model.v4, model.line, v4, lines{i}, noCycleMode);
    if m < 1, continue; end
    if t(1) <= 0 || t(2) <= 0, continue; end
    if t(1)/t(2)>2.5 || t(1)/t(2)<0.4, continue; end
    if d/m/m > 6, continue; end
    if m > 4, r = [72,50,42]; else r = [170,72,42]; end
    [fidx,t,cover,d] = ExtendMatch(model, image, v4idx(c(:,2)), t, r(1));
    [fidx,t,cover,d] = ExtendMatch(model, image, v4idx(c(:,2)), t, r(2));
    [fidx,t,cover,d] = ExtendMatch(model, image, v4idx(c(:,2)), t, r(3));
    cover = mean(cover);
    if cover < 0.81 || d > 49, continue; end
    if cover < 0.90 && d > 15, continue; end
    FindV4Feature('drawcolor', v4set(fidx,:), [repmat([1,0,0],size(c,1),1);repmat([0,0,1],length(fidx)-size(c,1),1)]);
    text(lines{i}(1,1),lines{i}(1,2),[num2str(i),':',num2str(cover),':',num2str(d)],'FontSize',18);
    if t(1)/t(2)>2.5 || t(1)/t(2)<0.4, continue; end
    rectangle('Position', [t(3),t(4),model.bound(3:4).*t(1:2)], 'LineWidth', 2);
    rect = [t(3:4),model.bound(3:4).*t(1:2)+t(3:4)];
    for i = 1:size(f,1)
      if RectOverlap(rect,f(i,1:4)) > 0.5 && d < f(i,6)
        f(i,:) = [rect, cover, d];
        rect = [];
      end
    end
    if ~isempty(rect)
      f = cat(1, f, [rect, cover, d]);
    end
  end
  hold off
end

% Compute the middle peak point of V4 features.
function f = ComputeV4MidPoint(v4)
  ab = sum(v4(:,5:6),2);
  ee = ones(size(v4,1),1);
  f(:,1) = sum(v4(:,1:4).*[ee,ab,ee,-ab],2)/2;
  f(:,2) = sum(v4(:,1:4).*[-ab,ee,ab,ee],2)/2;
end

% Extend seed features.
function [fidx,t,mlineCovered,d] = ExtendMatch(model, image, seed, tran, maxV4dist, noCycleMode) 
  if ~exist('noCycleMode','var'), noCycleMode = 'cycle'; end
  v4 = image.v4;
  v4(:,[1,3,10]) = (v4(:,[1,3,10])-tran(3))/tran(1);
  v4(:,[2,4,11]) = (v4(:,[2,4,11])-tran(4))/tran(2);
  d(:,:,1) = DiffMatrix(v4(:,1:2),model.line,2);
  d(:,:,2) = DiffMatrix(v4(:,3:4),model.line,2);
  d(:,:,3) = DiffMatrix(v4(:,10:11),model.line,2);
  v4dist = max(min(d,[],2),[],3);
  [~,order] = sort(v4dist);
  order = order(~ismember(order,seed));
  mlength = size(model.line,1);
  mlineCovered = zeros(1,mlength);
  covered = 0;
  modelpoint = [];
  imgpoint = [];
  fidx = [];
  for i = [seed,order']
    isSeed = ismember(i, seed);
    if ~isSeed && v4dist(i) > maxV4dist, break; end
    bound = v4(i,7:8);
    if ismember(i+1,fidx) && v4(i+1,9)==v4(i,9) && bound(2) < v4(i+1,7) - 1
      bound(2) = v4(i+1,7) - 1;
    end
    if ismember(i-1,fidx) && v4(i-1,9)==v4(i,9) && bound(1) > v4(i-1,8) + 1
      bound(1) = v4(i-1,8) + 1;
    end
    imgline = [image.lines{v4(i,9)}(bound(1):bound(2),1:2),ones(bound(2)-bound(1)+1,1)] * InverseTransform(tran);
    d = DiffMatrix(imgline([1,bound(2)-bound(1)+1],1:2), model.line(:,1:2), 2);
    [~,p] = min(d,[],2);
    if p(1) > p(2), range = p(1):-1:p(2); else range = p(1):p(2); end
    if abs(p(1)-p(2)) > mlength/2 && ~strcmp(noCycleMode,'nocycle')
      if p(1) > p(2), range = [p(1):mlength,1:p(2)]; else range = [p(1):-1:1,mlength:-1:p(2)]; end
    end
    canCover = sum(mlineCovered(range)==0);
    if ~isSeed && (canCover/length(range) < 0.25 || canCover < 20), continue; end
    ratio = LineLength(imgline) / LineLength(model.line(range,1:2));
    if ~isSeed && (ratio > 1.33 || ratio < 0.75), continue; end
    covered = covered + canCover;
    mlineCovered(range) = 1;
    imgpoint = cat(1, imgpoint, image.lines{v4(i,9)}(bound(1):bound(2),1:2));
    modelpoint = cat(1, modelpoint, model.line(range,1:2));
    fidx = cat(2, fidx, i);
    %fprintf('%d: v4dist=%f, cover=%d/%d, len/ratio=%f\n', i, v4dist(i), canCover, length(range), ratio);
    if covered/mlength > 0.98, break; end
  end
  imgr = sqrt(diag(cov(imgpoint,1)));
  modelr = sqrt(diag(cov(modelpoint,1)));
  imgc = mean(imgpoint);
  modelc = mean(modelpoint);
  t = [imgr./modelr, imgc'-modelc'.*imgr./modelr];
  imgpoint = [imgpoint, ones(size(imgpoint,1),1)] * InverseTransform(t);
  d = DiffMatrix(imgpoint, model.line, 2);
  d = max(min(d,[],2));
end

% Compute line length.
function f = LineLength(line)
  l = size(line,1);
  d = line(1:l-1,1:2) - line(2:l,1:2);
  f = sum(sqrt(sum(d.^2,2)));
end

% Compute inverse transform matrix.
% tran = [scalex, offsetx; scale, offsety].
function f = InverseTransform(tran)
  f = [1/tran(1),0;0,1/tran(2);-tran(3)/tran(1),-tran(4)/tran(2)];
end

% Compute difference matrix of two set of row vectors of specified width.
function f = DiffMatrix(rows1, rows2, width)
  f = zeros(size(rows1,1),size(rows2,1));
  for i = 1:width
    d = repmat(rows1(:,i),1,size(rows2,1)) - repmat(rows2(:,i)',size(rows1,1),1);
    f = f + d.^2;
  end
  f = sqrt(f);
end
