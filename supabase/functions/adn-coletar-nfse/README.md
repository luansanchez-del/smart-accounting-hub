# Coleta de NFS-e no ADN

Edge Function que consulta a API de distribuição de DF-e do Ambiente de
Dados Nacional por NSU e grava os XMLs de forma idempotente.

## Secrets obrigatórios

- `ADN_CERT_PEM`: cadeia do certificado cliente em PEM;
- `ADN_KEY_PEM`: chave privada correspondente em PEM.

Os Secrets nativos `SUPABASE_URL`, `SUPABASE_ANON_KEY` e
`SUPABASE_SERVICE_ROLE_KEY` também são utilizados. Nunca envie certificado ou
chave no corpo da requisição e nunca os grave nas tabelas.

## Configuração

Crie uma linha em `adn_nfse_configuracoes` para a empresa. Comece com
`ambiente = 'producao_restrita'` e `ativa = false`; valide certificado e CNPJ
antes de ativar. O `cnpj_consulta` deve estar sem pontuação e possuir a mesma
raiz do CNPJ presente no certificado, conforme a regra do ADN.

## Chamada autenticada

```json
{
  "empresa_id": "UUID_DA_EMPRESA"
}
```

A função exige JWT de usuário com permissão `documentos:criar`. O retorno
informa `coletados`, `duplicados` e `ultimo_nsu`. Erros ficam registrados em
`adn_nfse_configuracoes.ultimo_erro`.
