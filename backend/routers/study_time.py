from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from datetime import date, timedelta
from db import get_db
from models import Timer
from utils.auth import get_current_user
from sqlalchemy import text

router = APIRouter()

@router.get("/study-time/week")
def get_weekly_study_time(user=Depends(get_current_user), db: Session = Depends(get_db)):
    today = date.today()
    start = today - timedelta(days=today.weekday())  # 월요일
    end = start + timedelta(days=6)  # 일요일

    rows = db.execute(text("""
        SELECT DAYOFWEEK(study_date) AS weekday, SUM(total_minutes) AS total
        FROM timer
        WHERE user_id = :uid AND study_date BETWEEN :start AND :end
        GROUP BY weekday
    """), {"uid": user.user_id, "start": start, "end": end}).fetchall()

    weekday_map = {1: "일", 2: "월", 3: "화", 4: "수", 5: "목", 6: "금", 7: "토"}
    result = {day: 0 for day in weekday_map.values()}

    for row in rows:
        result[weekday_map[row[0]]] = row[1]

    return result
