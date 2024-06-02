function create_char(filename, character)

I_RGB = imread(filename);
I_GRAY = rgb2gray(I_RGB); 
I_THRESH = imbinarize(I_GRAY,0.9); %THRESH值，不要等於0或1


I_REGION = (I_THRESH ~= 1); %反色
I_CUT = crop(I_REGION);

for i=1:length(character)
    [words{i},I_CUT] = get_next_char(I_CUT);
    words{i} = imresize(words{i},[40,30]);
	n = double(character(i));
	name = strcat('./characters/', string(n), '.png');
    imwrite(words{i},name);
end

end