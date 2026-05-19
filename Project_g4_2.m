img_raw = 'Xray.png';

%% Creates the images
img_pixels = imread(img_raw); %Reads the raw picture
img_0to1 = im2double(img_pixels); %Rescales pixel values to stay between 0 and 1

[M, N] = size(img_0to1); %Reads the size of the image
max(max(img_0to1)); %Checks the value of the highest pixel in the image

%% First attempt at blurring, without using fourier transform
%PSF_length = 60;
%PSF_angle = 0;
%PSF_true = fspecial("motion",PSF_length,PSF_angle);
%
%img_distort = imfilter(img_0to1, PSF_true, "circular", "conv"); 
%
%subplot(1,2,1); 
%imshow(img_0to1);
%
%subplot(1,2,2); 
%imshow(img_distort);

%% Blurring using fourier transform 
PSF_length = 60;
PSF_angle = 0;
PSF_true = fspecial("motion",PSF_length,PSF_angle); %Creates a PSF, with a top hat function

img_0to1_ft = fft2(img_0to1); % f -> F, turns original image into fourier
PSF_fourier = psf2otf(PSF_true, [M,N]); % h -> H, turns psf image into fourier
img_blurred_ft = img_0to1_ft .* PSF_fourier ; % This is when the blurred is created (G = F * H)
img_blurred = ifft2(img_blurred_ft); % G -> g


subplot(2,3,1);
imshow(img_0to1); %originalbild f
title('f', 'FontSize', 24)

subplot(2,3,4);
imshow(log(abs(fftshift(img_0to1_ft))),[]); %originalbild i ft, F
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
img_blurred_noise = imnoise(img_blurred, "gaussian"); % This adds noise 
subplot(1,2,1);
imshow(img_blurred_noise);
title('Blurred image with noise', 'FontSize', 24);

%vår kod
img_blurred_noise_ft = fft2(img_blurred_noise); % Same thing in fourier
subplot(1,2,2);
imshow(img_blurred_noise_ft);
title('Blurred image with noise in fourier domain', 'FontSize', 24)

%% Pseudoinverse filter, with inverse example 


epsilon = 0.1; % Example value for epsilon

PSF_epsilon = zeros(size(PSF_fourier)); % Creates a Matrix the size of the PSF, filled with zeros 
Boolean_matrix = abs(PSF_fourier) >= epsilon; % Creates a boolean matrix, assigning all values bigger then epsilon with true

% The zeros in the zero matrix are replace in all positions where the
% matrix is "True". Those zeros are replaced with the value 1/H.
% PSF_espilon is now the same thing as PSF_fourier, but with every value
% less than epsilon being 0
PSF_epsilon(Boolean_matrix) = 1 ./PSF_fourier(Boolean_matrix);

% This does two things: First (G * (1/H)) is calculated, secondly, the
% inverse fourier transform is applied to go back into the picture domain
img_restored = ifft2(img_blurred_ft .*PSF_epsilon); 
subplot(1,3,1);
imshow(img_restored, []);
title('No noise', 'FontSize', 24)

%This does the same thing the comment above describes, but this time G also
%contains noise
img_restored_noise = ifft2(img_blurred_noise_ft .* PSF_epsilon);
subplot(1,3,2);
imshow(img_restored_noise, []);
title('Pseudoinverse with noise', 'FontSize', 24)

%This is only meant to display what is would look like with an inverse
%filter instead of a pseudo inverse filter, therefore epsilon will be set
%to 0.0001, just to avoid NaNinf values in the program. Everything else is
%the same as the code above
example_epsilon = 0.0001
PSF_example = zeros(size(PSF_fourier));
Example_matrix = abs(PSF_fourier) >= example_epsilon;
PSF_example(Example_matrix) = 1 ./PSF_fourier(Example_matrix);
img_restored_inverse_noise = ifft2(img_blurred_noise_ft .* PSF_example);
subplot(1,3,3);
imshow(img_restored_inverse_noise, []);
title('Inverse with noise', 'FontSize', 24)

%% Wiener filter

% 10 different distortions done by rotating and flipping in a non-symmetric
% way
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

% Takes the average of the 10 altered images above and makes a non-symetric
% distorted average
Distorted_ave = (Distorted1 + Distorted2 + Distorted3 + Distorted4 + Distorted5 + Distorted6 + Distorted7 + Distorted8 + Distorted9 + Distorted10)./10;

%This is a foor loop that returns Distort_loop: This is a picture, that is
%made up by 10 evenly rotated images over 360 degrees stacked on top of
%each other.
Distorted_loop= zeros(size(img_0to1));
for a = 36:36:360
    Distorted_loop = Distorted_loop + fft2(imrotate(img_0to1, a, "crop"));
end

% Here we have 6 more distorted images to make sure we have some fliped
% images added onto the foor loop. The _2 in the name is to make sure we
% don't confuse it with Distorted1 from earlier
Distorted1_2 = fft2(flip(img_0to1,1));
Distorted2_2= fft2(flip(img_0to1,2));
Distorted3_2 = fft2(flip(imrotate(img_0to1, 90, "crop")));
Distorted4_2 = fft2(flip(imrotate(img_0to1, 270, "crop")));
Distorted5_2 = fft2(flip(imrotate(img_0to1, 90, "crop")));
Distorted6_2 = fft2(flip(imrotate(img_0to1, 270, "crop")));

% The second distorted average we've made, that is symetric, 
% (referd to as periodic in the report),
% due to the for loop. We have 16 total pictures, since the loop contains 10
Distorted_ave_sym = (Distorted_loop + Distorted1_2 + Distorted2_2 + Distorted3_2 + Distorted4_2 + Distorted5_2 + Distorted6_2) ./16;

% This extracts the noise from the blurred picture
Pure_Noise = img_blurred_noise - img_blurred;

% Fourier transform on the Nosise
Pure_Noise_ft = fft2(Pure_Noise);

% S_nn is noise squared
S_nn = abs(Pure_Noise_ft).^2;

% S_ff for the two different versions 
S_ff = abs(Distorted_ave).^2;
S_ff_sym = abs(Distorted_ave_sym).^2;

% Here we calculate the K value for the different versions, third one is a
% Set value for comparison
K = S_nn ./S_ff;
K_sym = S_nn ./S_ff_sym;
K_set_value = 0.01

% This just renames our variables for clarity
G = img_blurred_noise_ft;  
H = PSF_fourier;

% Calculations
F_hat = (conj(H) ./ (abs(H).^2 + K)) .* G; 
F_hat_sym = (conj(H) ./ (abs(H).^2 + K_sym)) .* G;
F_hat_set_value = (conj(H) ./ (abs(H).^2 + K_set_value)) .* G;

% This creates the images
img_wiener = ifft2(F_hat);
img_wiener_sym = ifft2(F_hat_sym);
img_wiener_set_value = ifft2(F_hat_set_value);

% Display the images
subplot(1,3,1)
imshow(img_wiener, []);
title('Non-periodic', 'FontSize', 24)
subplot(1,3,2)
imshow(img_wiener_sym, []);
title('Semi-periodic', 'FontSize', 24)
subplot(1,3,3)
imshow(img_wiener_set_value, []);
title('K = 0.01', 'FontSize', 24)
