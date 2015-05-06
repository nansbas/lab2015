function out = Rgb2Lab(img)
  % RGB to XYZ
  if max(img(:)) > 1
    img = double(img) / 255;
  end
  idx = img > 0.04045;
  img(idx) = ((img(idx) + 0.055) / 1.055) .^ 2.4;
  img(~idx) = img(~idx) / 12.92;
  img = img * 100;
  if size(img,3) ~= 3
    img = repmat(img(:,:,1),1,1,3);
  end
  X = img(:,:,1) * 0.4124 + img(:,:,2) * 0.3576 + img(:,:,3) * 0.1805;
  Y = img(:,:,1) * 0.2126 + img(:,:,2) * 0.7152 + img(:,:,3) * 0.0722;
  Z = img(:,:,1) * 0.0193 + img(:,:,2) * 0.1192 + img(:,:,3) * 0.9505;
  % XYZ to CIE L*ab
  X = X / 95.047;
  Y = Y / 100.000;
  Z = Z / 108.883;
  xyz = cat(3, X, Y, Z);
  idx = xyz > 0.008856;
  xyz(idx) = xyz(idx) .^ (1/3);
  xyz(~idx) = xyz(~idx) * 7.787 + 16/116;
  L = xyz(:,:,2) * 116 - 16;
  a = (xyz(:,:,1) - xyz(:,:,2)) * 500;
  b = (xyz(:,:,2) - xyz(:,:,3)) * 200;
  out = cat(3, L/100, a/200+0.5, b/200+0.5);
end