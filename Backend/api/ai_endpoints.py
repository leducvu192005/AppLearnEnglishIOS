import os
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
import google.generativeai as genai

router = APIRouter(prefix="/api")

# Configure Gemini API Key if available
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
gemini_available = False

if GEMINI_API_KEY:
    try:
        genai.configure(api_key=GEMINI_API_KEY)
        # Using Gemini 1.5 Flash as the default fast and cost-effective model
        model = genai.GenerativeModel("gemini-1.5-flash")
        gemini_available = True
        print("Successfully configured Gemini API.")
    except Exception as e:
        print(f"Error configuring Gemini API: {e}")

# MARK: - Request/Response Models

class ExplainWordRequest(BaseModel):
    word: str

class ExplainWordResponse(BaseModel):
    word: str
    meaning: str
    explanation: str
    examples: List[str]

class ExampleRequest(BaseModel):
    word: str
    level: str  # e.g., "Beginner", "Intermediate", "Advanced"

class ExampleResponse(BaseModel):
    word: str
    level: str
    sentence: str

class CorrectionRequest(BaseModel):
    text: str

class CorrectionResponse(BaseModel):
    original: str
    corrected: str
    explanation: str

class ChatMessage(BaseModel):
    role: str  # "user" or "model" / "assistant"
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]

class ChatResponse(BaseModel):
    reply: str

# MARK: - Endpoints

@router.post("/explain-word", response_model=ExplainWordResponse)
async def explain_word(request: ExplainWordRequest):
    word = request.word.strip().lower()
    
    if gemini_available:
        try:
            prompt = (
                f"Explain the English word '{word}'. "
                "Format the response EXACTLY as a JSON object with these keys: "
                "'meaning' (Vietnamese translation), "
                "'explanation' (simple explanation in English suitable for learners), "
                "'examples' (list of 2 simple example sentences in English using the word). "
                "Return only the raw JSON. Do not include markdown code block syntax."
            )
            response = model.generate_content(prompt)
            # Safe JSON parsing
            import json
            raw_text = response.text.strip()
            # Strip markdown block wraps if model included them
            if raw_text.startswith("```"):
                lines = raw_text.split("\n")
                raw_text = "\n".join(lines[1:-1]) if lines[-1].startswith("```") else "\n".join(lines[1:])
            data = json.loads(raw_text.strip())
            return ExplainWordResponse(
                word=word,
                meaning=data.get("meaning", "N/A"),
                explanation=data.get("explanation", "N/A"),
                examples=data.get("examples", [])
            )
        except Exception as e:
            print(f"Gemini explain_word failed: {e}. Falling back to mock data.")
            
    # Mock Data Fallback
    mock_explanations = {
        "airport": {
            "meaning": "Sân bay",
            "explanation": "A place where aircraft land and take off, which has buildings for passengers to wait in.",
            "examples": ["I arrive at the airport two hours before my flight.", "The airport is very crowded today."]
        },
        "passport": {
            "meaning": "Hộ chiếu",
            "explanation": "An official document issued by a government, certifying the holder's identity and citizenship, entitling them to travel under its protection to and from foreign countries.",
            "examples": ["Do not forget your passport when traveling abroad.", "The officer stamped my passport."]
        }
    }
    
    word_info = mock_explanations.get(word, {
        "meaning": f"Nghĩa của từ '{word}'",
        "explanation": f"This is an English vocabulary word: '{word}'. Please set your GEMINI_API_KEY environment variable to get real AI-powered explanations.",
        "examples": [f"This is an example sentence with the word {word}.", f"Can you use the word {word} in a sentence?"]
    })
    
    return ExplainWordResponse(
        word=word,
        meaning=word_info["meaning"],
        explanation=word_info["explanation"],
        examples=word_info["examples"]
    )


@router.post("/example", response_model=ExampleResponse)
async def generate_example(request: ExampleRequest):
    word = request.word.strip()
    level = request.level.strip()
    
    if gemini_available:
        try:
            prompt = (
                f"Create a simple English example sentence using the word '{word}' "
                f"suitable for a student at '{level}' proficiency level. "
                "Keep the sentence short, clear, and return ONLY the sentence text itself, nothing else."
            )
            response = model.generate_content(prompt)
            return ExampleResponse(word=word, level=level, sentence=response.text.strip())
        except Exception as e:
            print(f"Gemini example failed: {e}. Falling back to mock data.")
            
    return ExampleResponse(
        word=word,
        level=level,
        sentence=f"This is a mock example sentence using '{word}' for a '{level}' learner."
    )


@router.post("/correct", response_model=CorrectionResponse)
async def correct_grammar(request: CorrectionRequest):
    text = request.text.strip()
    
    if gemini_available:
        try:
            prompt = (
                f"Analyze and correct the English grammar in the following text: '{text}'. "
                "Format the response EXACTLY as a JSON object with these keys: "
                "'corrected' (the corrected text, or the original text if no errors exist), "
                "'explanation' (a brief explanation of the errors in Vietnamese). "
                "Return only the raw JSON. Do not include markdown code block syntax."
            )
            response = model.generate_content(prompt)
            import json
            raw_text = response.text.strip()
            if raw_text.startswith("```"):
                lines = raw_text.split("\n")
                raw_text = "\n".join(lines[1:-1]) if lines[-1].startswith("```") else "\n".join(lines[1:])
            data = json.loads(raw_text.strip())
            return CorrectionResponse(
                original=text,
                corrected=data.get("corrected", text),
                explanation=data.get("explanation", "Không có lỗi sai nào được phát hiện.")
            )
        except Exception as e:
            print(f"Gemini correct failed: {e}. Falling back to mock data.")
            
    # Mock Data Fallback
    if "go yesterday" in text.lower():
        corrected = text.lower().replace("go yesterday", "went yesterday")
        explanation = "Từ 'go' (thì hiện tại) cần chuyển thành 'went' (quá khứ đơn) vì có trạng ngữ chỉ thời gian quá khứ là 'yesterday'."
    else:
        corrected = text
        explanation = "[Mẫu] Đã kiểm tra ngữ pháp. Hãy đặt biến môi trường GEMINI_API_KEY để AI phân tích lỗi thực tế."
        
    return CorrectionResponse(original=text, corrected=corrected, explanation=explanation)


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest):
    if gemini_available:
        try:
            # Map conversation messages to Gemini Chat format
            chat_history = []
            for msg in request.messages[:-1]:
                # Gemini expects role to be either 'user' or 'model'
                role = "user" if msg.role == "user" else "model"
                chat_history.append({"role": role, "parts": [msg.content]})
            
            # Start Gemini Chat session
            system_instruction = (
                "You are an friendly English learning assistant named Owl Tutor. "
                "You help the user practice conversational English. Speak in simple English. "
                "Keep your answers short (2-3 sentences max). If they make a grammatical error, "
                "politely correct it at the beginning of your message, then continue the conversation."
            )
            
            chat_session = genai.GenerativeModel(
                model_name="gemini-1.5-flash",
                system_instruction=system_instruction
            ).start_chat(history=chat_history)
            
            last_message = request.messages[-1].content
            response = chat_session.send_message(last_message)
            return ChatResponse(reply=response.text.strip())
            
        except Exception as e:
            print(f"Gemini chat failed: {e}. Falling back to mock response.")
            
    # Mock Data Fallback
    user_msg = request.messages[-1].content.lower()
    if "hello" in user_msg or "hi" in user_msg:
        reply = "Hello! I am Owl Tutor. How are you feeling today? Let's practice English!"
    elif "how are you" in user_msg:
        reply = "I'm doing great, thank you! What did you do today?"
    else:
        reply = f"I received your message: '{request.messages[-1].content}'. Set your GEMINI_API_KEY to start real conversations!"
        
    return ChatResponse(reply=reply)
