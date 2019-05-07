function Base.convert(::Type{Valid{N,ES}}, f::IEEEFloat) where {N,ES}
  value = Vnum{N, ES}(f)
  Valid{N, ES}(value, value)
end

function Base.convert(::Type{Valid{N,ES}}, i::Signed) where {N,ES}
  value = Vnum{N, ES}(i)
  Valid{N, ES}(value, value)
end

#conversion processes t hat aid and assist in converting Vnums into the appropriate
#type for rounding procedures.

@generated function Base.convert(::Type{Sigmoid{N,ES,:lower}}, v::Vnum{N,ES}) where {N,ES}
  inc = -increment(Sigmoid{N, ES, :lower})
  :(reinterpret(Sigmoid{N,ES,:lower}, @u(v) + isulp(v) * $inc))
end

@generated function Base.convert(::Type{Sigmoid{N,ES,:upper}}, v::Vnum{N,ES}) where {N,ES}
  inc = increment(Sigmoid{N, ES, :upper})
  :(reinterpret(Sigmoid{N,ES,:upper}, @u(v) + isulp(v) * $inc))
end

@generated function Base.convert(::Type{Sigmoid{N,ES,:inner}}, v::Vnum{N,ES}) where {N,ES}
  inc = increment(Sigmoid{N, ES, :inner})
  :(reinterpret(Sigmoid{N,ES,:inner}, @u(v) + (@u(v) > 0) ? (isulp(v) * -$inc) : (isulp(v) * $inc)))
end

@generated function Base.convert(::Type{Sigmoid{N,ES,:outer}}, v::Vnum{N,ES}) where {N,ES}
  inc = increment(Sigmoid{N, ES, :outer})
  :(reinterpret(Sigmoid{N,ES,:outer}, @u(v) + (@u(v) < 0) ? (isulp(v) * -$inc) : (isulp(v) * $inc)))
end
