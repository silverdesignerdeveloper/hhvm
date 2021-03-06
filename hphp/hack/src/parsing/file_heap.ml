(**
 * Copyright (c) 2015, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the "hack" directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 *
 *)

(*
    Shared memory heap containing the contents of files.
    Acts as a sort of caching facade which is filled on-demand
    as contents are needed - The "cache" is filled by loading from
    the file system if the file isn't opened in the IDE
    (otherwise uses the IDE contents).
    That is, the IDE version take precedence over file system's.
*)

type disk_type = Disk of string | Ide of File_content.t

module FileHeap = SharedMem.WithCache (Relative_path.S) (struct
    type t = disk_type
    let prefix = Prefix.make()
    let description = "Disk"
  end)

let get_contents fn =
  match FileHeap.get fn with
  | Some Ide f -> Some f.File_content.content
  | Some Disk contents -> Some contents
  | None ->
      let contents =
      try Sys_utils.cat (Relative_path.to_absolute fn) with _ -> "" in
      FileHeap.add fn (Disk contents);
      Some contents

let get_ide_contents_unsafe fn =
  match FileHeap.get fn with
  | Some Ide f -> f
  | _ -> assert false
