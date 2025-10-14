// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// ✅ Deno 환경용 Supabase Edge Function (Legacy FCM 방식)
// https://supabase.com/docs/guides/functions


// Supabase Edge Function (Deno) — FCM HTTP v1 (최신 방식)
// Supabase Edge Function (Deno) — FCM HTTP v1
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import "https://deno.land/x/dotenv/load.ts";
import { SignJWT, importPKCS8 } from "https://deno.land/x/jose@v4.14.4/index.ts";

type ServiceAccount = { project_id: string; client_email: string; private_key: string };

async function getAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const pkcs8 = sa.private_key.replace(/\\n/g, "\n");
  const key = await importPKCS8(pkcs8, "RS256");
  const jwt = await new SignJWT({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .sign(key);

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }).toString(),
  });

  if (!res.ok) throw new Error(`token exchange failed: ${res.status} ${await res.text()}`);
  const json = await res.json();
  return json.access_token as string;
}

serve(async (req) => {
  try {
    const raw = await req.json();
    console.log("🔎 request body (raw):", raw);

    const uid = String(raw?.user_id ?? "").trim();
    console.log("✅ using uid (trimmed):", uid);
    if (!uid) return new Response("user_id missing", { status: 400 });

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRole = Deno.env.get("SERVICE_ROLE_KEY");
    const saRaw = Deno.env.get("GOOGLE_SERVICE_ACCOUNT");
    console.log("ENV check:", {
      hasSUPABASE_URL: !!supabaseUrl,
      hasSERVICE_ROLE_KEY: !!serviceRole,
      hasSERVICE_ACCOUNT: !!saRaw,
    });
    if (!supabaseUrl || !serviceRole || !saRaw) {
      return new Response("Config missing", { status: 500 });
    }

    const { createClient } = await import("https://esm.sh/@supabase/supabase-js@2");
    const supabase = createClient(supabaseUrl, serviceRole);

    // 🔹 RPC는 text 하나를 반환 → 문자열로 처리
    const { data, error } = await supabase.rpc("get_user_token", { uid_text: uid });
    console.log("📄 query result (rpc):", { data, error });
    if (error) return new Response(`RPC failed: ${error.message}`, { status: 500 });

    const token = typeof data === "string" ? data : (data?.token as string | undefined);
    console.log("🎯 resolved token:", token);
    if (!token) return new Response("Token not found", { status: 400 });

    // 🔹 payload 한 번만 선언 (중복 선언 금지!!)
    const message = {
      message: {
        token,
        notification: { title: raw?.title ?? "알림", body: raw?.body ?? "" },
        android: { priority: "HIGH" },
        apns: { headers: { "apns-priority": "10" } },
      },
    };
    console.log("🧾 FCM payload:", JSON.stringify(message));

    const sa: ServiceAccount = JSON.parse(saRaw);
    const accessToken = await getAccessToken(sa);
    const endpoint = `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`;

    const fcmRes = await fetch(endpoint, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(message),
    });

    const text = await fcmRes.text();
    console.log("📡 FCM v1 response:", text);

    if (!fcmRes.ok) return new Response(`FCM v1 failed: ${fcmRes.status} ${text}`, { status: 500 });
    return new Response("Push sent (v1)!", { status: 200 });
  } catch (e) {
    console.error("🔥 send_notification error:", e);
    return new Response("Internal Server Error", { status: 500 });
  }
});







/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/send_notification' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
