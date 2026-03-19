from flask import Flask, render_template, request, redirect, url_for
import sqlite3
from pathlib import Path

app = Flask(__name__)

DB_FILE = Path("clinic.db")


def init_db():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS patient_intake (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            dob TEXT NOT NULL,
            phone TEXT NOT NULL,
            email TEXT NOT NULL,
            symptoms TEXT NOT NULL,
            preferred_date TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    conn.commit()
    conn.close()


@app.route("/")
def intake():
    return render_template("intake.html")


@app.route("/submit", methods=["POST"])
def submit():
    first_name = request.form["first_name"]
    last_name = request.form["last_name"]
    dob = request.form["dob"]
    phone = request.form["phone"]
    email = request.form["email"]
    symptoms = request.form["symptoms"]
    preferred_date = request.form["preferred_date"]

    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO patient_intake (
            first_name, last_name, dob, phone, email, symptoms, preferred_date
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
    """, (first_name, last_name, dob, phone, email, symptoms, preferred_date))
    conn.commit()
    conn.close()

    return redirect(url_for("admin"))


@app.route("/admin")
def admin():
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.cursor()
    cursor.execute("""
        SELECT id, first_name, last_name, dob, phone, email, symptoms, preferred_date, created_at
        FROM patient_intake
        ORDER BY created_at DESC
    """)
    submissions = cursor.fetchall()
    conn.close()

    return render_template("admin.html", submissions=submissions)


if __name__ == "__main__":
    init_db()
    app.run(host="0.0.0.0", port=5001, debug=True)