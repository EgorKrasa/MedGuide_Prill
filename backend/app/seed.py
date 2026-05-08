from __future__ import annotations

import json
from pathlib import Path

from sqlalchemy import delete, select
from sqlalchemy.orm import Session

from .models import Drug, Symptom, drug_symptoms


def seed_from_mobile_json(db: Session, mobile_assets_path: str) -> dict:
    path = Path(mobile_assets_path)
    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data, list):
        return {"inserted_drugs": 0, "inserted_symptoms": 0}

    db.execute(delete(drug_symptoms))
    db.execute(delete(Drug))
    db.execute(delete(Symptom))
    db.flush()

    inserted_drugs = 0
    inserted_symptoms = 0

    for row in data:
        if not isinstance(row, dict):
            continue

        drug_id = str(row.get("id", "")).strip()
        name = str(row.get("name", "")).strip()
        form = str(row.get("form", "")).strip()
        if not drug_id or not name or not form:
            continue

        drug = db.get(Drug, drug_id)
        if drug is None:
            drug = Drug(
                id=drug_id,
                name=name,
                form=form,
                dosage=row.get("dosage"),
                min_age=_int_or_none(row.get("minAge")),
                pregnancy_contraindicated=_bool_or_false(row.get("pregnancyContraindicated")),
                prescription_required=_bool_or_false(row.get("prescriptionRequired")),
                price_rub=_float_or_none(row.get("priceRub")),
                dosages=_list(row.get("dosages")),
                forms_available=_list(row.get("formsAvailable")),
                prices_rub=_float_list(row.get("pricesRub")),
                active_substances=_list(row.get("activeSubstances")),
                contraindications=_list(row.get("contraindications")),
                chronic_condition_warnings=_list(row.get("chronicConditionWarnings")),
                allergy_warnings=_list(row.get("allergyWarnings")),
                side_effects=_list(row.get("sideEffects")),
                notes=row.get("notes"),
            )
            db.add(drug)
            inserted_drugs += 1
        else:
            drug.name = name
            drug.form = form
            drug.dosage = row.get("dosage")
            drug.min_age = _int_or_none(row.get("minAge"))
            drug.pregnancy_contraindicated = _bool_or_false(row.get("pregnancyContraindicated"))
            drug.prescription_required = _bool_or_false(row.get("prescriptionRequired"))
            drug.price_rub = _float_or_none(row.get("priceRub"))
            drug.dosages = _list(row.get("dosages"))
            drug.forms_available = _list(row.get("formsAvailable"))
            drug.prices_rub = _float_list(row.get("pricesRub"))
            drug.active_substances = _list(row.get("activeSubstances"))
            drug.contraindications = _list(row.get("contraindications"))
            drug.chronic_condition_warnings = _list(row.get("chronicConditionWarnings"))
            drug.allergy_warnings = _list(row.get("allergyWarnings"))
            drug.side_effects = _list(row.get("sideEffects"))
            drug.notes = row.get("notes")

        symptom_names = _list(row.get("indicationsSymptoms"))
        symptoms = []
        for sname in symptom_names:
            sname_n = str(sname).strip()
            if not sname_n:
                continue
            existing = db.execute(select(Symptom).where(Symptom.name == sname_n)).scalars().first()
            if existing is None:
                existing = Symptom(name=sname_n)
                db.add(existing)
                db.flush()
                inserted_symptoms += 1
            symptoms.append(existing)

        drug.symptoms = symptoms

    db.commit()
    return {
        "inserted_drugs": inserted_drugs,
        "inserted_symptoms": inserted_symptoms,
        "catalog_replaced": True,
    }


def _list(v) -> list[str]:
    if v is None:
        return []
    if isinstance(v, list):
        return [str(x).strip() for x in v if str(x).strip()]
    return [str(v).strip()] if str(v).strip() else []


def _float_or_none(v) -> float | None:
    if v is None:
        return None
    try:
        return float(str(v).replace(",", "."))
    except ValueError:
        return None


def _float_list(v) -> list[float]:
    if v is None:
        return []
    if isinstance(v, list):
        out: list[float] = []
        for x in v:
            f = _float_or_none(x)
            if f is not None:
                out.append(f)
        return out
    f2 = _float_or_none(v)
    return [f2] if f2 is not None else []


def _int_or_none(v) -> int | None:
    if v is None:
        return None
    try:
        return int(v)
    except (TypeError, ValueError):
        return None


def _bool_or_false(v) -> bool:
    if isinstance(v, bool):
        return v
    if isinstance(v, str):
        return v.strip().lower() in {"1", "true", "yes", "y", "да"}
    if isinstance(v, (int, float)):
        return v != 0
    return False

