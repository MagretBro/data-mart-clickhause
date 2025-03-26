# data-mart-clickhause
Key Characteristics of the Data Mart:

- user_type_clean – Grouped user categories: new browser, dropped browser, old active repaid, etc.
- sess_id – Unique session identifier.
- sess_type – Type of session (e.g., old, new old, dropped borrower, etc.).
- sess_start / sess_end – Session start and end times.
- user_id_table / user_id_no_table – User identifiers.
- login_user_id_cnt – Number of users logged in during the session.
- medium, source, browser, country, region – Information about traffic, device, and geographical data.
- active_credit / active_credit_repaid – Flags for active credit and repaid credit status.
- blocked – Flag indicating if the user is blocked.
- s1, s2, s3, terms, dec, mam, scor – Data related to various stages of the registration process.
- loan_detail, PreApprove – Activity metrics for loan details and pre-approval pages.
- credit_cnt1, credit_approved_cnt1, credit_issued_cnt1 – Count of credit applications, approved credits, and issued loans.
- amount, count_days – Total amount and number of days for issued loans.


Основные характеристики витрины:
- user_type_clean – сгруппированные категории пользователей:
- new browser, dropped browser, old active repaid и т.д.
- sess_id – уникальный идентификатор сессии.
- sess_type – тип сессии (old, new old, dropped borrower и т. д.).
- sess_start / sess_end – время начала и окончания сессии.
- user_id_table / user_id_no_table – идентификаторы пользователей.
- login_user_id_cnt – количество пользователей, авторизованных в этой сессии.
- medium, source, browser, country, region – информация о трафике, устройстве и географии.
- active_credit / active_credit_repaid – флаги активного кредита и погашенного кредита.
- blocked – флаг заблокированного пользователя.
- s1, s2, s3, terms, dec, mam, scor – информация о прохождении различных этапов регистрации.
- loan_detail, PreApprove – показатели активности на страницах деталей займа и предварительного одобрения.
- credit_cnt1, credit_approved_cnt1, credit_issued_cnt1 – количество кредитных заявок, одобренных и выданных кредитов.
- amount, count_days – сумма и количество дней по выданным кредитам.
