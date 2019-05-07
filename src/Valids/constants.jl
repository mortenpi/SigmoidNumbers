
Base.one(T::Type{Valid{N,ES}}) where {N,ES} = Valid(one(Vnum{N,ES}), one(Vnum{N,ES}))
Base.zero(T::Type{Valid{N,ES}}) where {N,ES} = Valid(zero(Vnum{N,ES}), zero(Vnum{N,ES}))

mutable struct ∅; end
mutable struct ℝ; end
mutable struct ℝp; end

Base.convert(T::Type{Valid{N, ES}}, ::Type{∅}) where {N, ES}  = Valid(zero(     Vnum{N,ES}), maxneg( Vnum{N,ES}))
Base.convert(T::Type{Valid{N, ES}}, ::Type{ℝ}) where {N, ES}  = Valid(-maxpos( Vnum{N,ES}), maxpos(      Vnum{N,ES}))
Base.convert(T::Type{Valid{N, ES}}, ::Type{ℝp}) where {N, ES} = Valid(Vnum{N,ES}(Inf),       maxpos(      Vnum{N,ES}))

mutable struct __plusstar; end
Base.:+(::typeof(Base.:*)) = __plusstar
mutable struct __minusstar; end
Base.:-(::typeof(Base.:*)) = __minusstar
mutable struct __positives; end
mutable struct __negatives; end

ℝ(::Type{__plusstar}) =      __plusstar
ℝ(::Type{__minusstar}) =     __minusstar
ℝ(::typeof(+)) =             __positives
ℝ(::typeof(-)) =             __negatives

Base.convert(T::Type{Valid{N,ES}}, ::Type{__plusstar}) where {N,ES} =  Valid(minpos(Vnum{N, ES}),  maxpos(Vnum{N, ES}))
Base.convert(T::Type{Valid{N,ES}}, ::Type{__minusstar}) where {N,ES} = Valid(-maxpos(Vnum{N, ES}), maxneg(Vnum{N, ES}))
Base.convert(T::Type{Valid{N,ES}}, ::Type{__positives}) where {N,ES} = Valid(zero(Vnum{N, ES}),          maxpos(Vnum{N, ES}))
Base.convert(T::Type{Valid{N,ES}}, ::Type{__negatives}) where {N,ES} = Valid(-maxpos(Vnum{N, ES}),         zero(Vnum{N, ES}))

export ∅, ℝ, ℝp
