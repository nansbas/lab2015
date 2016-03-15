% Draw colorful weight matrix.
function img = ColorWeightMatrix(w)
  [py,px,n] = size(w);
  nc = ceil(sqrt(n));
  nr = ceil(n/nc);
  img = ones(py*nr+nr-1,px*nc+nc-1,3);
  for i = 1:n
    x = mod(i-1,nc)+1;
    y = ceil(i/nc);
    x = (1:px)+(1+px)*(x-1);
    y = (1:py)+(1+py)*(y-1);
    red = w(:,:,i);
    blue = -w(:,:,i);
    red(red<0) = 0;
    blue(blue<0) = 0;
    mred = max(red(:));
    mblue = max(blue(:));
    if mred > 0, red = red / mred; end
    if mblue > 0, blue = blue / mblue; end
    img(y,x,1) = red;
    img(y,x,2) = 0;
    img(y,x,3) = blue;
  end
end