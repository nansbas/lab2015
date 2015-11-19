function IeeeTipFigure(ethz, idx)
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

%{
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
%}