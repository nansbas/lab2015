%% get outline masks.
%{
for i = 1:5
  folder = ['saved-result/dataset/ETHZShapeClasses-V1.2/',ethzdata(i).name,'/'];
  n = 0;
  for j = 1:length(ethzdata(i).files)
    m0 = dir([folder,ethzdata(i).files(j).name,'_',lower(ethzdata(i).name),'_outlines.pgm']);
    m01 = dir([folder,ethzdata(i).files(j).name,'_half_',lower(ethzdata(i).name),'_outlines.pgm']);
    m1 = dir([folder,ethzdata(i).files(j).name,'.mask.*.png']);
    m2 = dir([folder,ethzdata(i).files(j).name,'_big.mask.*.png']);
    m3 = dir([folder,ethzdata(i).files(j).name,'_small.mask.*.png']);
    m4 = dir([folder,ethzdata(i).files(j).name,'_half.mask.*.png']);
    masks = [m0;m01;m1;m2;m3;m4];
    n = n + length(masks);
    imgall = [];
    for k = 1:length(masks)
      img = imread([folder,masks(k).name]);
      img = img~=median(img(:));
      if isempty(imgall)
        imgall = img(:,:,1);
      else
        imgall = imgall|img(:,:,1);
      end
    end
    fprintf('%d:run %d,%d: %s\n', n, i, j, ethzdata(i).files(j).name);
    if length(masks) ~= size(ethzdata(i).files(j).groundtruth,1)
      %fprintf('--------!!!======== WARN: not equal, masks=%d, groundtruth=%d\n', length(masks),size(ethzdata(i).files(j).groundtruth,1));
    end
    if isempty(imgall)
      fprintf('--------!!!======== WARN: empty mask\n');
    else
      ethzdata(i).files(j).mask = imgall;
      ethzv4(i).files(j).mask = imgall;
    end
  end
end
%}
%% read data from ethz-data.
%{
ethzv4 = [];
for i = 1:12
  for j = 1:length(ethzdata(i).files)
    fprintf('Run on image %d:%d:%s ... ... ', i, j, ethzdata(i).files(j).name);
    img = double(ethzdata(i).files(j).edge);
    [map,lines] = FindLine(img, img, 0.1, 20);
    f = FindV4Feature(lines, 1.6, 20);
    ethzv4(i).files(j).v4 = f;
    ethzv4(i).files(j).groundtruth = ethzdata(i).files(j).groundtruth;
    ethzv4(i).files(j).name = ethzdata(i).files(j).name;
    saveas(gcf, ['temp/newv4-',num2str(i),'-',num2str(j),'.jpg']);
    close gcf;
    fprintf('OK\n');
  end
end
%}
%% learn shape model.
%
for i=3
  [c,dist,label,maxZero,x,y,s,d,a,n,ignore] = LearnV4ShapeModel(ethzv4(i).files, ethzv4(i).model.init, ethzv4(i).model.sampleIndex);
  ethzv4(i).cluster.c = c;
  ethzv4(i).cluster.d = dist;
  ethzv4(i).model.label = label;
  ethzv4(i).model.maxZero = maxZero;
  ethzv4(i).model.x = x;
  ethzv4(i).model.y = y;
  ethzv4(i).model.s = s;
  ethzv4(i).model.d = d;
  ethzv4(i).model.a = a;
  ethzv4(i).model.n = n;
  ethzv4(i).model.ignore = ignore;
end
%}
%% Find where can set empty label.
%{
for i = [1,2,4,5]
  n = length(ethzv4(i).model.label);
  ignoreAfter = zeros(n,n);
  for j = 1:length(ethzv4(i).sample.label)
    k = ethzv4(i).sample.label{j};
    k(1) = 0;
    k = [k,n+1];
    for p = 2:length(k)
      for q = (k(p-1)+1):(k(p)-1)
        ignoreAfter(q,k(p-1)+1) = 1;
      end
    end
  end
  ethzv4(i).model.ignoreAfter = ignoreAfter;
end
%}
%% Check label and cluster consistent.
%{
for i=[1,2,4,5]
 for j=1:length(ethzv4(i).sample.index)
  k=ethzv4(i).sample.index{j};
  for m=2:length(k)
   cl=ethzv4(i).sample.cluster{j}(m);
   la=ethzv4(i).sample.label{j}(m);
   if ~ismember(cl, ethzv4(i).model.label{la})
    fprintf('! warning: %d,%d,%d\n', i,j,m);
   end
  end
 end
end
%}
