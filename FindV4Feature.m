function f = FindV4Feature(lines, threshold, minLength)
  if strcmp(lines,'draw')
    DrawResult(threshold);
  else
    f = [];
    for i = 1:length(lines)
      result = DoLine(lines{i}, threshold, minLength);
      result(:,9) = i;
      f = [f; result(:,1:9)];
    end
    DrawResult(f);
  end
end

function result = DoLine(line, threshold, minLength)
  result = [];
  for i = 1:5:size(line,1)
    for j = (i+minLength):5:size(line,1)
      p = line(i,1:2);
      q = line(j,1:2);
      t = [p(1),p(2),1,0;p(2),-p(1),0,1;q(1),q(2),1,0;q(2),-q(1),0,1]^(-1)*[-1;0;1;0];
      t = [t(1),-t(2);t(2),t(1);t(3),t(4)];
      xy = [line(i:j,1:2),ones(j-i+1,1)]*t;
      x = xy(:,1);
      y = xy(:,2);
      if sum(x<-1)>1 || sum(x>1)>1
        continue
      end
      A = [x.^2-abs(x)*2+1,1-x.^2];
      ySign = sign(sum(y));
      b = lsqnonneg(A, y * ySign);
      b = b * ySign;
      s = sum((A*b-y).^2);
      result = [result; p,q,b',i,j,j-i+1,s];
    end
  end
  if ~isempty(result)
    result = result(result(:,10)<=threshold & (result(:,5).*result(:,6)>=0),:);
    [temp,idx] = sort(result(:,9),'descend');
    cover = zeros(1,size(line,1));
    temp = [];
    for i = idx'
      if mean(cover(result(i,7):result(i,8))) > 0.75
        continue
      end
      temp = [temp; result(i,:)];
      cover(result(i,7):result(i,8)) = 1;
    end
    result = temp;
    if ~isempty(result)
      [temp,idx] = sort(result(:,7));
      result = result(idx,:);
    end
  end
end

function DrawResult(f)
  arg = {};
  x = (-1:0.1:1)';
  mu1 = x.^2-abs(x)*2+1;
  mu2 = 1-x.^2;
  hold on
  set(gca, 'ColorOrder', rand(32,3));
  for i = 1:size(f,1)
    t = [-1,0,1,0;0,1,0,1;1,0,1,0;0,-1,0,1]^(-1)*f(i,1:4)';
    t = [t(1),-t(2);t(2),t(1);t(3),t(4)];
    xy = [x,(mu1*f(i,5)+mu2*f(i,6)),ones(21,1)]*t;
    arg{i*2-1} = xy(:,1);
    arg{i*2} = xy(:,2);
    text(xy(11,1),xy(11,2),[num2str(f(i,9)),':',num2str(i)],'FontSize',16);
  end
  plot(arg{:}, 'LineWidth', 4);
  axis equal
  set(gca, 'YDir', 'reverse');
  hold off
end
