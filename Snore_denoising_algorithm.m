% Snore Audio Denoising and Extraction
% Based on methods from Sebastian et al. (Automated identification of the predominant site of 
% upper airway collapse in obstructive sleep apnoea patients using snore signal)
% Steps: Band-pass filtering -> Spectral Subtraction -> Wavelet Denoising

clear all; close all; clc;

%% 1. Load Audio Recording
[audioFile, path] = uigetfile({'*.wav;*.mp3;*.m4a', 'Audio Files'}, ...
    'Select Sleep Audio Recording');
if audioFile == 0
    error('No file selected');
end

[audio, fs] = audioread(fullfile(path, audioFile));

% Convert to mono if stereo
if size(audio, 2) > 1
    audio = mean(audio, 2);
end

% Normalize audio
audio = audio / max(abs(audio));

fprintf('Audio loaded: %s\n', audioFile);
fprintf('Duration: %.2f seconds\n', length(audio)/fs);
fprintf('Sample Rate: %d Hz\n', fs);

%% 2. STEP 1: Band-Pass Filtering
% Snore signals typically range from 20-2000 Hz
% Low freq: remove DC offset and very low freq noise
% High freq: remove high-frequency ambient noise

lowFreq = 20;    % Hz
highFreq = 2000; % Hz

% Design Butterworth band-pass filter
[b, a] = butter(4, [lowFreq highFreq]/(fs/2), 'bandpass');
audio_filtered = filtfilt(b, a, audio);

fprintf('\nStep 1: Band-pass filtering (%d-%d Hz) completed\n', lowFreq, highFreq);

%% 3. STEP 2: Spectral Subtraction
% Estimate noise from silent segments and subtract from signal

% Parameters for spectral subtraction
frameLength = round(0.025 * fs); % 25 ms frames
overlap = round(0.015 * fs);     % 15 ms overlap
nfft = 2^nextpow2(frameLength);
alpha = 2.0;  % Over-subtraction factor
beta = 0.01;  % Spectral floor

% Estimate noise spectrum from initial silent period (first 2 seconds)
noiseLength = min(2*fs, round(0.1*length(audio_filtered)));
noiseSegment = audio_filtered(1:noiseLength);

% Compute noise power spectrum
[S_noise, ~] = pwelch(noiseSegment, hamming(frameLength), overlap, nfft, fs);

% Perform spectral subtraction using STFT
hop = frameLength - overlap;
numFrames = floor((length(audio_filtered) - frameLength) / hop) + 1;
audio_ss = zeros(size(audio_filtered));

for i = 1:numFrames
    startIdx = (i-1) * hop + 1;
    endIdx = startIdx + frameLength - 1;
    
    if endIdx > length(audio_filtered)
        break;
    end
    
    frame = audio_filtered(startIdx:endIdx) .* hamming(frameLength);
    
    % FFT of current frame
    X = fft(frame, nfft);
    magnitude = abs(X);
    phase = angle(X);
    
    % Spectral subtraction
    magnitude_cleaned = sqrt(max(magnitude.^2 - alpha * S_noise' * nfft / frameLength, ...
                                 beta * magnitude.^2));
    
    % Reconstruct signal
    X_cleaned = magnitude_cleaned .* exp(1j * phase);
    frame_cleaned = real(ifft(X_cleaned, nfft));
    frame_cleaned = frame_cleaned(1:frameLength);
    
    % Overlap-add
    audio_ss(startIdx:endIdx) = audio_ss(startIdx:endIdx) + ...
                                 frame_cleaned .* hamming(frameLength);
end

% Normalize
audio_ss = audio_ss / max(abs(audio_ss));

fprintf('Step 2: Spectral subtraction completed\n');

%% 4. STEP 3: Wavelet Denoising
% Use wavelet transform for additional denoising
% Symlet wavelets work well for biomedical signals

waveletName = 'sym4';  % Symlet wavelet
level = 5;             % Decomposition level

% Perform wavelet decomposition
[C, L] = wavedec(audio_ss, level, waveletName);

% Estimate noise standard deviation using MAD (Median Absolute Deviation)
% Focus on detail coefficients at finest scale
detail1 = detcoef(C, L, 1);
sigma = median(abs(detail1)) / 0.6745;

% Universal threshold
N = length(audio_ss);
threshold = sigma * sqrt(2 * log(N));

% Apply soft thresholding
C_thresholded = wthresh(C, 's', threshold);

% Reconstruct signal
audio_denoised = waverec(C_thresholded, L, waveletName);

% Ensure same length as original
audio_denoised = audio_denoised(1:length(audio));

% Normalize final output
audio_denoised = audio_denoised / max(abs(audio_denoised));

fprintf('Step 3: Wavelet denoising completed\n');

%% 5. Snore Detection and Extraction
% Detect high-energy segments (potential snores)

% Energy envelope
windowSize = round(0.1 * fs); % 100ms window
energyEnvelope = movmean(audio_denoised.^2, windowSize);

% Adaptive threshold
energyThreshold = mean(energyEnvelope) + 2*std(energyEnvelope);

% Find snore candidates
snoreMask = energyEnvelope > energyThreshold;

% Remove short segments (< 200ms)
minSnoreDuration = round(0.2 * fs);
snoreMask = bwareaopen(snoreMask, minSnoreDuration);

% Extract snore segments
snoreSegments = audio_denoised .* snoreMask;

fprintf('\nSnore extraction completed\n');

%% 6. Visualization
t = (0:length(audio)-1) / fs;

figure('Position', [100 100 1200 800]);

% Original signal
subplot(5,1,1);
plot(t, audio, 'b');
title('Original Audio Recording');
ylabel('Amplitude');
xlim([0 max(t)]);
grid on;

% After band-pass filtering
subplot(5,1,2);
plot(t, audio_filtered, 'g');
title(sprintf('After Band-Pass Filter (%d-%d Hz)', lowFreq, highFreq));
ylabel('Amplitude');
xlim([0 max(t)]);
grid on;

% After spectral subtraction
subplot(5,1,3);
plot(t, audio_ss, 'm');
title('After Spectral Subtraction');
ylabel('Amplitude');
xlim([0 max(t)]);
grid on;

% After wavelet denoising
subplot(5,1,4);
plot(t, audio_denoised, 'r');
title('After Wavelet Denoising (Final Denoised Signal)');
ylabel('Amplitude');
xlim([0 max(t)]);
grid on;

% Extracted snores
subplot(5,1,5);
plot(t, snoreSegments, 'k', 'LineWidth', 1.5);
title('Extracted Snore Segments');
xlabel('Time (s)');
ylabel('Amplitude');
xlim([0 max(t)]);
grid on;

%% 7. Spectrograms Comparison
figure('Position', [100 100 1200 600]);

subplot(2,2,1);
spectrogram(audio, hamming(256), 128, 512, fs, 'yaxis');
title('Original Audio - Spectrogram');
colorbar;

subplot(2,2,2);
spectrogram(audio_filtered, hamming(256), 128, 512, fs, 'yaxis');
title('After Band-Pass Filter');
colorbar;

subplot(2,2,3);
spectrogram(audio_denoised, hamming(256), 128, 512, fs, 'yaxis');
title('Final Denoised Audio');
colorbar;

subplot(2,2,4);
spectrogram(snoreSegments, hamming(256), 128, 512, fs, 'yaxis');
title('Extracted Snores');
colorbar;

%% 8. Save Results
[~, fileName, ~] = fileparts(audioFile);

% Save denoised audio
outputFile = fullfile(path, [fileName, '_denoised.wav']);
audiowrite(outputFile, audio_denoised, fs);
fprintf('\nDenoised audio saved: %s\n', outputFile);

% Save extracted snores
snoreFile = fullfile(path, [fileName, '_snores.wav']);
audiowrite(snoreFile, snoreSegments, fs);
fprintf('Extracted snores saved: %s\n', snoreFile);

%% 9. Statistics
numSnoreEvents = sum(diff([0; snoreMask; 0]) == 1);
fprintf('\n--- Statistics ---\n');
fprintf('Number of snore events detected: %d\n', numSnoreEvents);
fprintf('Total snoring time: %.2f seconds (%.1f%% of recording)\n', ...
    sum(snoreMask)/fs, 100*sum(snoreMask)/length(audio));

% SNR improvement estimation
noise_orig = audio - audio_denoised;
snr_improvement = 10*log10(var(audio_denoised)/var(noise_orig));
fprintf('Estimated SNR improvement: %.2f dB\n', snr_improvement);

fprintf('\nProcessing complete!\n');