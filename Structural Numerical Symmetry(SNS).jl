using Printf # Imports the module for formatted output
using CSV # Imports the library for working with CSV files
using DataFrames # Imports the DataFrame type for tabular storage of results
using Base.Threads # Enables multithreading support
using ProgressMeter # Allows displaying progress during loop execution

# Splits the number N into m parts of approximately equal length
function split_number_str(N::Integer, m::Integer)
s = string(N) # Converts the number N to a string

if N < 10 # If the number is less than 10, pad with leading zeros to length #m
s = lpad(s, m, '0') # Adds leading zeros to reach length m
end

len = length(s) # Determines the total string length
base_len = div(len, m)  # Base length of each part
remainder = len % m # Remainder — number of parts that will be one #character longer

parts = String[] # Array to store the parts of the number
idx = 1 # Current position in the string

for i in 1:m  # Loop over the number of parts
current_len = base_len + (i <= remainder ? 1 : 0)  # Compute current part #length
push!(parts, s[idx:idx+current_len-1])  # Add the part to the array
idx += current_len  # Move the index to the start of the next part
end

return parts  # Returns the array of number parts
end

# Multiplies a part of the number while preserving its original length
function multiply_preserve_length(part::String, k::Integer)
num = parse(BigInt, part) * k  # Converts the part to a number and #multiplies by k
result = string(num) # Converts back to a string
return lpad(result, length(part), '0')  # Preserves original length by #padding with leading zeros
end

# Removes leading zeros from a string
function remove_leading_zeros(s::String)
if all(c -> c == '0', s)  # If the entire string consists of zeros
return "0" # Return "0"
else
idx = findfirst(c -> c != '0', s) # Find the first non-zero character
return s[idx:end] # Return the string without leading zeros
end
end

# Compares PQ and NK by prefix and suffix
function compare_pq_nk(pq::String, nk::String)
if pq == nk  # Full match
return "✅ Full match"
end

min_len = min(length(pq), length(nk))  # Minimum string length
prefix_match = 0  # Counter for matching prefix characters
for i in 1:min_len  # Compare characters from the beginning
pq[i] == nk[i] ? prefix_match += 1 : break  # Increment counter or exit #loop
end

suffix_match = 0  # Counter for matching suffix characters
for i in 1:min_len  # Compare characters from the end
pq[end - i + 1] == nk[end - i + 1] ? suffix_match += 1 : break  # Increment #or exit
end

if prefix_match > 0 && suffix_match > 0  # Both prefix and suffix match
return "🔄 Prefix and suffix match"
elseif prefix_match > 0  # Only prefix matches
return "🔄 Prefix matches only"
elseif suffix_match > 0  # Only suffix matches
return "🔄 Suffix matches only"
else  # No matches
return "❌ No match"
end
end

# Tests the algorithm for a single number
function check_algoritm(N::Integer, m::Integer, k::Integer)
N_str = string(N) # Convert N to string
nk_str = string(N * k) # Multiply N by k and convert to string

parts_str = split_number_str(N, m)  # Split N into m parts
multiplied_parts_str = [multiply_preserve_length(p, k) for p in parts_str] # Multiply each part
pq_str = join(multiplied_parts_str)  # Concatenate the multiplied parts

# Remove leading zeros before comparison
pq_clean = remove_leading_zeros(pq_str)  # Clean PQ
nk_clean = remove_leading_zeros(nk_str)  # Clean NK

result = compare_pq_nk(pq_clean, nk_clean)  # Compare PQ and NK

return (  # Return a NamedTuple with hypothesis test results
N = N,  # Original number N
m = m,  # Number of parts N was split into
k = k,  # Multiplier applied to each part
parts = string(parts_str),  # String representation of the split
multiplied_parts = string(multiplied_parts_str),  # String representation #of multiplied parts
PQ = pq_clean,  # Concatenated result of multiplied parts (leading zeros #removed)
NK = nk_clean,  # Result of N * k (leading zeros removed)
result = result  # Comparison result (full match, prefix/suffix, etc.)
)  # Final NamedTuple contains all data for this single test case
end

# Parallel testing over a range of numbers
function run_tests_parallel(start_N::Integer, stop_N::Integer, m::Integer, k::Integer)
results21_df = DataFrame(  # Create a DataFrame to store results
N = Int[], # Column "N" — integers
m = Int[], # Column "m" — integers
k = Int[], # Column "k" — integers
parts = String[], # Column "parts" — string representations of splits
multiplied_parts = String[], # Column "multiplied_parts" — multiplied parts #as strings
PQ = String[], # Column "PQ" — result after multiplying parts
NK = String[], # Column "NK" — result of N * k
result = String[] # Column "result" — match assessment
)

count_full = Atomic{Int}(0) # Counter for full matches
count_partial_start = Atomic{Int}(0) # Prefix only
count_partial_end = Atomic{Int}(0) # Suffix only
count_partial_both = Atomic{Int}(0) # Both prefix and suffix
count_none = Atomic{Int}(0) # No matches

@showprogress "🚀 Testing N ∈ [$start_N, $stop_N], m = $m, k = $k" for N in start_N:stop_N  # Show progress
res = check_algoritm(N, m, k) # Run test for current N

Threads.atomic_add!(count_full, res.result == "✅ Full match" ? 1 : 0)
Threads.atomic_add!(count_partial_start, res.result == "🔄 Prefix matches only" ? 1 : 0)
Threads.atomic_add!(count_partial_end, res.result == "🔄 Suffix matches only" ? 1 : 0)
Threads.atomic_add!(count_partial_both, res.result == "🔄 Prefix and suffix match" ? 1 : 0)
Threads.atomic_add!(count_none, res.result == "❌ No match" ? 1 : 0)

push!(results21_df, [  # Append current result to DataFrame
res.N,
res.m,
res.k,
res.parts,
res.multiplied_parts,
res.PQ,
res.NK,
res.result
])
end

full = count_full[]
partial_start = count_partial_start[]
partial_end = count_partial_end[]
partial_both = count_partial_both[]
none = count_none[]

println("\n💾 Saving results to CSV...")
CSV.write("results2.csv", results21_df)  # Write results table to CSV file

open("statistics7.txt", "w") do io  # Open file for writing statistics
write(io, "📊 Structural Numerical Symmetry Hypothesis\n")
write(io, "=========================================\n")
write(io, "N range: [$start_N, $stop_N]\n")
write(io, "Number of parts m = $m\n")
write(io, "Multiplier k = $k\n")
write(io, "-----------------------------------------\n")
write(io, "  ✅ Full matches: $full\n")
write(io, "  🔄 Prefix and suffix match: $partial_both\n")
write(io, "  🔄 Prefix matches only: $partial_start\n")
write(io, "  🔄 Suffix matches only: $partial_end\n")
write(io, "  ❌ No matches: $none\n")
write(io, "📄 Per-number results in 'results2.csv'\n")
end

println("\n📊 Summary statistics:")
@printf("  ✅ Full matches: %d\n", full)
@printf("  🔄 Prefix and suffix match: %d\n", partial_both)
@printf("  🔄 Prefix matches only: %d\n", partial_start)
@printf("  🔄 Suffix matches only: %d\n", partial_end)
@printf("  ❌ No matches: %d\n", none)
println("\n📄 Statistics saved to 'statistics7.txt'")
println("📄 Results saved to 'results2.csv'")

return results21_df # Return the populated results DataFrame
end

# User-defined parameters
start_N = 1 # Start of test range
stop_N = 10000000 # End of test range
m = 2 # Number of parts to split the number into
k = 99999999 # Multiplier for each part

# Run tests
run_tests_parallel(start_N, stop_N, m, k) # Execute main function for parallel hypothesis testing