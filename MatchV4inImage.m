function f = MatchV4inImage(model, image)
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
  for i = 1:length(lines)
    v4 = v4set(v4set(:,9)==i,:);
    v4idx = v4setidx(v4set(:,9)==i);
    if isempty(v4), continue; end
    [m,d,c,t] = MatchV4Array(model.v4, model.line, v4, lines{i});
    if m < 1, continue; end
    if t(1) <= 0 || t(2) <= 0, continue; end
    if t(1)/t(2)>2.5 || t(1)/t(2)<0.4, continue; end
    if d/m/m > 6, continue; end
    %FindV4Feature('drawcolor', v4set(v4idx(c(:,2)),:), [1,0,0]);
    [fidx,t,cover,d] = ExtendMatch(model, image, v4idx(c(:,2))', t);
    %FindV4Feature('drawcolor', v4set(fidx,:), [repmat([1,0,0],size(c,1),1);repmat([0,0,1],length(fidx)-size(c,1),1)]);
    %fidx0 = fidx;
    %[fidx,t,cover,d] = ExtendMatch(model, image, v4idx(c(:,2))', t);
    FindV4Feature('drawcolor', v4set(fidx,:), [repmat([1,0,0],size(c,1),1);repmat([0,0,1],length(fidx)-size(c,1),1)]);
    %if mean(cover) < 0.8 || d > 30, continue; end
    %text(lines{i}(1,1),lines{i}(1,2),[num2str(i),':',num2str(mean(cover)),':',num2str(d)],'FontSize',18);
    rectangle('Position', [t(3),t(4),model.bound(3:4).*t(1:2)], 'LineWidth', 2);
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
% seed is index in a column vector.
function [fidx,t,mlineCovered,d] = ExtendMatch(model, image, seed, tran) 
  v4 = image.v4;
  v4(:,[1,3,10]) = (v4(:,[1,3,10])-tran(3))/tran(1);
  v4(:,[2,4,11]) = (v4(:,[2,4,11])-tran(4))/tran(2);
  d(:,:,1) = DiffMatrix(v4(:,1:2),model.line,2);
  d(:,:,2) = DiffMatrix(v4(:,3:4),model.line,2);
  d(:,:,3) = DiffMatrix(v4(:,10:11),model.line,2);
  [d,pidx] = min(d,[],2);
  v4dist = max(d,[],3);
  [temp,order] = sort(v4dist);
  order = [seed;order(~ismember(order,seed))]';
  mlength = size(model.line,1);
  mlineCovered = zeros(1,mlength);
  covered = 0;
  pidx = reshape(pidx, size(pidx,1), 3);
  modelPoint = [];
  imgPoint = [];
  fidx = [];
  for i = order
    isSeed = ismember(i, seed);
    if ~isSeed && v4dist(i) > 350, break; end
    p = pidx(i,1:2);
    if p(1) == p(2), continue; end
    if p(1) > p(2), range = p(1):-1:p(2); else range = p(1):p(2); end
    if abs(p(1)-p(2)) > mlength/2
      if p(1) > p(2), range = [p(1):mlength,1:p(2)]; else range = [p(1):-1:1,mlength:-1:p(2)]; end
    end
    canCover = sum(mlineCovered(range)==0);
    if ~isSeed && canCover/length(range) < 0.25, continue; end
    if ~isSeed && canCover < 20, continue; end
    imgline = image.lines{v4(i,9)}(v4(i,7):v4(i,8),1:2);
    tImgLine = [];
    tImgLine(:,1) = (imgline(:,1)-tran(3))/tran(1);
    tImgLine(:,2) = (imgline(:,2)-tran(4))/tran(2);
    d = DiffMatrix(tImgLine, model.line(range,:),2);
    [d,idx] = min(d,[],2);
    idx = range(idx);
    pset = (d<=v4dist(i)) & (mlineCovered(idx)==0)';
    modelPoint = cat(1, modelPoint, model.line(idx(pset),1:2));
    imgPoint = cat(1, imgPoint, imgline(pset,1:2));
    covered = covered + canCover;
    fidx = cat(2, fidx, i);
    mlineCovered(range) = 1;
    if covered/mlength > 0.98, break; end
  end
  Ax = modelPoint;
  Ax(:,2) = 1;
  tx = (Ax'*Ax)^(-1)*Ax'*imgPoint(:,1);
  Ay = modelPoint;
  Ay(:,1) = 1;
  ty = (Ay'*Ay)^(-1)*Ay'*imgPoint(:,2);
  t = [tx';ty(2),ty(1)];
  dx = mean(((imgPoint(:,1)-tx(2))/tx(1)-modelPoint(:,1)).^2);
  dy = mean(((imgPoint(:,2)-ty(1))/ty(2)-modelPoint(:,2)).^2);
  d = sqrt(dx + dy);
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
