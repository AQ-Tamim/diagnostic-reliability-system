from db import get_connection


connection = get_connection()

if connection:
    cursor = connection.cursor()

    cursor.execute("""
        SELECT
            DATABASE(),
            VERSION(),
            CURRENT_USER()
    """)

    result = cursor.fetchone()

    print("\nDatabase connection details:")
    print("Database:", result[0])
    print("MariaDB Version:", result[1])
    print("Connected User:", result[2])

    cursor.close()
    connection.close()

    print("\nConnection closed successfully.")