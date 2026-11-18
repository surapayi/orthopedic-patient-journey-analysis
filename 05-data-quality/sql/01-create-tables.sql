-- 01-create-tables.sql
-- Builds the 10 tables for the outpatient orthopedic knee consult model.
-- Source: 04-data-dictionary.md (names, types, keys, and Null? rules).
-- All data in this project is synthetic. Nothing comes from a real clinic or patient.
--
-- Design choices:
--   * Foreign keys are declared so the model is documented.
--     Enforcement is turned OFF so the planted errors (E1, E3) can load.
--   * No UNIQUE rule on patient.mrn, so the duplicate MRN (E5) can load.
--   * No CHECK rules on status or code columns, so the bad status (E8) can load.
--   * Dates and times are TEXT (YYYY-MM-DD or YYYY-MM-DD HH:MM).
--   * Money is REAL to keep it simple.
--   * prescription.pharmacy_id is an external ID. There is no pharmacy table.

PRAGMA foreign_keys = OFF;

-- Drop in reverse order so this file can be run again.
-- This deletes all data. That is fine, because the data is made up.
DROP TABLE IF EXISTS charge;
DROP TABLE IF EXISTS claim;
DROP TABLE IF EXISTS prescription;
DROP TABLE IF EXISTS result;
DROP TABLE IF EXISTS imaging_order;
DROP TABLE IF EXISTS encounter;
DROP TABLE IF EXISTS eligibility_check;
DROP TABLE IF EXISTS coverage;
DROP TABLE IF EXISTS appointment;
DROP TABLE IF EXISTS patient;

-- 1. patient
CREATE TABLE patient (
    patient_id    INTEGER PRIMARY KEY,
    name          TEXT    NOT NULL,
    birth_date    TEXT    NOT NULL,
    address       TEXT,
    mrn           TEXT    NOT NULL
);

-- 2. appointment
CREATE TABLE appointment (
    appointment_id        INTEGER PRIMARY KEY,
    patient_id            INTEGER NOT NULL REFERENCES patient (patient_id),
    provider              TEXT    NOT NULL,
    visit_type            TEXT    NOT NULL,
    status                TEXT    NOT NULL,
    location              TEXT,
    appointment_datetime  TEXT    NOT NULL,
    appointment_reason    TEXT,
    create_datetime       TEXT    NOT NULL
);

-- 3. coverage
CREATE TABLE coverage (
    coverage_id   INTEGER PRIMARY KEY,
    patient_id    INTEGER NOT NULL REFERENCES patient (patient_id),
    member_id     TEXT    NOT NULL,
    plan          TEXT,
    payer_name    TEXT    NOT NULL
);

-- 4. eligibility_check
-- appointment_id can be empty: a walk-in has no appointment.
CREATE TABLE eligibility_check (
    check_id        INTEGER PRIMARY KEY,
    coverage_id     INTEGER NOT NULL REFERENCES coverage (coverage_id),
    appointment_id  INTEGER REFERENCES appointment (appointment_id),
    checked_at      TEXT    NOT NULL,
    is_active       INTEGER NOT NULL,   -- 1 = active, 0 = not active
    copay           REAL,
    deductible      REAL
);

-- 5. encounter
-- appointment_id can be empty: a walk-in has no appointment.
CREATE TABLE encounter (
    encounter_id      INTEGER PRIMARY KEY,
    patient_id        INTEGER NOT NULL REFERENCES patient (patient_id),
    appointment_id    INTEGER REFERENCES appointment (appointment_id),
    status            TEXT    NOT NULL,
    provider          TEXT    NOT NULL,
    arrival_datetime  TEXT    NOT NULL,
    reason            TEXT
);

-- 6. imaging_order
CREATE TABLE imaging_order (
    order_id           INTEGER PRIMARY KEY,
    encounter_id       INTEGER NOT NULL REFERENCES encounter (encounter_id),
    status             TEXT    NOT NULL,
    ordering_provider  TEXT    NOT NULL,
    exam_code          TEXT    NOT NULL,
    diagnosis_code     TEXT,
    ordered_datetime   TEXT    NOT NULL,
    laterality         TEXT,
    priority           TEXT
);

-- 7. result
CREATE TABLE result (
    result_id        INTEGER PRIMARY KEY,
    order_id         INTEGER NOT NULL REFERENCES imaging_order (order_id),
    status           TEXT    NOT NULL,
    result_text      TEXT,
    issued_at        TEXT,
    exam_datetime    TEXT,
    reader           TEXT,
    image_reference  TEXT
);

-- 8. prescription
CREATE TABLE prescription (
    prescription_id   INTEGER PRIMARY KEY,
    encounter_id      INTEGER NOT NULL REFERENCES encounter (encounter_id),
    prescriber        TEXT    NOT NULL,
    prescribed_at     TEXT    NOT NULL,
    medication_code   TEXT    NOT NULL,
    medication_dose   TEXT,
    directions        TEXT,
    status            TEXT    NOT NULL,
    pharmacy_id       TEXT    -- external ID, not a foreign key
);

-- 9. claim (created before charge, because charge points to it)
CREATE TABLE claim (
    claim_id      INTEGER PRIMARY KEY,
    encounter_id  INTEGER NOT NULL REFERENCES encounter (encounter_id),
    coverage_id   INTEGER NOT NULL REFERENCES coverage (coverage_id),
    status        TEXT    NOT NULL,
    total_amount  REAL    NOT NULL,
    submitted_at  TEXT,
    paid_amount   REAL,
    patient_owes  REAL
);

-- 10. charge
-- claim_id can be empty: a self-pay charge has no claim.
CREATE TABLE charge (
    charge_id       INTEGER PRIMARY KEY,
    encounter_id    INTEGER NOT NULL REFERENCES encounter (encounter_id),
    claim_id        INTEGER REFERENCES claim (claim_id),
    provider        TEXT    NOT NULL,
    service_date    TEXT    NOT NULL,
    cpt_code        TEXT    NOT NULL,
    diagnosis_code  TEXT    NOT NULL,
    units           INTEGER NOT NULL,
    amount          REAL    NOT NULL
);
