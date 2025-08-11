from logging.config import fileConfig

from sqlalchemy import engine_from_config, pool
from alembic import context

# Alembic Config
config = context.config

# Logging
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# -------------------------
# 경로 세팅 + 모델 import
# -------------------------
import os, sys

# .../backend/alembic/env.py 기준
BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))   # .../backend
ROOT_DIR = os.path.dirname(BASE_DIR)                                        # .../CapstoneEduApp (옵션)

if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)
if ROOT_DIR not in sys.path:
    sys.path.insert(0, ROOT_DIR)

# Base 및 모델 임포트 (autogenerate가 변경을 감지하려면 실제 import 필요)
from models import Base
from models.notification import Notification  # ← 알림 모델 추가 import
# 필요하면 다른 모델도 import:
# from models.user import User
# from models.plan import Plan
# from models.row_plan import RowPlan
# ...

target_metadata = Base.metadata

# -------------------------
# Offline / Online
# -------------------------
def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
