# Project 3 - Functional Programming

This is a web server implemented in OCaml that processes transactions and performs various validation checks.

## Features

The server implements a `POST ("/")` endpoint that performs the following checks:

### 1. JSON Validation

- Checks if the received payload is valid JSON  
- Rejects requests with invalid JSON, returning status 400 (Bad Request)  
- Rejects empty JSON payloads, returning status 400 (Bad Request)

### 2. Transaction Validation

- Makes sure the received header token is valid  
- Checks if the `transaction_id` field is present and valid  
- Checks if the `amount` field is present and valid  
- Rejects transactions with a zero amount (0.00), returning status 409 (Conflict)  
- Checks for duplicate `transaction_id`, returning status 409 (Conflict) for duplicates

### 3. Transaction Processing

- For valid transactions:
  - Inserts transaction data into the database  
  - Sends a success confirmation  
  - Returns status 200 (OK) with the original payload

### 4. Error Handling

- Route not found: Returns status 404 (Not Found)  
- Validation errors: Returns appropriate status with an error message  
- In case of an error, sends a cancellation request

## Technologies and Libraries Used

- OCaml  
- Cohttp  
- Lwt  
- Yojson  
- SQLite (for data storage)

## Running the Server

The server runs on port 8080 by default. To start:

```bash
dune build
dune exec func3-raul 
