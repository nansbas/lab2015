function [enty,acty] = V4LocalFeature(img)
  scale = 27; %[9,13,19,27];
  for s = scale
    [rf,~] = MakeSimpleRF(s,0:20:175,[3,3]);
    [~,cout] = SimpleCell(img,rf,fspecial('gauss',ceil(s*1.2),s/4));
    acty = max(cout,[],3);
    cout(cout<0.001) = 0.001;
    p = cout ./ repmat(sum(cout,3),[1,1,size(rf,3)]);
    enty = -sum(p.*log(p),3);
  end
end