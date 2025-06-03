open Cohttp_lwt_unix
open Cohttp
open Lwt.Infix
open Yojson.Safe

let handler _conn req body =
  let uri = Request.uri req in
  let path = Uri.path uri in
  let meth = Request.meth req in

  Printf.printf "Received %s request for %s\n%!" (Cohttp.Code.string_of_method meth) path;

  match (meth, path) with
  | (`POST, "/") ->
      Cohttp_lwt.Body.to_string body >>= fun body_str ->
      Printf.printf "Body received: %s\n%!" body_str;

      (* Parse JSON payload *)
      let json =
        try Ok (Yojson.Safe.from_string body_str)
        with Yojson.Json_error msg -> Error msg
      in
      (match json with
      | Ok json_obj -> (
          try
            let event = json_obj |> Util.member "event" |> Util.to_string in
            let transaction_id = json_obj |> Util.member "transaction_id" |> Util.to_string in
            let amount = json_obj |> Util.member "amount" |> Util.to_float in
            let currency = json_obj |> Util.member "currency" |> Util.to_string in
            let timestamp = json_obj |> Util.member "timestamp" |> Util.to_string in

            Printf.printf "Parsed JSON - Event: %s, Transaction ID: %s, Amount: %.2f, Currency: %s, Timestamp: %s\n%!"
              event transaction_id amount currency timestamp;

            let response_body =
              Printf.sprintf
                "Received event: %s\nTransaction ID: %s\nAmount: %.2f\nCurrency: %s\nTimestamp: %s\n"
                event transaction_id amount currency timestamp
            in
            Server.respond_string ~status:`OK ~body:response_body ()
          with
          | Util.Type_error (msg, _) ->
              Printf.printf "Type error: %s\n%!" msg;
              Server.respond_string ~status:`Bad_request ~body:("Invalid JSON structure: " ^ msg) ())
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
