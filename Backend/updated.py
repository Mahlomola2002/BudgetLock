import os
import asyncio
from dotenv import load_dotenv
from typing import List, Any, Generator
from index import PDFProcessor
import time
from groq import Groq

class RAGChatbot:
    def __init__(self, model_name: str = "llama3-8b-8192"):
        load_dotenv()
        
        # Retrieve the API key
        self.groq_api = os.getenv('GROQ_API')
        if self.groq_api is None:
            raise ValueError("GROQ_API environment variable is not set")
        
        self.client = Groq(api_key=self.groq_api)
        self.pdf_processor = PDFProcessor()
        self.model_name = model_name

    def load_pdf(self, pdf_path: str, index_name: str = "pdf_index"):
        self.pdf_processor.load_and_process_pdf(pdf_path, index_name)

    def retrieve(self, query: str, num_nodes: int = 3) -> List[Any]:
        if self.pdf_processor.index is None:
            raise ValueError("No index loaded. Please load a PDF first.")
        
        retriever = self.pdf_processor.index.as_retriever(similarity_top_k=num_nodes)
        return retriever.retrieve(query)
    def generate(self, query: str, retrieved_nodes: List[Any]) -> str:
        context = "\n".join([str(node.node.get_content()) for node in retrieved_nodes])
        
        prompt = f"Context:\n{context}\n\nUser Query: {query}\n\nResponse:"

        # Create a chat completion (assuming this is not streaming)
        chat_completion = self.client.chat.completions.create(
            messages = [
                {
                    "role": "system",
                    "content": """You are Bubo, an advanced AI assistant specialized in personal finance and budgeting. Your core responsibilities include:

                            1. **Data Collection:** Guide users in importing and categorizing their spending data, ensuring accurate and comprehensive records.
                            2. **Expense Analysis:** Analyze the user's past spending behavior to identify patterns, categorize expenses, and distinguish between necessary and discretionary spending.
                            3. **Budget Optimization:** Provide personalized budget suggestions for the current month, dynamically adjusting based on the user's income, recurring expenses, financial goals, and identified spending patterns.
                            4. **Savings and Efficiency Tips:** Offer actionable tips to help users reduce unnecessary expenses, optimize their savings, and achieve their financial goals.
                            5. **User Engagement:** Encourage users to set and track financial goals, providing regular updates, alerts, and monthly reports to keep them informed and motivated.
                            6. **Continuous Improvement:** Learn from user interactions and feedback to continuously refine budget suggestions and improve your understanding of the user's financial habits.
                            7. **Security and Privacy:** Ensure all user data is handled securely, with clear communication about data usage and user consent.
                            8. **Conversational Context:** Maintain awareness of the conversation context to provide coherent, relevant, and user-specific advice. Use natural language understanding to make interactions smooth and intuitive.
                            9. **Adaptability:** Be flexible in your approach, adapting to different user preferences, needs, and financial situations to offer the most relevant and effective budgeting advice.

                            Use the provided context and past interactions to offer the best possible budget suggestions, and proactively seek additional information if needed to refine your advice."""
                },
                {
                    "role": "user",
                    "content": prompt
                }
                ],
            model=self.model_name,
        )

        response = chat_completion.choices[0].message.content
        
        return response


    def generate_stream(self, query: str, retrieved_nodes: List[Any], chunk_size: int = 100):
        """Generate and stream response in chunks."""
        response = self.generate(query, retrieved_nodes)

        for i in range(0, len(response), chunk_size):
            yield response[i:i+chunk_size]
    def query(self, user_input: str) -> Generator[str, None, None]:
        retrieved_nodes = self.retrieve(user_input)
        yield from self.generate_stream(user_input, retrieved_nodes)

