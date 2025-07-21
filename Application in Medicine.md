# Analysis of Patient IDs, Drug Doses, and Biological Markers

## Example:

- N = 135  
- m = 2  
- k = 7  

**Splitting** → ["13", "5"]  

**Multiplying parts** → ["91", "35"]  
**Concatenating row-wise into a number** → PQ = 9135  

### Comparison:

- PQ = 9135  
- N * k = 945  

✅ Match at the beginning (`9`) and the end (`5`)

## Interpretation:

If a patient ID or drug dose starts and ends with the same digits after transformation, it preserves key identifiers.

This can be used as a verification tool in electronic medical records.
