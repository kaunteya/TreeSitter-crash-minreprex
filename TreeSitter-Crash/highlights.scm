; highlights.scm

(pair
  key: (_) @keyword
)

; Primitive values
(pair
  value: (string) @value.string ; String that is value against a key
)
(array (string) @value.string) ;String that is an array element
(number) @value.number
(null) @value.null

; Booleans
[
  (true)
  (false)
] @value.bool


; Brackets
[
  "{"
  "}"
  "["
  "]"
] @punctuation.bracket

; Delimiters
[
  ":"
  ","
] @punctuation.delimiter

(ERROR) @error
