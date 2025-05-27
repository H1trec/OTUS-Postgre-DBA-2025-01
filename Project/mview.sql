CREATE MATERIALIZED VIEW cal_month_sales_mv AS
SELECT   t.calendar_month_desc,
            SUM(s.amount_sold) AS dollars
   FROM     sh.sales s,
            sh.times t
   WHERE    s.time_id = t.time_id
   GROUP BY t.calendar_month_desc;


CREATE MATERIALIZED VIEW fweek_pscat_sales_mv AS
SELECT   t.week_ending_day,
            p.prod_subcategory,
            SUM(s.amount_sold) AS dollars,
            s.channel_id,
            s.promo_id
   FROM     sh.sales s,
            sh.times t,
            sh.products p
   WHERE    s.time_id = t.time_id
      AND   s.prod_id = p.prod_id
   GROUP BY t.week_ending_day,
            p.prod_subcategory,
            s.channel_id,
            s.promo_id;
CREATE INDEX fw_psc_s_mv_chan_bix ON fweek_pscat_sales_mv (channel_id);
CREATE INDEX fw_psc_s_mv_promo_bix ON fweek_pscat_sales_mv (promo_id);
CREATE INDEX fw_psc_s_mv_subcat_bix ON fweek_pscat_sales_mv (prod_subcategory);
CREATE INDEX fw_psc_s_mv_wd_bix ON fweek_pscat_sales_mv (week_ending_day);

