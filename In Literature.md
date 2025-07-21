# Application of the SNS Algorithm to Literature (Example Fragment)

"Буря мглою небо кроет, вихри снежные крутя"

## 1. Encoding Words as Numbers

A simple method can be used:

- Each letter is replaced by its ordinal number in the alphabet  
- Word → number = concatenation of these numbers  
- Sentence → long number formed by concatenating all words  

### Example:

| Word   | Letters | Ordinal Numbers | Number         |
|--------|---------|------------------|----------------|
| буря   | б у р я | 2 21 18 33       | 2211833        |
| мглою  | м г л о ю | 14 4 13 16 35 | 144131635      |
| небо   | н е б о | 15 6 2 16        | 156216         |
| кроет  | к р о е т | 12 18 16 6 20 | 121816620      |
| вихри  | в и х р и | 3 10 23 18 10 | 310231810      |
| снежные| с н е ж н ы е | 19 15 6 8 15 29 6 | 19156815296 |
| крутя  | к р у т я | 12 18 21 20 33 | 1218212033     |

## 2. Combining the Entire Sentence into One Number N

N = 2211833144131635156216121816620310231810191568152961218212033

This is the entire sentence represented as a single large natural number.

## 3. Applying SNS to N

Let:
- N = 2211833144131635156216121816620310231810191568152961218212033
- m = 2 (for symmetry)
- k = 7

**Splitting** → ["2211833144131635156216121816620", "310231810191568152961218212033"]

**Multiplying parts** → ["15482832008921446093512852716340", "2171622671340977070728527484231"]  
**Concatenating row-wise into a number** →  
PQ = 154828320089214460935128527163402171622671340977070728527484231

### Comparison:

- N * k = 15482832008921446093512852716342171622671340977070728527484231  
- PQ = 154828320089214460935128527163402171622671340977070728527484231  

✅ Perfect match!

## Interpretation:

Text as a number — this is possible.

Literary structure can be represented as a natural number.

This means that text can be mathematically processed, just like any other number.

## Practical Application:

This could become:

- A new method for copyright protection  
- A tool for text analysis  
- A model for digital humanities
