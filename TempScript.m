%% Som Training
eth = ethz2;
for i = 1:length(eth)
  som = eth(i).som;
  %som = SomModel('init', [], eth(i).sampleSize(1), eth(i).sampleSize(2));
  [som,map] = SomModel('learn', som, eth(i).sampleRidge, eth(i).sampleOri);
  eth(i).som = som;
  eth(i).sampleMap = map;
end
ethz2 = eth;
%{
%% Resize images and samples
load('ethz2');
ethz = ethz2;
[rf,out]=MakeSimpleRF(9,0:5:175,[6,6]);
for i = 1:length(ethz)
  n = 1;
  ethz(i).sample = {};
  ethz(i).sampleRidge = [];
  ethz(i).sampleOri = [];
  sh = round(sqrt(40000 / ethz(i).ratio));
  sw = round(sh * ethz(i).ratio);
  ethz(i).sampleSize = [sw,sh];
  for j = 1:length(ethz(i).files)
    fprintf('%s: %s\n', ethz(i).name, ethz(i).files(j).name);
    img = ethz(i).files(j).image;
    w = size(img,2);
    h = size(img,1);
    gt = ethz(i).files(j).groundtruth;
    wh = sqrt((gt(:,3)-gt(:,1)) .* (gt(:,4)-gt(:,2)))/18;
    gt(:,1:2) = gt(:,1:2) - repmat(wh,[1,2]);
    gt(:,3:4) = gt(:,3:4) + repmat(wh,[1,2]);
    gt(gt<1) = 1;
    gt(gt(:,3)>w,3) = w;
    gt(gt(:,4)>h,4) = h;
    r = [(gt(:,3)-gt(:,1)).^(-1)*sw,(gt(:,4)-gt(:,2)).^(-1)*sh];
    gt(:,1:2) = round(gt(:,1:2) .* r(:,1:2));
    r(:,1) = r(:,1) * w;
    r(:,2) = r(:,2) * h;
    r = round(r);
    for k = 1:size(gt,1)
      img2 = imresize(img,[r(k,2),r(k,1)]);
      [out,ori,ridge]=SimpleCell(img2,rf);
      xidx = gt(k,1) + (2:sw-3);
      yidx = gt(k,2) + (2:sh-3);
      ethz(i).sample{n} = img2(yidx,xidx,:); n = n + 1;
      ethz(i).sampleRidge = cat(3, ethz(i).sampleRidge, ridge(yidx,xidx));
      ethz(i).sampleOri = cat(3, ethz(i).sampleOri, ori(yidx,xidx));
    end
    r = round(mean(r,1));
    ethz(i).files(j).imageSize = r;
  end
end
%% Read dataset files to MAT
%cats = {'apple','bottle','giraffe','hat','mug','starfish','swan'};
%fdr = '~/Downloads/dataset/extended_ethz_shapes/';
cats = {'Applelogos','Bottles','Giraffes','Mugs','Swans'};
fdr = '~/Downloads/ETHZShapeClasses-V1.2/';
for i = 1:length(cats)
  ethz2(i).name = cats{i};
  files = dir([fdr,cats{i},'/*.jpg']);
  ethz2(i).ratio = 0;
  for j = 1:length(files)
    name = files(j).name;
    img = imread([fdr,cats{i},'/',name]);
    name = name(1:length(name)-4);
    ethz2(i).files(j).name = name;
    ethz2(i).files(j).image = img;
    temp = dir([fdr,cats{i},'/',name,'_*.groundtruth']);
    fp = fopen([fdr,cats{i},'/',temp(1).name]);
    gt = fscanf(fp, '%f', [4,Inf]);
    fclose(fp);
    ethz2(i).files(j).groundtruth = gt';
    ethz2(i).ratio = ethz2(i).ratio + mean((gt(3,:)-gt(1,:))./(gt(4,:)-gt(2,:)));
  end
  ethz2(i).ratio = ethz2(i).ratio / length(files);
end
%}