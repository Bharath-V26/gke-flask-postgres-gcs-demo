from flask import Flask, request, jsonify
import psycopg2
import os
from google.cloud import storage

app = Flask(__name__)

# -------------------------
# Postgres connection
# -------------------------
def get_db_connection():
    conn = psycopg2.connect(
        host=os.getenv("DB_HOST"),
        database=os.getenv("DB_NAME"),
        user=os.getenv("DB_USER"),
        password=os.getenv("DB_PASSWORD"),
    )
    return conn

# -------------------------
# Initialize DB (for demo)
# -------------------------
def init_db():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id SERIAL PRIMARY KEY,
            name VARCHAR(100)
        );
    """)
    conn.commit()
    cur.close()
    conn.close()

init_db()

# -------------------------
# Health check endpoint
# -------------------------
@app.route("/up-returns")
def up_returns():
    return "OK", 200

@app.route("/")
def home():
    return "Flask app on GKE with Postgres + GCS!"

# -------------------------
# User endpoints
# -------------------------
@app.route("/add", methods=["POST"])
def add():
    data = request.json
    name = data.get("name")

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("INSERT INTO users (name) VALUES (%s)", (name,))
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({"message": f"User {name} added!"})

@app.route("/list")
def list_users():
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute("SELECT id, name FROM users;")
    rows = cur.fetchall()
    cur.close()
    conn.close()

    return jsonify(rows)

# -------------------------
# File upload endpoint
# -------------------------
@app.route("/upload", methods=["POST"])
def upload():
    if "file" not in request.files:
        return jsonify({"error": "No file provided"}), 400

    file = request.files["file"]
    bucket_name = os.getenv("GCS_BUCKET")
    
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(file.filename)
    blob.upload_from_file(file)

    return jsonify({"message": f"File {file.filename} uploaded to {bucket_name}!"})

# -------------------------
# File download endpoint
# -------------------------
@app.route("/file/<filename>", methods=["GET"])
def get_file(filename):
    bucket_name = os.getenv("GCS_BUCKET")
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    blob = bucket.blob(filename)

    if not blob.exists():
        return jsonify({"error": "File not found"}), 404

    url = blob.generate_signed_url(expiration=3600)  # 1 hour valid
    return jsonify({"url": url})

# -------------------------
# Run Flask app
# -------------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)

