function [character, I_result] = get_next_char(I, n_divide)
%左到右找可以切的地方
if nargin < 2
	n_divide = 1;
end

[height, width] = size(I);
x = 0;
while x < width-1 && sum(I(:,x+1)) >= n_divide
	x = x + 1; %直到垂直線的白點數量小於n_divide才會停止
end

I_crop = crop(imcrop(I,[1,1,x,height]), n_divide);
[h, w] = size(I_crop);
if x > 8 || w/h < 0.5 %寬高有沒有到特定條件
	character = I_crop; %把切下來的東西覆蓋過去
else
	character = []; %沒有符合列出空矩陣
end

I(:,1:x) = 0;%把剛才原圖那邊切出來的部分設為0
if sum(sum(I)) ~= 0 %如果整張圖上面有白點的話
	I_result = crop(I, n_divide); %輸出圖在做一次crop
else
	I_result = [];
end

end