import httpx
from localization import get_translation

async def moderate_text(text: str, openai_key: str, lang_code: str = 'ko') -> tuple[bool, dict]: # 🥑 Add lang_code
    """
    OpenAI Moderation API를 사용하여 텍스트의 유해성을 검사합니다.
    반환값: (유해 여부(True/False), 상세 결과 dict)
    """
    if not text.strip():
        return False, {}

    async with httpx.AsyncClient() as client:
        try:
            resp = await client.post(
                "https://api.openai.com/v1/moderations",
                headers={"Authorization": f"Bearer {openai_key}"},
                json={"input": text},
                timeout=10.0,
            )
            resp.raise_for_status()
            data = resp.json()
            if not data.get("results") or not data["results"]:
                 raise ValueError("Moderation API response missing 'results'")
            result = data["results"][0]
            # 'flagged'가 True이면 유해한 콘텐츠로 판단
            is_flagged = result.get("flagged", False) # 🥑 Use .get for safety
            categories = result.get("categories", {}) # 🥑 Use .get for safety
            return is_flagged, categories
        except Exception as e:
            error_message = get_translation("error_moderation_api_failed", lang_code, error=str(e))
            print(f"🚨 Moderation API 호출 실패: {error_message}")
            # 예외 발생 시 안전을 위해 보수적으로 True 반환 가능
            return False, {"error": str(e)}