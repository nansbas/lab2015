function IeeeTipFigure(data, i)
  close all
  hold on
  colororder = [0,0,0;0,0,1;1,0,0;0,0.8,0.2;0.7,0.7,0;0.7,0,0.7];
  idx = [];
  for j = 1:length(data(i).line)
    idx(j) = isempty(data(i).line(j).fppi);
  end
  set(gca,'ColorOrder',colororder(~idx,:));
  fontsize = 15;
  arg = {};
  leg = {};
  p = 1;
  for j = 1:length(data(i).line)
    if isempty(data(i).line(j).fppi), continue; end
    arg{p*2-1} = data(i).line(j).fppi;
    arg{p*2} = data(i).line(j).rate;
    leg{p} = data(i).line(j).author;
    p = p + 1;
  end
  plot(arg{:},'linewidth',3);
  set(gca,'xlim',[0,1.5],'fontsize',fontsize,'xtick',0:0.2:1.5,'ytick',0:0.2:1,'linewidth',2);
  xlabel('False-positives per image','fontsize',fontsize);
  ylabel('Detection rate','fontsize',fontsize);
  title(data(i).name,'fontsize',fontsize);
  legend(leg,'fontsize',fontsize,'linewidth',1);
  set(gcf,'position',[100,100,400,280],'paperpositionmode','auto');
  grid on
  box on
  hold off
end

function IeeeTipFigureMpegDemo(mpeg, i, j)
  img = mpeg(i).files(j).image;
  img = padarray(img, [10,10]); 
  img = uint8((img > 0) * 255);
  img = imresize(img, sqrt(20000/size(img,1)/size(img,2)));
  [rf,~] = MakeSimpleRF(7, 0:30:170, [2,3]);
  [~,~,r] = SimpleCell(img, rf);
  [~,m,l] = FindLine(double(r), 9, 0);
  close all
  subplot(1,2,1);
  imshow(img);
  subplot(1,2,2);
  FindV4Feature(l, 3, 7);
  axis off
end

function EthzV4FeatureDemo(ethz, i, j, t1, t2, t3)
  img = ethz(i).files(j).image;
  ime = ethz(i).files(j).edgeImage;
  imshow(img);
  pt = ginput(2);
  img = img(pt(1,2):pt(2,2),pt(1,1):pt(2,1),:);
  ime = ime(pt(1,2):pt(2,2),pt(1,1):pt(2,1));
  [r,m,l]=FindLine(double(ime),9,t1);
  close all;
  f = FindV4Feature(l, t2, t3);
  axis off;
  imwrite(img, 'd:/1.png');
end

function EthzTimeTable()
  fprintf('Category ');
  for i = 1:5
   fprintf('& %s ', LqEthzTime(i).name);
  end
  fprintf('\\\\\nOur method (mean)');
  for i = 1:5
   fprintf('& %.2f ', mean(LqEthzTime(i).time(1,:)));
  end
  fprintf('\\\\\nOur method (min)');
  for i = 1:5
   fprintf('& %.2f ', min(LqEthzTime(i).time(1,:))+0.01);
  end
  fprintf('\\\\\nOur method (max)');
  for i = 1:5
   fprintf('& %.1f ', max(LqEthzTime(i).time(1,:)));
  end
  fprintf('\\\\\nMa et al (mean)');
  for i = 1:5
   fprintf('& %.1f ', mean(LqEthzTime(i).time(2,:)));
  end
  fprintf('\\\\\nMa et al (min)');
  for i = 1:5
   fprintf('& %.1f ', min(LqEthzTime(i).time(2,:)));
  end
  fprintf('\\\\\nMa et al (max)');
  for i = 1:5
   fprintf('& %.1f ', max(LqEthzTime(i).time(2,:)));
  end
  fprintf('\\\\\n')
end

function EthzTimeFigure(ethz, idx)
  p = ethz(idx).time;
  n = size(p,2);
  plot(1:n, p(1,:),'-',1:n,p(2,:),'--','LineWidth',2)
  set(gca, 'fontsize',14)
  xlabel('Image number','fontsize',14)
  ylabel('Time cost per image (minute)','fontsize',14)
  title([ethz(idx).name, ' category from ETHZ'],'fontsize',14)
  set(gcf,'Position',[100,100,480,260])
  set(gca, 'xlim',[1,n])
  if idx == 1
    legend(ethz(idx).legend)
  end
end

function RouteDemo()
  imgidx = 11;
  lineidx = [6,7];
  img = ethzdata(1).files(imgidx).edge;
  [r,m,p,l]=BuildGraph(double(img),100);
  line = l{lineidx(1)};
  a = [];
  for i = 9:2:size(line,1)
    xy = double(line(i,:) - line(i-8,:));
    a = [a,atan2(xy(2),xy(1))];
  end
  a = mod(round(a/pi*180)+360,180);
  b = resample(a,64,length(a));
  line = l{lineidx(2)};
  a = [];
  for i = 9:2:size(line,1)
    xy = double(line(i,:) - line(i-8,:));
    a = [a,atan2(xy(2),xy(1))];
  end
  a = mod(round(a/pi*180)+360,180);
  a = resample(a,64,length(a));
  plot(1:64,a,'r',1:64,b,'b');
  set(gca,'XTick',[],'XLim',[1,64],'YLim',[0,180]);
  set(gcf,'Position',[100,100,360,140]);
end