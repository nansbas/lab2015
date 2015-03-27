function DrawV4Model(model)
    figure
    hold on
    maxColor = max(model(:,23));
    [~,idx] = sort(model(:,23));
    for i = idx'
        rectangle('Position', [model(i,5)-model(i,4),model(i,6)-model(i,4), model(i,4)*2, model(i,4)*2], ...
            'Curvature', [1,1], 'EdgeColor', -[1,1,1]*model(i,23)/maxColor+1);
    end
    set(gca, 'XLim', [0,1], 'YLim', [0,1], 'YDir', 'reverse');
    hold off
end