# -*- coding: utf-8 -*-

import sys
from pathlib import Path

# Add backend folder to sys.path
sys.path.append(str(Path(__file__).resolve().parent.parent))

from services.grammar_service import GrammarCorrectionService

def run_test():
    service = GrammarCorrectionService()
    
    test_cases = [
        "She go to school.",
        "She go school yesterday.",
        "I has a apple."
    ]
    
    print("==================================================")
    print("🔍 KIỂM TRA LOGIC SỬA LỖI NGỮ PHÁP GEC")
    print("==================================================")
    
    for text in test_cases:
        print(f"\n📝 Câu đầu vào: '{text}'")
        res = service.correct_text(text)
        print(f"✅ Câu đã sửa: '{res['corrected']}'")
        print(f"💡 Giải thích:  {res['explanation']}")
        print("🛠️ Chi tiết lỗi thay đổi (Changes):")
        for i, change in enumerate(res['changes'], 1):
            print(f"  {i}. Sai: '{change['wrong']}' -> Đúng: '{change['correct']}' (Lý do: {change['reason']})")
        print("-" * 50)

if __name__ == "__main__":
    run_test()
