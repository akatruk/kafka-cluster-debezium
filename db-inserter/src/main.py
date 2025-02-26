import os
import time
import random
import logging
import sys
import psycopg2
from datetime import datetime

# Print directly to stdout for immediate confirmation
print("DB Inserter starting up...")
sys.stdout.flush()

# Configure logging with forced flush
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    stream=sys.stdout
)
logger = logging.getLogger('db-inserter')

# Force flush handler
for handler in logger.handlers:
    handler.flush()

logger.info("DB Inserter service initializing")
print(f"STDOUT: DB Inserter service initializing at {datetime.now()}")
sys.stdout.flush()

# Database configuration
DB_HOST = os.environ.get('DB_HOST', 'localhost')
DB_NAME = os.environ.get('DB_NAME', 'postgresdb')
DB_USER = os.environ.get('DB_USER', 'postgres')
DB_PASSWORD = os.environ.get('DB_PASSWORD', 'postgres')

logger.info(f"Database configuration: host={DB_HOST}, database={DB_NAME}, user={DB_USER}")
print(f"STDOUT: Database configuration: host={DB_HOST}, database={DB_NAME}, user={DB_USER}")
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
            logger.info("Table 'sensor_data' checked/created successfully")
            print("STDOUT: Table 'sensor_data' checked/created successfully")
            sys.stdout.flush()
    except Exception as e:
        logger.error(f"Error creating table: {e}")
        print(f"STDOUT ERROR: Error creating table: {e}")
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
            logger.info(f"Inserted data: timestamp={timestamp}, temperature={temperature}, humidity={humidity}")
            print(f"STDOUT: Inserted data: timestamp={timestamp}, temp={temperature}, humidity={humidity}")
            sys.stdout.flush()
    except Exception as e:
        logger.error(f"Error inserting data: {e}")
        print(f"STDOUT ERROR: Error inserting data: {e}")
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
            logger.info(f"Attempting to connect to database (attempt {retry_count + 1}/{max_retries})")
            print(f"STDOUT: Attempting to connect to database (attempt {retry_count + 1}/{max_retries})")
            sys.stdout.flush()
            
            connection = psycopg2.connect(
                host=DB_HOST,
                database=DB_NAME,
                user=DB_USER,
                password=DB_PASSWORD
            )
            logger.info("Successfully connected to the database")
            print("STDOUT: Successfully connected to the database")
            sys.stdout.flush()
            break
        except psycopg2.OperationalError as e:
            retry_count += 1
            logger.error(f"Failed to connect to the database: {e}")
            print(f"STDOUT ERROR: Failed to connect to the database: {e}")
            sys.stdout.flush()
            if retry_count < max_retries:
                wait_time = 5
                logger.info(f"Retrying in {wait_time} seconds...")
                print(f"STDOUT: Retrying in {wait_time} seconds...")
                sys.stdout.flush()
                time.sleep(wait_time)
            else:
                logger.critical("Maximum retry attempts reached. Exiting.")
                print("STDOUT CRITICAL: Maximum retry attempts reached. Exiting.")
                sys.stdout.flush()
                return
    
    try:
        # Create table if it doesn't exist
        create_table_if_not_exists(connection)
        
        # Main loop to insert data every 5 seconds
        logger.info("Starting data insertion loop")
        print("STDOUT: Starting data insertion loop")
        sys.stdout.flush()
        while True:
            insert_data(connection)
            time.sleep(5)
    except KeyboardInterrupt:
        logger.info("Shutting down...")
        print("STDOUT: Shutting down...")
        sys.stdout.flush()
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        print(f"STDOUT ERROR: Unexpected error: {e}")
        sys.stdout.flush()
    finally:
        if connection:
            connection.close()
            logger.info("Database connection closed")
            print("STDOUT: Database connection closed")
            sys.stdout.flush()

if __name__ == "__main__":
    logger.info("DB Inserter service starting")
    print("STDOUT: DB Inserter service starting from __main__")
    sys.stdout.flush()
    main() 