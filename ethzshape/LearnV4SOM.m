function [som,ethz] = LearnV4SOM(ethz, som)
  for i = 1:5
    ethz(i).sample = GetGroundTruth(ethz(i).files);
  end
  if ~exist('som','var'), som = CreateSOM(12, 9, 5); end
  for i = 1:1000
    category = 5 - mod(i,5);
    nsample = length(ethz(category).sample);
    sid = nsample - mod(ceil(i/5),nsample);
    som = SOMLearnSample(som, ethz(category).sample{sid}, category, 0.05, 0.3);
    if mod(i,1000) == 0
      close all;
      DrawSOM(som);
      saveas(gcf, 'som.png');
      saveas(gcf, 'som.fig');
    end
  end
end

% Create SOM with n*n units, m-dim input, k categories.
function som = CreateSOM(n, m, k)
  som.weight = rand(n*n,m);
  som.weight = NormalizeV4(som.weight);
  [x,y] = meshgrid(1:n,1:n);
  som.neighbor = (DiffMatrix([x(:), y(:)], [x(:), y(:)], [1,1]) == 1);
  som.category = zeros(n*n, k);
end

% Draw SOM.
function DrawSOM(som)
  r1 = 0.05; r2 = 0.1;
  p = [som.weight(:,1:4)*r2+som.weight(:,[7:8,7:8]), som.weight(:,5:6)];
  p = [p(:,1:4), ComputePeakPointAndScale(p)];
  for i = 1:5
    subplot(2,5,i); hold on
    colors = 1 - (som.category(:,i)+1)/(max(som.category(:,i))+1)*[1,1,1];
    [~,idx] = sort(som.category(:,i));
    for j = idx'
      rectangle('Position',[som.weight(j,7:8)-r1,r1*2,r1*2],'Curvature',[1,1],'EdgeColor',colors(j,:));
    end
    [x,y] = meshgrid(1:size(som.weight,1));
    for j = [x(som.neighbor),y(som.neighbor)]'
      if j(1)>j(2), line(som.weight(j',7), som.weight(j',8)); end
    end
    axis ij; axis off; axis equal; hold off
    subplot(2,5,i+5); hold on
    colors = 1 - (som.category(:,i)+1)/(max(som.category(:,i))+1)*[0.5,0.5,0.5];
    color2 = 1 - (som.category(:,i)+1)/(max(som.category(:,i))+1)*[1,1,0.2];
    for j = idx'
      rectangle('Position',[som.weight(j,7:8)-r2,r2*2,r2*2],'Curvature',[1,1],'EdgeColor',colors(j,:));
      line(p(j,[1,5,3]),p(j,[2,6,4]),'Color',color2(j,:));
    end
    axis ij; axis off; axis equal; hold off
  end
end

% Learn SOM from one sample.
% winner = [cid,xid,dist,reverse;...].
function [som,winner] = SOMLearnSample(som, x, category, rate, nfact)
  c = som.weight;
  x = NormalizeV4(x);
  d1 = DiffMatrix(x(:,1:2), c(:,1:2), [1,1]);
  d2 = DiffMatrix(x(:,3:4), c(:,1:2), [1,1]);
  da = DiffMatrix(x(:,5), c(:,5), 1);
  db = DiffMatrix(x(:,6), c(:,6), 1);
  dmu = MuDiff(da, db);
  da = DiffMatrix(-x(:,5), c(:,5), 1);
  db = DiffMatrix(-x(:,6), c(:,6), 1);
  dmu2 = MuDiff(da, db);
  reverse = (d2 < d1);
  dmu(reverse) = dmu2(reverse);
  d1(reverse) = d2(reverse);
  d = (d1/2 + dmu) + DiffMatrix(x(:,10:11), c(:,7:8), [1,1])*2.4; % 2.3856 = max(d1/2+dmu)/sqrt(2).
  [cidx,xidx] = meshgrid(1:size(c,1),1:size(x,1));
  [~,idx] = sort(d(:));
  cused = zeros(size(c,1),1);
  xused = zeros(size(x,1),1);
  cusedn = 0;
  xusedn = 0;
  winner = [];
  for i = idx'
    ci = cidx(i);
    xi = xidx(i);
    if xusedn >= size(x,1) || cusedn >= size(c,1), break; end
    if cused(ci) == 1 || xused(xi) == 1, continue; end
    cused(ci) = 1;
    xused(xi) = 1;
    winner = cat(1, winner, [ci, xi, d(xi,ci), reverse(xi,ci)]);
  end
  for i = 1:size(winner,1)
    ci = winner(i,1);
    xi = x(winner(i,2),[1:6,10:12]);
    if winner(i,4) % reverse
      xi(1:4) = xi([3,4,1,2]);
      xi(5:6) = -xi(5:6);
    end
    c(ci,:) = c(ci,:)*(1-rate) + xi*rate;
    som.category(ci,category) = som.category(ci,category) + 1;
    nrate = rate * winner(i,3) * nfact;
    neighbor = 1:size(c,1);
    for j = neighbor(som.neighbor(ci,:));
      c(j,:) = c(j,:)*(1-nrate) + c(ci,:)*nrate;
    end
  end
  c = NormalizeV4(c);
  som.weight = c;
end

% Retrieve training sample from files in one category.
function s = GetGroundTruth(files)
  s = {};
  for i = 1:length(files)
    v4 = files(i).v4;
    v4 = [v4, ComputePeakPointAndScale(v4)];
    gt0 = files(i).groundtruth;
    % Relax groundtruth boundary box.
    gt = gt0 * (diag(ones(1,4))+0.03*[1,0,-1,0;0,1,0,-1;-1,0,1,0;0,-1,0,1]);
    for j = 1:size(files(i).groundtruth,1)
      % Find features within groundtruth box.
      v = (v4(:,[1,3,10])<gt(j,3)) + (v4(:,[1,3,10])>gt(j,1)) + (v4(:,[2,4,11])<gt(j,4)) + (v4(:,[2,4,11])>gt(j,2));
      v = v4(sum(v,2)==12,:);
      if isempty(v), continue; end
      % Use mask.
      if isfield(files(i),'mask')
        m = files(i).mask{j};
        m = bwmorph(m, 'skel', Inf);
        [x,y] = meshgrid(1:size(m,2),1:size(m,1));
        xy = [x(m)+gt(j,1)-1, y(m)+gt(j,2)-1];
        d = max([min(DiffMatrix(v(:,1:2),xy,[1,1]),[],2), min(DiffMatrix(v(:,3:4),xy,[1,1]),[],2), ...
          min(DiffMatrix(v(:,10:11),xy,[1,1]),[],2)],[],2);
        v = v(d<0.1*sqrt((gt0(j,3)-gt0(j,1)+1)*(gt0(j,4)-gt0(j,2)+1)), :);
      end
      % Normalize middle point position and scale.
      if isempty(v), continue; end
      v(:,10) = v(:,10) - (gt(j,1)+gt(j,3))/2;
      v(:,11) = v(:,11) - (gt(j,2)+gt(j,4))/2;
      v(:,10:12) = v(:,10:12) / sqrt((gt0(j,3)-gt0(j,1)+1)*(gt0(j,4)-gt0(j,2)+1));
      s{length(s)+1} = v;
    end
  end
end

% Compute the middle peak point and scale of V4 features.
function f = ComputePeakPointAndScale(v4)
  ab = sum(v4(:,5:6),2);
  ee = ones(size(v4,1),1);
  f(:,1) = sum(v4(:,1:4).*[ee,ab,ee,-ab],2)/2;
  f(:,2) = sum(v4(:,1:4).*[-ab,ee,ab,ee],2)/2;
  f(:,3) = sqrt(sum((v4(:,1:4)*[0.5,0;0,0.5;-0.5,0;0,-0.5]).^2,2));
end

% Normalize V4 feature.
function v = NormalizeV4(v)
  v(:,1:4) = v(:,1:4)*[1,0,-1,0;0,1,0,-1;-1,0,1,0;0,-1,0,1];
  v(:,1:4) = v(:,1:4)./repmat(sqrt(sum(v(:,1:2).^2,2)),1,4);
end

% Calculate difference of features for parameters a, b.
function f = MuDiff(a,b)
  f = 0.4*(a.^2)+16/15*(b.^2)+1.2*(a.*b);
end

% Compute difference matrix of two set of row vectors of specified width.
function f = DiffMatrix(rows1, rows2, width)
  if length(width) == 1
    f = width * abs(repmat(rows1(:,1),1,size(rows2,1)) - repmat(rows2(:,1)',size(rows1,1),1));
  else
    f = zeros(size(rows1,1),size(rows2,1));
    for i = 1:length(width)
      d = repmat(rows1(:,i),1,size(rows2,1)) - repmat(rows2(:,i)',size(rows1,1),1);
      f = f + d.^2 * width(i);
    end
    f = sqrt(f);
  end
end

