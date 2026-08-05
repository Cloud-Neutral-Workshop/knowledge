---
title: "Incorporation Is Not the Finish Line: China, Hong Kong, and US LLC Real Cost Breakdown"
description: "An indie hacker's real-world research & breakdown of incorporation, compliance, hidden hurdles, and penalty risks across Mainland China, Hong Kong, and US Wyoming LLC."
slug: 2026-08-05-company-registration-real-costs-china-hong-kong-us-llc
lang: en
date: 2026-08-05T00:00:00Z
author: shenlan
tags:
  - company-incorporation
  - indie-hacker
  - compliance
  - global-business
category: essays
---

# Incorporation Is Not the Finish Line: China, Hong Kong, and US LLC Real Cost Breakdown

![Company Incorporation Cost Comparison](/assets/images/company_incorporation_costs.jpg)

> A real-world decision by an indie hacker after researching company formation across Mainland China, Hong Kong, and the United States.

Registering a company may only take a few days.

However, to actually launch a website, App, or AI product, collect payments, and sustain operations, true costs often begin *after* incorporation.

Obtaining a business license in Mainland China isn't hard, but you may face ICP filing, App filing, Value-Added Telecom licenses (ICP license), and AI compliance down the road. A Hong Kong company can be set up in hours, but you can't bypass company secretaries, registered addresses, bookkeeping, and annual audits. A US Wyoming LLC has low state government fees, but a single federal information reporting error can incur penalties starting at **$25,000 USD**.

Therefore, the real question to compare has never been:

> Where is incorporation cheapest?

Rather:

> Where can I establish a company to actually get my product up and running at a cost I can afford?

---

## Quick Comparison: Three Options at a Glance

| Item | Mainland China Company | Hong Kong Limited | Wyoming LLC |
|---|---|---|---|
| Formation Speed | Nationwide target within 4 working days; faster in some regions | Simple electronic application usually takes ~1 hour | State registration is fast; agent submission usually 1–2 working days |
| Formation Prerequisites | Physical/usable business address required; capital subscribed & paid within 5 years | Hong Kong registered address & company secretary required | In-state Registered Agent required |
| Website Launch | ICP filing required if hosted on Mainland China servers | Usually no ICP filing required | Usually no ICP filing required |
| App Launch | App filing required for internet info services targeting Mainland China | No equivalent universal filing | No equivalent universal filing |
| AI Products | May involve Generative AI registration/filing, algorithm filing, and content labeling | Dependent on business location & target user market | Dependent on target market & industry regulations |
| Annual Maintenance | Bookkeeping, tax filing, annual enterprise reporting, business license maintenance | Company secretary, registered address, Annual Return, Business Registration renewal, bookkeeping, audit, tax return | Registered Agent fee, state annual report, federal & potential state tax filings |
| Major Risk | Long launch pipeline, complex business classification logic | Ongoing secretary, audit, and tax costs even with zero revenue | Heavy penalties for missing/incomplete federal info filings |
| Best Suited For | Primarily serving Mainland China customers | Asian regional business, cross-border trade, and established revenue | Global SaaS, software, API, and indie hackers |

Company formation only means a "legal entity has been created", not that your website, App, payment gateway, and AI features are ready to operate.

---

## 1. Is a Mainland China Company Really Cheap?

### 1. The business license is easy; the downstream chain is the real cost

Starting a business in Mainland China has become highly digitized. Market regulation authorities previously set goals to compress business setup time to **within 4 working days**, and simple entity registration in many cities can be completed even faster.

However, starting from the revised *Company Law* implemented in 2024 and subsequent registration rules, shareholder subscribed capital contributions for newly established limited liability companies must, in principle, be **fully paid up within 5 years** from company formation.

This means you can no longer arbitrarily fill in a registered capital figure far beyond your actual financial capability. While it doesn't need to arrive in the bank account on day one, it becomes a mandatory shareholder obligation to fulfill within five years.

For ordinary software entrepreneurs, the business license itself is rarely the biggest expense. The real recurring costs include:

- Registered company address;
- Corporate bank account setup & maintenance;
- Bookkeeping and tax filings;
- Annual enterprise credit reporting;
- Filings or licenses required for websites, Apps, and specific business categories;
- Staffing, social security (Shebao), and data security compliance systems.

### 2. ICP Filing: Getting a business license doesn't grant it automatically

"ICP", often conflated in discussions, actually splits into at least two distinct categories.

**Category 1: Non-Commercial ICP Filing (ICP 备案).** If a website is hosted on servers inside Mainland China and provides non-commercial internet information services via domain name or IP address, an ICP filing is generally required. Both individuals and companies can serve as the filing entity. The government filing process itself is not a fee-based license.

Upon receiving complete materials, the Provincial Communications Administration is legally required to complete the filing or state reasons for rejection within **20 working days**. In practice, documentation must also undergo preliminary verification by cloud service providers or network access providers, so extra buffer time is usually needed.

Required materials typically include: real-name verified domain, Mainland servers/access resources, entity ID/license documents, website administrator details, contact info, and identity verification. Special content domains (e.g., news, education, medical) require pre-approval documents.

Thus, ICP filing is not just "buying a domain and filling out a form"—it is a compliance binding between the domain name, server location, legal entity, and actual site content.

### 3. "ICP Service Filing" usually refers to the ICP License

Strictly speaking, there is no generic administrative item called "ICP Service Filing". What people casually call "Commercial ICP" usually refers to the **Value-Added Telecommunications Business License for Information Services (Limited to Internet Information Services)**, commonly known as an ICP License. It is not an upgraded version of standard ICP filing, but an administrative approval license.

If a business actually falls under commercial internet information services, the applicant must be an legally established company satisfying strict requirements on capital, personnel, long-term service capability, technical infrastructure, facilities, and network security. Under current telecom licensing regulations:

- For intra-province/regional operations, the minimum registered capital is generally **1 million RMB**;
- For cross-province or nationwide operations, the minimum registered capital is generally **10 million RMB**;
- Required submissions include shareholding structures, domain names, website/App architecture, business plans, and security safeguards;
- Some local application guides explicitly require proof of staff employment and social security contributions;
- Upon formal acceptance, the review period can take up to **60 days**.

The claim that "the company must be 100% domestic-funded" is also an oversimplification. Foreign investment is not legally prohibited across all value-added telecom services, but it must follow the foreign-invested telecom enterprise approval path, involving extra conditions regarding foreign equity caps and foreign investor track records. Under general current rules, foreign equity in value-added telecom businesses is typically capped at **50%**, making approval significantly harder than for standard domestic enterprises.

For individual indie hackers, this means:

> Registering a standard Mainland software company is easy, but directly applying for a commercial ICP License is a completely different ballgame from a "few hundred RMB business license".

Furthermore, one shouldn't simply assume "if an App charges money, it definitely requires an ICP License". Whether a service falls under licensing mandates depends on specific analysis of payment recipients, service content, transaction models, and business classifications.

### 4. App Filing: Website filing does not cover your App automatically

App publishers offering internet information services within China must undergo App Filing (APP 备案). This framework covers not only traditional mobile Apps, but also distribution formats like **Mini-Programs and Quick Apps**.

App filing is typically submitted via network access providers or application distribution platforms. Provincial Communications Administrations must complete processing within **20 working days** upon receiving complete materials. Once completed, publishers must:

- Display the App filing number prominently within the App;
- Timely update filings when entity, domain, or service scope changes;
- Process filing cancellation when operations cease;
- Co-operate with app stores and access providers for periodic verification.

Consequently, a Mainland App project may simultaneously involve: business license, website ICP filing, App filing, industry-specific operational licenses, privacy policies, and personal information protection mechanisms. These are separate compliance items and cannot replace one another.

### 5. Software Copyright: Not a pre-launch blocker; individuals can apply too

Software copyright registration (软著) is often marketed by agents as a "mandatory item for incorporation," which is inaccurate. Once software is completed, either an individual or a company can apply as the copyright holder. It is generally not a statutory prerequisite for launching an ordinary website or App, nor must every indie hacker apply immediately.

It is better suited for: establishing clear software ownership; serving as prima facie evidence in infringement disputes; enterprise procurement, bidding, or qualification applications; app store audits or government project applications; and transferring IP from an individual to a company entity.

Applications require software specification documentation and a portion of source code. Regulations prescribe that the Copyright Protection Center of China should complete review within **60 days** of acceptance; if material corrections are requested, the total timeline extends further.

A rational sequence is:

> First validate whether the product is worth long-term operation, then pursue copyright filings based on IP protection and commercial needs—rather than buying a full bundle of agent services up front just to make the company look complete.

---

## 2. Calling LLM APIs: Does It Require Filing?

This is one of the most misunderstood questions surrounding domestic AI products in China. The answer is neither a simple "yes" nor "no".

### 1. Internal API calls do not automatically trigger public service filings

The *Interim Measures for the Management of Generative Artificial Intelligence Services* primarily apply to services that leverage generative AI technology to **provide text, image, audio, or video generation services to the public within Mainland China**.

Internal corporate R&D, internal office workflows, scientific research, or tools not offered to the Mainland public do not directly fall under these public service rules. Therefore:

- Using LLMs internally to summarize documents;
- Calling APIs for testing during development;
- Internal enterprise tools unavailable to the public;

cannot be equated to "mandatorily requiring Generative AI Service Filing".

### 2. Calling registered models for public features may require "Application / Feature Registration"

By the end of June 2026, the Cyberspace Administration of China (CAC) had published that: **988 generative AI services completed formal service filing; 598 applications or features directly calling registered model capabilities completed application registration.** Official guidelines clarify that applications or features directly utilizing registered model capabilities via APIs or other integration methods undergo application/feature registration managed by local cyberspace authorities. Released apps must also publicly display the name, filing number, or release ID of the underlying model used.

This can be understood as:

**Scenario A: Directly calling an already-registered foundation model** (e.g., calling a registered domestic model to provide AI writing, image generation, or assistant features to the Mainland public). Compliance evaluation for such apps focuses on: completing local app/feature registration, disclosing model names and filing numbers, implementing generated content watermarking/labeling, and establishing content safety, complaint handling, and user agreement mechanisms.

**Scenario B: Training, fine-tuning, or hosting your own model to offer public services.** If a company acts as the actual generative AI service provider—especially if the service possesses public opinion attributes or social mobilization capabilities—compliance responsibilities increase dramatically, entering the scope of full Generative AI Service Filing, security assessment, and algorithm filing.

### 3. AI Content Watermarking & Labeling required since late 2025

Starting September 1, 2025, qualifying generation/synthesis services must process explicit and implicit watermarking/labeling according to regulations. For instance: text interfaces must display AI-generated prompts; images and videos must include clear visual badges; file metadata must embed generation attributes, service provider info, or content IDs; and app stores may verify watermarking compliance documentation during App review.

This means AI compliance costs are not just "filling out a registration form", but directly permeate product UI design and technical architecture:

> UI prompts required, exported files watermarked, metadata written, logs and user terms fully aligned.

---

## 3. Does Using Algorithms Mandate Algorithm Filing?

Not necessarily.

The regulatory scope of algorithm recommendations covers generation/synthesis, personalized pushing, sorting/curating, search filtering, and dispatch decision algorithms. However, mandatory algorithm filing specifically targets algorithm recommendation service providers **with public opinion attributes or social mobilization capabilities**.

Eligible service providers must submit filings within **10 working days** of launching services. Upon receiving complete documentation, cyberspace authorities complete review within **30 working days**.

Therefore:

- A local utility tool;
- An internal Agent not open to the public;
- A simple productivity app without content distribution or social mobilization attributes;

should not be blindly assumed to require algorithm filing. However, if your product involves public content generation, information distribution, trending leaderboards, personalized recommendations, or large-scale user dissemination, professional algorithm compliance assessment before launch is essential.

---

## 4. Hong Kong Is International, But Costs Recur Every Year

Hong Kong company formation is indeed fast. Simple private companies limited by shares submitted electronically—where company names require no extra review and documents pass automated checks—can obtain an electronic Certificate of Incorporation and Business Registration Certificate in roughly **1 hour**.

From April 1, 2026 to March 31, 2027:

- Companies Registry electronic incorporation fee: **HK$1,545**;
- One-year Business Registration fee & levy: **HK$2,350**;
- Total baseline government formation cost: **HK$3,895**.

It looks inexpensive initially. However, the real cost of a Hong Kong company comes from ongoing maintenance.

### 1. Company Secretary is mandatory

Every Hong Kong private limited company must have at least one Company Secretary. If an individual, they must ordinarily reside in Hong Kong; if a corporate entity, it must maintain a registered office or place of business in Hong Kong. The sole director of a company cannot concurrently serve as company secretary.

Market pricing for corporate secretarial services starts around **HK$1,500/year** for basic packages; packages including registered address, statutory registers maintenance, change filings, and full compliance support easily reach several thousand to tens of thousands of HKD annually.

### 2. Annual Business Registration renewal and Annual Return

Private companies must file an Annual Return (Form NAR1) within **42 days** after the anniversary of incorporation. The government fee for timely filing is **HK$105**; late filings escalate steeply up to **HK$3,480** for delays exceeding 9 months. Additionally, the Business Registration Certificate must be renewed annually (HK$2,350 for 2026–2027).

### 3. Hong Kong companies are NOT "Zero-Tax-Filing" entities

Except in rare cases formally registered as dormant companies, Hong Kong companies are legally required to prepare financial statements and undergo independent statutory audits. Small private companies qualify for simplified reporting standards, but "simplified reporting" does not mean audit exemption.

For small, low-transaction entities, basic market audit quotes start around **HK$5,000**; as transaction volumes, revenue, bank accounts, cross-border complexity, and document completeness increase, combined bookkeeping, audit, and tax services often reach **HK$15,000–HK$30,000+ per year**. This part has no government fixed price and depends entirely on accounting complexity.

Hong Kong Profits Tax operates on a territorial source principle—meaning income is not automatically tax-free simply because it is earned by a Hong Kong company. Qualified corporations enjoy a two-tiered profits tax rate: **8.25%** on the first HK$2 million of assessable profits, and **16.5%** on profits thereafter. Determining whether profits arise in or derive from Hong Kong depends on factual analysis of operations and transaction locations.

Thus, the defining characteristic of a Hong Kong company is not slow setup, but:

> Extremely fast formation, but fixed recurring maintenance costs starting from year one.

It is best suited for businesses with existing cross-border revenue, Asian clients, or explicit banking and trading requirements—not for wrapping a zero-revenue personal side project in an "international entity shell."

---

## 5. US LLC Is Free? The Real Danger Lies in Info Reporting Errors

Taking Wyoming LLC as an example, effective July 2026, state fees stand at:

- Articles of Organization filing fee: **US$100**;
- Annual Report license tax: Minimum **US$60**, or calculated based on assets located in Wyoming, whichever is higher.

Looking strictly at state government fees, it is very low. Foreign individuals can hold a single-member LLC, with no requirement for shareholders to be US citizens or residents. However, "simple registration" does not equal "simple taxes".

### 1. An LLC does not automatically mean zero tax

A single-member LLC is treated by default as a disregarded entity separate from its owner for federal tax purposes. However, ultimate tax liability depends on: owner tax residency, income sources, whether engaged in a US Trade or Business (USTB), whether generating Effectively Connected Income (ECI), and state/sales tax obligations.

Non-US residents are generally liable for US tax primarily on US-source income and ECI. Thus, one cannot assume fixed zero tax simply because a foreigner holds the LLC.

### 2. The critical trap to watch: IRS Form 5472

A foreign-owned US disregarded entity involved in reportable transactions with related parties must file **Form 5472** along with a pro forma Form 1120. Owner capital contributions, withdrawals, or company payments made on behalf of the owner can all constitute reportable related-party transactions.

Failure to file Form 5472 on time or filing substantially incomplete information carries a baseline statutory penalty of **US$25,000**. Continuous failure to file after IRS notification incurs additional compounding penalties.

This is the single biggest contrast of a US LLC:

> State filing fee is only $100, but missing one federal information reporting deadline can cost $25,000 in penalties.

### 3. Formation does not mean EIN and bank accounts are complete

Applicants outside the US generally cannot use the IRS online EIN tool directly, as online applications require a principal business location in the US and a responsible party with an SSN or ITIN. Foreign applicants must apply via phone, fax, or mail. IRS guidelines state fax applications ideally take **~4 working days**, while mail takes **~4 weeks**, subject to seasonal processing backlogs.

Therefore, the actual execution pipeline is:

> LLC Formation → EIN → Bank/Financial Account Review → Payment Gateway Approval → Start Collecting Payments.

Holding a state-stamped PDF does not instantly unlock global payment acceptance.

*Note on BOI Reporting:* Many older tutorials still instruct new US entities to submit Beneficial Ownership Information (BOI) reports to FinCEN. However, following FinCEN's rule adjustments in March 2025, newly formed US domestic entities are currently exempt from BOI reporting requirements.

---

## 6. Northwest vs. doola: Choosing Between Cheap and "Able to Launch"

I initially prioritized Northwest Registered Agent.

**Northwest:** Base formation service is US$39 + state fees; includes the first year of Registered Agent; subsequent Registered Agent official price is US$125/year; provides business address and mail scanning. From a price, privacy, and core registration standpoint, its cost-effectiveness is outstanding.

However, it suits founders who: are comfortable handling EIN applications and tax filings themselves, hiring their own CPA, maintaining state annual reports, having payment methods that pass seamlessly, and wanting to minimize fixed annual costs.

I attempted payment using several international credit/debit cards, but transactions repeatedly failed payment risk checks. This doesn’t mean Northwest rejects international clients entirely, but under my specific combination of cards, region, and risk control filters, that path stalled.

**doola:** Starter plan currently costs US$297/year + state fees, covering LLC registration, EIN application assistance, US business address, Registered Agent, and US bank account setup guidance. doola states LLC filings are submitted within 1–2 business days, and accepts global debit/credit cards and bank transfers seamlessly.

Note: Starter does *not* include complete annual federal and state tax filings. The Tax and Compliance plan, which includes full tax filings, consultations, and comprehensive compliance, currently costs **US$1,999/year + state fees**.

So doola isn't "$297 solves everything forever". What it sells is an integrated onboarding pathway, EIN, address, and service stack tailored for non-US founders. On a standalone item basis, it is noticeably pricier than Northwest.

Yet my ultimate choice of doola came down to a pragmatic reality: a 20% discount code was available, the application form progressed smoothly, international payment succeeded, and the incorporation process officially kicked off.

When all is said and done, discounts are just catalysts. The decisive factor was simply:

> **The payment worked. 😄**

In early-stage entrepreneurship, a theoretically optimal plan that fails at checkout has an actual value of zero.

---

## Conclusion: Truly Cheap Is Not Where Registration Fees Are Lowest

After researching all three company models, my perspective on "cheap" fundamentally shifted.

- **Mainland China Company**: Cheap to incorporate, convenient for local domestic operations, but websites, Apps, and AI products must navigate multiple layers of filings, licensing, and technical compliance.
- **Hong Kong Company**: Lightning-fast incorporation, mature international business infrastructure, but company secretary, address, business registration, audit, and tax accounting form solid recurring annual expenses.
- **US LLC**: State formation and annual fees can be minimal, with unrivaled access to global software ecosystems, but tax rules and information reporting cannot be ignored—where error costs can dwarf initial incorporation fees.

Ultimately, I stopped searching for the "single best company structure in the world." I chose a pragmatic starting point: solo-friendly; capable of supporting software, App, SaaS, and API business; connected to global developer and payment infrastructure; payable with my existing cards; and paired with a commitment to learn and execute ongoing compliance.

For indie hackers, incorporating a company isn't proof of entrepreneurial success. It's just new infrastructure.

Completion of registration is merely `create`.

What follows is: `configure`, `deploy`, `operate`, `audit`, and `maintain`.

The truly expensive part is never building the company up. It's keeping it legally compliant, alive, and eventually generating real revenue.

---

*Disclaimer: Data and regulatory information verified as of August 5, 2026. This article reflects personal entrepreneurial notes and general information sharing, and does not constitute legal, financial, or tax advice for Mainland China, Hong Kong, or the United States. Whether your specific business requires an ICP License, Generative AI Registration, Algorithm Filing, or US Tax Reporting must be independently evaluated based on product nature, user demographics, revenue sources, and equity structures.*

**Interactive Question:** How much did you spend incorporating your company? What hidden traps did you encounter? Share your experience in the comments! The top 3 most-liked comments will receive a complimentary PDF copy of the *Three-Region Company Annual Cost Breakdown & Checklist*.
