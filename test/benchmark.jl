module Bench

using EasyRanges
using BenchmarkTools, Test

const try_turbo = false # NOTE: @turbo code broken for Cartesian indices

@static if try_turbo
    using LoopVectorization
end

test1_jl(A, B, C) = A ∩ (B .+ C)
test1(A, B, C) = @range A ∩ (B + C)

test2_jl(A, B, C) = A ∩ (B .- C)
test2(A, B, C) = @range A ∩ (B - C)


# Discrete correlation.
function correlate_jl!(dst, A, B)
    T = promote_type(eltype(A), eltype(B))
    @inbounds for i ∈ CartesianIndices(dst)
        s = zero(T)
        @simd for j ∈ CartesianIndices(A) ∩ (i .+ CartesianIndices(B))
            s += A[j]*B[j-i]
        end
        dst[i] = s
    end
    return dst
end
function correlate!(dst, A, B)
    T = promote_type(eltype(A), eltype(B))
    @inbounds for i ∈ CartesianIndices(dst)
        s = zero(T)
        @simd for j ∈ @range CartesianIndices(A) ∩ (i + CartesianIndices(B))
            s += A[j]*B[j-i]
        end
        dst[i] = s
    end
    return dst
end
@static if try_turbo
    function correlate_turbo!(dst, A, B)
        T = promote_type(eltype(A), eltype(B))
        @inbounds for i ∈ CartesianIndices(dst)
            s = zero(T)
            @turbo for j ∈ @range CartesianIndices(A) ∩ (i + CartesianIndices(B))
                s += A[j]*B[j-i]
            end
        dst[i] = s
        end
        return dst
    end
end

# Discrete convolution.
function convolve_jl!(dst, A, B)
    T = promote_type(eltype(A), eltype(B))
    @inbounds for i ∈ CartesianIndices(dst)
        s = zero(T)
        @simd for j ∈ CartesianIndices(A) ∩ (i .- CartesianIndices(B))
            s += A[j]*B[i-j]
        end
        dst[i] = s
    end
    return dst
end
function convolve!(dst, A, B)
    T = promote_type(eltype(A), eltype(B))
    @inbounds for i ∈ CartesianIndices(dst)
        s = zero(T)
        @simd for j ∈ @range CartesianIndices(A) ∩ (i - CartesianIndices(B))
            s += A[j]*B[i-j]
        end
        dst[i] = s
    end
    return dst
end
@static if try_turbo
    function convolve_turbo!(dst, A, B)
        T = promote_type(eltype(A), eltype(B))
        @inbounds for i ∈ CartesianIndices(dst)
            s = zero(T)
            @turbo for j ∈ @range CartesianIndices(A) ∩ (i - CartesianIndices(B))
                s += A[j]*B[i-j]
            end
            dst[i] = s
        end
        return dst
    end
end

A = CartesianIndices((30,40,50));
B = CartesianIndices((3,4,5));

for I ∈ (CartesianIndex(1,2,3), #= CartesianIndex(10,20,30) =#)
    println("Testing with I = $I")

    print("       A ∩ (B .+ I)"); @btime test1_jl($A, $B, $I);
    print("@range A ∩ (B  + I)"); @btime test1($A, $B, $I);
    print("       A ∩ (I .+ B)"); @btime test1_jl($A, $I, $B);
    print("@range A ∩ (I  + B)"); @btime test1($A, $I, $B);

    print("       A ∩ (B .- I)"); @btime test2_jl($A, $B, $I);
    print("@range A ∩ (B  - I)"); @btime test2($A, $B, $I);
    print("       A ∩ (I .- B)"); @btime test2_jl($A, $I, $B);
    print("@range A ∩ (I  - B)"); @btime test2($A, $I, $B);
end

T = Float32
A = rand(T, (8,8))
B = rand(T, (32,32))
C1 = similar(B)
C2 = similar(B)
x = '×'
println("\nTesting correlation of $(join(size(A),x)) and $(join(size(B),x)) arrays")
print("base Julia with @simd  "); @btime correlate_jl!($C1, $A, $B);
print("using @range and @simd "); @btime correlate!($C2, $A, $B);
@test C1 ≈ C2
if try_turbo
    print("using @range and @turbo"); @btime correlate_turbo!($C2, $A, $B);
    @test C1 ≈ C2
end
println("\nTesting correlation of $(join(size(B),x)) and $(join(size(A),x)) arrays")
print("base Julia with @simd  "); @btime correlate_jl!($C1, $B, $A);
print("using @range and @simd "); @btime correlate!($C2, $B, $A);
@test C1 ≈ C2
if try_turbo
    print("using @range and @turbo"); @btime correlate_turbo!($C2, $B, $A);
    @test C1 ≈ C2
end

println("\nTesting convolution of $(join(size(A),x)) and $(join(size(B),x)) arrays")
print("base Julia with @simd  "); @btime convolve_jl!($C1, $A, $B);
print("using @range and @simd "); @btime convolve!($C2, $A, $B);
@test C1 ≈ C2
if try_turbo
    print("using @range and @turbo"); @btime convolve_turbo!($C2, $A, $B);
    @test C1 ≈ C2
end
println("\nTesting convolution of $(join(size(B),x)) and $(join(size(A),x)) arrays")
print("base Julia with @simd  "); @btime convolve_jl!($C1, $B, $A);
print("using @range and @simd "); @btime convolve!($C2, $B, $A);
@test C1 ≈ C2
if try_turbo
    print("using @range and @turbo"); @btime convolve_turbo!($C2, $B, $A);
    @test C1 ≈ C2
end

end # module
