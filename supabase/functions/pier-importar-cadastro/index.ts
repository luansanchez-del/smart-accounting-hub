// Importação única de cadastro do PIER para public.empresas.
// Não é uma integração viva: você aciona esta função quando quiser trazer
// (ou atualizar) o cadastro de clientes do PIER. Nenhum dado contábil é
// tocado aqui — só nome/CNPJ/regime, e cada empresa importada gera também
// uma linha em public.importacoes com a resposta bruta do PIER, para manter
// a origem rastreável (nunca inserimos sem registrar de onde veio).
//
// Segurança: exige um usuário autenticado com permissão empresas:criar
// (checada via tem_permissao no banco, com o token do próprio chamador —
// não com a service role). Credenciais do PIER vêm só de variáveis de
// ambiente (Secrets do projeto), nunca do corpo da requisição.

import { createClient } from "jsr:@supabase/supabase-js@2";

const PIER_API_URL = Deno.env.get("PIER_API_URL");
const PIER_USERNAME = Deno.env.get("PIER_USERNAME");
const PIER_PASSWORD = Deno.env.get("PIER_PASSWORD");

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SUPABASE_ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY")!;

interface PierCliente {
  id: number;
  nome: string;
  documento: string;
  status: string;
  tributacao: string;
}

const REGIME_POR_TRIBUTACAO: Record<string, string> = {
  "Simples Nacional": "simples",
  "MEI": "mei",
  "Lucro Presumido": "presumido",
  "Lucro Real": "real",
  "Lucro Arbitrado": "real",
  "Imune": "imune",
  "Isenta": "isenta",
};

function limparCnpj(documento: string): string {
  return documento.replace(/\D/g, "");
}

function mapearRegime(tributacao: string): string {
  return REGIME_POR_TRIBUTACAO[tributacao] ?? "presumido";
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }
  if (!PIER_API_URL || !PIER_USERNAME || !PIER_PASSWORD) {
    return new Response(
      JSON.stringify({ erro: "PIER_API_URL, PIER_USERNAME ou PIER_PASSWORD não configurados nos Secrets." }),
      { status: 500, headers: { "Content-Type": "application/json" } },
    );
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ erro: "Sem token de autenticação." }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // Cliente com o token do próprio usuário chamador: qualquer insert respeita
  // as mesmas RLS policies de sempre (tem_permissao('empresas','criar')).
  const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData.user) {
    return new Response(JSON.stringify({ erro: "Token inválido." }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const loginResp = await fetch(`${PIER_API_URL}/api/v2/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username: PIER_USERNAME, password: PIER_PASSWORD }),
  });
  if (!loginResp.ok) {
    return new Response(
      JSON.stringify({ erro: `Falha no login do PIER (status ${loginResp.status}).` }),
      { status: 502, headers: { "Content-Type": "application/json" } },
    );
  }
  const { token } = (await loginResp.json()) as { token: string };

  const resultado = { importadas: 0, atualizadas: 0, ignoradas: 0, erros: [] as string[] };
  let pagina = 1;
  const itensPorPagina = 100;

  while (true) {
    const clientesResp = await fetch(
      `${PIER_API_URL}/api/v2/clientes?pagina=${pagina}&itensPorPagina=${itensPorPagina}&status=Ativo`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (!clientesResp.ok) {
      resultado.erros.push(`Página ${pagina}: status ${clientesResp.status} ao listar clientes.`);
      break;
    }
    const clientes = (await clientesResp.json()) as PierCliente[];
    if (clientes.length === 0) break;

    for (const cliente of clientes) {
      const cnpj = limparCnpj(cliente.documento);
      if (cnpj.length !== 14) {
        resultado.ignoradas++;
        continue;
      }

      const { data: existente } = await supabase
        .from("empresas")
        .select("id, regime_confirmado")
        .eq("cnpj", cnpj)
        .maybeSingle();

      if (existente) {
        const { error: erroUpdate } = await supabase
          .from("empresas")
          .update({
            razao_social: cliente.nome,
            nome_fantasia: cliente.nome,
            // Regime só é atualizado pelo PIER enquanto ninguém confirmou manualmente.
            ...(existente.regime_confirmado ? {} : { regime: mapearRegime(cliente.tributacao) }),
          })
          .eq("id", existente.id);

        if (erroUpdate) {
          resultado.erros.push(`Cliente PIER ${cliente.id} (${cliente.nome}): ${erroUpdate.message}`);
        } else {
          resultado.atualizadas++;
        }
        continue;
      }

      const { data: novaEmpresa, error: erroEmpresa } = await supabase
        .from("empresas")
        .insert({
          codigo: `PIER-${cliente.id}`,
          cnpj,
          tipo: "matriz",
          razao_social: cliente.nome,
          nome_fantasia: cliente.nome,
          uf: "",
          regime: mapearRegime(cliente.tributacao),
          regime_confirmado: false,
          created_by: userData.user.id,
        })
        .select("id")
        .single();

      if (erroEmpresa || !novaEmpresa) {
        resultado.erros.push(`Cliente PIER ${cliente.id} (${cliente.nome}): ${erroEmpresa?.message}`);
        continue;
      }

      await supabase.from("importacoes").insert({
        empresa_id: novaEmpresa.id,
        tipo: "cadastro_pier",
        status: "concluida",
        detalhes: cliente,
        created_by: userData.user.id,
      });

      resultado.importadas++;
    }

    if (clientes.length < itensPorPagina) break;
    pagina++;
  }

  return new Response(JSON.stringify(resultado), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
});
