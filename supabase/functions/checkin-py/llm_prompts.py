# llm_prompts.py

import os
import json
import httpx
from typing import Union


OPENAI_KEY = os.getenv("OPENAI_API_KEY")

# 1. 코치(분석) 모드 시스템 프롬프트 (기존의 것)
ANALYSIS_SYSTEM_PROMPT = """
You are a clinical-grade SRJ-5 emotion analysis assistant.
Return STRICT JSON ONLY matching this schema... 
(기존의 긴 프롬프트 내용 전체를 여기에 붙여넣으세요)
"""

# 2. 친구 모드 시스템 프롬프트 (새로 추가!)
FRIENDLY_SYSTEM_PROMPT = """
You are 'Moji', a friendly, warm, and supportive chatbot. Your personality is like a cheerful and empathetic friend.
- Your primary goal is to be a good conversational partner.
- Keep your responses short, typically 1-2 sentences.
- Use emojis to convey warmth and friendliness.
- Your name is '모지'.
- Respond in Korean.
"""

# 3. 통합 LLM 호출 함수
async def call_llm(system_prompt: str, user_content: str, model: str = "gpt-4o-mini", temperature: float = 0.0) -> Union[dict, str]:
    if not OPENAI_KEY:
        return {"error": "OpenAI key not found"}
    
    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={"Authorization": f"Bearer {OPENAI_KEY}"},
                json={
                    "model": model,
                    "messages": [
                        {"role": "system", "content": system_prompt},
                        {"role": "user", "content": user_content},
                    ],
                    "temperature": temperature,
                },
                timeout=30.0,
            )
            data = resp.json()

            # 응답이 JSON 형식인지, 단순 텍스트인지에 따라 다르게 처리
            content = data["choices"][0]["message"]["content"]
            try:
                # 분석 모드는 JSON을 반환해야 함
                return json.loads(content)
            except json.JSONDecodeError:
                # 친구 모드는 순수 텍스트를 반환
                return content

        except Exception as e:
            print(f"LLM call failed: {e}")
            return {"error": str(e)}