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
      match Yojson.Safe.from_string body_str with
      | exception Yojson.Json_error msg ->
          send_fail "{\"transaction_id\": \"fail\"}" >>= fun () ->
          Server.respond_string ~status:`Bad_request
            ~body:("Invalid JSON: " ^ msg) ()
      | json ->
          if json = `Assoc [] then
            send_fail "{\"transaction_id\": \"fail\"}" >>= fun () ->
            Server.respond_string ~status:`Bad_request
              ~body:"Empty JSON payload. Cancel request sent." ()
          else
            
            let transaction_id =
              json |> Util.member "transaction_id" |> Util.to_string
            in
            let amount = json |> Util.member "amount" |> Util.to_string in

            if amount = "0.00" then
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
              Server.respond_string ~status:`OK ~body:body_str ()))
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
