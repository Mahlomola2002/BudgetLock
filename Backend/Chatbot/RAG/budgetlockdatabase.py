# Copyright 2023 PingCAP, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import pymysql
from pymysql import Connection
from pymysql.cursors import DictCursor

from config import Config

def get_connection(autocommit: bool = True) -> Connection:
    config = Config()
    db_conf = {
        "host": "gateway01.eu-central-1.prod.aws.tidbcloud.com",
        "port": 4000,
        "user":"3E5xd5jEufqhDm6.root",
        "password": "NlbqFGGu2ykahnLo",
        "database": "BudgetLockDatabase",
        "autocommit": autocommit,
        "cursorclass": DictCursor,
    }

    if "C:\\Users\\masha\\OneDrive - University of Cape Town\\budget lock\\BudgetLockDatabase":
        db_conf["ssl_verify_cert"] = True
        db_conf["ssl_verify_identity"] = True
        db_conf["ssl_ca"] = config.ca_path

    return pymysql.connect(**db_conf)                         
        
def drop_table(table_name):
    try:
        # Establish a connection to the TiDB cluster
        connection = get_connection()

        with connection.cursor() as cursor:
            # Prepare the SQL DROP TABLE statement
            sql = f"DROP TABLE {table_name};"
            
            # Execute the SQL statement
            cursor.execute(sql)
            
        # Commit the transaction
        connection.commit()
        print(f"Table {table_name} dropped successfully!")

    except Exception as e:
        # If there's an error, rollback the transaction
        connection.rollback()
        print(f"An error occurred: {e}")

    finally:
        # Close the connection
        connection.close()    
        
def create_table():
    try:
        connection = get_connection()

        with connection.cursor() as cursor:
            # Prepare the SQL CREATE TABLE statement with utf8mb4 encoding
            sql = """
            CREATE TABLE IF NOT EXISTS AppData (
                category_name VARCHAR(255) PRIMARY KEY,
                amount DECIMAL(10, 2),
                emoji VARCHAR(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,
                deadline DATE,
                reminder DATETIME
            ) ENGINE=InnoDB;
            """
            
            # Execute the SQL statement
            cursor.execute(sql)
            
        # Commit the transaction
        connection.commit()
        print("Table 'AppData' created successfully!")

    except Exception as e:
        connection.rollback()
        print(f"An error occurred: {e}")

    finally:
        connection.close()        
        
        
            
def insert_task(category_name, amount, emoji, deadline, reminder):
    try:
        connection = get_connection()

        with connection.cursor() as cursor:
            sql = """
            INSERT INTO AppData (category_name, amount, emoji, deadline, reminder)
            VALUES (%s, %s, %s, %s, %s)
            """
            cursor.execute(sql, (category_name, amount, emoji, deadline, reminder))
            
        connection.commit()
        print(f"Task '{category_name}' inserted successfully!")

    except Exception as e:
        connection.rollback()
        print(f"An error occurred: {e}")

    finally:
        connection.close()


def display_all():
    try:
        connection = get_connection()

        with connection.cursor() as cursor:
            sql = "SELECT * FROM AppData ORDER BY category_name ASC"
            cursor.execute(sql)

            results = cursor.fetchall()

            i = 1
            print("category_name\tamount\temoji\tdeadline\treminder")
            for row in results:
                print(f"{row["category_name"]}\t\t{row["amount"]}\t{row["emoji"]}\t{row["deadline"]}\t{row["reminder"]}")
                i += 1
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        connection.close()
        
        
def delete_record_by_category(category_name: str) -> None:
    try:
        # Establish a connection to the database
        connection = get_connection()

        with connection.cursor() as cursor:
            # Prepare the SQL DELETE statement
            sql = "DELETE FROM AppData WHERE category_name = %s"
            
            # Execute the SQL statement with the given category name
            cursor.execute(sql, (category_name,))
            
        # Commit the transaction
        connection.commit()
        print(f"Record with category name '{category_name}' deleted successfully!")

    except Exception as e:
        # If there's an error, rollback the transaction
        connection.rollback()
        print(f"An error occurred: {e}")

    finally:
        # Close the connection
        connection.close()
                

if __name__ == "__main__":
    #drop_table("Data")
    #create_table()
    #insert_task("Rent", 2000.00, "🏡", "2024-08-31", "2024-08-30 09:00:00")
    #delete_record_by_category("Transport")
    display_all()