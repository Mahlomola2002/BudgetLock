import datetime
from http.client import HTTPException
import os
from typing import List
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from updated import RAGChatbot
import pymysql
from pymysql import Connection
from pymysql.cursors import DictCursor
from pydantic import BaseModel
import budgetlockdatabase
from fastapi.responses import JSONResponse  

load_dotenv()

app = FastAPI()

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

chatbot = RAGChatbot()

def get_connection(autocommit: bool = True):
    return budgetlockdatabase.get_connection()

class Budget(BaseModel):
    category_name: str
    amount: float
    emoji: str
class Customer(BaseModel):
    customer_name: str
    email:str
    category: str
class Transaction(BaseModel):
    category_name: str
    amount: float
    email: str
    customer_name: str
    affiliation_number: str
    payment_type: str
    

@app.post("/budgets/")
async def create_budget(budget: Budget):
    try:
        connection = budgetlockdatabase.get_connection()
        with connection.cursor() as cursor:
            sql = "INSERT INTO AppData (category_name, amount, emoji) VALUES (%s, %s, %s)"
            cursor.execute(sql, (budget.category_name, budget.amount, budget.emoji))
        connection.commit()
        return {"message": f"Budget '{budget.category_name}' added successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if connection:
            connection.close()
    
    

@app.get("/budgets/")
async def get_budgets():
    try:
        connection = budgetlockdatabase.get_connection()
        with connection.cursor() as cursor:
            sql = "SELECT * FROM AppData ORDER BY category_name ASC"
            cursor.execute(sql)
            results = cursor.fetchall()
            
            data = [{
                'category_name': row['category_name'],
                'amount': float(row['amount']),  # Convert to float for JSON serialization
                'emoji': row['emoji']
            } for row in results]
            
        return JSONResponse(content=data)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if connection:
            connection.close()

    
@app.delete("/budgets/{category_name}")
async def delete_budget(category_name: str):
    connection = None
    try:
        connection = get_connection()
        with connection.cursor() as cursor:
            sql = "DELETE FROM AppData WHERE category_name = %s"
            cursor.execute(sql, (category_name,))
        connection.commit()
        return {"message": f"Budget '{category_name}' deleted successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if connection:
            connection.close()

def create_table_if_not_exists():
    connection = None
    try:
        connection = get_connection()
        with connection.cursor() as cursor:
            sql = """
            CREATE TABLE IF NOT EXISTS AppData (
                category_name VARCHAR(255) PRIMARY KEY,
                amount DECIMAL(10, 2),
                emoji VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci
            ) ENGINE=InnoDB;
            """
            cursor.execute(sql)
        connection.commit()
        print("Table 'AppData' checked/created successfully!")
    except Exception as e:
        print(f"An error occurred while creating table: {e}")
    finally:
        if connection:
            connection.close()
def create_transactions_table():
    connection = None
    try:
        connection = get_connection()
        with connection.cursor() as cursor:
            sql = """
            CREATE TABLE IF NOT EXISTS Transactions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                category_name VARCHAR(255),
                amount DECIMAL(10, 2),
                email VARCHAR(255),
                customer_name VARCHAR(255),
                affiliation_number VARCHAR(255),
                payment_type VARCHAR(50),
                transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB;
            """
            cursor.execute(sql)
        connection.commit()
        print("Table 'Transactions' checked/created successfully!")
    except Exception as e:
        print(f"An error occurred while creating Transactions table: {e}")
    finally:
        if connection:
            connection.close()
@app.post("/transactions/")
async def create_transaction(transaction: Transaction):
    try:
        connection = get_connection()
        with connection.cursor() as cursor:
            sql = """
            INSERT INTO Transactions 
            (category_name, amount, email, customer_name, affiliation_number, payment_type) 
            VALUES (%s, %s, %s, %s, %s, %s)
            """
            cursor.execute(sql, (
                transaction.category_name,
                transaction.amount,
                transaction.email,
                transaction.customer_name,
                transaction.affiliation_number,
                transaction.payment_type
            ))
        connection.commit()
        return {"message": "Transaction recorded successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if connection:
            connection.close()
def create_customer_table():
    connection = None
    try:
        connection = get_connection()
        with connection.cursor() as cursor:
            sql = """
            CREATE TABLE IF NOT EXISTS Customer (
                customer_name VARCHAR(255) PRIMARY KEY,
                email VARCHAR(255),
                category VARCHAR(255)
                
            ) ENGINE=InnoDB;
            """
            cursor.execute(sql)
        connection.commit()
        print("Table 'Customer' checked/created successfully!")
    except Exception as e:
        print(f"An error occurred while creating table: {e}")
    finally:
        if connection:
            connection.close()
@app.post("/customers/")
async def create_customer(customer: Customer):
    try:
        connection = get_connection()
        with connection.cursor() as cursor:
            sql = "REPLACE INTO Customer (customer_name, email, category) VALUES (%s, %s, %s)"
            cursor.execute(sql, (customer.customer_name, customer.email, customer.category))
        connection.commit()
        return {"message": f"Customer '{customer.customer_name}' added successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if connection:
            connection.close()


@app.on_event("startup")
def startup_event():
    create_table_if_not_exists()
    create_customer_table()
    create_transactions_table()
    chatbot.load_pdf("expense.txt", "my_pdf_index")

@app.websocket("/ws/chat")
async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()

    # Ask the user how much they received for the current month
    await websocket.send_json({
        "text": "Please enter the amount you received for the current month:",
        "finished": False
    })
    
    try:
        income = await websocket.receive_text()

        # Confirm receipt of income
        await websocket.send_json({
            "text": f"Thank you! You entered: {income}. How can I assist you with your budget?",
            "finished": False
        })

        while True:
            try:
                message = await websocket.receive_text()

                # Pass the user's income and query to the chatbot
                full_message = f"User's monthly income: {income}. User query: {message}"
                
                for chunk in chatbot.query(full_message):
                    await websocket.send_json({
                        "text": chunk,
                        "finished": False
                    })
                
                await websocket.send_json({
                    "text": "",
                    "finished": True
                })
            except Exception as e:
                print(f"Error: {e}")
                await websocket.close()
                break
    except Exception as e:
        print(f"Error: {e}")
        await websocket.close()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="localhost", port=8020)
