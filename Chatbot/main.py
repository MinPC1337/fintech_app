from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_experimental.text_splitter import SemanticChunker
import os
from langchain_community.document_loaders import DirectoryLoader, UnstructuredFileLoader
from langchain_ollama import OllamaEmbeddings, ChatOllama
from langchain_community.vectorstores import FAISS
from langchain_community.vectorstores.faiss import DistanceStrategy
from langchain_core.prompts import ChatPromptTemplate
from langchain_core.runnables import RunnablePassthrough
from langchain_core.output_parsers import StrOutputParser

# ==========================================
# BƯỚC 1: LOAD TÀI LIỆU (DOCUMENT LOADING)
# ==========================================
# Đọc tất cả các file .pdf từ thư mục 'papers' sử dụng UnstructuredFileLoader
loader = DirectoryLoader(
    path="./data",
    glob="**/*.*",
    loader_cls=UnstructuredFileLoader,
    show_progress=True,
    use_multithreading=True
)
docs = loader.load()
print(f"Đã load {len(docs)} tài liệu gốc.")

# ==========================================
# BƯỚC 2: CHIA NHỎ VĂN BẢN (TRUNKING / TEXT SPLITTING)
# ==========================================
# Định nghĩa các ký tự phân tách tự nhiên theo định dạng Markdown
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

# Khởi tạo mô hình Embedding (sử dụng mô hình của Ollama)
embedding_model = OllamaEmbeddings(model="qwen3-embedding")

# text_splitter = SemanticChunker(
#     embedding_model, 
#     breakpoint_threshold_type="percentile", # Hoặc dùng "standard_deviation"
#     breakpoint_threshold_amount=0.85
# )

splits = text_splitter.split_documents(docs)
print(f"Đã chia tài liệu thành {len(splits)} chunks nhỏ.")
# Muốn xem cấu trúc các chunk có thể dùng: pprint(splits)

# ==========================================
# BƯỚC 3: EMBEDDING & VECTOR DATABASE (FAISS)
# ==========================================

# Tạo Vector Store từ các đoạn văn bản đã chia nhỏ
vector_store = FAISS.from_documents(
    documents=splits,
    embedding=embedding_model,
    distance_strategy=DistanceStrategy.COSINE # Sử dụng Cosine Similarity để so sánh vector
)

# Thiết lập bộ truy xuất dữ liệu (Retriever)
retriever = vector_store.as_retriever(
    search_type="similarity_score_threshold",
    search_kwargs={
        "k": 5,                     # Lấy tối đa 5 chunks tương đồng nhất
        "score_threshold": 0.2      # Chỉ lấy các chunk có độ tương đồng vượt ngưỡng 0.2
    }
)

# ==========================================
# BƯỚC 4: THIẾT KẾ PROMPT TEMPLATE
# ==========================================
template = """
Bạn là trợ lý ảo tài chính cá nhân được tích hợp sẵn trong ứng dụng Fintech Wallet.
Nhiệm vụ của bạn là: Giải đáp thắc mắc về ứng dụng, hướng dẫn sử dụng các tính năng, phân tích tình hình tài chính của người dùng dựa trên dữ liệu, và điều hướng (navigate) người dùng đến đúng màn hình họ cần.
Tone giọng: Lịch sự, thân thiện, chuyên nghiệp, luôn dùng Tiếng Việt chuẩn. Xưng "tôi" và gọi người dùng là "bạn".
Tuyệt đối: Không bịa đặt số liệu tài chính. Nếu người dùng hỏi về số dư hay giao dịch.
Quan trọng: Phải trả lời bằng tiếng việt

Context:
{context}

Question:
{question}

Answer:
"""
chat_prompt_template = ChatPromptTemplate.from_template(template)

# ==========================================
# BƯỚC 5: KHỞI TẠO LLM & ĐỊNH NGHĨA PIPELINE (RAG CHAIN)
# ==========================================
# Sử dụng mô hình Ollama với temperature = 0 (đảm bảo câu trả lời chính xác, ít sáng tạo)
llm = ChatOllama(model="qwen2.5:7b", temperature=0)

# Xây dựng LCEL Chain (LangChain Expression Language)
rag_chain = (
    {
        "context": retriever, 
        "question": RunnablePassthrough()
    }
    | chat_prompt_template
    | llm
    | StrOutputParser() # Chuyển kết quả AI trả về thành dạng chuỗi văn bản thuần túy
)

# ==========================================
# BƯỚC 6: CHẠY THỬ NGHIỆM CHATBOT
# ==========================================
if __name__ == "__main__":
    question = input("Nhập câu hỏi của bạn: ")
    print("\nĐang tìm câu trả lời...\n")
    
    answer = rag_chain.invoke(question)
    print("Câu trả lời từ Chatbot:")
    print(answer)