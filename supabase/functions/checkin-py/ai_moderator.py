import httpx

async def moderate_text(text: str, openai_key: str) -> tuple[bool, dict]:
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
            data = resp.json()
            result = data["results"][0]
            # 'flagged'가 True이면 유해한 콘텐츠로 판단
            is_flagged = result["flagged"]
            return is_flagged, result["categories"]
        except Exception as e:
            print(f"🚨 Moderation API 호출 실패: {e}")
            # 예외 발생 시 안전을 위해 보수적으로 True 반환 가능
            return False, {"error": str(e)}