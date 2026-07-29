-- Static status reference (no seed required)
select * from (
    values
        ('open', 'Open', 'purchase_order', false, 1),
        ('partial', 'Partially Received', 'purchase_order', false, 2),
        ('received', 'Fully Received', 'purchase_order', true, 3),
        ('cancelled', 'Cancelled', 'purchase_order', true, 4),
        ('open', 'Open', 'sales_order', false, 1),
        ('allocated', 'Allocated', 'sales_order', false, 2),
        ('shipped', 'Shipped', 'sales_order', true, 3),
        ('cancelled', 'Cancelled', 'sales_order', true, 4),
        ('in_transit', 'In Transit', 'shipment', false, 1),
        ('delivered', 'Delivered', 'shipment', true, 2),
        ('exception', 'Exception', 'shipment', true, 3)
) as t(status_code, status_name, status_domain, is_terminal, sort_order)
