# Author: Mikhail Yuryevich Yushchenko
# Project: Structural Numerical Symmetry Cellular Automaton ( SNS-CA )
# License: CC BY 4.0
# Date: 09.08.2026
using Printf
using Random
using Images
using Plots
using ProgressMeter
using Dates
using DelimitedFiles
using Base.Threads
function split_number_str(N::Integer,m::Integer) # Splits number N into m parts
s=string(N) # Convert number to string
if length(s)<m # If string is shorter than m
s=lpad(s,m,'0') # Pad with zeros on the left
end
len=length(s) # Get string length
base_len=len÷m # Base length for each part
remainder=len%m # Remainder to distribute
parts=String[] # Initialize empty array for parts
idx=1 # Start index
for i in 1:m # Loop through m parts
current_len=base_len+(i<=remainder?1:0) # Calculate current part length
if current_len>0 # If length is positive
push!(parts,s[idx:idx+current_len-1]) # Add substring to parts
else
push!(parts,"0") # Otherwise add "0"
end
idx+=current_len # Move index forward
end
return parts # Return array of string parts
end
function multiply_preserve_length(part::String,k::Integer) # Multiplies part by k, preserving length
if isempty(part) # If part is empty
return "0" # Return "0"
end
num=parse(BigInt,part)*k # Parse to BigInt and multiply by k
result=string(num) # Convert result to string
return lpad(result,length(part),'0') # Pad with zeros to preserve original length
end
function apply_sns(N::Integer,m::Integer,k::Integer) # Applies SNS transformation to number N
parts=split_number_str(N,m) # Split N into m parts
transformed_parts=[multiply_preserve_length(p,k) for p in parts] # Multiply each part by k
return join(transformed_parts,"") # Join transformed parts back together
end
function compare_pq_nk(pq::String,nk::String) # Compares SNS result with N*k by prefixes/suffixes
if pq==nk # If strings are identical
return 0 # Return 0 (F: Full match)
end
len_pq=length(pq) # Get length of pq
len_nk=length(nk) # Get length of nk
min_len=min(len_pq,len_nk) # Get minimum length
if min_len==0 # If minimum length is zero
return 4 # Return 4 (N: No match)
end
has_start_match=false # Flag for start match
has_end_match=false # Flag for end match
for l in 1:min_len # Loop through possible match lengths
if pq[1:l]==nk[1:l] # If prefixes match
has_start_match=true # Set start match flag
end
if pq[(end-l+1):end]==nk[(end-l+1):end] # If suffixes match
has_end_match=true # Set end match flag
end
end
if has_start_match&&has_end_match # If both start and end match
return 1 # Return 1 (B: Boundary match)
elseif has_end_match&&!has_start_match # If only end matches
return 2 # Return 2 (E: End match)
elseif has_start_match&&!has_end_match # If only start matches
return 3 # Return 3 (S: Start match)
else
return 4 # Return 4 (N: No match)
end
end
function get_cell_state(N::BigInt,m::Int,k::Int)::Tuple{String,Int} # Gets cell state
pq=apply_sns(N,m,k) # Apply SNS transformation
nk=string(N*k) # Calculate N*k as string
type_flag=compare_pq_nk(pq,nk) # Compare pq and nk
return pq,type_flag # Return result and type flag
end
function initialize_grid(L::Int,min_val::Int=10^4,max_val::Int=10^8;seed::Union{Int,Nothing}=nothing) # Initializes L×L grid
if seed!==nothing # If seed is provided
Random.seed!(seed) # Set random seed for reproducibility
end
grid=Array{BigInt}(undef,L,L) # Create uninitialized BigInt array
for i in 1:L,j in 1:L # Loop through all cells
grid[i,j]=BigInt(rand(min_val:max_val)) # Fill with random BigInt values
end
return grid # Return initialized grid
end
function update_cell(N::BigInt,m::Int,k::Int) # Updates single cell state
pq_str,type_flag=get_cell_state(N,m,k) # Get cell state
if type_flag==4 # If no match (N state)
return BigInt(0) # Cell dies (returns 0)
else
return parse(BigInt,pq_str) # Otherwise return transformed value
end
end
function update_grid!(grid::Array{BigInt,2},m::Int,k::Int) # Updates entire grid in-place
L=size(grid,1) # Get grid size
new_grid=copy(grid) # Create copy of grid
for i in 1:L,j in 1:L # Loop through all cells
new_grid[i,j]=update_cell(grid[i,j],m,k) # Update each cell
end
copyto!(grid,new_grid) # Copy new values back to original grid
end
function grid_to_image(grid::Array{BigInt,2},L::Int,m::Int,k::Int) # Converts grid to RGB image
img=Matrix{RGB{Float64}}(undef,L,L) # Create uninitialized RGB matrix
for i in 1:L,j in 1:L # Loop through all cells
N=grid[i,j] # Get cell value
if N==0 # If cell is dead
img[i,j]=RGB(0.0,0.0,0.0) # Set to black
else
len=length(string(N)) # Get string length of cell value
max_len=100 # Maximum length for normalization
intensity=clamp(len/max_len,0.1,1.0) # Calculate color intensity
_,type_flag=get_cell_state(N,m,k) # Get cell state type
if type_flag==0 # If F (Full match)
img[i,j]=RGB(intensity,0.8*intensity,0.0) # Golden color
elseif type_flag==1 # If B (Boundary match)
img[i,j]=RGB(0.0,intensity,0.0) # Green color
elseif type_flag==2 # If E (End match)
img[i,j]=RGB(intensity,0.0,0.0) # Red color
elseif type_flag==3 # If S (Start match)
img[i,j]=RGB(0.0,0.0,intensity) # Blue color
else
img[i,j]=RGB(0.3,0.3,0.3) # Gray color (N state)
end
end
end
return img # Return RGB image matrix
end
function save_frame(grid::Array{BigInt,2},frame_num::Int,m::Int,k::Int,dir="ca_sns_frames/") # Saves grid frame as PNG
mkpath(dir) # Create directory if it doesn't exist
L=size(grid,1) # Get grid size
img=grid_to_image(grid,L,m,k) # Convert grid to image with correct parameters
save(joinpath(dir,"frame_$(string(frame_num;pad=5)).png"),img) # Save image with padded frame number
end
function collect_statistics(grid::Array{BigInt,2},m::Int,k::Int) # Collects statistics of cell states
L=size(grid,1) # Get grid size
counts=Dict("F"=>0,"B"=>0,"E"=>0,"S"=>0,"N"=>0) # Initialize counters for each state
for i in 1:L,j in 1:L # Loop through all cells
N=grid[i,j] # Get cell value
if N==0 # If cell is dead
counts["N"]+=1 # Increment N counter
else
_,type_flag=get_cell_state(N,m,k) # Get cell state type
type_name=["F","B","E","S","N"][type_flag+1] # Convert flag to state name
counts[type_name]+=1 # Increment corresponding counter
end
end
return counts # Return dictionary of counts
end
function run_ca_sns_gif(L::Int=75,steps::Int=300,m::Int=2,k::Int=3,min_val::Int=10^4,max_val::Int=10^8,fps::Int=5,frames_dir::String="ca_sns_frames/",gif_filename::String="CA-SNS_m$(m)_k$(k)_$(Date(today())).gif";seed::Union{Int,Nothing}=42) # Main simulation function
min_val=max(min_val,10^(m-1)) # Adjust min_val to ensure enough digits for m parts
println("SNS-CA | m=$m, k=$k | Grid: $L×$L | Steps: $steps | Seed: $seed\n") # Print simulation info
grid=initialize_grid(L,min_val,max_val;seed=seed) # Initialize grid with seed
mkpath(frames_dir) # Create frames directory
stats=Dict{String,Vector{Int}}("F"=>Int[],"B"=>Int[],"E"=>Int[],"S"=>Int[],"N"=>Int[]) # Initialize statistics dictionary
@showprogress "Evolving..." for t in 1:steps # Progress bar for evolution loop
update_grid!(grid,m,k) # Update grid for one step
counts=collect_statistics(grid,m,k) # Collect statistics for current step
for key in keys(counts) # Loop through state types
push!(stats[key],counts[key]) # Add counts to statistics
end
save_frame(grid,t,m,k,frames_dir) # Save frame as PNG
end
alive_count=sum(x->x>0,grid) # Count alive cells
println("\nCompleted: $alive_count/$(L*L) cells alive") # Print completion message
stats_file="stats_m$(m)_k$(k)_seed$(seed).csv" # Generate statistics filename
stats_matrix=hcat(stats["F"],stats["B"],stats["E"],stats["S"],stats["N"]) # Combine statistics into matrix
writedlm(stats_file,stats_matrix,',') # Write statistics to CSV file
println("Statistics saved to $stats_file") # Print statistics save message
println("\nBuilding GIF...") # Print GIF building message
if Sys.which("ffmpeg")===nothing # If ffmpeg is not installed
println("ffmpeg not found. Frames saved in '$frames_dir'.") # Print warning
println("Install ffmpeg for automatic GIF creation.") # Print installation hint
else
try
cmd=`ffmpeg -y -framerate $fps -i $(joinpath(frames_dir,"frame_%05d.png")) -vf "scale=500:500:flags=lanczos" -pix_fmt rgb24 $gif_filename` # Build ffmpeg command
run(cmd) # Execute ffmpeg command
println("GIF created: $gif_filename") # Print success message
catch e
println("Error creating GIF: ",e) # Print error message
end
end
return stats # Return statistics dictionary
end
function analyze_single_trajectory(N::BigInt,m::Int,k::Int,steps::Int) # Analyzes single number trajectory
println("Analyzing trajectory: N=$N, m=$m, k=$k") # Print analysis info
println("-"^60) # Print separator
current=N # Set current value to N
for i in 1:steps # Loop through steps
pq,type_flag=get_cell_state(current,m,k) # Get current state
type_name=["F","B","E","S","N"][type_flag+1] # Convert flag to state name
println("Step $i: $current -> $pq [$type_name]") # Print step info
if type_flag==4 # If cell died
println("Cell died at step $i") # Print death message
break # Exit loop
end
current=parse(BigInt,pq) # Update current value
end
end
function test_edge_cases() # Tests edge cases
println("Testing edge cases...") # Print test message
@assert split_number_str(123456,2)==["123","456"] # Test split with even length
@assert split_number_str(12345,2)==["123","45"] # Test split with odd length
@assert length(split_number_str(5,3))==3 # Test split with short number
@assert length(apply_sns(123456,2,3))==6 # Test SNS preserves length
@assert compare_pq_nk("123","123")==0 # Test full match
@assert compare_pq_nk("123","124")==3 # Test start match
@assert compare_pq_nk("123","223")==2 # Test end match
@assert compare_pq_nk("123","456")==4 # Test no match
println("All tests passed!") # Print success message
end
run_ca_sns_gif(100,300,2,3,10,10^6,5;seed=42) # Run main simulation with default parameters
