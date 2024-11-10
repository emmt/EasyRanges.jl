module TestingEasyRanges

using Test

using Base: OneTo
using EasyRanges
using EasyRanges:
    forward, backward, ranges, normalize, stretch, shrink, plus, minus, cap

# A bit of type-piracy for more readable error messages.
Base.show(io::IO, x::CartesianIndices) =
    print(io, "CartesianIndices($(x.indices))")

# CartesianIndices with non-unit ranges appear in Julia 1.6
const CARTESIAN_INDICES_MAY_HAVE_NON_UNIT_RANGES = (VERSION ≥ v"1.6")

@testset "EasyRanges" begin
    # Test `normalize`.
    @test_throws Exception normalize()
    @test_throws Exception normalize("hello")
    @test normalize(5) === 5
    @test normalize(UInt16(7)) === 7
    @test normalize(OneTo{Int}(8)) === OneTo(8)
    @test normalize(OneTo{UInt16}(3)) === OneTo(3)
    @test normalize(3:8) === 3:8
    @test normalize(UInt16(3):UInt16(8)) === 3:8
    @test normalize(8:-3:-1) === 8:-3:-1
    @test normalize(Int16(8):Int16(-3):Int16(-1)) === 8:-3:-1
    @test normalize(CartesianIndex(-1,2,3,4)) === CartesianIndex(-1,2,3,4)
    @test normalize(CartesianIndices((Int16(-1):Int16(3),Int16(2):Int16(8)))) === CartesianIndices((-1:3,2:8))
    @test normalize((-1,3,2)) === (-1,3,2)
    @test normalize((Int16(-1),Int16(3),Int16(2))) === (-1,3,2)

    # Test `forward`.
    @test_throws Exception forward(π) === π
    @test forward(-5) === -5
    @test forward(0x5) === 5
    @test forward(OneTo(6)) === OneTo{Int}(6)
    @test forward(OneTo{Int16}(6)) === OneTo{Int}(6)
    @test forward(2:7) === 2:7
    @test forward(Int16(2):Int16(7)) === 2:7
    @test forward(-2:3:11) === -2:3:11
    @test forward(Int16(-2):Int16(3):Int16(11)) === -2:3:11
    @test forward(11:-3:-2) === -1:3:11
    @test forward(Int16(11):Int16(-3):Int16(-2)) === -1:3:11
    @test forward(CartesianIndex(-1,3,4)) === CartesianIndex(-1,3,4)
    @test forward(CartesianIndices((Int16(0):Int16(3),Int16(8):Int16(-3):Int16(1)))) === CartesianIndices((0:3, 2:3:8))

    # Test `backward`.
    @test_throws Exception backward(π) === π
    @test backward(-5) === -5
    @test backward(0x5) === 5
    @test backward(OneTo(5)) === 5:-1:1
    @test backward(2:3:12) === 11:-3:2
    @test backward(11:-3:2) === 11:-3:2
    @test backward(CartesianIndex(-1,3,4)) === CartesianIndex(-1,3,4)
    @test backward(CartesianIndices((Int16(0):Int16(3),Int16(8):Int16(-3):Int16(1)))) === CartesianIndices((3:-1:0, 8:-3:2))

    # Unary plus.
    @test_throws Exception plus(1.0) === 1.0
    @test plus(7) === 7
    @test plus(Int16(7)) === 7
    @test plus(2:8) === 2:8
    @test plus(Int16(2):Int16(8)) === 2:8
    @test plus(2:3:12) === 2:3:11
    @test plus(Int16(2):Int16(3):Int16(12)) === 2:3:11
    @test plus(12:-4:-1) === 12:-4:0
    @test plus(CartesianIndex(-1,2,3,4)) === CartesianIndex(-1,2,3,4)
    @test plus(CartesianIndices((4:8,2:9))) === CartesianIndices((4:8,2:9))
    if CARTESIAN_INDICES_MAY_HAVE_NON_UNIT_RANGES
        @test plus(CartesianIndices((8:-1:4,2:3:9))) === CartesianIndices((8:-1:4,2:3:8))
    end

    # Addition.
    @test_throws Exception plus(2, π) === (2 + π)
    @test plus(3, 8) === 11
    @test plus(Int16(3), Int16(8)) === 11
    @test plus(1:4, 2) === 3:6
    @test plus(2, 1:4) === 3:6
    @test plus(1:2:8, 3) === 4:2:10
    @test plus(3, 1:2:8) === 4:2:10
    @test plus(8:-2:1, 3) === 11:-2:5
    @test plus(3, 8:-2:1) === 11:-2:5
    @test plus(CartesianIndices(((4:8, 2:9))), CartesianIndex(-1,2)) === CartesianIndices(((3:7, 4:11)))
    @test (@range CartesianIndices(((4:8, 2:9))) + CartesianIndex(-1,2)) === CartesianIndices(((3:7, 4:11)))
    @test plus(CartesianIndex(-1,2), CartesianIndices(((4:8, 2:9)))) === CartesianIndices(((3:7, 4:11)))
    @test (@range CartesianIndex(-1,2) + CartesianIndices(((4:8, 2:9)))) === CartesianIndices(((3:7, 4:11)))

    # Addition of 3 or more arguments
    @test_throws Exception plus(1.0, 2, π, sqrt(2)) === (1.0 + 2 + π + sqrt(2))
    @test plus(1, 2:3, 4) === 7:8 == 1 .+ (2:3) .+ 4

    # Unary minus.
    @test_throws Exception minus(1.0) === -1.0
    @test minus(7) === -7
    @test minus(Int16(7)) === -7
    @test minus(2:8) === -8:-2
    @test minus(Int16(2):Int16(8)) === -8:-2
    @test minus(2:3:12) === -2:-3:-11
    @test minus(Int16(2):Int16(3):Int16(12)) === -2:-3:-11
    @test minus(12:-4:-1) === -12:4:0
    @test minus(CartesianIndex(-1,2,3,4)) === CartesianIndex(1,-2,-3,-4)
    @test minus(CartesianIndices((4:8,2:9))) === CartesianIndices((-8:-4,-9:-2))
    if CARTESIAN_INDICES_MAY_HAVE_NON_UNIT_RANGES
        @test minus(CartesianIndices((8:-1:3,2:3:9))) === CartesianIndices((-8:1:-3,-2:-3:-8))
    end

    # Subtraction.
    @test_throws Exception minus(2, π) === (2 - π)
    @test minus(3, 8) === -5
    @test minus(Int16(3), Int16(8)) === -5
    @test minus(1:4, 2) === -1:2
    @test minus(2, 1:4) === -2:1
    @test minus(1:2:8, 3) === -2:2:4
    @test minus(3, 0:2:9) === 3:-2:-5
    @test minus(8:-2:1, 3) === 5:-2:-1
    @test minus(3, 8:-2:1) === -5:2:1
    @test minus(CartesianIndices(((4:8, 2:9))), CartesianIndex(-1,2)) === CartesianIndices(((5:9, 0:7)))
    @test (@range CartesianIndices(((4:8, 2:9))) - CartesianIndex(-1,2)) === CartesianIndices(((5:9, 0:7)))
    @test minus(CartesianIndex(-1,2), CartesianIndices(((4:8, 2:9)))) === CartesianIndices(((-9:-5, -7:0)))
    @test (@range CartesianIndex(-1,2) - CartesianIndices(((4:8, 2:9)))) === CartesianIndices(((-9:-5, -7:0)))

    # Intersection.
    @test_throws Exception cap([1], 1) == [1]
    @test cap(-7, -7) === -7:-7
    @test cap(2, 0) === 1:0
    @test cap(Int16(2), Int16(0)) === 1:0
    @test cap(2, 0:6) === 2:2
    @test cap(0:6, 2) === 2:2
    @test cap(-1, 0:6) === 1:0
    @test cap(0:6, -1) === 1:0
    @test cap(OneTo(5), OneTo(7)) === OneTo(5)
    @test cap(OneTo(9), OneTo(7)) === OneTo(7)
    @test cap(1:7, 2:5) === 2:5
    @test cap(2:5, 1:7) === 2:5
    @test cap(1:7, 0:5) === 1:5
    @test cap(0:5, 1:7) === 1:5
    @test cap(1:7, 2:8) === 2:7
    @test cap(2:8, 1:7) === 2:7
    @test cap(2:3:9, 11) === 1:0
    @test cap(2:3:9, 5) === 5:5
    @test cap(2:3:9, 1:1:7) === 2:3:5
    @test cap(2:3:14, 1:2:12) === 5:6:11
    @test cap(14:-3:2, 1:2:12) === 5:6:11

    @test_throws Exception (@range [1] ∩ 1) == [1]
    @test (@range -7 ∩ -7) === -7:-7
    @test (@range 2 ∩ 0) === 1:0
    @test (@range Int16(2) ∩ Int16(0)) === 1:0
    @test (@range 2 ∩ (0:6)) === 2:2
    @test (@range (0:6) ∩ 2) === 2:2
    @test (@range -1 ∩ (0:6)) === 1:0
    @test (@range (0:6) ∩ -1) === 1:0
    @test (@range OneTo(5) ∩ OneTo(7)) === OneTo(5)
    @test (@range OneTo(9) ∩ OneTo(7)) === OneTo(7)
    @test (@range (1:7) ∩ (2:5)) === 2:5
    @test (@range (2:5) ∩ (1:7)) === 2:5
    @test (@range (1:7) ∩ (0:5)) === 1:5
    @test (@range (0:5) ∩ (1:7)) === 1:5
    @test (@range (1:7) ∩ (2:8)) === 2:7
    @test (@range (2:8) ∩ (1:7)) === 2:7
    @test (@range (2:3:9) ∩ (1:1:7)) === 2:3:5
    @test (@range (2:3:14) ∩ (1:2:12)) === 5:6:11
    @test (@range (14:-3:2) ∩ (1:2:12)) === 5:6:11

    @test (@range intersect(14:-3:2, 1:2:12)) === 5:6:11
    @test (@range Base.intersect(14:-3:2, 1:2:12)) === 5:6:11

    @test cap(CartesianIndex(3,4), CartesianIndex(3,4)) === CartesianIndices((3:3,4:4))
    @test (@range CartesianIndex(3,4) ∩ CartesianIndex(3,4)) === CartesianIndices((3:3,4:4))

    # Intersection of CartesianIndices and CartesianIndex
    @test cap(CartesianIndices((2:4, 5:9)), CartesianIndex(3,5)) === CartesianIndices((3:3, 5:5))
    @test (@range CartesianIndices((2:4, 5:9)) ∩ CartesianIndex(3,5)) === CartesianIndices((3:3, 5:5))
    @test cap(CartesianIndices((2:4, 5:9)), CartesianIndex(1,5)) === CartesianIndices((1:0, 5:5))
    @test (@range CartesianIndices((2:4, 5:9)) ∩ CartesianIndex(1,5)) === CartesianIndices((1:0, 5:5))
    @test cap(CartesianIndices((2:4, 5:9)), CartesianIndex(2,3)) === CartesianIndices((2:2, 1:0))
    @test (@range CartesianIndices((2:4, 5:9)) ∩ CartesianIndex(2,3)) === CartesianIndices((2:2, 1:0))

    # Intersection of CartesianIndices
    @test cap(CartesianIndices((2:4, 5:9)), CartesianIndices((0:3, 6:10))) === CartesianIndices((2:3, 6:9))
    @test (@range CartesianIndices((2:4, 5:9)) ∩ CartesianIndices((0:3, 6:10))) === CartesianIndices((2:3, 6:9))

    # Streching.
    @test stretch(7, 11) === -4:18
    @test stretch(Int16(7), Int16(11)) === -4:18
    @test stretch(OneTo(6), 3) === -2:9
    @test stretch(OneTo{Int16}(6), Int16(3)) === -2:9
    @test stretch(7, 3) === 4:10
    @test stretch(7, Int16(3)) === 4:10
    @test_throws ArgumentError stretch(1:3:9, 2)
    @test_throws ArgumentError @range (1:3:9) ± 2
    @test stretch(1:3:14, 6) === -5:3:19
    @test (@range (1:3:14) ± 6) === -5:3:19
    @test stretch(15:-3:-1, 6) === 9:-3:6
    @test (@range (15:-3:-1) ± 6) === 6:3:9
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
    @test_throws ArgumentError shrink(1:3:9, 2)
    @test_throws ArgumentError @range (1:3:9) ∓ 2
    @test shrink(-1:3:15, 6) === 5:3:8
    @test (@range (-1:3:15) ∓ 6) === 5:3:8
    @test shrink(15:-3:-1, 6) === 21:-3:-6
    @test (@range (15:-3:-1) ∓ 6) === -6:3:21
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
