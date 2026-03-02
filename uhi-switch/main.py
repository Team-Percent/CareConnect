from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from pydantic import BaseModel
from typing import List
import uuid

import models
from database import engine, get_db

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="UHI Switch Server")

class ConsentGrantRequest(BaseModel):
    patient_abha_id: str
    doctor_id: str
    hospital_id: str
    permissions: List[str]
    expires_at: datetime

class ConsentResponse(BaseModel):
    consent_id: str
    patient_abha_id: str
    doctor_id: str
    hospital_id: str
    status: str
    permissions: List[str]
    granted_at: datetime
    expires_at: datetime

@app.get("/health")
def health_check():
    return {"status": "ok"}

@app.post("/consent/grant", response_model=ConsentResponse)
def grant_consent(consent_req: ConsentGrantRequest, db: Session = Depends(get_db)):
    consent_id = str(uuid.uuid4())
    db_consent = models.ConsentArtifact(
        consent_id=consent_id,
        patient_abha_id=consent_req.patient_abha_id,
        doctor_id=consent_req.doctor_id,
        hospital_id=consent_req.hospital_id,
        status="GRANTED",
        permissions=consent_req.permissions,
        granted_at=datetime.now(timezone.utc),
        expires_at=consent_req.expires_at
    )
    db.add(db_consent)
    
    # Audit trail
    db_audit = models.AuditLog(
        actor=consent_req.patient_abha_id,
        action="GRANT_CONSENT",
        resource=f"ConsentArtifact/{consent_id}",
        current_hash=consent_id,
        previous_hash="root"
    )
    db.add(db_audit)
    
    db.commit()
    db.refresh(db_consent)
    return db_consent

@app.get("/consent/list", response_model=List[ConsentResponse])
def list_consents(patient_abha_id: str, db: Session = Depends(get_db)):
    consents = db.query(models.ConsentArtifact).filter(
        models.ConsentArtifact.patient_abha_id == patient_abha_id
    ).all()
    return consents
