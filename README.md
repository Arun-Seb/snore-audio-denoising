# Snore Audio Denoising and Extraction

MATLAB implementation for denoising sleep audio recordings and extracting snore signals using advanced signal processing techniques.

## Overview

This tool processes sleep audio recordings to remove noise and isolate snore events using a three-stage denoising pipeline based on methods described in:

**Reference Paper:**
> Sebastian, A., Cistulli, P. A., Cohen, G., & de Chazal, P. "Automated identification of the predominant site of upper airway collapse in obstructive sleep apnoea patients using snore signal"

## Features

- **Multi-stage Denoising Pipeline**
  - Band-pass filtering
  - Spectral subtraction
  - Wavelet denoising
  
- **Automated Snore Detection**
  - Energy-based detection
  - Adaptive thresholding
  - Duration filtering

- **Comprehensive Visualization**
  - Time-domain waveforms at each stage
  - Spectrograms for frequency analysis
  - Before/after comparisons

- **Audio Output**
  - Denoised full recording
  - Extracted snore segments only

## Requirements

### MATLAB Version
- MATLAB R2016b or later recommended

### Required Toolboxes
- Signal Processing Toolbox
- Wavelet Toolbox

### Supported Audio Formats
- WAV (recommended)
- MP3
- M4A

## Installation

1. Download or clone the repository
2. Open MATLAB
3. Navigate to the script directory
4. Ensure required toolboxes are installed

```matlab
% Check if required toolboxes are installed
ver('signal')
ver('wavelet')
```

## Usage

### Basic Usage

1. Run the script:
```matlab
Snore_denoising_algorithm
```

2. Select your sleep audio recording file when prompted

3. Wait for processing to complete (progress shown in command window)

4. Review the generated figures and saved output files

### Expected Processing Time

- **Short recordings (<5 min):** ~10-30 seconds
- **Medium recordings (5-30 min):** ~30-120 seconds  
- **Long recordings (>30 min):** ~2-10 minutes

*Processing time depends on your computer's performance*

## Processing Pipeline

### Stage 1: Band-Pass Filtering
- **Frequency Range:** 20-2000 Hz
- **Purpose:** Remove DC offset, very low-frequency noise, and high-frequency ambient noise
- **Filter Type:** 4th-order Butterworth
- **Rationale:** Snore signals primarily contain energy in this frequency range

### Stage 2: Spectral Subtraction
- **Method:** STFT-based noise estimation and subtraction
- **Frame Length:** 25 ms
- **Overlap:** 15 ms
- **Over-subtraction Factor (α):** 2.0
- **Spectral Floor (β):** 0.01
- **Purpose:** Remove stationary background noise

### Stage 3: Wavelet Denoising
- **Wavelet:** Symlet-4 (sym4)
- **Decomposition Level:** 5
- **Thresholding:** Soft thresholding with universal threshold
- **Noise Estimation:** Median Absolute Deviation (MAD)
- **Purpose:** Remove residual non-stationary noise

### Snore Detection
- **Window Size:** 100 ms energy envelope
- **Detection:** Adaptive threshold (mean + 2×std)
- **Minimum Duration:** 200 ms
- **Purpose:** Identify and isolate snore events

## Output Files

The script generates the following output files in the same directory as the input:

1. **`[filename]_denoised.wav`**
   - Complete denoised audio recording
   - Same duration as original
   - All noise reduction stages applied

2. **`[filename]_snores.wav`**
   - Extracted snore segments only
   - Silent periods between snores are zeroed
   - Same duration as original

## Parameters Customization

You can adjust the following parameters in the code:

### Band-Pass Filter
```matlab
lowFreq = 20;    % Lower cutoff frequency (Hz)
highFreq = 2000; % Upper cutoff frequency (Hz)
```

### Spectral Subtraction
```matlab
alpha = 2.0;  % Over-subtraction factor (1.0-3.0)
beta = 0.01;  % Spectral floor (0.001-0.1)
```

### Wavelet Denoising
```matlab
waveletName = 'sym4';  % Wavelet type ('sym4', 'db4', 'coif3')
level = 5;             % Decomposition level (3-8)
```

### Snore Detection
```matlab
windowSize = round(0.1 * fs);      % Energy window (seconds)
minSnoreDuration = round(0.2 * fs); % Minimum snore duration (seconds)
```

## Visualization

The script generates two figure windows:

### Figure 1: Time-Domain Analysis
Shows 5 subplots:
1. Original audio recording
2. After band-pass filtering
3. After spectral subtraction
4. After wavelet denoising (final)
5. Extracted snore segments

### Figure 2: Frequency-Domain Analysis
Shows 4 spectrograms:
1. Original audio
2. After band-pass filter
3. Final denoised audio
4. Extracted snores only

## Performance Metrics

The script calculates and displays:
- **Number of snore events detected**
- **Total snoring time** (seconds and percentage)
- **SNR improvement** (dB)

## Troubleshooting

### Issue: "No file selected" error
**Solution:** Run the script again and select a valid audio file

### Issue: Poor snore detection
**Solutions:**
- Adjust the energy threshold multiplier (try 1.5 or 3.0 instead of 2.0)
- Modify minimum snore duration
- Check if audio quality is sufficient

### Issue: Over-denoising (loss of snore detail)
**Solutions:**
- Reduce spectral subtraction alpha parameter (try 1.5)
- Increase spectral floor beta (try 0.02)
- Reduce wavelet decomposition level (try 3-4)

### Issue: Under-denoising (too much noise remains)
**Solutions:**
- Increase alpha parameter (try 2.5-3.0)
- Decrease beta parameter (try 0.005)
- Use different wavelet ('db8' or 'coif5')

## Technical Notes

### Noise Estimation
The script estimates background noise from the first 2 seconds of the recording. Ensure this portion contains minimal snoring for best results.

### Memory Requirements
For long recordings (>1 hour), ensure sufficient RAM is available. The script processes the entire file in memory.

### Sampling Rate
The script automatically handles different sampling rates. Original sampling rate is preserved in output files.

## Citation

If you use this code in your research, please cite:

```
Sebastian, A., Cistulli, P. A., Cohen, G., & de Chazal, P. 
"Automated identification of the predominant site of upper airway 
collapse in obstructive sleep apnoea patients using snore signal"
```

## License

This code is provided for research and educational purposes.

## Contributing

Suggestions and improvements are welcome. Please test thoroughly with your specific audio recordings.

## Contact & Support

For issues or questions:
- Check the troubleshooting section above
- Review parameter customization options
- Verify your audio file format and quality

## Version History

**v1.0** - Initial release
- Three-stage denoising pipeline
- Automated snore detection
- Comprehensive visualization
- Audio output generation

## Acknowledgments

Based on methodologies described in sleep apnea research literature, particularly the work of Sebastian et al. on snore signal analysis for OSA diagnosis.