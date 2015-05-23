function f = FindV4Feature(line, result)
  DrawResult(line,result);
  %f = DoLine(line,0.001,9);
end

function result = DoLine(line, threshold, minLength)
  result = [];
  for i = 1:size(line,1)
    for j = (i+minLength):size(line,1)
      p = line(i,1:2);
      q = line(j,1:2);
      t = [p(1),p(2),1,0;p(2),-p(1),0,1;q(1),q(2),1,0;q(2),-q(1),0,1]^(-1)...
        *[-1;0;1;0];
      t = [t(1),-t(2);t(2),t(1);t(3),t(4)];
      xy = [line(i:j,1:2),ones(j-i+1,1)]*t;
      x = xy(:,1);
      y = xy(:,2);
      if sum(x<-1)>1 || sum(x>1)>1
        break
      end
      A = [x.^2-abs(x)*2+1,1-x.^2];
      b = (A'*A)^(-1)*A'*y;
      s = mean((A*b-y).^2);
      result = [result; p,q,b',s,i,j,j-i+1];
    end
  end
  result = result(result(:,7)<=threshold ...
    & (result(:,5).*result(:,6)>=0),:);
  [temp,idx] = sort(result(:,10),'descend');
  cover = zeros(1,size(line,1));
  temp = [];
  for i = idx'
    if mean(cover(result(i,8):result(i,9))) > 0.75
      continue
    end
    temp = [temp; result(i,:)];
    cover(result(i,8):result(i,9)) = 1;
  end
  result = temp;
  DrawResult(line, result);
end

function DrawResult(line, result)
  arg = {};
  move = [4,0,0,0,0,4;0,0,4,0,0,0];
  for i = 1:size(result,1)
    arg{i*2-1} = line(result(i,8):result(i,9),1)+move(1,i);
    arg{i*2} = line(result(i,8):result(i,9),2)+move(2,i);
  end
  plot(arg{:}, 'LineWidth', 6);
  axis equal
  set(gca, 'YDir', 'reverse');
end
