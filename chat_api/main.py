from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from fastapi.responses import StreamingResponse
import json


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

import openai

# Set up your OpenAI API credentials
openai.api_key = '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'

import os
import openai



def generate_chat_response(message):
    completion = openai.ChatCompletion.create(
        model="gpt-3.5-turbo",
        messages=[
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": message}
        ]
    )

    print(completion.choices[0].message.content)

    return completion.choices[0].message.content

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
