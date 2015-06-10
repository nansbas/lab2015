function f = MatchV4inImage(model, lines, v4set)
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
    [m,d,c,t] = MatchV4Array(model.v4, v4, 'circular', model.position);
    if m < 3, continue; end
    text(lines{i}(1,1),lines{i}(1,2),[num2str(i),':',num2str(m),':',num2str(d)],'FontSize',14);
    rectangle('Position', t, 'LineWidth', 2);
  end
  hold off
end