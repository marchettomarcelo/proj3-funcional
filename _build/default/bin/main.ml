open Cohttp_lwt_unix
open Cohttp
open Lwt.Infix
open Yojson.Safe
open Func3_raul.Webhook
open Func3_raul.Db_utils

let handler _conn req body =
  let uri = Request.uri req in
  let path = Uri.path uri in
  let meth = Request.meth req in

  match (meth, path) with
  | `POST, "/" -> (
      Cohttp_lwt.Body.to_string body >>= fun body_str ->
      let json =
        try Ok (Yojson.Safe.from_string body_str)
        with Yojson.Json_error msg -> Error msg
      in

      match json with
      | Ok json_obj ->
          let transaction_id =
            json_obj |> Util.member "transaction_id" |> Util.to_string
          in
          (* let event = json_obj |> Util.member "event" |> Util.to_string in *)
          let amount = json_obj |> Util.member "amount" |> Util.to_string in

          (* let currency = json_obj |> Util.member "currency" |> Util.to_string in
             let timestamp = json_obj |> Util.member "timestamp" |> Util.to_string in *)
          if amount = "0.00" then
            send_fail body_str >>= fun () ->
            Server.respond_string ~status:`Conflict
              ~body:"Amount is zero. Cancel request sent." ()
              
          else if amount = "0.00" then
            send_fail body_str >>= fun () ->
            Server.respond_string ~status:`Conflict
              ~body:"Amount is zero. Cancel request sent." ()
          else if transaction_exists transaction_id then
            send_fail body_str >>= fun () ->
            Server.respond_string ~status:`Conflict
              ~body:"Duplicate transaction_id. Cancel request sent." ()
          else (
            insert_data transaction_id;
            send_success body_str >>= fun () ->
            Server.respond_string ~status:`OK ~body:body_str ())
            
      | Error msg ->
          Printf.printf "JSON parse error: %s\n%!" msg;

          send_fail body_str >>= fun () ->
          Server.respond_string ~status:`Bad_request
            ~body:("JSON parse error: " ^ msg)
            ())
  | `GET, "/" ->
      Printf.printf "Responding to GET /\n%!";
      Server.respond_string ~status:`OK ~body:"Hello, OCaml Web Server!" ()
  | `GET, "/about" ->
      Printf.printf "Responding to GET /about\n%!";
      Server.respond_string ~status:`OK
        ~body:"About: This is a simple OCaml web server." ()
  | _ ->
      Printf.printf "Unhandled route: %s %s\n%!"
        (Cohttp.Code.string_of_method meth)
        path;
      Server.respond_string ~status:`Not_found ~body:"404: Page not found" ()

let start_server () =
  create_table ();

  let port = 8080 in
  let server =
    Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback:handler ())
  in
  Printf.printf "Server running on http://localhost:%d\n%!" port;
  server

let () = Lwt_main.run (start_server ())
