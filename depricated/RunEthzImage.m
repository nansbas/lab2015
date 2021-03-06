function [out,data] = RunEthzImage(ethz, trainCat, testCat, idx, rf, bpnet)
  %fprintf('Run cat %d on cat %d image %d\n', trainCat, testCat, idx);
  t = ethz(trainCat);
  f = ethz(testCat).files(idx);
  w = f.imageSize(1);
  h = f.imageSize(2);
  img = imresize(f.image, [h,w]);
  [temp,ori,ridge] = SimpleCell(img, rf);
  rects = [];
  step = 6;
  W = length(1:step:(w-t.sampleSize(1)));
  H = length(1:step:(h-t.sampleSize(2)));
  for x = 1:step:(w-t.sampleSize(1))
    for y = 1:step:(h-t.sampleSize(2))
      rects = [rects; x,y,x+t.sampleSize(1),y+t.sampleSize(2)];
    end
  end
  if isempty(rects)
    rects = [1,1,w,h];
    W = 1;
    H = 1;
  end
  c = SomComplexCell(t.complex, ridge, ori, t.sampleSize, rects, 0.8, 2);
  [v,m] = SomV4Cell(t.v4som, f.v4data, t.sampleSize, rects, 1);
  [net,out] = BPnetTrain(bpnet, [c;v]);
  out = reshape(out, [H,W]);
  list = MaxRect(out, ethz(trainCat).sampleSize/step*1.5);
  idx = list(:,1) * H + list(:,2) + 1;
  data = [c(:,idx);v(:,idx)];
end