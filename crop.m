function I_result = crop(I, n_divide) %%把圖丟進來，把上下左右黑邊(不重要的)切掉，只留下最接近的

if nargin < 2
	n_divide = 1; %%設定一個值，如果白點的數量小於n_divide的話，就分割
end

[h, w] = size(I);
top = 1;   %%這四個邊都是在最邊邊的地方
bottom = h;
left =1;
right = w;
while top < h && sum(I(top,:)) < n_divide
    top = top+1; %%top從一開始上往下，直到水平線上有白點為止
end
while bottom >= 1 && sum(I(bottom,:)) < n_divide
    bottom = bottom-1; %%bottom下往上，直到水平線上有白點為止
end
while left < w && sum(I(:,left)) < n_divide
    left = left+1;%%left左往右，直到垂直線上有白點為止
end
while right >= 1 && sum(I(:,right)) < n_divide
    right = right -1;%%right右往左，直到垂直線上有白點為止
end
height = bottom - top; %%切圖，左上的點加上寬高來切圖
width = right - left;

I_result = imcrop(I,[left,top,width,height]); %%每次呼叫crop的話就會把上下左右沒有白點的地放給去掉
end