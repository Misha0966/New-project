# Application of the SNS Algorithm in Number Theory

## A New Metric for Numbers

Numbers can be classified based on the type of match they produce:

**Examples:**

- **Class F**: Numbers with a full match  
- **Class B**: Numbers with a match at the beginning and end  
- **Class E**: Numbers with a match only at the end  

This classification could open a new direction in number theory research.

---

## Preservation of Invariants Under Transformation

- Even when the internal structure of a number changes:  
- The **beginning** and **end** remain invariant

Such numbers can be called: **Structurally Invariant Numbers**

---

### Match at the Beginning and End

| N      | m | k | PQ         | N * k    | Result                |
|--------|---|---|------------|----------|-----------------------|
| 899766 | 2 | 4 | 35963064   | 3599064  | Match at start and end |
| 1234   | 2 | 4 | 48136      | 4936     | Match at start and end |
| 135    | 2 | 7 | 9135       | 945      | Match at start and end |
| 12345  | 3 | 3 | 3610215    | 37035    | Match at start and end |

---

### Match Only at the End

| N  | m | k | PQ   | N * k | Result            |
|----|---|---|------|-------|-------------------|
| 13 | 2 | 7 | 721  | 91    | Match only at end |
| 17 | 2 | 4 | 428  | 68    | Match only at end |
| 15 | 2 | 7 | 735  | 105   | Match only at end |

---

### Full Match

| N    | m | k | PQ     | N * k | Result           |
|------|---|---|--------|-------|------------------|
| 101  | 2 | 7 | 707    | 707   | Full match       |
| 1001 | 2 | 7 | 7007   | 7007  | Full match       |
| 7007 | 2 | 1 | 7007   | 7007  | Full match       |

---

## Interpretation

- The **end** of a number — its least significant digits —  
  often remains stable under transformation  
- This resembles the last digits of prime numbers, which often repeat  
- It suggests a form of numerical robustness or conservation

---

## Formal Model in Number Theory

### 1. Full Match:

**PQ = N × k ⇔ ∀i, length(Aᵢ × k) = length(Aᵢ)**  
This occurs when multiplication doesn't increase the number of digits in any part.

### 2. Match at Start and End:

- Most commonly observed  
- Indicates scale and invariant preservation  

**Example:**

- N = 1234  
- m = 2  
- k = 4  

**Splitting** → ["12", "34"]  
**Multiplying parts** → ["48", "136"]  
**Concatenating** → PQ = 48136  
N × k = 4936  
✅ Match at the beginning (`4`) and end (`6`)

### 3. Match Only at the End:

- The least significant part is preserved, but not the most  
- May reflect stability of the last digit under multiplication  

**Example:**

- N = 13  
- m = 2  
- k = 7  

**Splitting** → ["1", "3"]  
**Multiplying parts** → ["7", "21"]  
**Concatenating** → PQ = 721  
N × k = 91  
✅ Match only at the end

---

## Observed Pattern

- If the **beginning matches**, the **end also matches**  
- But the reverse is **not always true**

This property has not been disproven so far.

---

## Analysis of Prime Numbers

| N   | m | k | PQ   | N * k | Result              |
|-----|---|---|------|-------|---------------------|
| 101 | 2 | 7 | 707  | 707   | Full match          |
| 11  | 2 | 9 | 99   | 99    | Full match          |
| 13  | 2 | 2 | 26   | 26    | Full match          |
| 17  | 2 | 4 | 428  | 68    | Match only at end   |
| 19  | 2 | 2 | 218  | 38    | Match only at end   |
| 23  | 2 | 4 | 812  | 92    | Match only at end   |

This suggests that **prime numbers also have a structural fingerprint** that can be analyzed using SNS.



## Statistical Overview

**Range:** N ∈ [10..10⁷], m = 2, k = 7

- **Full matches:** 1,430,749  
- **Match at start and end:** 8,560,838  
- **Match only at end:** 8,404  
- **No match:** 0  
