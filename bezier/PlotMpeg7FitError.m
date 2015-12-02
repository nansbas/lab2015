args = {};
shape = {'-o', '-+', '-x', '-*', '-<', '->', '-s', '-d'};
for i = 1:8
  x = mpeg7fit(i).result(:,3);
  y = mpeg7fit(i).result(:,5)/max(mpeg7fit(i).averageSize)*100;
  args{i*3-2} = x;
  args{i*3-1} = y;
  args{i*3} = shape{i};
end
plot(args{:}, 'LineWidth', 1);
set(gca, 'fontsize', 12, 'xtick', 0:20:120, 'ytick', 0:1:5);
set(gcf, 'position', [100,100,480,300]);
xlabel('ÿ����������V4��������');
ylabel('����ػ����(%)')
legend({mpeg7fit.className});