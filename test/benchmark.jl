module Bench

using EasyRanges
using BenchmarkTools

test1_jl(A, B, C) = A ∩ (B .+ C)
test1(A, B, C) = @range A ∩ (B + C)

test2_jl(A, B, C) = A ∩ (B .- C)
test2(A, B, C) = @range A ∩ (B - C)

A = CartesianIndices((30,40,50));
B = CartesianIndices((3,4,5));

I = CartesianIndex(1,2,3);
println("Testing with I = $I")

print("       A ∩ (B .+ I)"); @btime test1_jl($A, $B, $I);
print("@range A ∩ (B  + I)"); @btime test1($A, $B, $I);
print("       A ∩ (I .+ B)"); @btime test1_jl($A, $I, $B);
print("@range A ∩ (I  + B)"); @btime test1($A, $I, $B);

print("       A ∩ (B .- I)"); @btime test2_jl($A, $B, $I);
print("@range A ∩ (B  - I)"); @btime test2($A, $B, $I);
print("       A ∩ (I .- B)"); @btime test2_jl($A, $I, $B);
print("@range A ∩ (I  - B)"); @btime test2($A, $I, $B);

I = CartesianIndex(10,20,30);
println("\nTesting with I = $I")

print("       A ∩ (B .+ I)"); @btime test1_jl($A, $B, $I);
print("@range A ∩ (B  + I)"); @btime test1($A, $B, $I);
print("       A ∩ (I .+ B)"); @btime test1_jl($A, $I, $B);
print("@range A ∩ (I  + B)"); @btime test1($A, $I, $B);

print("       A ∩ (B .- I)"); @btime test2_jl($A, $B, $I);
print("@range A ∩ (B  - I)"); @btime test2($A, $B, $I);
print("       A ∩ (I .- B)"); @btime test2_jl($A, $I, $B);
print("@range A ∩ (I  - B)"); @btime test2($A, $I, $B);

end # module
