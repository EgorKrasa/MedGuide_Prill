from sqlalchemy import Boolean, Column, Float, ForeignKey, Integer, String, Table, Text
from sqlalchemy.dialects.postgresql import ARRAY
from sqlalchemy.orm import Mapped, mapped_column, relationship

from .db import Base


drug_symptoms = Table(
    "drug_symptoms",
    Base.metadata,
    Column("drug_id", ForeignKey("drugs.id", ondelete="CASCADE"), primary_key=True),
    Column("symptom_id", ForeignKey("symptoms.id", ondelete="CASCADE"), primary_key=True),
)


class Drug(Base):
    __tablename__ = "drugs"

    id: Mapped[str] = mapped_column(String(64), primary_key=True)
    name: Mapped[str] = mapped_column(String(255), index=True)
    form: Mapped[str] = mapped_column(String(128))
    dosage: Mapped[str | None] = mapped_column(String(128), nullable=True)
    min_age: Mapped[int | None] = mapped_column(Integer, nullable=True)
    pregnancy_contraindicated: Mapped[bool] = mapped_column(Boolean, default=False)
    prescription_required: Mapped[bool] = mapped_column(Boolean, default=False)

    price_rub: Mapped[float | None] = mapped_column(nullable=True)
    dosages: Mapped[list[str]] = mapped_column(ARRAY(Text), default=list)
    forms_available: Mapped[list[str]] = mapped_column(ARRAY(Text), default=list)
    prices_rub: Mapped[list[float]] = mapped_column(ARRAY(Float), default=list)

    active_substances: Mapped[list[str]] = mapped_column(ARRAY(Text), default=list)
    contraindications: Mapped[list[str]] = mapped_column(ARRAY(Text), default=list)
    chronic_condition_warnings: Mapped[list[str]] = mapped_column(ARRAY(Text), default=list)
    allergy_warnings: Mapped[list[str]] = mapped_column(ARRAY(Text), default=list)
    side_effects: Mapped[list[str]] = mapped_column(ARRAY(Text), default=list)
    notes: Mapped[str | None] = mapped_column(Text, nullable=True)

    symptoms: Mapped[list["Symptom"]] = relationship(
        secondary=drug_symptoms,
        back_populates="drugs",
        lazy="selectin",
    )


class Symptom(Base):
    __tablename__ = "symptoms"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(255), unique=True, index=True)

    drugs: Mapped[list[Drug]] = relationship(
        secondary=drug_symptoms,
        back_populates="symptoms",
        lazy="selectin",
    )

