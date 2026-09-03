import { createClient } from "jsr:@supabase/supabase-js@2";

const URLS = {
  producao: "https://adn.nfse.gov.br/contribuintes",
  producao_restrita: "https://adn.producaorestrita.nfse.gov.br/contribuintes",
} as const;

const jsonHeaders = { "Content-Type": "application/json" };
const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function resposta(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: jsonHeaders });
}

function base64ParaBytes(value: string): Uint8Array {
  const binary = atob(value);
  return Uint8Array.from(binary, (char) => char.charCodeAt(0));
}

async function descompactarXml(value: string): Promise<string> {
  const stream = new Blob([base64ParaBytes(value)])
    .stream()
    .pipeThrough(new DecompressionStream("gzip"));
  return new Response(stream).text();
}

async function sha256(value: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
  return Array.from(new Uint8Array(digest), (byte) => byte.toString(16).padStart(2, "0")).join("");
}

async function consultarLote(
  client: Deno.HttpClient,
  baseUrl: string,
  nsu: number,
  cnpj: string,
) {
  const url = new URL(`${baseUrl}/DFe/${nsu}`);
  url.searchParams.set("lote", "true");
  url.searchParams.set("cnpjConsulta", cnpj);

  let esperaMs = 2500;
  for (let tentativa = 1; tentativa <= 8; tentativa++) {
    let response: Response;
    try {
      response = await fetch(url, {
        client,
        headers: { Accept: "application/json", "User-Agent": "Numera-Coleta-NFSe/1.0" },
        signal: AbortSignal.timeout(60_000),
      });
    } catch (error) {
      if (tentativa === 8) throw error;
      await sleep(esperaMs);
      esperaMs = Math.min(Math.round(esperaMs * 1.6), 15_000);
      continue;
    }

    if (response.status === 429) {
      const retryAfter = Number(response.headers.get("retry-after"));
      await sleep(Number.isFinite(retryAfter) ? retryAfter * 1000 : esperaMs);
      esperaMs = Math.min(Math.round(esperaMs * 1.6), 15_000);
      continue;
    }
    if (response.status === 404) {
      const texto = await response.text();
      const body = (() => {
        try {
          return JSON.parse(texto);
        } catch {
          return null;
        }
      })();
      if (body && ("LoteDFe" in body || /NENHUM_DOCUMENTO|E2220/i.test(texto))) {
        return body.LoteDFe ? body : { LoteDFe: [] };
      }
      throw new Error(`ADN respondeu HTTP 404: ${texto.slice(0, 300)}`);
    }
    if (response.status === 401 || response.status === 403) {
      throw new Error(`Certificado recusado pelo ADN (HTTP ${response.status}).`);
    }
    if (!response.ok) {
      throw new Error(`ADN respondeu HTTP ${response.status}: ${(await response.text()).slice(0, 300)}`);
    }
    return response.json();
  }
  throw new Error("Limite de tentativas do ADN excedido.");
}

Deno.serve(async (request) => {
  if (request.method !== "POST") return resposta({ erro: "Método não permitido." }, 405);

  const authorization = request.headers.get("Authorization");
  if (!authorization) return resposta({ erro: "Sem token de autenticação." }, 401);

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const certChain = Deno.env.get("ADN_CERT_PEM");
  const privateKey = Deno.env.get("ADN_KEY_PEM");
  if (!certChain || !privateKey) {
    return resposta({ erro: "ADN_CERT_PEM e ADN_KEY_PEM não configurados nos Secrets." }, 500);
  }

  const body = await request.json().catch(() => ({}));
  const empresaId = typeof body.empresa_id === "string" ? body.empresa_id : "";
  if (!empresaId) return resposta({ erro: "empresa_id é obrigatório." }, 400);

  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return resposta({ erro: "Token inválido." }, 401);

  const { data: permitido } = await userClient.rpc("tem_permissao", {
    p_modulo: "documentos",
    p_acao: "criar",
  });
  if (!permitido) return resposta({ erro: "Sem permissão para coletar documentos." }, 403);

  const admin = createClient(supabaseUrl, serviceKey);
  const { data: config, error: configError } = await admin
    .from("adn_nfse_configuracoes")
    .select("*")
    .eq("empresa_id", empresaId)
    .eq("ativa", true)
    .single();
  if (configError || !config) return resposta({ erro: "Coleta ADN não configurada ou inativa." }, 409);

  const httpClient = Deno.createHttpClient({ cert: certChain, key: privateKey });
  let cursor = Number(config.ultimo_nsu);
  let coletados = 0;
  let duplicados = 0;

  try {
    await admin.from("adn_nfse_configuracoes").update({
      ultima_execucao_em: new Date().toISOString(), ultimo_erro: null,
    }).eq("id", config.id);

    for (let lote = 0; lote < 100; lote++) {
      const payload = await consultarLote(httpClient, URLS[config.ambiente as keyof typeof URLS], cursor, config.cnpj_consulta);
      const documentos = Array.isArray(payload.LoteDFe) ? payload.LoteDFe : [];
      if (documentos.length === 0) break;

      let maiorNsu = cursor;
      for (const item of documentos) {
        const nsu = Number(item.NSU);
        if (!Number.isSafeInteger(nsu) || nsu < 0 || !item.ArquivoXml) continue;
        maiorNsu = Math.max(maiorNsu, nsu);
        const xml = await descompactarXml(item.ArquivoXml);
        const hash = await sha256(xml);

        const { data: existente } = await admin.from("adn_nfse_documentos")
          .select("id").eq("empresa_id", empresaId).or(`nsu.eq.${nsu},hash_sha256.eq.${hash}`).maybeSingle();
        if (existente) { duplicados++; continue; }

        const nome = `${item.TipoDocumento || "DFe"}-${item.ChaveAcesso || nsu}.xml`;
        const { data: documento, error: documentoError } = await admin.from("documentos").insert({
          empresa_id: empresaId,
          nome_arquivo: nome,
          tipo: item.TipoDocumento || "nfse",
          origem: "adn_nfse",
          created_by: userData.user.id,
        }).select("id").single();
        if (documentoError) throw documentoError;

        const { error: xmlError } = await admin.from("adn_nfse_documentos").insert({
          empresa_id: empresaId,
          documento_id: documento.id,
          nsu,
          chave_acesso: item.ChaveAcesso || "",
          tipo_documento: item.TipoDocumento || "desconhecido",
          tipo_evento: item.TipoEvento || null,
          data_geracao: item.DataHoraGeracao || null,
          xml,
          hash_sha256: hash,
        });
        if (xmlError) {
          await admin.from("documentos").delete().eq("id", documento.id);
          throw xmlError;
        }
        coletados++;
      }

      if (maiorNsu <= cursor) break;
      cursor = maiorNsu;
      await admin.from("adn_nfse_configuracoes").update({ ultimo_nsu: cursor }).eq("id", config.id);
      if (payload.StatusProcessamento !== "DOCUMENTOS_LOCALIZADOS" && documentos.length < 50) break;
      await sleep(2000);
    }

    await admin.from("adn_nfse_configuracoes").update({
      ultimo_nsu: cursor,
      ultimo_sucesso_em: new Date().toISOString(),
      ultimo_erro: null,
    }).eq("id", config.id);
    return resposta({ coletados, duplicados, ultimo_nsu: cursor });
  } catch (error) {
    const mensagem = error instanceof Error ? error.message : String(error);
    await admin.from("adn_nfse_configuracoes").update({ ultimo_erro: mensagem.slice(0, 1000) }).eq("id", config.id);
    return resposta({ erro: mensagem, coletados, ultimo_nsu: cursor }, 502);
  } finally {
    httpClient.close();
  }
});
