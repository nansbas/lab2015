function out = RunEthzImage(ethz, trainCat, testCat, idx, rf)
  fprintf('Run cat %d on cat %d image %d\n', trainCat, testCat, idx);
  t = ethz(trainCat);
  f = ethz(testCat).files(idx);
  w = f.imageSize(1);
  h = f.imageSize(2);
  img = imresize(f.image, [h,w]);
  [temp,ori,ridge] = SimpleCell(img, rf);
  rects = [];
  W = length(1:3:(w-t.sampleSize(1)));
  H = length(1:3:(h-t.sampleSize(2)));
  for x = 1:3:(w-t.sampleSize(1))
    for y = 1:3:(h-t.sampleSize(2))
      rects = [rects; x,y,x+t.sampleSize(1),y+t.sampleSize(2)];
    end
  end
  if isempty(rects)
    rects = [1,1,w,h];
    W = 1;
    H = 1;
  end
  [c,m] = SomComplexCell(t.complex, ridge, ori, t.sampleSize, rects, 0.8, 2);
  [v,m] = SomV4Cell(t.v4som, f.v4data, t.sampleSize, rects, 1);
  [net,out] = BPnetTrain(t.bpnet, [c;v]);
  out = reshape(out, [H,W]);
end