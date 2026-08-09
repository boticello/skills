---
name: enterprise-capability-maturity-model
description: Load when asked to create, critique, or reframe a maturity model for an enterprise architecture, data, platform, security, or AI topic such as data fabric, data mesh, platform engineering, zero trust, or AI operating model, especially when the model must include system dynamics, dependencies, leverage points, and topic-fit judgment.
---

# Overview

Use this skill to produce maturity models for enterprise architecture and adjacent domains without blindly accepting the user's topic label. Many EA topics are not stable capability objects; they are often architectural patterns, slogans, target states, or vendor-shaped bundles. The skill must first decide what can genuinely mature: a capability system, operating model, governance mechanism, platform discipline, or architecture practice.

This skill keeps the maturity-model structure but adds system logic: dependencies, enabling conditions, bottlenecks, reinforcing loops, balancing loops, and sequencing. It is designed for topics such as data fabric, data mesh, platform engineering, zero trust, enterprise AI, knowledge management, integration, observability, and digital operating models.

## Workflow

- [ ] Step 1: Classify the topic before modelling it.
  - Put the topic in one primary class:
    - capability
    - architecture pattern
    - operating model
    - governance model
    - platform discipline
    - delivery practice
    - target outcome
    - market label / vendor category
  - If the topic spans several classes, state the dominant one and the secondary ones.

- [ ] Step 2: Decide the modelling object.
  - Ask: what exactly is becoming more mature?
  - Prefer objects with agency and evidence, such as:
    - federated data governance capability
    - internal platform product operating model
    - policy-driven access control capability
    - metadata-driven integration capability
    - enterprise AI lifecycle governance
  - Reject objects phrased only as aspirations, trends, or umbrella labels unless reframed.

- [ ] Step 3: Make a framing verdict.
  - Choose one:
    - suitable as-is
    - suitable after reframing to a more specific capability
    - better treated as a subdomain of a broader operating model
    - better analysed with another frame
  - If another frame is better, pick one default:
    - operating model assessment
    - capability map
    - architecture review
    - readiness assessment
    - governance diagnostic
    - adoption model
    - reference architecture analysis

- [ ] Step 4: Set the enterprise boundary.
  - Define:
    - scope: enterprise, business unit, platform group, domain team, product line, function
    - layer: strategy, governance, architecture, engineering, operations, adoption
    - assessed unit: central team, federated model, platform, or whole organization
  - State what the model excludes, especially adjacent concerns that would blur the result.

- [ ] Step 5: Select dimensions.
  - Use 5 to 7 dimensions.
  - In EA contexts, prefer this candidate set and prune as needed:
    - strategy and business alignment
    - governance and decision rights
    - architecture and standards
    - platform and tooling
    - delivery model and workflows
    - roles, skills, and incentives
    - measurement, controls, and learning
    - adoption and business embedment
  - Do not include both overlapping dimensions and cosmetic renamings of the same idea.

- [ ] Step 6: Define stages.
  - Use 5 stages by default:
    1. Fragmented
    2. Piloting
    3. Standardized
    4. Federated
    5. Adaptive
  - Rename only when the domain has a clearer progression.
  - Make stages cumulative but not perfectly uniform across dimensions.
  - Each stage must be evidenced by operating reality, not ambition.

- [ ] Step 7: Explain the journey.
  - For each stage transition, identify:
    - what changes structurally
    - what new capability becomes institutionalized
    - what dependency must exist first
    - what usually breaks
    - what management action or architectural move unlocks progress
  - Emphasize sequencing rather than just descriptions.

- [ ] Step 8: Add system dynamics.
  - Identify:
    - leverage points: small interventions with cross-dimensional effects
    - dependencies: upstream capabilities required for scale
    - reinforcing loops: improvements that compound
    - balancing loops: forces that slow or reverse progress
    - bottlenecks: the limiting constraint
    - path dependencies: prior architectural or organizational choices that constrain future options

- [ ] Step 9: Stress-test the maturity logic.
  - Ask:
    - is the model privileging centralization by default?
    - is it confusing technology rollout with adoption or governance maturity?
    - is the "highest" stage genuinely best for all contexts?
    - is the model describing an architecture pattern when it should describe an operating capability?
  - Correct for those biases before finalizing.

## Key Rules

- Model the maturity of enterprise capabilities and institutional mechanisms, not the maturity of buzzwords.
- In EA domains, architecture, governance, and operating model are separate but coupled; do not collapse them into one dimension.
- Distinguish design-time maturity from run-time maturity. A well-documented architecture is not the same as a well-operated capability.
- Distinguish local excellence from enterprise scalability. A strong pilot does not imply federated maturity.
- Treat standards, metadata, identity, policy, ownership, and funding as enabling infrastructure, not side notes.
- Make dependencies directional where possible.
- Name the bottleneck explicitly. Most enterprise systems are constrained by ownership, incentives, funding model, identity, or metadata quality before they are constrained by tooling.
- Do not assume the final stage is maximum automation or maximum decentralization. Advanced states are context-shaped.
- If the user's term is fashionable or contested, separate durable capability needs from market vocabulary.
- If the best analysis is not a maturity model, say so and switch frame.

## EA Gotchas

- "Data fabric" is often too ambiguous to model directly; it may refer to metadata, integration, policy enforcement, semantic interoperability, or vendor tooling.
- "Data mesh" is often mis-modelled as a technology architecture when it is mainly an operating model and governance pattern.
- "Platform engineering" is often mis-modelled as tooling maturity when the real object is productized internal platform capability plus adoption.
- "Zero trust" is often mis-modelled as a security tool stack when the real object is continuous policy-based access and verification capability.
- "AI operating model" is often too broad unless scoped to lifecycle governance, model delivery, business embedment, or risk controls.
- Enterprise architecture topics commonly have multiple valid advanced states. A heavily regulated centralized enterprise and a digital-native federated enterprise may both be mature in different ways.
- Maturity is often lumpy. Governance may outpace tooling, or platform capability may outpace business adoption.
- The wrong abstraction level creates fake precision. Reframe early rather than building a polished but invalid model.

## Topic Reframing Patterns

When the topic is too vague, use one of these reframing moves:

- Pattern to capability:
  - "data fabric" -> metadata-driven, policy-aware data integration and access capability
  - "zero trust" -> continuous identity, policy, and access enforcement capability

- Label to operating model:
  - "data mesh" -> federated data product operating model with domain ownership and platform enablement
  - "platform engineering" -> internal platform product operating model and adoption capability

- Broad concept to narrower assessable object:
  - "enterprise AI" -> AI lifecycle governance and delivery capability
  - "observability" -> production telemetry, diagnosis, and reliability response capability

- Narrow concept to broader system:
  - "MDM" -> enterprise information management and control capability, if the user's real concern is wider than master data alone

## Output Format

Use this structure exactly.

### 1. Topic Fit
- Verdict: suitable as-is / reframe / nest in broader concept / use another frame
- Topic class:
- Why:
  - 3 to 5 bullets
- Recommended object of maturity:
- Better frame if maturity model is not primary:

### 2. Framing
- Enterprise scope:
- Assessed unit:
- In-scope layers:
- Out-of-scope concerns:
- What maturity means here:

### 3. Dimensions
Use this table:

| Dimension | What matures | Observable evidence | Dependencies | Leverage points |
|---|---|---|---|---|

### 4. Stages
Use this table:

| Stage | Enterprise pattern | Observable traits | Failure modes | Unlocks |
|---|---|---|---|---|

### 5. Dimension Journeys
For each dimension, provide:
- early-state condition
- transition markers
- advanced-state condition
- typical stall points
- leading indicators

### 6. System Dynamics
Include:
- leverage points
- enabling conditions
- reinforcing loops
- balancing loops
- bottlenecks
- sequencing implications

### 7. Critique
Include:
- why this topic is or is not a good maturity object
- what this model oversimplifies
- where the abstraction level could still be wrong
- how context changes the meaning of "advanced"

## Defaults by Topic

Use these defaults unless the user's wording clearly points elsewhere:

- Data fabric:
  - Default object: metadata-driven, policy-aware data integration and access capability
  - Likely dimensions: metadata, interoperability, policy enforcement, governance, platform enablement, adoption

- Data mesh:
  - Default object: federated data product operating model
  - Likely dimensions: domain ownership, platform services, governance federation, standards, incentives, product thinking

- Platform engineering:
  - Default object: internal platform product capability
  - Likely dimensions: platform product management, self-service workflows, golden paths, telemetry, adoption, funding and ownership

- Zero trust:
  - Default object: continuous identity- and policy-centric access control capability
  - Likely dimensions: identity, policy, enforcement points, telemetry, governance, user friction, exception handling

- AI operating model:
  - Default object: enterprise AI lifecycle governance and delivery capability
  - Likely dimensions: intake and prioritization, data/model lifecycle, controls, deployment, monitoring, accountability, business adoption

## Validation

Before finalizing, check:
1. Did I classify the topic before modelling it?
2. Did I reframe the topic if it was at the wrong conceptual level?
3. Are architecture, governance, platform, and operating model kept distinct where needed?
4. Are stages based on evidence, not aspirations?
5. Did I make the journey depend on enablers, dependencies, and bottlenecks?
6. Did I include reinforcing and balancing loops?
7. Did I avoid implying one universal end-state?
8. Would this still be credible to an enterprise architect, operating model lead, and platform leader reading the same output?
