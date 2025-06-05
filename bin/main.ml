open Cohttp_lwt_unix
open Cohttp
open Lwt.Infix
open Yojson.Safe

let transaction_ids = ref []

let send_fail body_str =
  let cancel_uri = Uri.of_string "http://localhost:5001/cancelar" in
  let headers = Header.init_with "Content-Type" "application/json" in
  let webhook_body = Cohttp_lwt.Body.of_string body_str in

  Client.post ~headers ~body:webhook_body cancel_uri >>= fun (resp, _body) ->
  let cancel_status = Response.status resp in
  Printf.printf "Cancel webhook response: %s\n%!" (Cohttp.Code.string_of_status cancel_status);
  Lwt.return_unit

let send_success body_str =
  let success_uri = Uri.of_string "http://localhost:5001/confirmar" in
  let headers = Header.init_with "Content-Type" "application/json" in
  let webhook_body = Cohttp_lwt.Body.of_string body_str in

  Client.post ~headers ~body:webhook_body success_uri >>= fun (resp, _body) ->
  let success_status = Response.status resp in
  Printf.printf "Success webhook response: %s\n%!" (Cohttp.Code.string_of_status success_status);
  Lwt.return_unit

let handler _conn req body =
  let uri = Request.uri req in
  let path = Uri.path uri in
  let meth = Request.meth req in

  Printf.printf "Received %s request for %s\n%!" (Cohttp.Code.string_of_method meth) path;

  match (meth, path) with
  | (`POST, "/") ->
    Cohttp_lwt.Body.to_string body >>= fun body_str ->
    Printf.printf "Body received: %s\n%!" body_str;

    let json =
      try Ok (Yojson.Safe.from_string body_str)
      with Yojson.Json_error msg -> Error msg
    in

    (match json with
    | Ok json_obj ->
    
        let transaction_id = json_obj |> Util.member "transaction_id" |> Util.to_string in
        (* let event = json_obj |> Util.member "event" |> Util.to_string in
        let amount = json_obj |> Util.member "amount" |> Util.to_string in
        let currency = json_obj |> Util.member "currency" |> Util.to_string in
        let timestamp = json_obj |> Util.member "timestamp" |> Util.to_string in  *)

        if List.mem transaction_id !transaction_ids then
          (send_fail body_str >>= fun () ->
           Server.respond_string ~status:`Conflict ~body:"Duplicate transaction_id. Cancel request sent." ())
        else
          (transaction_ids := transaction_id :: !transaction_ids;
           send_success body_str >>= fun () ->
           Server.respond_string ~status:`OK ~body:body_str ())
    
    | Error msg ->
        Printf.printf "JSON parse error: %s\n%!" msg;
        Server.respond_string ~status:`Bad_request ~body:("JSON parse error: " ^ msg) ())
    

  | (`GET, "/") ->
      Printf.printf "Responding to GET /\n%!";
      Server.respond_string ~status:`OK ~body:"Hello, OCaml Web Server!" ()

  | (`GET, "/about") ->
      Printf.printf "Responding to GET /about\n%!";
      Server.respond_string ~status:`OK ~body:"About: This is a simple OCaml web server." ()

  | _ ->
      Printf.printf "Unhandled route: %s %s\n%!" (Cohttp.Code.string_of_method meth) path;
      Server.respond_string ~status:`Not_found ~body:"404: Page not found" ()

let start_server () =
  let port = 8080 in
  let server =
    Server.create
      ~mode:(`TCP (`Port port))
      (Server.make ~callback:handler ())
  in
  Printf.printf "Server running on http://localhost:%d\n%!" port;
  server

let () = Lwt_main.run (start_server ())
