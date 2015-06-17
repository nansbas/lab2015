function f = MatchV4inImage(model, image)
  lines = image.lines;
  v4set = image.v4;
  for i = 1:length(lines)
    r = rand();
    g = rand();
    b = rand();
    for j = 1:size(lines{i})
      img(lines{i}(j,2),lines{i}(j,1),1) = r;
      img(lines{i}(j,2),lines{i}(j,1),2) = g;
      img(lines{i}(j,2),lines{i}(j,1),3) = b;
    end
  end
  img = 1 - img;
  imshow(img);
  hold on
  for i = 1:length(lines)
    v4 = v4set(v4set(:,9)==i,:);
    if isempty(v4), continue; end
    [m,d,c,t] = MatchV4Array(model.v4, model.line, v4, lines{i});
    if m < 3, continue; end
    if t(1) < 0 || t(2) < 0, continue; end
    text(lines{i}(1,1),lines{i}(1,2),[num2str(i),':',num2str(m),':',num2str(d)],'FontSize',14);
    rectangle('Position', [t(3),t(4),model.bound(3:4).*t(1:2)], 'LineWidth', 2);
  end
  hold off
end