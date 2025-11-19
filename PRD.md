# Product Requirements Document (PRD)

> Duplicate into your repository's `docs/` folder. Keep narratives concise and traceable to measurable outcomes.

## 1. Metadata
- **Product / Feature Name**: PetPal Frontend, Pet Service, Activity Service
- **Author(s)**: GitHub Copilot
- **Date**: 2025-11-18
- **Revision**: v1.0
- **Status**: Draft
- **Related Docs**: README.md, backend/pet-service/README.md, backend/activity-service/README.md, infra/cosmos.bicep

## 2. Summary
PetPal needs a cohesive web experience that lets pet owners view, edit, and monitor pets alongside their activity history. This release aligns the React frontend with the Pet Service and Activity Service APIs so users can manage core pet data and log daily activities without touching underlying infrastructure. Success is measured by faster pet onboarding, richer engagement with activity timelines, and improved operational reliability of the services backing the UI.

## 3. Goals & Non-Goals
| Goals | Non-Goals |
| --- | --- |
| Unified dashboard for viewing and editing pet profiles plus recent activities. | Building or referencing the accessory service. |
| Reliable CRUD APIs for pets and activities with Cosmos DB persistence. | Native mobile apps; responsive web is sufficient. |
| Capture meaningful telemetry for pet creation and activity logging journeys. | Advanced analytics pipelines or ML-driven recommendations. |

## 4. Success Metrics
- Reduce average time to create a pet and first activity to <3 minutes (measured via frontend telemetry funnel tracked in Application Insights).
- Achieve P95 latency <500 ms for write operations across both services under emulator load tests (measured by load-test scripts owned by the backend team).
- Reach 70% engagement where daily-active users interact with both pets and activities modules (measured via frontend instrumentation dashboards maintained by product analytics).

## 5. Users & Personas
| Persona | Needs | Success Criteria |
| --- | --- | --- |
| Household Pet Owner | Quick overview of pet health, edit details, log walks/feeds. | Can add a new pet and log an activity without errors in <5 minutes. |
| Caretaker/Staff | Manage multiple pets, filter by status or date, ensure compliance logs. | Finds any pet or activity within 3 search/filter interactions. |
| Clinic/Trainer Partner | Record structured vet/training visits tied to specific pets. | Logs specialized activities with notes and timestamps that remain queryable by petId. |

## 6. Assumptions & Constraints
- Azure Cosmos DB (NoSQL API) is the authoritative store; emulator is used locally with same schema.
- Frontend auth relies on existing GitHub OIDC integration from workshop assets; no new auth features planned.
- Services run inside container apps; scale-out relies on stateless FastAPI instances with shared Cosmos throughput.
- Regulatory scope limited to demo data (no PII/PHI), so standard workshop security posture applies.

## 7. Specification by Example
| Scenario | Given | When | Then | Automated Test? |
| --- | --- | --- | --- | --- |
| Create pet | User is on dashboard | User submits valid pet form | Pet appears on card list with health metrics | `backend/pet-service/test_api.py` |
| Filter activities | Activities exist for multiple pets | User filters by pet and date | List shows only matching activities in reverse chronological order | Add test to `backend/activity-service` (TBD) |
| Log activity from pet view | Pet detail drawer open | User submits activity modal | Activity timeline refreshes with new entry and success toast | Cypress/UI smoke test (future) |

## 8. Requirements
### Functional
1. Frontend must list pets with summary metrics and allow inline edit/create aligned with Pet Service schema.
2. Frontend must surface an activity timeline per pet and allow logging new activities via Activity Service.
3. Pet Service must expose CRUD endpoints plus search/filter with pagination.
4. Activity Service must support create/read/delete plus filtering by pet, type, and date window.
5. Both services must expose `/health` endpoints that initialize Cosmos resources and report status.

### Non-Functional
- **Performance**: P95 <300 ms for reads, <500 ms for writes at workshop scale; monitor RU usage.
- **Security/Privacy**: Enforce HTTPS, store secrets in environment variables or managed identity, validate payloads server-side.
- **Observability**: Structured logs include request id, RU charge, and HTTP status; propagate `traceparent` header end-to-end.
- **Accessibility**: Frontend components meet WCAG 2.1 AA keyboard and contrast requirements.

## 9. UX & Flows
- Wireframes live in `solutions/challenge-06/docs/app-full.png`; they show the dashboard layout referenced above.
- Primary journey: dashboard → create pet → view pet detail → log activity → confirm toast → updated timeline.
- Secondary journey: use filters/search on dashboard to locate specific pets/activities, leveraging query parameters to the services.

## 10. Dependencies
- Internal: Pet Service (FastAPI), Activity Service (FastAPI), shared Cosmos DB account/emulator, infra scripts in `start.sh`.
- Third-party: Azure Cosmos DB Emulator, GitHub authentication for frontend, Application Insights for telemetry (optional).
- Launch blockers: Verified Cosmos throughput configuration and smoke tests covering create/edit/delete flows.

## 11. Rollout Plan
- **Phase 1 (MVP)**: CRUD for pets, activity logging basic flow, service health checks wired into start scripts.
- **Phase 2 (Beta)**: Add filters, telemetry dashboards, and automated UI smoke tests.
- **Phase 3 (GA)**: Harden accessibility and latency, document runbooks, finalize autoscale thresholds. Feature flag activity validation if cross-service dependency not ready.
- Provide lightweight enablement guide in `docs/` plus update workshop instructions.

## 12. Risks & Mitigations
| Risk | Impact | Likelihood | Mitigation |
| --- | --- | --- | --- |
| Cosmos RU throttling during demos | Slower writes, degraded UX | Medium | Enable retry-after handling on frontend, monitor diagnostics, pre-provision RU burst. |
| Cross-service validation causing cascading failures | Activity logging blocked when Pet Service unavailable | Medium | Implement cached pet metadata or circuit breaker; allow eventual consistency with warning banner. |
| Accessibility gaps in new UI | Users with assistive tech blocked | Low | Include accessibility review in GA checklist and run automated audits. |

## 13. Open Questions
- What auth mechanism should the production frontend use to call the services (API key vs. managed identity gateway)?
- Do we need offline caching for the dashboard to support intermittent connectivity scenarios?
- Should Activity Service enforce pet existence synchronously or accept writes and reconcile later?

## 14. Change Log
| Date | Author | Change |
| --- | --- | --- |
| 2025-11-18 | GitHub Copilot | Initial draft aligned to template for frontend + pet + activity scope. |
