# AppLearnEnglish AI FastAPI Backend

FastAPI Backend phục vụ các tính năng AI học tiếng Anh, đặc biệt là tích hợp mô hình sửa lỗi ngữ pháp **Local GEC Model (FLAN-T5 Base + LoRA adapter)**.

---

## 🛠️ Cài đặt Môi trường (Setup)

1. **Khởi tạo và kích hoạt virtual environment**:
   Vì Backend sử dụng các thư viện AI lớn, khuyến khích sử dụng chung môi trường ảo `venv` của AI nếu chạy cùng máy, hoặc cài đặt độc lập:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Cấu hình biến môi trường**:
   Tạo tệp `.env` dựa trên file mẫu `.env.example`:
   ```bash
   cp .env.example .env
   ```
   Các tham số cấu hình:
   - `BASE_MODEL`: Tên mô hình gốc (Mặc định: `google/flan-t5-base`).
   - `MODEL_PATH`: Đường dẫn tuyệt đối hoặc tương đối trỏ đến thư mục LoRA adapter (Mặc định: `../AI/checkpoints/checkpoint-final`).
   - `DEVICE`: Thiết bị chạy (`mps` cho Apple Silicon, `cuda` cho GPU NVIDIA, hoặc `cpu`).
   - `GEMINI_API_KEY`: Khóa API Gemini dùng làm phương án dự phòng (Fallback) khi mô hình local không khả dụng.

---

## 🚀 Chạy Server cục bộ

Khởi chạy server uvicorn cục bộ (phục vụ kết nối từ iOS Simulator trên cổng `8000`):
```bash
uvicorn main:app --reload --port 8000
```
Server sẽ tự động kích hoạt tiến trình nạp (Pre-load) mô hình GEC vào RAM khi khởi động để tối ưu tốc độ phản hồi cho các request tiếp theo.

---

## 🧪 Chạy Kiểm thử (Unit Tests)

Chạy bộ kiểm thử tự động của Backend:
```bash
pytest tests/test_grammar.py
```

Hoặc kiểm tra thủ công qua API:
- **Endpoint**: `POST http://localhost:8000/api/correct`
- **Request Body**:
  ```json
  {
    "text": "I has a apple."
  }
  ```
- **Response Output**:
  ```json
  {
    "original": "I has a apple.",
    "corrected": "I have an apple.",
    "explanation": "Đã tìm thấy và sửa các lỗi: Thay đổi từ 'has' thành 'have'., Thay đổi từ 'a' thành 'an'.",
    "changes": [
      {
        "wrong": "has",
        "correct": "have",
        "reason": "Thay đổi từ 'has' thành 'have'."
      },
      {
        "wrong": "a",
        "correct": "an",
        "reason": "Thay đổi từ 'a' thành 'an'."
      }
    ]
  }
  ```
