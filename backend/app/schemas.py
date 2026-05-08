from pydantic import BaseModel, Field


class SymptomOut(BaseModel):
    id: int
    name: str


class DrugOut(BaseModel):
    id: str
    name: str
    image_index: int | None = None
    image_url: str | None = None
    form: str
    dosage: str | None = None
    min_age: int | None = None
    pregnancy_contraindicated: bool = False
    prescription_required: bool = False
    price_rub: float | None = None
    dosages: list[str] = Field(default_factory=list)
    forms_available: list[str] = Field(default_factory=list)
    prices_rub: list[float] = Field(default_factory=list)
    active_substances: list[str] = Field(default_factory=list)
    contraindications: list[str] = Field(default_factory=list)
    chronic_condition_warnings: list[str] = Field(default_factory=list)
    allergy_warnings: list[str] = Field(default_factory=list)
    side_effects: list[str] = Field(default_factory=list)
    notes: str | None = None
    symptoms: list[SymptomOut] = Field(default_factory=list)

