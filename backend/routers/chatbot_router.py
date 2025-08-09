# backend/routers/chatbot_router.py

from fastapi import APIRouter, Request
from schemas.chatbot_schema import ChatRequest
from services.rag_service import retrieve_relevant_chunks
from services.gpt_service import ask_gpt

router = APIRouter()

@router.post("/chat")
def chat_with_gpt(request: ChatRequest):
    try:
        chunks = retrieve_relevant_chunks(request.question)

        # ✅ 문맥 여부에 따라 프롬프트 다르게 구성
        if not chunks:
            # 🔁 GPT only, but 정직하게 (너가 원하는 fallback)
            prompt = f"""
당신은 친절한 학습 도우미입니다. 
사용자가 올린 문서에서 관련 내용을 찾지 못했습니다. 
그렇기 때문에 당신이 알고 있는 범위에서만 답변해주세요.
모르면 모른다고 답하세요.

[질문]
{request.question}

[답변]
"""
        else:
            # ✅ RAG + GPT 결합 응답
            context = "\n".join(chunks)
            prompt = f"""
당신은 친절한 학습 도우미입니다. 아래 문맥을 참고하여 사용자 질문에 답변해주세요.

[문맥]
{context}

[질문]
{request.question}

[답변]
"""

        answer = ask_gpt(prompt)
        return {"answer": answer}

    except Exception as e:
        return {"error": str(e)}