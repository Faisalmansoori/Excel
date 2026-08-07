use youtube;
select * from ytdata;


-- 1.Find the top 5 countries generating the highest total revenue while considering only countries with more than 100,000 total views.
SELECT
    Country,
    SUM(Views) AS total_views,
    SUM(Revenue) AS total_revenue
FROM ytdata
GROUP BY Country
HAVING SUM(Views) > 100000
ORDER BY total_revenue DESC
LIMIT 5;
#______________________________________________________________________________________________________________________________________________________#

#2.Find the day that generated the highest revenue for every country. 
WITH ranked_revenue AS (
    SELECT
        Date,
        Country,
        Revenue,
        ROW_NUMBER() OVER (PARTITION BY Country ORDER BY Revenue DESC) AS rn
    FROM ytdata
)
SELECT
    Date,
    Country,
    Revenue
FROM ranked_revenue
WHERE rn = 1
ORDER BY Revenue DESC;
#__________________________________________________________________________________________________________________________________________________#

#3.Identify countries whose total revenue exceeds the overall average revenue generated across all countries. 
SELECT
    Country,
    SUM(Revenue) AS total_revenue
FROM ytdata
GROUP BY Country
HAVING SUM(Revenue) > (
						SELECT AVG(country_total)
						FROM (
							SELECT SUM(Revenue) AS country_total
							FROM ytdata
							GROUP BY Country
						) AS country_totals
					  )
ORDER BY total_revenue DESC;
#__________________________________________________________________________________________________________________________________________________#

#4.Marketing wants the three highest-performing traffic sources within each country based on views.
WITH source_views AS (
    SELECT
        Country,
        Source,
        SUM(Views) AS total_views
    FROM ytdata
    GROUP BY Country, Source
),
ranked_sources AS (
    SELECT
        Country,
        Source,
        total_views,
        DENSE_RANK() OVER (PARTITION BY Country ORDER BY total_views DESC) AS rnk
    FROM source_views
)
SELECT
    Country,
    Source,
    total_views,
    rnk
FROM ranked_sources
WHERE rnk <= 3
ORDER BY Country, rnk;
#__________________________________________________________________________________________________________________________________________________#

#5.Find countries where the monthly revenue variance is the lowest. 
WITH monthly_revenue AS (
    SELECT
        Country,
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        SUM(Revenue) AS monthly_total
    FROM ytdata
    GROUP BY Country, DATE_FORMAT(Date, '%Y-%m')
),
country_variance AS (
    SELECT
        Country,
        STDDEV(monthly_total) AS revenue_stddev,
        COUNT(*) AS months_counted
    FROM monthly_revenue
    GROUP BY Country
)
SELECT
    Country,
    revenue_stddev,
    months_counted
FROM country_variance
ORDER BY revenue_stddev ASC;
#__________________________________________________________________________________________________________________________________________________#

#6.Calculate monthly revenue growth percentage.
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY DATE_FORMAT(Date, '%Y-%m')
),
revenue_with_lag AS (
    SELECT
        revenue_month,
        total_revenue,
        LAG(total_revenue) OVER (ORDER BY revenue_month) AS prev_month_revenue
    FROM monthly_revenue
)
SELECT
    revenue_month,
    total_revenue,
    prev_month_revenue,
    ROUND(
        (total_revenue - prev_month_revenue) / prev_month_revenue * 100, 2
    ) AS revenue_growth_pct
FROM revenue_with_lag
ORDER BY revenue_month;
#__________________________________________________________________________________________________________________________________________________#

#7.Find the day with maximum subscriber gain for each month.
WITH ranked_days AS (
    SELECT
        Date,
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        Subscribers_Gained,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_FORMAT(Date, '%Y-%m')
            ORDER BY Subscribers_Gained DESC
        ) AS rn
    FROM ytdata
)
SELECT
    Date,
    revenue_month,
    Subscribers_Gained
FROM ranked_days
WHERE rn = 1
ORDER BY revenue_month;
#__________________________________________________________________________________________________________________________________________________#

#8.Find the Countries With Revenue Above Monthly Average.
SELECT *
FROM (
    SELECT
        Country,
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY Country, DATE_FORMAT(Date, '%Y-%m')
) AS mcr
WHERE mcr.total_revenue > (
    SELECT AVG(monthly_total)
    FROM (
        SELECT SUM(Revenue) AS monthly_total
        FROM ytdata
        WHERE DATE_FORMAT(Date, '%Y-%m') = mcr.revenue_month
        GROUP BY Country
    ) AS month_avg
)
ORDER BY mcr.revenue_month, mcr.total_revenue DESC;

#9.Find the top 10 Highest Watch Time Days.
SELECT
    Date,
    Country,
    Watch_Time_Hours
FROM ytdata
ORDER BY Watch_Time_Hours DESC
LIMIT 10;
#__________________________________________________________________________________________________________________________________________________#

#10.Find the second Highest Revenue Country.
SELECT
    Country,
    SUM(Revenue) AS total_revenue
FROM ytdata
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 1 OFFSET 1;
#__________________________________________________________________________________________________________________________________________________#

#11.Find the top Device by Revenue in Every Country.
WITH device_revenue AS (
    SELECT
        Country,
        Device,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY Country, Device
),
ranked_devices AS (
    SELECT
        Country,
        Device,
        total_revenue,
        RANK() OVER (PARTITION BY Country ORDER BY total_revenue DESC) AS rnk
    FROM device_revenue
)
SELECT
    Country,
    Device,
    total_revenue
FROM ranked_devices
WHERE rnk = 1
ORDER BY total_revenue DESC;
#__________________________________________________________________________________________________________________________________________________#

#12.Traffic Sources Producing Above Average Subscribers.
SELECT
    Source,
    SUM(Subscribers_Gained) AS total_subscribers
FROM ytdata
GROUP BY Source
HAVING SUM(Subscribers_Gained) > (
    SELECT AVG(source_total)
    FROM (
        SELECT SUM(Subscribers_Gained) AS source_total
        FROM ytdata
        GROUP BY Source
    ) AS source_totals
)
ORDER BY total_subscribers DESC;
#__________________________________________________________________________________________________________________________________________________#

#13.Find the daily Revenue Rank
SELECT
    Date,
    Country,
    Revenue,
    RANK() OVER (ORDER BY Revenue DESC) AS revenue_rank
FROM ytdata
ORDER BY revenue_rank;
#__________________________________________________________________________________________________________________________________________________#

#14.Find the running Total Revenue.
SELECT
    Date,
    Revenue,
    SUM(Revenue) OVER (
        ORDER BY Date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_revenue
FROM ytdata
ORDER BY Date;
#__________________________________________________________________________________________________________________________________________________#

#15.Find the cumulative subscribers.
SELECT
    Date,
    Subscribers_Gained,
    SUM(Subscribers_Gained) OVER (ORDER BY Date) AS cumulative_subscribers
FROM ytdata
ORDER BY Date;
#__________________________________________________________________________________________________________________________________________________#

#16.Find the countries With More Than 10 Revenue Peaks.
SELECT
    Country,
    COUNT(*) AS revenue_peak_days
FROM ytdata
WHERE Revenue > (SELECT AVG(Revenue) FROM ytdata)
GROUP BY Country
HAVING COUNT(*) > 10
ORDER BY revenue_peak_days DESC;
#__________________________________________________________________________________________________________________________________________________#

#17.Find the Highest Revenue Device Per Month.
WITH device_monthly_revenue AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        Device,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY DATE_FORMAT(Date, '%Y-%m'), Device
),
ranked_devices AS (
    SELECT
        revenue_month,
        Device,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY revenue_month
            ORDER BY total_revenue DESC
        ) AS rn
    FROM device_monthly_revenue
)
SELECT
    revenue_month,
    Device,
    total_revenue
FROM ranked_devices
WHERE rn = 1
ORDER BY revenue_month;
#__________________________________________________________________________________________________________________________________________________#

#18.Find the bottom 5 Revenue Countries.
SELECT
    Country,
    SUM(Revenue) AS total_revenue
FROM ytdata
GROUP BY Country
ORDER BY total_revenue ASC
LIMIT 5;
#__________________________________________________________________________________________________________________________________________________#

#19.Find the third Highest Watch Time Country.
SELECT
    Country,
    SUM(Watch_Time_Hours) AS total_watch_time
FROM ytdata
GROUP BY Country
ORDER BY total_watch_time DESC
LIMIT 1 OFFSET 2;
#__________________________________________________________________________________________________________________________________________________#

#20.Find the countries Having Revenue Greater Than Previous Month.
WITH monthly_revenue AS (
    SELECT
        Country,
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY Country, DATE_FORMAT(Date, '%Y-%m')
),
revenue_with_lag AS (
    SELECT
        Country,
        revenue_month,
        total_revenue,
        LAG(total_revenue) OVER (
            PARTITION BY Country
            ORDER BY revenue_month
        ) AS prev_month_revenue
    FROM monthly_revenue
)
SELECT
    Country,
    revenue_month,
    total_revenue,
    prev_month_revenue
FROM revenue_with_lag
WHERE total_revenue > prev_month_revenue
ORDER BY Country, revenue_month;
#__________________________________________________________________________________________________________________________________________________#

#21.Find the top Gender by Revenue Within Each Age Group.
WITH age_gender_revenue AS (
    SELECT
        Age_Group,
        Gender,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY Age_Group, Gender
),
ranked_gender AS (
    SELECT
        Age_Group,
        Gender,
        total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY Age_Group
            ORDER BY total_revenue DESC
        ) AS rnk
    FROM age_gender_revenue
)
SELECT
    Age_Group,
    Gender,
    total_revenue
FROM ranked_gender
WHERE rnk = 1
ORDER BY total_revenue DESC;
#__________________________________________________________________________________________________________________________________________________#

#22.Find the average Revenue Per Device Greater Than Overall Average.
SELECT
    Device,
    AVG(Revenue) AS avg_revenue
FROM ytdata
GROUP BY Device
HAVING AVG(Revenue) > (
    SELECT AVG(Revenue) FROM ytdata
)
ORDER BY avg_revenue DESC;
#__________________________________________________________________________________________________________________________________________________#

#23.Find the top 5 Days With Highest RPM (Revenue Per 1000 Views)
WITH rpm_calc AS (
    SELECT
        Date,
        Country,
        Views,
        Revenue,
        (Revenue / Views) * 1000 AS rpm
    FROM ytdata
)
SELECT
    Date,
    Country,
    Views,
    Revenue,
    rpm
FROM rpm_calc
ORDER BY rpm DESC
LIMIT 5;
#__________________________________________________________________________________________________________________________________________________#

#24.Find the Countries Contributing Top 80% Revenue
WITH country_revenue AS (
    SELECT
        Country,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY Country
),
running AS (
    SELECT
        Country,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS running_total,
        SUM(total_revenue) OVER () AS grand_total
    FROM country_revenue
)
SELECT
    Country,
    total_revenue,
    running_total,
    ROUND(running_total * 100.0 / grand_total, 2) AS cumulative_pct
FROM running
WHERE running_total - total_revenue < grand_total * 0.8
ORDER BY total_revenue DESC;
#__________________________________________________________________________________________________________________________________________________#

#25.Find the rank Traffic Sources by Subscribers.
SELECT
    Source,
    SUM(Subscribers_Gained) AS total_subscribers,
    DENSE_RANK() OVER (ORDER BY SUM(Subscribers_Gained) DESC) AS source_rank
FROM ytdata
GROUP BY Source
ORDER BY source_rank;
#__________________________________________________________________________________________________________________________________________________#

#26.Find the revenue Share Percentage by Country.
WITH country_revenue AS (
    SELECT
        Country,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY Country
)
SELECT
    Country,
    total_revenue,
    ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS revenue_share_pct
FROM country_revenue
ORDER BY revenue_share_pct DESC;
#__________________________________________________________________________________________________________________________________________________#

#27.Find the longest revenue growth streak.
WITH revenue_with_lag AS (
    SELECT
        Date,
        Revenue,
        LAG(Revenue) OVER (ORDER BY Date) AS prev_revenue
    FROM ytdata
),
growth_flag AS (
    SELECT
        Date,
        Revenue,
        CASE WHEN Revenue > prev_revenue THEN 1 ELSE 0 END AS is_growth
    FROM revenue_with_lag
),
streak_groups AS (
    SELECT
        Date,
        is_growth,
        ROW_NUMBER() OVER (ORDER BY Date)
          - ROW_NUMBER() OVER (PARTITION BY is_growth ORDER BY Date) AS streak_id
    FROM growth_flag
),
streak_lengths AS (
    SELECT
        streak_id,
        COUNT(*) AS streak_length,
        MIN(Date) AS streak_start,
        MAX(Date) AS streak_end
    FROM streak_groups
    WHERE is_growth = 1
    GROUP BY streak_id
)
SELECT streak_start, streak_end, streak_length
FROM streak_lengths
ORDER BY streak_length DESC
LIMIT 1;
#__________________________________________________________________________________________________________________________________________________#

#28.Find the months Where Revenue Increased But Views Decreased.
WITH monthly_stats AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        SUM(Revenue) AS total_revenue,
        SUM(Views) AS total_views
    FROM ytdata
    GROUP BY DATE_FORMAT(Date, '%Y-%m')
),
monthly_with_lag AS (
    SELECT
        revenue_month,
        total_revenue,
        total_views,
        LAG(total_revenue) OVER (ORDER BY revenue_month) AS prev_revenue,
        LAG(total_views) OVER (ORDER BY revenue_month) AS prev_views
    FROM monthly_stats
)
SELECT
    revenue_month,
    total_revenue,
    prev_revenue,
    total_views,
    prev_views,
    CASE
        WHEN total_revenue > prev_revenue AND total_views < prev_views
        THEN 'Revenue Increase, Views Decrease'
    END AS trend_flag
FROM monthly_with_lag
WHERE total_revenue > prev_revenue AND total_views < prev_views
ORDER BY revenue_month;
#__________________________________________________________________________________________________________________________________________________#

#29.Find the Highest Revenue Weekend.
WITH weekend_data AS (
    SELECT
        Date,
        Revenue,
        CASE
            WHEN DAYOFWEEK(Date) = 7 THEN Date
            WHEN DAYOFWEEK(Date) = 1 THEN DATE_SUB(Date, INTERVAL 1 DAY)
        END AS saturday_date
    FROM ytdata
    WHERE DAYOFWEEK(Date) IN (1, 7)
)
SELECT
    saturday_date,
    SUM(Revenue) AS total_weekend_revenue
FROM weekend_data
GROUP BY saturday_date
ORDER BY total_weekend_revenue DESC
LIMIT 1;
#__________________________________________________________________________________________________________________________________________________#

#30.Find the countries Having More Than 3 Devices Generating Above Average Revenue
WITH country_device_avg AS (
    SELECT
        Country,
        Device,
        AVG(Revenue) AS avg_device_revenue
    FROM ytdata
    GROUP BY Country, Device
)
SELECT
    Country,
    COUNT(DISTINCT Device) AS devices_above_avg
FROM country_device_avg
WHERE avg_device_revenue > (SELECT AVG(Revenue) FROM ytdata)
GROUP BY Country
HAVING COUNT(DISTINCT Device) > 3
ORDER BY devices_above_avg DESC;
#__________________________________________________________________________________________________________________________________________________#

#31.Find the top 5 Countries by Watch Time Growth
WITH monthly_watch_time AS (
    SELECT
        Country,
        DATE_FORMAT(Date, '%Y-%m') AS watch_month,
        SUM(Watch_Time_Hours) AS total_watch_time
    FROM ytdata
    GROUP BY Country, DATE_FORMAT(Date, '%Y-%m')
),
watch_time_with_lag AS (
    SELECT
        Country,
        watch_month,
        total_watch_time,
        LAG(total_watch_time) OVER (
            PARTITION BY Country
            ORDER BY watch_month
        ) AS prev_watch_time
    FROM monthly_watch_time
)
SELECT
    Country,
    watch_month,
    total_watch_time,
    prev_watch_time,
    ROUND((total_watch_time - prev_watch_time) * 100.0 / prev_watch_time, 2) AS growth_pct
FROM watch_time_with_lag
WHERE prev_watch_time IS NOT NULL
ORDER BY growth_pct DESC
LIMIT 5;
#__________________________________________________________________________________________________________________________________________________#

#32.Find the revenue Leader Among Age Groups
WITH age_revenue AS (
    SELECT
        Age_Group,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY Age_Group
),
ranked_age AS (
    SELECT
        Age_Group,
        total_revenue,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS rn
    FROM age_revenue
)
SELECT
    Age_Group,
    total_revenue
FROM ranked_age
WHERE rn = 1;
#__________________________________________________________________________________________________________________________________________________#

#33.Find the device With Highest Average View Duration
SELECT
    Device,
    AVG(Average_View_duration) AS avg_view_duration
FROM ytdata
GROUP BY Device
ORDER BY avg_view_duration DESC
LIMIT 1;
#__________________________________________________________________________________________________________________________________________________#

#34.Find the Most Profitable Traffic Source Per Month
WITH source_monthly_revenue AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        Source,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY DATE_FORMAT(Date, '%Y-%m'), Source
),
ranked_sources AS (
    SELECT
        revenue_month,
        Source,
        total_revenue,
        RANK() OVER (
            PARTITION BY revenue_month
            ORDER BY total_revenue DESC
        ) AS rnk
    FROM source_monthly_revenue
)
SELECT
    revenue_month,
    Source,
    total_revenue
FROM ranked_sources
WHERE rnk = 1
ORDER BY revenue_month;
#__________________________________________________________________________________________________________________________________________________#

#35.Find the top 2 Countries in Every Month
WITH country_monthly_revenue AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        Country,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY DATE_FORMAT(Date, '%Y-%m'), Country
),
ranked_countries AS (
    SELECT
        revenue_month,
        Country,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY revenue_month
            ORDER BY total_revenue DESC
        ) AS rn
    FROM country_monthly_revenue
)
SELECT
    revenue_month,
    Country,
    total_revenue,
    rn
FROM ranked_countries
WHERE rn <= 2
ORDER BY revenue_month, rn;
#__________________________________________________________________________________________________________________________________________________#

#36.Detect Duplicate Highest Revenue Days
WITH ranked_revenue AS (
    SELECT
        Date,
        Country,
        Revenue,
        DENSE_RANK() OVER (ORDER BY Revenue DESC) AS rnk
    FROM ytdata
)
SELECT
    Date,
    Country,
    Revenue
FROM ranked_revenue
WHERE rnk = 1;
#__________________________________________________________________________________________________________________________________________________#

#37.Find the monthly Revenue Contribution %
WITH monthly_revenue AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY DATE_FORMAT(Date, '%Y-%m')
)
SELECT
    revenue_month,
    total_revenue,
    ROUND(total_revenue * 100.0 / SUM(total_revenue) OVER (), 2) AS revenue_contribution_pct
FROM monthly_revenue
ORDER BY revenue_month;
#__________________________________________________________________________________________________________________________________________________#

#38.Find the Countries With Revenue Growth Above 25%
WITH monthly_revenue AS (
    SELECT
        Country,
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY Country, DATE_FORMAT(Date, '%Y-%m')
),
growth_calc AS (
    SELECT
        Country,
        revenue_month,
        total_revenue,
        LAG(total_revenue) OVER (
            PARTITION BY Country
            ORDER BY revenue_month
        ) AS prev_revenue
    FROM monthly_revenue
)
SELECT
    Country,
    revenue_month,
    total_revenue,
    prev_revenue,
    ROUND((total_revenue - prev_revenue) * 100.0 / prev_revenue, 2) AS growth_pct
FROM growth_calc
WHERE prev_revenue IS NOT NULL
HAVING growth_pct > 25
ORDER BY growth_pct DESC;
#__________________________________________________________________________________________________________________________________________________#

#39.Find the Revenue Distribution Quartiles.
WITH revenue_quartiles AS (
    SELECT
        Date,
        Revenue,
        NTILE(4) OVER (ORDER BY Revenue) AS quartile
    FROM ytdata
)
SELECT
    quartile,
    COUNT(*) AS num_days,
    MIN(Revenue) AS min_revenue,
    MAX(Revenue) AS max_revenue,
    ROUND(AVG(Revenue), 2) AS avg_revenue
FROM revenue_quartiles
GROUP BY quartile
ORDER BY quartile;
#__________________________________________________________________________________________________________________________________________________#

#40.Find the Rank Countries by Subscriber Conversion Rate.
WITH country_stats AS (
    SELECT
        Country,
        SUM(Subscribers_Gained) AS total_subscribers,
        SUM(Views) AS total_views
    FROM ytdata
    GROUP BY Country
),
conversion_calc AS (
    SELECT
        Country,
        total_subscribers,
        total_views,
        ROUND(total_subscribers * 100.0 / total_views, 4) AS conversion_rate_pct
    FROM country_stats
)
SELECT
    Country,
    total_subscribers,
    total_views,
    conversion_rate_pct,
    RANK() OVER (ORDER BY conversion_rate_pct DESC) AS conversion_rank
FROM conversion_calc
ORDER BY conversion_rank;
#__________________________________________________________________________________________________________________________________________________#

#41.Calculate subscriber conversion rate (Subscribers Gained / Views) for each country and rank them
WITH country_stats AS (
    SELECT
        Country,
        SUM(Subscribers_Gained) AS total_subscribers,
        SUM(Views) AS total_views
    FROM ytdata
    GROUP BY Country
),
conversion_calc AS (
    SELECT
        Country,
        total_subscribers,
        total_views,
        ROUND(total_subscribers * 100.0 / total_views, 4) AS conversion_rate_pct
    FROM country_stats
)
SELECT
    Country,
    total_subscribers,
    total_views,
    conversion_rate_pct,
    RANK() OVER (ORDER BY conversion_rate_pct DESC) AS conversion_rank
FROM conversion_calc
ORDER BY conversion_rank;
#__________________________________________________________________________________________________________________________________________________#

#42.Find the Top Revenue Day Per Traffic Source.
WITH ranked_source_days AS (
    SELECT
        Date,
        Source,
        Country,
        Revenue,
        ROW_NUMBER() OVER (
            PARTITION BY Source
            ORDER BY Revenue DESC
        ) AS rn
    FROM ytdata
)
SELECT
    Date,
    Source,
    Country,
    Revenue
FROM ranked_source_days
WHERE rn = 1
ORDER BY Revenue DESC;
#__________________________________________________________________________________________________________________________________________________#

#43.Find the Highest Average Revenue Device in Top 5 Countries
WITH top5_countries AS (
    SELECT Country
    FROM ytdata
    GROUP BY Country
    ORDER BY SUM(Revenue) DESC
    LIMIT 5
),
device_avg_revenue AS (
    SELECT
        Device,
        AVG(Revenue) AS avg_revenue
    FROM ytdata
    WHERE Country IN (SELECT Country FROM top5_countries)
    GROUP BY Device
)
SELECT
    Device,
    avg_revenue
FROM device_avg_revenue
ORDER BY avg_revenue DESC
LIMIT 1;
#__________________________________________________________________________________________________________________________________________________#

#44.Find the Monthly Revenue Leader by Gender
WITH gender_monthly_revenue AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        Gender,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY DATE_FORMAT(Date, '%Y-%m'), Gender
),
ranked_gender AS (
    SELECT
        revenue_month,
        Gender,
        total_revenue,
        RANK() OVER (
            PARTITION BY revenue_month
            ORDER BY total_revenue DESC
        ) AS rnk
    FROM gender_monthly_revenue
)
SELECT
    revenue_month,
    Gender,
    total_revenue
FROM ranked_gender
WHERE rnk = 1
ORDER BY revenue_month;
#__________________________________________________________________________________________________________________________________________________#

#45.Find the Top Revenue Age Group Within Every Device
WITH device_age_revenue AS (
    SELECT
        Device,
        Age_Group,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY Device, Age_Group
),
ranked_age AS (
    SELECT
        Device,
        Age_Group,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY Device
            ORDER BY total_revenue DESC
        ) AS rn
    FROM device_age_revenue
)
SELECT
    Device,
    Age_Group,
    total_revenue
FROM ranked_age
WHERE rn = 1
ORDER BY total_revenue DESC;
#__________________________________________________________________________________________________________________________________________________#

#46.Find the find Days Where Revenue Was More Than Double the Daily Average
SELECT
    Date,
    Country,
    Revenue
FROM ytdata
HAVING Revenue > 2 * (
    SELECT AVG(Revenue) FROM ytdata
)
ORDER BY Revenue DESC;
#__________________________________________________________________________________________________________________________________________________#

#47.Find the Top 10 Most Efficient Days
WITH efficiency_calc AS (
    SELECT
        Date,
        Country,
        Revenue,
        Watch_Time_Hours,
        ROUND(Revenue / Watch_Time_Hours, 2) AS efficiency
    FROM ytdata
)
SELECT
    Date,
    Country,
    Revenue,
    Watch_Time_Hours,
    efficiency
FROM efficiency_calc
ORDER BY efficiency DESC
LIMIT 10;
#__________________________________________________________________________________________________________________________________________________#

#48.Find the Countries Appearing in Top 3 Revenue Rankings for More Than 5 Months.
WITH country_monthly_revenue AS (
    SELECT
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        Country,
        SUM(Revenue) AS total_revenue
    FROM ytdata
    GROUP BY DATE_FORMAT(Date, '%Y-%m'), Country
),
ranked_countries AS (
    SELECT
        revenue_month,
        Country,
        total_revenue,
        DENSE_RANK() OVER (
            PARTITION BY revenue_month
            ORDER BY total_revenue DESC
        ) AS rnk
    FROM country_monthly_revenue
)
SELECT
    Country,
    COUNT(*) AS months_in_top3
FROM ranked_countries
WHERE rnk <= 3
GROUP BY Country
HAVING COUNT(*) > 5
ORDER BY months_in_top3 DESC;
#__________________________________________________________________________________________________________________________________________________#

#49.Find the Complete Executive Performance Report
-- Prepare an executive report showing, for every country:

-- Total Views
-- Total Revenue
-- Total Subscribers
-- Average Watch Time
-- Revenue Rank
-- Revenue Share %
-- Previous Month Revenue
-- Revenue Growth %
-- Running Revenue
-- Top Performing Device
-- Best Traffic Source
WITH country_totals AS (
    SELECT
        Country,
        SUM(Views) AS total_views,
        SUM(Revenue) AS total_revenue,
        SUM(Subscribers_Gained) AS total_subscribers,
        ROUND(AVG(Watch_Time_Hours), 2) AS avg_watch_time
    FROM ytdata
    GROUP BY Country
    HAVING SUM(Revenue) > 0
),

ranked_revenue AS (
    SELECT
        Country,
        total_views,
        total_revenue,
        total_subscribers,
        avg_watch_time,
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        ROUND(total_revenue * 100.0 / (
            SELECT SUM(total_revenue) FROM country_totals
        ), 2) AS revenue_share_pct,
        SUM(total_revenue) OVER (
            ORDER BY total_revenue DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_revenue
    FROM country_totals
),

monthly_country_revenue AS (
    SELECT
        Country,
        DATE_FORMAT(Date, '%Y-%m') AS revenue_month,
        SUM(Revenue) AS monthly_revenue
    FROM ytdata
    GROUP BY Country, DATE_FORMAT(Date, '%Y-%m')
),

monthly_with_lag AS (
    SELECT
        Country,
        revenue_month,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            PARTITION BY Country ORDER BY revenue_month
        ) AS prev_month_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY Country ORDER BY revenue_month DESC
        ) AS rn_latest
    FROM monthly_country_revenue
),

latest_month_growth AS (
    SELECT
        Country,
        monthly_revenue AS latest_month_revenue,
        prev_month_revenue,
        CASE
            WHEN prev_month_revenue IS NULL THEN NULL
            ELSE ROUND((monthly_revenue - prev_month_revenue) * 100.0 / prev_month_revenue, 2)
        END AS revenue_growth_pct
    FROM monthly_with_lag
    WHERE rn_latest = 1
),

device_revenue AS (
    SELECT
        Country,
        Device,
        SUM(Revenue) AS device_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY Country ORDER BY SUM(Revenue) DESC
        ) AS device_rn
    FROM ytdata
    GROUP BY Country, Device
),

top_device AS (
    SELECT Country, Device AS top_device
    FROM device_revenue
    WHERE device_rn = 1
),

source_revenue AS (
    SELECT
        Country,
        Source,
        SUM(Revenue) AS source_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY Country ORDER BY SUM(Revenue) DESC
        ) AS source_rn
    FROM ytdata
    GROUP BY Country, Source
),

best_source AS (
    SELECT Country, Source AS best_source
    FROM source_revenue
    WHERE source_rn = 1
)

SELECT
    r.Country,
    r.total_views,
    r.total_revenue,
    r.total_subscribers,
    r.avg_watch_time,
    r.revenue_rank,
    r.revenue_share_pct,
    lm.prev_month_revenue      AS previous_month_revenue,
    lm.revenue_growth_pct,
    r.running_revenue,
    td.top_device,
    bs.best_source
FROM ranked_revenue AS r
LEFT JOIN latest_month_growth AS lm ON r.Country = lm.Country
LEFT JOIN top_device          AS td ON r.Country = td.Country
LEFT JOIN best_source         AS bs ON r.Country = bs.Country
ORDER BY r.revenue_rank;
#__________________________________________________________________________________________________________________________________________________#

#50.Find the Detect Revenue Outliers
WITH revenue_stats AS (
    SELECT
        AVG(Revenue) AS avg_revenue,
        STDDEV(Revenue) AS stddev_revenue
    FROM ytdata
),
revenue_zscore AS (
    SELECT
        yt.Date,
        yt.Country,
        yt.Revenue,
        ROUND((yt.Revenue - rs.avg_revenue) / rs.stddev_revenue, 2) AS z_score
    FROM ytdata AS yt
    CROSS JOIN revenue_stats AS rs
)
SELECT
    Date,
    Country,
    Revenue,
    z_score
FROM revenue_zscore
WHERE ABS(z_score) > 2
ORDER BY z_score DESC;
#__________________________________________________________________________________________________________________________________________________#
