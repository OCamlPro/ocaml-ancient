let () =
  match Sys.argv.(1) with
  | "Unix" ->
      Format.printf
        "(-DOS_TYPE_UNIX -DHAVE_SBRK -DHAVE_MMAP -DHAVE_LIMITS_H \
         -DHAVE_UNISTD_H)"
  | _ -> Format.printf "()"
