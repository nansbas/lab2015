function DrawV4Model(pos, ori, strength)
  %figure
  hold on
  radius = min([max(pos(:,1))-min(pos(:,1)), max(pos(:,2))-min(pos(:,2))]) / 64;
  rects = pos - radius;
  ori = ori / 180 * pi;
  line1 = [pos(:,1),pos(:,1)+cos(ori(:,1))*radius,pos(:,2),pos(:,2)+sin(ori(:,1))*radius];
  line2 = [pos(:,1),pos(:,1)+cos(ori(:,2))*radius,pos(:,2),pos(:,2)+sin(ori(:,2))*radius];
  strength = strength - min(strength);
  strength = strength / max(strength);
  [~,idx] = sort(strength);
  for i = idx'
    rectangle(...
      'Position', [rects(i,:), radius*2, radius*2], 'LineWidth', 1, ...
      'Curvature', [1,1], 'EdgeColor', -[1,1,1]*strength(i)+1);
    line(line1(i,1:2), line1(i,3:4), 'LineWidth', 2, ...
      'Color', -[1,1,0]*strength(i)+1);
    line(line2(i,1:2), line2(i,3:4), 'LineWidth', 2, ...
      'Color', -[0,1,1]*strength(i)+1);
  end
  set(gca, 'YDir', 'reverse');
  %set(gca, 'YDir', 'reverse', 'XLim', [-0.1,1.1], 'YLim', [-0.1,1.1], 'XTick', [], 'YTick', [], 'Position', [0,0,1,1]);
  %set(gcf, 'PaperPositionMode', 'auto', 'Position', [100,100,300,300]);
  hold off
end