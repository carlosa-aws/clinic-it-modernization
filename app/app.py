from flask import Flask, render_template, request, redirect, url_for
import os
import psycopg2

app = Flask(__name__)


def get_db_connection():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        database=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
        port=os.environ.get("DB_PORT", "5432")
    )


def init_db():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS patient_intake (
            id SERIAL PRIMARY KEY,
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
    cursor.close()
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

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        INSERT INTO patient_intake (
            first_name, last_name, dob, phone, email, symptoms, preferred_date
        ) VALUES (%s, %s, %s, %s, %s, %s, %s)
    """, (first_name, last_name, dob, phone, email, symptoms, preferred_date))
    conn.commit()
    cursor.close()
    conn.close()

    return redirect(url_for("admin"))


@app.route("/admin")
def admin():
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute("""
        SELECT id, first_name, last_name, dob, phone, email, symptoms, preferred_date, created_at
        FROM patient_intake
        ORDER BY created_at DESC
    """)
    submissions = cursor.fetchall()
    cursor.close()
    conn.close()

    return render_template("admin.html", submissions=submissions)


if __name__ == "__main__":
    init_db()
