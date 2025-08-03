# services/rag_service.py

from services.embedding_service import get_embedding
from utils.vector_db_utils import search_similar_chunks

def retrieve_relevant_chunks(question: str, top_k=3) -> list[str]:
    q_embedding = get_embedding(question)
    chunks = search_similar_chunks(q_embedding, top_k=top_k)
    return chunks
