-- Enhanced Schema Design
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(100),
    registration_date DATE,
    birth_date DATE,
    gender VARCHAR(20),
    country VARCHAR(50),
    city VARCHAR(50),
    postal_code VARCHAR(20),
    segment VARCHAR(20),
    income_bracket VARCHAR(20),
    opt_in_marketing BOOLEAN
);

CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    subcategory VARCHAR(50),
    brand VARCHAR(50),
    supplier_id INT,
    base_price DECIMAL(10,2),
    cost DECIMAL(10,2),
    weight_kg DECIMAL(5,2),
    is_perishable BOOLEAN,
    shelf_life_days INT,
    reorder_point INT,
    min_stock_level INT,
    max_stock_level INT
);

CREATE TABLE suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100),
    country VARCHAR(50),
    lead_time_days INT,
    reliability_score DECIMAL(3,2),
    payment_terms_days INT
);

CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY,
    product_id INT,
    warehouse_id INT,
    quantity INT,
    batch_number VARCHAR(50),
    manufacturing_date DATE,
    expiry_date DATE,
    last_restock_date DATE,
    stock_status VARCHAR(20),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE warehouses (
    warehouse_id INT PRIMARY KEY,
    warehouse_name VARCHAR(100),
    country VARCHAR(50),
    city VARCHAR(50),
    capacity_sqm DECIMAL(10,2),
    operating_cost_day DECIMAL(10,2)
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    store_id INT,
    transaction_date TIMESTAMP,
    quantity INT,
    unit_price DECIMAL(10,2),
    discount DECIMAL(4,2),
    payment_method VARCHAR(20),
    online_order BOOLEAN,
    delivery_required BOOLEAN,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE marketing_campaigns (
    campaign_id INT PRIMARY KEY,
    campaign_name VARCHAR(100),
    start_date DATE,
    end_date DATE,
    channel VARCHAR(50),
    budget DECIMAL(10,2),
    target_segment VARCHAR(20)
);

CREATE TABLE campaign_responses (
    response_id INT PRIMARY KEY,
    campaign_id INT,
    customer_id INT,
    response_date TIMESTAMP,
    interaction_type VARCHAR(50),
    conversion_flag BOOLEAN,
    revenue_generated DECIMAL(10,2),
    FOREIGN KEY (campaign_id) REFERENCES marketing_campaigns(campaign_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE customer_service (
    ticket_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    ticket_date TIMESTAMP,
    resolution_date TIMESTAMP,
    issue_type VARCHAR(50),
    priority VARCHAR(20),
    status VARCHAR(20),
    satisfaction_score INT,
    resolution_time_hours DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE website_analytics (
    session_id INT PRIMARY KEY,
    customer_id INT,
    visit_date TIMESTAMP,
    page_views INT,
    time_spent_seconds INT,
    device_type VARCHAR(20),
    entry_page VARCHAR(100),
    exit_page VARCHAR(100),
    conversion_flag BOOLEAN,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE competitor_pricing (
    competitor_price_id INT PRIMARY KEY,
    product_id INT,
    competitor_name VARCHAR(100),
    price DECIMAL(10,2),
    price_date DATE,
    promotion_flag BOOLEAN,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-------------------------------------------------------------------------

-- 1.Customer Segmentation and Lifecycle Analysis
WITH customer_metrics AS (
    SELECT 
        c.customer_id,
        c.registration_date,
        c.income_bracket,
        COUNT(DISTINCT t.transaction_id) as purchase_count,
        SUM(t.quantity * t.unit_price * (1 - t.discount)) as total_spent,
        MAX(t.transaction_date) as last_purchase_date,
        AVG(t.quantity * t.unit_price * (1 - t.discount)) as avg_order_value,
        PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY t.quantity * t.unit_price * (1 - t.discount)) as median_order_value,
        STRING_AGG(DISTINCT p.category, ', ') as preferred_categories
    FROM customers c
    LEFT JOIN transactions t ON c.customer_id = t.customer_id
    LEFT JOIN products p ON t.product_id = p.product_id
    GROUP BY c.customer_id, c.registration_date, c.income_bracket
),
customer_segments AS (
    SELECT 
        *,
        NTILE(4) OVER (ORDER BY total_spent) as spending_quartile,
        NTILE(4) OVER (ORDER BY purchase_count) as frequency_quartile,
        NTILE(4) OVER (ORDER BY avg_order_value) as aov_quartile,
        CASE 
            WHEN DATE_PART('day', NOW() - last_purchase_date) <= 30 THEN 'Active'
            WHEN DATE_PART('day', NOW() - last_purchase_date) <= 90 THEN 'At Risk'
            WHEN DATE_PART('day', NOW() - last_purchase_date) <= 180 THEN 'Churning'
            ELSE 'Churned'
        END as lifecycle_status
    FROM customer_metrics
)
SELECT 
    lifecycle_status,
    income_bracket,
    COUNT(*) as customer_count,
    AVG(total_spent) as avg_customer_value,
    AVG(purchase_count) as avg_purchase_frequency,
    ROUND(AVG(CASE WHEN lifecycle_status = 'Active' THEN 1 ELSE 0 END) * 100, 2) as active_rate
FROM customer_segments
GROUP BY CUBE(lifecycle_status, income_bracket)
HAVING lifecycle_status IS NOT NULL;



-- 2. Inventory Carrying Cost and Optimization
WITH daily_inventory AS (
    SELECT 
        i.warehouse_id,
        i.product_id,
        w.operating_cost_day,
        p.cost as unit_cost,
        i.quantity,
        p.weight_kg,
        w.capacity_sqm,
        DATE_PART('day', AGE(i.expiry_date, i.manufacturing_date)) as shelf_life_remaining
    FROM inventory i
    JOIN products p ON i.product_id = p.product_id
    JOIN warehouses w ON i.warehouse_id = w.warehouse_id
),
inventory_costs AS (
    SELECT 
        warehouse_id,
        SUM(quantity * unit_cost) as total_inventory_value,
        SUM(quantity * weight_kg) as total_weight,
        SUM(CASE 
            WHEN shelf_life_remaining < 30 THEN quantity * unit_cost * 1.5
            WHEN shelf_life_remaining < 60 THEN quantity * unit_cost * 1.2
            ELSE quantity * unit_cost
        END) as risk_adjusted_value,
        operating_cost_day * SUM(quantity * weight_kg) / capacity_sqm as space_cost
    FROM daily_inventory
    GROUP BY warehouse_id, operating_cost_day, capacity_sqm
)
SELECT 
    i.warehouse_id,
    w.warehouse_name,
    w.city,
    ROUND(i.total_inventory_value, 2) as inventory_value,
    ROUND(i.risk_adjusted_value, 2) as risk_adjusted_value,
    ROUND(i.space_cost, 2) as daily_space_cost,
    ROUND(i.total_weight, 2) as total_weight_kg,
    ROUND(i.total_weight / w.capacity_sqm, 2) as weight_density_per_sqm,
    CASE 
        WHEN i.total_weight / w.capacity_sqm > 1000 THEN 'Over Capacity'
        WHEN i.total_weight / w.capacity_sqm > 750 THEN 'Near Capacity'
        WHEN i.total_weight / w.capacity_sqm > 500 THEN 'Optimal'
        ELSE 'Under Utilized'
    END as capacity_status
FROM inventory_costs i
JOIN warehouses w ON i.warehouse_id = w.warehouse_id



-- 3.Marketing Campaign Attribution and ROI Analysis

WITH campaign_performance AS (
    SELECT 
        mc.campaign_id,
        mc.campaign_name,
        mc.channel,
        mc.budget,
        COUNT(DISTINCT cr.customer_id) as reached_customers,
        COUNT(DISTINCT CASE WHEN cr.conversion_flag THEN cr.customer_id END) as converted_customers,
        SUM(cr.revenue_generated) as attributed_revenue,
        SUM(t.quantity * t.unit_price * (1 - t.discount)) as total_revenue
    FROM marketing_campaigns mc
    LEFT JOIN campaign_responses cr ON mc.campaign_id = cr.campaign_id
    LEFT JOIN transactions t ON cr.customer_id = t.customer_id 
        AND t.transaction_date BETWEEN mc.start_date AND mc.end_date + INTERVAL '30 days'
    GROUP BY mc.campaign_id, mc.campaign_name, mc.channel, mc.budget
),
campaign_metrics AS (
    SELECT 
        *,
        ROUND(converted_customers::DECIMAL / NULLIF(reached_customers, 0) * 100, 2) as conversion_rate,
        ROUND(attributed_revenue / NULLIF(budget, 0), 2) as roi,
        ROUND(attributed_revenue::DECIMAL / NULLIF(converted_customers, 0), 2) as revenue_per_conversion,
        DENSE_RANK() OVER (PARTITION BY channel ORDER BY attributed_revenue DESC) as channel_rank
    FROM campaign_performance
)
SELECT 
    channel,
    COUNT(*) as campaign_count,
    AVG(conversion_rate) as avg_conversion_rate,
    AVG(roi) as avg_roi,
    SUM(attributed_revenue) as total_revenue,
    SUM(budget) as total_spend,
    ROUND(SUM(attributed_revenue) / NULLIF(SUM(budget), 0), 2) as channel_roi
FROM campaign_metrics
GROUP BY channel
HAVING SUM(budget) > 0
ORDER BY channel_roi DESC;



-- 4.Product Performance and Profitability Analysis
WITH product_metrics AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.category,
        p.base_price,
        p.cost,
        COUNT(DISTINCT t.transaction_id) as total_sales,
        SUM(t.quantity) as units_sold,
        ROUND(SUM(t.quantity * t.unit_price * (1 - t.discount)),2) as revenue,
        SUM(t.quantity * p.cost) as total_cost,
        COUNT(DISTINCT t.customer_id) as unique_customers,
        ROUND(AVG(cs.satisfaction_score),2) as product_satisfaction
    FROM products p
    LEFT JOIN transactions t ON p.product_id = t.product_id
    LEFT JOIN customer_service cs ON p.product_id = cs.product_id
    GROUP BY p.product_id, p.product_name, p.category, p.base_price, p.cost
),
profitability_analysis AS (
    SELECT 
        *,
        revenue - total_cost as gross_profit,
        ROUND((revenue - total_cost) / NULLIF(revenue, 0) * 100,2) as margin_percentage,
        revenue / NULLIF(units_sold, 0) as average_selling_price,
        NTILE(4) OVER (PARTITION BY category ORDER BY revenue - total_cost DESC) as profit_quartile
    FROM product_metrics
)
SELECT * FROM profitability_analysis
ORDER BY gross_profit DESC, margin_percentage DESC
LIMIT 10;



-- 5. Market Basket Analysis with Sequential Patterns
WITH purchase_sequences AS (
    SELECT 
        t1.customer_id,
        p1.category as first_purchase,
        p2.category as second_purchase,
        p3.category as third_purchase,
        DATE_PART('day', t2.transaction_date - t1.transaction_date) as days_between_1_2,
        DATE_PART('day', t3.transaction_date - t2.transaction_date) as days_between_2_3
    FROM transactions t1
    JOIN transactions t2 ON t1.customer_id = t2.customer_id 
        AND t2.transaction_date > t1.transaction_date
    JOIN transactions t3 ON t2.customer_id = t3.customer_id 
        AND t3.transaction_date > t2.transaction_date
    JOIN products p1 ON t1.product_id = p1.product_id
    JOIN products p2 ON t2.product_id = p2.product_id
    JOIN products p3 ON t3.product_id = p3.product_id
    WHERE t3.transaction_date <= t1.transaction_date + INTERVAL '90 days'
),
sequence_analysis AS (
    SELECT 
        first_purchase,
        second_purchase,
        third_purchase,
        COUNT(*) as sequence_count,
        AVG(days_between_1_2) as avg_days_first_second,
        AVG(days_between_2_3) as avg_days_second_third
    FROM purchase_sequences
    GROUP BY first_purchase, second_purchase, third_purchase
    HAVING COUNT(*) >= 5
)
SELECT * FROM sequence_analysis
ORDER BY sequence_count DESC;


-- 6.Customer Service Quality Analysis
WITH service_metrics AS (
    SELECT 
        cs.customer_id,
        COUNT(*) as total_tickets,
        AVG(satisfaction_score) as avg_satisfaction,
        AVG(resolution_time_hours) as avg_resolution_time,
        COUNT(CASE WHEN status = 'Resolved' THEN 1 END) * 100.0 / COUNT(*) as resolution_rate,
        COUNT(CASE WHEN priority = 'High' THEN 1 END) as high_priority_tickets
    FROM customer_service cs
    GROUP BY cs.customer_id
),
impact_analysis AS (
    SELECT 
        sm.*,
        COUNT(DISTINCT t.transaction_id) as purchases_after_service,
        SUM(t.quantity * t.unit_price * (1 - t.discount)) as revenue_after_service
    FROM service_metrics sm
    LEFT JOIN transactions t ON sm.customer_id = t.customer_id
    GROUP BY sm.customer_id, sm.total_tickets, sm.avg_satisfaction, 
             sm.avg_resolution_time, sm.resolution_rate, sm.high_priority_tickets
)
SELECT 
    CASE 
        WHEN avg_satisfaction >= 4 THEN 'Highly Satisfied'
        WHEN avg_satisfaction >= 3 THEN 'Satisfied'
        ELSE 'Unsatisfied'
    END as satisfaction_level,
    COUNT(*) as customer_count,
    ROUND(AVG(avg_resolution_time), 2) as avg_resolution_hours,
    ROUND(AVG(resolution_rate), 2) as avg_resolution_rate,
    ROUND(AVG(revenue_after_service), 2) as avg_subsequent_revenue
FROM impact_analysis
GROUP BY CASE 
    WHEN avg_satisfaction >= 4 THEN 'Highly Satisfied'
    WHEN avg_satisfaction >= 3 THEN 'Satisfied'
    ELSE 'Unsatisfied'
END;


-- 7.Seasonal Trend Analysis with YoY Growth
WITH monthly_sales AS (
    SELECT 
        TO_CHAR(transaction_date, 'Month') as month_name,
        EXTRACT(YEAR FROM transaction_date) as year,
        p.category,
        SUM(t.quantity * t.unit_price * (1 - t.discount)) as revenue
    FROM transactions t
    JOIN products p ON t.product_id = p.product_id
    GROUP BY 1, 2, 3
),
yoy_comparison AS (
    SELECT 
        month_name,
        year,
        category,
        revenue,
        LAG(revenue, 12) OVER (
            PARTITION BY category 
            ORDER BY year, TO_DATE(month_name, 'Month')
        ) as last_year_revenue
    FROM monthly_sales
)
SELECT 
    month_name,
    year,
    category,
    revenue,
    last_year_revenue,
    CASE 
        WHEN last_year_revenue > 0 
        THEN ROUND(((revenue - last_year_revenue) / last_year_revenue * 100), 2)
        ELSE NULL 
    END as yoy_growth_percentage
FROM yoy_comparison
WHERE year > (SELECT MIN(year) FROM monthly_sales)
ORDER BY category, year, TO_DATE(month_name, 'Month');



-- 8.Website Behavior and Conversion Analysis
WITH session_analysis AS (
    SELECT 
        wa.customer_id,
        COUNT(*) as total_sessions,
        AVG(page_views) as avg_page_views,
        AVG(time_spent_seconds) as avg_session_duration,
        COUNT(DISTINCT CASE WHEN conversion_flag THEN session_id END) as converted_sessions,
        STRING_AGG(DISTINCT device_type, ', ') as devices_used,
        MODE() WITHIN GROUP (ORDER BY entry_page) as common_entry_page,
        MODE() WITHIN GROUP (ORDER BY exit_page) as common_exit_page
    FROM website_analytics wa
    GROUP BY wa.customer_id
),
conversion_impact AS (
    SELECT 
        sa.*,
        COUNT(DISTINCT t.transaction_id) as purchases,
        SUM(t.quantity * t.unit_price * (1 - t.discount)) as total_revenue
    FROM session_analysis sa
    LEFT JOIN transactions t ON sa.customer_id = t.customer_id
    GROUP BY sa.customer_id, sa.total_sessions, sa.avg_page_views, sa.avg_session_duration,
             sa.converted_sessions, sa.devices_used, sa.common_entry_page, sa.common_exit_page
)
SELECT 
    CASE 
        WHEN converted_sessions::FLOAT / total_sessions >= 0.1 THEN 'High Conversion'
        WHEN converted_sessions::FLOAT / total_sessions >= 0.05 THEN 'Medium Conversion'
        ELSE 'Low Conversion'
    END as conversion_segment,
    COUNT(*) as customer_count,
    CAST(AVG(avg_session_duration) AS NUMERIC(10,2)) as avg_time_spent,
    CAST(AVG(converted_sessions::FLOAT / total_sessions * 100) AS NUMERIC(10,2)) as conversion_rate,
    CAST(AVG(total_revenue) AS NUMERIC(10,2)) as avg_revenue_per_customer
FROM conversion_impact
GROUP BY CASE 
    WHEN converted_sessions::FLOAT / total_sessions >= 0.1 THEN 'High Conversion'
    WHEN converted_sessions::FLOAT / total_sessions >= 0.05 THEN 'Medium Conversion'
    ELSE 'Low Conversion'
END;



truncate table products cascade;
select * from customer_service;

COPY products (product_id,product_name,category,subcategory,brand,supplier_id,base_price,cost,weight_kg,is_perishable,shelf_life_days,reorder_point,min_stock_level,max_stock_level)
FROM 'D:\GRADE B\Retail Database\products1.csv'
DELIMITER ',' CSV HEADER;


ALTER TABLE customer_service
ADD CONSTRAINT fk_customer_service_product_id
FOREIGN KEY (product_id)
REFERENCES products(product_id);

ALTER TABLE customer_service
ADD CONSTRAINT fk_customer_service_customer_id
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id);


