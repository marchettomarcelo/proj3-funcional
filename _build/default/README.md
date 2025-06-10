# Func3-raul

Este é um servidor web implementado em OCaml que processa transações e realiza várias verificações de validação.

## Funcionalidades

O servidor implementa um endpoint POST ("/") que realiza as seguintes verificações:

### 1. Validação de JSON

-   Verifica se o payload recebido é um JSON válido
-   Rejeita requisições com JSON inválido, retornando status 400 (Bad Request)
-   Rejeita payloads JSON vazios, retornando status 400 (Bad Request)

### 2. Validação de Transação

-   Verifica se o campo `transaction_id` está presente e é válido
-   Verifica se o campo `amount` está presente e é válido
-   Rejeita transações com valor zero (0.00), retornando status 409 (Conflict)
-   Verifica duplicidade de `transaction_id`, retornando status 409 (Conflict) para transações duplicadas

### 3. Processamento de Transação

-   Para transações válidas:
    -   Insere os dados da transação no banco de dados
    -   Envia uma confirmação de sucesso
    -   Retorna status 200 (OK) com o payload original

### 4. Tratamento de Erros

-   Rota não encontrada: Retorna status 404 (Not Found)
-   Erros de validação: Retorna status apropriado com mensagem de erro
-   Em caso de erro, envia uma requisição de cancelamento

## Requisitos

-   OCaml
-   Cohttp
-   Lwt
-   Yojson
-   SQLite (para armazenamento de dados)

## Executando o Servidor

O servidor roda na porta 8080 por padrão. Para iniciar:

```bash
dune build
dune exer
```

O servidor estará disponível em: http://localhost:8080

## Formato da Requisição

A requisição deve ser um POST para "/" com um JSON contendo:

```json
{
	"transaction_id": "string",
	"amount": "string"
}
```

## Respostas

### Sucesso (200 OK)

-   Retorna o payload original da transação

### Erro (400 Bad Request)

-   JSON inválido
-   Payload vazio

### Erro (409 Conflict)

-   Valor da transação é zero
-   ID de transação duplicado

### Erro (404 Not Found)

-   Rota não encontrada
