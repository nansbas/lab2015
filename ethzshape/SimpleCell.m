% Filter image with simple cell receptive field.
%  img: RGB or grayscale image.
%  rf: simple cell receptive fields with degrees from 0 to 180.
%  out: 3D output for all receptive fields.
%  ori: orientation according to maximal output.
%  ridge: find ridge from maximal output across orientations.
function [out,ori,ridge] = SimpleCell(img, rf)
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
  ori = (idx - 1) * 180 / size(rf,3);
  ridge = FindRidge(mout, ori, 1);
  mout(ridge==0) = 0;
  ridge = mout;
end
