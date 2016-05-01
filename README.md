# SimpleIdn

SimpleIdn Crystal language. Translated from Ruby https://github.com/mmriis/simpleidn. 

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

