open Cohttp_lwt_unix
open Cohttp
open Lwt.Infix

let send_fail body_str =
  let cancel_uri = Uri.of_string "http://localhost:5001/cancelar" in
  let headers = Header.init_with "Content-Type" "application/json" in
  let webhook_body = Cohttp_lwt.Body.of_string body_str in

  Client.post ~headers ~body:webhook_body cancel_uri >>= fun (resp, _body) ->
  let cancel_status = Response.status resp in
  Printf.printf "Cancel webhook response: %s\n%!"
    (Cohttp.Code.string_of_status cancel_status);
  Lwt.return_unit

let send_success body_str =
  let success_uri = Uri.of_string "http://localhost:5001/confirmar" in
  let headers = Header.init_with "Content-Type" "application/json" in
  let webhook_body = Cohttp_lwt.Body.of_string body_str in

  Client.post ~headers ~body:webhook_body success_uri >>= fun (resp, _body) ->
  let success_status = Response.status resp in
  Printf.printf "Success webhook response: %s\n%!"
    (Cohttp.Code.string_of_status success_status);
  Lwt.return_unit