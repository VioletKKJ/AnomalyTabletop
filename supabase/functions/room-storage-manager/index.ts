import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Content-Type": "application/json",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: corsHeaders });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Método não permitido." }, 405);

  try {
    const url = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!url || !serviceKey) return json({ error: "Configuração interna do Storage indisponível." }, 500);

    const admin = createClient(url, serviceKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const body = await req.json();
    const action = String(body?.action || "");
    const roomId = String(body?.roomId || "");
    const userId = String(body?.userId || "");
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(roomId) ||
        !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(userId)) {
      return json({ error: "Mesa ou usuário inválido." }, 400);
    }

    // O Anomaly VTT usa autenticação própria (não Supabase Auth). A autorização
    // segue o mesmo vínculo de mestre em room_members usado pelas RPCs atuais.
    const { data: membership, error: memberError } = await admin
      .from("room_members")
      .select("role")
      .eq("room_id", roomId)
      .eq("user_id", userId)
      .maybeSingle();

    if (memberError) throw memberError;
    if (!membership || membership.role !== "mestre") {
      return json({ error: "Somente o mestre desta mesa pode gerenciar os arquivos." }, 403);
    }

    const root = `rooms/${roomId}`;
    const bucket = admin.storage.from("tabletop");

    if (action === "list") {
      const files: Array<Record<string, unknown>> = [];
      const pending = [root];
      while (pending.length) {
        const folder = pending.pop()!;
        let offset = 0;
        while (true) {
          const { data, error } = await bucket.list(folder, {
            limit: 1000,
            offset,
            sortBy: { column: "name", order: "asc" },
          });
          if (error) throw error;
          const entries = data || [];
          for (const entry of entries) {
            if (entry.id == null) {
              pending.push(`${folder}/${entry.name}`);
            } else {
              const path = `${folder}/${entry.name}`;
              const meta = (entry.metadata || {}) as Record<string, unknown>;
              files.push({
                path,
                name: entry.name,
                folder: folder.slice(root.length + 1),
                size: Number(meta.size || 0),
                contentType: String(meta.mimetype || meta.contentType || ""),
                createdAt: entry.created_at || null,
                updatedAt: entry.updated_at || null,
              });
              if (files.length > 10000) {
                return json({ error: "Esta mesa tem mais de 10.000 arquivos. Use a exclusão em lotes menores." }, 413);
              }
            }
          }
          if (entries.length < 1000) break;
          offset += entries.length;
        }
      }
      files.sort((a, b) => String(b.updatedAt || b.createdAt || "").localeCompare(String(a.updatedAt || a.createdAt || "")));
      return json({ files, count: files.length });
    }

    if (action === "delete") {
      const paths = Array.isArray(body?.paths) ? [...new Set(body.paths.map((p: unknown) => String(p)))] : [];
      if (!paths.length || paths.length > 1000) return json({ error: "Selecione entre 1 e 1.000 arquivos." }, 400);
      if (paths.some((path: string) =>
        !path.startsWith(root + "/") ||
        path.includes("..") ||
        path.startsWith("/") ||
        path.includes("\\")
      )) {
        return json({ error: "Um ou mais caminhos não pertencem a esta mesa." }, 403);
      }
      const { data, error } = await bucket.remove(paths);
      if (error) throw error;
      return json({ deleted: (data || []).length, paths });
    }

    return json({ error: "Ação desconhecida." }, 400);
  } catch (error) {
    console.error("[room-storage-manager]", error);
    return json({ error: error instanceof Error ? error.message : "Erro interno ao gerenciar arquivos." }, 500);
  }
});
