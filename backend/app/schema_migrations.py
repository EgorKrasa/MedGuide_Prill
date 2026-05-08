from __future__ import annotations

from sqlalchemy import text
from sqlalchemy.engine import Engine


def upgrade_schema(engine: Engine) -> None:
    """
    Лёгкие миграции для учебного проекта.

    SQLAlchemy `create_all()` не добавляет новые колонки в уже существующие таблицы,
    поэтому при развитии модели нужно либо дропать таблицы, либо делать ALTER TABLE.
    Здесь делаем безопасные ALTER-ы только если колонок нет.
    """

    stmts: list[str] = [
        """
        ALTER TABLE drugs
        ADD COLUMN IF NOT EXISTS min_age INTEGER NULL;
        """,
        """
        ALTER TABLE drugs
        ADD COLUMN IF NOT EXISTS pregnancy_contraindicated BOOLEAN NOT NULL DEFAULT FALSE;
        """,
        """
        ALTER TABLE drugs
        ADD COLUMN IF NOT EXISTS prescription_required BOOLEAN NOT NULL DEFAULT FALSE;
        """,
        """
        ALTER TABLE drugs
        ADD COLUMN IF NOT EXISTS price_rub DOUBLE PRECISION NULL;
        """,
        """
        ALTER TABLE drugs
        ADD COLUMN IF NOT EXISTS chronic_condition_warnings TEXT[] NOT NULL DEFAULT '{}'::text[];
        """,
        """
        ALTER TABLE drugs
        ADD COLUMN IF NOT EXISTS allergy_warnings TEXT[] NOT NULL DEFAULT '{}'::text[];
        """,
        """
        ALTER TABLE drugs
        ADD COLUMN IF NOT EXISTS dosages TEXT[] NOT NULL DEFAULT '{}'::text[];
        """,
        """
        ALTER TABLE drugs
        ADD COLUMN IF NOT EXISTS forms_available TEXT[] NOT NULL DEFAULT '{}'::text[];
        """,
        """
        ALTER TABLE drugs
        ADD COLUMN IF NOT EXISTS prices_rub DOUBLE PRECISION[] NOT NULL DEFAULT '{}'::double precision[];
        """,
    ]

    with engine.begin() as conn:
        drugs_exists = conn.execute(text("SELECT to_regclass('public.drugs')")).scalar_one_or_none()
        if not drugs_exists:
            return
        for stmt in stmts:
            conn.execute(text(stmt))
