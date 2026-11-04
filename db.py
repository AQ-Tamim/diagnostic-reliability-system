import os
import mysql.connector
from dotenv import load_dotenv

# Load database configuration
load_dotenv()

DB_CONFIG = {
    "host": os.getenv("DB_HOST"),
    "port": int(os.getenv("DB_PORT", 3306)),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}


def get_connection():
    """Establish and return a MariaDB connection."""

    try:
        connection = mysql.connector.connect(**DB_CONFIG)

        if connection.is_connected():
            print("Successfully connected to MariaDB.")

        return connection

    except mysql.connector.Error as error:
        print(f"Database connection failed: {error}")
        raise