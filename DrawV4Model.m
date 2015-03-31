function DrawV4Model(model)
  %figure
  hold on
  if size(model,2) <= 5
    model = model(:,[2,3,1,4,5]);
    radius = 0.05;
    rects = model(:,1:2) - radius;
    line1 = [model(:,1),model(:,1)+cos(model(:,4))*radius,model(:,2),model(:,2)+sin(model(:,4))*radius];
    line2 = [model(:,1),model(:,1)+cos(model(:,5))*radius,model(:,2),model(:,2)+sin(model(:,5))*radius];
  else
    radius = mean(model(:,4)) / 3;
    rects = model(:,5:6) - radius;
    line1 = [model(:,5),model(:,5)+cos(model(:,9))*radius,model(:,6),model(:,6)+sin(model(:,9))*radius];
    line2 = [model(:,5),model(:,5)+cos(model(:,12))*radius,model(:,6),model(:,6)+sin(model(:,12))*radius];
  end
  model(:,3) = model(:,3) - min(model(:,3));
  maxColor = max(model(:,3));
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