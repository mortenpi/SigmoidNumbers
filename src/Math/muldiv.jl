import Base: *

*(lhs::Bool, rhs::Sigmoid{N, ES, mode}) where {N, ES, mode} = reinterpret(Sigmoid{N, ES, mode}, @s(rhs) * lhs)
*(lhs::Sigmoid{N, ES, mode}, rhs::Bool) where {N, ES, mode} = reinterpret(Sigmoid{N, ES, mode}, @s(lhs) * rhs)

#############################################################################3##
## return types for valid division.

const multiplication_types = Dict((:guess, :guess) => :guess,
                                  (:inward_exact,  :inward_exact)  => :inward_exact,
                                  (:inward_ulp,    :inward_exact)  => :inward_ulp,
                                  (:inward_exact,  :inward_ulp)    => :inward_ulp,
                                  (:inward_ulp,    :inward_ulp)    => :inward_ulp,
                                  (:outward_exact, :outward_exact) => :outward_exact,
                                  (:outward_ulp,   :outward_exact) => :outward_ulp,
                                  (:outward_exact, :outward_ulp)   => :outward_ulp,
                                  (:outward_ulp,   :outward_ulp)   => :outward_ulp)

const nanerror_code = :(throw(NaNError(*, Any[lhs, rhs])))

const multiplication_inf_zero = Dict((:guess,         :guess)         => nanerror_code,
                                     (:inward_exact,  :inward_exact)  => nanerror_code,
                                     (:inward_ulp,    :inward_exact)  => :(zero(Sigmoid{N,ES,:inward_exact})),
                                     (:inward_exact,  :inward_ulp)    => :(Sigmoid{N,ES,:inward_exact}(Inf)),
                                     (:inward_ulp,    :inward_ulp)    => :(zero(Sigmoid{N,ES,:inward_ulp})),
                                     (:outward_exact, :outward_exact) => nanerror_code,
                                     (:outward_ulp,   :outward_exact) => :(zero(Sigmoid{N,ES,:outward_exact})),
                                     (:outward_exact, :outward_ulp)   => :(Sigmoid{N,ES,:outward_exact}(Inf)),
                                     (:outward_ulp,   :outward_ulp)   => :(Sigmoid{N,ES,:outward_ulp}(Inf)))

const multiplication_left_inf = Dict((:guess, :guess)                 => :(Sigmoid{N,ES,:guess}(Inf)),
                                     (:inward_exact,  :inward_exact)  => :(Sigmoid{N,ES,:inward_exact}(Inf)),
                                     (:inward_ulp,    :inward_exact)  => :(Sigmoid{N,ES,:inward_ulp}(Inf)),
                                     (:inward_exact,  :inward_ulp)    => :(Sigmoid{N,ES,:inward_exact}(Inf)),
                                     (:inward_ulp,    :inward_ulp)    => :(Sigmoid{N,ES,:inward_ulp}(Inf)),
                                     (:outward_exact, :outward_exact) => :(Sigmoid{N,ES,:outward_exact}(Inf)),
                                     (:outward_ulp,   :outward_exact) => :(Sigmoid{N,ES,:outward_ulp}(Inf)),
                                     (:outward_exact, :outward_ulp)   => :(Sigmoid{N,ES,:outward_exact}(Inf)),
                                     (:outward_ulp,   :outward_ulp)   => :(Sigmoid{N,ES,:outward_ulp}(Inf)))

const multiplication_left_zero = Dict((:guess,         :guess)         => :(zero(Stype)),
                                      (:inward_exact,  :inward_exact)  => :(zero(Sigmoid{N,ES,:inward_exact})),
                                      (:inward_ulp,    :inward_exact)  => :(zero(Sigmoid{N,ES,:inward_ulp})),
                                      (:inward_exact,  :inward_ulp)    => :(zero(Sigmoid{N,ES,:inward_exact})),
                                      (:inward_ulp,    :inward_ulp)    => :(zero(Sigmoid{N,ES,:inward_ulp})),
                                      (:outward_exact, :outward_exact) => :(zero(Sigmoid{N,ES,:outward_exact})),
                                      (:outward_ulp,   :outward_exact) => :(zero(Sigmoid{N,ES,:outward_ulp})),
                                      (:outward_exact, :outward_ulp)   => :(zero(Sigmoid{N,ES,:outward_exact})),
                                      (:outward_ulp,   :outward_ulp)   => :(zero(Sigmoid{N,ES,:outward_ulp})))

@generated function *(lhs::Sigmoid{N, ES, lhs_mode}, rhs::Sigmoid{N, ES, rhs_mode}) where {N, ES, lhs_mode, rhs_mode}

    #dealing with modes for multiplication
    if !haskey(multiplication_types, (lhs_mode, rhs_mode))

        #inward_exact and outward_exact could be annihilators which makes some processes
        #try to send "incorrect types" to the multiplication algorithm.  This segment
        #of metacode deals with these situations, and creates stub multiplication
        #algorithms which handle these cases.

        rhs_infcheck,rhs_zercheck = (rhs_mode == :inward_exact) || (rhs_mode == :outward_exact) ? (:(!isfinite(rhs)),:(Base.iszero(rhs))) : (:(false), :(false))

        lhs_test = if (lhs_mode == :inward_exact) || (lhs_mode == :outward_exact)
            quote
                if Base.iszero(lhs)
                    $rhs_infcheck && $nanerror_code
                    return zero(Sigmoid{N,ES,:inward_exact})
                end
                if !isfinite(lhs)
                    $rhs_zercheck && $nanerror_code
                    return Sigmoid{N,ES,:outward_exact}(Inf)
                end
            end
        else
            :()
        end

        rhs_test = if (rhs_mode == :inward_exact) || (rhs_mode == :outward_exact)
            quote
                Base.iszero(rhs) && return zero(Sigmoid{N,ES,:inward_exact})
                !isfinite(rhs) && return Sigmoid{N,ES,:outward_exact}(Inf)
            end
        else
            :()
        end

        return quote
            $lhs_test
            $rhs_test
            throw(ArgumentError("incompatible types"))
        end
    end

    #throw(ArgumentError("incompatible types passed to multiplication function! ($lhs_mode, $rhs_mode)"))
    mode = multiplication_types[(lhs_mode, rhs_mode)]
    infzero_code = multiplication_inf_zero[(lhs_mode,rhs_mode)]
    zeroinf_code = multiplication_inf_zero[(rhs_mode,lhs_mode)]
    leftinf_code = multiplication_left_inf[(lhs_mode,rhs_mode)]
    rightinf_code = multiplication_left_inf[(rhs_mode,lhs_mode)]
    leftzero_code = multiplication_left_zero[(lhs_mode,rhs_mode)]
    rightzero_code = multiplication_left_zero[(rhs_mode,lhs_mode)]

    S = Sigmoid{N,ES,mode}

    quote
        Stype = $S
        #multiplying infinities is infinite.
        if !isfinite(lhs)
            (reinterpret((@UInt), rhs) == zero(@UInt)) && return $infzero_code
            return $leftinf_code
        end
        if !isfinite(rhs)
            (reinterpret((@UInt), lhs) == zero(@UInt)) && return $zeroinf_code
            return $rightinf_code
        end
        #mulitplying zeros is zero
        (reinterpret((@UInt), lhs) == zero(@UInt)) && return $leftzero_code
        (reinterpret((@UInt), rhs) == zero(@UInt)) && return $rightzero_code
        return mul_algorithm(lhs, rhs)
    end
end


@generated function mul_algorithm(lhs::Sigmoid{N, ES, lhs_mode}, rhs::Sigmoid{N, ES, rhs_mode}) where {N, ES, lhs_mode, rhs_mode}

    #dealing with modes for multiplication
    haskey(multiplication_types, (lhs_mode, rhs_mode)) || throw(ArgumentError("incompatible types passed to multiplication function!"))
    mode = multiplication_types[(lhs_mode, rhs_mode)]

    S = Sigmoid{N,ES,mode}
    quotemode = QuoteNode(mode)

    quote
        #generate the lhs and rhs subcomponents.
        mode = $quotemode
        @breakdown lhs
        @breakdown rhs
        #sign is the xor of both signs.
        mul_sgn = lhs_sgn ⊻ rhs_sgn
        #the multiplicative exponent is the sum of the two exponents.
        mul_exp = lhs_exp + rhs_exp
        lhs_frc = (lhs_frc >> 1) | (@signbit)
        rhs_frc = (rhs_frc >> 1) | (@signbit)
        #then calculate the fraction.
        mul_frc = demote(promote(lhs_frc) * promote(rhs_frc))
        shift = leading_zeros(mul_frc)
        mul_frc <<= shift + 1
        mul_exp -= (shift - 1)
        __round(build_numeric($S, mul_sgn, mul_exp, mul_frc))
    end
end

################################################################################
## division

const division_types = Dict((:guess, :guess) => :guess,
                            (:exact, :exact) => :exact,  #these three are supported for inverse calculation.
                            (:exact, :upper) => :lower,
                            (:exact, :lower) => :upper,
                            (:inward_exact,  :outward_exact)  => :inward_exact,
                            (:inward_ulp,    :outward_exact)  => :inward_ulp,
                            (:inward_exact,  :outward_ulp)    => :inward_ulp,
                            (:inward_ulp,    :outward_ulp)    => :inward_ulp,
                            (:outward_exact, :inward_exact) => :outward_exact,
                            (:outward_ulp,   :inward_exact) => :outward_ulp,
                            (:outward_exact, :inward_ulp)   => :outward_ulp,
                            (:outward_ulp,   :inward_ulp)   => :outward_ulp)

const division_left_inf = Dict((:guess, :guess)                 => :(Sigmoid{N,ES,:guess}(Inf)),
                               (:exact, :exact)                 => :(Sigmoid{N,ES,:exact}(Inf)),  #these three are supported for inverse calculation.
                               (:exact, :upper)                 => :(Sigmoid{N,ES,:exact}(Inf)),
                               (:exact, :lower)                 => :(Sigmoid{N,ES,:exact}(Inf)),
                               (:inward_exact,  :outward_exact) => :(Sigmoid{N,ES,:inward_exact}(Inf)),
                               (:inward_ulp,    :outward_exact) => :(Sigmoid{N,ES,:inward_ulp}(Inf)),
                               (:inward_exact,  :outward_ulp)   => :(Sigmoid{N,ES,:inward_exact}(Inf)),
                               (:inward_ulp,    :outward_ulp)   => :(Sigmoid{N,ES,:inward_ulp}(Inf)),
                               (:outward_exact, :inward_exact)  => :(Sigmoid{N,ES,:outward_exact}(Inf)),
                               (:outward_ulp,   :inward_exact)  => :(nothing),
                               (:outward_exact, :inward_ulp)    => :(Sigmoid{N,ES,:outward_exact}(Inf)),
                               (:outward_ulp,   :inward_ulp)    => :(nothing))

const division_right_inf = Dict((:guess, :guess)                 => :(zero(Sigmoid{N,ES,:guess})),
                                (:exact, :exact)                 => :(zero(Sigmoid{N,ES,:exact})),  #these three are supported for inverse calculation.
                                (:exact, :upper)                 => :(zero(Sigmoid{N,ES,:lower})),
                                (:exact, :lower)                 => :(zero(Sigmoid{N,ES,:upper})),
                                (:upper, :exact)                 => :(zero(Sigmoid{N,ES,:exact})),
                                (:lower, :exact)                 => :(zero(Sigmoid{N,ES,:exact})),
                                (:inward_exact,  :outward_exact) => :(zero(Sigmoid{N,ES,:inward_exact})),
                                (:inward_ulp,    :outward_exact) => :(zero(Sigmoid{N,ES,:inward_exact})),
                                (:inward_exact,  :outward_ulp)   => :(nothing),
                                (:inward_ulp,    :outward_ulp)   => :(nothing),
                                (:outward_exact, :inward_exact)  => :(zero(Sigmoid{N,ES,:outward_exact})),
                                (:outward_ulp,   :inward_exact)  => :(zero(Sigmoid{N,ES,:outward_exact})),
                                (:outward_exact, :inward_ulp)    => :(zero(Sigmoid{N,ES,:outward_ulp})),
                                (:outward_ulp,   :inward_ulp)    => :(zero(Sigmoid{N,ES,:outward_ulp})))

const division_zero_inf =  Dict((:guess, :guess)                 => :(zero(Sigmoid{N,ES,:guess})),
                                (:exact, :exact)                 => :(zero(Sigmoid{N,ES,:exact})),  #these three are supported for inverse calculation.
                                (:exact, :upper)                 => :(zero(Sigmoid{N,ES,:lower})),
                                (:exact, :lower)                 => :(zero(Sigmoid{N,ES,:upper})),
                                (:upper, :exact)                 => :(zero(Sigmoid{N,ES,:exact})),
                                (:lower, :exact)                 => :(zero(Sigmoid{N,ES,:exact})),
                                (:inward_exact,  :outward_exact) => :(zero(Sigmoid{N,ES,:inward_exact})),
                                (:inward_ulp,    :outward_exact) => :(nothing),
                                (:inward_exact,  :outward_ulp)   => :(zero(Sigmoid{N,ES,:inward_exact})),
                                (:inward_ulp,    :outward_ulp)   => :(nothing),
                                (:outward_exact, :inward_exact)  => :(zero(Sigmoid{N,ES,:inward_exact})),
                                (:outward_ulp,   :inward_exact)  => :(zero(Sigmoid{N,ES,:outward_exact})),
                                (:outward_exact, :inward_ulp)    => :(zero(Sigmoid{N,ES,:outward_exact})),
                                (:outward_ulp,   :inward_ulp)    => :(zero(Sigmoid{N,ES,:outward_ulp})))


const division_both_inf = Dict((:guess, :guess)                 => :(throw(NaNError(/,[lhs, rhs]))),
                               (:exact, :exact)                 => :(throw(NaNError(/,[lhs, rhs]))),  #these three are supported for inverse calculation.
                               (:exact, :upper)                 => :(Sigmoid{N,ES,:exact}(Inf)),
                               (:exact, :lower)                 => :(Sigmoid{N,ES,:exact}(Inf)),
                               (:upper, :exact)                 => :(zero(Sigmoid{N,ES,:exact})),
                               (:lower, :exact)                 => :(zero(Sigmoid{N,ES,:exact})),
                               (:inward_exact,  :outward_exact) => :(throw(NaNError(/,[lhs, rhs]))),
                               (:inward_ulp,    :outward_exact) => :(zero(Sigmoid{N,ES,:inward_exact})),
                               (:inward_exact,  :outward_ulp)   => :(Sigmoid{N,ES,:inward_exact}(Inf)),
                               (:inward_ulp,    :outward_ulp)   => :(nothing),
                               (:outward_exact, :inward_exact)  => :(throw(NaNError(/,[lhs, rhs]))),
                               (:outward_ulp,   :inward_exact)  => :(zero(Sigmoid{N,ES,:outward_exact})),
                               (:outward_exact, :inward_ulp)    => :(Sigmoid{N,ES,:outward_exact}(Inf)),
                               (:outward_ulp,   :inward_ulp)    => :(nothing))

const division_both_zero = Dict((:guess, :guess)                 => :(throw(NaNError(/,[lhs, rhs]))),
                                (:exact, :exact)                 => :(throw(NaNError(/,[lhs, rhs]))),  #these three are supported for inverse calculation.
                                (:upper, :exact)                 => :(Sigmoid{N,ES,:exact}(Inf)),
                                (:lower, :exact)                 => :(Sigmoid{N,ES,:exact}(Inf)),
                                (:exact, :upper)                 => :(zero(Sigmoid{N,ES,:exact})),
                                (:exact, :lower)                 => :(zero(Sigmoid{N,ES,:exact})),
                                (:inward_exact,  :outward_exact) => :(throw(NaNError(/,[lhs, rhs]))),
                                (:inward_ulp,    :outward_exact) => :(Sigmoid{N,ES,:inward_exact}(Inf)),
                                (:inward_exact,  :outward_ulp)   => :(zero(Sigmoid{N,ES,:inward_exact})),
                                (:inward_ulp,    :outward_ulp)   => :(nothing),
                                (:outward_exact, :inward_exact)  => :(throw(NaNError(/,[lhs, rhs]))),
                                (:outward_ulp,   :inward_exact)  => :(Sigmoid{N,ES,:outward_exact}(Inf)),
                                (:outward_exact, :inward_ulp)    => :(zero(Sigmoid{N,ES,:outward_exact})),
                                (:outward_ulp,   :inward_ulp)    => :(nothing))

const division_left_zero = Dict((:guess, :guess)                 => :(zero(Sigmoid{N,ES,:guess})),
                                (:exact, :exact)                 => :(zero(Sigmoid{N,ES,:exact})),  #these three are supported for inverse calculation.
                                (:exact, :upper)                 => :(zero(Sigmoid{N,ES,:exact})),
                                (:exact, :lower)                 => :(zero(Sigmoid{N,ES,:exact})),
                                (:upper, :exact)                 => :(zero(Sigmoid{N,ES,:upper})),
                                (:lower, :exact)                 => :(zero(Sigmoid{N,ES,:lower})),
                                (:inward_exact,  :outward_exact) => :(zero(Sigmoid{N,ES,:inward_exact})),
                                (:inward_ulp,    :outward_exact) => :(nothing),
                                (:inward_exact,  :outward_ulp)   => :(zero(Sigmoid{N,ES,:inward_exact})),
                                (:inward_ulp,    :outward_ulp)   => :(nothing),
                                (:outward_exact, :inward_exact)  => :(zero(Sigmoid{N,ES,:outward_exact})),
                                (:outward_ulp,   :inward_exact)  => :(zero(Sigmoid{N,ES,:outward_ulp})),
                                (:outward_exact, :inward_ulp)    => :(zero(Sigmoid{N,ES,:outward_exact})),
                                (:outward_ulp,   :inward_ulp)    => :(zero(Sigmoid{N,ES,:outward_ulp})))

const division_right_zero = Dict((:guess, :guess)                 => :(Sigmoid{N,ES,:guess}(Inf)),
                                 (:exact, :exact)                 => :(Sigmoid{N,ES,:exact}(Inf)),  #these three are supported for inverse calculation.
                                 (:exact, :upper)                 => :(Sigmoid{N,ES,:lower}(Inf)),
                                 (:exact, :lower)                 => :(Sigmoid{N,ES,:upper}(Inf)),
                                 (:upper, :exact)                 => :(Sigmoid{N,ES,:exact}(Inf)),
                                 (:lower, :exact)                 => :(Sigmoid{N,ES,:exact}(Inf)),
                                 (:inward_exact,  :outward_exact) => :(Sigmoid{N,ES,:inward_exact}(Inf)),
                                 (:inward_ulp,    :outward_exact) => :(Sigmoid{N,ES,:inward_exact}(Inf)),
                                 (:inward_exact,  :outward_ulp)   => :(Sigmoid{N,ES,:inward_ulp}(Inf)),
                                 (:inward_ulp,    :outward_ulp)   => :(Sigmoid{N,ES,:inward_ulp}(Inf)),
                                 (:outward_exact, :inward_exact)  => :(Sigmoid{N,ES,:outward_exact}(Inf)),
                                 (:outward_ulp,   :inward_exact)  => :(Sigmoid{N,ES,:outward_exact}(Inf)),
                                 (:outward_exact, :inward_ulp)    => :(nothing),
                                 (:outward_ulp,   :inward_ulp)    => :(nothing))


@generated function Base.:/(lhs::Sigmoid{N,ES,lhs_mode}, rhs::Sigmoid{N,ES,rhs_mode}) where {N,ES,lhs_mode,rhs_mode}
     if !haskey(division_types, (lhs_mode, rhs_mode))
        #inward_exact and outward_exact could be annihilators which makes some processes
        #try to send "incorrect types" to the division algorithm.  This segment
        #of metacode deals with these situations, and creates stub division
        #algorithms which handle these cases.

        rhs_infcheck,rhs_zercheck = (rhs_mode == :inward_exact) || (rhs_mode == :outward_exact) ? (:(!isfinite(rhs)),:(Base.iszero(rhs))) : (:(false), :(false))

        lhs_test = if (lhs_mode == :inward_exact) || (lhs_mode == :outward_exact)
            quote
                if Base.iszero(lhs)
                    $rhs_zercheck && $nanerror_code
                    return zero(Sigmoid{N,ES,:inward_exact})
                end
                if !isfinite(lhs)
                    $rhs_infcheck && $nanerror_code
                    return Sigmoid{N,ES,:outward_exact}(Inf)
                end
            end
        else
            :()
        end

        rhs_test = if (rhs_mode == :inward_exact) || (rhs_mode == :outward_exact)
            quote
                Base.iszero(rhs) && return Sigmoid{N,ES,:outward_exact}(Inf)
                !isfinite(rhs) && return zero(Sigmoid{N,ES,:inward_exact})
            end
        else
            :()
        end

        return quote
            $lhs_test
            $rhs_test
            throw(ArgumentError("incompatible types"))
        end
    end

    mode = division_types[(lhs_mode, rhs_mode)]
    quotemode = QuoteNode(mode)

    #specialized code for certain results
    division_left_inf_code  = division_left_inf[(lhs_mode, rhs_mode)]
    division_right_inf_code = division_right_inf[(lhs_mode, rhs_mode)]
    division_both_inf_code  = division_both_inf[(lhs_mode, rhs_mode)]
    division_both_zero_code = division_both_zero[(lhs_mode, rhs_mode)]
    division_left_zero_code = division_left_zero[(lhs_mode, rhs_mode)]
    division_right_zero_code = division_right_zero[(lhs_mode, rhs_mode)]
    division_zero_inf_code  = division_zero_inf[(lhs_mode, rhs_mode)]

    #calculate the number of rounds we should apply the goldschmidt method.
    rounds = Int(ceil(log(2,N))) + 1
    top_bit = promote(one(@UInt) << (__BITS - 1))
    bot_bit = (one(@UInt) << (__BITS - N - 1))

    quote
        mode = $quotemode
        #ZERO AND INFINITY EXCEPTION CASES.

        #dividing infinities or by zero is infinite.
        if !isfinite(lhs)
            isfinite(rhs) || return $division_both_inf_code
            return $division_left_inf_code
        end

        if rhs == zero(Sigmoid{N, ES, rhs_mode})
            (lhs == zero(Sigmoid{N, ES, lhs_mode})) && return $division_both_zero_code
            return $division_right_zero_code
        end

        #dividing zeros or by infinity is zero
        if !isfinite(rhs)
            Base.iszero(lhs) || return $division_right_inf_code
            return $division_zero_inf_code
        end

        lhs == zero(Sigmoid{N, ES, lhs_mode}) && return $division_left_zero_code

    cq_mask = promote(-one(@UInt))

    #generate the lhs and rhs subcomponents.  Unlike multiplication, however,
    #we want there to 'always be a hidden bit', so we should use the "numeric" method.
    @breakdown lhs numeric
    @breakdown rhs numeric

    #sign is the xor of both signs.
    div_sgn = lhs_sgn ⊻ rhs_sgn

    #do something different if rhs_frc is zero (aka power of two)
    if rhs_frc == 0
      div_exp = lhs_exp - rhs_exp
      return __round(build_numeric(Sigmoid{N, ES, mode}, div_sgn, div_exp, lhs_frc))
    end

    #the multiplicative exponent is the product of the two exponents.
    div_exp = lhs_exp - rhs_exp - 1

    #calculate the number of zeros in the solution.
    lhs_zeros = trailing_zeros(lhs_frc) - (__BITS - N)
    rhs_zeros = trailing_zeros(rhs_frc) - (__BITS - N)

    cumulative_quotient = promote(lhs_frc)
    cumulative_zpower   = promote(-rhs_frc) >> 1
    power_gain = 0

    #then calculate the fraction, using binomial goldschmidt.
    # binomial goldschmidt algorithm:  x ∈ [1, 2), y ∈ [0.5, 1)
    #   define z ≡ 1 - y ⇒ y == 1 - z.
    #   Note (1 - z)(1 + z)(1 + z^2)(1 + z^4) == (1 - z^2n) → 1
    for rd = 1:($rounds - 1)
      #update the quotient
      cumulative_quotient += ((cumulative_quotient * cumulative_zpower) >> __BITS) + cumulative_zpower
      cumulative_zpower = (cumulative_zpower ^ 2) >> __BITS
      shift = __BITS - leading_zeros(cumulative_quotient)
      if (shift > 0)
        cumulative_quotient &= cq_mask
        cumulative_quotient >>= 1
        power_gain += 1
        (shift == 2) && (cumulative_quotient |= $top_bit)
      end
    end
    #update the cumulative quotient one last time.
    cumulative_quotient += ((cumulative_quotient * cumulative_zpower) >> __BITS) + cumulative_zpower
    shift = __BITS - leading_zeros(cumulative_quotient)
    if (shift > 0)
      cumulative_quotient &= cq_mask
      cumulative_quotient >>= 1
      power_gain += 1
      (shift == 2) && (cumulative_quotient |= $top_bit)
    end

    div_frc = demoteright(cumulative_quotient)


    result_ones = trailing_ones(div_frc >> (__BITS - N))

    if (lhs_zeros + N + (result_ones != N) == result_ones + rhs_zeros)
      #increment the lowest bit
      div_frc += $bot_bit
      #mask out all the other ones that were trailing.
      div_frc &= -$bot_bit

      #bump it if we triggered a carry.
      power_gain += (div_frc == 0)
    end

    __round(build_numeric(Sigmoid{N, ES, mode}, div_sgn, div_exp + power_gain, div_frc))
  end
end

Base.inv(x::Sigmoid{N,ES,mode}) where {N,ES,mode} = one(Sigmoid{N,ES,mode}) / x
Base.inv(x::Sigmoid{N,ES,:lower}) where {N,ES} = one(Sigmoid{N,ES,:exact}) / x
Base.inv(x::Sigmoid{N,ES,:upper}) where {N,ES} = one(Sigmoid{N,ES,:exact}) / x
