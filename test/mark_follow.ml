let () =
  let x = Ancient.mark "foo" in
  let y = Ancient.follow x in
  assert (String.equal y "foo")
