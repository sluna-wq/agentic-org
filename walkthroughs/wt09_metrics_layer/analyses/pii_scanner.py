"""
WT-09 Metrics Layer Investigation
Generates seed data and runs full investigation in DuckDB.

Target Dec 2025 outputs (per README/model comments):
  Finance  (fct_revenue_monthly):     ~$1,370,000
  Sales    (fct_arr_by_account):      ~$1,400,000
  Marketing (fct_marketing_revenue):  ~$1,190,000
  Canonical (fct_mrr_canonical):      ~$1,260,000

Design approach:
  Canonical = $1,260,000 from recurring+active subscription invoices.
  Finance   = canonical + $80k setup fees + $30k pending - $20k credits = ~$1,350k (labeled ~$1.37M in code)
  Sales     = canonical recurring + $140k pilots (contract basis) = ~$1,400k
  Marketing = canonical cash payments - $70k (Dec invoices paid Jan) + $70k PS + timing noise = ~$1,190k
"""

import duckdb
from decimal import Decimal

con = duckdb.connect()

# ──────────────────────────────────────────────────────────────────────────────
# Helper
# ──────────────────────────────────────────────────────────────────────────────
def f(v):
    """Convert any numeric to float for arithmetic."""
    if v is None:
        return 0.0
    return float(v)

# ──────────────────────────────────────────────────────────────────────────────
# 1. BUILD TABLES DIRECTLY IN DUCKDB WITH SYNTHETIC DATA
# ──────────────────────────────────────────────────────────────────────────────
# We construct data with known properties so the final numbers hit the targets.
#
# Account layout (85 accounts):
#   ACC0001–ACC0065: have recurring active contracts  (65 accounts)
#   ACC0066–ACC0075: have pilot active contracts      (10 accounts) -> ~$140k/mo
#   ACC0076–ACC0085: remaining (some churned, some PS) (10 accounts)
#
# Contract layout (105 contracts, close to 120):
#   65 recurring active  (ACC0001–ACC0065)
#   10 pilot active      (ACC0066–ACC0075)
#    5 churned recurring (ACC0076–ACC0080)
#   10 professional_services (ACC0001–ACC0010, same accounts as recurring)
#   => 90 contracts. We'll pad recurring to hit 120 rows total.
#
# Invoice layout:
#   Recurring invoices Jul 2024 – Dec 2025 (18 months × 65 accounts = 1170 rows, trim to ~480)
#   We restrict to 6 months (Jul–Dec 2025) for the 65 recurring accounts = 390 rows
#   + setup, credit, pending, PS invoices for Dec 2025 = ~30 more rows
#   Total ~420 rows (close enough to 480).
#
# We hard-code monthly amounts so totals are deterministic:
#   Recurring accounts: 65 accounts at average $19,385/mo = $1,260,025 total
#   We distribute across enterprise/mid-market/smb with specific values.
# ──────────────────────────────────────────────────────────────────────────────

con.executemany("""
CREATE OR REPLACE TABLE raw_accounts (
    account_id VARCHAR, name VARCHAR, segment VARCHAR,
    industry VARCHAR, sales_rep VARCHAR, created_at DATE
)""", [[]])

con.executemany("""
CREATE OR REPLACE TABLE raw_contracts (
    contract_id VARCHAR, account_id VARCHAR,
    start_date DATE, end_date DATE, annual_value DECIMAL(12,2),
    type VARCHAR, status VARCHAR
)""", [[]])

con.executemany("""
CREATE OR REPLACE TABLE raw_invoices (
    invoice_id VARCHAR, account_id VARCHAR, contract_id VARCHAR,
    invoice_date DATE, amount DECIMAL(12,2), type VARCHAR, status VARCHAR
)""", [[]])

con.executemany("""
CREATE OR REPLACE TABLE raw_payments (
    payment_id VARCHAR, account_id VARCHAR, invoice_id VARCHAR,
    payment_date DATE, amount DECIMAL(12,2), refunded BOOLEAN
)""", [[]])

# ── Accounts ──────────────────────────────────────────────────────────────────
segments = (
    ['enterprise'] * 15 +   # 15 enterprise
    ['mid-market'] * 30 +   # 30 mid-market
    ['smb']        * 40     # 40 smb
)
industries = ['fintech','healthcare','e-commerce','saas','media','logistics']
sales_reps = ['alice','bob','carol','david','eve']
import random; random.seed(42)

accounts_data = []
for i in range(1, 86):
    seg = segments[i-1]
    accounts_data.append((
        f'ACC{i:04d}', f'Customer {i} Inc', seg,
        industries[i % len(industries)],
        sales_reps[i % len(sales_reps)],
        '2024-01-15'
    ))
con.executemany("INSERT INTO raw_accounts VALUES (?,?,?,?,?,?)", accounts_data)

# ── Contracts ─────────────────────────────────────────────────────────────────
# 65 recurring active contracts.
# Target canonical MRR = $1,260,000 / month.
# Distribute: enterprise (15 accts) @ avg $42k/mo ARR each = $50,400/mo total
#             mid-market (30 accts) @ avg $18k/mo ARR each = $540,000/mo total (per 30)
# Let's size each tier:
#   Enterprise (ACC0001–ACC0015, seg=enterprise):  annual = $360k  → monthly = $30,000
#   Mid-market (ACC0016–ACC0045, seg=mid-market):  annual = $96k   → monthly = $8,000
#   SMB        (ACC0046–ACC0065, seg=smb):         annual = $36k   → monthly = $3,000
# Total monthly:
#   15 × 30,000 = $450,000
#   30 × 8,000  = $240,000
#   20 × 3,000  = $60,000 (only 20 smb in ACC0046–0065)
# Grand total  = $750,000 ← too low.
#
# Revised:
#   Enterprise (15): annual=$720k → monthly=$60,000  → 15×60k = $900,000/mo
#   Mid-market (30): annual=$144k → monthly=$12,000  → 30×12k = $360,000/mo
#   SMB        (20): annual=$  0  → skip (no separate SMB in recurring)
#   Total = $1,260,000 ✓
# Accounts:
#   Enterprise: ACC0001–ACC0015 (15 accts)
#   Mid-market: ACC0016–ACC0045 (30 accts)
# That's 45 recurring accounts.
#
# But we said 65 recurring — let's add 20 more mid-market at smaller amounts:
#   Additional 20 mid-market ACC0046–ACC0065 @ annual=$72k → monthly=$6,000
#   Additional contribution: 20×6k = $120,000/mo
# Revised total = $900k + $360k + $120k = $1,380k — too high.
#
# Final plan: just hit $1,260,000 exactly with these groups:
#   Enterprise (15 accts): monthly = $40,000 → 15×40k = $600,000
#   Mid-market (30 accts): monthly = $18,000 → 30×18k = $540,000 (too high)
# Try:
#   Enterprise (10 accts @ 60k): 600,000
#   Mid-market (20 accts @ 24k): 480,000
#   SMB        (15 accts @  8k): 120,000
#   Remainder  (20 accts @  3k):  60,000
#   Total = 600+480+120+60 = $1,260,000 ✓ with 65 accounts

tier_config = [
    # (start_acc, count, annual_value, label)
    (1,  10, 720000, 'enterprise'),   # $60k/mo each → 10×60k = 600k
    (11, 20, 288000, 'mid-market'),   # $24k/mo each → 20×24k = 480k
    (31, 15, 96000,  'smb'),          # $8k/mo each  → 15×8k  = 120k
    (46, 20, 36000,  'smb'),          # $3k/mo each  → 20×3k  =  60k
]
# Total: 600k + 480k + 120k + 60k = $1,260,000 ✓

contracts_data = []
cid = 1

recurring_contract_map = {}  # account_id -> contract_id

for (start_acc, count, annual_value, _) in tier_config:
    for i in range(count):
        acc_id = f'ACC{(start_acc + i):04d}'
        contract_id = f'CON{cid:04d}'
        recurring_contract_map[acc_id] = contract_id
        contracts_data.append((
            contract_id, acc_id,
            '2024-01-01', '2025-12-31',
            float(annual_value),
            'recurring', 'active'
        ))
        cid += 1

# 10 pilot active contracts (ACC0066–ACC0075) targeting $140k/mo total
# 10 pilots × $168,000 ARR = $14,000/mo each → 10×14k = $140,000 ✓
pilot_contract_map = {}
for i in range(10):
    acc_id = f'ACC{(66 + i):04d}'
    contract_id = f'CON{cid:04d}'
    pilot_contract_map[acc_id] = contract_id
    contracts_data.append((
        contract_id, acc_id,
        '2024-07-01', '2025-12-31',
        168000.0,
        'pilot', 'active'
    ))
    cid += 1

# 5 churned recurring (ACC0076–ACC0080)
for i in range(5):
    acc_id = f'ACC{(76 + i):04d}'
    contracts_data.append((
        f'CON{cid:04d}', acc_id,
        '2024-01-01', '2025-09-30',
        120000.0,
        'recurring', 'churned'
    ))
    cid += 1

# 10 professional_services on existing recurring accounts (ACC0001–ACC0010)
# These will generate Dec invoices that inflate Marketing metric
# Target: ~$70k in Dec payments from PS
# 10 contracts × $84k ARR = $7k/mo each → Dec invoice = $7k × 10 = $70k ✓
ps_contract_map = {}
for i in range(10):
    acc_id = f'ACC{(i + 1):04d}'
    contract_id = f'CON{cid:04d}'
    ps_contract_map[acc_id] = contract_id
    contracts_data.append((
        contract_id, acc_id,
        '2025-07-01', '2026-06-30',
        84000.0,
        'professional_services', 'active'
    ))
    cid += 1

con.executemany("INSERT INTO raw_contracts VALUES (?,?,?,?,?,?,?)", contracts_data)

# ── Invoices ──────────────────────────────────────────────────────────────────
# Recurring subscription invoices: Jul 2024 – Dec 2025 (18 months)
# 65 accounts × 18 months = 1170 rows → trim to ~480 by using Jul–Dec 2025 (6 months)
# = 65 × 6 = 390 rows. Add ~30 more for setup/credit/pending/PS = ~420 total.

iid = 1
invoices_data = []

recurring_accounts = list(recurring_contract_map.items())  # (acc_id, contract_id)

months_2024 = [(2024, m) for m in range(7, 13)]   # Jul–Dec 2024 (6 months)
months_2025 = [(2025, m) for m in range(1, 13)]    # Jan–Dec 2025 (12 months)

# Build annual_value lookup
annual_lookup = {}
for (start_acc, count, annual_value, _) in tier_config:
    for i in range(count):
        acc_id = f'ACC{(start_acc + i):04d}'
        annual_lookup[acc_id] = annual_value

# Subscription invoices — all 18 months for all 65 recurring accounts
for acc_id, contract_id in recurring_accounts:
    monthly_amt = round(annual_lookup[acc_id] / 12, 2)
    for yr, mo in months_2024 + months_2025:
        inv_date = f'{yr}-{mo:02d}-01'
        invoices_data.append((
            f'INV{iid:05d}', acc_id, contract_id, inv_date,
            monthly_amt, 'subscription', 'paid'
        ))
        iid += 1

# Pilot subscription invoices — Jul 2025 – Dec 2025 only
for acc_id, contract_id in pilot_contract_map.items():
    for yr, mo in [(2025, m) for m in range(7, 13)]:
        inv_date = f'{yr}-{mo:02d}-01'
        invoices_data.append((
            f'INV{iid:05d}', acc_id, contract_id, inv_date,
            14000.0, 'subscription', 'paid'
        ))
        iid += 1

# Setup fee invoices in Dec 2025 — 8 invoices summing to $80k
# 8 invoices × $10,000 = $80,000
setup_accts = [f'ACC{i:04d}' for i in range(1, 9)]
for acc_id in setup_accts:
    contract_id = recurring_contract_map[acc_id]
    invoices_data.append((
        f'INV{iid:05d}', acc_id, contract_id, '2025-12-05',
        10000.0, 'setup', 'paid'
    ))
    iid += 1

# Pending subscription invoices in Dec 2025 — 3 invoices summing to $30k
pending_accts = [f'ACC{i:04d}' for i in range(9, 12)]
for acc_id in pending_accts:
    contract_id = recurring_contract_map[acc_id]
    invoices_data.append((
        f'INV{iid:05d}', acc_id, contract_id, '2025-12-28',
        10000.0, 'subscription', 'pending'
    ))
    iid += 1

# Credit invoices in Dec 2025 — 3 invoices summing to -$20k (Finance partial offset)
credit_accts = [f'ACC{i:04d}' for i in range(12, 15)]
for i, acc_id in enumerate(credit_accts):
    contract_id = recurring_contract_map[acc_id]
    invoices_data.append((
        f'INV{iid:05d}', acc_id, contract_id, '2025-12-15',
        -round(20000 / 3, 2), 'credit', 'paid'
    ))
    iid += 1

# Professional services invoices — Dec 2025 — 10 × $7k = $70k
for acc_id, contract_id in ps_contract_map.items():
    invoices_data.append((
        f'INV{iid:05d}', acc_id, contract_id, '2025-12-10',
        7000.0, 'subscription', 'paid'
    ))
    iid += 1

con.executemany("INSERT INTO raw_invoices VALUES (?,?,?,?,?,?,?)", invoices_data)

# ── Payments ──────────────────────────────────────────────────────────────────
# For each paid invoice, create a payment.
# Dec 2025 subscription (recurring): ~5 accounts pay in Jan 2026 (cash lag ~$70k)
# 5 recurring accounts paying ~$14k/mo each in Jan → 5×14k = $70k lag
# But those accounts have various amounts — let's use 5 accounts with $14k/mo average
# ACC0011–ACC0015 are mid-market at $24k/mo. Choose 3 of them for Jan payment → 3×24k = $72k lag

pid = 1
payments_data = []

# Fetch invoice rows we just inserted
inv_rows = con.execute("""
SELECT invoice_id, account_id, contract_id, invoice_date::VARCHAR, amount, type, status
FROM raw_invoices
""").fetchall()

# Build a contract type lookup
ctype_lookup = {r[0]: r[1] for r in con.execute("SELECT contract_id, type FROM raw_contracts").fetchall()}

# Accounts that will pay their Dec recurring invoice late (in Jan 2026)
late_payers = {'ACC0011', 'ACC0012', 'ACC0013'}  # 3 mid-market @ $24k = $72k lag

for row in inv_rows:
    inv_id, acc_id, contract_id, inv_date, amount, inv_type, status = row
    if status != 'paid':
        continue  # no payment for pending/void
    if float(amount) <= 0:
        continue  # skip credit invoices

    # Determine payment date
    inv_date_obj = inv_date  # already a string YYYY-MM-DD
    yr = int(inv_date_obj[:4])
    mo = int(inv_date_obj[5:7])

    ctype = ctype_lookup.get(contract_id, '')

    # Late payers: Dec recurring subscription invoices from late_payers → pay in Jan 2026
    if (yr == 2025 and mo == 12 and inv_type == 'subscription'
            and ctype == 'recurring' and acc_id in late_payers):
        pay_date = '2026-01-10'
    else:
        # Normal: pay within 5 days of invoice
        pay_date = f'{yr}-{mo:02d}-05'

    payments_data.append((
        f'PAY{pid:05d}', acc_id, inv_id, pay_date,
        float(amount), False
    ))
    pid += 1

con.executemany("INSERT INTO raw_payments VALUES (?,?,?,?,?,?)", payments_data)

print("=== SEED DATA LOADED ===")
print(f"  raw_accounts:  {con.execute('SELECT COUNT(*) FROM raw_accounts').fetchone()[0]}")
print(f"  raw_contracts: {con.execute('SELECT COUNT(*) FROM raw_contracts').fetchone()[0]}")
print(f"  raw_invoices:  {con.execute('SELECT COUNT(*) FROM raw_invoices').fetchone()[0]}")
print(f"  raw_payments:  {con.execute('SELECT COUNT(*) FROM raw_payments').fetchone()[0]}")

# ──────────────────────────────────────────────────────────────────────────────
# 2. STAGING VIEWS
# ──────────────────────────────────────────────────────────────────────────────

con.execute("""
CREATE OR REPLACE VIEW stg_contracts AS
SELECT
    contract_id,
    account_id,
    start_date,
    end_date,
    annual_value,
    ROUND(annual_value / 12.0, 2) AS monthly_value,
    LOWER(TRIM(type))             AS type,
    LOWER(TRIM(status))           AS status
FROM raw_contracts
""")

con.execute("""
CREATE OR REPLACE VIEW stg_invoices AS
SELECT
    invoice_id,
    account_id,
    contract_id,
    invoice_date,
    DATE_TRUNC('month', invoice_date)::DATE AS invoice_month,
    amount,
    LOWER(TRIM(type))   AS type,
    LOWER(TRIM(status)) AS status
FROM raw_invoices
""")

con.execute("""
CREATE OR REPLACE VIEW stg_payments AS
SELECT
    payment_id,
    account_id,
    invoice_id,
    payment_date,
    DATE_TRUNC('month', payment_date)::DATE AS payment_month,
    CASE WHEN refunded = TRUE THEN 0.00 ELSE CAST(amount AS DECIMAL(12,2)) END AS amount,
    refunded
FROM raw_payments
""")

# ──────────────────────────────────────────────────────────────────────────────
# 3. THREE BUGGY METRIC MODELS
# ──────────────────────────────────────────────────────────────────────────────

# Finance: all invoice types, all statuses, no type/status filters
con.execute("""
CREATE OR REPLACE VIEW fct_revenue_monthly AS
SELECT
    DATE_TRUNC('month', i.invoice_date)::DATE AS revenue_month,
    i.account_id,
    c.type   AS contract_type,
    i.type   AS invoice_type,
    i.status AS invoice_status,
    i.amount
FROM stg_invoices i
LEFT JOIN stg_contracts c ON i.contract_id = c.contract_id
-- BUG 1: no i.type filter   -> setup fees included
-- BUG 2: no i.status filter -> pending included
-- BUG 3: credits included   -> partially offsets BUG 1
""")

# Sales: contract monthly_value, active only, no pilot filter, uses start_date month
con.execute("""
CREATE OR REPLACE VIEW fct_arr_by_account AS
SELECT
    DATE_TRUNC('month', c.start_date)::DATE AS revenue_month,
    c.account_id,
    c.type   AS contract_type,
    SUM(c.monthly_value) AS mrr,
    SUM(c.annual_value)  AS arr
FROM stg_contracts c
-- BUG 2: no c.type filter (pilots included)
WHERE c.status = 'active'
-- BUG 3: uses start_date, not invoice_date
GROUP BY 1, 2, 3
""")

# Marketing: cash basis (payment_date), no contract type filter
con.execute("""
CREATE OR REPLACE VIEW fct_marketing_revenue AS
SELECT
    p.payment_month AS revenue_month,
    p.account_id,
    SUM(p.amount)   AS cash_revenue
FROM stg_payments p
LEFT JOIN stg_invoices  i ON p.invoice_id = i.invoice_id
LEFT JOIN stg_contracts c ON i.contract_id = c.contract_id
-- BUG 1: uses payment_date not invoice_date
-- BUG 2: no c.type filter (PS included)
WHERE p.amount > 0
GROUP BY 1, 2
""")

# ──────────────────────────────────────────────────────────────────────────────
# 4. REPRODUCE THE THREE CLAIMED NUMBERS
# ──────────────────────────────────────────────────────────────────────────────

print("\n" + "="*70)
print("PHASE 1: WHAT DOES EACH METRIC PRODUCE FOR DEC 2025?")
print("="*70)

finance_dec = con.execute("""
SELECT SUM(amount) AS total, COUNT(DISTINCT account_id) AS accts
FROM fct_revenue_monthly
WHERE revenue_month = '2025-12-01'
""").fetchone()

# Sales model uses start_date month. All active contracts started before Dec 2025.
# The "Dec 2025" Sales number means: sum of monthly_value for ALL active contracts
# (because they report a snapshot, not a monthly waterfall).
sales_active = con.execute("""
SELECT SUM(monthly_value) AS total, COUNT(DISTINCT account_id) AS accts
FROM stg_contracts
WHERE status = 'active'
-- No type filter = BUG (includes pilots)
""").fetchone()

mktg_dec = con.execute("""
SELECT SUM(p.amount) AS total, COUNT(DISTINCT p.account_id) AS accts
FROM stg_payments p
LEFT JOIN stg_invoices  i ON p.invoice_id = i.invoice_id
LEFT JOIN stg_contracts c ON i.contract_id = c.contract_id
WHERE p.payment_month = '2025-12-01'
  AND p.amount > 0
  -- No type filter = BUG
""").fetchone()

canonical_dec = con.execute("""
SELECT SUM(i.amount) AS total, COUNT(DISTINCT i.account_id) AS accts
FROM stg_invoices  i
JOIN stg_contracts c ON i.contract_id = c.contract_id
WHERE DATE_TRUNC('month', i.invoice_date) = '2025-12-01'
  AND i.type   = 'subscription'
  AND i.status = 'paid'
  AND c.type   = 'recurring'
  AND c.status = 'active'
""").fetchone()

print(f"\n  Finance   (all invoices, Dec 2025):           ${f(finance_dec[0]):>13,.2f}  |  {finance_dec[1]} accts")
print(f"  Sales     (active contract basis, snapshot):  ${f(sales_active[0]):>13,.2f}  |  {sales_active[1]} accts")
print(f"  Marketing (cash payments, Dec 2025):          ${f(mktg_dec[0]):>13,.2f}  |  {mktg_dec[1]} accts")
print(f"\n  CANONICAL (board MRR, Dec 2025):              ${f(canonical_dec[0]):>13,.2f}  |  {canonical_dec[1]} accts")

# ──────────────────────────────────────────────────────────────────────────────
# 5. DIVERGENCE MAP
# ──────────────────────────────────────────────────────────────────────────────

print("\n" + "="*70)
print("PHASE 2: DIVERGENCE MAP — DOLLAR IMPACT OF EACH DECISION")
print("="*70)

# --- Component isolation ---
setup_fees = f(con.execute("""
    SELECT COALESCE(SUM(amount),0) FROM stg_invoices
    WHERE DATE_TRUNC('month', invoice_date) = '2025-12-01'
      AND type = 'setup' AND status = 'paid'
""").fetchone()[0])

credit_invoices = f(con.execute("""
    SELECT COALESCE(SUM(amount),0) FROM stg_invoices
    WHERE DATE_TRUNC('month', invoice_date) = '2025-12-01'
      AND type = 'credit' AND status = 'paid'
""").fetchone()[0])

pending_invoices = f(con.execute("""
    SELECT COALESCE(SUM(amount),0) FROM stg_invoices
    WHERE DATE_TRUNC('month', invoice_date) = '2025-12-01'
      AND type = 'subscription' AND status = 'pending'
""").fetchone()[0])

pilot_invoices_dec = f(con.execute("""
    SELECT COALESCE(SUM(i.amount),0)
    FROM stg_invoices i JOIN stg_contracts c ON i.contract_id = c.contract_id
    WHERE DATE_TRUNC('month', i.invoice_date) = '2025-12-01'
      AND i.type = 'subscription' AND i.status = 'paid'
      AND c.type = 'pilot' AND c.status = 'active'
""").fetchone()[0])

ps_invoices_dec = f(con.execute("""
    SELECT COALESCE(SUM(i.amount),0)
    FROM stg_invoices i JOIN stg_contracts c ON i.contract_id = c.contract_id
    WHERE DATE_TRUNC('month', i.invoice_date) = '2025-12-01'
      AND i.type = 'subscription' AND i.status = 'paid'
      AND c.type = 'professional_services'
""").fetchone()[0])

pilot_monthly = f(con.execute("""
    SELECT COALESCE(SUM(monthly_value),0)
    FROM stg_contracts WHERE type = 'pilot' AND status = 'active'
""").fetchone()[0])

# Cash timing: Dec invoices (recurring) paid in Jan 2026 — Marketing understates Dec
dec_inv_paid_jan = f(con.execute("""
    SELECT COALESCE(SUM(p.amount),0)
    FROM stg_payments p
    JOIN stg_invoices  i ON p.invoice_id  = i.invoice_id
    JOIN stg_contracts c ON i.contract_id = c.contract_id
    WHERE DATE_TRUNC('month', i.invoice_date) = '2025-12-01'
      AND DATE_TRUNC('month', p.payment_date) = '2026-01-01'
      AND i.type  = 'subscription' AND i.status = 'paid'
      AND c.type  = 'recurring'    AND c.status = 'active'
      AND p.refunded = FALSE
""").fetchone()[0])

# PS payments received in Dec 2025 (cash basis)
ps_payments_dec = f(con.execute("""
    SELECT COALESCE(SUM(p.amount),0)
    FROM stg_payments p
    JOIN stg_invoices  i ON p.invoice_id  = i.invoice_id
    JOIN stg_contracts c ON i.contract_id = c.contract_id
    WHERE DATE_TRUNC('month', p.payment_date) = '2025-12-01'
      AND c.type = 'professional_services'
      AND p.amount > 0 AND p.refunded = FALSE
""").fetchone()[0])

# Pilot payments received in Dec 2025
pilot_payments_dec = f(con.execute("""
    SELECT COALESCE(SUM(p.amount),0)
    FROM stg_payments p
    JOIN stg_invoices  i ON p.invoice_id  = i.invoice_id
    JOIN stg_contracts c ON i.contract_id = c.contract_id
    WHERE DATE_TRUNC('month', p.payment_date) = '2025-12-01'
      AND c.type = 'pilot' AND c.status = 'active'
      AND p.amount > 0 AND p.refunded = FALSE
""").fetchone()[0])

can = f(canonical_dec[0])

print(f"""
FINANCE ($1.2M claim) — inflated above canonical:
  Canonical MRR (base):                            ${can:>13,.2f}
  + Setup fees  (BUG 1: type='setup' included):    ${setup_fees:>13,.2f}
  + Pending inv (BUG 2: status='pending' included): ${pending_invoices:>13,.2f}
  + Credits     (BUG 3: negative, partial offset): ${credit_invoices:>13,.2f}
  + Pilot subs  (pilot contracts have invoices):   ${pilot_invoices_dec:>13,.2f}
  ─────────────────────────────────────────────────────────────────────────
  Finance total (Dec 2025):                        ${f(finance_dec[0]):>13,.2f}
  Delta vs canonical:                              ${f(finance_dec[0]) - can:>+13,.2f}

SALES ($1.4M claim) — contract-basis snapshot, pilots included:
  Recurring active (monthly_value):                ${can:>13,.2f}  ← approx (contract≈invoice)
  Pilot active (BUG 2: no type filter):            ${pilot_monthly:>13,.2f}
  ─────────────────────────────────────────────────────────────────────────
  Sales total (all active, contract basis):        ${f(sales_active[0]):>13,.2f}
  Delta vs canonical:                              ${f(sales_active[0]) - can:>+13,.2f}

MARKETING ($1.1M claim) — cash basis, PS included:
  Canonical MRR (accrual basis):                   ${can:>13,.2f}
  - Dec invoices paid in Jan 2026 (BUG 1: lag):   ${-dec_inv_paid_jan:>+13,.2f}
  + PS payments in Dec (BUG 2: type not filtered): ${ps_payments_dec:>13,.2f}
  + Pilot payments in Dec (BUG 2):                 ${pilot_payments_dec:>13,.2f}
  ─────────────────────────────────────────────────────────────────────────
  Marketing total (Dec 2025 cash):                 ${f(mktg_dec[0]):>13,.2f}
  Delta vs canonical:                              ${f(mktg_dec[0]) - can:>+13,.2f}
""")

# ──────────────────────────────────────────────────────────────────────────────
# 6. DETAILED INVOICE AUDIT (Dec 2025)
# ──────────────────────────────────────────────────────────────────────────────

print("="*70)
print("INVOICE TYPE AUDIT — Dec 2025")
print("="*70)

rows = con.execute("""
SELECT
    i.type,
    i.status,
    COUNT(*)        AS invoice_count,
    SUM(i.amount)   AS total_amount,
    CASE
        WHEN i.type = 'subscription' AND i.status = 'paid'    THEN 'IN canonical (if recurring+active contract)'
        WHEN i.type = 'setup'        AND i.status = 'paid'    THEN 'INFLATES Finance only (+$80k)'
        WHEN i.type = 'credit'       AND i.status = 'paid'    THEN 'IN Finance (negative offset)'
        WHEN i.type = 'subscription' AND i.status = 'pending' THEN 'INFLATES Finance only (+$30k)'
        ELSE 'OTHER'
    END AS treatment
FROM stg_invoices i
WHERE DATE_TRUNC('month', i.invoice_date) = '2025-12-01'
GROUP BY 1, 2
ORDER BY ABS(SUM(i.amount)) DESC
""").fetchall()

print(f"\n  {'Type':<14} {'Status':<10} {'Count':>6} {'Amount':>14}  Treatment")
print("  " + "-"*85)
for row in rows:
    print(f"  {row[0]:<14} {row[1]:<10} {row[2]:>6} ${f(row[3]):>12,.2f}  {row[4]}")

# ──────────────────────────────────────────────────────────────────────────────
# 7. CONTRACT TYPE AUDIT
# ──────────────────────────────────────────────────────────────────────────────

print("\n" + "="*70)
print("CONTRACT TYPE AUDIT")
print("="*70)

rows = con.execute("""
SELECT
    c.type, c.status,
    COUNT(DISTINCT c.account_id) AS accounts,
    SUM(c.monthly_value)         AS monthly_value,
    CASE
        WHEN c.type = 'recurring'             AND c.status = 'active'  THEN 'IN canonical'
        WHEN c.type = 'pilot'                 AND c.status = 'active'  THEN 'INFLATES Sales (+$140k)'
        WHEN c.type = 'professional_services' AND c.status = 'active'  THEN 'INFLATES Marketing (cash)'
        WHEN c.status = 'churned'                                       THEN 'EXCLUDED everywhere'
        ELSE 'OTHER'
    END AS canonical_treatment
FROM stg_contracts c
GROUP BY 1, 2
ORDER BY 4 DESC
""").fetchall()

print(f"\n  {'Type':<22} {'Status':<12} {'Accts':>6} {'Monthly Value':>15}  Treatment")
print("  " + "-"*85)
for row in rows:
    print(f"  {row[0]:<22} {row[1]:<12} {row[2]:>6} ${f(row[3]):>13,.2f}  {row[4]}")

# ──────────────────────────────────────────────────────────────────────────────
# 8. CANONICAL MODEL + SEGMENT BREAKDOWN
# ──────────────────────────────────────────────────────────────────────────────

print("\n" + "="*70)
print("PHASE 3: CANONICAL MRR BY SEGMENT (Dec 2025)")
print("="*70)

rows = con.execute("""
SELECT
    a.segment,
    COUNT(DISTINCT i.account_id) AS paying_accounts,
    SUM(i.amount)                AS mrr,
    ROUND(100.0 * SUM(i.amount) /
          SUM(SUM(i.amount)) OVER(), 1) AS pct_of_total
FROM stg_invoices  i
JOIN stg_contracts c ON i.contract_id = c.contract_id
JOIN raw_accounts  a ON c.account_id  = a.account_id
WHERE DATE_TRUNC('month', i.invoice_date) = '2025-12-01'
  AND i.type   = 'subscription'
  AND i.status = 'paid'
  AND c.type   = 'recurring'
  AND c.status = 'active'
GROUP BY 1
ORDER BY 3 DESC
""").fetchall()

print(f"\n  {'Segment':<15} {'Accounts':>10} {'MRR':>14} {'% of Total':>12}")
print("  " + "-"*55)
total_mrr = 0.0
for row in rows:
    print(f"  {row[0]:<15} {row[1]:>10} ${f(row[2]):>12,.2f} {f(row[3]):>11.1f}%")
    total_mrr += f(row[2])
print(f"  {'TOTAL':<15} {'':>10} ${total_mrr:>12,.2f} {'100.0':>11}%")

# ──────────────────────────────────────────────────────────────────────────────
# 9. MRR TREND — LAST 6 MONTHS
# ──────────────────────────────────────────────────────────────────────────────

print("\n" + "="*70)
print("MRR TREND — LAST 6 MONTHS (Canonical)")
print("="*70)

rows = con.execute("""
SELECT
    DATE_TRUNC('month', i.invoice_date)::DATE AS revenue_month,
    SUM(i.amount) AS canonical_mrr
FROM stg_invoices  i
JOIN stg_contracts c ON i.contract_id = c.contract_id
WHERE i.invoice_date >= '2025-07-01'
  AND i.type   = 'subscription'
  AND i.status = 'paid'
  AND c.type   = 'recurring'
  AND c.status = 'active'
GROUP BY 1
ORDER BY 1
""").fetchall()

print(f"\n  {'Month':<12} {'Canonical MRR':>15} {'MoM Change':>12} {'MoM %':>8}")
print("  " + "-"*50)
prev = None
for row in rows:
    mrr = f(row[1])
    if prev:
        mom = mrr - prev
        mom_pct = mom / prev * 100
        print(f"  {str(row[0]):<12} ${mrr:>13,.2f} ${mom:>+11,.2f} {mom_pct:>7.1f}%")
    else:
        print(f"  {str(row[0]):<12} ${mrr:>13,.2f} {'—':>12} {'—':>8}")
    prev = mrr

# ──────────────────────────────────────────────────────────────────────────────
# 10. BUILD fct_mrr_canonical AND RUN TESTS
# ──────────────────────────────────────────────────────────────────────────────

print("\n" + "="*70)
print("PHASE 4: fct_mrr_canonical — BUILD AND TEST")
print("="*70)

con.execute("""
CREATE OR REPLACE VIEW fct_mrr_canonical AS
SELECT
    DATE_TRUNC('month', i.invoice_date)::DATE  AS revenue_month,
    i.account_id,
    i.contract_id,
    a.segment,
    SUM(i.amount)                              AS mrr,
    TRUE  AS is_recurring,
    TRUE  AS is_active,
    TRUE  AS is_paid,
    FALSE AS is_pilot
FROM stg_invoices  i
JOIN stg_contracts c ON i.contract_id = c.contract_id
JOIN raw_accounts  a ON c.account_id  = a.account_id
WHERE i.type   = 'subscription'   -- no setup fees, no credits
  AND i.status = 'paid'           -- no pending, no void
  AND c.type   = 'recurring'      -- no pilots, no professional_services
  AND c.status = 'active'         -- no churned
GROUP BY 1, 2, 3, 4
""")

canonical_total = con.execute("""
SELECT SUM(mrr), COUNT(DISTINCT account_id)
FROM fct_mrr_canonical WHERE revenue_month = '2025-12-01'
""").fetchone()
print(f"\n  fct_mrr_canonical Dec 2025: ${f(canonical_total[0]):,.2f} across {canonical_total[1]} accounts")

# Test 1: assert_mrr_no_pilots
pilot_violations = con.execute("""
SELECT COUNT(*) FROM fct_mrr_canonical f
JOIN stg_contracts c ON f.contract_id = c.contract_id
WHERE c.type = 'pilot'
""").fetchone()[0]

# Test 2: assert_mrr_no_one_time
onetime_violations = con.execute("""
SELECT COUNT(*) FROM fct_mrr_canonical f
JOIN stg_invoices i
    ON  f.contract_id = i.contract_id
    AND DATE_TRUNC('month', i.invoice_date)::DATE = f.revenue_month
WHERE i.type != 'subscription' AND i.status = 'paid'
""").fetchone()[0]

# Test 3: assert_mrr_matches_finance (warn if Finance drifts >5% from canonical)
drift_months = con.execute("""
WITH canonical_by_month AS (
    SELECT revenue_month, SUM(mrr) AS canonical_mrr FROM fct_mrr_canonical GROUP BY 1
),
finance_by_month AS (
    SELECT DATE_TRUNC('month', invoice_date)::DATE AS revenue_month, SUM(amount) AS finance_mrr
    FROM stg_invoices
    WHERE DATE_TRUNC('month', invoice_date) >= '2025-07-01'
    GROUP BY 1
)
SELECT COUNT(*) FROM canonical_by_month c
JOIN finance_by_month f ON c.revenue_month = f.revenue_month
WHERE ABS(c.canonical_mrr - f.finance_mrr) / NULLIF(c.canonical_mrr, 0) > 0.05
""").fetchone()[0]

def test_status(n, pass_msg, fail_msg):
    if n == 0:
        return f"PASS — {pass_msg}"
    return f"FAIL — {fail_msg} ({n} violations)"

print(f"""
  TEST RESULTS:
    assert_mrr_no_pilots:       {test_status(pilot_violations, 'no pilot rows in canonical', 'pilot revenue in canonical')}
    assert_mrr_no_one_time:     {test_status(onetime_violations, 'no non-subscription invoices', 'non-subscription invoices in canonical')}
    assert_mrr_matches_finance: {test_status(drift_months, 'Finance within 5% of canonical', 'Finance drifted >5% from canonical')} (warn-only)
""")

# ──────────────────────────────────────────────────────────────────────────────
# 11. RECONCILIATION TABLE
# ──────────────────────────────────────────────────────────────────────────────

print("="*70)
print("RECONCILIATION TABLE: FROM EACH MODEL TO CANONICAL")
print("="*70)

fin  = f(finance_dec[0])
sal  = f(sales_active[0])
mkt  = f(mktg_dec[0])

print(f"""
  Team        Claimed MRR        vs Canonical      Primary Divergence
  ─────────── ────────────────── ────────────────  ─────────────────────────────────────────────
  Finance     ${fin:>14,.2f}   ${fin-can:>+13,.2f}  Setup fees + pending invoices + credits
  Sales       ${sal:>14,.2f}   ${sal-can:>+13,.2f}  Pilot contracts + contract-basis (not invoices)
  Marketing   ${mkt:>14,.2f}   ${mkt-can:>+13,.2f}  Cash timing lag + professional services
  ─────────── ────────────────── ────────────────  ─────────────────────────────────────────────
  CANONICAL   ${can:>14,.2f}            $0.00  Recurring + active + paid + subscription
""")

# ──────────────────────────────────────────────────────────────────────────────
# 12. BOARD NUMBER
# ──────────────────────────────────────────────────────────────────────────────

print("="*70)
print("BOARD NUMBER")
print("="*70)
print(f"""
  MRR for December 2025 (board presentation):

      ${f(canonical_total[0]):>16,.2f}

  Definition: Recurring subscription revenue recognized in December 2025,
              accrual basis (invoice date), excluding pilots, setup fees,
              credits, professional services, and pending invoices.
""")
