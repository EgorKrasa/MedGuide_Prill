from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str = "postgresql+psycopg://prill:prill@localhost:5432/prill"
    cors_origins: str = "*"
    seed_admin_token: str = ""
    image_base_url: str = "https://prill-api.onrender.com/media/drugs"


settings = Settings()

