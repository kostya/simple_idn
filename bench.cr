require "./src/simple_idn"

# puts SimpleIdn.to_unicode("xn--mllerriis-l8a.com")
# puts SimpleIdn.to_ascii("møllerriis.com")

puts "to_unicode"
t = Time.now
str = "xn--mllerriis-l8a.com"
s = 0
500000.times do
  s += SimpleIdn.to_unicode(str).bytesize
end
p s
p Time.now - t

puts "to_ascii"
t = Time.now
str = "møllerriis.com"
s = 0
500000.times do
  s += SimpleIdn.to_ascii(str).bytesize
end
p s
p Time.now - t
