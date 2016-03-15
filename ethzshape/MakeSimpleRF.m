% Make Simple Receptive Field.
%  Generate Gabor filters of `rfsize` x `rfsize`, with orientations in `degrees`.
%  `rf` contains all filters and `out` is the rendered image.
function [rf,out] = MakeSimpleRF(rfsize, degrees)
  if ~exist('grid','var')
    grid = [1,length(degrees)];
  end
  [x,y] = meshgrid(1:rfsize);
  x = x - ceil(rfsize/2);
  y = y - ceil(rfsize/2);
  rf = zeros(rfsize,rfsize,length(degrees));
  rr = rfsize * 0.45;
  for i = 1:length(degrees)
    a = degrees(i) * pi / 180;
    x1 = x * cos(a) - y * sin(a);
    y1 = x * sin(a) + y * cos(a);
    % rf1 = sin(y1*pi/rr) .* ((exp((sqrt(x1.^2 + y1.^2)-rr)*32/rr)+1).^(-1));
    rf1 = sin(y1*pi/rr) .* exp(-(x1.^2+y1.^2)/rr/rr);
    rf1(rf1>0) = rf1(rf1>0) / sum(rf1(rf1>0));
    rf1(rf1<0) = rf1(rf1<0) / abs(sum(rf1(rf1<0)));
    rf(:,:,i) = rf1;
  end
  out = ColorWeightMatrix(rf);
end