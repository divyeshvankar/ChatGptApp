import os
import openai
import config
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from fastapi.responses import StreamingResponse
import json

openai.api_key = config.API_KEY

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
    # Create a generator function to stream the response line by line
    async def generate_response():
        yield '{"response": ['

        # Define the conversation history with the chat model
        conversation_history = [

            {"role": "user", "content": message.message}
        ]

        # Send the initial system message and user message to OpenAI API
        for i, msg in enumerate(conversation_history):
            if i > 0:
                yield ','
            yield json.dumps(msg)

        # Process the incoming message and generate a response
        completion = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=conversation_history
        )

        # Yield each line of the response separately
        for i, choice in enumerate(completion.choices):
            if choice:
                yield ','
            yield json.dumps(choice.message)

        yield "]}"
      
    # Return the StreamingResponse to stream the response line by line
    return StreamingResponse(generate_response(), media_type="application/json")
