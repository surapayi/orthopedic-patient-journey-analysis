# Sample Data Plan

This plan says what made-up data I will load into SQLite, and why.

## Read this first

- All data is made up. Nothing comes from a real clinic or a real patient.
- I have not worked in a clinic. The scenarios come from my swimlane, my data dictionary, and public sources.
- The planted errors are on purpose. They test my data quality checks.
- Status values are the ones I assumed in the data dictionary.

## Assumptions

This is why I picked these cases. The "Basis" column says where each assumption comes from.

| ID | Assumption | Why it matters for the sample data | Basis |
|---|---|---|---|
| A1 | The clinic has one EHR with built-in practice management. Imaging is a separate system. The clearinghouse, payer, e-prescribing network, and pharmacy are outside the clinic. | It decides which data comes from the EHR and which comes from other systems. | My README |
| A2 | A patient can walk in with no appointment. | S2: an encounter with an empty `appointment_id` | My ERD note |
| A3 | A patient can be self-pay. A self-pay charge has no claim. | S3: an empty `claim_id` on a charge is allowed | My ERD |
| A4 | A patient may not go through every step. They can no-show, cancel, or leave before the X-ray. | S5, S6, S11 | Assumed |
| A5 | A visit does not always need an X-ray or a prescription. | S10, S12 | Assumed |
| A6 | One order can have many results, like Preliminary then Final. It can also have none yet. | S7, S11 | My ERD |
| A7 | If coverage is inactive, the visit still happens. The charges are not sent to the payer. | S4 | Assumed |
| A8 | The payer takes time to reply. A claim can sit as Submitted with no payment. | S9: an empty `paid_amount` is normal at that stage | Assumed |
| A9 | A payer can reject a claim. | S8 | Assumed |
| A10 | The EHR checks basic things at data entry, like required fields and formats. This catches single-field mistakes. | My planted errors focus on other kinds of problems (see A11). | Assumed |
| A11 | Errors still get in. They come from bugs in calculations, from other systems, from manual edits, from duplicate registration, and from messages that arrive late or in the wrong order. | It explains how each planted error could happen. | Assumed |
| A12 | I chose errors that NOT NULL and primary key rules do not already block. | If the database blocked a bad row, it could never load, so no check could test it. | My design choice |
| A13 | I treat E6 (appointment created after the visit date) as an error. A real clinic might sometimes enter a visit late on purpose. | This is a judgment call. I will say so in the write-up. | My design choice |
| A14 | The data is simplified: no write-offs or adjustments, one diagnosis per charge, one coverage per claim, and the patient is the subscriber. | It keeps the model small. These are listed in my data dictionary too. | My design choice |

## How I decided I have enough cases

- Every rule has at least one row that passes and one row that fails.
- Every link between tables has a zero, one, and many case where that makes sense.
- Every optional field is empty in one row and filled in another.
- Every status value appears at least once.

More rows would not make the checks better. They would only make the data harder to read.

## Out of scope

I left these out on purpose: prior authorization, referrals, patients with several visits, secondary insurance, claim resubmission, and write-offs.

## Planted errors (updated)

| ID | Error in plain words | Rule it breaks | Quality dimension | How it could happen (assumed) | Row (fill in later) |
|---|---|---|---|---|---|
| E1 | A charge points to a claim that does not exist | Every foreign key has a parent | Consistency | A claim was deleted, or the claim ID was keyed wrong | charge: |
| E2 | A claim's `total_amount` does not equal the sum of its charges | Claim total equals sum of its charge amounts | Consistency | A calculation bug, or a charge edited after the claim was built | claim: |
| E3 | A result points to an order that does not exist | Every result links to an order | Consistency | The imaging system sent the wrong order ID | result: |
| E4 | A claim has `paid_amount` bigger than `total_amount` | Paid should not be bigger than billed | Validity | A payer reply was matched to the wrong claim | claim: |
| E5 | A second patient (1013) has the same `mrn` as patient 1001 | MRN should be unique | Uniqueness | Two staff registered the same patient | patient: |
| E6 | An appointment was created after the appointment date | Created date comes before the visit date | Validity (date logic) | A visit was entered late by hand (see A13) | appointment: |
| E7 | A coverage has an empty text value in `member_id` | Required field must have a real value | Completeness | An interface filled an empty string instead of leaving it empty | coverage: |
| E8 | A claim has the status "Pending", which is not in my allowed list | Status must be one of the allowed values | Validity | Another system sent a status code I do not list | claim: |
| E9 | An order has status Completed but no result | A completed order should have at least one result | Consistency | The result message was lost or has not arrived | imaging_order: |

## Why I need two kinds of rows

- **Normal scenarios** show that my design handles real situations. A good check should **not** flag these.
- **Planted errors** are bad rows I add on purpose. If a check finds nothing, I would not know if the check is broken or the data is clean. The planted errors prove each check works.

## How I will build it

- SQLite, using DB Browser for SQLite.
- Files in the `/sql` folder: `01_create_tables.sql`, `02_sample_data.sql`, `03_dq_checks.sql`.
- Tables come from the data dictionary: same names, types, keys, and "Null?" rules.
- I will not add a UNIQUE rule on `mrn`. If I did, SQLite would block the duplicate in E5.
- SQLite does not enforce foreign keys unless I turn them on. I will leave them off so E1 and E3 can load.
- Each planted error lives in its own extra row. A normal scenario never breaks.
- Size target: about 11 patients, 10 appointments, 9 coverages, 11 encounters, 8 orders, 10 results, 9 prescriptions, 20 charges, 9 claims.

## Normal scenarios

| ID | Scenario | Story in plain words | What it tests | Should a check flag it? |
|---|---|---|---|---|
| S1 | Full happy path | Patient 1001 books an appointment. Coverage is active and the eligibility check says yes. The patient arrives and the encounter is finished. The surgeon orders a right knee X-ray. The result is Final. A prescription is Filled. Two charges (99204 for $250, 73560 for $150) go on one claim. The claim is Paid: total 400, paid 280, patient owes 120. | The whole journey works with no gaps | No |
| S2 | Walk-in | Patient 1002 has no appointment. The encounter has an empty `appointment_id`. The patient has active coverage, an X-ray with a Final result, charges, and a claim. | An empty `appointment_id` on an encounter is allowed | No |
| S3 | Self-pay | Patient 1003 has an appointment and an encounter. There is no coverage row and no eligibility check. The charges have an empty `claim_id`. There is no claim. | An empty `claim_id` on a charge is allowed | No |
| S4 | Inactive coverage | Patient 1004 has a coverage row. The eligibility check says `is_active = 0`. The visit still happens. The charges have an empty `claim_id`. | Inactive coverage is a real case, not an error | No |
| S5 | No-show | Patient 1005 has an appointment with status No-show. An eligibility check was run earlier. There is no encounter and no charges. | An appointment can exist with no encounter | No |
| S6 | Cancelled appointment | Patient 1006 has an appointment with status Cancelled. There is no encounter. | Same as S5, a different status | No |
| S7 | Preliminary, then final | Patient 1007 has one X-ray order. It has two results: one Preliminary and one Final. | One order can have many results | No |
| S8 | Rejected claim | Patient 1008 has a claim with status Rejected. `paid_amount` and `patient_owes` are empty. | A claim can be unpaid for a real reason | No |
| S9 | Claim in progress | Patient 1009 has a claim with status Submitted. `paid_amount` and `patient_owes` are empty. | An empty `paid_amount` is normal before the payer replies | No |
| S10 | Consult only | Patient 1010 has a visit with a 99204 charge only. There is no X-ray order and no prescription. The claim is Paid. | A visit does not need child rows in every table | No |
| S11 | Order not completed | Patient 1011 has an appointment and an encounter. The surgeon places an X-ray order. The patient leaves without the scan. The order stays Ordered. There is no result. Only the 99204 visit charge is billed. | An order can have zero results. No X-ray charge without a scan. | No |
| S12 | Prescription only | Patient 1012 has an encounter. There is no X-ray order. One prescription is Sent. The 99204 charge goes on a Paid claim. | A visit can have a prescription and no X-ray | No |

## Planted errors

Fill in the last column after the SQL is written. This is my answer key.

| ID | Error in plain words | Rule it breaks | Quality dimension | Row (fill in later) |
|---|---|---|---|---|
| E1 | A charge points to a claim that does not exist | Every foreign key has a parent | Consistency | charge: |
| E2 | A claim's `total_amount` does not equal the sum of its charges | Claim total equals sum of its charge amounts | Consistency | claim: |
| E3 | A result points to an order that does not exist | Every result links to an order | Consistency | result: |
| E4 | A claim has `paid_amount` bigger than `total_amount` | Paid should not be bigger than billed | Validity | claim: |
| E5 | A second patient (1011) has the same `mrn` as patient 1001 | MRN should be unique | Uniqueness | patient: |
| E6 | An appointment was created after the appointment date | Created date comes before the visit date | Validity (date logic) | appointment: |
| E7 | A coverage has an empty text value in `member_id` instead of a real ID | Required field must have a real value | Completeness | coverage: |
| E8 | A claim has the status "Pending", which is not in my list of allowed values | Status must be one of the allowed values | Validity | claim: |

Extra errors if I have time:
- A `cpt_code` that is not 5 characters.
- An encounter linked to an appointment that belongs to a different patient.

## Which rule from the data dictionary each one covers

| Rule in the data dictionary | Covered by |
|---|---|
| Every foreign key should match a parent row | E1, E3 |
| Claim total equals the sum of its charges | E2 |
| A walk-in can have an empty `appointment_id`. Any other empty key is an error. | S2 (should pass) |
| A self-pay charge can have an empty `claim_id` | S3 (should pass) |
| Every result links to an order | E3 |
| Paid should not be bigger than billed | E4 |

## Scenario coverage matrix

| ID | Scenario | Appointment | Coverage and check | Encounter | X-ray order | Result | Prescription | Charges | Claim |
|---|---|---|---|---|---|---|---|---|---|
| S1 | Full happy path | Arrived | Active | Finished | Completed | Final | Filled | 2 | Paid |
| S2 | Walk-in | None | Active, check has no appointment | Finished, no appointment | Completed | Final | Sent | 2 | Paid |
| S3 | Self-pay | Arrived | None | Finished | Completed | Final | None | 2, no claim | None |
| S4 | Inactive coverage | Arrived | Inactive | Finished | None | None | None | 1, no claim | None |
| S5 | No-show | No-show | Active (check run earlier) | None | None | None | None | None | None |
| S6 | Cancelled | Cancelled | None | None | None | None | None | None | None |
| S7 | Preliminary, then final | Arrived | Active | Finished | Completed | Preliminary, then Final | None | 2 | Paid |
| S8 | Rejected claim | Arrived | Active | Finished | None | None | None | 1 | Rejected |
| S9 | Claim in progress | Arrived | Active | Finished | None | None | None | 1 | Submitted |
| S10 | Consult only | Arrived | Active | Finished | None | None | None | 1 | Paid |
| S11 | Order not completed | Arrived | Active | Finished | Ordered | None | None | 1 | Paid |
| S12 | Prescription only | Arrived | Active | Finished | None | None | Sent | 1 | Paid |

## Open questions

- **O1. Walk-ins and eligibility checks.** In my dictionary, `eligibility_check.appointment_id` cannot be empty. But a walk-in has no appointment. A real clinic would still check coverage at check-in. Options: let the field be empty, or say walk-ins have no check row. I need to decide before I write the SQL.
- **O2. Rejected claims.** Should `paid_amount` be empty or 0 for a rejected claim? For now I will use empty.
