import os
import json
import logging
import boto3
import pymysql
import secrets
import string
import traceback

logger = logging.getLogger()
logger.setLevel(logging.INFO)

secrets_client = boto3.client("secretsmanager")


def generate_password(length=32):
    chars = string.ascii_letters + string.digits + "!@#$^&*()_+-="
    return "".join(secrets.choice(chars) for _ in range(length))


def lambda_handler(event, context):
    logger.info("Starting database setup Lambda function")

    try:
        # ───────────────────────────────────────────────
        # Load env vars
        # ───────────────────────────────────────────────
        master_secret_arn = os.environ["MASTER_SECRET_ARN"]
        wordpress_secret_name = os.environ["WORDPRESS_SECRET_NAME"]
        db_host = os.environ["DB_HOST"]
        db_port = int(os.environ["DB_PORT"])
        wp_db_name = os.environ["WORDPRESS_DB_NAME"]
        wp_db_user = os.environ["WORDPRESS_DB_USER"]

        logger.info("Loaded environment variables")

        # ───────────────────────────────────────────────
        # Fetch master creds
        # ───────────────────────────────────────────────
        master_secret = secrets_client.get_secret_value(
            SecretId=master_secret_arn
        )
        master_creds = json.loads(master_secret["SecretString"])
        master_username = master_creds["username"]
        master_password = master_creds["password"]

        logger.info("Master credentials retrieved")

        # ───────────────────────────────────────────────
        # Connect to MySQL
        # ───────────────────────────────────────────────
        conn = pymysql.connect(
            host=db_host,
            user=master_username,
            password=master_password,
            database=wp_db_name,
            port=db_port,
            connect_timeout=10,
            cursorclass=pymysql.cursors.DictCursor,
        )
        cursor = conn.cursor()

        # ───────────────────────────────────────────────
        # Check if user exists
        # ───────────────────────────────────────────────
        cursor.execute(
            "SELECT User FROM mysql.user WHERE User = %s",
            (wp_db_user,)
        )
        user_exists = cursor.fetchone()

        wp_db_password = generate_password()

        # ───────────────────────────────────────────────
        # Create or update user
        # ───────────────────────────────────────────────
        if user_exists:
            logger.info("User exists — rotating password")
            cursor.execute(
                "ALTER USER %s@%s IDENTIFIED BY %s",
                (wp_db_user, "%", wp_db_password)
            )
        else:
            logger.info("User does not exist — creating")
            cursor.execute(
                "CREATE USER %s@%s IDENTIFIED BY %s",
                (wp_db_user, "%", wp_db_password)
            )

        # ───────────────────────────────────────────────
        # Grant privileges
        # ───────────────────────────────────────────────
        cursor.execute(
            "GRANT ALL PRIVILEGES ON `{}`.* TO %s@%s".format(wp_db_name),
            (wp_db_user, "%")
        )
        cursor.execute("FLUSH PRIVILEGES")
        conn.commit()

        # ───────────────────────────────────────────────
        # Store credentials in secrets
        # ───────────────────────────────────────────────
        wp_secret_value = {
            "username": wp_db_user,
            "password": wp_db_password,
            "dbname": wp_db_name,
            "host": db_host,
            "port": db_port,
        }

        secrets_client.put_secret_value(
            SecretId=wordpress_secret_name,
            SecretString=json.dumps(wp_secret_value),
        )

        logger.info("Database setup completed successfully")
        return {"statusCode": 200, "body": "WordPress DB setup complete"}

    except Exception as e:
        logger.error(f"ERROR: {e}")
        logger.error(traceback.format_exc())
        return {"statusCode": 500, "body": str(e)}
