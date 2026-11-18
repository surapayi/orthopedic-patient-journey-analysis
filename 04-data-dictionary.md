# Data Dictionary: Outpatient Orthopedic Consult for Knee Pain

This file explains each column in the ERD (`03-data-model.png`).

## Read this first

- All data is made up. There is no real patient data.
- I have not worked in a clinic. This dictionary is built from public sources. These include FHIR R4, HL7, X12, NCPDP, and CMS pages.
- A real system would have more columns than this. I kept only the fields my swimlane uses.
- "Assumed" means I made the choice. It did not come from a real clinic.

## How to read the columns

| Column | Meaning |
|---|---|
| Column | The field name, as drawn in the ERD |
| Type | A SQLite-friendly type. Dates and times are TEXT in ISO format (YYYY-MM-DD or YYYY-MM-DD HH:MM). Money is REAL here to keep it simple. |
| Null? | "No" means the field should never be empty. "Yes" means it can be empty. |
| Key | PK = primary key. FK = foreign key. |
| Description | What the field means, in plain words |
| Example | A made-up value |
| Source system | Where the data starts, based on the setup in my README |
| Reference | A public spec I used for field ideas. FHIR is a guide for field names. It is not the data source. |

## Source systems (from my README setup)

| Source system | What it is |
|---|---|
| EHR | The one EHR. It has practice management built in (scheduling, registration, charges, claims). |
| Imaging system | A separate system that holds X-ray orders, images, and reads. |
| Clearinghouse / payer | Outside the clinic. Handles eligibility checks and claims. |
| E-prescribing network / pharmacy | Outside the clinic. Receives the prescription. |

---

## 1. patient

One row per person seen at the clinic.

| Column | Type | Null? | Key | Description | Example | Source system | Reference |
|---|---|---|---|---|---|---|---|
| patient_id | INTEGER | No | PK | Internal ID for the patient | 1001 | EHR (assumed, system-generated) | FHIR Patient.id |
| name | TEXT | No | | Patient's full name in one field | Anna Reyes | EHR (registration) | FHIR Patient.name |
| birth_date | TEXT | No | | Date of birth | 1968-04-12 | EHR (registration) | FHIR Patient.birthDate |
| address | TEXT | Yes | | Home address | 100 Sample Ave, Springfield, WA 98000 | EHR (registration) | FHIR Patient.address |
| mrn | TEXT | No | | Medical record number the clinic uses. Assumed to be unique. | MRN-000123 | EHR (assumed, system-generated) | FHIR Patient.identifier |

Note: `name` is one field because that is how I drew it. A real system splits first and last name.

## 2. appointment

One row per booked visit. A walk-in has no row here.

| Column | Type | Null? | Key | Description | Example | Source system | Reference |
|---|---|---|---|---|---|---|---|
| appointment_id | INTEGER | No | PK | Internal ID for the appointment | 2001 | EHR (scheduling) | FHIR Appointment.id |
| patient_id | INTEGER | No | FK | Links to patient | 1001 | EHR (scheduling) | FHIR Appointment.participant.actor (Patient) |
| provider | TEXT | No | | Surgeon the visit is booked with | Dr. Sample Lee | EHR (scheduling) | FHIR Appointment.participant.actor (Practitioner)|
| visit_type | TEXT | No | | Kind of visit | New patient | EHR (scheduling) | FHIR Appointment.appointmentType |
| status | TEXT | No | | Where the appointment stands. Assumed values: Booked, Arrived, Cancelled, No-show | Booked | EHR (scheduling) | FHIR Appointment.status |
| location | TEXT | Yes | | Clinic site or room | Ortho Clinic, Room 3 | EHR (scheduling) | FHIR Appointment.participant.actor (Location) |
| appointment_datetime | TEXT | No | | Date and time of the visit | 2026-12-01 09:30 | EHR (scheduling) | FHIR Appointment.start |
| appointment_reason | TEXT | Yes | | Why the patient is coming | Chronic right knee pain | EHR (scheduling) | FHIR Appointment.reasonCode |
| create_datetime | TEXT | No | | When the appointment was booked | 2026-11-20 14:05 | EHR (scheduling) | FHIR Appointment.created |

## 3. coverage

One row per insurance plan a patient has on file.

| Column | Type | Null? | Key | Description | Example | Source system | Reference |
|---|---|---|---|---|---|---|---|
| coverage_id | INTEGER | No | PK | Internal ID for the coverage record | 3001 | EHR (registration) | FHIR Coverage.id |
| patient_id | INTEGER | No | FK | Links to patient | 1001 | EHR (registration) | FHIR Coverage.beneficiary |
| member_id | TEXT | No | | Member ID on the insurance card | MEM-778899 | EHR (registration, from the card) | FHIR Coverage.subscriberId |
| plan | TEXT | Yes | | Name of the plan | Sample PPO Gold | EHR (registration) | FHIR Coverage.class |
| payer_name | TEXT | No | | Name of the insurance company | Sample Health Insurance | EHR (registration) | FHIR Coverage.payor |

## 4. eligibility_check

One row each time the clinic checks if coverage is active.

| Column | Type | Null? | Key | Description | Example | Source system | Reference |
|---|---|---|---|---|---|---|---|
| check_id | INTEGER | No | PK | Internal ID for the check | 4001 | EHR (assumed, system-generated) | FHIR CoverageEligibilityRequest.id |
| coverage_id | INTEGER | No | FK | Links to coverage | 3001 | EHR | FHIR CoverageEligibilityRequest.insurance.coverage |
| appointment_id | INTEGER | Yes | FK | Links to the appointment the check was for | 2001 | EHR | no direct match (local design choice) |
| checked_at | TEXT | No | | When the check was sent | 2026-11-30 08:00 | EHR | FHIR CoverageEligibilityRequest.created; X12 270/271 |
| is_active | INTEGER | No | | 1 = coverage active, 0 = not active | 1 | Payer, through the clearinghouse | X12 271, FHIR CoverageEligibilityResponse.insurance.inforce |
| copay | REAL | Yes | | Fixed amount the patient pays at the visit | 40.00 | Payer, through the clearinghouse | X12 271 |
| deductible | REAL | Yes | | Deductible amount from the payer reply | 1500.00 | Payer, through the clearinghouse | X12 271 |

Note: The request goes out as X12 270. The reply comes back as X12 271. The EHR stores the answer.

## 5. encounter

One row per actual visit. It is created when the patient arrives.

| Column | Type | Null? | Key | Description | Example | Source system | Reference |
|---|---|---|---|---|---|---|---|
| encounter_id | INTEGER | No | PK | Internal ID for the visit | 5001 | EHR | FHIR Encounter.id |
| patient_id | INTEGER | No | FK | Links to patient | 1001 | EHR | FHIR Encounter.subject |
| appointment_id | INTEGER | Yes | FK | Links to appointment. Empty for a walk-in. | 2001 | EHR | FHIR Encounter.appointment |
| status | TEXT | No | | Where the visit stands. Assumed values: Arrived, In progress, Finished | Arrived | EHR | FHIR Encounter.status |
| provider | TEXT | No | | Surgeon who saw the patient | Dr. Sample Lee | EHR | FHIR Encounter.participant.individual |
| arrival_datetime | TEXT | No | | When the patient checked in | 2026-12-01 09:22 | EHR (check-in) | FHIR Encounter.period.start; HL7 ADT-A04 |
| reason | TEXT | Yes | | Reason for the visit | Chronic right knee pain | EHR (check-in) | FHIR Encounter.reasonCode |

## 6. imaging_order

One row per X-ray order.

| Column | Type | Null? | Key | Description | Example | Source system | Reference |
|---|---|---|---|---|---|---|---|
| order_id | INTEGER | No | PK | Internal ID for the order | 6001 | EHR | FHIR ServiceRequest.id |
| encounter_id | INTEGER | No | FK | Links to encounter | 5001 | EHR | FHIR ServiceRequest.encounter |
| status | TEXT | No | | Where the order stands. Assumed values: Ordered, In progress, Completed, Cancelled | Ordered | EHR, updated by imaging system | FHIR ServiceRequest.status |
| ordering_provider | TEXT | No | | Who placed the order | Dr. Sample Lee | EHR | FHIR ServiceRequest.requester |
| exam_code | TEXT | No | | Code for the exam. Example is a CPT code for a knee X-ray, 1 to 2 views. | 73560 | EHR | FHIR ServiceRequest.code |
| diagnosis_code | TEXT | Yes | | ICD-10 code for why the exam is ordered | M25.561 | EHR | FHIR ServiceRequest.reasonCode |
| ordered_datetime | TEXT | No | | When the order was placed | 2026-12-01 09:50 | EHR | FHIR ServiceRequest.authoredOn |
| laterality | TEXT | Yes | | Which side of the body to scan: Left, Right, or Both | Right | EHR | FHIR ServiceRequest.bodySite |
| priority | TEXT | Yes | | How fast it is needed. Assumed values: Routine, Urgent | Routine | EHR | FHIR ServiceRequest.priority |

## 7. result

One row per result for an order. An order can have more than one result (for example, preliminary and then final).

| Column | Type | Null? | Key | Description | Example | Source system | Reference |
|---|---|---|---|---|---|---|---|
| result_id | INTEGER | No | PK | Internal ID for the result | 7001 | Imaging system (assumed) | FHIR DiagnosticReport.id |
| order_id | INTEGER | No | FK | Links to imaging_order | 6001 | Imaging system | FHIR DiagnosticReport.basedOn |
| status | TEXT | No | | Assumed values: Preliminary, Final, Corrected | Final | Imaging system | FHIR DiagnosticReport.status |
| result_text | TEXT | Yes | | Written findings (made up) | No fracture. Mild joint space narrowing. | Imaging system | FHIR DiagnosticReport.conclusion |
| issued_at | TEXT | Yes | | When the result was released | 2026-12-01 11:10 | Imaging system | FHIR DiagnosticReport.issued |
| exam_datetime | TEXT | Yes | | When the X-ray was taken | 2026-12-01 10:05 | Imaging system | FHIR ImagingStudy.started |
| reader | TEXT | Yes | | Who read the images | Dr. Sample Chen | Imaging system | FHIR DiagnosticReport.resultsInterpreter |
| image_reference | TEXT | Yes | | ID or link to the images. The images stay in the imaging system. | IMG-STUDY-0001 | Imaging system | DICOM, FHIR DiagnosticReport.imagingStudy |

## 8. prescription

One row per prescription sent to a pharmacy.

| Column | Type | Null? | Key | Description | Example | Source system | Reference |
|---|---|---|---|---|---|---|---|
| prescription_id | INTEGER | No | PK | Internal ID for the prescription | 8001 | EHR | FHIR MedicationRequest.id |
| encounter_id | INTEGER | No | FK | Links to encounter | 5001 | EHR | FHIR MedicationRequest.encounter |
| prescriber | TEXT | No | | Who wrote the prescription | Dr. Sample Lee | EHR | FHIR MedicationRequest.requester |
| prescribed_at | TEXT | No | | When it was written | 2026-12-01 11:30 | EHR | FHIR MedicationRequest.authoredOn |
| medication_code | TEXT | No | | RxNorm code for the drug. I will look up a real code in RxNav before using one. | (RxNorm code for ibuprofen 800 mg tablet) | EHR | FHIR MedicationRequest.medication[x] , NCPDP SCRIPT |
| medication_dose | TEXT | Yes | | Strength and form | 800 mg tablet | EHR | FHIR MedicationRequest.dosageInstruction.doseAndRate.dose[x] (Dosage data type) |
| directions | TEXT | Yes | | Instructions for the patient | Take 1 tablet by mouth every 8 hours with food | EHR | FHIR MedicationRequest.dosageInstruction.text |
| status | TEXT | No | | Assumed values: Sent, Received, Filled, Cancelled | Sent | EHR, updated by e-prescribing network | FHIR MedicationRequest.status |
| pharmacy_id | TEXT | Yes | | ID of the outside pharmacy. This is an external ID, not a foreign key. There is no pharmacy table. | PHARM-0001 | E-prescribing network | NCPDP SCRIPT |

## 9. charge

One row per service the clinic bills for.

| Column | Type | Null? | Key | Description | Example | Source system | Reference |
|---|---|---|---|---|---|---|---|
| charge_id | INTEGER | No | PK | Internal ID for the charge | 9001 | EHR (practice management) | FHIR ChargeItem.id |
| encounter_id | INTEGER | No | FK | Links to encounter | 5001 | EHR (practice management) | FHIR ChargeItem.context |
| claim_id | INTEGER | Yes | FK | Links to claim. Empty if self-pay. | 10001 | EHR (practice management) | n/a |
| provider | TEXT | No | | Who did the service | Dr. Sample Lee | EHR (practice management) | FHIR ChargeItem.performer |
| service_date | TEXT | No | | Date of the service | 2026-12-01 | EHR (practice management) | FHIR ChargeItem.occurrence[x]; X12 837P |
| cpt_code | TEXT | No | | CPT code for the service. Examples: 99204 (new patient visit), 73560 (knee X-ray) | 99204 | EHR (practice management) | FHIR ChargeItem.code; X12 837P |
| diagnosis_code | TEXT | No | | ICD-10 code for the reason for the service | M25.561 | EHR (practice management) | FHIR ChargeItem.reason; X12 837P |
| units | INTEGER | No | | Number of times the service was done | 1 | EHR (practice management) | FHIR ChargeItem.quantity; X12 837P |
| amount | REAL | No | | Total price for this service line (price × units) | 250.00 | EHR (practice management, assumed fee schedule) | FHIR ChargeItem.priceOverride (loose fit); X12 837P |

## 10. claim

One row per bill sent to an insurance company.

| Column | Type | Null? | Key | Description | Example | Source system | Reference |
|---|---|---|---|---|---|---|---|
| claim_id | INTEGER | No | PK | Internal ID for the claim | 10001 | EHR (practice management) | FHIR Claim.id |
| encounter_id | INTEGER | No | FK | Links to encounter | 5001 | EHR (practice management) | FHIR Claim.item.encounter |
| coverage_id | INTEGER | No | FK | Links to the coverage that is billed | 3001 | EHR (practice management) | FHIR Claim.insurance.coverage |
| status | TEXT | No | | Assumed values: Ready, Submitted, Accepted, Rejected, Paid | Submitted | EHR, updated from clearinghouse and payer replies | X12 277CA; loose fit: FHIR ClaimResponse.outcome |
| total_amount | REAL | No | | Total billed. It should equal the sum of the amounts on its charges. | 400.00 | EHR (practice management) | FHIR Claim.total; X12 837P |
| submitted_at | TEXT | Yes | | When the claim was sent | 2026-12-02 16:00 | EHR, through the clearinghouse | FHIR Claim.created; loose fit; X12 837P |
| paid_amount | REAL | Yes | | What the payer paid | 280.00 | Payer, through the clearinghouse | FHIR ClaimResponse.payment.amount; X12 835 |
| patient_owes | REAL | Yes | | What is left for the patient to pay | 120.00 | Payer reply (835), stored in EHR | No direct match in FHIR; X12 835|

---

## Data quality rules (planned for week3)

- Every foreign key should match a row in its parent table.
- `claim.total_amount` should equal the sum of `charge.amount` for that claim.
- A walk-in encounter can have an empty `appointment_id`. Any other empty key is an error.
- A self-pay charge can have an empty `claim_id`.
- Every result should link to an order.
- `paid_amount` should not be bigger than `total_amount`.

## Known simplifications

- `name` and `address` are single fields.
- Money is stored as REAL. A real system would use exact decimals.
- FHIR ChargeItem has no plain price field. priceOverride is the closest match.
- There is no pharmacy, provider, or diagnosis table. I kept them as plain fields.
- Real claims are more complex. My design has one diagnosis per charge.
- Real patients might have more than one insurance plan. My design has one coverage per claim.
- Patient is assumed to be the subscriber.
- Status values are my assumptions.
- No write-offs. patient_owes is stored, not calculated.
