function Caltech101Result

zhang=[1, 0.22; 5, 0.46; 10, 0.55; 15, 0.595; 20, 0.63; 30, 0.685]; % Zhang et al (CVPR06)
griffin=[5, 0.44; 10, 0.54; 15, 0.597; 20, 0.62; 25, 0.645; 30, 0.67]; % Griffin et al (Tech.Rep.06)
lazebnik=[15, 0.57; 30, 0.655]; % Lazebnik et al (CVPR06)
wang=[5, 0.197; 15, 0.445; 20, 0.5; 25, 0.568; 30, 0.635]; % Wang et al (CVPR06)
grauman = [1, 0.18; 3, 0.28; 5, 0.35; 10, 0.43; 15, 0.495; 20, 0.535; 25, 0.555; 30, 0.585]; % Grauman & Darrell (ICCV05)
mutch = [15, 0.51; 30, 0.565]; % Mutch & Lowe (CVPR06)
bosch = [5,0.54; 10,0.63; 15,0.68; 20,0.71; 25,0.755; 30,0.78]; % Bosch et al (CIVR07)
bosch2 = [5,0.578; 10,0.67; 15,0.71; 20,0.725; 25,0.77; 30, 0.798]; % Bosch et al (ICCV07)

liu = [15, 0.6754; 30, 0.7487]; % Liu et al (PR2013)
yanliu = [5, 0.583; 25, 0.7141]; % Yan Liu et al (PR2011)
cjzhang = [15, 0.7086; 30, 0.7662]; % Zhang et al (CVIU2014)
luo = [15, 0.6708; 30, 0.7360]; % Luo et al (NeuroComp2015)
heo = [5, 0.5483; 15, 0.6981; 30, 0.7654]; % Heo et al (ISVC2014)
boiman = [5, 0.57; 15, 0.735; 30, 0.79]; % Boiman et al (CVPR08)
our = [5, 0.68; 10, 0.73; 15, 0.75; 20, 0.77; 25, 0.8; 30, 0.81];

%figure;
h1 = plot(our(:,1),our(:,2), '-ok', 'LineWidth', 1);
hold on;
h2 = plot(boiman(:,1),boiman(:,2), ':*', 'LineWidth', 1); % 2008
h3 = plot(heo(:,1),heo(:,2), ':v', 'LineWidth', 1); % 2014
h4 = plot(liu(:,1),liu(:,2), ':h', 'LineWidth', 1); % 2013
h5 = plot(bosch2(:,1),bosch2(:,2), ':^', 'LineWidth', 1); % 2007
h6 = plot(zhang(:,1),zhang(:,2), ':+', 'LineWidth', 1); % 2006
h7 = plot(wang(:,1),wang(:,2), ':d', 'LineWidth', 1); % 2006
h8 = plot(lazebnik(:,1),lazebnik(:,2), ':<', 'LineWidth', 1); % 2006
h9 = plot(grauman(:,1), grauman(:,2), ':>', 'LineWidth', 1); % 2005

grid on;
hold off;

xlabel('Number of training samples');
ylabel('Performance');
set(gca, 'XLim', [0,30], 'YLim', [0,0.85]);
set(gca, 'XTick', 0:5:40, 'YTick', 0:0.1:0.9);
legend([h1,h3,h4,h2,h5,h6,h7,h8,h9], ...
  {'Our model', 'Heo et al. 2014', 'Liu et al. 2013', 'Boiman et al. 2008', 'Bosch et al. 2007', ...
  'Zhang et al. 2006', 'Wang et al. 2006', 'Lazebnik et al. 2006', 'Grauman et al. 2005'}, ...
  'fontsize', 10);

pos = get(gcf, 'Position');
pos(3) = 500; 
pos(4) = 350;
set(gcf, 'Position', pos);

end
