function DrawV4Model(model)
  %figure
  hold on
  maxColor = max(model(:,3));
  radius = mean(model(:,4)) / 3;
  rects = model(:,5:6) - radius;
  line1 = [model(:,5),model(:,5)+cos(model(:,9))*radius,model(:,6),model(:,6)+sin(model(:,9))*radius];
  line2 = [model(:,5),model(:,5)+cos(model(:,12))*radius,model(:,6),model(:,6)+sin(model(:,12))*radius];
  [~,idx] = sort(model(:,3));
  for i = idx'
    rectangle(...
      'Position', [rects(i,:), radius*2, radius*2], 'LineWidth', 2, ...
      'Curvature', [1,1], 'EdgeColor', -[1,1,1]*model(i,3)/maxColor+1);
    line(line1(i,1:2), line1(i,3:4), 'LineWidth', 2, ...
      'Color', -[1,0,1]*model(i,3)/maxColor+1);
    line(line2(i,1:2), line2(i,3:4), 'LineWidth', 2, ...
      'Color', -[0,1,1]*model(i,3)/maxColor+1);
  end
  set(gca, 'YDir', 'reverse');
  hold off
end