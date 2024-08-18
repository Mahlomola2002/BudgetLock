import os
import asyncio
from groq import AsyncGroq
from dotenv import load_dotenv
from typing import List, Any
from gtts import gTTS
import pygame
import tempfile
import pandas as pd
from datetime import datetime, timedelta
import time
from index import PDFProcessor  # Import the PDFProcessor class

class FinancialAssistant:
    def __init__(self, model_name: str = "llama3-8b-8192"):
        load_dotenv()
        self.groq_api = os.getenv('GROQ_API')
        if self.groq_api is None:
            raise ValueError("GROQ_API environment variable is not set")
        
        self.client = AsyncGroq(api_key=self.groq_api)
        self.model_name = model_name
        self.conversation_history = []
        pygame.mixer.init()
        self.tts_cache = {}
        
        self.financial_data = None
        self.pdf_processor = PDFProcessor()  # Initialize the PDFProcessor
        
        self.personalities = {
            "conservative": """You are a conservative financial advisor. Prioritize saving and minimizing risk in your advice.""",
            "balanced": """You are a balanced financial advisor. Provide advice that balances saving and spending for a comfortable lifestyle.""",
            "growth-oriented": """You are a growth-oriented financial advisor. Focus on opportunities for financial growth and investment."""
        }
        self.current_personality = "balanced"

    # ... [keep the speak method unchanged] ...

    async def load_financial_data(self, csv_path: str):
        self.financial_data = pd.read_csv(csv_path)
        self.financial_data['Date'] = pd.to_datetime(self.financial_data['Date'])

    async def load_financial_documents(self, pdf_path: str, index_name: str = "financial_docs_index"):
        await asyncio.to_thread(self.pdf_processor.load_and_process_pdf, pdf_path, index_name)

    async def load_existing_index(self, index_name: str):
        await asyncio.to_thread(self.pdf_processor.load_index, index_name)

    async def analyze_spending(self, start_date: datetime, end_date: datetime):
        if self.financial_data is None:
            raise ValueError("No financial data loaded. Please load data first.")
        
        period_data = self.financial_data[(self.financial_data['Date'] >= start_date) & (self.financial_data['Date'] <= end_date)]
        total_spent = period_data['Amount'].sum()
        spending_by_category = period_data.groupby('Category')['Amount'].sum().to_dict()
        
        return total_spent, spending_by_category

    async def generate_budget(self, query: str, previous_spending: dict, income: float) -> str:
        spending_summary = "\n".join([f"{category}: ${amount:.2f}" for category, amount in previous_spending.items()])
        total_spent = sum(previous_spending.values())
        
        # Query the financial documents for relevant information
        doc_query = f"Provide advice on budgeting and financial planning related to: {query}"
        doc_response = await asyncio.to_thread(self.pdf_processor.query, doc_query)
        
        prompt = f"""
        Previous month's spending:
        {spending_summary}
        
        Total spent: ${total_spent:.2f}
        Monthly income: ${income:.2f}
        
        User Query: {query}
        
        Relevant financial advice from documents:
        {doc_response}
        
        Based on this information, please provide:
        1. A detailed budget allocation for next month, broken down by category.
        2. Specific recommendations for adjusting spending habits.
        3. Suggestions for potential savings opportunities.
        4. Any categories where spending could be reduced or optimized.
        5. A brief explanation of your recommendations, incorporating the relevant advice from the financial documents.

        Response:
        """

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

    # ... [keep the query, summarize_conversation, and set_personality methods unchanged] ...
    async def query(self, user_input: str, income: float) -> str:
        print("Analyzing your financial data...", end="", flush=True)
        last_month = datetime.now().replace(day=1) - timedelta(days=1)
        start_date = last_month.replace(day=1)
        end_date = last_month
        
        total_spent, spending_by_category = await self.analyze_spending(start_date, end_date)
        
        response = await self.generate_budget(user_input, spending_by_category, income)
        print("\rHere's the financial advice:           ")  # Clear the "Analyzing" message
        await self.speak(response)
        return response

    async def summarize_conversation(self):
        conversation = "\n".join([f"User: {msg['user']}\nFinancial Advisor: {msg['ai']}" for msg in self.conversation_history])
        prompt = f"Please provide a concise summary of the following financial advice conversation:\n\n{conversation}\n\nSummary:"

        chat_completion = await self.client.chat.completions.create(
            messages=[
                {"role": "system", "content": "You are a helpful AI assistant tasked with summarizing financial advice conversations."},
                {"role": "user", "content": prompt},
            ],
            model=self.model_name,
        )

        summary = chat_completion.choices[0].message.content
        return summary

    async def set_personality(self, personality: str):
        if personality in self.personalities:
            self.current_personality = personality
            return f"Financial advising style set to {personality}."
        else:
            return "Invalid style. Please choose from: " + ", ".join(self.personalities.keys())


async def main():
    assistant = FinancialAssistant()
    
    print("Loading financial data...")
    await assistant.load_financial_data("expense.csv")  # Use the correct path to your CSV file
    print("Financial data loaded successfully!")

    # Personality selection at the start
    while True:
        print("\nSelect a financial advising style:")
        print("1. Conservative")
        print("2. Balanced")
        print("3. Growth-oriented")
        choice = input("Enter your choice (1/2/3): ")
        
        if choice == '1':
            await assistant.set_personality("conservative")
            break
        elif choice == '2':
            await assistant.set_personality("balanced")
            break
        elif choice == '3':
            await assistant.set_personality("growth-oriented")
            break
        else:
            print("Invalid choice. Please try again.")

    income = float(input("Please enter your monthly income: $"))

    greeting = f"Hello! I'm your {assistant.current_personality} financial advisor. How can I assist you with your finances today?"
    print("Financial Advisor:", greeting)
    
    assistant.conversation_history.append({"user": "", "ai": greeting})

    while True:
        user_query = input("You: ")

        if user_query.lower() in ['exit', 'quit', 'bye']:
            break
        
        response = await assistant.query(user_query, income)
        print(f"Financial Advisor: {response}")

    # Offer summary at the end of the conversation
    summary_choice = input("Would you like a summary of our financial advice conversation? (yes/no): ")
    if summary_choice.lower() == 'yes':
        summary = await assistant.summarize_conversation()
        print("\nConversation Summary:")
        print(summary)
        

    farewell = "Thank you for using our financial advisory service. Have a great day and remember to stick to your budget!"
    print("Financial Advisor:", farewell)
    

if __name__ == "__main__":
    asyncio.run(main())