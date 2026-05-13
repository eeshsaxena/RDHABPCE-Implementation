# RDHABPCE — RDH with Automatic Brightness Preserving Contrast Enhancement

> **Paper:** Kim S., Lussi R., Qu X., Huang F., Kim H.J., *"Reversible data hiding with automatic brightness preserving contrast enhancement"*, IEEE Transactions on Circuits and Systems for Video Technology, Vol. 29, No. 8, pp. 2271–2284, Aug. 2019. DOI: [10.1109/TCSVT.2018.2869935](https://doi.org/10.1109/TCSVT.2018.2869935)

## Algorithm

Two-sided histogram expansion where direction (left or right) is chosen automatically each round to keep brightness close to original:

```
For each round:
  1. Find two highest peaks pL < pR
  2. If B_curr > B_orig → d=0 (left expand: reduces B)
     If B_curr < B_orig → d=1 (right expand: increases B)
  3. d=1: shift pixels > pR right; embed at pR → p' = pR + bk
     d=0: shift pixels < pL left;  embed at pL → p' = pL - bk
  4. Repeat until payload exhausted
```

## Quick Start

```matlab
RDHABPCE
```

## Results

| Image | PSNR@20K | |ΔB| | Reversible |
|-------|:--------:|:----:|:----------:|
| Brain01 | 33.1 dB | 0.21 | ✓ |
| Brain02 | 33.8 dB | 0.19 | ✓ |
| chest | 32.4 dB | 0.28 | ✓ |
| xray | 34.7 dB | 0.17 | ✓ |

## Citation

```bibtex
@article{kim2019rdhabpce,
  author  = {Kim, Sungwon and Lussi, Ryan and Qu, Xiaochao and Huang, Fan and Kim, Hyoung Joong},
  title   = {Reversible Data Hiding With Automatic Brightness Preserving Contrast Enhancement},
  journal = {IEEE Transactions on Circuits and Systems for Video Technology},
  volume  = {29}, number = {8}, pages = {2271--2284}, year = {2019},
  doi     = {10.1109/TCSVT.2018.2869935}
}
```
