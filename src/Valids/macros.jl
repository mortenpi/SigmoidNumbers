
#these four macros convert the Vnum value into the appropriate type of rounding
#sigmoid by calling the call constructors which are designed to handle bumping
#up or down the ubit.

typeas(value::Valid{N,ES}, stype::Symbol) where {N,ES} = Sigmoid{N,ES,stype}
Base.:~(value::Valid{N,ES}, stype::Symbol) where {N,ES} = typeas(value, stype)

macro upper(value)
  esc(:(isulp(($value).upper) ? reinterpret(($value ~ :upper), ($value).upper |> lub) : reinterpret(($value ~ :exact), ($value).upper)))
end

macro lower(value)
  esc(:(isulp(($value).lower) ? reinterpret(($value ~ :lower), ($value).lower |> glb) : reinterpret(($value ~ :exact), ($value).lower)))
end

macro exact(value)
  esc(:(reinterpret(($value ~ :exact), ($value).lower)))
end


"""
    SigmoidNumbers.@d_lower(value)

retrieves a directionally typecast lower value.  This could be typecast as one
of: :inward_exact, :inward_ulp, :outward_exact, :outward_ulp, depending on
the nature of the values.

#Examples

"""
macro d_lower(value)
    esc(quote
        if Base.iszero($value.lower)
            Base.iszero($value.upper) ? zero($value ~ :inward_exact)                            : zero($value ~ :outward_exact)
        elseif !isfinite($value.lower)
            isfinite($value.upper)    ? reinterpret(($value ~ :inward_exact), $value.lower)     : reinterpret(($value ~ :outward_exact), $value.lower)
        elseif ($value.lower < zero($value ~ :ubit))
            isulp($value.lower)       ? reinterpret(($value ~ :inward_ulp),  glb($value.lower)) : reinterpret(($value ~ :inward_exact),  $value.lower)
        else
            isulp($value.lower)       ? reinterpret(($value ~ :outward_ulp), glb($value.lower)) : reinterpret(($value ~ :outward_exact), $value.lower)
        end
    end)
end

macro d_upper(value)
    esc(quote
        if Base.iszero($value.upper)
            Base.iszero($value.lower) ? zero($value ~ :inward_exact)                            : zero($value ~ :outward_exact)
        elseif !isfinite($value.upper)
            isfinite($value.lower)    ? reinterpret(($value ~ :inward_exact), $value.upper)     : reinterpret(($value ~ :outward_exact), $value.upper)
        elseif ($value.upper < zero($value ~ :ubit))
            isulp($value.upper)       ? reinterpret(($value ~ :outward_ulp), lub($value.upper)) : reinterpret(($value ~ :outward_exact), $value.upper)
        else
            isulp($value.upper)       ? reinterpret(($value ~ :inward_ulp),  lub($value.upper)) : reinterpret(($value ~ :inward_exact),  $value.upper)
        end
    end)
end


recast_as_lower(x::Sigmoid{N,ES,:exact}) where {N,ES} = x
recast_as_lower(x::Sigmoid{N,ES,:lower}) where {N,ES} = x
recast_as_lower(x::Sigmoid{N,ES,:cross}) where {N,ES} = reinterpret(Sigmoid{N,ES,:lower}, x)
recast_as_lower(x::Sigmoid{N,ES,:upper}) where {N,ES} = reinterpret(Sigmoid{N,ES,:lower}, x)
macro rl(value)
  esc(:(recast_as_lower($value)))
end

recast_as_upper(x::Sigmoid{N,ES,:exact}) where {N,ES} = x
recast_as_upper(x::Sigmoid{N,ES,:upper}) where {N,ES} = x
recast_as_upper(x::Sigmoid{N,ES,:cross}) where {N,ES} = reinterpret(Sigmoid{N,ES,:upper}, x)
recast_as_upper(x::Sigmoid{N,ES,:lower}) where {N,ES} = reinterpret(Sigmoid{N,ES,:upper}, x)
macro ru(value)
  esc(:(recast_as_upper($value)))
end
