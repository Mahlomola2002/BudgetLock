import os
import asyncio
from groq import AsyncGroq
from dotenv import load_dotenv
from typing import List, Any
from gtts import gTTS
import pygame
import tempfile
from index import PDFProcessor
import time

class RAGChatbot:
    def __init__(self, model_name: str = "llama3-8b-8192"):
        load_dotenv()
        self.groq_api = os.getenv('GROQ_API')
        if self.groq_api is None:
            raise ValueError("GROQ_API environment variable is not set")
        
        self.client = AsyncGroq(api_key=self.groq_api)
        self.pdf_processor = PDFProcessor()
        self.model_name = model_name
        self.conversation_history = []
        pygame.mixer.init()
        self.tts_cache = {}
        
        self.personalities = {
            "professional": """You are ArcAI, a professional and efficient AI assistant. Your responses should be concise, accurate, and formal.""",
            "friendly": """You are ArcAI, a friendly and approachable AI assistant. Your responses should be warm, engaging, and conversational, while still being informative.""",
            "creative": """You are ArcAI, a creative and imaginative AI assistant. Your responses should be innovative, thought-provoking, and include analogies or metaphors when appropriate."""
        }
        self.current_personality = "professional"

    async def speak(self, text: str):
        if text in self.tts_cache:
            temp_filename = self.tts_cache[text]
        else:
            tts = gTTS(text=text, lang='en')
            with tempfile.NamedTemporaryFile(delete=False, suffix=".mp3") as fp:
                temp_filename = fp.name
                tts.save(temp_filename)
                self.tts_cache[text] = temp_filename

        pygame.mixer.music.load(temp_filename)
        pygame.mixer.music.play()
        while pygame.mixer.music.get_busy():
            await asyncio.sleep(0.1)

    async def load_pdf(self, pdf_path: str, index_name: str = "pdf_index"):
        await asyncio.to_thread(self.pdf_processor.load_and_process_pdf, pdf_path, index_name)

    async def load_existing_index(self, index_name: str):
        await asyncio.to_thread(self.pdf_processor.load_index, index_name)

    async def retrieve(self, query: str, num_nodes: int = 3) -> List[Any]:
        if self.pdf_processor.index is None:
            raise ValueError("No index loaded. Please load a PDF or an existing index first.")
        
        retriever = self.pdf_processor.index.as_retriever(similarity_top_k=num_nodes)
        return await asyncio.to_thread(retriever.retrieve, query)

    async def generate(self, query: str, retrieved_nodes: List[Any]) -> str:
        context = "\n".join([str(node.node.get_content()) for node in retrieved_nodes])
        conversation_history = "\n".join([f"User: {msg['user']}\nArcAI: {msg['ai']}" for msg in self.conversation_history[-5:]])
        prompt = f"Conversation history:\n{conversation_history}\n\nContext:\n{context}\n\nUser Query: {query}\n\nResponse:"

        chat_completion = await self.client.chat.completions.create(
            messages=[
                {"role": "system", "content": self.personalities[self.current_personality]},
                {"role": "user", "content": prompt},
            ],
            model=self.model_name,
        )

        response = chat_completion.choices[0].message.content
        self.conversation_history.append({"user": query, "ai": response})
        return response

    async def query(self, user_input: str) -> str:
        print("Processing your query...", end="", flush=True)
        retrieved_nodes = await self.retrieve(user_input)
        response = await self.generate(user_input, retrieved_nodes)
        print("\rHere's the response:           ")  # Clear the "Processing" message
        await self.speak(response)
        return response

    async def summarize_conversation(self):
        conversation = "\n".join([f"User: {msg['user']}\nArcAI: {msg['ai']}" for msg in self.conversation_history])
        prompt = f"Please provide a concise summary of the following conversation:\n\n{conversation}\n\nSummary:"

        chat_completion = await self.client.chat.completions.create(
            messages=[
                {"role": "system", "content": "You are a helpful AI assistant tasked with summarizing conversations."},
                {"role": "user", "content": prompt},
            ],
            model=self.model_name,
        )

        summary = chat_completion.choices[0].message.content
        return summary

    async def set_personality(self, personality: str):
        if personality in self.personalities:
            self.current_personality = personality
            return f"Personality set to {personality}."
        else:
            return "Invalid personality. Please choose from: " + ", ".join(self.personalities.keys())

async def main():
    chatbot = RAGChatbot()
    
    print("Loading PDF...")
    await chatbot.load_pdf("data/data.pdf", "my_pdf_index")
    print("PDF loaded successfully!")

    # Personality selection at the start
    while True:
        print("\nSelect a personality for ArcAI:")
        print("1. Professional")
        print("2. Friendly")
        print("3. Creative")
        choice = input("Enter your choice (1/2/3): ")
        
        if choice == '1':
            await chatbot.set_personality("professional")
            break
        elif choice == '2':
            await chatbot.set_personality("friendly")
            break
        elif choice == '3':
            await chatbot.set_personality("creative")
            break
        else:
            print("Invalid choice. Please try again.")

    greeting = f"Hello! I'm ArcAI, your {chatbot.current_personality} assistant. How can I assist you today?"
    print("ArcAI:", greeting)
    await chatbot.speak(greeting)
    chatbot.conversation_history.append({"user": "", "ai": greeting})

    while True:
        user_query = input("You: ")

        if user_query.lower() in ['exit', 'quit', 'bye']:
            break
        
        start_time = time.time()
        response = await chatbot.query(user_query)
        end_time = time.time()
        
        print(f"ArcAI: {response}")
        print(f"Response time: {end_time - start_time:.2f} seconds")

    # Offer summary at the end of the conversation
    summary_choice = input("Would you like a summary of our conversation? (yes/no): ")
    if summary_choice.lower() == 'yes':
        summary = await chatbot.summarize_conversation()
        print("\nConversation Summary:")
        print(summary)
        await chatbot.speak(summary)

    farewell = "Goodbye! Have a great day!"
    print("ArcAI:", farewell)
    await chatbot.speak(farewell)

if __name__ == "__main__":
    asyncio.run(main())