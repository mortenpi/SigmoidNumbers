

#this is a stub function.  It needs to be tested before being officially accepted.
@generated function __round(x::Sigmoid{N, ES, :ubit}, extrabits::(@UInt) = zero(@UInt)) where {N, ES}
  #for convenience, store the type of x as T.
  T = x
  z = zero(@UInt)

  innerbit = one(@UInt) << (__BITS - N)
  checkmask = (-(@UInt)(1)) >> (N)
  blankmask = ~((-(@UInt)(1)) >> N)
  quote
    #take exact zero and exact infinity.
    if (extrabits == zero(@UInt))
      (@u(x) == @signbit) && return reinterpret($T, @signbit)
      (@u(x) == zero(@UInt)) && return reinterpret($T, zero(@UInt))
    end

    truncated_value = @u(x) & $blankmask

    #eliminate values that go towards infinity - as "maxreal"
    (truncated_value == (@signbit) - $innerbit) && return reinterpret($T, truncated_value)
    #eliminate values that go down to infinity.
    (truncated_value == (@signbit)) && return reinterpret($T, truncated_value + $innerbit)
    #eliminate values that go down to zero.
    (truncated_value == zero(@UInt)) && return reinterpret($T, $innerbit)
    #eliminate values that go up to zero.
    (truncated_value == -$innerbit) && return reinterpret($T, -$innerbit)

    #first look to see if the checkbit is set.  If it's zero, round down.
    ($checkmask & @u(x) != $z) && return reinterpret($T, truncated_value | $innerbit)
    return reinterpret($T, truncated_value)
  end
end


#unify the three modes because we'll use the same mode for all of them.
RoundedSigmoid{N,ES} = Union{Sigmoid{N,ES,:upper}, Sigmoid{N,ES,:lower}, Sigmoid{N,ES,:exact}, Sigmoid{N,ES,:outward_exact}, Sigmoid{N,ES,:inward_exact}}
Direct_Sigmoid{N,ES} = Union{Sigmoid{N,ES,:outward_ulp}, Sigmoid{N,ES,:inward_ulp}}

@generated function __round(x::Union{RoundedSigmoid{N, ES}, Direct_Sigmoid{N,ES}}, extrabits::(@UInt) = zero(@UInt)) where {N, ES}
  #for convenience, store the type of x as T.
  T = x
  z = zero(@UInt)

  innerbit = one(@UInt) << (__BITS - N)
  checkmask = (-(@UInt)(1)) >> (N)
  blankmask = ~((-(@UInt)(1)) >> N)
  quote
    #take exact zero and exact infinity.
    if (extrabits == zero(@UInt))
      (@u(x) == @signbit) && return reinterpret($T, @signbit)
      (@u(x) == zero(@UInt)) && return reinterpret($T, zero(@UInt))
    end

    truncated_value = @u(x) & $blankmask

    #eliminate values that go towards infinity - as "maxreal"
    (truncated_value == (@signbit) - $innerbit) && return reinterpret($T, truncated_value)
    #eliminate values that go down to infinity.
    (truncated_value == (@signbit)) && return reinterpret($T, truncated_value + $innerbit)
    #eliminate values that go down to zero.
    (truncated_value == zero(@UInt)) && return reinterpret($T, $innerbit)
    #eliminate values that go up to zero.
    (truncated_value == -$innerbit) && return reinterpret($T, -$innerbit)

    #first look to see if the checkbit is set.  If it's zero, round down.
    ($checkmask & @u(x) != $z) && return reinterpret($T, truncated_value | $innerbit)
    return reinterpret($T, truncated_value)
  end
end

resolve_rounding(x::Sigmoid{N,ES,:lower}) where {N,ES}         = upper_ulp(reinterpret(Sigmoid{N,ES,:ubit}, x))
resolve_rounding(x::Sigmoid{N,ES,:upper}) where {N,ES}         = lower_ulp(reinterpret(Sigmoid{N,ES,:ubit}, x))
resolve_rounding(x::Sigmoid{N,ES,:exact}) where {N,ES}         = reinterpret(Sigmoid{N,ES,:ubit}, x)
resolve_rounding(x::Sigmoid{N,ES,:outward_exact}) where {N,ES} = reinterpret(Sigmoid{N,ES,:ubit}, x)
resolve_rounding(x::Sigmoid{N,ES,:inward_exact}) where {N,ES}  = reinterpret(Sigmoid{N,ES,:ubit}, x)

#special resolve_rounding functions which also must take location into account for the inf/zero values.
@generated function resolve_rounding(x::Sigmoid{N,ES,mode}, ::Type{Val{location}}) where {N,ES,mode,location}
    inf_ulp  = (mode == :outward_ulp) ? :(throw(ArgumentError("an outward ulp cannot be inf"))) : (location == :upper ? :maxpos : :minneg)
    zero_ulp = (mode == :inward_ulp)  ? :(throw(ArgumentError("an inward ulp cannot be zero"))) : (location == :upper ? :maxneg : :minpos)
    negative_ulp = (mode == :outward_ulp) ? :lower_ulp : :upper_ulp
    positive_ulp = (mode == :outward_ulp) ? :upper_ulp : :lower_ulp
    quote
        if !isfinite(x)
            $(inf_ulp)(Vnum{N,ES})
        elseif Base.iszero(x)
            $(zero_ulp)(Vnum{N,ES})
        elseif x < zero(x)
            $(negative_ulp)(reinterpret(Vnum{N,ES},x))
        else
            $(positive_ulp)(reinterpret(Vnum{N,ES},x))
        end
    end
end


→(lower::RoundedSigmoid{N,ES}, upper::RoundedSigmoid{N,ES}) where {N,ES} = resolve_rounding(lower)              → resolve_rounding(upper)
→(lower::RoundedSigmoid{N,ES}, upper::Direct_Sigmoid{N,ES}) where {N,ES} = resolve_rounding(lower)              → resolve_rounding(upper, Val{:upper})
→(lower::Direct_Sigmoid{N,ES}, upper::RoundedSigmoid{N,ES}) where {N,ES} = resolve_rounding(lower, Val{:lower}) → resolve_rounding(upper)
→(lower::Direct_Sigmoid{N,ES}, upper::Direct_Sigmoid{N,ES}) where {N,ES} = resolve_rounding(lower, Val{:lower}) → resolve_rounding(upper, Val{:upper})
