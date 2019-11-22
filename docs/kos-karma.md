# KosKarma

[Back](/datamaskin/)

See what people or things are popular in your channels or not.

## Commands
- `+1 [object]` Add karma to something.
- `-1 [object]` Remove karma from something.
- `karma_en` Show english text with details about  karma for a object.
- `karma` Show norwegian text with details about karma for a object.
- `karmaprec` Show the same text as the above just with higher
  precision on the calculated total.
- `hikarma`, `high` Show the top scorers in the channel
- `lokarma`, `low` Show the bottom scorers in a channel
- `høy`, `snill` Show the top scorer with norwegian text.
- `lav`, `slem` Show the bottom scorers with norwegian text.
- `rmkarma [object]` An admin kan remove all karma from an object, in case of trolls.

## Listen

This plugin is listening to different things, and will pick up things
like `++object`, `object++` that will heighten the karma of the object
by one. `--object`, `object--` will decrease the karma of an object by
one.

If you don't like the C-style, you can alternatively use Common Lisp
style to increase or decrease the karma of an object, `(incf object)`
and `(decf object)` respectively. `incf` and `decf` can take an
integer argument as last argument, with a max of 3. Example: `(incf
object 3)`

The last way to increase karma is to use latex style
`\addtocounter{object}{number}`, the max here is also 3.
