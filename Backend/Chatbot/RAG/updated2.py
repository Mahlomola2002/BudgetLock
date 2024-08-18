import os
import asyncio
from groq import AsyncGroq
from dotenv import load_dotenv
from typing import List, Any, AsyncGenerator

import time

class RAGChatbot:
    def __init__(self, model_name: str = "llama3-70b-8192"):
        load_dotenv()
        self.groq_api = os.getenv('GROQ_API')
        if self.groq_api is None:
            raise ValueError("GROQ_API environment variable is not set")
        
        self.client = AsyncGroq(api_key=self.groq_api)
        self.website_processor = WebsiteProcessor()
        self.model_name = model_name
        self.conversation_history = []
        self.feedback_log = []
        self.personalities = {
            "professional": """You are ArcAI, a professional and efficient AI assistant. Your responses should be concise, accurate, and formal.""",
            "friendly": """You are ArcAI, a friendly and approachable AI assistant. Your responses should be warm, engaging, and conversational, while still being informative.""",
            "creative": """You are ArcAI, a creative and imaginative AI assistant. Your responses should be innovative, thought-provoking, and include analogies or metaphors when appropriate.""",
            "Advisor": """You are a Safety AI Bot designed to help users determine the safest places to visit based on various safety parameters. Your primary goal is to provide accurate, up-to-date, and helpful safety advice. Here are your main responsibilities:

Safety Assessment: Evaluate the safety of locations based on crime rates, recent incidents, local regulations, and other relevant data.

Recommendations: Suggest safe places to visit and activities to engage in, tailored to the user's preferences and current safety conditions.

Alert Notifications: Inform users of any safety alerts, advisories, or significant changes in safety conditions for their areas of interest.

Travel Tips: Provide general safety tips for travel, such as avoiding certain areas at night, staying aware of surroundings, and emergency contact information.

User Interaction: Engage with users in a friendly, informative manner, answering their questions about safety and providing personalized advice.

Continuous Learning: Stay updated with the latest safety data and trends to ensure the most accurate advice is given."""
        }

        self.current_personality = "professional"

    async def load_website(self, url: str, index_name: str = "website_index"):  # New method
        await asyncio.to_thread(self.website_processor.load_and_process_website, url, index_name)

    async def load_existing_index(self, index_name: str):
        await asyncio.to_thread(self.website_processor.load_index, index_name)

    async def retrieve(self, query: str, num_nodes: int = 3) -> List[Any]:
        if self.website_processor.index is None:
            raise ValueError("No index loaded. Please load a website or an existing index first.")
        
        retriever = self.website_processor.index.as_retriever(similarity_top_k=num_nodes)
        return await asyncio.to_thread(retriever.retrieve, query)

    async def generate_stream(self, query: str, retrieved_nodes: List[Any]) -> AsyncGenerator[str, None]:
        context = "\n".join([str(node.node.get_content()) for node in retrieved_nodes])
        conversation_history = "\n".join([f"User: {msg['user']}\nArcAI: {msg['ai']}" for msg in self.conversation_history[-5:]])
        
        negative_feedback_count = sum(1 for feedback in self.feedback_log if feedback['feedback'].lower() == 'no')
        feedback_context = f"There have been {negative_feedback_count} instances of negative feedback. Improve the response accordingly."

        prompt = f"Conversation history:\n{conversation_history}\n\nContext:\n{context}\n\nUser Query: {query}\n\nFeedback Context: {feedback_context}\n\nResponse:"

        stream = await self.client.chat.completions.create(
            messages=[
                {"role": "system", "content": self.personalities[self.current_personality]},
                {"role": "user", "content": prompt},
            ],
            model=self.model_name,
            stream=True,
        )

        full_response = ""
        async for chunk in stream:
            if chunk.choices[0].delta.content is not None:
                content = chunk.choices[0].delta.content
                full_response += content
                yield content

        self.conversation_history.append({"user": query, "ai": full_response})

    async def query(self, user_input: str) -> AsyncGenerator[str, None]:
        print("Processing your query...", end="", flush=True)
        retrieved_nodes = await self.retrieve(user_input)
        print("\rHere's the response:           ")  # Clear the "Processing" message
        
        async for response_chunk in self.generate_stream(user_input, retrieved_nodes):
            yield response_chunk

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

    async def get_feedback(self, user_query: str, response: str):
        feedback = input(f"Was this response helpful? (yes/no): ")
        self.feedback_log.append({'query': user_query, 'response': response, 'feedback': feedback})
        
        if feedback.lower() == 'yes':
            print("Great! I'm glad I could help.")
        else:
            print("I'm sorry to hear that. I'll strive to improve.")

async def main():
    chatbot = RAGChatbot()
    

    while True:
        print("\nSelect a personality for ArcAI:")
        print("1. Professional")
        print("2. Friendly")
        print("3. Creative")
        print("4. Advisor")
        choice = input("Enter your choice (1/2/3/4): ")
        
        if choice == '1':
            await chatbot.set_personality("professional")
            break
        elif choice == '2':
            await chatbot.set_personality("friendly")
            break
        elif choice == '3':
            await chatbot.set_personality("creative")
            break
        elif choice == '4':
            await chatbot.set_personality("funny")
            break
        else:
            print("Invalid choice. Please try again.")

    greeting = f"Hello! I'm ArcAI, your {chatbot.current_personality} assistant. How can I assist you today?"
    print("ArcAI:", greeting)
    chatbot.conversation_history.append({"user": "", "ai": greeting})
    user = input("ArcAI: Do you want to add a new website? (yes/no): ")
    while True:
        if user.lower() == 'yes':
            url = input("Enter the website URL: ")
            print("Loading website...")
            await chatbot.load_website(url, "my_website_index")
            print("Website loaded successfully!")
            break
        elif user.lower() == 'no':
            print("Loading existing index...")
            await chatbot.load_existing_index("my_website_index")
            print("Index loaded successfully!")
            break
        else:
            print("Invalid entry")
            user = input("ArcAI: Do you want to add a new website? (yes/no): ")
        
    while True:
        user_query = input("You: ")

        if user_query.lower() in ['exit', 'quit', 'bye']:
            break
        
        start_time = time.time()
        print("ArcAI: ", end="", flush=True)
        full_response = ""
        async for response_chunk in chatbot.query(user_query):
            print(response_chunk, end="", flush=True)
            full_response += response_chunk
        print()  # New line after the complete response
        end_time = time.time()
        
        print(f"Response time: {end_time - start_time:.2f} seconds")

        await chatbot.get_feedback(user_query, full_response)

    summary_choice = input("Would you like a summary of our conversation? (yes/no): ")
    if summary_choice.lower() == 'yes':
        summary = await chatbot.summarize_conversation()
        print("\nConversation Summary:")
        print(summary)

    farewell = "Goodbye! Have a great day!"
    print("ArcAI:", farewell)

if __name__ == "__main__":
    asyncio.run(main())