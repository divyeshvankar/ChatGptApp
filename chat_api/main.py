
import os
import openai
import config

openai.api_key = config.API_KEY




from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()

# Enable CORS to allow cross-origin requests
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["*"],
)

class Message(BaseModel):
    message: str

@app.options("/chat")
async def chat_options():
    return {}

@app.post("/chat")
async def chat(message: Message):
    # Process the incoming message and generate a response
    response = generate_chat_response(message.message)

    return {"response": response}


def generate_chat_response(message):
    # Define the conversation history with the chat model
    conversation_history = [
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": message}
    ]
      
    completion = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": message}
        ]
    )

    print(completion.choices[0].message)

    return completion.choices[0].message

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
