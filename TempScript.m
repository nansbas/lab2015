%{
% Som Training
eth = ethz2;
for i = 1:length(eth)
  som = eth(i).som;
  %som = SomModel('init', [], eth(i).sampleSize(1), eth(i).sampleSize(2));
  [som,map] = SomModel('learn', som, eth(i).sampleRidge, eth(i).sampleOri);
  eth(i).som = som;
  eth(i).sampleMap = map;
end
ethz2 = eth;
%}
%{
%% Resize images and samples
[rf,out]=MakeSimpleRF(9,0:5:175,[6,6]);
for i = 1:length(ethz)
  n = 0;
  ethz(i).sample = {};
  ethz(i).sampleRidge = [];
  ethz(i).sampleOri = [];
  for j = 1:length(ethz(i).files)
    %fprintf('%s: %s\n', ethz(i).name, ethz(i).files(j).name);
    img = ethz(i).files(j).image;
    h = size(img,1);
    w = size(img,2);
    gt = ethz(i).files(j).groundtruth;
    rx = (ethz(i).sampleSize(1)-20) * ((gt(:,3)-gt(:,1)).^(-1));
    ry = (ethz(i).sampleSize(2)-20) * ((gt(:,4)-gt(:,2)).^(-1));
    gt = round(gt .* [rx,ry,rx,ry] + repmat([-10,-10,10,10],size(gt,1),1));
    imr = round([ry * h, rx * w]);
    gt(gt<1) = 1;
    for k = 1:size(gt,1)
      gt(k,3) = gt(k,1) + ethz(i).sampleSize(1) - 1;
      gt(k,4) = gt(k,2) + ethz(i).sampleSize(2) - 1;
      padx = 0;
      pady = 0;
      if gt(k,3) > imr(k,2)
        padx = gt(k,3) - imr(k,2);
        gt(k,3) = imr(k,2);
      end
      if gt(k,4) > imr(k,1)
        pady = gt(k,4) - imr(k,1);
        gt(k,4) = imr(k,1);
      end
      img2 = imresize(img,imr(k,:));
      [out,ori,ridge]=SimpleCell(img2,rf);
      xidx = gt(k,1):gt(k,3);
      yidx = gt(k,2):gt(k,4);
      n = n + 1;
      if padx > 0 || pady > 0
        fprintf('%d:%s:%s: size: %d,%d; pad: %d,%d\n', n, ethz(i).name, ethz(i).files(j).name, gt(k,3)-gt(k,1)+1,gt(k,4)-gt(k,2)+1, padx, pady);
      end
      ethz(i).sample{n} = padarray(img2(yidx,xidx,:),[pady,padx],0,'post'); 
      ethz(i).sampleRidge = cat(3, ethz(i).sampleRidge, padarray(ridge(yidx,xidx),[pady,padx],0,'post'));
      ethz(i).sampleOri = cat(3, ethz(i).sampleOri, padarray(ori(yidx,xidx),[pady,padx],0,'post'));
    end
    imr = round(mean(imr,1));
    ethz(i).files(j).imageSize = [imr(2),imr(1)];
  end
end
%}
%{
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