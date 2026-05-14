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
title('f', 'FontSize', 24)

subplot(2,3,4);
imshow(log(abs(fftshift(img_distort_ft))),[]); %originalbild i ft, F
title('F', 'FontSize', 24)

subplot(2,3,2);
imshow(PSF_true); % h 
title('h', 'FontSize', 24)

subplot(2,3,5);
imshow(log(abs(fftshift(PSF_fourier))),[]); % H
title('H', 'FontSize', 24)

subplot(2,3,3);
imshow(img_blurred); % blurrad bild, g
title('g', 'FontSize', 24)

subplot(2,3,6);
imshow(log(abs(fftshift(img_blurred_ft))),[]); %blurrad bild i ft, G
title('G', 'FontSize', 24)

%% Add noise 
img_blurred_noise = imnoise(img_blurred, "gaussian");
subplot(1,2,1);
imshow(img_blurred_noise);
title('Blurred image with noise', 'FontSize', 24);

%vår kod
img_blurred_noise_ft = fftshift(fft2(img_blurred_noise));
subplot(1,2,2);
imshow(img_blurred_noise_ft);
title('Blurred image with noise in fourier domain', 'FontSize', 24)

%chattens förslag
%img_blurred_noise_ft = fft2(img_blurred_noise);
%subplot(1,2,2);
%imshow(log(1+abs(fftshift(img_blurred_noise_ft))), []);
%img_blurred_noise_ft = fft2(img_blurred_noise);
%subplot(1,2,2);
%imshow(log(1+abs(fftshift(img_blurred_noise_ft))), []);

%% Pseudoinverse nytt försök


epsilon = 0.1; %Låga värden ger mycket noise, höga värden dålig detalj

PSF_zero = zeros(size(PSF_fourier)); %Gör en lika stor matris med bara 0:or
Cutoff_matrix = abs(PSF_fourier) >= epsilon; %Bildar en boolean matris, True där värden är större än epsilon, alltså okej att ta inverse på

%imshow (Cutoff_matrix)

PSF_zero(Cutoff_matrix) = 1 ./PSF_fourier(Cutoff_matrix); % När Cutoff är true ersätts nollor med inversen av H (PSF_fourier)

img_restored = ifft2(img_blurred_ft .*PSF_zero); % Utan noise
subplot(1,2,1);
imshow(img_restored);

%img_blurred_noise_ft är noiset i fourier, som multipliceras med
%Nollmatrisen (där nollorna ersätts på alla ställen "som spelar roll")
img_restored_noise = ifft2(img_blurred_noise_ft .* PSF_zero);
subplot(1,2,2);
imshow(real(img_restored_noise), []);
imshow(img_restored_noise);

%% simpla sättet att köra Wiener, nästa steg är att ersätta K med S och ta avrage mellan övriga delar av bilden (se star treak exemplet från slides
%obs ej klar



Distorted1 = fft2(imrotate(img_0to1, 56, "crop"));
Distorted2 = fft2(imrotate(img_0to1, 120, "crop"));
Distorted3 = fft2(imrotate(img_0to1, 175, "crop"));
Distorted4 = fft2(flip(imrotate(img_0to1, 235, "crop")));
Distorted5 = fft2(imrotate(img_0to1, 310, "crop"));
Distorted6 = fft2(flip(img_0to1));
Distorted7 = fft2(imrotate(img_0to1, 55, "crop"));
Distorted8 = fft2(flip(imrotate(img_0to1, 138, "crop")));
Distorted9 = fft2(flip(imrotate(img_0to1, 235, "crop")));
Distorted10 = fft2(imrotate(img_0to1, 343, "crop"));


Distorted15 = fft2(flip(img_0to1,1));
Distorted16 = fft2(flip(img_0to1,2));
Distorted17 = fft2(flip(imrotate(img_0to1, 90, "crop")));
Distorted18 = fft2(flip(imrotate(img_0to1, 270, "crop")));
Distorted19 = fft2(flip(imrotate(img_0to1, 90, "crop")));
Distorted20 = fft2(flip(imrotate(img_0to1, 270, "crop")));


%    Distorted1 = fft2(imrotate(img_0to1, v, "crop"));
%end
Distorted_ave = (Distorted1 + Distorted2 + Distorted3 + Distorted4 + Distorted5 + Distorted6 + Distorted7 + Distorted8 + Distorted9 + Distorted10)./10;
Distorted_ave2= zeros(size(img_0to1));
for a = 36:36:360
    Distorted_ave2 = Distorted_ave2 + fft2(imrotate(img_0to1, a, "crop"));
end

Distorted_ave_tot = (Distorted_ave2 + Distorted15 + Distorted16 + Distorted17 + Distorted18 + Distorted19 + Distorted20) ./16;

Pure_Noise = img_blurred_noise - img_blurred;
%imshow(Pure_Noise, []);

Pure_Noise_ft = fft2(Pure_Noise);

S_nn = abs(Pure_Noise_ft).^2;
%S_nn = img_blurred_noise_ft; First try. Very wrong. S_nn är inte kvadrerad och är inte bara noise :)   
S_ff = abs(Distorted_ave).^2;
S_ff2 = abs(Distorted_ave_tot).^2;
K = S_nn ./S_ff;
K2 = S_nn ./S_ff2;
K3 = 0.01

G = fft2(img_blurred_noise);  
H = PSF_fourier;

F_hat = (conj(H) ./ (abs(H).^2 + K)) .* G; %se slide 57 för formel
F_hat2 = (conj(H) ./ (abs(H).^2 + K2)) .* G;
F_hat3 = (conj(H) ./ (abs(H).^2 + K3)) .* G;

img_wiener = ifft2(F_hat);
img_wiener2 = ifft2(F_hat2);
img_wiener3 = ifft2(F_hat3);

subplot(1,3,1)
imshow(img_wiener, []);
title('Non-periodic', 'FontSize', 24)
subplot(1,3,2)
imshow(img_wiener2, []);
title('Semi-periodic', 'FontSize', 24)
subplot(1,3,3)
imshow(img_wiener3, []);
title('K = 0.01', 'FontSize', 24)

%%

Test = ifft2(Distorted_ave);
Test2 = ifft2(Distorted_ave_tot);

subplot(1,2,1)
imshow(Test, []);
title('Non-periodic S-ff', 'FontSize', 24)
subplot(1,2,2)
imshow(Test2, []);
title('Periodic S-ff', 'FontSize', 24)