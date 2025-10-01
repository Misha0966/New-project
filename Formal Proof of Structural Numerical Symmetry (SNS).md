# Formal Proof of SNS (Structural Numerical Symmetry)

## The SNS Phenomenon

For any natural number **N ≥ 1**, split into **m ≥ 2** natural parts, and multiplied by a natural number **k**:

- Either **PQ = NK** (exact match)
- Or the beginning and end match
- Or only the end matches

But in no case is there a complete mismatch.

## Empirical Finding

Everywhere and always, for any type of match, **the end matches**.

This is the key invariant of the phenomenon.

Even in the range from 30 to 40 million, only exact matches or matches of both beginning and end occur, but **the end always matches**.

## Important Observation

If the last digit always matches, then checking the end is a **necessary condition** for all other types of matches.

## Last Digit Invariance Theorem

**Statement**: For any natural number **N ≥ 1**, split into **m ≥ 2** natural parts, and multiplied by a natural number **k**, the result of concatenating the multiplied parts as string **PQ** always has the **same last digit** as the classical product **NK = N * k**.

That is:

last_digit(PQ) = last_digit(NK)


### Proof

Let **N = A₁A₂...Aₘ** where N is a natural number represented as a string, and A₁, A₂, ..., Aₘ are its parts after splitting.

When multiplying part by part, we get:

PQ = string(A₁ * k) + string(A₂ * k) + ... + string(Aₘ * k)


where **PQ** is the result of concatenating the multiplied parts of the natural number.

Let **B = Aₘ** where B is the last part of the original number.

After multiplication:

Bk = B * k

Since when concatenating parts, the last digit of PQ is determined precisely by Bk:

last_digit(PQ) = (B * k) mod 10

Now consider classical multiplication:

NK = N * k = (a * 10 + B) * k = a * 10 * k + B * k


**a * 10 * k** ends with zero ⇒ `last_digit(NK) = (B * k) mod 10 = last_digit(PQ)`

**Therefore**:

For any natural N and any natural number k:
The last digit of PQ always equals the last digit of N * K

## Returning to the Impossibility of Beginning-Only Matches

Throughout all testing history (between PQ and N * k):

- There were many cases of exact matches
- There were even more cases of beginning and end matches
- There were many cases of end-only matches
- But **not a single case** of beginning-only match

This indicates that the **end is more stable and robust** than the beginning.

Thus, we can emphasize:

**The end of the number is invariant** with respect to the SNS (Structural Numerical Symmetry) phenomenon.

The beginning may differ between PQ and N * k, but the end **cannot**.

## Proving the Structural Numerical Symmetry Phenomenon via the Last Digit Theorem

We can make the following assertion:

Since the end of PQ always matches the end of NK, then:

**Beginning-only match is impossible** because it would violate the end invariance.

*All three types of matches:*
- Exact match
- Beginning and end match
- End-only match

Derive from one fundamental fact: **the end of the number is preserved** after transformation.

### Mathematically

If:

PQ = string(A₁ * k) + string(A₂ * k) + ... + string(Aₘ * k)

where **PQ** is the result of concatenating the multiplied parts of the natural number

NK = N * k

And:

last_digit(PQ) = last_digit(N * K)

Then:

- Beginning-only match is impossible
- There will always be either an exact match, or an end match, or both

**Q.E.D.**
