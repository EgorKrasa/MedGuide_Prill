from __future__ import annotations

import re
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from .db import Base, engine, get_db
from .models import Drug, Symptom
from .schema_migrations import upgrade_schema
from .schemas import DrugOut, SymptomOut
from .seed import seed_from_mobile_json
from .settings import settings

app = FastAPI(title="PRILL API", version="0.1.0")


def _image_file_path_for(index: int) -> Path | None:
    ext = _IMAGE_EXT_BY_INDEX.get(index)
    if ext is None:
        return None
    path = _STATIC_DRUGS_DIR / f"{index}{ext}"
    if not path.exists() or not path.is_file():
        return None
    return path

_IMAGE_INDEX_BY_DRUG_ID = {
    "парацетамол": 1,
    "ибупрофен": 2,
    "нимесулид": 3,
    "омепразол": 4,
    "панкреатин": 5,
    "амброксол": 6,
    "лоратадин": 7,
    "дротаверин": 8,
    "лоперамид": 9,
    "сертралин": 10,
    "флуоксетин": 11,
    "амитриптилин": 12,
    "диазепам": 13,
    "феназепам": 14,
    "кветиапин": 15,
    "венлафаксин": 16,
    "эсциталопрам": 17,
    "буспирон": 18,
    "тразодон": 19,
    "арипипразол": 20,
    "метформин": 21,
    "амоксициллин": 22,
    "азитромицин": 23,
    "цефтриаксон": 24,
    "левофлоксацин": 25,
    "кларитромицин": 26,
    "моксифлоксацин": 27,
    "фуросемид": 28,
    "спиронолактон": 29,
    "бисопролол": 30,
    "лозартан": 31,
    "амлодипин": 32,
    "эналаприл": 33,
    "рамиприл": 34,
    "аторвастатин": 35,
    "розувастатин": 36,
    "клопидогрел": 37,
    "ацетилсалициловаякислота": 38,
    "варфарин": 39,
    "ривароксабан": 40,
}


def _drug_name_suggest_key(name: str) -> str:
    s = name.strip()
    m = re.match(r"^(.+?)\s*\([^)]*\)\s*$", s)
    if m:
        return m.group(1).strip().lower()
    return s.lower()


def _better_drug_suggest_label(a: str, b: str) -> str:
    def score(x: str) -> tuple[int, int]:
        branded = 1 if ("(" in x and ")" in x) else 0
        return (branded, len(x))

    return a if score(a) < score(b) else b


def _seed_auth_ok(token: str | None) -> bool:
    expected = settings.seed_admin_token.strip()
    if not expected:
        # local/dev mode: token check disabled
        return True
    return (token or "").strip() == expected


def _image_index_for(drug_id: str) -> int | None:
    return _IMAGE_INDEX_BY_DRUG_ID.get(drug_id.strip().lower())


def _image_url_for(drug_id: str) -> str | None:
    base = settings.image_base_url.strip().rstrip("/")
    index = _image_index_for(drug_id)
    if not base or index is None:
        return None
    return f"{base}/{index}"


@app.get("/media/drugs/{index}")
def drug_image(index: int):
    path = _image_file_path_for(index)
    if path is None:
        raise HTTPException(status_code=404, detail="Image not found")
    return FileResponse(path)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.cors_origins.split(",")] if settings.cors_origins else ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def _startup() -> None:
    upgrade_schema(engine)
    Base.metadata.create_all(bind=engine)


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/admin/seed")
def admin_seed(
    db: Annotated[Session, Depends(get_db)],
    mobile_assets_path: str = Query(
        default="../mobile/assets/drugs.json",
        description="Путь до mobile/assets/drugs.json (для демо-сидирования)",
    ),
    token: str | None = Query(default=None, description="Токен админ-доступа для production seed"),
) -> dict:
    if not _seed_auth_ok(token):
        raise HTTPException(status_code=403, detail="Forbidden")
    return seed_from_mobile_json(db, mobile_assets_path)


@app.get("/symptoms", response_model=list[SymptomOut])
def symptom_suggest(
    db: Annotated[Session, Depends(get_db)],
    query: str = Query("", min_length=0, max_length=64),
    limit: int = Query(10, ge=1, le=50),
) -> list[SymptomOut]:
    q = query.strip()
    stmt = select(Symptom).order_by(Symptom.name.asc()).limit(limit)
    if q:
        stmt = (
            select(Symptom)
            .where(func.lower(Symptom.name).contains(q.lower()))
            .order_by(Symptom.name.asc())
            .limit(limit)
        )
    rows = db.execute(stmt).scalars().all()
    return [SymptomOut(id=s.id, name=s.name) for s in rows]


@app.get("/suggest/active", response_model=list[str])
def suggest_active_substances(
    db: Annotated[Session, Depends(get_db)],
    query: str = Query("", min_length=0, max_length=64),
    limit: int = Query(12, ge=1, le=50),
) -> list[str]:
    q = query.strip().lower()
    rows = db.execute(select(Drug.active_substances)).scalars().all()
    substances: set[str] = set()
    for arr in rows:
        for s in arr or []:
            s2 = str(s).strip()
            if not s2:
                continue
            if q and q not in s2.lower():
                continue
            substances.add(s2)
    out = sorted(substances, key=lambda x: x.lower())
    return out[:limit]


@app.get("/suggest/drug_name", response_model=list[str])
def suggest_drug_names(
    db: Annotated[Session, Depends(get_db)],
    query: str = Query("", min_length=0, max_length=64),
    limit: int = Query(12, ge=1, le=50),
) -> list[str]:
    q = query.strip().lower()
    stmt = select(Drug.name).distinct().order_by(Drug.name.asc())
    rows = db.execute(stmt).scalars().all()
    raw = [str(x).strip() for x in rows if str(x).strip()]

    dedup: dict[str, str] = {}
    for n in raw:
        key = _drug_name_suggest_key(n)
        if key not in dedup:
            dedup[key] = n
        else:
            dedup[key] = _better_drug_suggest_label(dedup[key], n)

    names = list(dedup.values())
    if q:
        names = [n for n in names if q in n.lower()]
    names.sort(key=lambda x: x.lower())
    return names[:limit]


@app.get("/drugs", response_model=list[DrugOut])
def search_drugs(
    db: Annotated[Session, Depends(get_db)],
    symptoms: list[str] = Query(default_factory=list, description="Повторяющийся параметр: ?symptoms=кашель&symptoms=температура"),
    limit: int = Query(50, ge=1, le=200),
) -> list[DrugOut]:
    normalized = [s.strip() for s in symptoms if s.strip()]
    if not normalized:
        return []

    # Ищем препараты, у которых есть ВСЕ симптомы из списка (AND логика).
    subq = (
        select(Drug.id)
        .join(Drug.symptoms)
        .where(Symptom.name.in_(normalized))
        .group_by(Drug.id)
        .having(func.count(func.distinct(Symptom.id)) >= len(set(normalized)))
        .subquery()
    )

    stmt = (
        select(Drug)
        .options(selectinload(Drug.symptoms))
        .join(subq, subq.c.id == Drug.id)
        .order_by(Drug.name.asc())
        .limit(limit)
    )
    rows = db.execute(stmt).scalars().all()
    return [_drug_to_out(d) for d in rows]


@app.get("/drugs/search", response_model=list[DrugOut])
def search_drugs_by_mode(
    db: Annotated[Session, Depends(get_db)],
    mode: str = Query("symptom", pattern="^(symptom|active|name)$"),
    query: str = Query("", min_length=1, max_length=128),
    limit: int = Query(100, ge=1, le=300),
) -> list[DrugOut]:
    q = query.strip().lower()
    if not q:
        return []

    base_stmt = select(Drug).options(selectinload(Drug.symptoms)).order_by(Drug.name.asc()).limit(500)
    rows = db.execute(base_stmt).scalars().all()
    filtered: list[Drug] = []
    for d in rows:
        if mode == "name":
            if q in d.name.lower():
                filtered.append(d)
        elif mode == "active":
            if any(q in s.lower() for s in (d.active_substances or [])):
                filtered.append(d)
        else:
            symptom_names = [s.name.lower() for s in (d.symptoms or [])]
            if any(q in s for s in symptom_names):
                filtered.append(d)
        if len(filtered) >= limit:
            break

    rows = filtered
    return [_drug_to_out(d) for d in rows]


@app.get("/drugs/{drug_id}", response_model=DrugOut)
def get_drug(db: Annotated[Session, Depends(get_db)], drug_id: str) -> DrugOut:
    stmt = select(Drug).where(Drug.id == drug_id).options(selectinload(Drug.symptoms))
    drug = db.execute(stmt).scalars().first()
    if drug is None:
        raise HTTPException(status_code=404, detail="Drug not found")
    return _drug_to_out(drug)


@app.get("/drugs/{drug_id}/analogs", response_model=list[DrugOut])
def get_drug_analogs(
    db: Annotated[Session, Depends(get_db)],
    drug_id: str,
    limit: int = Query(10, ge=1, le=30),
) -> list[DrugOut]:
    drug = db.execute(select(Drug).where(Drug.id == drug_id)).scalars().first()
    if drug is None:
        raise HTTPException(status_code=404, detail="Drug not found")

    actives = [x.lower() for x in (drug.active_substances or [])]
    if not actives:
        return []

    stmt = (
        select(Drug)
        .options(selectinload(Drug.symptoms))
        .where(Drug.id != drug.id)
        .where(Drug.form == drug.form)
    )
    candidates = db.execute(stmt).scalars().all()
    analogs = []
    for candidate in candidates:
        candidate_actives = {x.lower() for x in (candidate.active_substances or [])}
        if candidate_actives.intersection(actives):
            analogs.append(candidate)
        if len(analogs) >= limit:
            break
    return [_drug_to_out(d) for d in analogs]


def _drug_to_out(d: Drug) -> DrugOut:
    return DrugOut(
        id=d.id,
        name=d.name,
        image_index=_image_index_for(d.id),
        image_url=_image_url_for(d.id),
        form=d.form,
        dosage=d.dosage,
        min_age=d.min_age,
        pregnancy_contraindicated=d.pregnancy_contraindicated,
        prescription_required=d.prescription_required,
        price_rub=d.price_rub,
        dosages=list(d.dosages or []),
        forms_available=list(d.forms_available or []),
        prices_rub=list(d.prices_rub or []),
        active_substances=list(d.active_substances or []),
        contraindications=list(d.contraindications or []),
        chronic_condition_warnings=list(d.chronic_condition_warnings or []),
        allergy_warnings=list(d.allergy_warnings or []),
        side_effects=list(d.side_effects or []),
        notes=d.notes,
        symptoms=[SymptomOut(id=s.id, name=s.name) for s in (d.symptoms or [])],
    )

