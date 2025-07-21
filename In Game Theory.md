# SNS Algorithm in Gaming

The SNS algorithm can be used as a tool for analyzing:

- Game IDs  
- Strategies  
- Winning probabilities  
- Patterns in player behavior  

## Example:

### Game ID:

- N = 13579  # player or game unique ID  
- m = 2  
- k = 7  

**Splitting** → ["135", "79"]  

**Multiplying parts** → ["945", "553"]  
**Concatenating row-wise into a number** → PQ = "945553"  

### Comparison:

- PQ = 945553  
- N * k = 94953  

✅ Match at the beginning (`9`) and the end (`3`)  

## Interpretation:

The player's ID retains key markers.  
This may indicate repeated behavior.  
Such an ID can be used as a player fingerprint.  
```
