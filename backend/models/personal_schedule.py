from sqlalchemy import Column, Integer, String, Date, ForeignKey, DateTime
from sqlalchemy.orm import relationship
from datetime import datetime
from db import Base

class PersonalSchedule(Base):
    __tablename__ = "personal_schedule"

    id = Column(Integer, primary_key=True, index=True)

    user_id = Column(Integer, ForeignKey("user.user_id"))
    title = Column(String, nullable=False)
    date = Column(Date, nullable=False)
    color = Column(String, default="#2196F3")  # 기본 파란색
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")
