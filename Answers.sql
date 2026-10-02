-- ============================================================
-- q1. basic filtering – high-value products
-- ============================================================

select event_id,store_id,product_code,base_price,promo_type from retail_events_db.fact_events
where base_price>1000;


-- ============================================================
-- q2. sorting promotional events
-- ============================================================

select event_id,product_code,promo_type,
	`quantity_sold(before_promo)`,
    `quantity_sold(after_promo)` as quantity_sold_after_promo 
    from retail_events_db.fact_events
order by quantity_sold_after_promo desc;


-- ============================================================
-- q3. distinct promotion types
-- ============================================================

select distinct
    promo_type
	from fact_events;


-- ============================================================
-- q4. basic aggregation
-- ============================================================

select
    count(*) as total_events,
    sum(`quantity_sold(before_promo)`) as total_quantity_before,
    sum(`quantity_sold(after_promo)`) as total_quantity_after,
    avg(base_price) as average_base_price,
    max(base_price) as maximum_base_price,
    min(base_price) as minimum_base_price
from fact_events;


-- ============================================================
-- q5. sales volume by promotion type
-- ============================================================

select
    promo_type,
    count(*) as event_count,
    sum(`quantity_sold(before_promo)`) as total_before,
    sum(`quantity_sold(after_promo)`) as total_after
from fact_events
group by promo_type
order by total_after desc;


-- ============================================================
-- q6. promotion uplift
-- ============================================================

select
    promo_type,
    sum(`quantity_sold(before_promo)`) as total_before,
    sum(`quantity_sold(after_promo)`) as total_after,
    sum(`quantity_sold(after_promo)`)
        - sum(`quantity_sold(before_promo)`) as quantity_change
from fact_events
group by promo_type
order by quantity_change desc;


-- ============================================================
-- q7. product performance
-- ============================================================

select
    p.product_code,
    product_name,
    category,
    sum(f.`quantity_sold(after_promo)`) as total_quantity_after
from fact_events f
inner join dim_products p
    on f.product_code = p.product_code
group by
    p.product_code,
    product_name,
    category
order by total_quantity_after desc;


-- ============================================================
-- q8. category-level performance
-- ============================================================

select
    category,
    count(*) as event_count,
    sum(f.`quantity_sold(before_promo)`) as total_before,
    sum(f.`quantity_sold(after_promo)`) as total_after,
    sum(f.`quantity_sold(after_promo)`) - sum(f.`quantity_sold(before_promo)`) as quantity_change
from fact_events f
inner join dim_products p
    on f.product_code = p.product_code
group by category
order by total_after desc;


-- ============================================================
-- q9. store performance
-- ============================================================

select
    city,
    count(*) as event_count,
    sum(f.`quantity_sold(before_promo)`) as total_before,
    sum(f.`quantity_sold(after_promo)`) as total_after
from fact_events f
inner join dim_stores s
    on f.store_id = s.store_id
group by city
order by total_after desc;


-- ============================================================
-- q10. campaign performance
-- ============================================================

select
    campaign_name,
    start_date,
    end_date,
    count(*) as event_count,
    sum(f.`quantity_sold(before_promo)`) as total_before,
    sum(f.`quantity_sold(after_promo)`) as total_after
from fact_events f
inner join dim_campaigns c
    on f.campaign_id = c.campaign_id
group by
    c.campaign_id,
    campaign_name,
    start_date,
    end_date
order by total_after desc;


-- ============================================================
-- q11. product category with having
-- ============================================================

select
    category,
    sum(f.`quantity_sold(after_promo)`) as total_quantity_after,
    avg(f.base_price) as average_base_price
from fact_events f
inner join dim_products p
    on f.product_code = p.product_code
group by category
having sum(f.`quantity_sold(after_promo)`) > 1000
order by total_quantity_after desc;


-- ============================================================
-- q12. store + category analysis
-- ============================================================

select
    city,
    category,
    sum(f.`quantity_sold(after_promo)`) as total_quantity_after
from fact_events f
inner join dim_stores s
    on f.store_id = s.store_id
inner join dim_products p
    on f.product_code = p.product_code
group by
    city,
    category
order by
    city,
    total_quantity_after desc;


-- ============================================================
-- q13. promotion effectiveness by product
-- ============================================================

select
    p.product_name,
    category,
    sum(f.`quantity_sold(before_promo)`) as total_before,
    sum(f.`quantity_sold(after_promo)`) as total_after,
    sum(f.`quantity_sold(after_promo)`) - sum(f.`quantity_sold(before_promo)`) as quantity_change,
    (
        (
            sum(f.`quantity_sold(after_promo)`) - sum(f.`quantity_sold(before_promo)`)
        )
        / nullif(sum(f.`quantity_sold(before_promo)`), 0)
    ) * 100 as percentage_change
from fact_events f
inner join dim_products p
    on f.product_code = p.product_code
group by
    p.product_code,
    product_name,
    category
order by percentage_change desc;


-- ============================================================
-- q14. campaign and promotion type analysis
-- ============================================================

select
    campaign_name,
    promo_type,
    count(*) as event_count,
    sum(f.`quantity_sold(before_promo)`) as total_before,
    sum(f.`quantity_sold(after_promo)`) as total_after,
    sum(f.`quantity_sold(after_promo)`)
        - sum(f.`quantity_sold(before_promo)`) as quantity_change
from fact_events f
inner join dim_campaigns c
    on f.campaign_id = c.campaign_id
group by
    c.campaign_id,
    campaign_name,
    promo_type
order by
    campaign_name,
    quantity_change desc;


-- ============================================================
-- q15. product revenue before and after promotion
-- ============================================================

select
    product_name,
    category,
    sum(f.base_price * f.`quantity_sold(before_promo)`) as revenue_before,
    sum(f.base_price * f.`quantity_sold(after_promo)`) as revenue_after,
    sum(f.base_price * f.`quantity_sold(after_promo)`) - sum(f.base_price * f.`quantity_sold(before_promo)`) as revenue_difference
from fact_events f
inner join dim_products p
    on f.product_code = p.product_code
group by
    p.product_code,
    product_name,
    category
order by revenue_difference desc;


-- ============================================================
-- q16. classify promotion performance
-- ============================================================

with promotion_summary as (
    select
        promo_type,
        sum(`quantity_sold(before_promo)`) as total_before,
        sum(`quantity_sold(after_promo)`) as total_after
    from fact_events
    group by promo_type
)
select
    promo_type,
    total_before,
    total_after,
    ((total_after - total_before)/ nullif(total_before, 0)) * 100 as percentage_change,
    case
        when ((total_after - total_before) / nullif(total_before, 0)) * 100 >= 50
            then 'high impact'
        when ((total_after - total_before) / nullif(total_before, 0)) * 100 >= 20
            then 'medium impact'
        else 'low impact'
    end as performance_category
from promotion_summary
order by percentage_change desc;


-- ============================================================
-- q17. top 2 products within each category
-- ============================================================

with product_sales as (
    select
        p.category,
        p.product_name,
        sum(f.`quantity_sold(after_promo)`) as total_quantity_after
    from fact_events f
    inner join dim_products p
        on f.product_code = p.product_code
    group by
        p.product_code,
        p.product_name,
        p.category
),
ranked_products as (
    select
        category,
        product_name,
        total_quantity_after,
        dense_rank() over (
            partition by category
            order by total_quantity_after desc
        ) as category_rank
    from product_sales
)
select
    category,
    product_name,
    total_quantity_after,
    category_rank
from ranked_products
where category_rank <= 2
order by
    category,
    category_rank;


-- ============================================================
-- q18. top 2 stores within each city
-- ============================================================

with store_sales as (
    select
        s.city,
        s.store_id,
        sum(f.`quantity_sold(after_promo)`) as total_quantity_after
    from fact_events f
    inner join dim_stores s
        on f.store_id = s.store_id
    group by
        s.city,
        s.store_id
),
ranked_stores as (
    select
        city,
        store_id,
        total_quantity_after,
        dense_rank() over (
            partition by city
            order by total_quantity_after desc
        ) as city_rank
    from store_sales
)
select
    city,
    store_id,
    total_quantity_after,
    city_rank
from ranked_stores
where city_rank <= 2
order by
    city,
    city_rank;


-- ============================================================
-- q19. top 3 products per campaign by percentage change
-- ============================================================

with campaign_product as (
    select
        c.campaign_name,
        p.product_name,
        sum(f.`quantity_sold(before_promo)`) as total_before,
        sum(f.`quantity_sold(after_promo)`) as total_after
    from fact_events f
    inner join dim_campaigns c
        on f.campaign_id = c.campaign_id
    inner join dim_products p
        on f.product_code = p.product_code
    group by
        c.campaign_id,
        c.campaign_name,
        p.product_code,
        p.product_name
),
calculated as (
    select
        campaign_name,
        product_name,
        total_before,
        total_after,
        total_after - total_before as quantity_change,
        (
            (total_after - total_before)
            / nullif(total_before, 0)
        ) * 100 as percentage_change
    from campaign_product
),
ranked as (
    select
        campaign_name,
        product_name,
        total_before,
        total_after,
        quantity_change,
        percentage_change,
        dense_rank() over (
            partition by campaign_name
            order by percentage_change desc
        ) as campaign_rank
    from calculated
)
select
    campaign_name,
    product_name,
    total_before,
    total_after,
    quantity_change,
    percentage_change,
    campaign_rank
from ranked
where campaign_rank <= 3
order by
    campaign_name,
    campaign_rank;


-- ============================================================
-- q20. complete promotional performance analysis
-- ============================================================

with product_summary as (
    select
        p.product_code,
        p.product_name,
        p.category,
        count(*) as event_count,
        sum(f.`quantity_sold(before_promo)`) as total_before,
        sum(f.`quantity_sold(after_promo)`) as total_after,
        sum(
            f.base_price * f.`quantity_sold(before_promo)`
        ) as revenue_before,
        sum(
            f.base_price * f.`quantity_sold(after_promo)`
        ) as revenue_after,
        avg(f.base_price) as average_base_price
    from fact_events f
    inner join dim_products p
        on f.product_code = p.product_code
    group by
        p.product_code,
        p.product_name,
        p.category
),
calculated as (
    select
        product_code,
        product_name,
        category,
        event_count,
        total_before,
        total_after,
        total_after - total_before as quantity_change,
        (
            (total_after - total_before)
            / nullif(total_before, 0)
        ) * 100 as percentage_change,
        revenue_before,
        revenue_after,
        revenue_after - revenue_before as revenue_change,
        average_base_price
    from product_summary
),
ranked as (
    select
        product_name,
        category,
        event_count,
        total_before,
        total_after,
        quantity_change,
        percentage_change,
        revenue_before,
        revenue_after,
        revenue_change,
        average_base_price,
        dense_rank() over (
            partition by category
            order by revenue_change desc
        ) as product_rank
    from calculated
)
select
    product_name,
    category,
    event_count,
    total_before,
    total_after,
    quantity_change,
    percentage_change,
    revenue_before,
    revenue_after,
    revenue_change,
    average_base_price,
    product_rank
from ranked
where product_rank <= 2
order by
    category,
    product_rank;


-- ============================================================
-- end of answers
-- ============================================================