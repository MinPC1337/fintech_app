from langchain_text_splitters import RecursiveCharacterTextSplitter
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from langchain_community.document_loaders import DirectoryLoader, UnstructuredFileLoader
from langchain_ollama import OllamaEmbeddings, OllamaLLM
from langchain_community.vectorstores import FAISS
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser

app = FastAPI()

# 1. Khởi tạo Mô hình Nhúng (Embedding) và LLM siêu nhẹ qua Ollama
embeddings = OllamaEmbeddings(model="qwen3-embedding")
llm = OllamaLLM(model="qwen2.5:7b", temperature=0) 

# 2. Đọc tài liệu 
loader = DirectoryLoader("./data", glob="**/*.*", loader_cls=UnstructuredFileLoader)
docs = loader.load()

# 3. Text Splitting
markdown_separators = [
    r"\n# ", r"\n## ", r"\n### ", r"\n#### ", r"\n##### ", r"\n###### ", # Headings
    r"```", # Code blocks
    r"\n\n", r"\n", r" ", r"" # Đoạn, dòng, từ, ký tự
]

text_splitter = RecursiveCharacterTextSplitter(
    chunk_size=1200,          # Kích thước tối đa mỗi chunk (1200 ký tự)
    chunk_overlap=200,        # Độ trùng lặp giữa 2 chunk liên tiếp
    add_start_index=True,     # Lưu vị trí bắt đầu của chunk để trích dẫn source
    strip_whitespace=True,    # Xóa khoảng trắng thừa ở đầu/cuối chunk
    separators=markdown_separators
)

# Tiến hành cắt văn bản thông minh theo mạch ý nghĩa
splits = text_splitter.split_documents(docs)

# 4. Lưu trữ vào Vector Database Local (FAISS)
vector_store = FAISS.from_documents(splits, embeddings)
retriever = vector_store.as_retriever(search_kwargs={"k": 4})

# 5. Cấu hình Prompt nghiêm ngặt cho Chatbot Tài chính 
template = """Bạn là trợ lý AI thông minh trong ứng dụng "Fintech Wallet" — ứng dụng quản lý tài chính cá nhân và nhóm dành cho người dùng Việt Nam.

QUY TẮC QUAN TRỌNG:
1. LUÔN trả về đúng một JSON hợp lệ, KHÔNG có markdown (không dùng ```json), KHÔNG có văn bản thừa ngoài JSON.
2. Trả lời bằng Tiếng Việt, thân thiện và chuyên nghiệp.
3. Sử dụng "Thông tin người dùng" hoặc "Ngữ cảnh ứng dụng" để lấy dữ liệu thực tế thay vì tự bịa ra. Nếu người dùng hỏi số dư, hãy xem trong "Thông tin người dùng".
4. Khi người dùng hỏi thông tin, tư vấn → trả về: {{"action": "none", "message": "Câu trả lời..."}}
5. Khi người dùng muốn đi đến một trang cụ thể → GỢI Ý và hỏi xác nhận: {{"action": "navigate", "target": "TÊN_TRANG", "message": "Giải thích..."}}
Danh sách trang hợp lệ: home, budget, group_wallet, settings, deposit, transfer, send_money, profile, notifications, transaction_history.

THÔNG TIN NGƯỜI DÙNG:
{user_context}

LỊCH SỬ TRÒ CHUYỆN:
{history_str}

NGỮ CẢNH ỨNG DỤNG:
{context}

CÂU HỎI HIỆN TẠI:
{question}

TRẢ LỜI (Chỉ xuất JSON):"""

prompt = ChatPromptTemplate.from_template(template)

# 6. Thiết lập RAG Pipeline Chain
rag_chain = (
    prompt
    | llm
    | StrOutputParser()
)

class ChatMessage(BaseModel):
    role: str
    content: str

class QueryRequest(BaseModel):
    question: str
    history: Optional[List[ChatMessage]] = []
    user_context: Optional[str] = ""

def format_history(history: List[ChatMessage]):
    if not history:
        return "Không có"
    return "\n".join([f"{msg.role}: {msg.content}" for msg in history])

@app.post("/api/chat")
async def chat_with_financial_bot(request: QueryRequest):
    try:
        # Lấy tài liệu từ Vector DB
        context_docs = retriever.invoke(request.question)
        context_str = "\n\n".join([doc.page_content for doc in context_docs])
        
        history_str = format_history(request.history)
        
        response = rag_chain.invoke({
            "context": context_str,
            "user_context": request.user_context,
            "history_str": history_str,
            "question": request.question
        })
        
        # Thử loại bỏ các ký tự markdown JSON thừa nếu LLM tự chèn
        clean_response = response.strip()
        if clean_response.startswith("```json"):
            clean_response = clean_response[7:]
        if clean_response.startswith("```"):
            clean_response = clean_response[3:]
        if clean_response.endswith("```"):
            clean_response = clean_response[:-3]
            
        return {"answer": clean_response.strip()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))