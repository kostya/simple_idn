# SimpleIdn

SimpleIdn for Crystal language. Translated from Ruby https://github.com/mmriis/simpleidn. 

This shard allows easy conversion from punycode ACE strings to unicode UTF-8 strings and visa versa.

The implementation is heavily based on the RFC3492 C example implementation but simplified since it does not preserve case.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  simple_idn:
    github: kostya/simple_idn
```


## Usage


```crystal
require "simple_idn"

puts SimpleIdn.to_unicode("xn--mllerriis-l8a.com")
# => møllerriis.com

puts SimpleIdn.to_ascii("møllerriis.com")
# => xn--mllerriis-l8a.com
```

