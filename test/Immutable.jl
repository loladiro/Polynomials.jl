using LinearAlgebra

#   compare upto trailing  zeros
function  upto_tz(as, bs)
    n,m = findlast.(!iszero, (as,bs))
    n == m || return false
    isnothing(n) &&  return true
    for i in 1:n
        as[i] != bs[i] && return false
    end
    true
end
==ᵗ⁰(a,b) = upto_tz(a,b)

Ps = (ImmutablePolynomial, Poly, Polynomial)

@testset "Construction" for coeff in [
    Int64[1, 1, 1, 1],
    Float32[1, -4, 2],
    ComplexF64[1 - 1im, 2 + 3im],
    [3 // 4, -2 // 1, 1 // 1]
]

    for P in Ps
        p = P(coeff)
        @test degree(p) == length(coeff) - 1
        @test p.var == :x
        @test length(p) == length(coeff)
        @test eltype(p) == eltype(coeffs(p))
        @test all([-200, -0.3, 1, 48.2] .∈ domain(p))
    end
    
end

@testset "Mapdomain" begin
    for P in Ps
        x = -30:20
        mx = mapdomain(P, x)
        @test mx == x

        x = 0.5:0.01:0.6
        mx = mapdomain(P, x)
        @test mx == x
    end
end

@testset "Other Construction" begin
    for P in (ImmutablePolynomial{10}, Polynomial, Poly)

        # Leading 0s
        p = P([1, 2, 0, 0])
        @test p.coeffs ==ᵗ⁰ [1, 2]

        # different type
        p = Polynomial{Float64}(ones(Int32, 4))
        @test p.coeffs ==ᵗ⁰ ones(Float64, 4)


        p = P(30)
        @test p.coeffs ==ᵗ⁰ [30]

        p = zero(P{Int})
        @test p.coeffs ==ᵗ⁰ [0]

        p = one(P{Int})
        @test p.coeffs ==ᵗ⁰ [1]

        pNULL = P(Int[])
        @test iszero(pNULL)
        @test degree(pNULL) == -1

        p0 = P([0])
        @test iszero(p0)
        @test degree(p0) == -1

        # variable(), P() to generate `x` in given basis
        @test degree(variable(P)) == 1
        @test variable(P)(1) == 1
        @test degree(P()) == 1
        @test P()(1) == 1
        @test variable(P, :y) == P(:y)

    end
end

pNULL = Polynomial(Int[])
p0 = Polynomial([0])
p1 = Polynomial([1,0,0,0,0,0,0,0,0,0,0,0,0,0])
p2 = Polynomial([1,1,0,0])
p3 = Polynomial([1,2,1,0,0,0,0])
p4 = Polynomial([1,3,3,1,0,0])
p5 = Polynomial([1,4,6,4,1,0,0,0,0,0,0,0,0,0,0,0,0,0])
pN = Polynomial([276,3,87,15,24,0])
pR = Polynomial([3 // 4, -2 // 1, 1 // 1])

@testset "Arithmetic" begin

    for  P in Ps
        pNULL = P(Int[])
        p0 = P([0])
        p1 = P([1,0,0,0,0,0,0,0,0,0,0,0,0,0])
        p2 = P([1,1,0,0])
        p3 = P([1,2,1,0,0,0,0])
        p4 = P([1,3,3,1,0,0])
        p5 = P([1,4,6,4,1,0,0,0,0,0,0,0,0,0,0,0,0,0])
        pN = P([276,3,87,15,24,0])
        pR = P([3 // 4, -2 // 1, 1 // 1])
        
    
        @test p3 == P([1,2,1])
        @test pN * 10 == P([2760, 30, 870, 150, 240])
        @test pN / 10.0 == P([27.6, 0.3, 8.7, 1.5, 2.4])
        @test 10 * pNULL + pN == pN
        @test 10 * p0 + pN == pN
        @test p5 + 2 * p1 == P([3,4,6,4,1])
        @test 10 * pNULL - pN == -pN
        @test p0 - pN == -pN
        @test p5 - 2 * p1 == P([-1,4,6,4,1])
        @test p2 * p2 * p2 == p4
        @test p2^4 == p5
        @test pNULL^3 == pNULL
        @test pNULL * pNULL == pNULL
        
        @test pNULL + 2 == p0 + 2 == 2 + p0 == P([2])
        @test p2 - 2 == -2 + p2 == P([-1,1])
        @test 2 - p2 == P([1,-1])

    end
end

@testset "Divrem" begin
    for P in  Ps
        p0 = P([0])
        p1 = P([1])
        p2 = P([5, 6, -3, 2 ,4])
        p3 = P([7, -3, 2, 6])
        p4 = p2 * p3
        @test divrem(p4, p2) == (p3, zero(p3))
        @test p3 % p2 == p3
        @test all((map(abs, (p2 ÷ p3 - Polynomial([1 / 9,2 / 3])).coeffs)) .< eps())
        @test divrem(p0, p1) == (p0, p0)
        @test divrem(p1, p1) == (p1, p0)
        @test divrem(p2, p2) == (p1, p0)
        @test divrem(pR, pR) == (one(pR), zero(pR))
        @test_throws DivideError p1 ÷ p0
        @test_throws DivideError divrem(p0, p0)
    end
end

@testset "Comparisons" begin
    for P in Ps
        pX = P([1, 2, 3, 4, 5])
        pS1 = P([1, 2, 3, 4, 5], "s")
        pS2 = P([1, 2, 3, 4, 5], 's')
        pS3 = P([1, 2, 3, 4, 5], :s)
        @test pX != pS1
        @test pS1 == pS2
        @test pS1 == pS3
        @test_throws ErrorException pS1 + pX
        @test_throws ErrorException pS1 - pX
        @test_throws ErrorException pS1 * pX
        @test_throws ErrorException pS1 ÷ pX
        @test_throws ErrorException pS1 % pX
        
        # Testing copying.
        pcpy1 = P([1,2,3,4,5], :y)
        pcpy2 = copy(pcpy1)
        @test pcpy1 == pcpy2
        
        # Check for isequal
        p1 = P([-0., 5., Inf])
        p2 = P([0., 5., Inf])
        p3 = P([0, NaN])

        @test p1 == p2 && !isequal(p1, p2)
        @test p3 === p3 && p3 ≠ p3 && isequal(p3, p3)
        
        p = fromroots(P, [1,2,3])
        q = fromroots(P, [1,2,3])
        @test hash(p) == hash(q)
        
        p1s = P([1,2], :s)
        p1x = P([1,2], :x)
        p2s = P([1], :s)
        
        @test p1s == p1s
        @test p1s ≠ p1x
        @test p1s ≠ p2s

        @test_throws ErrorException p1s ≈ p1x
        @test p1s ≉ p2s
        @test p1s ≈ P([1,2.], :s)
        
        @test p2s ≈ 1.0 ≈ p2s
        @test p2s == 1.0 == p2s
        @test p2s ≠ 2.0 ≠ p2s
        @test p1s ≠ 2.0 ≠ p1s
        
        @test nnz(map(P, sparse(1.0I, 5, 5))) == 5
        
        @test P([0.5]) + 2 == P([2.5])
        @test 2 - P([0.5]) == P([1.5])
    end
end

@testset "Fitting" begin
    for P in Ps
        xs = range(0, stop = π, length = 10)
        ys = sin.(xs)

        p = fit(P, xs, ys)
        y_fit = p.(xs)
        abs_error = abs.(y_fit .- ys)
        @test maximum(abs_error) <= 0.03

        p = fit(P, xs, ys, 2)
        y_fit = p.(xs)
        abs_error = abs.(y_fit .- ys)
        @test maximum(abs_error) <= 0.03
        
        # Test weighted
        for W in [1, ones(size(xs)), diagm(0 => ones(size(xs)))]
            p = fit(P, xs, ys, 2, weights = W)
            @test p.(xs) ≈ y_fit
        end


        # Getting error on passing Real arrays to polyfit #146
        xx = Real[20.0, 30.0, 40.0]
        yy = Real[15.7696, 21.4851, 28.2463]
        fit(xx, yy, 2)
    end
end

@testset "Values" begin
    for P in Ps
        @test fromroots(P, Int[])(2.) == 1.
        @test pN(-.125) == 276.9609375
        @test pNULL(10) == 0
        @test p0(-10) == 0
        @test fromroots(P, [1 // 2, 3 // 2])(1 // 2) == 0 // 1
        
        # Check for Inf/NaN operations
        p1 = P([Inf, Inf])
        p2 = P([0, Inf])
        @test p1(Inf) == Inf
        @test isnan(p1(-Inf))
        @test isnan(p1(0))
        @test p2(-Inf) == -Inf
        
        # issue #189
        p = P([0,1,2,3])
        A = [0 1; 0  0];
        @test  p(A) == A  + 2A^2 + 3A^3
    end

end

@testset "Conversion" begin
    # unnecessary copy in convert #65
    for P in (Polynomial, Poly)
        p1 = P([1,2])
        p2 = convert(P{Int64}, p1)
        p2[3] = 3
        @test p1[3] == 3

        p = P([0,one(Float64)])
        @test P{Complex{Float64}} == typeof(p + 1im)
        @test P{Complex{Float64}} == typeof(1im - p)
        @test P{Complex{Float64}} == typeof(p * 1im)
    end
end

@testset "Roots" begin
    for P in Ps

        pNULL = P(Int[])
        p0 = P([0])
        p1 = P([1,0,0,0,0,0,0,0,0,0,0,0,0,0])
        p2 = P([1,1,0,0])
        p3 = P([1,2,1,0,0,0,0])
        p4 = P([1,3,3,1,0,0])
        p5 = P([1,4,6,4,1,0,0,0,0,0,0,0,0,0,0,0,0,0])
        pN = P([276,3,87,15,24,0])
        pR = P([3 // 4, -2 // 1, 1 // 1])
        
        # From roots
        r = [2, 3]
        @test fromroots(r) == Polynomial([6, -5, 1])
        p = fromroots(P, r)
        @test p == P([6, -5, 1])
        @test sort(roots(p)) ≈ r
        
        @test roots(p0) == roots(p1) == roots(pNULL) == []
        @test roots(P([0,1,0])) == [0.0]
        r = roots(P([0,1,0]))
        
        @test roots(p2) == [-1]
        a_roots = [c for c in coeffs(copy(pN))]
        @test all(map(abs, sort(roots(fromroots(a_roots))) - sort(a_roots)) .< 1e6)
        @test length(roots(p5)) == 4
        @test roots(pNULL) == []
        @test sort(roots(pR)) == [1 // 2, 3 // 2]
        
        A = [1 0; 0 1]
        @test fromroots(A) == Polynomial(Float64[1, -2, 1])
        p = fromroots(P, A)
        @test p == P(Float64[1, -2, 1])
        @test roots(p) ≈ sort!(eigvals(A), rev = true)
        
        x = variable()
        plarge = 8.362779449448982e41 - 2.510840694154672e57x + 4.2817430781178795e44x^2 - 1.6225927682921337e31x^3 + 1.0x^4  # #120
        @test length(roots(plarge)) == 4
    end
end

@testset "Integrals and Derivatives" begin
    # Integrals derivatives
    for P in Ps

        pNULL = P(Int[])
        p0 = P([0])
        p1 = P([1,0,0,0,0,0,0,0,0,0,0,0,0,0])
        p2 = P([1,1,0,0])
        p3 = P([1,2,1,0,0,0,0])
        p4 = P([1,3,3,1,0,0])
        p5 = P([1,4,6,4,1,0,0,0,0,0,0,0,0,0,0,0,0,0])
        pN = P([276,3,87,15,24,0])
        pR = P([3 // 4, -2 // 1, 1 // 1])

        c = [1, 2, 3, 4]
        p = P(c)
        der = derivative(p)
        @test der.coeffs ==ᵗ⁰ [2, 6, 12]
        int = integrate(der, 1)
        @test int.coeffs ==ᵗ⁰ c
        
        @test derivative(integrate(pN)) == convert(P{Float64}, pN)
        @test derivative(pR) == P([-2 // 1,2 // 1])
        @test derivative(p3) == P([2,2])
        @test derivative(p1) == derivative(p0) == derivative(pNULL) == pNULL
        @test_throws ErrorException derivative(pR, -1)
        @test integrate(pNULL, 1) == convert(P{Float64}, p1)
        @test integrate(P([1,1,0,0]), 0, 2) == 4.0

        if P ∈ (Polynomial, Poly)
            rc = Rational{Int64}[1,2,3]
            @test integrate(P(rc)) == P{eltype(rc)}([0, 1, 1, 1])
        end

        for i in 1:10
            p = P(rand(1:5, 6))
            @test degree(round(p - integrate(derivative(p)), digits=13)) <= 0
            @test degree(round(p - derivative(integrate(p)), digits=13)) <= 0
        end
            
        
        
        # Handling of `NaN`s
        p     = P([NaN, 1, 5])
        pder  = derivative(p)
        pint  = integrate(p)
        
        @test isnan(p(1)) # p(1) evaluates to NaN
        @test isequal(pder, P([NaN]))
        @test isequal(pint, P([NaN]))
        
        pint  = integrate(p, 0.0im)
        @test isequal(pint, P([NaN]))
        
        # Issue with overflow and polyder Issue #159
        @test !iszero(derivative(P(BigInt[0, 1])^100, 100))
    end
end

@testset "Elementwise Operations" begin
    for P in Ps
        p1  = P([1, 2])
        p2  = P([3, 1.])
        p   = [p1, p2]
        q   = [3, p1]
        @test q isa Vector{typeof(p1)}
        @test p isa Vector{typeof(p2)}

        psum  = p .+ 3
        pprod = p .* 3
        pmin  = p .- 3
        @test psum  isa Vector{typeof(p2)}
        @test pprod isa Vector{typeof(p2)}
        @test pmin  isa Vector{typeof(p2)}
    end
end

@testset "Chop and Truncate" begin
    # chop and truncate
    for P in Ps
        p = P([1, 1, 1, 0])
        p = chop(p)
        @test p.coeffs ==ᵗ⁰ [1, 1, 1]
        ## truncation
        p1 = P([1,1] / 10)
        p2 = P([1,2] / 10)
        p3 = P([1,3] / 10)
        psum = p1 + p2 - p3
        @test degree(psum) == 1         # will have wrong degree
        @test degree(truncate(psum)) == 0 # the degree should be correct after truncation
        
        @test truncate(P([2,1]), rtol = 1 / 2, atol = 0) == P([2])
        @test truncate(P([2,1]), rtol = 1, atol = 0)   == P([0])
        @test truncate(P([2,1]), rtol = 0, atol = 1)   == P([2])
        
        pchop = P([1, 2, 3, 0, 0, 0])
        pchopped = chop(pchop)
        @test roots(pchop) == roots(pchopped)
        
        # round
        psmall = P(eps()*rand(1:10,  9))
        @test degree(round(psmall, digits=14)) == -1
        
    end
end

@testset "Linear Algebra" begin
    for P in Ps
        p = P([3, 4])
        @test norm(p) == 5
        p = P([-1, 3, 5, -2])
        @test norm(p) ≈ 6.244997998398398
        p = P([1 - 1im, 2 - 3im])
        p2 = conj(p)
        @test p2.coeffs ==ᵗ⁰ [1 + 1im, 2 + 3im]
        @test transpose(p) == p
        @test transpose!(p) == p
        
        @test norm(P([1., 2.])) == norm([1., 2.])
        @test norm(P([1., 2.]), 1) == norm([1., 2.], 1)
    end
end

@testset "Indexing" begin
    # Indexing
    for P in Ps
        p = P([-1, 3, 5, -2])
        @test p[0] == -1
        @test p[[1, 2]] ==ᵗ⁰ [3, 5]
        @test p[1:2] ==ᵗ⁰ [3, 5]
        @test p[:] ==ᵗ⁰ [-1, 3, 5, -2]

        if P != ImmutablePolynomial
            p1  = Poly([1,2,1])
            p1[5] = 1
            @test p1[5] == 1
            @test p1 == P([1,2,1,0,0,1])
        
            @test p[end] == p.coeffs[end]
            p[1] = 2
            @test p.coeffs[2] == 2
            p[2:3] = [1, 2]
            @test p.coeffs[3:4] == [1, 2]
            p[0:1] = 0
            @test p.coeffs[1:2] == [0, 0]
            p[:] = 1
            @test p.coeffs == ones(4)
            

            p[:] = 0
            @test chop(p) ≈ zero(p)
        end

        p1 = P([1,2,0,3])
        for term in p1
            @test isa(term, P)
        end
        
        @test eltype(p1) == Int
        if P != ImmutablePolynomial
            @test eltype(collect(p1)) == P{Int}
            @test eltype(collect(P{Float64}, p1)) == P{Float64}
            @test_throws InexactError collect(P{Int}, P([1.2]))
        end
        
        @test length(collect(p1)) == degree(p1) + 1
        
        @test [p1[idx] for idx in eachindex(p1)] ==ᵗ⁰ [1,2,0,3]
    end
end

@testset "Copying" begin
    for P in Ps
        pcpy1 = P([1,2,3,4,5], :y)
        pcpy2 = copy(pcpy1)
        @test pcpy1 == pcpy2
    end
end

@testset "GCD" begin
    for P in Ps
        p1 = P([2.,5.,1.])
        p2 = P([1.,2.,3.])
        
        @test degree(gcd(p1, p2)) == 0          # no common roots
        @test degree(gcd(p1, P(5))) == 0          # ditto
        @test degree(gcd(p1, P(eps(0.)))) == 0          # ditto
        @test degree(gcd(p1, P(0))) == degree(p1) # P(0) has the roots of p1
        @test degree(gcd(p1 + p2 * 170.10734737144486, p2)) == 0          # see, c.f., #122
        
        p1 = fromroots(P, [1.,2.,3.])
        p2 = fromroots(P, [1.,2.,6.])
        res = roots(gcd(p1, p2))
        @test 1. ∈ res
        @test 2. ∈ res
    end
end

@testset "Pade" begin
    # exponential
    coeffs = 1 .// BigInt.(gamma.(1:17))
    a = Polynomial(coeffs)
    PQexp = Pade(a, 8, 8)
    @test PQexp(1.0) ≈ exp(1.0)
    @test PQexp(-1.0) ≈ exp(-1.0)
    
    # sine
    coeffs = BigInt.(sinpi.((0:16) ./ 2)) .// BigInt.(gamma.(1:17))
    p = Polynomial(coeffs)
    PQsin = Pade(p, 8, 7)
    @test PQsin(1.0) ≈ sin(1.0)
    @test PQsin(-1.0) ≈ sin(-1.0)
    
    # cosine
    coeffs = BigInt.(sinpi.((1:17) ./ 2)) .// BigInt.(gamma.(1:17))
    p = Polynomial(coeffs)
    PQcos = Pade(p, 8, 8)
    @test PQcos(1.0) ≈ cos(1.0)
    @test PQcos(-1.0) ≈ cos(-1.0)
    
    # summation of a factorially divergent series
    γ = 0.5772156649015
    s = BigInt.(gamma.(BigInt(1):BigInt(61)))
    coeffs = (BigInt(-1)).^(0:60) .* s .// 1
    d = Polynomial(coeffs)
    PQexpint = Pade(d, 30, 30)
    @test Float64(PQexpint(1.0)) ≈ exp(1) * (-γ - sum([(-1)^k / k / gamma(k + 1) for k = 1:20]))
end

@testset "Showing" begin
    p = Polynomial([1, 2, 3])
    @test sprint(show, p) == "Polynomial(1 + 2*x + 3*x^2)"

    p = Polynomial([1.0, 2.0, 3.0])
    @test sprint(show, p) == "Polynomial(1.0 + 2.0*x + 3.0*x^2)"

    p = Polynomial([1 + 1im, -2im])
    @test sprint(show, p) == "Polynomial((1 + 1im) - 2im*x)"

    p = Polynomial{Rational}([1, 4])
    @test sprint(show, p) == "Polynomial(1//1 + 4//1*x)"

    p = Polynomial([1,2,3,1])  # leading coefficient of 1
    @test repr(p) == "Polynomial(1 + 2*x + 3*x^2 + x^3)"
    p = Polynomial([1.0, 2.0, 3.0, 1.0])
    @test repr(p) == "Polynomial(1.0 + 2.0*x + 3.0*x^2 + 1.0*x^3)"
    p = Polynomial([1, im])
    @test repr(p) == "Polynomial(1 + im*x)"
    p = Polynomial([1 + im, 1 - im, -1 + im, -1 - im])# minus signs
    @test repr(p) == "Polynomial((1 + 1im) + (1 - 1im)*x - (1 - 1im)*x^2 - (1 + 1im)*x^3)"
    p = Polynomial([1.0, 0 + NaN * im, NaN, Inf, 0 - Inf * im]) # handle NaN or Inf appropriately
    @test repr(p) == "Polynomial(1.0 + NaN*im*x + NaN*x^2 + Inf*x^3 - Inf*im*x^4)"

    p = Polynomial([1,2,3])

    @test repr("text/latex", p) == "\$1 + 2\\cdot x + 3\\cdot x^{2}\$"
    p = Polynomial([1 // 2, 2 // 3, 1])
    @test repr("text/latex", p) == "\$\\frac{1}{2} + \\frac{2}{3}\\cdot x + x^{2}\$"

    # customized printing with printpoly
    function printpoly_to_string(args...; kwargs...)
        buf = IOBuffer()
        printpoly(buf, args...; kwargs...)
        return String(take!(buf))
    end
    @test printpoly_to_string(Polynomial([1,2,3], "y")) == "1 + 2*y + 3*y^2"
    @test printpoly_to_string(Polynomial([1,2,3], "y"), descending_powers = true) == "3*y^2 + 2*y + 1"
    @test printpoly_to_string(Polynomial([2, 3, 1], :z), descending_powers = true, offset = -2) == "1 + 3*z^-1 + 2*z^-2"
    @test printpoly_to_string(Polynomial([-1, 0, 1], :z), offset = -1, descending_powers = true) == "z - z^-1"
end

@testset "Plotting" begin
    p = fromroots([-1, 1]) # x^2 - 1
    r = -1.4:0.055999999999999994:1.4
    rec = apply_recipe(Dict{Symbol,Any}(), p)
    @test getfield(rec[1], 1) == Dict{Symbol,Any}(:label => "-1 + x^2")
    @test rec[1].args == (r, p.(r))

    r = -1:0.02:1
    rec = apply_recipe(Dict{Symbol,Any}(), p, -1, 1)
    @test getfield(rec[1], 1) == Dict{Symbol,Any}(:label => "-1 + x^2")
    @test rec[1].args == (r, p.(r))

    p = ChebyshevT([1,1,1])
    rec = apply_recipe(Dict{Symbol,Any}(), p)
    r = -1.0:0.02:1.0  # uses domain(p)
    @test rec[1].args == (r, p.(r))

end
