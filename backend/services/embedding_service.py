# services/embedding_service.py (수정)

import os
import numpy as np
import pickle
from openai import OpenAI
from dotenv import load_dotenv
from typing import List
import faiss

load_dotenv()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

def get_embedding(text: str) -> list[float]:
    response = client.embeddings.create(
        model="text-embedding-3-small",  # or "text-embedding-ada-002"
        input=text
    )
    return response.data[0].embedding


def embed_chunks(chunks: List[str], save_path: str = "vector_db/faiss_db.pkl"):
    """
    여러 chunk의 텍스트를 임베딩한 후 FAISS DB로 저장
    """
    # ✅ 1. 텍스트 -> 임베딩
    embeddings = [get_embedding(chunk) for chunk in chunks]
    embeddings = np.array(embeddings).astype("float32")

    # ✅ 2. FAISS 인덱스 생성
    dim = embeddings.shape[1]
    index = faiss.IndexFlatL2(dim)
    index.add(embeddings)

    # ✅ 3. 저장 (Pickle)
    os.makedirs(os.path.dirname(save_path), exist_ok=True)
    with open(save_path, "wb") as f:
        pickle.dump(index, f)

    print(f"✅ FAISS 인덱스 저장 완료: {save_path}")
