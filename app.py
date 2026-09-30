from datetime import datetime
import os
import platform
import socket
import threading

import mysql.connector
from mysql.connector import Error

from flask import Flask, jsonify, render_template


app = Flask(__name__)


APP_NAME = os.getenv(
    "APP_NAME",
    "Karan DevOps Dashboard",
)

APP_VERSION = os.getenv(
    "APP_VERSION",
    "2.0.0",
)

ENVIRONMENT = os.getenv(
    "ENVIRONMENT",
    "Development",
)


DB_HOST = os.getenv(
    "DB_HOST",
    "localhost",
)

DB_PORT = int(
    os.getenv(
        "DB_PORT",
        "3306",
    )
)

DB_NAME = os.getenv(
    "DB_NAME",
    "karan_dashboard",
)

DB_USER = os.getenv(
    "DB_USER",
    "karan",
)

DB_PASSWORD = os.getenv(
    "DB_PASSWORD",
    "karanpassword",
)


_db_initialized = False

_db_init_lock = threading.Lock()


def get_system_info():

    return {
        "hostname": socket.gethostname(),
        "platform": platform.system(),
        "python_version": platform.python_version(),
        "environment": ENVIRONMENT,
    }


def get_db_connection():

    return mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASSWORD,
        connection_timeout=5,
    )


def initialize_database():

    global _db_initialized

    if _db_initialized:
        return

    with _db_init_lock:

        if _db_initialized:
            return

        connection = get_db_connection()

        cursor = connection.cursor()

        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS skills (
                id INT AUTO_INCREMENT PRIMARY KEY,
                name VARCHAR(100) NOT NULL UNIQUE,
                level INT NOT NULL
            )
            """
        )

        cursor.execute(
            """
            CREATE TABLE IF NOT EXISTS pipeline_stages (
                id INT AUTO_INCREMENT PRIMARY KEY,
                stage_order INT NOT NULL UNIQUE,
                stage VARCHAR(100) NOT NULL,
                status VARCHAR(50) NOT NULL,
                description VARCHAR(255) NOT NULL
            )
            """
        )

        skills = [
            ("Linux", 82),
            ("Git & GitHub", 78),
            ("Docker", 80),
            ("Jenkins", 70),
            ("Kubernetes", 68),
            ("Bash Scripting", 74),
            ("Python", 72),
            ("MySQL", 65),
        ]

        cursor.executemany(
            """
            INSERT IGNORE INTO skills
            (
                name,
                level
            )
            VALUES
            (
                %s,
                %s
            )
            """,
            skills,
        )

        pipeline = [
            (
                1,
                "Checkout",
                "success",
                "Source code downloaded from GitHub",
            ),
            (
                2,
                "Syntax Check",
                "success",
                "Python syntax validated",
            ),
            (
                3,
                "Unit Tests",
                "success",
                "Application unit tests executed",
            ),
            (
                4,
                "Docker Build",
                "success",
                "Docker image built successfully",
            ),
            (
                5,
                "Docker Push",
                "success",
                "Docker image pushed to Docker Hub",
            ),
            (
                6,
                "Kubernetes Deploy",
                "success",
                "Application deployed to Kubernetes",
            ),
            (
                7,
                "Health Check",
                "success",
                "Application health endpoint verified",
            ),
        ]

        cursor.executemany(
            """
            INSERT IGNORE INTO pipeline_stages
            (
                stage_order,
                stage,
                status,
                description
            )
            VALUES
            (
                %s,
                %s,
                %s,
                %s
            )
            """,
            pipeline,
        )

        connection.commit()

        cursor.close()

        connection.close()

        _db_initialized = True


def check_database():

    connection = get_db_connection()

    cursor = connection.cursor()

    cursor.execute(
        "SELECT 1"
    )

    cursor.fetchone()

    cursor.close()

    connection.close()

    return True


@app.route("/")
def home():

    return render_template(
        "index.html",
        app_name=APP_NAME,
        version=APP_VERSION,
        environment=ENVIRONMENT,
        year=datetime.now().year,
    )


@app.route("/api/status")
def api_status():

    try:

        database_status = (
            "connected"
            if check_database()
            else "disconnected"
        )

    except Error:

        database_status = "disconnected"

    return jsonify(
        {
            "app": APP_NAME,
            "status": "running",
            "health": (
                "healthy"
                if database_status == "connected"
                else "degraded"
            ),
            "database": database_status,
            "version": APP_VERSION,
            "environment": ENVIRONMENT,
            "timestamp": datetime.now().isoformat(),
            "system": get_system_info(),
        }
    )


@app.route("/api/skills")
def api_skills():

    try:

        initialize_database()

        connection = get_db_connection()

        cursor = connection.cursor(
            dictionary=True
        )

        cursor.execute(
            """
            SELECT
                name,
                level
            FROM skills
            ORDER BY id
            """
        )

        skills = cursor.fetchall()

        cursor.close()

        connection.close()

        return jsonify(
            {
                "skills": skills
            }
        )

    except Error:

        return (
            jsonify(
                {
                    "error": "Database is not available"
                }
            ),
            503,
        )


@app.route("/api/pipeline")
def api_pipeline():

    try:

        initialize_database()

        connection = get_db_connection()

        cursor = connection.cursor(
            dictionary=True
        )

        cursor.execute(
            """
            SELECT
                stage,
                status,
                description
            FROM pipeline_stages
            ORDER BY stage_order
            """
        )

        pipeline = cursor.fetchall()

        cursor.close()

        connection.close()

        return jsonify(
            {
                "pipeline": pipeline
            }
        )

    except Error:

        return (
            jsonify(
                {
                    "error": "Database is not available"
                }
            ),
            503,
        )


@app.route("/health")
def health():

    try:

        initialize_database()

        check_database()

        return (
            jsonify(
                {
                    "status": "healthy",
                    "database": "connected",
                    "service":
                        "karan-devops-dashboard",
                    "version": APP_VERSION,
                }
            ),
            200,
        )

    except Error:

        return (
            jsonify(
                {
                    "status": "unhealthy",
                    "database": "disconnected",
                    "service":
                        "karan-devops-dashboard",
                    "version": APP_VERSION,
                }
            ),
            503,
        )


if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=5000,
    )
