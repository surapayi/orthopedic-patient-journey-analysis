-- 02-sample-data.sql
-- Loads made-up rows into the 10 tables.
-- All data is synthetic. Nothing comes from a real clinic or patient.
-- Scenario and error IDs (S1, E5, ...) match sample-data-plan.md.
-- Run 01-create-tables.sql first. To run this file again, run 01 first.
--
-- Batches in this file:
--   Batch 1: all patients, and scenario S1 (full happy path)
-- Dates are in the past so that Paid claims make sense.

PRAGMA foreign_keys = OFF;

-- =====================================================================
-- Batch 1a: patients 1001 to 1013
-- 1001 to 1010 are the normal scenarios S1 to S10.
-- 1011 is S11 and 1012 is S12.
-- 1013 is planted error E5: same MRN as patient 1001.
-- Patient 1005 has an empty address on purpose (address is optional).
-- =====================================================================
INSERT INTO patient (patient_id, name, birth_date, address, mrn) VALUES
(1001, 'Anna Reyes',    '1968-04-12', '100 Sample Ave, Springfield, WA 98000', 'MRN-000123'),
(1002, 'Ben Carter',    '1975-09-03', '102 Sample Ave, Springfield, WA 98000', 'MRN-000124'),
(1003, 'Carla Nguyen',  '1982-01-27', '104 Sample Ave, Springfield, WA 98000', 'MRN-000125'),
(1004, 'David Okafor',  '1959-11-15', '106 Sample Ave, Springfield, WA 98000', 'MRN-000126'),
(1005, 'Elena Petrova', '1990-06-08', NULL,                                    'MRN-000127'),
(1006, 'Frank Dubois',  '1971-03-22', '110 Sample Ave, Springfield, WA 98000', 'MRN-000128'),
(1007, 'Grace Kim',     '1963-12-30', '112 Sample Ave, Springfield, WA 98000', 'MRN-000129'),
(1008, 'Henry Alvarez', '1985-07-19', '114 Sample Ave, Springfield, WA 98000', 'MRN-000130'),
(1009, 'Irene Novak',   '1978-02-14', '116 Sample Ave, Springfield, WA 98000', 'MRN-000131'),
(1010, 'James Tanaka',  '1954-10-05', '118 Sample Ave, Springfield, WA 98000', 'MRN-000132'),
(1011, 'Karen Singh',   '1969-05-21', '120 Sample Ave, Springfield, WA 98000', 'MRN-000133'),
(1012, 'Luis Moreno',   '1988-08-09', '122 Sample Ave, Springfield, WA 98000', 'MRN-000134'),
-- E5 (planted error): a different person with the same MRN as patient 1001
(1013, 'Mia Johnson',   '1995-04-17', '124 Sample Ave, Springfield, WA 98000', 'MRN-000123');

-- =====================================================================
-- Batch 1b: S1 full happy path (patient 1001)
-- Appointment, active coverage, eligibility check, finished encounter,
-- right knee X-ray with a Final result, a filled prescription,
-- two charges on one Paid claim.
-- =====================================================================
INSERT INTO appointment (appointment_id, patient_id, provider, visit_type, status, location, appointment_datetime, appointment_reason, create_datetime) VALUES
(2001, 1001, 'Dr. Sample Lee', 'New patient', 'Arrived', 'Ortho Clinic, Room 3', '2026-09-14 09:30', 'Chronic right knee pain', '2026-09-02 14:05');

INSERT INTO coverage (coverage_id, patient_id, member_id, plan, payer_name) VALUES
(3001, 1001, 'MEM-778899', 'Sample PPO Gold', 'Sample Health Insurance');

INSERT INTO eligibility_check (check_id, coverage_id, appointment_id, checked_at, is_active, copay, deductible) VALUES
(4001, 3001, 2001, '2026-09-13 08:00', 1, 40.00, 1500.00);

INSERT INTO encounter (encounter_id, patient_id, appointment_id, status, provider, arrival_datetime, reason) VALUES
(5001, 1001, 2001, 'Finished', 'Dr. Sample Lee', '2026-09-14 09:22', 'Chronic right knee pain');

INSERT INTO imaging_order (order_id, encounter_id, status, ordering_provider, exam_code, diagnosis_code, ordered_datetime, laterality, priority) VALUES
(6001, 5001, 'Completed', 'Dr. Sample Lee', '73560', 'M25.561', '2026-09-14 09:50', 'Right', 'Routine');

INSERT INTO result (result_id, order_id, status, result_text, issued_at, exam_datetime, reader, image_reference) VALUES
(7001, 6001, 'Final', 'No fracture. Mild joint space narrowing.', '2026-09-14 11:10', '2026-09-14 10:05', 'Dr. Sample Chen', 'IMG-STUDY-0001');

-- medication_code is a real RxNorm code from RxNav. 197807 is ibuprofen 800 MG Oral Tablet
INSERT INTO prescription (prescription_id, encounter_id, prescriber, prescribed_at, medication_code, medication_dose, directions, status, pharmacy_id) VALUES
(8001, 5001, 'Dr. Sample Lee', '2026-09-14 11:30', '197807', '1 tablet', 'Take 1 tablet by mouth every 8 hours with food', 'Filled', 'PHARM-0001');

-- Claim is loaded before its charges, because charges point to it.
INSERT INTO claim (claim_id, encounter_id, coverage_id, status, total_amount, submitted_at, paid_amount, patient_owes) VALUES
(10001, 5001, 3001, 'Paid', 400.00, '2026-09-15 16:00', 280.00, 120.00);

INSERT INTO charge (charge_id, encounter_id, claim_id, provider, service_date, cpt_code, diagnosis_code, units, amount) VALUES
(9001, 5001, 10001, 'Dr. Sample Lee', '2026-09-14', '99204', 'M25.561', 1, 250.00),
(9002, 5001, 10001, 'Dr. Sample Lee', '2026-09-14', '73560', 'M25.561', 1, 150.00);

-- =====================================================================
-- S2 walk-in (patient 1002)
-- No appointment. The encounter and the eligibility check both have an
-- empty appointment_id. Active coverage, left knee X-ray with a Final
-- result, a prescription, two charges on one Paid claim.
-- =====================================================================
INSERT INTO coverage (coverage_id, patient_id, member_id, plan, payer_name) VALUES
(3002, 1002, 'MEM-112233', 'Sample HMO Silver', 'Sample Health Insurance');

INSERT INTO eligibility_check (check_id, coverage_id, appointment_id, checked_at, is_active, copay, deductible) VALUES
(4002, 3002, NULL, '2026-09-16 09:45', 1, 30.00, 2000.00);

INSERT INTO encounter (encounter_id, patient_id, appointment_id, status, provider, arrival_datetime, reason) VALUES
(5002, 1002, NULL, 'Finished', 'Dr. Sample Lee', '2026-09-16 09:40', 'Left knee pain, walk-in');

INSERT INTO imaging_order (order_id, encounter_id, status, ordering_provider, exam_code, diagnosis_code, ordered_datetime, laterality, priority) VALUES
(6002, 5002, 'Completed', 'Dr. Sample Lee', '73560', 'M25.562', '2026-09-16 10:05', 'Left', 'Routine');

INSERT INTO result (result_id, order_id, status, result_text, issued_at, exam_datetime, reader, image_reference) VALUES
(7002, 6002, 'Final', 'No fracture seen.', '2026-09-16 11:00', '2026-09-16 10:20', 'Dr. Sample Chen', 'IMG-STUDY-0002');

INSERT INTO prescription (prescription_id, encounter_id, prescriber, prescribed_at, medication_code, medication_dose, directions, status, pharmacy_id) VALUES
(8002, 5002, 'Dr. Sample Lee', '2026-09-16 11:30', '197807', '1 tablet', 'Take 1 tablet by mouth every 8 hours with food', 'Sent', 'PHARM-0002');

INSERT INTO claim (claim_id, encounter_id, coverage_id, status, total_amount, submitted_at, paid_amount, patient_owes) VALUES
(10002, 5002, 3002, 'Paid', 400.00, '2026-09-17 15:30', 300.00, 100.00);

INSERT INTO charge (charge_id, encounter_id, claim_id, provider, service_date, cpt_code, diagnosis_code, units, amount) VALUES
(9003, 5002, 10002, 'Dr. Sample Lee', '2026-09-16', '99204', 'M25.562', 1, 250.00),
(9004, 5002, 10002, 'Dr. Sample Lee', '2026-09-16', '73560', 'M25.562', 1, 150.00);

-- =====================================================================
-- S3 self-pay (patient 1003)
-- Appointment and encounter, right knee X-ray with a Final result.
-- No coverage, no eligibility check, no claim.
-- Both charges have an empty claim_id.
-- =====================================================================
INSERT INTO appointment (appointment_id, patient_id, provider, visit_type, status, location, appointment_datetime, appointment_reason, create_datetime) VALUES
(2003, 1003, 'Dr. Sample Lee', 'New patient', 'Arrived', 'Ortho Clinic, Room 2', '2026-09-18 10:00', 'Right knee pain', '2026-09-10 11:20');

INSERT INTO encounter (encounter_id, patient_id, appointment_id, status, provider, arrival_datetime, reason) VALUES
(5003, 1003, 2003, 'Finished', 'Dr. Sample Lee', '2026-09-18 09:55', 'Right knee pain');

INSERT INTO imaging_order (order_id, encounter_id, status, ordering_provider, exam_code, diagnosis_code, ordered_datetime, laterality, priority) VALUES
(6003, 5003, 'Completed', 'Dr. Sample Lee', '73560', 'M25.561', '2026-09-18 10:20', 'Right', 'Routine');

INSERT INTO result (result_id, order_id, status, result_text, issued_at, exam_datetime, reader, image_reference) VALUES
(7003, 6003, 'Final', 'No fracture seen.', '2026-09-18 11:15', '2026-09-18 10:35', 'Dr. Sample Chen', 'IMG-STUDY-0003');

INSERT INTO charge (charge_id, encounter_id, claim_id, provider, service_date, cpt_code, diagnosis_code, units, amount) VALUES
(9005, 5003, NULL, 'Dr. Sample Lee', '2026-09-18', '99204', 'M25.561', 1, 250.00),
(9006, 5003, NULL, 'Dr. Sample Lee', '2026-09-18', '73560', 'M25.561', 1, 150.00);

-- =====================================================================
-- S4 inactive coverage (patient 1004)
-- Coverage row exists, but the eligibility check says is_active = 0.
-- copay and deductible are empty because the payer gave no benefits.
-- The visit still happens, with a left knee X-ray (Final result) and a
-- prescription. The charges are not sent to the payer, so claim_id is
-- empty. There is no claim.
-- =====================================================================
INSERT INTO appointment (appointment_id, patient_id, provider, visit_type, status, location, appointment_datetime, appointment_reason, create_datetime) VALUES
(2004, 1004, 'Dr. Sample Lee', 'New patient', 'Arrived', 'Ortho Clinic, Room 3', '2026-09-21 14:00', 'Left knee pain', '2026-09-12 09:40');

INSERT INTO coverage (coverage_id, patient_id, member_id, plan, payer_name) VALUES
(3004, 1004, 'MEM-445566', 'Sample PPO Basic', 'Sample Health Insurance');

INSERT INTO eligibility_check (check_id, coverage_id, appointment_id, checked_at, is_active, copay, deductible) VALUES
(4004, 3004, 2004, '2026-09-20 08:15', 0, NULL, NULL);

INSERT INTO encounter (encounter_id, patient_id, appointment_id, status, provider, arrival_datetime, reason) VALUES
(5004, 1004, 2004, 'Finished', 'Dr. Sample Lee', '2026-09-21 13:50', 'Left knee pain');

INSERT INTO imaging_order (order_id, encounter_id, status, ordering_provider, exam_code, diagnosis_code, ordered_datetime, laterality, priority) VALUES
(6004, 5004, 'Completed', 'Dr. Sample Lee', '73560', 'M25.562', '2026-09-21 14:15', 'Left', 'Routine');

INSERT INTO result (result_id, order_id, status, result_text, issued_at, exam_datetime, reader, image_reference) VALUES
(7004, 6004, 'Final', 'No fracture seen.', '2026-09-21 15:10', '2026-09-21 14:30', 'Dr. Sample Chen', 'IMG-STUDY-0004');

INSERT INTO prescription (prescription_id, encounter_id, prescriber, prescribed_at, medication_code, medication_dose, directions, status, pharmacy_id) VALUES
(8004, 5004, 'Dr. Sample Lee', '2026-09-21 15:30', '197807', '1 tablet', 'Take 1 tablet by mouth every 8 hours with food', 'Received', 'PHARM-0004');

INSERT INTO charge (charge_id, encounter_id, claim_id, provider, service_date, cpt_code, diagnosis_code, units, amount) VALUES
(9007, 5004, NULL, 'Dr. Sample Lee', '2026-09-21', '99204', 'M25.562', 1, 250.00),
(9008, 5004, NULL, 'Dr. Sample Lee', '2026-09-21', '73560', 'M25.562', 1, 150.00);
