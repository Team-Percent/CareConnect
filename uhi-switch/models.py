from sqlalchemy import Column, Integer, String, DateTime, JSON
from sqlalchemy.ext.declarative import declarative_base
from datetime import datetime, timezone

Base = declarative_base()

class ConsentArtifact(Base):
    __tablename__ = "consent_artifacts"

    id = Column(Integer, primary_key=True, index=True)
    consent_id = Column(String, unique=True, index=True)
    patient_abha_id = Column(String, index=True)
    doctor_id = Column(String)
    hospital_id = Column(String)
    status = Column(String, default="GRANTED") # GRANTED, REVOKED, EXPIRED
    permissions = Column(JSON) # e.g. ["Observation", "Condition"]
    granted_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    expires_at = Column(DateTime)

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    actor = Column(String) # who made the request
    action = Column(String) # what action (e.g. "READ_FHIR")
    resource = Column(String) # resource accessed (e.g. "Patient/123")
    consent_id = Column(String, nullable=True) # consent artifact used
    previous_hash = Column(String) # For cryptographic chaining
    current_hash = Column(String)
