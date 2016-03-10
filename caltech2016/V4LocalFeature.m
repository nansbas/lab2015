function [frame,enty,acty] = V4LocalFeature(img)
  scale = [9,13,19,27];
  frame = [];
  [xp,yp] = meshgrid(1:size(img,2),1:size(img,1));
  for s = scale
    [rf,~] = MakeSimpleRF(s,0:20:175,[3,3]);
    [sout,~,ridge] = SimpleCell(img,rf);
    cout = sout;
    for i = 1:size(rf,3)
      temp = cout(:,:,i); temp(ridge==0) = 0;
      cout(:,:,i) = imfilter(temp, fspecial('gauss', s*2, s/2));
    end
    acty = max(cout,[],3);
    cout(cout<0.001) = 0.001;
    p = cout ./ repmat(sum(cout,3),[1,1,size(rf,3)]);
    enty = -sum(p.*log(p),3);
    [~,mact] = FindMax(acty, s);
    p = enty<mean(enty(:)) & acty>mean(acty(:)) & mact;
    frame = cat(1, frame, [xp(p),yp(p),p(p)*s]);
  end
  close all;
  imshow(img);
  hold on;
  for i = 1:size(frame,1)
    rectangle('position',[frame(i,1:2)-frame(i,3),frame(i,[3,3])*2],'curvature',[1,1],'edgecolor',[0,1,0],'linewidth',1);
  end
  hold off;
end