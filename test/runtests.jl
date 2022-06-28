module TestIndexingTools

using Test

using Base: OneTo
using IndexingTools
using IndexingTools:
    forward, backward, ranges, to_type, to_int, stretch, shrink,
    first_last, first_step_last

# A bit of type-piracy for more readable error messages.
Base.show(io::IO, x::CartesianIndices) =
    print(io, "CartesianIndices($(x.indices))")

# CartesianIndices with non-unit ranges appear in Julia 1.6
const CARTESIAN_INDICES_MAY_HAVE_NON_UNIT_RANGES = (VERSION ≥ v"1.6")

@testset "IndexingTools" begin
    # to_type
    let A = [-1,0,2]
        @test to_type(Array{Int}, A) === A
        @test to_type(Array{Int16}, A) isa Array{Int16}
        @test to_type(Array{Int16}, A) == A
    end

    # to_int
    @test to_int(5) === 5
    @test to_int(UInt16(7)) === 7
    @test to_int(OneTo{Int}(8)) === OneTo(8)
    @test to_int(OneTo{UInt16}(3)) === OneTo(3)
    @test to_int(3:8) === 3:8
    @test to_int(UInt16(3):UInt16(8)) === 3:8
    @test to_int(8:-3:-1) === 8:-3:-1
    @test to_int(Int16(8):Int16(-3):Int16(-1)) === 8:-3:-1
    @test to_int(CartesianIndex(-1,2,3,4)) === CartesianIndex(-1,2,3,4)
    @test to_int(CartesianIndices((Int16(-1):Int16(3),Int16(2):Int16(8)))) === CartesianIndices((-1:3,2:8))
    @test to_int((-1,3,2)) === (-1,3,2)
    @test to_int((Int16(-1),Int16(3),Int16(2))) === (-1,3,2)

    # first_last and first_step_last
    @test first_last(Int16(-4):Int16(11)) == (-4, 11)
    @test_throws MethodError first_last(-4:2:11)
    @test first_step_last(Int16(-4):Int16(11)) === (-4,1,11)
    @test first_step_last(Int16(-4):Int16(2):Int16(11)) === (-4,2,10)

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
    let I = CartesianIndex(7,8)
        @test stretch(I, 2) === CartesianIndices((5:9, 6:10))
        @test (@range I ± 2) === CartesianIndices((5:9, 6:10))
        @test stretch(I, (2,3)) === CartesianIndices((5:9, 5:11))
        @test (@range I ± (2,3)) === CartesianIndices((5:9, 5:11))
        @test stretch(I, CartesianIndex(2,3)) === CartesianIndices((5:9, 5:11))
        @test (@range I ± CartesianIndex(2,3)) === CartesianIndices((5:9, 5:11))
    end
    let R = CartesianIndices((5:8, -1:4))
        @test stretch(R, 2) === CartesianIndices((3:10, -3:6))
        @test (@range R ± 2) === CartesianIndices((3:10, -3:6))
        @test stretch(R, (2,3)) === CartesianIndices((3:10, -4:7))
        @test (@range R ± (2,3)) === CartesianIndices((3:10, -4:7))
        @test stretch(R, CartesianIndex(2,3)) === CartesianIndices((3:10, -4:7))
        @test (@range R ± CartesianIndex(2,3)) === CartesianIndices((3:10, -4:7))
    end

    # Shrinking.
    @test shrink(7, -11) === -4:18
    @test shrink(Int16(7), -Int16(11)) === -4:18
    @test shrink(OneTo(6), 2) === 3:4
    @test shrink(OneTo{Int16}(6), Int16(2)) === 3:4
    @test shrink(7, -3) === 4:10
    @test shrink(7, -Int16(3)) === 4:10
    let R = CartesianIndices((5:11, -1:6))
        @test shrink(R, 2) === CartesianIndices((7:9, 1:4))
        @test (@range R ∓ 2) === CartesianIndices((7:9, 1:4))
        @test shrink(R, (2,3)) === CartesianIndices((7:9, 2:3))
        @test (@range R ∓ (2,3)) === CartesianIndices((7:9, 2:3))
        @test shrink(R, CartesianIndex(2,3)) === CartesianIndices((7:9, 2:3))
        @test (@range R ∓ CartesianIndex(2,3)) === CartesianIndices((7:9, 2:3))
    end

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
