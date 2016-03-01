function [sout,cout] = SimpleCell(img, rf, crf)
  if size(img,3) == 3
    img = rgb2gray(img);
  end
  img = double(img(:,:,1));
  m1 = max(img(:));
  m0 = min(img(:));
  if m1 > m0
    img = (img - m0) / (m1 - m0);
  end
  sout = zeros(size(img,1),size(img,2),size(rf,3));
  cout = zeros(size(img,1),size(img,2),size(rf,3));
  for i = 1:size(rf,3)
    mout = imfilter(img, rf(:,:,i), 'replicate');
    mout(mout<0) = 0;
    ridge = FindRidge(mout, 1);
    mout(ridge==0) = 0;
    sout(:,:,i) = mout;
    cout(:,:,i) = imfilter(mout, crf, 'replicate');
  end
  sout = sout / max(sout(:));
  cout = cout / max(cout(:));
end
