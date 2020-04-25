export   SparsePolynomial

"""
    SparsePolynomial(coeffs::Dict, var)

Polynomials in the standard basis backed by a dictionary holding the non-zero coefficients. For
polynomials of high degree, this might be advantageous.
Addition and multiplication with constant polynomials are treated as symboless.

Examples:

```jldoctest
julia> using Polynomials

julia> P  = SparsePolynomial
SparsePolynomial

julia> p,q = P([1,2,3]), P([4,3,2,1])
(SparsePolynomial(1 + 2*x + 3*x^2), SparsePolynomial(4 + 3*x + 2*x^2 + x^3))

julia> p+q
SparsePolynomial(5 + 5*x + 5*x^2 + x^3)

julia> p*q
SparsePolynomial(4 + 11*x + 20*x^2 + 14*x^3 + 8*x^4 + 3*x^5)

julia> p+1
SparsePolynomial(2 + 2*x + 3*x^2)

julia> q*2
SparsePolynomial(8 + 6*x + 4*x^2 + 2*x^3)

julia> p = Polynomials.basis(P, 10^9) - Polynomials.basis(P,0) # also P(Dict(0=>-1, 10^9=>1))
SparsePolynomial(-1.0 + 1.0*x^1000000000)

julia> p(1)
0.0
```

"""
mutable struct SparsePolynomial{T <: Number} <: StandardBasisPolynomial{T}
    coeffs::Dict{Int, T}
    var::Symbol
    function SparsePolynomial{T}(coeffs::Dict{Int, T}, var::Symbol) where {T <: Number}

        for (k,v)  in coeffs
            iszero(v) && pop!(coeffs,  k)
        end
        
        new{T}(coeffs, var)
        
    end
    function SparsePolynomial{T}(coeffs::AbstractVector{T}, var::Symbol) where {T <: Number}

        last_nz = findlast(!iszero, coeffs)

        D = Dict{Int,T}()
        if last_nz != nothing
            for i in 1:last_nz
                if !iszero(coeffs[i])
                    D[i-1] = coeffs[i]
                end
            end
        end
        
        return new{T}(D, var)
        
    end
end

@register SparsePolynomial

function SparsePolynomial(coeffs::Dict{Int, T}, var::Symbol) where {T <: Number}
    SparsePolynomial{T}(coeffs, var)
end
function SparsePolynomial(coeffs::AbstractVector{T}, var::Symbol) where {T <: Number}
    SparsePolynomial{T}(coeffs, var)
end

# conversion
function Base.convert(P::Type{<:Polynomial}, q::SparsePolynomial)
    ⟒(P)(coeffs(q), q.var)
end

function Base.convert(P::Type{<:SparsePolynomial}, q::StandardBasisPolynomial{T}) where {T}
    R = promote(eltype(P), T)
    ⟒(P){R}(coeffs(q), q.var)
end

## changes to common
degree(p::SparsePolynomial) = isempty(p.coeffs) ? -1 : maximum(keys(p.coeffs))
basis(P::Type{<:SparsePolynomial}, n::Int, var=:x) =
    SparsePolynomial(Dict(n=>one(eltype(one(P)))), var)

# return coeffs as  a vector
# use p.coeffs to get Dictionary
function  coeffs(p::SparsePolynomial{T})  where {T}

    n = degree(p)
    cs = zeros(T, n+1)
    for (k,v) in p.coeffs
        cs[k+1]=v
    end
    cs
    
end

# get/set index
function Base.getindex(p::SparsePolynomial{T}, idx::Int) where {T <: Number}
    get(p.coeffs, idx, zero(T))
end

function Base.setindex!(p::SparsePolynomial, value::Number, idx::Int)
    idx < 0  && return p
    if iszero(value)
        haskey(p.coeffs, idx) && pop!(p.coeffs, idx)
    else
        p.coeffs[idx]  = value
    end
    return p
end


Base.firstindex(p::SparsePolynomial) = sort(collect(keys(p.coeffs)), by=x->x[1])[1]
Base.lastindex(p::SparsePolynomial) = sort(collect(keys(p.coeffs)), by=x->x[1])[end]
Base.eachindex(p::SparsePolynomial) = sort(collect(keys(p.coeffs)), by=x->x[1])

# only from tail
function chop!(p::SparsePolynomial{T};
               rtol::Real = Base.rtoldefault(real(T)),
               atol::Real = 0,) where {T}

    for k in sort(collect(keys(p.coeffs)), by=x->x[1], rev=true)
        if isapprox(p[k], zero(T); rtol = rtol, atol = atol)
            pop!(p.coeffs, k)
        else
            return p
        end
    end
    
    return p
    
end

function truncate!(p::SparsePolynomial{T};
                   rtol::Real = Base.rtoldefault(real(T)),
                   atol::Real = 0,) where {T}
    
    max_coeff = maximum(abs, coeffs(p))
    thresh = max_coeff * rtol + atol

    for (k,val) in  p.coeffs
        if abs(val) <= thresh
            pop!(p.coeffs,k)
        end
    end
    
    return p
    
end

##
## ----
##
    
# ignore variaible of  constants for `+` or `*`
function _promote_constant_variable(p::P, q::Q) where {P<:SparsePolynomial, Q<:SparsePolynomial}
    
    if  degree(p) <= 0
        p  = P(p.coeffs, q.var)
    elseif degree(q) <= 0
        q  = Q(q.coeffs, p.var)
    end
    
    return p,q
    
end

function (p::SparsePolynomial{T})(x::S) where {T,S}
    
    tot = zero(T)*one(eltype(x))
    for (k,v) in p.coeffs
        tot = _muladd(x^k, v, tot)
    end
    
    return tot
    
end


   
function Base.:+(p1::SparsePolynomial{T}, p2::SparsePolynomial{S}) where {T, S}

    p1,p2 = _promote_constant_variable(p1, p2) ## check degree 0 or 1
    p1.var != p2.var && error("SparsePolynomials must have same variable")

    R = promote_type(T,S)
    P = SparsePolynomial

    p = zero(P{R}, p1.var)
    for i in union(keys(p1.coeffs), keys(p2.coeffs))
        p[i] = p1[i] + p2[i]
    end

    return  p

end

function Base.:+(p::SparsePolynomial{T}, c::S) where {T, S <: Number}

    R = promote_type(T,S)
    P = SparsePolynomial
    
    q = zero(P{R}, p.var)
    for (k,v) in p.coeffs
        q[k] = R(v)
    end
    q[0] = q[0] + c

    return q
end

function Base.:*(p1::SparsePolynomial{T}, p2::SparsePolynomial{S}) where {T,S}

    p1, p2 = _promote_constant_variable(p1, p2)
    p1.var != p2.var && error("SparsePolynomials must have same variable")

    R = promote_type(T,S)
    P = SparsePolynomial
    
    p  = zero(P{R},  p1.var)
    for  (k1, v1)  in p1.coeffs
        for  (k2, v2) in  p2.coeffs
            p[k1+k2] = muladd(v1, v2, p[k1+k2])
        end
    end
    
    return p
    
end


function Base.:*(p::SparsePolynomial{T}, c::S) where {T, S}

    R = promote_type(T,S)
    P = SparsePolynomial

    q  = zero(P{R},  p.var)
    for (k,v) in p.coeffs
        q[k] = v * c
    end
    
    return q
end



function derivative(p::SparsePolynomial{T}, order::Integer = 1) where {T}
    
    order < 0 && error("Order of derivative must be non-negative")
    order == 0 && return p

    R = eltype(one(T)/1)
    P = SparsePolynomial
    hasnan(p) && return P(Dict(0 => R(NaN)), p.var)

    n = degree(p)
    order > n && return zero(P{R}, p.var)

    dpn = zero(P{R}, p.var)
    @inbounds for (k,val) in p.coeffs
        dpn[k-order] = prod(j for j in k:k-order+1)  * val
    end

    return dpn

end


function integrate(p::SparsePolynomial{T}, k::S) where {T, S<:Number}
    
    R = eltype((one(T)+one(S))/1)
    P = SparsePolynomial

    if hasnan(p) || isnan(k)
        return P(Dict(0 => NaN), p.var) # not R(NaN)!! don't like XXX
    end

    ∫p = P{R}(R(k), p.var)
    for (k,val) in p.coeffs
        ∫p[k + 1] = val / (k+1)
    end
    
    return ∫p
    
end
