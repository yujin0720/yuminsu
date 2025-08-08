from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from db import get_db
from models.timer import Timer
from models import user as user_model
from pydantic import BaseModel
from datetime import date, timedelta, datetime
from utils.auth import get_current_user
from typing import Dict, List, Optional
from schemas.timer import TimerCreate, TimerRead

router = APIRouter()

# ✔️ 공부 시간 저장
@router.post("/")
def add_timer_session(
    data: TimerCreate,
    db: Session = Depends(get_db),
    current_user: user_model.User = Depends(get_current_user)
):
    print("수신된 타이머 데이터:", data.dict())

    # 세션 길이 계산
    if data.start_time and data.end_time:
        session_duration = int((data.end_time - data.start_time).total_seconds() / 60)
    else:
        session_duration = data.total_minutes

    timer = Timer(
        user_id=current_user.user_id,
        study_date=data.study_date,
        total_minutes=session_duration,
        start_time=data.start_time,
        end_time=data.end_time
    )
    db.add(timer)
    db.commit()

    return {"message": "세션 저장 완료", "session_minutes": session_duration}


# ✔️ 특정 날짜 공부 시간 조회
@router.get("/timer/{study_date}", response_model=TimerRead)
def get_timer(
    study_date: date,
    db: Session = Depends(get_db),
    current_user: user_model.User = Depends(get_current_user)
):
    timer = db.query(Timer).filter(
        Timer.user_id == current_user.user_id,
        Timer.study_date == study_date
    ).first()
    if not timer:
        raise HTTPException(status_code=404, detail="No timer found")
    return timer


# ✔️ 오늘 공부 시간 총합
@router.get("/today")
def get_today_time(
    current_user: user_model.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    today = date.today()
    timers = db.query(Timer).filter(
        Timer.user_id == current_user.user_id,
        Timer.study_date == today
    ).all()
    total_minutes = sum(t.total_minutes for t in timers)
    return {"today_minutes": total_minutes}


# ✔️ 주간 전체 합계
@router.get("/weekly")
def get_weekly_total_time(
    current_user: user_model.User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    today = date.today()
    start_week = today - timedelta(days=today.weekday())
    end_week = start_week + timedelta(days=6)

    timers = db.query(Timer).filter(
        Timer.user_id == current_user.user_id,
        Timer.study_date >= start_week,
        Timer.study_date <= end_week
    ).all()

    total_minutes = sum(t.total_minutes for t in timers)
    return {"weekly_minutes": total_minutes}


# ✔️ 주간 요일별 공부 시간
@router.get("/weekly-by-day")
def get_weekly_minutes_by_day(
    week_offset: int = 0,
    current_user: user_model.User = Depends(get_current_user),
    db: Session = Depends(get_db)
) -> Dict[str, int]:
    today = date.today()
    start_of_week = today - timedelta(days=today.weekday()) + timedelta(weeks=week_offset)
    end_of_week = start_of_week + timedelta(days=6)

    timers = db.query(Timer).filter(
        Timer.user_id == current_user.user_id,
        Timer.study_date >= start_of_week,
        Timer.study_date <= end_of_week
    ).all()

    study_by_day = {day: 0 for day in ['월', '화', '수', '목', '금', '토', '일']}
    for entry in timers:
        weekday_name = ['월', '화', '수', '목', '금', '토', '일'][entry.study_date.weekday()]
        study_by_day[weekday_name] += entry.total_minutes

    return study_by_day


# ✔️ 특정 날짜의 모든 공부 세션 조회
@router.get("/sessions/{study_date}", response_model=List[TimerRead])
def get_timer_sessions_by_date(
    study_date: date,
    db: Session = Depends(get_db),
    current_user: user_model.User = Depends(get_current_user)
):
    sessions = db.query(Timer).filter(
        Timer.user_id == current_user.user_id,
        Timer.study_date == study_date
    ).all()

    return sessions

# ✔️ 특정 공부 세션 삭제
@router.delete("/{timer_id}")
def delete_timer_session(
    timer_id: int,
    db: Session = Depends(get_db),
    current_user: user_model.User = Depends(get_current_user)
):
    session = db.query(Timer).filter(
        Timer.timer_id == timer_id,
        Timer.user_id == current_user.user_id
    ).first()

    if not session:
        raise HTTPException(status_code=404, detail="세션을 찾을 수 없습니다.")

    db.delete(session)
    db.commit()
    return {"message": "세션이 삭제되었습니다."}
