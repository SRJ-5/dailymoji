// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
// supabase/functions/daily_reminder/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import "https://deno.land/x/dotenv/load.ts";

// 함수 실행: 매일 새벽 (스케줄러에 의해 자동 호출됨)
serve(async () => {
  console.log("🕓 daily_reminder 함수 시작");

  // Supabase 클라이언트 초기화
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
  );

  // 최근 로그인 기록이 7일 이상 없는 유저 조회
  const sevenDaysAgo = new Date(Date.now() - 5 * 1000).toISOString();

  const { data: inactiveUsers, error } = await supabase
    .from("user_tokens") // 👈 유저 정보가 저장된 테이블명 (필요 시 수정)
    .select("user_id, updated_at")
    .lt("updated_at", sevenDaysAgo);

  if (error) {
    console.error("❌ 유저 조회 실패:", error.message);
    return new Response("DB error", { status: 500 });
  }

  if (!inactiveUsers || inactiveUsers.length === 0) {
    console.log("✅ 미접속 유저 없음 (알림 전송 X)");
    return new Response("No inactive users", { status: 200 });
  }

  console.log(`📋 ${inactiveUsers.length}명의 미접속 유저 발견`);

  // 각 유저에게 알림 발송
  for (const user of inactiveUsers) {
    try {
      const response = await fetch(
        `${Deno.env.get("SUPABASE_URL")}/functions/v1/send_notification`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            user_id: user.user_id,
            title: "데일리모지가 당신을 그리워하고 있어요 💌",
            body: "오늘 하루의 감정을 기록해보는 건 어때요?",
          }),
        }
      );

      if (response.ok) {
        console.log(`📤 알림 전송 완료 → user_id: ${user.user_id}`);
      } else {
        console.error(`⚠️ 알림 실패 → user_id: ${user.user_id}`, await response.text());
      }
    } catch (err) {
      console.error(`🚨 알림 전송 중 예외 발생 → user_id: ${user.user_id}`, err);
    }
  }

  return new Response("✅ daily_reminder 실행 완료", { status: 200 });
});


/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/daily_reminder' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
