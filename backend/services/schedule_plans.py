import os
from datetime import datetime, timedelta, date
from collections import defaultdict
from dotenv import load_dotenv
from db import SessionLocal
from models.user import User
from models.subject import Subject
from models.plan import Plan

load_dotenv()

# 날짜 → 요일 맵 생성
def get_date_weekday_map(start_date: str, end_date: str) -> dict:
    date_map = {}
    start = datetime.strptime(start_date, "%Y-%m-%d")
    end = datetime.strptime(end_date, "%Y-%m-%d")
    current = start
    while current <= end:
        weekday = current.strftime("%a").lower()[:3]
        date_map[current.strftime("%Y-%m-%d")] = weekday
        current += timedelta(days=1)
    return date_map

# 순수 파이썬 기반 스케줄링 로직 (GPT 호출 없음)
def get_plan_schedule_from_gpt(data: dict) -> list:
    user_info = data["users"][0]
    study_time = user_info["study_time"]
    date_weekday_map = data["date_weekday_map"]
    study_calendar = data["study_calendar"]
    used_time_by_date = defaultdict(int)

    subject_date_ranges = defaultdict(list)
    for subj in data["subjects"]:
        sid = subj["subject_id"]
        start = subj["start_date"]
        end = subj["end_date"]
        for date_str, weekday in date_weekday_map.items():
            if start <= date_str <= end:
                subject_date_ranges[sid].append(date_str)

    for sid in subject_date_ranges:
        subject_date_ranges[sid].sort()

    result = []
    plans = sorted(data["plans"], key=lambda p: p["plan_id"])

    for plan in plans:
        plan_id = plan["plan_id"]
        subject_id = plan["subject_id"]
        plan_time = plan["plan_time"]

        candidate_dates = subject_date_ranges.get(subject_id, [])
        assigned = False

        for d in candidate_dates:
            if used_time_by_date[d] + plan_time <= study_calendar[d]:
                result.append({"plan_id": plan_id, "plan_date": d})
                used_time_by_date[d] += plan_time
                assigned = True
                break

        if not assigned:
            print(f"⛔ 공부 시간이 부족하여 plan_id={plan_id} 를 배정할 수 없습니다.")
            return [{"error": "공부 시간이 부족하여 모든 계획을 배정할 수 없습니다."}]

    return result

# 사용자, 과목, 계획 가져오기
def fetch_user_data(db, user_id):
    user = db.query(User).filter(User.user_id == user_id).first()
    if not user:
        return None, [], []

    subjects = db.query(Subject).filter(Subject.user_id == user_id).all()

    completed_names_query = db.query(Plan.plan_name).filter(
        Plan.complete == True, Plan.user_id == user_id
    ).distinct()
    completed_names = {name for (name,) in completed_names_query}

    all_plans = db.query(Plan).filter(
        Plan.complete == False, Plan.user_id == user_id
    ).all()
    filtered_plans = [p for p in all_plans if p.plan_name not in completed_names]

    return user, subjects, filtered_plans

# 지난 날짜 계획 초기화
def reset_old_plan_dates(db, user_id):
    today = date.today()
    db.query(Plan).filter(
        Plan.complete == False,
        Plan.plan_date < today,
        Plan.user_id == user_id
    ).update({"plan_date": None})
    db.commit()

# GPT 입력용 데이터 구성
def build_prompt_data(user, subjects, plans):
    days = ["mon", "tue", "wed", "thu", "fri", "sat", "sun"]

    user_data = {
        "user_id": user.user_id,
        "study_time": {d: getattr(user, f"study_time_{d}") for d in days}
    }

    subject_list = []
    plan_list = [
        {
            "plan_id": p.plan_id,
            "user_id": p.user_id,
            "subject_id": p.subject_id,
            "plan_time": p.plan_time,
            "plan_name": p.plan_name
        } for p in plans
    ]

    all_dates = set()
    for s in subjects:
        subject_list.append({
            "subject_id": s.subject_id,
            "user_id": s.user_id,
            "start_date": s.start_date.strftime("%Y-%m-%d"),
            "end_date": s.end_date.strftime("%Y-%m-%d")
        })
        date_map = get_date_weekday_map(
            s.start_date.strftime("%Y-%m-%d"),
            s.end_date.strftime("%Y-%m-%d")
        )
        all_dates.update(date_map.items())

    date_weekday_map = {d: wd for d, wd in all_dates}
    study_calendar = {d: getattr(user, f"study_time_{wd}") for d, wd in all_dates}

    return {
        "users": [user_data],
        "subjects": subject_list,
        "plans": plan_list,
        "date_weekday_map": date_weekday_map,
        "study_calendar": study_calendar
    }

# GPT 결과 반영
def apply_plan_dates(db, plan_dates):
    updated = 0
    for plan in plan_dates:
        plan_id = plan.get("plan_id")
        plan_date = plan.get("plan_date")
        if plan_id and plan_date:
            db_plan = db.query(Plan).filter(Plan.plan_id == plan_id).first()
            if db_plan and db_plan.plan_date != plan_date:
                db_plan.plan_date = plan_date
                updated += 1
    db.commit()
    return updated

# FastAPI에서 호출할 수 있도록 하는 진입점 함수
def run_schedule_for_user(user_id: int, db):
    try:
        user, subjects, plans = fetch_user_data(db, user_id)

        if not user:
            return {"error": "해당 유저가 존재하지 않습니다."}
        elif not plans:
            return {"message": "배정할 계획이 없습니다."}

        reset_old_plan_dates(db, user_id)
        prompt_data = build_prompt_data(user, subjects, plans)
        plan_dates = get_plan_schedule_from_gpt(prompt_data)

        if plan_dates:
            if "error" in plan_dates[0]:
                return {"warning": plan_dates[0]["error"]}
            updated_count = apply_plan_dates(db, plan_dates)
            return {"message": f"\u2705 계획 {updated_count}건 날짜 배정 완료!"}
        else:
            return {"warning": "계획 날짜 배정 결과가 비어 있습니다."}

    except Exception as e:
        return {"error": str(e)}