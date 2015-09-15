%% Image to gray scale.
% img: image.
function f = Image2Gray(img)
    if size(img,3) >= 3
        f = rgb2gray(img(:,:,1:3));
    else
        f = img(:,:,1);
    end
end