clear all;
clc;

Nth_DATASET = 2;

% preprocess 1 : create characters of letter and number
fileList = dir(['./characters/*.png']);
n_characters = length(fileList);
if n_characters ~= 62 %%小寫(26)+大寫(26)+數字(10)
	create_char('./image/letter.png', 'abcdefghijklmnopqrstuvwxyz');
	create_char('./image/capital.png', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
	create_char('./image/number.png', '0123456789');
	disp('Characters created complete!');
end

% preprocess 2 : random select a CAPTCHA image in dataset
path_jpg = strcat('./CAPTCHA/', string(Nth_DATASET), '/*.jpg');
path_png = strcat('./CAPTCHA/', string(Nth_DATASET), '/*.png');
dataset_jpg = dir([path_jpg]);
dataset_png = dir([path_png]);
dataset = cat(1, dataset_jpg, dataset_png);%%連接

X = round(rand(1,1)*length(dataset));
filename = strcat('./CAPTCHA/', string(Nth_DATASET), '/', dataset(X).name);
I_rgb = imread(filename);
disp('CAPTCHA read complete!');

% method 1 : replace those color equals to rectangle edge color to white
% %%把rbg的四個邊上的顏色讀取近來做成一個list
[height, width] = size(I_rgb);%%讀rgb的寬和高
H = cat(2, I_rgb(1,1:width), I_rgb(height,1:width)); %%上下兩個水平的邊
V = cat(1, I_rgb(1:height,1), I_rgb(1:height,width));%%左右兩個垂直的邊，
side_colors = cat(2, H, V.');%%2的意思為將width的長度連結再一起，2個width，height同理，.'為轉置，轉置之後相加會變成1*2w+2h *用來分割長和寬
side_colors = unique(side_colors);%%將重複的刪除
I_clean = I_rgb;
for i=1:length(side_colors) %%每次都使用一個side_colors(四個邊上面的顏色)，如果有一樣的就變成白色
	I_clean(find(I_clean==side_colors(i)))=255; %%find作用為找index(i_clean裡面的特定顏色)，
end %%for的作用就是把邊上特定顏色跑一遍
if Nth_DATASET > 4 %%偷吃步(不用講)
	I_clean = I_rgb; %%覆蓋
end

% method 2 : automatically select a threshold to denoise image
I_gray = rgb2gray(I_clean); %%先變成灰階圖
threshold = graythresh(I_gray);
if Nth_DATASET == 0
	threshold = 0.4; %%偷吃步，對captcha的第0個資料夾
end
I_thresh = imbinarize(I_gray, threshold); %%利用threshold讓圖片變成黑白


% method 3 : construct a square structure element to make image dilate
I_reverse = (I_thresh ~= 1); %~= == != %把變成黑白的圖片做反色(黑白變成白黑)
%輸入0返回1 輸入1返回0
I_dilate = imresize(I_reverse, 1.25);%%先放大1.25倍
SE0 = strel('square', 3); %變成3*3的方形
I_dilate = imdilate(I_dilate, SE0); %%膨脹
I_dilate = imresize(I_dilate, 0.8); %%在縮小0.8倍
%%如果沒有先放大在縮小的話，圖片會變得很誇張
I_dilate1 = imdilate(I_reverse, SE0); %%膨脹
SE1 = strel('disk', 3);
%I_open = imopen(I_reverse, SE1);
I_open = imopen(I_reverse, ones(5,1)); %%開運算為先侵蝕再膨脹，消除小物體在分離，跟侵蝕很像，差別再膨脹、侵蝕都會改變面積，開運算部會
%%開運算目的是把黏再一起的地方分開來，ones(5,1)為垂直，ones會創造裡面都是一的矩陣，去比較，如果線蓋到的地方會計算裡面一的個數，如果小於某個值(垂直連接不夠的地方)就會設為0
I_close = imclose(I_open, ones(1,5)); %%先不用
subplot(4,2,1), imshow(I_rgb), title('RGB image')
subplot(4,2,2), imshow(I_clean), title('clean image')
subplot(4,2,3), imshow(I_thresh), title('threshold image')
subplot(4,2,4), imshow(I_reverse), title('reverse image')
subplot(4,2,5), imshow(I_dilate), title('dilate image')
subplot(4,2,6), imshow(I_open), title('open image')
subplot(4,2,7), imshow(I_close), title('close image')
subplot(4,2,8), imshow(I_dilate1), title('dilate1')
% method 4 : cutting image into several characters
I = I_reverse; %%把剛剛反色的圖拿來用
cnt = 1;
open = false; 
while true
	i = 1;
	I_crop = crop(I, cnt); %把上下左右不重要的地放給去除掉
	while size(I_crop,2) > 10 %%如果寬太長的話就會依值執行下面的迴圈
		[character, I_crop] = get_next_char(I_crop, cnt); %抓下一個character，[]裡面一個是已切除的圖，另一個是尚未切除的圖
		if size(character,1) > 0 && size(character,2) > 0 %如果character的寬跟高都>0的話 %看是否為空矩陣
			chars{i} = character;%如果不適空矩陣的話，令一個數組來儲存他 
			i = i+1;%在往下一個圖片去抓
		else
			continue
		end
	end
	disp(length(chars)); %看切出來有幾個character
	if length(chars) >= 4 %因為一班來說驗證碼都>=4個數
		break
	end
	cnt = cnt+1; %如果沒有的話，令一個計數器去+1，計數器每增加一個就是增加一次容忍值
	if cnt==20 || open %cnt就是我丟進去的n_divid(想成容忍度)
		open = true; %如果切了20次都沒有辦法>4的話，就做開運算
		cnt = 0;
		I = imopen(I, ones(3,1)); %(3,1)每次切一點點點
		%I = imclose(I, ones(2,1));
	end
end

for i=1:length(chars)
	chars{i} = imresize(chars{i},[40,30]);
end

% method 5 : compare cutting characters with standard characters
k = 1;
if Nth_DATASET < 4
	n_characters = 33; %matlab裡面開頭1的話會先讀取，所以d-z有23個+ 0-9有10個 = 33個
	k = 24; %從0開始讀
end
for i=1:length(chars)%把驗證碼中的每個字卡依序讀出來
	for j = k:n_characters %只會讀24->33(數字就會是0~9)，10個 %跑原本做好的字卡		
		filename = strcat('./characters/', fileList(j).name); %把字卡的路徑拼起來
		character = imread(filename); %讀取字卡
		intersection(1,j) = sum(sum(chars{i} == character));%原本字卡的image跟切下來的字卡的image做交集(兩個都等於1的話 +1)，兩個圖片如果交集(顏色重疊)的地方越多，sum越大
    end %如果兩個字卡的pixel都是0(黑)的話，也會加(把兩張圖相似的地方疊起來)    chars{i}:驗證碼 character:做好的圖卡
	[val, idx] = max(intersection); %取最大的數字跟位置

	len = length(fileList(idx).name);%讀最大值的數字和位置，讀檔名
	str = fileList(idx).name(1:len-4);%把.png||.jpg給去除掉
	output(1,i) = char(str2double(str));%檔名ascii轉成數字之後，再用char function轉成character
end
output

