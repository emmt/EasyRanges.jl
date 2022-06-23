module TestIndexingTools

using Test

using Base: OneTo
using IndexingTools
using IndexingTools: forward, ranges, to_type, to_int, pm, mp

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
    @test pm(7, 11) === -4:18
    @test pm(Int16(7), Int16(11)) === -4:18
    @test pm(OneTo(6), 3) === -2:9
    @test pm(OneTo{Int16}(6), Int16(3)) === -2:9
    @test pm(7, 3) === 4:10
    @test pm(7, Int16(3)) === 4:10

    # Shrinking.
    @test mp(7, -11) === -4:18
    @test mp(Int16(7), -Int16(11)) === -4:18
    @test mp(OneTo(6), -2) === 3:4
    @test mp(OneTo{Int16}(6), -Int16(2)) === 3:4
    @test mp(7, -3) === 4:10
    @test mp(7, -Int16(3)) === 4:10

    # Shift CartesianIndices by CartesianIndex.
    @test (@range CartesianIndices((2:3, -1:5)) + CartesianIndex(4,-7)) ===
        CartesianIndices((6:7, -8:-2))
    @test (@range CartesianIndices((2:3, -1:5)) - CartesianIndex(4,-7)) ===
        CartesianIndices((-2:-1, 6:12))

    @test (@range CartesianIndex(4,-7) + CartesianIndices((2:3, -1:5))) ===
        CartesianIndices((6:7, -8:-2))
    @test (@range CartesianIndices((2:3, -1:5)) - CartesianIndex(4,-7)) ===
        CartesianIndices((-2:-1, 6:12))
end

end # module
