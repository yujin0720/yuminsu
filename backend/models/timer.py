from sqlalchemy import Column, Integer, Date, ForeignKey, TIMESTAMP
from sqlalchemy.sql import func
from db import Base

class Timer(Base):
    __tablename__ = "timer"

    timer_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("user.user_id"), nullable=False)
    study_date = Column(Date, nullable=False)
    total_minutes = Column(Integer, nullable=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
