# Business questions

Questions this model is intended to answer. Matching SQL lives in `sql/analytics/kpi_queries.sql`.

## Inventory

1. What is on-hand and available inventory value by warehouse and product?
2. Which SKUs have high reserved quantity relative to on-hand?
3. How did inventory positions change between two snapshot dates?
4. What is the net flow of stock by movement type (receipt, issue, transfer, adjust)?

## Procurement

5. What is open PO quantity and amount by supplier / warehouse?
6. What is supplier on-time receipt performance (received date vs promised date)?
7. What is receipt fill rate (received / ordered) by supplier and SKU?
8. Which suppliers miss lead-time commitments most often?

## Fulfillment

9. What is order fill rate (shipped / ordered) by product, customer, and channel?
10. Which open sales orders are at risk based on inventory availability?
11. What is booked vs shipped revenue by week?

## Logistics

12. What is OTIF (on time in full) by carrier, lane (warehouse → customer region), and week?
13. What is freight cost per shipment and per kg by carrier mode?
14. Which shipments missed the promised delivery date?

## Cross-process

15. For a given SKU, can we trace PO receipts → inventory → sales shipments (using product + warehouse + date)?
16. Which warehouses are over/under capacity relative to on-hand units?
