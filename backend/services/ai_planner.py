import json
import ast
import pymysql
import traceback
from config import ask_gpt
from schemas.plan_schema import ToDoItem

# GPT 응답을 안전하게 파싱
def safe_parse_gpt_response(response: str) -> list:
    content = response.strip()
    print("📤 GPT 응답 원문 >>>", repr(content))

    if content.startswith("- "):
        result = [line[2:].strip() for line in content.split("\n") if line.startswith("- ")]
        print("📤 목록형 파싱 결과:", result)
        return result

    if not content.startswith("[") or not content.endswith("]"):
        print("📛 GPT 응답이 리스트 형식이 아님 → 무시됨")
        return []

    try:
        result = ast.literal_eval(content)
        print("📤 리터럴 파싱 결과:", result)
        return result
    except Exception as e:
        print(f"⚠️ 리스트 파싱 실패: {e}")
        return []

# 유니코드 정리 (이모지 깨짐 방지)
def clean_unicode(text: str) -> str:
    return text.encode("utf-8", "replace").decode("utf-8")

# GPT로 학습 항목 분해
def expand_row_plan_name(row_plan_name: str) -> list:
    system_prompt = (
        "너는 학습 항목을 콘텐츠 단위로 나누는 도우미야.\n\n"
        "💡 반드시 다음 규칙을 따라:\n"
        "1. 출력은 반드시 **파이썬 리스트** 형식으로. 예: ['1주차 시청', '2주차 시청']\n"
        "2. 출력 외에는 아무 말도 하지 마. (설명, 마크다운, 말머리 등 절대 쓰지 마)\n"
        "3. 입력에 **숫자 범위**가 포함된 경우, **범위 숫자만 확장**해서 뒤의 단어를 붙여줘.\n"
        "   예: '3-9주차 시청' → ['3주차 시청', '4주차 시청', ..., '9주차 시청']\n"
        "   예: '1~9주차 시청' → ['1주차 시청', ..., '9주차 시청']\n"
        "4. 기존 문장을 앞에 붙이지 마. 항상 **숫자부터 시작하는 콘텐츠 단위**만 포함해.\n"
        "5. 복습, 정리, 요약 등은 포함하지 마. 실제 콘텐츠만 포함시켜.\n\n"
        "🚫 금지 예시: ['3-9주차 시청 3주차'] 또는 ['3-9주차 시청 - 1회차 3주차']\n"
        "✅ 정답 예시: ['3주차 시청', '4주차 시청', ..., '9주차 시청']"
    )

    user_prompt = f"\n\n입력 문장: {row_plan_name}\n리스트로 나눠줘."

    try:
        full_prompt = clean_unicode(system_prompt + user_prompt)
        response = ask_gpt(prompt=full_prompt, model="gpt-3.5-turbo", temperature=0.2)
        return safe_parse_gpt_response(response)
    except Exception as e:
        print(f"GPT 호출 실패: {e}")
        return []

# row_plan 테이블 저장
def save_row_plans_to_db(user_data: dict):
    db = pymysql.connect(
        host='localhost',
        user='root',
        password='0904',
        database='yuminsu',
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )
    try:
        with db.cursor() as cursor:
            for plan in user_data["row_plans"]:
                cursor.execute("""
                    INSERT INTO row_plan (user_id, subject_id, row_plan_name, type, repetition, ranking, plan_time)
                    VALUES (%s, %s, %s, %s, %s, %s, %s)
                """, (
                    user_data["user_id"],
                    user_data["subject_id"],
                    plan["row_plan_name"],
                    plan["type"],
                    plan["repetition"],
                    plan["ranking"],
                    plan.get("plan_time", 60)
                ))
        db.commit()
        print("row_plan 테이블 저장 완료!")
    except Exception as e:
        print("row_plan 저장 오류:", e)
    finally:
        db.close()

# 계획(plan) 생성 및 저장
def generate_and_save_plans(user_id: int, subject_id: int):
    print(f"✅ AI 계획 생성 시작: user_id={user_id}, subject_id={subject_id}")
    db = pymysql.connect(
        host='localhost',
        user='root',
        password='0904',
        database='yuminsu',
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )

    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT * FROM row_plan
                WHERE user_id = %s AND subject_id = %s
                ORDER BY ranking ASC
            """, (user_id, subject_id))
            row_plans = cursor.fetchall()
            print(f"📦 row_plan 개수: {len(row_plans)}")

        if not row_plans:
            raise Exception("❌ row_plan이 존재하지 않음")

        todo_items = []
        for plan in row_plans:
            plan_name = plan.get("row_plan_name")
            tasks = expand_row_plan_name(plan_name)
            print(f"🔍 '{plan_name}' → 분해 결과: {tasks}")
            if not tasks:
                raise Exception(f"[GPT 파싱 실패] row_plan_name: {plan_name} → tasks 비었음")

            repetition = plan.get("repetition", 1)
            plan_time = plan.get("plan_time", 60)

            for r in range(1, repetition + 1):
                for t in tasks:
                    todo_items.append({
                        "user_id": user_id,
                        "subject_id": subject_id,
                        "plan_name": f"{r}회차 {t}",
                        "complete": False,
                        "plan_time": plan_time,
                        "plan_date": None
                    })

        print(f"📝 생성된 plan 개수: {len(todo_items)}")

        with db.cursor() as cursor:
            for item in todo_items:
                cursor.execute("""
                    INSERT INTO plan (user_id, subject_id, plan_name, complete, plan_time, plan_date)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    item["user_id"],
                    item["subject_id"],
                    item["plan_name"],
                    item["complete"],
                    item["plan_time"],
                    item["plan_date"]
                ))

        db.commit()
        print(f"✅ plan {len(todo_items)}개 저장 완료!")

    except Exception as e:
        print("❌ 계획 생성 또는 저장 오류:", e)
        traceback.print_exc()
    finally:
        db.close()


# plan 테이블에서 ToDoItem 리스트 반환
def create_plan_list_for_response(user_id: int, subject_id: int):
    db = pymysql.connect(
        host='localhost',
        user='root',
        password='0904',
        database='yuminsu',
        charset='utf8mb4',
        cursorclass=pymysql.cursors.DictCursor
    )
    try:
        with db.cursor() as cursor:
            cursor.execute("""
                SELECT plan_id, plan_name, plan_time, plan_date, complete
                FROM plan
                WHERE user_id = %s AND subject_id = %s
                ORDER BY plan_id
            """, (user_id, subject_id))

            rows = cursor.fetchall()
            return [ToDoItem(**row) for row in rows]

    except Exception as e:
        print("plan 리스트 응답 오류:", e)
        traceback.print_exc()
        return []
    finally:
        db.close()