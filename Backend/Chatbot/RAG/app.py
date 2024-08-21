from http.client import HTTPException
import os
from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from updated import RAGChatbot
from pydantic import BaseModel
from datetime import date, datetime
from typing import List
import pymysql
from pymysql.cursors import DictCursor

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
    db_conf = {
        "host": "gateway01.eu-central-1.prod.aws.tidbcloud.com",
        "port": 4000,
        "user": "3E5xd5jEufqhDm6.root",
        "password": "NlbqFGGu2ykahnLo",
        "database": "BudgetLockDatabase",
        "autocommit": autocommit,
        "cursorclass": DictCursor,
    }
    return pymysql.connect(**db_conf)
class Budget(BaseModel):
    category_name: str
    amount: float
    emoji: str
    deadline: date
    reminder: datetime
def create_table_if_not_exists():
    try:
        connection = get_connection()
        with connection.cursor() as cursor:
            sql = """
            CREATE TABLE IF NOT EXISTS AppData (
                category_name VARCHAR(255) PRIMARY KEY,
                amount DECIMAL(10, 2),
                emoji VARCHAR(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
                deadline DATE,
                reminder DATETIME
            ) ENGINE=InnoDB;
            """
            cursor.execute(sql)
        connection.commit()
        print("Table 'AppData' checked/created successfully!")
    except Exception as e:
        print(f"An error occurred while creating table: {e}")
    finally:
        connection.close()
@app.post("/budgets/")
async def create_budget(budget: Budget):
    try:
        connection = get_connection()
        with connection.cursor() as cursor:
            sql = """
            INSERT INTO AppData (category_name, amount, emoji, deadline, reminder)
            VALUES (%s, %s, %s, %s, %s)
            """
            cursor.execute(sql, (budget.category_name, budget.amount, budget.emoji, budget.deadline, budget.reminder))
        connection.commit()
        return {"message": "Budget created successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        connection.close()

@app.get("/budgets/", response_model=List[Budget])
async def get_budgets():
    try:
        connection = get_connection()
        with connection.cursor() as cursor:
            sql = "SELECT * FROM AppData ORDER BY category_name ASC"
            cursor.execute(sql)
            results = cursor.fetchall()
        return [Budget(**result) for result in results]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        connection.close()

@app.delete("/budgets/{category_name}")
async def delete_budget(category_name: str):
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
        connection.close()

@app.on_event("startup")
def startup_event():
    chatbot.load_pdf("expense.txt", "my_pdf_index")
    create_table_if_not_exists()

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
    uvicorn.run(app, host="localhost", port=8000)
