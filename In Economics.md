# Analysis of Transactions, Financial Data, IDs and Amounts

## Example:

- N = 12345678901234567890  # long ID or amount  
- m = 2  
- k = 3  

**Splitting** → ["12345678901", "234567890"]  

**Multiplying parts** → ["37037036703", "703703670"]  
**Concatenating row-wise into a number** → PQ = 37037036703703703670  

### Comparison:

- PQ = 37037036703703703670  
- N * k = 37037036703703703670  
✅ Perfect match!

## Interpretation:

Such numbers can be transaction identifiers.  
Matching the beginning and end acts as a fingerprint of integrity.  
This can help detect fraud or errors in financial records.
