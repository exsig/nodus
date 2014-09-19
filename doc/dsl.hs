




nodus split
   in (a:'a)
  out (a:'a a:'a)
match
  (a) -> (a a)

nodus join
   in (a:'a b:'a)
  out (c:'a)
match
  (a _) -> (a)
  (_ b) -> (b)


nodus terminal
   in (a:'a)
  out (a:'a)
match
  (a) -> (a)
