% Convert integer indexed map to RGB color image.
function out = Map2Color(map)
  r = zeros(size(map,1),size(map,2));
  g = zeros(size(map,1),size(map,2));
  b = zeros(size(map,1),size(map,2));
  for i = 1:max(map(:))
    r(map == i) = rand();
    g(map == i) = rand();
    b(map == i) = rand();
  end
  out = uint8(cat(3,r,g,b)*255);
end