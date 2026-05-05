clear all
close all

%%

img_raw = 'Xray.png';

%% Gör om bild till 0-1 värden
img_pixels = imread(img_raw);
img_0to1 = im2double(img_pixels);

[M, N] = size(img_0to1);

%%
%kollar maxvärdet på högsta pixeln
max(max(img_0to1))

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


%% Add noise 
img_blurred_noise = imnoise(img_blurred, "gaussian");
subplot(1,2,1);
imshow(img_blurred_noise);
 
%vår kod
img_blurred_noise_ft = fftshift(fft2(img_blurred_noise));
subplot(1,2,2);
imshow(img_blurred_noise_ft);

%chattens förslag
%img_blurred_noise_ft = fft2(img_blurred_noise);
%subplot(1,2,2);
%imshow(log(1+abs(fftshift(img_blurred_noise_ft))), []);

%% Pseudoinverse nytt försök

epsilon = 0.1; %Låga värden ger mycket noise, höga värden dålig detalj

PSF_zero = zeros(size(PSF_fourier)); %Gör en lika stor matris med bara 0:or
Cutoff_matrix = abs(PSF_fourier) <= epsilon; %Bildar en boolean matris, True där värden är större än epsilon, alltså okej att ta inverse på
imshow((Cutoff_matrix),[])
%imshow (Cutoff_matrix)

PSF_zero(Cutoff_matrix) = 1 ./PSF_fourier(Cutoff_matrix); % När Cutoff är true ersätts nollor med inversen av H (PSF_fourier)
imshow(log(abs(PSF_zero)),[])

img_restored = ifft2(img_blurred_ft .*PSF_zero); % Utan noise
subplot(1,2,1);
imshow(img_restored);

%img_blurred_noise_ft är noiset i fourier, som multipliceras med
%Nollmatrisen (där nollorna ersätts på alla ställen "som spelar roll")
img_restored_noise = ifft2(img_blurred_noise_ft .* PSF_zero); %med noise
subplot(1,2,2);
imshow(img_restored_noise);


%%
%fem kopior av rotade originalbilder
distorted1 = fft2(imrotate(img_0to1, 10, "crop"));
distorted2 = fft2(imrotate(img_0to1, 355, "crop"));
distorted3 = fft2(imrotate(img_0to1, 5, "crop"));
distorted4 = fft2(imrotate(img_0to1, 350, "crop"));
distorted5 = fft2(flip(img_0to1));
distorted_av = (distorted1 + distorted2 + distorted3 + distorted4+ distorted5)./6;


%%
s_nn = img_blurred_noise_ft;
s_ff = abs(distorted_av).^2;

K = s_nn ./s_ff;

G = fft2(img_blurred_noise);  
H = PSF_fourier;

F_hat = (conj(H) ./ (abs(H).^2 + K)) .* G; %se slide 57 för formel

img_wiener = ifft2(F_hat);

imshow(img_wiener, []);
