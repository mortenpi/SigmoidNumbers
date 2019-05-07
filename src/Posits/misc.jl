doc"""
  SigmoidNumbers.find_lsb(p)

  returns the exponent of the least significant bit of the posit.
"""
function find_lsb(p::Posit{N,ES}) where {N,ES}
  (sgn, exp, frc) = posit_components(p)

  exp - (64 - trailing_zeros(frc)) - (sgn && frc != zero(UInt64))

end
