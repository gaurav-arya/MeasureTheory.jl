# Adapted from https://github.com/tpapp/TransformVariables.jl/blob/master/src/special_arrays.jl

export CorrCholesky

"""
    CorrCholesky(n)
Cholesky factor of a correlation matrix of size `n`.
Transforms ``n(n-1)/2`` real numbers to an ``n×n`` lower-triangular matrix `L`, such that
`L*L'` is a correlation matrix (positive definite, with unit diagonal).

# Notes
If
- `z` is a vector of `n` IID standard normal variates,
- `σ` is an `n`-element vector of standard deviations,
- `C` is obtained from `CorrCholesky(n)`,
then `Diagonal(σ) * C.L * z` is a zero-centered multivariate normal variate with the standard deviations `σ` and
correlation matrix `C.L * C.U`.
"""
struct CorrCholesky <: TV.VectorTransform
    n::Int
end

TV.dimension(t::CorrCholesky) = TV.dimension(CorrCholeskyUpper(t.n))

# TODO: For now we just transpose the CorrCholeskyUpper result. We should
# consider whether it can help performance to implement this directly for the
# lower triangular case
function TV.transform_with(flag::TV.LogJacFlag, t::CorrCholesky, x::AbstractVector, index)
    U, ℓ, index = TV.transform_with(flag, CorrCholeskyUpper(t.n), x, index)
    return Cholesky(U, 'U', 0), ℓ, index
end

TV.inverse_eltype(t::CorrCholesky, x::AbstractMatrix) = TV.extended_eltype(x)

TV.inverse_eltype(t::CorrCholesky, x::Cholesky) = TV.extended_eltype(x)

function TV.inverse_at!(x::AbstractVector, index, t::CorrCholesky, L::LowerTriangular)
    return TV.inverse_at!(x, index, CorrCholeskyUpper(t.n), L')
end

function TV.inverse_at!(x::AbstractVector, index, t::CorrCholesky, U::UpperTriangular)
    return TV.inverse_at!(x, index, CorrCholeskyUpper(t.n), U)
end

function TV.inverse_at!(x::AbstractVector, index, t::CorrCholesky, C::Cholesky)
    return TV.inverse_at!(x, index, t, C.UL)
end
