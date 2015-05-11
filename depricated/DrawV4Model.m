function DrawV4Model(pos, ori, strength, neighbor)
  DrawSOM(pos, strength, neighbor);
  %DrawV4ModelBasic(pos, ori, strength(:,1));
end

function DrawSOM(pos, strength, neighbor)
  %figure
  hold on
  radius = min([max(pos(:,1))-min(pos(:,1)), max(pos(:,2))-min(pos(:,2))]) / 32;
  rects = pos - radius;
  hit = strength(:,2);
  strength = strength(:,1) - min(strength(:,1));
  strength = strength / max(strength) * 0.7 + 0.3;
  [~,idx] = sort(strength);
  for i = idx'
    for j = idx'
      if neighbor(i,j) > 0 && i > j
        line(pos([i,j],1), pos([i,j],2));
      end
    end
  end
  for i = idx'
    rectangle(...
      'Position', [rects(i,:), radius*2, radius*2], 'LineWidth', 1, ...
      'Curvature', [1,1], 'EdgeColor', -[1,1,1]*strength(i)+1);
    text(pos(i,1), pos(i,2), num2str(hit(i)), 'HorizontalAlignment', 'center', ...
      'Color', -[1,1,1]*strength(i)+1);
  end
  set(gca, 'YDir', 'reverse', 'XLim', [-0.1,1.1], 'YLim', [-0.1,1.1], 'XTick', [], 'YTick', [], 'Position', [0,0,1,1]);
  hold off
end

function DrawV4ModelBasic(pos, ori, strength)
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