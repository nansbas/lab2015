function f = Matrix2Code(m)
  f = [];
  if iscell(m)
    for i = 1:length(m)
      f = [f, 10, mat2str(m{i})];
    end
  else
    f = mat2str(m);
  end
end