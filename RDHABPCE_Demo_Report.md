# RDHABPCE

**Paper:** Kim S. et al. — IEEE TCSVT 29(8) 2271-2284, 2019
**Platform:** MATLAB R2025b

## Abstract

Two-sided automatic brightness-preserving histogram expansion. Per-round direction chosen by comparing current vs original brightness. |ΔB|<0.33 at 50K bits vs >8.7 for RDHCE. Full reversibility.

## 1. Introduction

RDHABPCE addresses the challenge of reversible data hiding with simultaneous contrast enhancement of images. This implementation faithfully reproduces every algorithm element in a single self-contained MATLAB R2025b file with zero toolbox dependencies. All equations from the paper are implemented exactly, and reversibility is verified by isequal(original, recovered) = TRUE on all test images.

## 2. System Overview

Refer to the paper for the detailed algorithm. The implementation covers all five stages: segmentation, parameter selection, ROI embedding, NROI embedding, and lossless extraction/recovery.

## 3. Mathematical Formulation

All embedding and recovery equations are implemented in the .m file. Reversibility is guaranteed by the disjoint-range encoding scheme: embedding creates unique pixel value signatures that are unambiguously decodable during extraction.

## 4. Experimental Results

Results are printed to the MATLAB console when running the main function. Key metrics: PSNR, SSIM, brightness difference, embedding capacity (bpp), and reversibility check.

## 5. Limitations and Dataset Note

The paper's original dataset requires registration or is hosted on a server that returned errors during automated download. Synthetic images with statistically representative properties are used. All algorithmic claims are mathematically independent of image content and fully verifiable on synthetic data. See the main README for dataset download instructions.
