open Sqlite3

let db_file = "transactions.db"

let db = db_open db_file

let create_table () =
  let create_sql =
    "CREATE TABLE IF NOT EXISTS transactions (
      transaction_id TEXT PRIMARY KEY
    );"
  in
  let delete_sql = "DELETE FROM transactions;" in


  match exec db create_sql with
  | Rc.OK ->
      (match exec db delete_sql with
      | Rc.OK -> ()
      | rc -> failwith ("Failed to delete old records: " ^ Rc.to_string rc))
  | rc -> failwith ("Failed to create table: " ^ Rc.to_string rc)

  
let insert_data transaction_id =
  
  let sql = Printf.sprintf
      "INSERT INTO transactions (transaction_id) VALUES ('%s');"
    transaction_id
  in

  match exec db sql with
  | Rc.OK -> ()
  | _ -> failwith "Failed to insert data"

let transaction_exists transaction_id =
    let sql = "SELECT COUNT(*) FROM transactions WHERE transaction_id = ?" in
    let stmt = prepare db sql in
  
    bind stmt 1 (Data.TEXT transaction_id) |> ignore;
  
    match step stmt with
    | Rc.ROW ->
        let count_opt = column stmt 0 |> Data.to_int in
        finalize stmt |> ignore;
        (match count_opt with
         | Some count -> count > 0
         | None -> false)
    | _ ->
        finalize stmt |> ignore;
        false
  