function IeeeTipFigure(ethz, i, j, t1, t2, t3)
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

function IeeeTipEthzTimeTable()
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

function IeeeTipEthzTimeFigure(ethz, idx)
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

function IeeeTipRouteDemo()
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