
export For
using Random
import Base

# ForArray

ForArray{D,N,T,F} = ProductMeasure{ReadonlyMappedArray{D, N, T, F}} 

function Base.show(io::IO, d::ForArray{D,N,T,F}) where {D,N,T,F}
    print(io, "For(")
    print(io, d.data.f, ", ")
    print(io, d.data.data, ")")
end

function Base.show(io::IO, d::ForArray{D,N,T,F}) where {D,N,T <: CartesianIndices,F}
    print(io, "For(")
    print(io, d.data.f, ", ")
    join(io, size(d.data), ", ")
    print(io, ")")
end

For(f, dims::AbstractArray...) = ProductMeasure(mappedarray(f, dims...))

For(f, dims::Int...) = ProductMeasure(mappedarray(i -> f(Tuple(i)...), CartesianIndices(dims))) 

function Base.eltype(::ForArray{D,N,T,F}) where {D,N,T,F}
    return eltype(D)
end

basemeasure(μ::ForArray) = @inbounds basemeasure(μ.data[1])^size(μ.data)

# """
#     indexstyle(a::AbstractArray, b::AbstractArray)

# Find the best IndexStyle that works for both `a` and `b`. This will return
# `IndexLinear` if both `a` and `b` support it; otherwise it will fall back on `IndexCartesian`.
# """
# function indexstyle(::A,::B)
#     if IndexStyle(A) == IndexStyle(B) == IndexLinear()
#         return IndexLinear()
#     end

#     return IndexCartesian()
# end

# function Base.rand(rng::AbstractRNG, μ::ForArray{D,N,T,F}) where {F,T<:AbstractArray,D,X}
#     s = size(μ.θ)
#     x = Array{X,length(s)}(undef, s...)
#     rand!(rng, x, μ)
# end

# function logdensity(μ::ForArray{D,N,T,F}, x)
#     getℓ(θⱼ, xⱼ) = logdensity(μ.f(θⱼ), xⱼ)
#     ℓ = mappedarray(getℓ, μ.θ, x)
#     _logdensity(μ, x, indexstyle(μ.θ, x), result_type)
# end

# function _logdensity(μ::ForArray{D,N,T,F}, x, ::IndexLinear, ::Type{R}) where {R<:AbstractFloat}
#     ℓ = zero(R)
#     μ.f(μ.θ)
# end

# function basemeasure(μ::ForArray{D,N,T,F}) where {F,T<:AbstractArray,D,X}

# ForGenerator

ForGenerator{G} = ProductMeasure{G} where {G <: Base.Generator}

For(f, dims::Base.Generator) = ProductMeasure(Base.Generator(f ∘ dims.f, dims.iter))

sampletype(::ForGenerator) = Base.Generator

function Base.rand(rng::AbstractRNG, d::ForGenerator)
    r(x) = rand(rng, x)
    Base.Generator(r ∘ d.data.f, d.data.iter)
end

function MeasureTheory.logdensity(d::ForGenerator, x)
    sum((logdensity(dj, xj) for (dj, xj) in zip(d.data, x)))
end


###############################################################################
# DynamicFor

# A `DynamicFor` is produced when `For` is called on a `DynamicIterator`.

@concrete terse struct DynamicFor <: AbstractMeasure
    f
    iter
end

iterate(iter::DynamicIterator) = dyniterate(iter, nothing)
iterate(iter::DynamicIterator, state) = dyniterate(iter, state)

For(f, it::DynamicIterator) = DynamicFor(f, it)

For(f, it::DynamicFor) = DynamicFor(f, it)

function dyniterate(fr::DynamicFor, state)
      ϕ = dyniterate(fr.iter, state)
      ϕ === nothing && return nothing
      u, state = ϕ
      fr.f(u), state
end