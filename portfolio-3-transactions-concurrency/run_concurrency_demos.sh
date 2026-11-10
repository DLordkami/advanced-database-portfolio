#!/bin/bash
# Runs demos 2-6. Usage: ./run_concurrency_demos.sh  (needs psql access to kasuwa_demo)
PSQL="psql -p ${PGPORT:-5433} -d kasuwa_demo -q"
reset() { $PSQL -c "UPDATE marketplace.products SET stock_qty=10 WHERE product_id IN (1,2); UPDATE marketplace.products SET unit_price=2500.00 WHERE product_id=3;"; }
final() { $PSQL -Atc "SELECT 'FINAL stock of product 1 = '||stock_qty||'   $1' FROM marketplace.products WHERE product_id=1"; }
pair() { $PSQL -f "$1_A.sql" 2>&1 & sleep 0.3; $PSQL -f "$1_B.sql" 2>&1 & wait; }
echo "=== DEMO 2: LOST UPDATE (READ COMMITTED, read-then-write, no lock) ==="; reset; pair 02_lost_update; final "<-- WRONG: correct answer is 10-3-4 = 3 (A overwrote B)"
echo; echo "=== DEMO 3: FIX WITH SELECT ... FOR UPDATE (row lock) ==="; reset; pair 03_for_update; final "<-- CORRECT: 10-3-4 = 3 (B waited for A)"
echo; echo "=== DEMO 4: REPEATABLE READ detects the conflict ==="; reset; pair 04_repeatable_read; final "<-- only B committed (10-4); A was rejected and must retry"
for L in read_committed repeatable_read; do
  echo; echo "=== DEMO 5: NON-REPEATABLE READ under $L ==="; reset
  $PSQL -f 05_reader_$L.sql 2>&1 & sleep 0.3
  $PSQL -f 05_nonrepeatable_writer.sql 2>&1 & wait
done
echo; echo "=== DEMO 6: DEADLOCK (opposite lock order) ==="; reset; pair 06_deadlock
