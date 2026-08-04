import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

from contextlib import asynccontextmanager
from services.model_loader import load_grammar_model

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Load model on server start to cache in RAM
    print("[INFO] Pre-loading local GEC model on startup...")
    load_grammar_model()
    yield
    print("[INFO] Shutting down server and releasing GEC model resources...")

app = FastAPI(
    title="AppLearnEnglish AI Backend",
    description="FastAPI Backend for AI-powered English learning features",
    version="1.0.0",
    lifespan=lifespan
)

# Configure CORS to allow access from the iOS Simulator
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all HTTP methods (POST, GET, OPTIONS, etc.)
    allow_headers=["*"],  # Allows all HTTP headers
)

# Import and register the AI endpoints router
from api.ai_endpoints import router as ai_router
app.include_router(ai_router)

@app.get("/")
def read_root():
    return {
        "status": "online",
        "message": "Welcome to AppLearnEnglish AI Backend. The server is ready."
    }

if __name__ == "__main__":
    # Run the server locally on port 8000
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
