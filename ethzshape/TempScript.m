%% load horse-data
%{
%[rf,out]=MakeSimpleRF(9,0:5:175,[6,6]);
for i=1:length(horsedata.posFiles)
  close all;
  FindV4Feature('drawcolor',posFiles(i).v4,[1,1,1]/4);
  pause
end
%}
%% draw ethz fppi curve
%{
hold on
h1 = plot(r(:,1),r(:,2),'LineWidth',3,'Color',[0,114,189]/255);
h2 = plot(0,0,'-','LineWidth',3,'Color',[0,0.5,0]);
h3 = plot(0,0,'--','LineWidth',2,'Color',[0,0.5,0]);
h4 = plot(0,0,'-','LineWidth',3,'Color',[1,0,0]);
h5 = plot(0,0,'--','LineWidth',2,'Color',[1,0,0]);
h6 = plot(0,0,'--','LineWidth',3,'Color',[0,0,1]);
legend([h1,h2,h3,h4,h5,h6],{'Our model','Ferrari et al. PAMI 08(20% IoU)','Ferrari et al. PAMI 08(PASCAL)','Full system(20% IoU)','Full system(PASCAL)','Hough only (PASCAL)'});
hold off
%}
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
for i = 4:5
  for j = 1:length(ethz(i).files)
    for k = 1:size(ethz(i).files(j).groundtruth,1)
      gt = ethz(i).files(j).groundtruth(k,:);
      if i <= 3
        maskname = ['D:\Downloads\ethz_shape_classes_v12\',ethz(i).name,'\',ethz(i).files(j).name,'.mask.',num2str(k-1),'.png'];
        img = imread(maskname) > 0;
      else
        maskname = ['D:\Downloads\ethz_shape_classes_v12\',ethz(i).name,'\',ethz(i).files(j).name,'_',lower(ethz(i).name),'_outlines.pgm'];
        img = imread(maskname);
        img = img ~= median(img(:));
      end
      img = img(gt(2):gt(4),gt(1):gt(3),1);
      imwrite(img, ['../temp/',num2str(i),'-',num2str(j),'-',num2str(k),'-',ethz(i).name,'-',ethz(i).files(j).name,'.png']);
      ethz(i).files(j).mask{k}=img;
    end
  end
end
%}
%% get V4 features.
%{
ethzv4 = [];
for i = 1:5
  ethzv4(i).name = ethz(i).name;
  for j = 1:length(ethz(i).files)
    fprintf('Run on image %d:%d:%s ... ... \n', i, j, ethz(i).files(j).name);
    img = double(ethz(i).files(j).edgeImage);
    [~,~,lines] = FindLine(img, 20, 1);
    close all;
    f = FindV4Feature(lines, 2.5, 20);
    ethzv4(i).files(j).name = ethz(i).files(j).name;
    ethzv4(i).files(j).groundtruth = ethz(i).files(j).groundtruth;
    ethzv4(i).files(j).mask = ethz(i).files(j).mask;
    ethzv4(i).files(j).v4 = f;
    ethzv4(i).files(j).lines = lines;
    saveas(gcf, ['../temp/v4',num2str(i),'-',num2str(j),'.jpg']);
  end
end
%}
%% learn shape model.
%{
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
