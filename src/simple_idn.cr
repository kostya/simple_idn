module SimpleIdn
  VERSION = "0.1"

  # The ConversionError is raised when an error occurs during a
  # Punycode <-> Unicode conversion.
  class ConversionError < Exception
  end

  module Punycode
    INITIAL_N    =       0x80
    INITIAL_BIAS =         72
    DELIMITER    =    0x2D_u8
    BASE         =         36
    DAMP         =        700
    TMIN         =          1
    TMAX         =         26
    SKEW         =         38
    MAXINT       = 0x7FFFFFFF

    # decode_digit(cp) returns the numeric value of a basic code
    # point (for use in representing integers) in the range 0 to
    # base-1, or base if cp is does not represent a value.
    def self.decode_digit(cp)
      (cp - 48 < 10) ? cp - 22 : ((cp - 65 < 26) ? cp - 65 : ((cp - 97 < 26) ? cp - 97 : BASE))
    end

    # encode_digit(d,flag) returns the basic code point whose value
    # (when used for representing integers) is d, which needs to be in
    # the range 0 to base-1. The lowercase form is used unless flag is
    # nonzero, in which case the uppercase form is used. The behavior
    # is undefined if flag is nonzero and digit d has no uppercase form.
    def self.encode_digit(d)
      d + 22 + 75 * (d < 26 ? 1 : 0)
      #  0..25 map to ASCII a..z or A..Z
      # 26..35 map to ASCII 0..9
    end

    # Bias adaptation function
    def self.adapt(delta, numpoints, firsttime)
      delta = firsttime ? (delta / DAMP) : (delta >> 1)
      delta += (delta / numpoints)

      k = 0
      while delta > (((BASE - TMIN) * TMAX) / 2)
        delta /= BASE - TMIN
        k += BASE
      end
      return k + (BASE - TMIN + 1) * delta / (delta + SKEW)
    end

    # encode_basic(bcp,flag) forces a basic code point to lowercase if flag is zero,
    # uppercase if flag is nonzero, and returns the resulting code point.
    # The code point is unchanged if it is caseless.
    # The behavior is undefined if bcp is not a basic code point.
    def self.encode_basic(bcp, flag)
      bcp -= (bcp - 97 < 26 ? 1 : 0) << 5
      return bcp + ((!flag && (bcp - 65 < 26 ? 1 : 0)) << 5)
    end

    # Main decode
    def self.decode(input)
      output = [] of Char

      # Initialize the state:
      n = INITIAL_N
      i = 0
      bias = INITIAL_BIAS

      # Handle the basic code points: Let basic be the number of input code
      # points before the last delimiter, or 0 if there is none, then
      # copy the first basic code points to the output.
      basic = input.rindex(DELIMITER.chr) || 0

      input.each_byte.each_with_index do |byte, i|
        break if i >= basic
        raise ConversionError.new("Illegal input >= 0x80") if byte >= 0x80
        output << byte.chr # to_utf8_character not needed her because ord < 0x80 (128) which is within US-ASCII.
      end

      # Main decoding loop: Start just after the last delimiter if any
      # basic code points were copied; start at the beginning otherwise.

      ic = basic > 0 ? basic + 1 : 0
      while ic < input.size
        # ic is the index of the next character to be consumed,

        # Decode a generalized variable-length integer into delta,
        # which gets added to i. The overflow checking is easier
        # if we increase i as we go, then subtract off its starting
        # value at the end to obtain delta.
        oldi = i
        w = 1
        k = BASE
        while true
          raise ConversionError.new("punycode_bad_input(1)") if ic >= input.size

          digit = decode_digit(input[ic].ord)
          ic += 1

          raise ConversionError.new("punycode_bad_input(2)") if digit >= BASE

          raise ConversionError.new("punycode_overflow(1)") if digit > (MAXINT - i) / w

          i += digit * w
          t = k <= bias ? TMIN : k >= bias + TMAX ? TMAX : k - bias
          break if digit < t
          raise ConversionError.new("punycode_overflow(2)") if w > MAXINT / (BASE - t)

          w *= BASE - t
          k += BASE
        end

        out1 = output.size + 1
        bias = adapt(i - oldi, out1, oldi == 0)

        # i was supposed to wrap around from out to 0,
        # incrementing n each time, so we'll fix that now:
        raise ConversionError.new("punycode_overflow(3)") if (i / out1) > MAXINT - n

        n += (i / out1)
        i %= out1

        # Insert n at position i of the output:
        output.insert(i, n.chr)
        i += 1
      end

      return output.join
    end

    # Main encode function
    def self.encode(input)
      input = input.chars
      output = [] of UInt8

      # Initialize the state:
      n = INITIAL_N
      delta = 0
      bias = INITIAL_BIAS

      # Handle the basic code points:
      output = input.select do |char|
        char.ord if char.ord < 0x80
      end

      h = b = output.size

      # h is the number of code points that have been handled, b is the
      # number of basic code points

      output << DELIMITER.chr if b > 0

      # Main encoding loop:
      while h < input.size
        # All non-basic code points < n have been
        # handled already. Find the next larger one:

        m = MAXINT

        input.each do |char|
          m = char.ord if char.ord >= n && char.ord < m
        end

        # Increase delta enough to advance the decoder's
        # <n,i> state to <m,0>, but guard against overflow:

        raise ConversionError.new("punycode_overflow (1)") if m - n > ((MAXINT - delta) / (h + 1)).floor

        delta += (m - n) * (h + 1)
        n = m

        input.each_with_index do |char, j|
          if char.ord < n
            delta += 1
            raise ConversionError.new("punycode_overflow(2)") if delta > MAXINT
          end

          if (char.ord == n)
            # Represent delta as a generalized variable-length integer:
            q = delta
            k = BASE
            while true
              t = k <= bias ? TMIN : k >= bias + TMAX ? TMAX : k - bias
              break if q < t
              output << encode_digit(t + (q - t) % (BASE - t)).chr
              q = ((q - t) / (BASE - t)).floor
              k += BASE
            end
            output << encode_digit(q).chr
            bias = adapt(delta, h + 1, h == b)
            delta = 0
            h += 1
          end
        end

        delta += 1
        n += 1
      end
      return output.join
    end
  end

  # Converts a UTF-8 unicode string to a punycode ACE string.
  # == Example
  #   SimpleIDN.to_ascii("møllerriis.com")
  # => "xn--mllerriis-l8a.com"
  def self.to_ascii(domain)
    domain_array = domain.split(".")
    # return domain if domain_array.size == 1
    domain_array.map do |s|
      (s =~ /[^A-Z0-9@\-*_]/i ? "xn--" + Punycode.encode(s) : s).downcase
    end.join(".")
  end

  # Converts a punycode ACE string to a UTF-8 unicode string.
  # == Example
  #   SimpleIDN.to_unicode("xn--mllerriis-l8a.com")
  # => "møllerriis.com"
  def self.to_unicode(domain)
    domain_array = domain.split(".")
    # return domain if domain_array.size == 1
    domain_array.map do |s|
      (s =~ /^xn\-\-/i ? Punycode.decode(s.gsub("xn--", "")) : s)
    end.join(".")
  end
end
