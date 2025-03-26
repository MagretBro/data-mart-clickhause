

select
if(user_type in ('new browser','dropped browser','dropped user','dropped borrower', 'dropped credit','new old','old new', 'old old','old active repaid'),user_type,'the rest') user_type_clean,
t.*
from
        (
          select
        case
        when sess_type = 'old' then
            case when active_credit = 1 then concat(sess_type," active",if(active_credit_repaid = 1,' repaid',''))
            else 
            concat(sess_type,
            if(old_new in (' old',' new'),old_new,' pending'),
            if(blocked=1,' blocked',''))
            end
        when sess_type in ('new old','dropped credit') then
            case when active_app = 1 then concat(sess_type, ' pending')
            else concat(sess_type,if(blocked=1,' blocked',''))
            end
        else sess_type
        end user_type,
        t.*
        from
                (select
                /*sess_info*/
                sess_id, sess_type, sess_start, sess_end,
                /* user id info */
                user_id_table, min_user_id_field user_id_no_table, min_user_id_field, max_user_id_field,
                null user_id_passport, null user_id_phone, null user_id_email,
                login_user_id_cnt, login_user_id_cnt all_user_id_cnt, name_cnt, cid_cnt,0 cnt_202411,
                /*traffic, landing, device info, geo*/
                medium,source,campaign,cast(null as string) landing_host,cast(null as string) partner,cast(null as string) wmid,device,os,browser,browserVersion,landing,ab_test,cast(null as string) ab_test_202411,country,region,city,
                /* new reg steps*/
                max(if(page in ('Phone_Email', 'step1'), 1, 0)) as s1,
                max(0) as s1sms,
                max(if(page in ('DNI_Passport','step2'), 1, 0)) as s2,
                max(if(page in ('Address','step3'), 1, 0)) as s3,
                max(if(page in ('Calculator','terms'), 1, 0)) as terms,
                max(if(page in ('Decision_Approve','decision'), 1, 0)) as dec,
                max(if(page in ('After_Decision_Dispending_Type','step7'), 1, 0)) as s7,
                max(if(page in ('photo_passport_pop_up','load_passport'),1,0)) passport,
                max(if(page in ('Scoring','scoring') and time>first_s7,1,0)) scor,
                /* old reg steps*/
                max(if(page in ('loan_detail','calculator_lk'),1,0)) loan_detail,
                max(if(page in ('PreApprove','preapprove'),1,0)) PreApprove,
                max(if(page in ('Dispending_Type','step7'), 1, 0)) as mam,
                max(if(page in ('Scoring','scoring'),1,0)) scor_rec,
                max(if(page like '_ecision%',1,0)) dec_rec,
                /* status info */
                max(blocked) blocked,
                if(max(active_credit)=1,0,max(active_app)) active_app,
                max(active_credit) active_credit,
                max(active_credit_repaid) active_credit_repaid,
                case
                  when substr(max(old_new_status),23,length(max(old_new_status))-22) = 'COMPLETED' then ' new'
                  when substr(max(old_new_status),23,length(max(old_new_status))-22) in ('CANCELLED','RETURNED') then ' old'
                  when substr(max(old_new_status),23,length(max(old_new_status))-22) in ('PENDING','PROCESSING') then ' pending'
                  else ''
                end old_new,
                /* sess info*/
                max(sess_applic) sess_with_application,
                max(sess_scoring) sess_with_scoring,
                max(sess_approve) sess_with_approve,
                max(sess_issued) sess_with_issued,
                /* credit cnts*/
                max(credit_cnt1) credit_cnt1,
                max(credit_approved_cnt1) credit_approved_cnt1,
                max(credit_issued_cnt1) credit_issued_cnt1,
                max(amount) amount,
                max(count_days) count_days,
                max(prev_credit_number) prev_credit_number
                from
                  (
                  /* ADD BLOCKED,ACTIVE CREDIT,OLD/NEW, AND APPLICATION INFO AND RESETS LANDING*/
                  select t6.*,
                  if(bl.borrower_id is not null,1,0) blocked,
                  /* active repiad*/
                  if(ca.date_requested is not null,1,0) active_app,
                  if(ca.issued = 1 and ca.date_received<sess_start and sess_type = 'old',1,0) active_credit,
                  if(ca.date_repaid <= sess_end,1,0) active_credit_repaid,
                  /*old new*/
                  concat(cast(c_all.date_requested as string),c_all.status) old_new_status,
                  /* application info*/
                  if(c1.user_id is not null or c2.user_id is not null,1,0) sess_applic,
                  if(c1.scoring = 1 or c2.scoring = 1 ,1,0) sess_scoring,
                  if(c1.approved = 1 or c2.approved = 1,1,0) sess_approve,
                  if(c1.issued = 1 or c2.issued = 1,1,0) sess_issued,
                  /* credit cnts*/
                  count(distinct c1.credit_id) over (partition by new_id,session) credit_cnt1,
                  count(distinct if(c1.approved = 1,c1.credit_id,null)) over (partition by new_id,session) credit_approved_cnt1,
                  count(distinct if(c1.issued = 1,c1.credit_id,null)) over (partition by new_id,session) credit_issued_cnt1,
                  max(if(c1.issued = 1,c1.initial_amount,0)) over (partition by new_id,session) amount,
                  max(if(c1.issued = 1,c1.credit_count_days,0)) over (partition by new_id,session) count_days,
                  max(ifnull(c_all.credit_number,0)) over (partition by new_id,session) prev_credit_number,
                  from
                    (/* FINDS SESS_TYPE*/
                    select
                    t5.*,
                    case
                        when (user_creation_date is null) then concat(if(cs.first_time<t5.sess_start,'dropped','new'),' browser')
                        when (user_creation_date>sess_start) then  concat(if(cs.first_time<t5.sess_start,'dropped','new'),' browser')
                        when (borrower_creation_date is null) then 'dropped user'
                        when borrower_creation_date>sess_start then 'dropped user'
                        when first_app is null then 'dropped borrower'
                        when first_app > sess_start then 'dropped borrower'
                        when first_scoring is null then 'dropped credit'
                        when first_scoring > sess_start then 'dropped credit'
                        when first_loan is null then 'new old'
                        when first_loan > sess_start then 'new old'
                        else 'old'
                    end sess_type
                    from
                      (/*MERGES USER INFO FOR TABLE AND NO TABLE USERS*/
                      select
                      t4.* except(user_creation_date,borrower_creation_date,first_app,first_scor,first_loan,b_ids),
                      ifnull(t4.user_creation_date,c.user_creation_date) user_creation_date,
                      ifnull(t4.borrower_creation_date,c.borrower_creation_date) borrower_creation_date,
                      ifnull(t4.first_app,c.first_app) first_app,
                      ifnull(t4.first_scor,c.first_scoring) first_scoring,
                      ifnull(t4.first_loan,c.first_loan) first_loan,
                      ifnull(b_ids, c.borrower_id) b_ids
                      from
                        (/* ADD USER INFO FOR NO-TABLE USERS, CALCULATES CNTS*/
                        select
                        t3.* except(user_id,medium,source,campaign,country,region,city),
                        /* sess_info*/
                        concat(new_id,'-','{{ ds_nodash }}','-',session) sess_id,
                        min(time) over (partition by new_id, session) sess_start,
                        max(time) over (partition by new_id, session) sess_end,
                        if(c1 is null,if(min(t3.user_id_field) over (partition by clientId, session) is null,'clientId','user_field'),'user_table') user_type,
                        /*user_ids*/
                        t3.user_id user_id_table,
                        min(t3.user_id_field) over (partition by new_id, session) min_user_id_field,
                        max(t3.user_id_field) over (partition by new_id, session) max_user_id_field,
                        /* cnts*/
                        count(distinct t3.user_id_field) over (partition by new_id, session) login_user_id_cnt,
                        count(distinct name) over (partition by new_id, session) name_cnt,
                        count(distinct clientId) over (partition by new_id, session) cid_cnt,
                        /* geo*/
                        first_value(country) over (partition by new_id, session order by time) country,
                        first_value(region) over (partition by new_id, session order by time) region,
                        first_value(city) over (partition by new_id, session order by time) city,
                        /* trafic */
                        first_value(medium) over (partition by new_id, session order by time) medium,
                        first_value(source) over (partition by new_id, session order by time) source,
                        first_value(campaign) over (partition by new_id, session order by time) campaign,
                        first_value(page) over (partition by new_id, session order by time) landing,
                        /* first steps*/
                        min(if(page in ('After_Decision_Dispending_Type','step7'),time,null)) over (partition by new_id, session) first_s7
                        from
                          (/* FINDS SESSION NUMBER*/
                          select
                          t2.*,
                          sum(if(prev_time is null or timestamp_diff(time,prev_time,hour)>5,1,0))
                            over (partition by new_id order by time RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) session
                          from
                            (/* ADD PREV TIME AND ALL NAMES FOR SESSION FOR COUNTING*/
                            select
                            t1.*,
                            lag(time) over (partition by new_id order by time) prev_time,
                            bc.name
                            from
                              (/* COLLECTS RAW DATA AND JOINS CLIENT TYPE*/
                              SELECT
                              user_pseudo_id clientId,
                              timestamp_add(TIMESTAMP_MICROS(event_timestamp), interval 3 hour) time,
                              (select value.string_value from t.event_params where key in ('step_name','value')) page,
                              safe_cast(if(length(t.user_id) >= 7,t.user_id,null) as int64) user_id_field,
                              ifnull(c1,user_pseudo_id) new_id,
                              c.*,
                              /* geo info*/
                              geo.country,geo.region,geo.city,
                              /* traffic info*/
                              traffic_source.medium, traffic_source.source, traffic_source.name campaign,
                              /* device */
                              'ANDROID APP' device, 'ANDROID' os, 'ANDROID APP' browser, cast(null as string) browserVersion,
                              cast(null as string) ab_test
                              FROM `web_adress.analytics_ab_test.events_*` t
                              /* for client type*/
                              left join `web_adress.analytics_ab_test.client_type_{{ ds_nodash }}` c
                              on t.user_pseudo_id = c.cid
                              where _table_suffix = '{{ ds_nodash }}'
                              and  event_name in ('step','visit_screen') and  app_info.id = 'web_adress_ru'
                              and platform = 'ANDROID'
                              order by ifnull(c1,user_pseudo_id),event_date,event_timestamp
                              ) t1
                              /* for names*/
                              left join `web_adress.ln.borrower_creation_date` bc
                              on bc.user_id = t1.user_id_field
                            ) t2
                          ) t3
                        ) t4
                        /* for no_table user info*/
                        left join `web_adress.ln.user_type` c
                        on t4.min_user_id_field = c.user_id and t4.user_type != 'user table'
                      ) t5
                    left join `web_adress.analytics_ab_test.first_client_show` cs
                    on cs.clientId = t5.new_id
                    ) t6
                    /* for blocks*/
                    left join `web_adress.ln.borrower_block` bl
                    on t6.b_ids = bl.borrower_id and t6.sess_start >= bl.block_from and t6.sess_start <= bl.block_to and sess_type in ('new old','old','dropped credit', 'dropped borrower')
                    /* for active credits*/
                    left join `web_adress.ln.credit_received_repaid` ca
                    on t6.b_ids = ca.borrower_id and t6.sess_start >= ca.date_requested and (t6.sess_start <= ca.date_repaid and ca.issued = 1 or t6.sess_start <= timestamp(ca.date_cancel)) and sess_type in ('dropped credit','new old','old')
                    /* for new/old division */
                    left join `web_adress.ln.credits_all` c_all
                    on t6.b_ids = c_all.borrower_id and t6.sess_start>c_all.date_requested and t6.sess_type = 'old'
                    /* for applications during session (min)*/
                    left join `web_adress.ln.credit_received_repaid` c1
                    on t6.min_user_id_field = c1.user_id and t6.sess_start <= timestamp_add(c1.date_requested, interval 5 minute)
                    and timestamp_add(t6.sess_end, interval 5 minute) >= c1.date_requested and c1.ref = 0
                    /* for applications during session (min)*/
                    left join `web_adress.ln.credit_received_repaid` c2
                    on t6.max_user_id_field = c2.user_id and t6.sess_start <= timestamp_add(c2.date_requested, interval 5 minute)
                    and timestamp_add(t6.sess_end, interval 5 minute) >= c2.date_requested and c2.ref = 0
                  ) t7
                group by
                sess_id, sess_type, sess_start, sess_end,
                user_id_table, user_id_no_table, min_user_id_field, max_user_id_field, user_id_passport, user_id_phone, user_id_email,
                login_user_id_cnt, all_user_id_cnt, name_cnt, cid_cnt,cnt_202411,
                medium,source,campaign,device,os,browser,browserVersion,landing,ab_test,ab_test_202411,country,region,city
                ) t
        ) t