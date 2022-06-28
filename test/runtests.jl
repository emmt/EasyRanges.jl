module TestIndexingTools

using Test

using Base: OneTo
using IndexingTools
using IndexingTools: forward, backward, ranges, to_type, to_int, stretch, shrink

# CartesianIndices with non-unit ranges appear in Julia 1.6
const CARTESIAN_INDICES_MAY_HAVE_NON_UNIT_RANGES = (VERSION ≥ v"1.6")

@testset "IndexingTools.jl" begin
    # Check normalization of ranges.
    @test forward(OneTo(6)) === OneTo{Int}(6)
    @test forward(OneTo{Int16}(6)) === OneTo{Int}(6)
    @test forward(2:7) === 2:7
    @test forward(Int16(2):Int16(7)) === 2:7
    @test forward(-2:3:11) === -2:3:11
    @test forward(Int16(-2):Int16(3):Int16(11)) === -2:3:11
    @test forward(11:-3:-2) === -1:3:11
    @test forward(Int16(11):Int16(-3):Int16(-2)) === -1:3:11

    # Streching.
    @test stretch(7, 11) === -4:18
    @test stretch(Int16(7), Int16(11)) === -4:18
    @test stretch(OneTo(6), 3) === -2:9
    @test stretch(OneTo{Int16}(6), Int16(3)) === -2:9
    @test stretch(7, 3) === 4:10
    @test stretch(7, Int16(3)) === 4:10

    # Shrinking.
    @test shrink(7, -11) === -4:18
    @test shrink(Int16(7), -Int16(11)) === -4:18
    @test shrink(OneTo(6), -2) === 3:4
    @test shrink(OneTo{Int16}(6), -Int16(2)) === 3:4
    @test shrink(7, -3) === 4:10
    @test shrink(7, -Int16(3)) === 4:10

    # Shift CartesianIndices by CartesianIndex.
    @test (@range CartesianIndices((2:3, -1:5)) + CartesianIndex(4,-7)) ===
        CartesianIndices((6:7, -8:-2))
    @test (@range CartesianIndices((2:3, -1:5)) - CartesianIndex(4,-7)) ===
        CartesianIndices((-2:-1, 6:12))

    @test (@range CartesianIndex(4,-7) + CartesianIndices((2:3, -1:5))) ===
        CartesianIndices((6:7, -8:-2))
    @test (@range CartesianIndices((2:3, -1:5)) - CartesianIndex(4,-7)) ===
        CartesianIndices((-2:-1, 6:12))

    @test (@range OneTo(5)) === OneTo(5)
    @test (@reverse_range OneTo(5)) === 5:-1:1

    @test (@range 1:5) === 1:5
    @test (@reverse_range 1:5) === 5:-1:1
    @test (@range 5:-1:1) === 1:1:5
    @test (@reverse_range 5:-1:1) === 5:-1:1

    @test (@range -7:2:6) === -7:2:5
    @test (@reverse_range -7:2:6) === 5:-2:-7
    @test (@range 5:-2:-8) === -7:2:5
    @test (@reverse_range 5:-2:-8) === 5:-2:-7

    # Shift CartesianIndices by CartesianIndex (reversed).
    if CARTESIAN_INDICES_MAY_HAVE_NON_UNIT_RANGES
        @test (@reverse_range CartesianIndices((2:3, -1:5)) + CartesianIndex(4,-7)) ===
            CartesianIndices((7:-1:6, -2:-1:-8))
        @test (@reverse_range CartesianIndices((2:3, -1:5)) - CartesianIndex(4,-7)) ===
            CartesianIndices((-1:-1:-2, 12:-1:6))

        @test (@reverse_range CartesianIndex(4,-7) + CartesianIndices((2:3, -1:5))) ===
            CartesianIndices((7:-1:6, -2:-1:-8))
        @test (@reverse_range CartesianIndices((2:3, -1:5)) - CartesianIndex(4,-7)) ===
            CartesianIndices((-1:-1:-2, 12:-1:6))
    end
end

end # module
