open Printf
open Unix

type witness = int array

type tree =
  | Not_Found
  | Exists of witness * tree array
  | Not_Exists of tree array

let witness_size = 0

(* Create shared dictionary. *)

(* Tree used to store the words.  This is stupid and inefficient
 * but it is here to demonstrate the 'Ancient' module, not good use
 * of trees.
 *)

let arraysize = 256 (* one element for each character *)

let add_to_tree tree word =
  let len = String.length word in
  if len > 0 then (
    let tree = ref tree in
    for i = 0 to len - 2 do
      let c = word.[i] in
      let c = Char.code c in
      match !tree.(c) with
      | Not_Found ->
          (* Allocate more tree. *)
          let tree' = Array.make arraysize Not_Found in
          !tree.(c) <- Not_Exists tree';
          tree := tree'
      | Exists (witness, tree') ->
          assert (Array.length witness = witness_size);
          tree := tree'
      | Not_Exists tree' -> tree := tree'
    done;

    (* Final character. *)
    let c = word.[len - 1] in
    let c = Char.code c in
    match !tree.(c) with
    | Not_Found ->
        !tree.(c) <-
          Exists (Array.make witness_size 0, Array.make arraysize Not_Found)
    | Exists (witness, _) ->
        assert (Array.length witness = witness_size);
        () (* same word added twice *)
    | Not_Exists tree' -> !tree.(c) <- Exists (Array.make witness_size 0, tree'))

let word_exists tree word =
  try
    let tree = ref tree in
    let len = String.length word in
    for i = 0 to len - 2 do
      let c = word.[i] in
      let c = Char.code c in
      match !tree.(c) with
      | Not_Found -> raise Not_found
      | Exists (_, tree') | Not_Exists tree' -> tree := tree'
    done;

    (* Final character. *)
    let c = word.[len - 1] in
    let c = Char.code c in
    match !tree.(c) with Not_Found | Not_Exists _ -> false | Exists _ -> true
  with Not_found -> false

let write ~wordsfile ~datafile ~baseaddr =
  let md =
    let fd = openfile datafile [ O_RDWR; O_TRUNC; O_CREAT ] 0o644 in
    Ancient.attach fd baseaddr
  in
  let tree : tree array = Array.make arraysize Not_Found in

  (* Read in the words and put them in the tree. *)
  let chan = open_in wordsfile in
  let count = ref 0 in
  let rec loop () =
    let word = input_line chan in
    add_to_tree tree word;
    incr count;
    loop ()
  in
  (try loop () with End_of_file -> ());
  close_in chan;

  printf "Added %d words to the tree.\n" !count;

  printf "Sharing tree in data file ...\n%!";
  ignore (Ancient.share md 0 tree);

  (* Perform a full GC and compact, which is a good way to see
   * if we've trashed the OCaml heap in some way.
   *)
  Array.fill tree 0 arraysize Not_Found;
  printf "Garbage collecting ...\n%!";
  Gc.compact ();

  printf "Detaching file and finishing.\n%!";

  Ancient.detach md

let verify ~wordsfile ~datafile =
  let md =
    let fd = openfile datafile [ O_RDWR ] 0o644 in
    Ancient.attach fd 0n
  in
  let tree : tree array Ancient.ancient = Ancient.get md 0 in
  let tree = Ancient.follow tree in

  (* Read in the words and keep in a local list. *)
  let words = ref [] in
  let chan = open_in wordsfile in
  let rec loop () =
    let word = input_line chan in
    if word <> "" then words := word :: !words;
    loop ()
  in
  (try loop () with End_of_file -> ());
  close_in chan;
  let words = List.rev !words in

  (* Verify that the number of words in the tree is the same as the
   * number of words in the words file.
   *)
  let nr_expected = List.length words in
  let nr_actual =
    let rec count tree =
      let c = ref 0 in
      for i = 0 to arraysize - 1 do
        match tree.(i) with
        | Not_Found -> ()
        | Exists (witness, tree) ->
            assert (Array.length witness = witness_size);
            c := !c + 1 + count tree
        | Not_Exists tree -> c := !c + count tree
      done;
      !c
    in
    count tree
  in

  if nr_expected <> nr_actual then
    failwith
      (sprintf "verify failed: expected %d words but counted %d in tree"
         nr_expected nr_actual);

  (* Check each word exists in the tree. *)
  List.iter
    (fun word ->
      if not (word_exists tree word) then
        failwith (sprintf "verify failed: word '%s' missing from tree" word))
    words;

  Ancient.detach md;

  (* Garbage collect - good way to check we haven't broken anything. *)
  Gc.compact ();

  printf "Verification succeeded.\n"

let () =
  match Array.to_list Sys.argv with
  | [ _; "write"; wordsfile; datafile; baseaddr ] ->
      write ~wordsfile ~datafile ~baseaddr:(Nativeint.of_string baseaddr)
  | [ _; "verify"; wordsfile; datafile ] -> verify ~wordsfile ~datafile
  | _ -> failwith (Format.sprintf "%s: wrong usage" Sys.executable_name)
