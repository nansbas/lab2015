function err = TestMyRepnet
  V = [1,1,0,0; 0,0,1,1]';
  w = rand(2,4);
  a = rand(4,1);
  b = rand(2,1);
  r = 0.01;
  err = [];
  for i = 1:500
    v = V(:,mod(i,2)+1);
    sh = w*v+b;
    h = act(sh);
    sv = w'*h+a;
    v1 = act(sv);
    da = (v-v1).*act1(sv);
    a = a + da * r;
    db = (w*da).*act1(sh);
    b = b + db * r;
    dw = db*v';
    w = w + dw * r;
    fprintf('error: %f\n', sum((v1-v).^2));
    err = [err, sum((v1-v).^2)];
  end
end

function y = act(x)
  y = x;
  y(y<0) = 0;
end

function y = act1(x)
  y = x;
  y(x>0) = 1;
  y(x<0) = 0;
end