function f = NeuralFeature(img, frames)
  scales = frames(3,:);
  temp = round((scales - min(scales)) / (max(scales) - min(scales)) * 3);
  scales = round(temp / 3 * (max(scales) - min(scales))) + min(scales);
  scales(scales < 8) = 8;
  [nscales,~,scaleIdx] = unique(scales);
  simpleRFsize = round(nscales/3);
  complexRFsize = round(nscales/1.5);
  oriRange = 0:20:160;
  f = zeros(size(frames,2),length(oriRange)*9);
  cout = cell(1,length(nscales));
  for i = 1:length(nscales)
    rf = MakeSimpleRF(simpleRFsize(i), oriRange, [1,length(oriRange)]);
    out = SimpleCell(img, rf);
    cout1 = zeros(size(out));
    for j = 1:size(out,3)
      cout1(:,:,j) = imfilter(out(:,:,j), fspecial('gaussian', complexRFsize(i), simpleRFsize(i)), 'replicate');
    end
    cout{i} = cout1;
  end
  [x,y] = meshgrid(-1:1);
  for i = 1:length(scaleIdx)
    px = x(:) * complexRFsize(scaleIdx(i)) + frames(1,i);
    py = y(:) * complexRFsize(scaleIdx(i)) + frames(2,i);
    if sum(px < 1) > 0 || sum(px > size(img,2)) > 0, continue; end
    if sum(py < 1) > 0 || sum(py > size(img,1)) > 0, continue; end
    for j = 1:9
      f(i,(1:length(oriRange))+(j-1)*length(oriRange)) = cout{scaleIdx(i)}(py(j),px(j),:);
    end
  end
end