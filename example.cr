require "./src/simple_idn"

puts SimpleIdn.to_unicode("xn--mllerriis-l8a.com")
# => møllerriis.com

puts SimpleIdn.to_ascii("møllerriis.com")
# => xn--mllerriis-l8a.com
