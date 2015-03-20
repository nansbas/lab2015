function [out,idx,ridge,lmap] = SimpleCell(img, rf)
  if size(img,3) == 3
    img = rgb2gray(img);
  end
  img = double(img(:,:,1)) / double(max(img(:)));
  out = zeros(size(img,1),size(img,2),size(rf,3));
  for i = 1:size(rf,3)
    out(:,:,i) = imfilter(img, rf(:,:,i), 'replicate');
  end
  out = abs(out);
  [mout,idx] = max(out, [], 3);
  ridge = FindRidge(mout, 1);
  gauss = fspecial('gaussian', size(rf,1), size(rf,1));
  mout(ridge==0) = 0;
  strength = imfilter(mout, gauss);
  ori = (idx - 1) * pi / size(rf,3);
  sup = LateralSuppress(ridge, strength, ori, size(rf,1)/2+1);
  mout = mout - sup * 6;
  mout(mout<0) = 0;
  ridge = mout;
  lmap = FindLine(ridge, double(idx-1)*180/size(rf,3), 1, 100, 10);
  lmap1 = zeros(size(lmap));
  lmap2 = zeros(size(lmap));
  lmap3 = zeros(size(lmap));
  for i = 1:max(lmap(:))
    lmap1(lmap==i) = randi(255);
    lmap2(lmap==i) = randi(255);
    lmap3(lmap==i) = randi(255);
  end
  lmap = uint8(cat(3,lmap1,lmap2,lmap3));
end
