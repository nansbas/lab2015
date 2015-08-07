% Find and draw V4 features or V4 model.
%   FindV4Feature('draw',f): Draw features in matrix f.
%   f = FindV4Feature('drawmodel',f): Draw model f.
%     A model is a set of normalized V4 features with position ans scale.
%     The return value is de-normalized features.
%   f = FindV4Feature(lines, threshold, minLength): Find and draw V4 features.
%     lines is a cell array of matrix {[x1,y1;x2,y2;...],...}.
%     threshold is the maximal summed error in least squares fitting.
%     minLength is the minimal feature length.
%     We usually use FindV4Feature(lines, 0.05, 20) for ETHZ-shape images.
%     Returned features f is row matrix,
%     [x1,y1,x2,y2,a,b,startPointIndex,endPointIndex,lineIndex;...].
%     Normalized model f is row matrix,
%     [x1,y1,x2,y2,a,b,startPointIndex,endPointIndex,N/A,midX,midY,scale;...].
function f = FindV4Feature(lines, threshold, minLength)
  if strcmp(lines,'draw')
    DrawResult(threshold);
  elseif strcmp(lines,'drawcolor')
    DrawResult(threshold, minLength);
  elseif strcmp(lines,'drawmodel')
    f = threshold;
    f(:,1:4) = f(:,1:4) .* f(:,[12,12,12,12]) + f(:,[10,11,10,11]);
    DrawResult(f);
  else
    f = [];
    for i = 1:length(lines)
      result = DoLine(lines{i}, threshold, minLength);
      if ~isempty(result)
        result(:,9) = i;
        f = [f; result(:,1:9)];
      end
    end
    DrawResult(f);
  end
end

% Fit V4 feature.
%   It returns empty matrix if no feature fits.
%   The feature is in [x1,y1,x2,y2,a,b].
function f = FitV4(line, threshold)
  f = [];
  xy = line(:,1:2);
  len = size(xy,1);
  p = xy(1,1:2);
  q = xy(len,1:2);
  t = [p(1),p(2),1,0;p(2),-p(1),0,1;q(1),q(2),1,0;q(2),-q(1),0,1]^(-1)*[-1;0;1;0];
  t = [t(1),-t(2);t(2),t(1);t(3),t(4)];
  xy = [xy,ones(len,1)]*t;
  x = xy(:,1);
  y = xy(:,2);
  if sum(x<-1)>1 || sum(x>1)>1
    return
  end
  A = [x.^2-abs(x)*2+1,1-x.^2];
  ySign = sign(sum(y));
  b = lsqnonneg(A, y * ySign);
  b = b * ySign;
  s = mean(abs(A*b-y))*sum((p-q).^2)/size(xy,1); % sum((A*b-y).^2);
  if b(1)*b(2) >= 0 && s <= threshold
    f = [p,q,b'];
  end
end

% Find V4 features on a single line.
function result = DoLine(line, threshold, minLength)
  result = [];
  for i = 1:5:size(line,1)
    for j = (i+minLength):5:size(line,1)
      f = FitV4(line(i:j,1:2), threshold);
      if ~isempty(f)
        result = cat(1,result,[f,i,j,j-i+1]);
      end
    end
  end
  key = [];
  nonkey = [];
  if ~isempty(result)
    [~,idx] = sort(result(:,9),'descend');
    cover = zeros(1,size(line,1));
    for i = idx'
      if mean(cover(result(i,7):result(i,8))) <= 0.05
        key = cat(1,key,result(i,:));
        cover(result(i,7):result(i,8)) = 1;
      else
        nonkey = cat(1,nonkey,result(i,:));
      end
    end
  end
  result = [];
  if ~isempty(key) && ~isempty(nonkey)
    [~,idx] = sort(key(:,7));
    key = key(idx,:);
    for i = 1:(size(key,1)-1)
      u = round(mean(key(i,7:8)));
      v = round(mean(key(i+1,7:8)));
      m = round(mean([key(i,8),key(i+1,7)]));
      r = max(abs(m-u),abs(m-v));
      rr = (m - nonkey(:,7)) ./ (nonkey(:,8) - m);
      fillgap = nonkey(nonkey(:,7)>=m-r & nonkey(:,8)<=m+r & nonkey(:,7)<m & nonkey(:,8)>m & rr>=1/3 & rr<=3,:);
      if ~isempty(fillgap)
        [~,j] = max(fillgap(:,9));
        result = cat(1,result,fillgap(j,:));
      end
    end
  end
  result = [result;key];
  if ~isempty(result) 
    [~,idx] = sort(result(:,7));
    result = result(idx,:);
  end
end

% Draw V4 features.
function DrawResult(f, colororder)
  if ~exist('colororder','var'), colororder = rand(32,3); end
  arg = {};
  x = (-1:0.1:1)';
  mu1 = x.^2-abs(x)*2+1;
  mu2 = 1-x.^2;
  hold on
  set(gca, 'ColorOrder', colororder);
  for i = 1:size(f,1)
    t = [-1,0,1,0;0,1,0,1;1,0,1,0;0,-1,0,1]^(-1)*f(i,1:4)';
    t = [t(1),-t(2);t(2),t(1);t(3),t(4)];
    xy = [x,(mu1*f(i,5)+mu2*f(i,6)),ones(21,1)]*t;
    arg{i*2-1} = xy(:,1);
    arg{i*2} = xy(:,2);
  end
  plot(arg{:}, 'LineWidth', 3);
  for i = 1:size(f,1)
    t = [-1,0,1,0;0,1,0,1;1,0,1,0;0,-1,0,1]^(-1)*f(i,1:4)';
    t = [t(1),-t(2);t(2),t(1);t(3),t(4)];
    xy = [x,(mu1*f(i,5)+mu2*f(i,6)),ones(21,1)]*t;
    text(xy(11,1),xy(11,2),[' ',num2str(i)],'FontSize',14);
  end
  axis equal
  set(gca, 'YDir', 'reverse');
  hold off
end
