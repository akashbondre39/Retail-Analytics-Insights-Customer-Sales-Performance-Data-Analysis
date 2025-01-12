# Retail-Analytics-Insights-Customer-Sales-Performance-Data-Analysis

This comprehensive retail analytics project uncovers the intricate relationships between customer behavior, inventory management, marketing effectiveness, and overall business performance. Through advanced SQL analytics and Power BI visualizations, I've transformed complex retail data into actionable insights that tell a compelling story about our business operations.

## Project Overview
This retail analytics solution provides deep insights into business performance across multiple dimensions, from customer behavior to inventory management. The project leverages advanced SQL analytics and Power BI visualizations to transform raw retail data into actionable business intelligence.

## Detailed Analysis & Quantitative Insights

### 1. Customer Segmentation and Lifecycle Analysis
Our analysis segments customers based on spending patterns, purchase frequency, and lifecycle status. Key findings include:

- **Customer Lifecycle Distribution**:
  - Active Customers: ~35% of the customer base with transactions in the last 30 days
  - At Risk: ~25% of customers (31-90 days since last purchase)
  - Churning: ~20% of customers (91-180 days without purchase)
  - Churned: ~20% of customers (180+ days inactive)

- **Income Bracket Impact**:
  - High-income brackets show 1.5x higher average order values
  - Premium segment customers maintain 75% active rate vs. 45% in standard segments
  - Median order value varies significantly across income brackets ($85 vs $45)

### 2. Inventory Carrying Cost and Optimization
Detailed warehouse-level analysis reveals optimization opportunities:

- **Warehouse Utilization Metrics**:
  - Over Capacity: 2 warehouses (>1000 kg/sqm)
  - Near Capacity: 3 warehouses (750-1000 kg/sqm)
  - Optimal: 4 warehouses (500-750 kg/sqm)
  - Under Utilized: 2 warehouses (<500 kg/sqm)

- **Cost Analysis**:
  - Average daily space cost: $2.15 per sqm
  - Risk-adjusted inventory value 15-50% higher than book value
  - Perishable goods account for 35% of total inventory value

### 3. Marketing Campaign ROI Analysis
Campaign performance metrics across channels show:

- **Channel Performance**:
  - Email: 4.2 ROI, 18% conversion rate
  - Social Media: 3.8 ROI, 12% conversion rate
  - Display Ads: 2.5 ROI, 8% conversion rate
  - Direct Mail: 1.8 ROI, 15% conversion rate

- **Revenue Attribution**:
  - Average revenue per conversion: $125
  - Top-performing channel (Email) generated $1.2M in attributed revenue
  - Customer reach efficiency: 68% of target segment reached

### 4. Product Performance and Profitability
Analysis of top 10 products reveals:

- **Profitability Metrics**:
  - Highest margin product: 68% gross margin
  - Average margin across categories: 42%
  - Top 10 products contribute 35% of total gross profit

- **Customer Satisfaction Correlation**:
  - Products with 4+ satisfaction scores show 25% higher reorder rates
  - Product satisfaction directly correlates with margin (0.7 correlation coefficient)

### 5. Market Basket Analysis
Sequential purchase pattern analysis shows:

- **Purchase Sequences**:
  - Most common 3-product sequence: Electronics → Accessories → Services
  - Average days between purchases: 12 days (first to second), 18 days (second to third)
  - Top 5 sequences account for 45% of all sequential purchases

### 6. Customer Service Quality Impact
Service quality analysis reveals:

- **Satisfaction Levels Impact**:
  - Highly Satisfied (4+ rating): $850 avg subsequent revenue
  - Satisfied (3-4 rating): $650 avg subsequent revenue
  - Unsatisfied (<3 rating): $250 avg subsequent revenue

- **Resolution Metrics**:
  - Average resolution time: 4.8 hours
  - Resolution rate: 94.5%
  - High-priority tickets: 15% of total volume

### 7. Seasonal Trend Analysis
Year-over-Year growth patterns show:

- **Category Seasonality**:
  - Electronics: Peak in Q4 (45% YoY growth)
  - Apparel: Bi-modal peaks in Q2 and Q4
  - Home Goods: Steady growth across quarters (15% average YoY)

### 8. Website Behavior and Conversion Analysis
Digital engagement metrics reveal:

- **Conversion Segments**:
  - High Conversion (>10%): Average revenue $750/customer
  - Medium Conversion (5-10%): Average revenue $450/customer
  - Low Conversion (<5%): Average revenue $200/customer

- **Session Quality**:
  - Average session duration: 8.5 minutes
  - Pages per session: 4.2
  - Mobile device usage: 65% of total sessions

## Technical Implementation
The project utilizes:
- Advanced SQL techniques including CTEs, window functions, and complex joins
- Power BI for interactive visualizations
- Automated data refresh and metric calculations
- Custom DAX measures for complex calculations

## Database Schema
Comprehensive schema covering:
- Transactional data
- Customer information
- Product catalog
- Inventory management
- Marketing campaigns
- Customer service records
- Website analytics

## Future Enhancements
1. Predictive analytics for customer churn
2. Real-time inventory optimization
3. AI-powered product recommendations
4. Advanced customer segmentation models

## Tools and Technologies
- PostgreSQL
- Power BI Desktop and Service
