# Rex Replace

[Back](/datamaskin/)

Use regular expressions to correct your self or others.

## Listen

`s/<reg-expr>/<replacement>/` Replaces the first line that matches the
reg-expr with the replacement. It will first try to replace your last
line, but if none of them matches it will try to replace the last
sentences said by others.

Examples:
- `s/dgo/dog/` => dog
- `s/(bar)(foo)/\2\1/` => foobar
