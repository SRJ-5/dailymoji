# supabase/functions/checkin-py/Dockerfile

# 1. 베이스 이미지로 파이썬 3.9 버전을 사용합니다.
FROM python:3.9-slim

# 2. 작업 디렉토리를 /app 으로 설정합니다.
WORKDIR /app

# 3. FastAPI 서버가 외부 요청을 받을 수 있도록 포트를 엽니다.
EXPOSE 8000

# 4. requirements.txt 파일을 복사합니다.
COPY requirements.txt .

# 5. kiwipiepy를 포함한 모든 라이브러리를 설치합니다.
RUN pip install --no-cache-dir -r requirements.txt

# 6. 현재 폴더의 모든 .py 파일들을 복사합니다.
COPY . .

# 7. FastAPI 서버를 실행하는 명령입니다.
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]