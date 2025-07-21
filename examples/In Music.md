# Analysis of Duration, Rhythm, and MIDI Notes

## Example:

- N = 6062646567697172  # MIDI notes C-D-E-F-G-A-B-C  
- m = 2  
- k = 2  

**Splitting** → ["606264656", "7697172"]  

**Multiplying parts** → ["1212529312", "15394344"]  
**Concatenating row-wise into a number** → PQ = 121252931215394344  

### Comparison:

- PQ = 121252931215394344  
- N * k = 12125293135394344  

✅ Match at the beginning (`1`) and the end (`3`)

## Interpretation:

Preservation of a melodic "fingerprint" after scaling.

This can be used as a tool for generating music from numbers.
