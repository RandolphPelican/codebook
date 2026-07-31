#!/usr/bin/env python3
"""
B61 - Metabolic capability demo (CodebookOS V1.1)

Proves the V1.1 substrate change end to end: a child cap with a finite
energy_budget is entered, made to do work, and dies on schedule when its
energy_dispatched would exceed that budget. On V1.0 the same program runs
to completion, because cap budgets were decorative.

Structure:
  1. Baseline under ROOT (unbounded) - shows normal completion.
  2. Forge a child cap with a small finite budget.
  3. Enter it and run a loop that outspends the budget.
  4. Substrate halts with the CAP BANKRUPT banner naming the cap_id.

Nothing after step 4 prints. That silence is the demonstration.

Run-twice reset canary
----------------------
The program halts while still nested inside the bankrupt cap - cap_exit is
never reached. Before V1.1 chunk 6, current_cap_id would stay pointed at the
dead cap and the NEXT program run would instant-fatigue on a cap the user
believes they already left. Load and run this twice back to back without
rebooting: both runs must behave identically. That is the reset canary.

Observer effect
---------------
The Cap accessors cost 1j and .fetch debits before the handler runs, so a cap
reading its own consumption includes the cost of the read. Measurement is
physical in a substrate that prices measurement.

This file is demo-tier. It imports the compiler and modifies nothing in
boot/, surfaces/, or tools/.

Usage (from repo root):
    python3 demos/b61_cap_bankruptcy.py surfaces/test_b61_cap_bankruptcy.cbc
"""

import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'tools'))

from atreyu_x86 import AtreyuX86, CAP_BITMAP_UNBOUNDED  # noqa: E402

# Budget sized to be outspent by the loop below but large enough that the
# cap survives entry and a few prints, so the death is visibly mid-stride
# rather than immediate.
CHILD_BUDGET = 600
BURN_PER_ROUND = 10   # inner burn per climb reading


def demo_b61_cap_bankruptcy():
    body = [
        {'type': 'print', 'value': {'type': 'str',
         'value': '=== B61 Metabolic Capability (V1.1) ==='}},

        # --- Step 1: baseline under ROOT -----------------------------------
        {'type': 'print', 'value': {'type': 'str',
         'value': 'ROOT budget (expect unbounded sentinel):'}},
        {'type': 'print', 'value': {'type': 'cap_budget',
         'operand': {'type': 'int', 'value': 1}}},

        # --- Step 2: forge a bounded child ---------------------------------
        {'type': 'print', 'value': {'type': 'str',
         'value': 'Forging child cap with finite budget...'}},
        {'type': 'let', 'name': 'co', 'value': {
            'type': 'cap_new',
            'granted_bitmap': CAP_BITMAP_UNBOUNDED,
            'energy_budget': CHILD_BUDGET}},
        {'type': 'let', 'name': 'cap_child', 'value': {
            'type': 'outcome_unwrap_ok', 'operand': {'type': 'var', 'name': 'co'}}},
        {'type': 'print', 'value': {'type': 'str', 'value': 'child budget:'}},
        {'type': 'print', 'value': {'type': 'cap_budget',
         'operand': {'type': 'var', 'name': 'cap_child'}}},
        {'type': 'print', 'value': {'type': 'str',
         'value': 'child used (Babylon ledger, expect 0):'}},
        {'type': 'print', 'value': {'type': 'cap_used',
         'operand': {'type': 'var', 'name': 'cap_child'}}},
        {'type': 'print', 'value': {'type': 'str',
         'value': 'child dispatched (metabolic ledger, expect 0):'}},
        {'type': 'print', 'value': {'type': 'cap_dispatched',
         'operand': {'type': 'var', 'name': 'cap_child'}}},

        # --- Step 3: enter and outspend ------------------------------------
        {'type': 'print', 'value': {'type': 'str',
         'value': 'Entering child. Burning until bankrupt...'}},
        {'type': 'let', 'name': 'enter', 'value': {
            'type': 'cap_enter', 'operand': {'type': 'var', 'name': 'cap_child'}}},

        # Climb structure: rounds of burn work with a metabolic self-read
        # between rounds. The framebuffer shows a rising column of joules
        # terminating in the substrate's banner — the thesis, not an error
        # message. Reading the climb costs joules too (observer effect):
        # each printed reading includes the cost of reading it.
        {'type': 'print', 'value': {'type': 'str',
         'value': 'dispatched climb:'}},
        {'type': 'let', 'name': 'r', 'value': {'type': 'int', 'value': 0}},
        {'type': 'while',
         'cond': {'type': 'lt',
                  'left': {'type': 'var', 'name': 'r'},
                  'right': {'type': 'int', 'value': 999}},
         'body': {'type': 'block', 'stmts': [
             {'type': 'let', 'name': 'r', 'value': {
                 'type': 'add',
                 'left': {'type': 'var', 'name': 'r'},
                 'right': {'type': 'int', 'value': 1}}},
             # burn round: BURN_PER_ROUND inner iterations
             {'type': 'let', 'name': 'k', 'value': {'type': 'int', 'value': 0}},
             {'type': 'while',
              'cond': {'type': 'lt',
                       'left': {'type': 'var', 'name': 'k'},
                       'right': {'type': 'int', 'value': BURN_PER_ROUND}},
              'body': {'type': 'block', 'stmts': [
                  {'type': 'let', 'name': 'k', 'value': {
                      'type': 'add',
                      'left': {'type': 'var', 'name': 'k'},
                      'right': {'type': 'int', 'value': 1}}},
              ]}},
             # metabolic self-read between rounds
             {'type': 'print', 'value': {'type': 'cap_dispatched',
              'operand': {'type': 'var', 'name': 'cap_child'}}},
         ]}},

        # --- Step 4: unreachable on V1.1 -----------------------------------
        # If the substrate is enforcing, execution never arrives here. Seeing
        # this line means cap budgets are still decorative.
        {'type': 'print', 'value': {'type': 'str',
         'value': '!! REACHED POST-LOOP - budget was NOT enforced (V1.0 behaviour) !!'}},
        {'type': 'let', 'name': 'exit', 'value': {'type': 'cap_exit'}},
        {'type': 'print', 'value': {'type': 'str',
         'value': '=== B61 complete (unexpected on V1.1) ==='}},
    ]
    return {'type': 'program', 'body': body}


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else 'surfaces/test_b61_cap_bankruptcy.cbc'
    ast = demo_b61_cap_bankruptcy()
    bc = AtreyuX86().compile(ast)
    with open(out, 'wb') as f:
        f.write(bc)
    print('B61: compiled %d bytes -> %s' % (len(bc), out))
    print('     child budget = %dj, climb rounds of %d burn iters + dispatched read' % (CHILD_BUDGET, BURN_PER_ROUND))
    print('     expect: CAP BANKRUPT banner; the post-loop line must NOT print')


if __name__ == '__main__':
    main()
