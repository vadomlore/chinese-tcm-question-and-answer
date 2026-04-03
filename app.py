from __future__ import annotations

from datetime import date
from pathlib import Path

from flask import Flask, render_template, request

from src.tcm_cards.daily_cards import load_review_session

app = Flask(__name__)
DATA_DIR = Path(__file__).parent / "data" / "daily"


@app.get("/")
def index():
    requested_date = request.args.get("date")
    session = load_review_session(DATA_DIR, requested_date or date.today().isoformat())
    return render_template("index.html", session=session, requested_date=requested_date)


if __name__ == "__main__":
    app.run(debug=True)
