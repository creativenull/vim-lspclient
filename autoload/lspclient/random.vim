vim9script

# Create random strings for tokens
export def RandomStr(length: number = 15): string
  const seed = srand()
  const chars = '0123456789abcdefghijklmnopzrstuvwxyzABCDEFGHIJKLMNOPZRSTUVWXYZ'
  const max = chars->len()
  var result = ''

  for i in range(length)
    result ..= chars[rand(seed) % max]
  endfor

  return result
enddef
