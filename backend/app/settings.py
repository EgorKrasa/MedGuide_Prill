from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


def _normalize_database_url(url: str) -> str:
    """Render/Neon часто отдают postgres:// — для SQLAlchemy+psycopg нужен другой префикс."""
    if url.startswith("postgres://"):
        return "postgresql+psycopg://" + url[len("postgres://") :]
    if url.startswith("postgresql://") and "+psycopg" not in url:
        return "postgresql+psycopg://" + url[len("postgresql://") :]
    return url


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg://prill:prill@localhost:5432/prill"

    @field_validator("database_url", mode="before")
    @classmethod
    def normalize_db_url(cls, v: object) -> object:
        if isinstance(v, str):
            return _normalize_database_url(v)
        return v
    cors_origins: str = "*"
    seed_admin_token: str = ""
    image_base_url: str = "https://prill-api.onrender.com/media/drugs"


settings = Settings()

