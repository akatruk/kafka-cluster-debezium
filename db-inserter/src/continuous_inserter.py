import os
import time
import random
import sys
import psycopg2
from datetime import datetime

# Print immediately to stdout
print("Continuous DB Inserter Starting...")
sys.stdout.flush()

# Database configuration
DB_HOST = os.environ.get('DB_HOST', 'postgres')
DB_NAME = os.environ.get('DB_NAME', 'postgresdb')
DB_USER = os.environ.get('DB_USER', 'postgres')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'postgres')

print(f"Database configuration: host={DB_HOST}, database={DB_NAME}, user={DB_USER}")
sys.stdout.flush()

def create_table_if_not_exists(conn):
    """Create the data table if it doesn't exist."""
    try:
        with conn.cursor() as cursor:
            cursor.execute('''
                CREATE TABLE IF NOT EXISTS sensor_data (
                    id SERIAL PRIMARY KEY,
                    timestamp TIMESTAMP NOT NULL,
                    temperature FLOAT NOT NULL,
                    humidity FLOAT NOT NULL
                )
            ''')
            conn.commit()
            print("Table 'sensor_data' checked/created successfully")
            sys.stdout.flush()
    except Exception as e:
        print(f"Error creating table: {e}")
        sys.stdout.flush()
        raise

def insert_data(conn):
    """Insert random sensor data into the database."""
    timestamp = datetime.now()
    temperature = round(random.uniform(15.0, 35.0), 2)
    humidity = round(random.uniform(30.0, 90.0), 2)
    
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                "INSERT INTO sensor_data (timestamp, temperature, humidity) VALUES (%s, %s, %s)",
                (timestamp, temperature, humidity)
            )
            conn.commit()
            print(f"Inserted data: timestamp={timestamp}, temperature={temperature}, humidity={humidity}")
            sys.stdout.flush()
    except Exception as e:
        print(f"Error inserting data: {e}")
        sys.stdout.flush()
        conn.rollback()

def main():
    """Main function to connect to the database and insert data periodically."""
    print("Main function started")
    sys.stdout.flush()
    
    connection = None
    retry_count = 0
    max_retries = 5
    
    # Try to connect to the database with retries
    while retry_count < max_retries:
        try:
            print(f"Attempting to connect to database (attempt {retry_count + 1}/{max_retries})")
            sys.stdout.flush()
            
            connection = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD
            )
            print("Successfully connected to the database")
            sys.stdout.flush()
            break
        except Exception as e:
            retry_count += 1
            print(f"Failed to connect to the database: {e}")
            sys.stdout.flush()
            if retry_count < max_retries:
                wait_time = 5
                print(f"Retrying in {wait_time} seconds...")
                sys.stdout.flush()
                time.sleep(wait_time)
            else:
                print("Maximum retry attempts reached. Exiting.")
                sys.stdout.flush()
                return
    
    try:
        # Create table if it doesn't exist
        create_table_if_not_exists(connection)
        
        # Query the data
        with connection.cursor() as cursor:
            cursor.execute("SELECT COUNT(*) FROM sensor_data")
            count = cursor.fetchone()[0]
            print(f"Total records in sensor_data: {count}")
            sys.stdout.flush()
        
        # Main loop to insert data every 5 seconds
        print("Starting data insertion loop")
        sys.stdout.flush()
        while True:
            insert_data(connection)
            time.sleep(5)
    except KeyboardInterrupt:
        print("Shutting down...")
        sys.stdout.flush()
    except Exception as e:
        print(f"Unexpected error: {e}")
        sys.stdout.flush()
    finally:
        if connection:
            connection.close()
            print("Database connection closed")
            sys.stdout.flush()

if __name__ == "__main__":
    main() 