img_raw = 'Xray.png';

%% Gör om bild till 0-1 värden
img_pixels = imread(img_raw);
img_0to1 = im2double(img_pixels);

[M, N] = size(img_0to1);

%% 
PSF_length = 60;
PSF_angle = 0;
PSF_true = fspecial("motion",PSF_length,PSF_angle);

img_distort = imfilter(img_0to1, PSF_true, "circular", "conv");

subplot(1,2,1); 
imshow(img_0to1);

subplot(1,2,2); 
imshow(img_distort);

%%
% nytt sätt att blurra fast med fourier 
PSF_length = 60;
PSF_angle = 0;
PSF_true = fspecial("motion",PSF_length,PSF_angle);

img_distort_ft = fft2(img_0to1); %gör om bilden till fourierdomänen så f-> F
PSF_fourier = psf2otf(PSF_true, [M,N]); %gör om psf till fouriervärden h -> H
img_blurred_ft = img_distort_ft .* PSF_fourier ; %F * H = G
img_blurred = ifft2(img_blurred_ft); % G -> g


subplot(2,3,1); 
imshow(img_0to1); %originalbild f

subplot(2,3,4);
imshow(log(abs(fftshift(img_distort_ft))),[]); %originalbild i ft, F

subplot(2,3,2);
imshow(PSF_true); % h 

subplot(2,3,5);
imshow(log(abs(fftshift(PSF_fourier))),[]); % H

subplot(2,3,3); 
imshow(img_blurred); % blurrad bild, g
 
subplot(2,3,6);
imshow(log(abs(fftshift(img_blurred_ft))),[]); %blurrad bild i ft, G


%% Add noise (Skipped for now)


%% Psuedoinverse filter
%ändrat till att räkna med fouriertransformerade blurrade bilden

img_restored = ifft2(img_blurred_ft ./PSF_fourier);
imshow(img_restored);

%%