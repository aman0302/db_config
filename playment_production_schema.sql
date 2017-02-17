--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: hstore; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS hstore WITH SCHEMA public;


--
-- Name: EXTENSION hstore; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION hstore IS 'data type for storing sets of (key, value) pairs';


--
-- Name: tablefunc; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS tablefunc WITH SCHEMA public;


--
-- Name: EXTENSION tablefunc; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION tablefunc IS 'functions that manipulate whole tables, including crosstab';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


SET search_path = public, pg_catalog;

--
-- Name: datediff(character varying, timestamp with time zone, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION datediff(units character varying, start_t timestamp with time zone, end_t timestamp with time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $$
   DECLARE
     diff_interval INTERVAL; 
     diff INT = 0;
     years_diff INT = 0;
   BEGIN
     IF units IN ('yy', 'yyyy', 'year', 'mm', 'm', 'month') THEN
       years_diff = DATE_PART('year', end_t) - DATE_PART('year', start_t);
 
       IF units IN ('yy', 'yyyy', 'year') THEN
         -- SQL Server does not count full years passed (only difference between year parts)
         RETURN years_diff;
       ELSE
         -- If end month is less than start month it will subtracted
         RETURN years_diff * 12 + (DATE_PART('month', end_t) - DATE_PART('month', start_t)); 
       END IF;
     END IF;
 
     -- Minus operator returns interval 'DDD days HH:MI:SS'  
     diff_interval = end_t - start_t;
 
     diff = diff + DATE_PART('day', diff_interval);
 
     IF units IN ('wk', 'ww', 'week') THEN
       diff = diff/7;
       RETURN diff;
     END IF;
 
     IF units IN ('dd', 'd', 'day') THEN
       RETURN diff;
     END IF;
 
     diff = diff * 24 + DATE_PART('hour', diff_interval); 
 
     IF units IN ('hh', 'hour') THEN
        RETURN diff;
     END IF;
 
     diff = diff * 60 + DATE_PART('minute', diff_interval);
 
     IF units IN ('mi', 'n', 'minute') THEN
        RETURN diff;
     END IF;
 
     diff = diff * 60 + DATE_PART('second', diff_interval);
 
     RETURN diff;
   END;
$$;


--
-- Name: getlastxminquestionsubmissions(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION getlastxminquestionsubmissions(xmin integer) RETURNS TABLE(question_id uuid, options text, submission_count integer, micro_task_id uuid, meta_data jsonb)
    LANGUAGE plpgsql
    AS $$
                                    BEGIN

                                    RETURN QUERY

                                    select qss.question_id , string_agg(qss.body::text, ';') , cast(count(*) as integer) as submission_count , l.micro_task_id, l.meta_data from question_submissions qss
				                            inner join mission_submissions ms on ms.id = qss.mission_submission_id
                                    inner join
                                    (
                                    select qs.question_id , mtq.micro_task_id, mt.meta_data ,
                                    case when mt.meta_data->>'only_count_successful_submissions' = 'true' then true else false end as onlyCountSuccessfulSubmissions
                                    from question_submissions qs
                                    inner join questions q on q.id = qs.question_id
                                    inner join micro_task_question_associators mtq on mtq.question_id = q.id
                                    inner join micro_tasks mt on mt.id = mtq.micro_task_id
                                    where qs.created_at > (now() - (xmin||' minute')::interval)
                                    and (qs.is_test = 'false' or qs.is_test is null)
                                    and (q.is_test = 'false' or q.is_test is NULL)
                                    and q.is_active = 'true'
                                    group by qs.question_id, mtq.micro_task_id,  mt.meta_data

                                    ) l on l.question_id = qss.question_id
                                    where
                                    (is_test = 'false' or is_test is null)
                                    and ((l.onlyCountSuccessfulSubmissions AND ms.status = 1 )
                                    or
                                    ( NOT l.onlyCountSuccessfulSubmissions ))
                                    group by qss.question_id, l.micro_task_id, l.meta_data;
                                    END
                          $$;


--
-- Name: getlastxminquestionsubmissionstemp(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION getlastxminquestionsubmissionstemp(xmin integer) RETURNS TABLE(question_id uuid, options text, submission_count integer, micro_task_id uuid, meta_data jsonb)
    LANGUAGE plpgsql
    AS $$
                                    BEGIN

                                    RETURN QUERY

                                    select qss.question_id , string_agg(qss.body::text, ';') , cast(count(*) as integer) as submission_count , l.micro_task_id, l.meta_data from question_submissions qss
				                            inner join mission_submissions ms on ms.id = qss.mission_submission_id
                                    inner join
                                    (
                                    select qs.question_id , mtq.micro_task_id, mt.meta_data ,
                                    case when mt.meta_data->>'only_count_successful_submissions' = 'true' then true else false end as onlyCountSuccessfulSubmissions
                                    from question_submissions qs
                                    inner join questions q on q.id = qs.question_id
                                    inner join micro_task_question_associators mtq on mtq.question_id = q.id
                                    inner join micro_tasks mt on mt.id = mtq.micro_task_id
                                    left outer join question_answer qa on qa.question_id = q.id
                                    AND qa.micro_task_id = mt.id
                                    where qs.created_at > (now() - (xmin||' minute')::interval)
                                    and (qs.is_test = 'false' or qs.is_test is null)
                                    and (q.is_test = 'false' or q.is_test is NULL)
                                    and qa.id is null
                                    group by qs.question_id, mtq.micro_task_id,  mt.meta_data

                                    ) l on l.question_id = qss.question_id
                                    where
                                    (is_test = 'false' or is_test is null)
                                    and ((l.onlyCountSuccessfulSubmissions AND ms.status = 1 )
                                    or
                                    ( NOT l.onlyCountSuccessfulSubmissions ))
                                    group by qss.question_id, l.micro_task_id, l.meta_data;
                                    END
                          $$;


--
-- Name: getmicrotasksforuser(uuid); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION getmicrotasksforuser(userid uuid) RETURNS TABLE(id uuid, name character varying, label character varying, description text, meta_data jsonb, test_question_count integer, test_question_submission_count integer, todays_mission_submission_count integer, daily_limit integer, points integer, power integer)
    LANGUAGE plpgsql
    AS $_$
                  BEGIN

                  DROP TABLE IF EXISTS daily_mission_submission_group;
                  DROP TABLE IF EXISTS test_question_remaining_group;

                  CREATE TEMP TABLE daily_mission_submission_group as
                  select mt.id as micro_task_id , cast(count(ms.id) as integer) as todays_mission_submission_count , cast (mt.meta_data->>'daily_limit' as integer) as daily_limit ,
                  max(r.points) as points,
                  max(r.power) as power
                  from micro_tasks mt
                  left outer join missions m on m.micro_task_id = mt.id  and m.user_id = $1
                  left outer join mission_submissions ms on  ms.mission_id = m.id and ms.created_at > date_trunc('day', now())
                  left outer join micro_task_reward_associators mtr on mtr.micro_task_id = mt.id
                  left outer join rewards r on r.id = mtr.reward_id
                  where ((mt.is_deleted = 'false' and mt.is_active = 'true' and mt.type = 1)
                  AND exists (select 1 from tags_micro_task_group
                    where
                    micro_task_id =  mt.id
                    AND
                    (( tag_value = '*' AND tag_name = 'USERID') OR
                    ( tag_value = $1::text AND tag_name = 'USERID'))
                    limit 1
                    ) is TRUE
                    )
                  group by mt.id;

                  CREATE TEMP TABLE test_question_remaining_group as
                  select mt.id as id,  mt.name, mt.label, mt.description, mt.meta_data,
                  cast(count(q.id) as integer) as test_question_count, cast(count(qs.id) as integer) as test_question_submission_count
                  from micro_tasks mt
                  inner join micro_task_question_associators mtqa on mtqa.micro_task_id = mt.id
                  inner join questions q on q.id = mtqa.question_id and q.is_test = 'true' AND q.is_active = 'true'
                  left outer join question_submissions qs on qs.question_id = q.id and qs.user_id = $1
                  and qs.is_test = 'false'
                  where ((mt.is_deleted = 'false' and mt.is_active = 'true' and mt.type = 1)
                  AND exists (select 1 from tags_micro_task_group
                    where
                    micro_task_id =  mt.id
                    AND
                    (( tag_value = '*' AND tag_name = 'USERID') OR
                    ( tag_value = $1::text AND tag_name = 'USERID'))
                    limit 1
                    ) is TRUE
                    )
                  OR
                  (mt.is_deleted = 'false' and EXISTS (select 1 from user_role_associators ur where ur.role_id = (select r.id from roles r where r.label = 'admin')
			              and ur.user_id = $1 limit 1
                  ))
                  group by mt.id;

                  RETURN QUERY
                  select tqrg.* , dmsg.todays_mission_submission_count, dmsg.daily_limit, dmsg.points, dmsg.power  from test_question_remaining_group tqrg
                  left outer join daily_mission_submission_group dmsg on tqrg.id = dmsg.micro_task_id
                  where dmsg.micro_task_id not in
                  (select u.micro_task_id from user_micro_task_blocker u
                  where user_id = $1 and DATE_PART('day', current_date - created_at) < unblock_after_days);

                  drop table test_question_remaining_group;
                  drop table daily_mission_submission_group;
                          END
                          $_$;


--
-- Name: json_object_del_key(json, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION json_object_del_key(json json, key_to_del text) RETURNS json
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
SELECT CASE
  WHEN ("json" -> "key_to_del") IS NULL THEN "json"
  ELSE (SELECT concat('{', string_agg(to_json("key") || ':' || "value", ','), '}')
          FROM (SELECT *
                  FROM json_each("json")
                 WHERE "key" <> "key_to_del"
               ) AS "fields")::json
END
$$;


--
-- Name: json_object_set_key(json, text, anyelement); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION json_object_set_key(json json, key_to_set text, value_to_set anyelement) RETURNS json
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
SELECT concat('{', string_agg(to_json("key") || ':' || "value", ','), '}')::json
  FROM (SELECT *
          FROM json_each("json")
         WHERE "key" <> "key_to_set"
         UNION ALL
        SELECT "key_to_set", to_json("value_to_set")) AS "fields"
$$;


--
-- Name: json_object_set_key(jsonb, text, anyelement); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION json_object_set_key(json jsonb, key_to_set text, value_to_set anyelement) RETURNS json
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
SELECT concat('{', string_agg(to_json("key") || ':' || "value", ','), '}')::json
  FROM (SELECT *
          FROM json_each("json")
         WHERE "key" <> "key_to_set"
         UNION ALL
        SELECT "key_to_set", to_json("value_to_set")) AS "fields"
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: availabilities; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE availabilities (
    id uuid NOT NULL,
    entity_id uuid,
    entity_type character varying(255),
    activated_at timestamp with time zone,
    activator_id uuid,
    activator_type character varying(255),
    deactivated_at timestamp with time zone,
    deactivator_id uuid,
    deactivator_type character varying(255)
);


--
-- Name: batch_process; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE batch_process (
    id uuid NOT NULL,
    name character varying(255),
    done boolean DEFAULT false,
    aborted boolean DEFAULT false,
    completion integer,
    type integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    macro_task_id uuid NOT NULL
);


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE clients (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_secret_uuid uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    options jsonb DEFAULT '{}'::jsonb NOT NULL
);


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE comments (
    id uuid NOT NULL,
    creator_id uuid,
    body character varying(255),
    entity_id uuid,
    entity_type character varying(255),
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: contact_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE contact_requests (
    id uuid NOT NULL,
    user_id uuid,
    email character varying(255),
    name character varying(255),
    subject character varying(255),
    message text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: coupon_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE coupon_transactions (
    id uuid NOT NULL,
    coupon_id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    count integer DEFAULT 0 NOT NULL,
    is_served boolean DEFAULT false,
    served_at timestamp with time zone,
    served_by uuid,
    email_id character varying(255),
    transaction_details jsonb,
    mobile_no character varying(255),
    is_reverted boolean DEFAULT false
);


--
-- Name: coupons; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE coupons (
    id uuid NOT NULL,
    points integer DEFAULT 10 NOT NULL,
    times_redeemed integer DEFAULT 0 NOT NULL,
    integration_provider_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    quantity integer DEFAULT 0 NOT NULL,
    is_hidden boolean DEFAULT false NOT NULL
);


--
-- Name: cron_job_configurations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE cron_job_configurations (
    id integer NOT NULL,
    emails character varying(255),
    time_configuration character varying(255),
    subject character varying(255),
    is_active boolean DEFAULT false,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: cron_job_configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE cron_job_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: cron_job_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE cron_job_configurations_id_seq OWNED BY cron_job_configurations.id;


--
-- Name: crowdsourcing_flu_buffer; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE crowdsourcing_flu_buffer (
    id uuid NOT NULL,
    flu_id uuid NOT NULL,
    question_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    is_deleted boolean DEFAULT false
);


--
-- Name: crowdsourcing_step_configuration; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE crowdsourcing_step_configuration (
    id uuid NOT NULL,
    step_id uuid,
    micro_task_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: emails; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE emails (
    id uuid NOT NULL,
    email character varying(255),
    user_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: external_accounts; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE external_accounts (
    id uuid NOT NULL,
    integration_provider_id uuid NOT NULL,
    email_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    profile_info jsonb,
    external_id character varying(255),
    user_id uuid
);


--
-- Name: feed_line; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feed_line (
    id uuid NOT NULL,
    reference_id character varying(255),
    data jsonb,
    tag character varying(255),
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    step_id uuid,
    build jsonb,
    project_id uuid NOT NULL
);


--
-- Name: feed_line_log; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feed_line_log (
    id integer NOT NULL,
    flu_id uuid NOT NULL,
    message character varying(255),
    meta_data jsonb,
    step_type integer,
    step_id uuid,
    created_at timestamp with time zone DEFAULT now(),
    step_entry boolean,
    step_exit boolean,
    work_flow_id uuid
);


--
-- Name: feed_line_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE feed_line_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feed_line_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE feed_line_log_id_seq OWNED BY feed_line_log.id;


--
-- Name: feedbacks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE feedbacks (
    id uuid NOT NULL,
    subject character varying(255) NOT NULL,
    user_id uuid,
    body text,
    "from" character varying(255) NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: force_update_app; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE force_update_app (
    id uuid NOT NULL,
    message character varying(255) NOT NULL,
    optional_min character varying(255),
    optional_max character varying(255),
    mandatory_min character varying(255),
    mandatory_max character varying(255),
    is_active boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: grammar_elements; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE grammar_elements (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    label character varying(255) NOT NULL,
    input_template jsonb,
    grammar_version character varying(255),
    is_deleted boolean DEFAULT false NOT NULL,
    description character varying(255) NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: image_dictionary; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE image_dictionary (
    id uuid NOT NULL,
    real_url character varying(255) NOT NULL,
    cloud_url character varying(255) NOT NULL,
    extra character varying(255),
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: input_flu_validator; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE input_flu_validator (
    id uuid NOT NULL,
    field_name character varying(255) NOT NULL,
    type character varying(255) NOT NULL,
    is_mandatory boolean DEFAULT true,
    tag character varying(255) NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    project_id uuid NOT NULL
);


--
-- Name: integration_providers; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE integration_providers (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    label character varying(255) NOT NULL,
    website character varying(255) NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    logo_url character varying(255)
);


--
-- Name: invitation_requests; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE invitation_requests (
    id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email character varying(255),
    user_id uuid
);


--
-- Name: knex_migrations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE knex_migrations (
    id integer NOT NULL,
    name character varying(255),
    batch integer,
    migration_time timestamp with time zone
);


--
-- Name: knex_migrations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE knex_migrations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: knex_migrations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE knex_migrations_id_seq OWNED BY knex_migrations.id;


--
-- Name: knex_migrations_lock; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE knex_migrations_lock (
    is_locked integer
);


--
-- Name: logic_gate; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE logic_gate (
    id uuid NOT NULL,
    input_template jsonb,
    formula integer NOT NULL
);


--
-- Name: logic_gate_formula; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE logic_gate_formula (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: macro_tasks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE macro_tasks (
    id uuid NOT NULL,
    label character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    project_id uuid NOT NULL,
    creator_id uuid NOT NULL
);


--
-- Name: micro_task_batches; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE micro_task_batches (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    micro_task_id uuid NOT NULL,
    batch_id integer NOT NULL,
    is_finished boolean DEFAULT false,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: micro_task_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE micro_task_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: micro_task_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE micro_task_batches_id_seq OWNED BY micro_task_batches.id;


--
-- Name: micro_task_question_associators; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE micro_task_question_associators (
    id uuid NOT NULL,
    micro_task_id uuid NOT NULL,
    question_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: micro_task_question_associators_dump; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE micro_task_question_associators_dump (
    id uuid,
    micro_task_id uuid,
    question_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: micro_task_resource_associators; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE micro_task_resource_associators (
    resource_id uuid NOT NULL,
    micro_task_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    id uuid NOT NULL
);


--
-- Name: micro_task_reward_associators; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE micro_task_reward_associators (
    id uuid NOT NULL,
    micro_task_id uuid NOT NULL,
    reward_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: micro_task_type; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE micro_task_type (
    id integer NOT NULL,
    name character varying(255) NOT NULL
);


--
-- Name: micro_tasks; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE micro_tasks (
    id uuid NOT NULL,
    macro_task_id uuid NOT NULL,
    creator_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name character varying(255) NOT NULL,
    label character varying(255) NOT NULL,
    description text,
    meta_data jsonb,
    duration integer,
    power integer,
    points integer,
    is_deleted boolean DEFAULT false,
    is_active boolean DEFAULT true,
    fallback_micro_task_id uuid,
    type integer,
    expired_at timestamp with time zone NOT NULL
);


--
-- Name: mission_batch_question_associators; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mission_batch_question_associators (
    id integer NOT NULL,
    mission_batch_id integer NOT NULL,
    question_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    is_active boolean DEFAULT true,
    counter integer DEFAULT 0,
    sub_counter integer DEFAULT 0
);


--
-- Name: mission_batch_question_associators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mission_batch_question_associators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mission_batch_question_associators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mission_batch_question_associators_id_seq OWNED BY mission_batch_question_associators.id;


--
-- Name: mission_batches; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mission_batches (
    id integer NOT NULL,
    micro_task_id uuid NOT NULL,
    is_active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: mission_batches_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE mission_batches_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mission_batches_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE mission_batches_id_seq OWNED BY mission_batches.id;


--
-- Name: mission_question_associators; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mission_question_associators (
    mission_id uuid NOT NULL,
    question_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    id uuid NOT NULL
);


--
-- Name: mission_question_associators_dump; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mission_question_associators_dump (
    mission_id uuid,
    question_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    id uuid
);


--
-- Name: mission_submissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mission_submissions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    mission_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    correct_test_question_count integer,
    incorrect_test_question_count integer,
    status integer DEFAULT 0 NOT NULL
);


--
-- Name: mission_submissions_dump; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE mission_submissions_dump (
    id uuid,
    user_id uuid,
    mission_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    correct_test_question_count integer,
    incorrect_test_question_count integer,
    status integer
);


--
-- Name: missions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE missions (
    id uuid NOT NULL,
    user_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    micro_task_id uuid,
    ui_template_id uuid,
    submission_template_id uuid,
    duration integer,
    power integer,
    points integer,
    guidelines_id uuid,
    instructions_id uuid,
    mission_batch_id integer
);


--
-- Name: missions_dump; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE missions_dump (
    id uuid,
    user_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    micro_task_id uuid,
    ui_template_id uuid,
    submission_template_id uuid,
    duration integer,
    power integer,
    points integer,
    guidelines_id uuid,
    instructions_id uuid,
    mission_batch_id integer
);


--
-- Name: notification_recipient_associators; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notification_recipient_associators (
    id uuid NOT NULL,
    recipient_id uuid NOT NULL,
    notification_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    is_read boolean
);


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE notifications (
    id uuid NOT NULL,
    message text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE permissions (
    id uuid NOT NULL,
    role_id uuid NOT NULL,
    permission character varying(255),
    entity_type character varying(255) NOT NULL,
    entity_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: point_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE point_transactions (
    id uuid NOT NULL,
    reward_transaction_id uuid,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    amount_credited integer
);


--
-- Name: power_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE power_transactions (
    id uuid NOT NULL,
    reward_transaction_id uuid,
    amount_credited integer,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: project_configuration; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE project_configuration (
    project_id uuid NOT NULL,
    post_back_url character varying(255) NOT NULL,
    headers jsonb NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    options jsonb
);


--
-- Name: projects; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE projects (
    id uuid NOT NULL,
    label character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    client_id uuid,
    creator_id uuid NOT NULL,
    started_at timestamp with time zone,
    ended_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: query_configurations; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE query_configurations (
    id integer NOT NULL,
    cron_job_id integer,
    query text NOT NULL,
    body text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: query_configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE query_configurations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: query_configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE query_configurations_id_seq OWNED BY query_configurations.id;


--
-- Name: question_answer; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE question_answer (
    id uuid NOT NULL,
    question_id uuid NOT NULL,
    micro_task_id uuid NOT NULL,
    body jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: question_submission_dump; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE question_submission_dump (
    id uuid,
    user_id uuid,
    mission_submission_id uuid,
    question_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    confidence integer,
    is_test boolean,
    body jsonb,
    status integer
);


--
-- Name: question_submission_dump2; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE question_submission_dump2 (
    id uuid,
    user_id uuid,
    mission_submission_id uuid,
    question_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    confidence integer,
    is_test boolean,
    body jsonb,
    status integer
);


--
-- Name: question_submissions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE question_submissions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    mission_submission_id uuid,
    question_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    confidence integer,
    is_test boolean DEFAULT false NOT NULL,
    body jsonb,
    status integer DEFAULT 0 NOT NULL
);


--
-- Name: questions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE questions (
    id uuid NOT NULL,
    body jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    label character varying(255) NOT NULL,
    is_test boolean,
    creator_id uuid,
    is_active boolean DEFAULT true,
    is_active_fallback boolean
);


--
-- Name: questions_dump; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE questions_dump (
    id uuid,
    body jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    label character varying(255),
    is_test boolean,
    creator_id uuid,
    is_active boolean
);


--
-- Name: resources; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE resources (
    id uuid NOT NULL,
    body text,
    body_type character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    label character varying(255) NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    creator_id uuid NOT NULL
);


--
-- Name: reward_transactions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE reward_transactions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    reward_id uuid NOT NULL,
    mission_id uuid,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: rewards; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE rewards (
    id uuid NOT NULL,
    points integer NOT NULL,
    power integer NOT NULL,
    creator_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE roles (
    id uuid NOT NULL,
    name character varying(255) NOT NULL,
    label character varying(255) NOT NULL,
    approval_strategy integer NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: routes; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE routes (
    id uuid NOT NULL,
    step_id uuid,
    logic_gate_id uuid,
    next_step_id uuid,
    is_deleted boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: step; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE step (
    id uuid NOT NULL,
    type integer NOT NULL,
    work_flow_id uuid,
    is_deleted boolean DEFAULT false,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    is_start boolean DEFAULT false NOT NULL
);


--
-- Name: step_type; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE step_type (
    id integer NOT NULL,
    name character varying(255)
);


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    id uuid,
    name character varying(255) NOT NULL,
    value character varying(255) NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL
);


--
-- Name: tags_micro_task_group; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE tags_micro_task_group (
    id uuid,
    tag_name character varying(255) NOT NULL,
    tag_value character varying(255) NOT NULL,
    micro_task_id uuid NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    expired_at timestamp with time zone NOT NULL
);


--
-- Name: task; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE task (
    id uuid NOT NULL,
    is_active boolean DEFAULT false,
    is_deleted boolean DEFAULT false,
    macro_task_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: temp; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE temp (
    question_id uuid,
    test_question_body jsonb
);


--
-- Name: test_questions; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE test_questions (
    id integer NOT NULL,
    question_id uuid NOT NULL,
    micro_task_id uuid NOT NULL,
    answer_body jsonb,
    is_active boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: test_questions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE test_questions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: test_questions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE test_questions_id_seq OWNED BY test_questions.id;


--
-- Name: transformation_step_configuration; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE transformation_step_configuration (
    id integer NOT NULL,
    step_id uuid NOT NULL,
    template_id character varying(255) NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: transformation_step_configuration_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE transformation_step_configuration_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: transformation_step_configuration_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE transformation_step_configuration_id_seq OWNED BY transformation_step_configuration.id;


--
-- Name: user_activity; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_activity (
    id uuid NOT NULL,
    user_id uuid,
    type integer NOT NULL,
    body jsonb NOT NULL,
    is_deleted boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    is_read boolean DEFAULT false
);


--
-- Name: user_micro_task_blocker; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_micro_task_blocker (
    id uuid NOT NULL,
    user_id uuid,
    micro_task_id uuid,
    unblock_after_days integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: user_mission_batch_associators; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_mission_batch_associators (
    id integer NOT NULL,
    user_id uuid NOT NULL,
    mission_batch_id integer NOT NULL,
    is_finished boolean DEFAULT false,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    finished_at timestamp with time zone
);


--
-- Name: user_mission_batch_associators_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE user_mission_batch_associators_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_mission_batch_associators_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE user_mission_batch_associators_id_seq OWNED BY user_mission_batch_associators.id;


--
-- Name: user_role_associators; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE user_role_associators (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    role_id uuid NOT NULL,
    approved_at timestamp with time zone,
    approval_strategy integer NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: users; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE users (
    id uuid NOT NULL,
    username character varying(255) NOT NULL,
    password character varying(255),
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    gender character varying(1),
    first_name character varying(255),
    last_name character varying(255),
    locale character varying(255),
    avatar_url character varying(255),
    incorrect_questions_count integer DEFAULT 0 NOT NULL,
    correct_questions_count integer DEFAULT 0 NOT NULL,
    pending_questions_count integer DEFAULT 0 NOT NULL,
    coins_count integer DEFAULT 0 NOT NULL,
    current_power integer DEFAULT 0 NOT NULL,
    coupon_redeemed_count integer DEFAULT 0 NOT NULL,
    phone character varying(255),
    total_coins_count integer DEFAULT 0 NOT NULL
);


--
-- Name: work_flow; Type: TABLE; Schema: public; Owner: -; Tablespace: 
--

CREATE TABLE work_flow (
    id uuid NOT NULL,
    project_id uuid NOT NULL,
    is_deleted boolean DEFAULT false,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY cron_job_configurations ALTER COLUMN id SET DEFAULT nextval('cron_job_configurations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY feed_line_log ALTER COLUMN id SET DEFAULT nextval('feed_line_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY knex_migrations ALTER COLUMN id SET DEFAULT nextval('knex_migrations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_task_batches ALTER COLUMN id SET DEFAULT nextval('micro_task_batches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mission_batch_question_associators ALTER COLUMN id SET DEFAULT nextval('mission_batch_question_associators_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY mission_batches ALTER COLUMN id SET DEFAULT nextval('mission_batches_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY query_configurations ALTER COLUMN id SET DEFAULT nextval('query_configurations_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY test_questions ALTER COLUMN id SET DEFAULT nextval('test_questions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY transformation_step_configuration ALTER COLUMN id SET DEFAULT nextval('transformation_step_configuration_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_mission_batch_associators ALTER COLUMN id SET DEFAULT nextval('user_mission_batch_associators_id_seq'::regclass);


--
-- Name: availabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY availabilities
    ADD CONSTRAINT availabilities_pkey PRIMARY KEY (id);


--
-- Name: batch_process_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY batch_process
    ADD CONSTRAINT batch_process_pkey PRIMARY KEY (id);


--
-- Name: clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (id);


--
-- Name: clients_user_id_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY clients
    ADD CONSTRAINT clients_user_id_unique UNIQUE (user_id);


--
-- Name: comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: contact_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contact_requests
    ADD CONSTRAINT contact_requests_pkey PRIMARY KEY (id);


--
-- Name: coupon_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY coupon_transactions
    ADD CONSTRAINT coupon_transactions_pkey PRIMARY KEY (id);


--
-- Name: coupons_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY coupons
    ADD CONSTRAINT coupons_pkey PRIMARY KEY (id);


--
-- Name: cron_job_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY cron_job_configurations
    ADD CONSTRAINT cron_job_configurations_pkey PRIMARY KEY (id);


--
-- Name: crowdsourcing_flu_buffer_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY crowdsourcing_flu_buffer
    ADD CONSTRAINT crowdsourcing_flu_buffer_pkey PRIMARY KEY (id);


--
-- Name: crowdsourcing_step_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY crowdsourcing_step_configuration
    ADD CONSTRAINT crowdsourcing_step_configuration_pkey PRIMARY KEY (id);


--
-- Name: crowdsourcing_step_configuration_step_id_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY crowdsourcing_step_configuration
    ADD CONSTRAINT crowdsourcing_step_configuration_step_id_unique UNIQUE (step_id);


--
-- Name: emails_email_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY emails
    ADD CONSTRAINT emails_email_unique UNIQUE (email);


--
-- Name: emails_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY emails
    ADD CONSTRAINT emails_pkey PRIMARY KEY (id);


--
-- Name: external_accounts_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY external_accounts
    ADD CONSTRAINT external_accounts_pkey PRIMARY KEY (id);


--
-- Name: feed_line_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feed_line_log
    ADD CONSTRAINT feed_line_log_pkey PRIMARY KEY (id);


--
-- Name: feed_line_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feed_line
    ADD CONSTRAINT feed_line_pkey PRIMARY KEY (id);


--
-- Name: feed_line_reference_id_project_id_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feed_line
    ADD CONSTRAINT feed_line_reference_id_project_id_unique UNIQUE (reference_id, project_id);


--
-- Name: feedbacks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY feedbacks
    ADD CONSTRAINT feedbacks_pkey PRIMARY KEY (id);


--
-- Name: force_update_app_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY force_update_app
    ADD CONSTRAINT force_update_app_pkey PRIMARY KEY (id);


--
-- Name: grammar_elements_label_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY grammar_elements
    ADD CONSTRAINT grammar_elements_label_unique UNIQUE (label);


--
-- Name: grammar_elements_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY grammar_elements
    ADD CONSTRAINT grammar_elements_pkey PRIMARY KEY (id);


--
-- Name: image_dictionary_cloud_url_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY image_dictionary
    ADD CONSTRAINT image_dictionary_cloud_url_unique UNIQUE (cloud_url);


--
-- Name: image_dictionary_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY image_dictionary
    ADD CONSTRAINT image_dictionary_pkey PRIMARY KEY (id);


--
-- Name: image_dictionary_real_url_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY image_dictionary
    ADD CONSTRAINT image_dictionary_real_url_unique UNIQUE (real_url);


--
-- Name: input_flu_validator_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY input_flu_validator
    ADD CONSTRAINT input_flu_validator_pkey PRIMARY KEY (id);


--
-- Name: integration_providers_label_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY integration_providers
    ADD CONSTRAINT integration_providers_label_unique UNIQUE (label);


--
-- Name: integration_providers_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY integration_providers
    ADD CONSTRAINT integration_providers_pkey PRIMARY KEY (id);


--
-- Name: invitation_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY invitation_requests
    ADD CONSTRAINT invitation_requests_pkey PRIMARY KEY (id);


--
-- Name: knex_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY knex_migrations
    ADD CONSTRAINT knex_migrations_pkey PRIMARY KEY (id);


--
-- Name: logic_gate_formula_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY logic_gate_formula
    ADD CONSTRAINT logic_gate_formula_pkey PRIMARY KEY (id);


--
-- Name: logic_gate_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY logic_gate
    ADD CONSTRAINT logic_gate_pkey PRIMARY KEY (id);


--
-- Name: macro_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY macro_tasks
    ADD CONSTRAINT macro_tasks_pkey PRIMARY KEY (id);


--
-- Name: micro_task_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY micro_task_batches
    ADD CONSTRAINT micro_task_batches_pkey PRIMARY KEY (id);


--
-- Name: micro_task_question_associators_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY micro_task_question_associators
    ADD CONSTRAINT micro_task_question_associators_pkey PRIMARY KEY (id);


--
-- Name: micro_task_resource_associators_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY micro_task_resource_associators
    ADD CONSTRAINT micro_task_resource_associators_pkey PRIMARY KEY (id);


--
-- Name: micro_task_reward_associators_micro_task_id_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY micro_task_reward_associators
    ADD CONSTRAINT micro_task_reward_associators_micro_task_id_unique UNIQUE (micro_task_id);


--
-- Name: micro_task_reward_associators_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY micro_task_reward_associators
    ADD CONSTRAINT micro_task_reward_associators_pkey PRIMARY KEY (id);


--
-- Name: micro_task_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY micro_task_type
    ADD CONSTRAINT micro_task_type_pkey PRIMARY KEY (id);


--
-- Name: micro_tasks_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY micro_tasks
    ADD CONSTRAINT micro_tasks_pkey PRIMARY KEY (id);


--
-- Name: mission_batch_question_associators_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mission_batch_question_associators
    ADD CONSTRAINT mission_batch_question_associators_pkey PRIMARY KEY (id);


--
-- Name: mission_batches_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mission_batches
    ADD CONSTRAINT mission_batches_pkey PRIMARY KEY (id);


--
-- Name: mission_question_associators_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mission_question_associators
    ADD CONSTRAINT mission_question_associators_pkey PRIMARY KEY (id);


--
-- Name: mission_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mission_submissions
    ADD CONSTRAINT mission_submissions_pkey PRIMARY KEY (id);


--
-- Name: missions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY missions
    ADD CONSTRAINT missions_pkey PRIMARY KEY (id);


--
-- Name: notification_recipient_associators_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notification_recipient_associators
    ADD CONSTRAINT notification_recipient_associators_pkey PRIMARY KEY (id);


--
-- Name: notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id);


--
-- Name: permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: point_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY point_transactions
    ADD CONSTRAINT point_transactions_pkey PRIMARY KEY (id);


--
-- Name: power_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY power_transactions
    ADD CONSTRAINT power_transactions_pkey PRIMARY KEY (id);


--
-- Name: projects_label_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_label_unique UNIQUE (label);


--
-- Name: projects_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: query_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY query_configurations
    ADD CONSTRAINT query_configurations_pkey PRIMARY KEY (id);


--
-- Name: question_answer_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY question_answer
    ADD CONSTRAINT question_answer_pkey PRIMARY KEY (id);


--
-- Name: question_answer_question_id_micro_task_id_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY question_answer
    ADD CONSTRAINT question_answer_question_id_micro_task_id_unique UNIQUE (question_id, micro_task_id);


--
-- Name: question_submissions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY question_submissions
    ADD CONSTRAINT question_submissions_pkey PRIMARY KEY (id);


--
-- Name: questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_pkey PRIMARY KEY (id);


--
-- Name: resources_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY resources
    ADD CONSTRAINT resources_pkey PRIMARY KEY (id);


--
-- Name: reward_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY reward_transactions
    ADD CONSTRAINT reward_transactions_pkey PRIMARY KEY (id);


--
-- Name: rewards_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY rewards
    ADD CONSTRAINT rewards_pkey PRIMARY KEY (id);


--
-- Name: roles_label_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_label_unique UNIQUE (label);


--
-- Name: roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: routes_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY routes
    ADD CONSTRAINT routes_pkey PRIMARY KEY (id);


--
-- Name: step_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY step
    ADD CONSTRAINT step_pkey PRIMARY KEY (id);


--
-- Name: step_type_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY step_type
    ADD CONSTRAINT step_type_pkey PRIMARY KEY (id);


--
-- Name: tags_micro_task_group_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags_micro_task_group
    ADD CONSTRAINT tags_micro_task_group_pkey PRIMARY KEY (tag_name, tag_value, micro_task_id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (name, value);


--
-- Name: task_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_pkey PRIMARY KEY (id);


--
-- Name: test_questions_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_questions
    ADD CONSTRAINT test_questions_pkey PRIMARY KEY (id);


--
-- Name: test_questions_question_id_micro_task_id_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY test_questions
    ADD CONSTRAINT test_questions_question_id_micro_task_id_unique UNIQUE (question_id, micro_task_id);


--
-- Name: transformation_step_configuration_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transformation_step_configuration
    ADD CONSTRAINT transformation_step_configuration_pkey PRIMARY KEY (id);


--
-- Name: transformation_step_configuration_step_id_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY transformation_step_configuration
    ADD CONSTRAINT transformation_step_configuration_step_id_unique UNIQUE (step_id);


--
-- Name: user role unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_role_associators
    ADD CONSTRAINT "user role unique" UNIQUE (user_id, role_id);


--
-- Name: user_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_activity
    ADD CONSTRAINT user_activity_pkey PRIMARY KEY (id);


--
-- Name: user_micro_task_blocker_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_micro_task_blocker
    ADD CONSTRAINT user_micro_task_blocker_pkey PRIMARY KEY (id);


--
-- Name: user_mission_batch_associators_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_mission_batch_associators
    ADD CONSTRAINT user_mission_batch_associators_pkey PRIMARY KEY (id);


--
-- Name: user_role_associators_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY user_role_associators
    ADD CONSTRAINT user_role_associators_pkey PRIMARY KEY (id);


--
-- Name: users_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users_username_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY users
    ADD CONSTRAINT users_username_unique UNIQUE (username);


--
-- Name: work_flow_pkey; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY work_flow
    ADD CONSTRAINT work_flow_pkey PRIMARY KEY (id);


--
-- Name: work_flow_project_id_unique; Type: CONSTRAINT; Schema: public; Owner: -; Tablespace: 
--

ALTER TABLE ONLY work_flow
    ADD CONSTRAINT work_flow_project_id_unique UNIQUE (project_id);


--
-- Name: availabilities_entity_id_activated_at_deactivated_at_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX availabilities_entity_id_activated_at_deactivated_at_index ON availabilities USING btree (entity_id, activated_at, deactivated_at);


--
-- Name: contact_requests_email_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contact_requests_email_index ON contact_requests USING btree (email);


--
-- Name: contact_requests_name_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX contact_requests_name_index ON contact_requests USING btree (name);


--
-- Name: coupon_transactions_is_served_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX coupon_transactions_is_served_index ON coupon_transactions USING btree (is_served);


--
-- Name: coupon_transactions_user_id_coupon_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX coupon_transactions_user_id_coupon_id_index ON coupon_transactions USING btree (user_id, coupon_id);


--
-- Name: coupons_integration_provider_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX coupons_integration_provider_id_index ON coupons USING btree (integration_provider_id);


--
-- Name: createdat index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "createdat index" ON questions USING btree (created_at DESC NULLS LAST);


--
-- Name: crowdsourcing_flu_buffer_is_deleted_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX crowdsourcing_flu_buffer_is_deleted_index ON crowdsourcing_flu_buffer USING btree (is_deleted);


--
-- Name: emails_email_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX emails_email_index ON emails USING btree (email);


--
-- Name: external_accounts_external_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX external_accounts_external_id_index ON external_accounts USING btree (external_id);


--
-- Name: feed_line_reference_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX feed_line_reference_id_index ON feed_line USING btree (reference_id);


--
-- Name: feed_line_tag_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX feed_line_tag_index ON feed_line USING btree (tag);


--
-- Name: force_update_app_is_active_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX force_update_app_is_active_index ON force_update_app USING btree (is_active);


--
-- Name: grammar_elements_label_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX grammar_elements_label_index ON grammar_elements USING btree (label);


--
-- Name: image_dictionary_cloud_url_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX image_dictionary_cloud_url_index ON image_dictionary USING btree (cloud_url);


--
-- Name: image_dictionary_real_url_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX image_dictionary_real_url_index ON image_dictionary USING btree (real_url);


--
-- Name: integration_providers_label_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX integration_providers_label_index ON integration_providers USING btree (label);


--
-- Name: integration_providers_website_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX integration_providers_website_index ON integration_providers USING btree (website);


--
-- Name: is active; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "is active" ON mission_batches USING btree (is_active);


--
-- Name: is active index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "is active index" ON mission_batch_question_associators USING btree (is_active);


--
-- Name: is active test questions; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "is active test questions" ON test_questions USING btree (is_active);


--
-- Name: is finished umba; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "is finished umba" ON user_mission_batch_associators USING btree (is_finished);


--
-- Name: macro_tasks_label_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX macro_tasks_label_index ON macro_tasks USING btree (label);


--
-- Name: micro_task_question_associators_micro_task_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX micro_task_question_associators_micro_task_id_index ON micro_task_question_associators USING btree (micro_task_id);


--
-- Name: micro_task_question_associators_question_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX micro_task_question_associators_question_id_index ON micro_task_question_associators USING btree (question_id);


--
-- Name: micro_task_resource_associators_micro_task_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX micro_task_resource_associators_micro_task_id_index ON micro_task_resource_associators USING btree (micro_task_id);


--
-- Name: micro_task_resource_associators_resource_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX micro_task_resource_associators_resource_id_index ON micro_task_resource_associators USING btree (resource_id);


--
-- Name: micro_task_reward_associators_micro_task_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX micro_task_reward_associators_micro_task_id_index ON micro_task_reward_associators USING btree (micro_task_id);


--
-- Name: micro_task_reward_associators_reward_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX micro_task_reward_associators_reward_id_index ON micro_task_reward_associators USING btree (reward_id);


--
-- Name: micro_task_type_name_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX micro_task_type_name_index ON micro_task_type USING btree (name);


--
-- Name: micro_tasks_is_active_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX micro_tasks_is_active_index ON micro_tasks USING btree (is_active);


--
-- Name: micro_tasks_is_deleted_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX micro_tasks_is_deleted_index ON micro_tasks USING btree (is_deleted);


--
-- Name: micro_tasks_label_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX micro_tasks_label_index ON micro_tasks USING btree (label);


--
-- Name: microtaskid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX microtaskid ON mission_batches USING btree (micro_task_id);


--
-- Name: microtaskid test question; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "microtaskid test question" ON test_questions USING btree (micro_task_id);


--
-- Name: mission batch id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "mission batch id" ON user_mission_batch_associators USING btree (mission_batch_id);


--
-- Name: mission_batches_is_active_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX mission_batches_is_active_index ON mission_batches USING btree (is_active);


--
-- Name: mission_question_associators_mission_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX mission_question_associators_mission_id_index ON mission_question_associators USING btree (mission_id);


--
-- Name: mission_question_associators_question_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX mission_question_associators_question_id_index ON mission_question_associators USING btree (question_id);


--
-- Name: mission_submissions_mission_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX mission_submissions_mission_id_index ON mission_submissions USING btree (mission_id);


--
-- Name: mission_submissions_status_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX mission_submissions_status_index ON mission_submissions USING btree (status);


--
-- Name: mission_submissions_user_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX mission_submissions_user_id_index ON mission_submissions USING btree (user_id);


--
-- Name: missionbatchid; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX missionbatchid ON mission_batch_question_associators USING btree (mission_batch_id);


--
-- Name: missions_micro_task_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX missions_micro_task_id_index ON missions USING btree (micro_task_id);


--
-- Name: missions_user_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX missions_user_id_index ON missions USING btree (user_id);


--
-- Name: notification_recipient_associators_recipient_id_notification_id; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX notification_recipient_associators_recipient_id_notification_id ON notification_recipient_associators USING btree (recipient_id, notification_id);


--
-- Name: pkey; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX pkey ON questions USING btree (id);


--
-- Name: projects_label_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX projects_label_index ON projects USING btree (label);


--
-- Name: qid index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "qid index" ON mission_batch_question_associators USING btree (question_id);


--
-- Name: question_answer_micro_task_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX question_answer_micro_task_id_index ON question_answer USING btree (micro_task_id);


--
-- Name: question_answer_question_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX question_answer_question_id_index ON question_answer USING btree (question_id);


--
-- Name: question_answer_question_id_micro_task_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX question_answer_question_id_micro_task_id_index ON question_answer USING btree (question_id, micro_task_id);


--
-- Name: question_submissions_is_test_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX question_submissions_is_test_index ON question_submissions USING btree (is_test);


--
-- Name: question_submissions_mission_submission_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX question_submissions_mission_submission_id_index ON question_submissions USING btree (mission_submission_id);


--
-- Name: question_submissions_question_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX question_submissions_question_id_index ON question_submissions USING btree (question_id);


--
-- Name: question_submissions_status_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX question_submissions_status_index ON question_submissions USING btree (status);


--
-- Name: question_submissions_user_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX question_submissions_user_id_index ON question_submissions USING btree (user_id);


--
-- Name: questionid index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "questionid index" ON test_questions USING btree (question_id);


--
-- Name: questions_is_active_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX questions_is_active_index ON questions USING btree (is_active);


--
-- Name: questions_is_test_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX questions_is_test_index ON questions USING btree (is_test);


--
-- Name: questions_label_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX questions_label_index ON questions USING btree (label);


--
-- Name: resources_body_type_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX resources_body_type_index ON resources USING btree (body_type);


--
-- Name: resources_label_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX resources_label_index ON resources USING btree (label);


--
-- Name: role_id index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "role_id index" ON roles USING btree (id);


--
-- Name: roles_label_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX roles_label_index ON roles USING btree (label);


--
-- Name: routes_step_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX routes_step_id_index ON routes USING btree (step_id);


--
-- Name: step_work_flow_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX step_work_flow_id_index ON step USING btree (work_flow_id);


--
-- Name: sub counter index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "sub counter index" ON mission_batch_question_associators USING btree (sub_counter);


--
-- Name: tag_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tag_index ON tags_micro_task_group USING btree (tag_name, tag_value, micro_task_id);


--
-- Name: tags_micro_task_group_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tags_micro_task_group_id_index ON tags_micro_task_group USING btree (id);


--
-- Name: tags_micro_task_group_micro_task_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tags_micro_task_group_micro_task_id_index ON tags_micro_task_group USING btree (micro_task_id);


--
-- Name: tags_micro_task_group_tag_name_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tags_micro_task_group_tag_name_index ON tags_micro_task_group USING btree (tag_name);


--
-- Name: tags_micro_task_group_tag_value_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tags_micro_task_group_tag_value_index ON tags_micro_task_group USING btree (tag_value);


--
-- Name: tags_name_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tags_name_index ON tags USING btree (name);


--
-- Name: tags_name_value_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tags_name_value_index ON tags USING btree (name, value);


--
-- Name: tags_value_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX tags_value_index ON tags USING btree (value);


--
-- Name: test_questions_is_active_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX test_questions_is_active_index ON test_questions USING btree (is_active);


--
-- Name: user_activity_is_deleted_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX user_activity_is_deleted_index ON user_activity USING btree (is_deleted);


--
-- Name: user_activity_type_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX user_activity_type_index ON user_activity USING btree (type);


--
-- Name: user_activity_user_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX user_activity_user_id_index ON user_activity USING btree (user_id);


--
-- Name: user_id index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "user_id index" ON user_role_associators USING btree (user_id);


--
-- Name: user_micro_task_blocker_micro_task_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX user_micro_task_blocker_micro_task_id_index ON user_micro_task_blocker USING btree (micro_task_id);


--
-- Name: user_micro_task_blocker_user_id_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX user_micro_task_blocker_user_id_index ON user_micro_task_blocker USING btree (user_id);


--
-- Name: user_role_associators_approval_strategy_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX user_role_associators_approval_strategy_index ON user_role_associators USING btree (approval_strategy);


--
-- Name: userid umba; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX "userid umba" ON user_mission_batch_associators USING btree (user_id);


--
-- Name: users_username_index; Type: INDEX; Schema: public; Owner: -; Tablespace: 
--

CREATE INDEX users_username_index ON users USING btree (username);


--
-- Name: batch_process_macro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY batch_process
    ADD CONSTRAINT batch_process_macro_task_id_foreign FOREIGN KEY (macro_task_id) REFERENCES macro_tasks(id) ON DELETE CASCADE;


--
-- Name: clients_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY clients
    ADD CONSTRAINT clients_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: comments_creator_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY comments
    ADD CONSTRAINT comments_creator_id_foreign FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: contact_requests_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY contact_requests
    ADD CONSTRAINT contact_requests_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: coupon_transactions_coupon_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coupon_transactions
    ADD CONSTRAINT coupon_transactions_coupon_id_foreign FOREIGN KEY (coupon_id) REFERENCES coupons(id) ON DELETE CASCADE;


--
-- Name: coupon_transactions_served_by_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coupon_transactions
    ADD CONSTRAINT coupon_transactions_served_by_foreign FOREIGN KEY (served_by) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: coupon_transactions_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coupon_transactions
    ADD CONSTRAINT coupon_transactions_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: coupons_integration_provider_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY coupons
    ADD CONSTRAINT coupons_integration_provider_id_foreign FOREIGN KEY (integration_provider_id) REFERENCES integration_providers(id);


--
-- Name: crowdsourcing_flu_buffer_flu_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crowdsourcing_flu_buffer
    ADD CONSTRAINT crowdsourcing_flu_buffer_flu_id_foreign FOREIGN KEY (flu_id) REFERENCES feed_line(id);


--
-- Name: crowdsourcing_flu_buffer_question_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crowdsourcing_flu_buffer
    ADD CONSTRAINT crowdsourcing_flu_buffer_question_id_foreign FOREIGN KEY (question_id) REFERENCES questions(id);


--
-- Name: crowdsourcing_step_configuration_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crowdsourcing_step_configuration
    ADD CONSTRAINT crowdsourcing_step_configuration_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id);


--
-- Name: crowdsourcing_step_configuration_step_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY crowdsourcing_step_configuration
    ADD CONSTRAINT crowdsourcing_step_configuration_step_id_foreign FOREIGN KEY (step_id) REFERENCES step(id);


--
-- Name: emails_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY emails
    ADD CONSTRAINT emails_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: external_accounts_integration_provider_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_accounts
    ADD CONSTRAINT external_accounts_integration_provider_id_foreign FOREIGN KEY (integration_provider_id) REFERENCES integration_providers(id) ON DELETE CASCADE;


--
-- Name: external_accounts_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY external_accounts
    ADD CONSTRAINT external_accounts_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: feed_line_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY feed_line
    ADD CONSTRAINT feed_line_project_id_foreign FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: feed_line_step_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY feed_line
    ADD CONSTRAINT feed_line_step_id_foreign FOREIGN KEY (step_id) REFERENCES step(id);


--
-- Name: feedbacks_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY feedbacks
    ADD CONSTRAINT feedbacks_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: input_flu_validator_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY input_flu_validator
    ADD CONSTRAINT input_flu_validator_project_id_foreign FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: invitation_requests_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY invitation_requests
    ADD CONSTRAINT invitation_requests_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: logic_gate_formula_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY logic_gate
    ADD CONSTRAINT logic_gate_formula_foreign FOREIGN KEY (formula) REFERENCES logic_gate_formula(id);


--
-- Name: macro_tasks_creator_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY macro_tasks
    ADD CONSTRAINT macro_tasks_creator_id_foreign FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: macro_tasks_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY macro_tasks
    ADD CONSTRAINT macro_tasks_project_id_foreign FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE;


--
-- Name: micro_task_batches_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_task_batches
    ADD CONSTRAINT micro_task_batches_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id);


--
-- Name: micro_task_batches_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_task_batches
    ADD CONSTRAINT micro_task_batches_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: micro_task_question_associators_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_task_question_associators
    ADD CONSTRAINT micro_task_question_associators_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id);


--
-- Name: micro_task_question_associators_question_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_task_question_associators
    ADD CONSTRAINT micro_task_question_associators_question_id_foreign FOREIGN KEY (question_id) REFERENCES questions(id);


--
-- Name: micro_task_resource_associators_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_task_resource_associators
    ADD CONSTRAINT micro_task_resource_associators_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id) ON DELETE CASCADE;


--
-- Name: micro_task_resource_associators_resource_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_task_resource_associators
    ADD CONSTRAINT micro_task_resource_associators_resource_id_foreign FOREIGN KEY (resource_id) REFERENCES resources(id) ON DELETE CASCADE;


--
-- Name: micro_task_reward_associators_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_task_reward_associators
    ADD CONSTRAINT micro_task_reward_associators_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id) ON DELETE CASCADE;


--
-- Name: micro_task_reward_associators_reward_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_task_reward_associators
    ADD CONSTRAINT micro_task_reward_associators_reward_id_foreign FOREIGN KEY (reward_id) REFERENCES rewards(id) ON DELETE CASCADE;


--
-- Name: micro_tasks_creator_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_tasks
    ADD CONSTRAINT micro_tasks_creator_id_foreign FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE SET NULL;


--
-- Name: micro_tasks_fallback_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_tasks
    ADD CONSTRAINT micro_tasks_fallback_micro_task_id_foreign FOREIGN KEY (fallback_micro_task_id) REFERENCES micro_tasks(id) ON DELETE CASCADE;


--
-- Name: micro_tasks_macro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_tasks
    ADD CONSTRAINT micro_tasks_macro_task_id_foreign FOREIGN KEY (macro_task_id) REFERENCES macro_tasks(id) ON DELETE CASCADE;


--
-- Name: micro_tasks_type_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY micro_tasks
    ADD CONSTRAINT micro_tasks_type_foreign FOREIGN KEY (type) REFERENCES micro_task_type(id);


--
-- Name: mission_batch_question_associators_mission_batch_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mission_batch_question_associators
    ADD CONSTRAINT mission_batch_question_associators_mission_batch_id_foreign FOREIGN KEY (mission_batch_id) REFERENCES mission_batches(id);


--
-- Name: mission_batch_question_associators_question_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mission_batch_question_associators
    ADD CONSTRAINT mission_batch_question_associators_question_id_foreign FOREIGN KEY (question_id) REFERENCES questions(id);


--
-- Name: mission_batches_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mission_batches
    ADD CONSTRAINT mission_batches_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id);


--
-- Name: mission_question_associators_mission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mission_question_associators
    ADD CONSTRAINT mission_question_associators_mission_id_foreign FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE;


--
-- Name: mission_question_associators_question_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mission_question_associators
    ADD CONSTRAINT mission_question_associators_question_id_foreign FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE;


--
-- Name: mission_submissions_mission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mission_submissions
    ADD CONSTRAINT mission_submissions_mission_id_foreign FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE;


--
-- Name: mission_submissions_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY mission_submissions
    ADD CONSTRAINT mission_submissions_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: missions_guidelines_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY missions
    ADD CONSTRAINT missions_guidelines_id_foreign FOREIGN KEY (guidelines_id) REFERENCES resources(id) ON DELETE CASCADE;


--
-- Name: missions_instructions_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY missions
    ADD CONSTRAINT missions_instructions_id_foreign FOREIGN KEY (instructions_id) REFERENCES resources(id) ON DELETE CASCADE;


--
-- Name: missions_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY missions
    ADD CONSTRAINT missions_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id);


--
-- Name: missions_mission_batch_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY missions
    ADD CONSTRAINT missions_mission_batch_id_foreign FOREIGN KEY (mission_batch_id) REFERENCES mission_batches(id);


--
-- Name: missions_submission_template_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY missions
    ADD CONSTRAINT missions_submission_template_id_foreign FOREIGN KEY (submission_template_id) REFERENCES resources(id);


--
-- Name: missions_ui_template_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY missions
    ADD CONSTRAINT missions_ui_template_id_foreign FOREIGN KEY (ui_template_id) REFERENCES resources(id);


--
-- Name: missions_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY missions
    ADD CONSTRAINT missions_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: notification_recipient_associators_notification_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_recipient_associators
    ADD CONSTRAINT notification_recipient_associators_notification_id_foreign FOREIGN KEY (notification_id) REFERENCES notifications(id) ON DELETE CASCADE;


--
-- Name: notification_recipient_associators_recipient_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY notification_recipient_associators
    ADD CONSTRAINT notification_recipient_associators_recipient_id_foreign FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: permissions_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY permissions
    ADD CONSTRAINT permissions_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- Name: point_transactions_reward_transaction_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY point_transactions
    ADD CONSTRAINT point_transactions_reward_transaction_id_foreign FOREIGN KEY (reward_transaction_id) REFERENCES reward_transactions(id) ON DELETE CASCADE;


--
-- Name: point_transactions_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY point_transactions
    ADD CONSTRAINT point_transactions_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: power_transactions_reward_transaction_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY power_transactions
    ADD CONSTRAINT power_transactions_reward_transaction_id_foreign FOREIGN KEY (reward_transaction_id) REFERENCES reward_transactions(id) ON DELETE CASCADE;


--
-- Name: power_transactions_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY power_transactions
    ADD CONSTRAINT power_transactions_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: project_configuration_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY project_configuration
    ADD CONSTRAINT project_configuration_project_id_foreign FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- Name: projects_client_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_client_id_foreign FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;


--
-- Name: projects_creator_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY projects
    ADD CONSTRAINT projects_creator_id_foreign FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: query_configurations_cron_job_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY query_configurations
    ADD CONSTRAINT query_configurations_cron_job_id_foreign FOREIGN KEY (cron_job_id) REFERENCES cron_job_configurations(id);


--
-- Name: question_answer_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY question_answer
    ADD CONSTRAINT question_answer_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id) ON DELETE CASCADE;


--
-- Name: question_answer_question_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY question_answer
    ADD CONSTRAINT question_answer_question_id_foreign FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE;


--
-- Name: question_submissions_mission_submission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY question_submissions
    ADD CONSTRAINT question_submissions_mission_submission_id_foreign FOREIGN KEY (mission_submission_id) REFERENCES mission_submissions(id) ON DELETE CASCADE;


--
-- Name: question_submissions_question_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY question_submissions
    ADD CONSTRAINT question_submissions_question_id_foreign FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE;


--
-- Name: question_submissions_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY question_submissions
    ADD CONSTRAINT question_submissions_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: questions_creator_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY questions
    ADD CONSTRAINT questions_creator_id_foreign FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: resources_creator_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY resources
    ADD CONSTRAINT resources_creator_id_foreign FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: reward_transactions_mission_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reward_transactions
    ADD CONSTRAINT reward_transactions_mission_id_foreign FOREIGN KEY (mission_id) REFERENCES missions(id) ON DELETE CASCADE;


--
-- Name: reward_transactions_reward_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reward_transactions
    ADD CONSTRAINT reward_transactions_reward_id_foreign FOREIGN KEY (reward_id) REFERENCES rewards(id) ON DELETE CASCADE;


--
-- Name: reward_transactions_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY reward_transactions
    ADD CONSTRAINT reward_transactions_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: rewards_creator_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY rewards
    ADD CONSTRAINT rewards_creator_id_foreign FOREIGN KEY (creator_id) REFERENCES users(id);


--
-- Name: routes_logic_gate_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY routes
    ADD CONSTRAINT routes_logic_gate_id_foreign FOREIGN KEY (logic_gate_id) REFERENCES logic_gate(id) ON DELETE CASCADE;


--
-- Name: routes_next_step_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY routes
    ADD CONSTRAINT routes_next_step_id_foreign FOREIGN KEY (next_step_id) REFERENCES step(id) ON DELETE CASCADE;


--
-- Name: routes_step_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY routes
    ADD CONSTRAINT routes_step_id_foreign FOREIGN KEY (step_id) REFERENCES step(id) ON DELETE CASCADE;


--
-- Name: step_type_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY step
    ADD CONSTRAINT step_type_foreign FOREIGN KEY (type) REFERENCES step_type(id);


--
-- Name: step_work_flow_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY step
    ADD CONSTRAINT step_work_flow_id_foreign FOREIGN KEY (work_flow_id) REFERENCES work_flow(id);


--
-- Name: tags_micro_task_group_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY tags_micro_task_group
    ADD CONSTRAINT tags_micro_task_group_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id) ON DELETE CASCADE;


--
-- Name: task_macro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY task
    ADD CONSTRAINT task_macro_task_id_foreign FOREIGN KEY (macro_task_id) REFERENCES macro_tasks(id) ON DELETE CASCADE;


--
-- Name: test_questions_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY test_questions
    ADD CONSTRAINT test_questions_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id);


--
-- Name: test_questions_question_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY test_questions
    ADD CONSTRAINT test_questions_question_id_foreign FOREIGN KEY (question_id) REFERENCES questions(id);


--
-- Name: transformation_step_configuration_step_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY transformation_step_configuration
    ADD CONSTRAINT transformation_step_configuration_step_id_foreign FOREIGN KEY (step_id) REFERENCES step(id);


--
-- Name: user_activity_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_activity
    ADD CONSTRAINT user_activity_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: user_micro_task_blocker_micro_task_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_micro_task_blocker
    ADD CONSTRAINT user_micro_task_blocker_micro_task_id_foreign FOREIGN KEY (micro_task_id) REFERENCES micro_tasks(id) ON DELETE CASCADE;


--
-- Name: user_micro_task_blocker_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_micro_task_blocker
    ADD CONSTRAINT user_micro_task_blocker_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: user_mission_batch_associators_mission_batch_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_mission_batch_associators
    ADD CONSTRAINT user_mission_batch_associators_mission_batch_id_foreign FOREIGN KEY (mission_batch_id) REFERENCES mission_batches(id);


--
-- Name: user_mission_batch_associators_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_mission_batch_associators
    ADD CONSTRAINT user_mission_batch_associators_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id);


--
-- Name: user_role_associators_role_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_role_associators
    ADD CONSTRAINT user_role_associators_role_id_foreign FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE;


--
-- Name: user_role_associators_user_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY user_role_associators
    ADD CONSTRAINT user_role_associators_user_id_foreign FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;


--
-- Name: work_flow_project_id_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY work_flow
    ADD CONSTRAINT work_flow_project_id_foreign FOREIGN KEY (project_id) REFERENCES projects(id);


--
-- PostgreSQL database dump complete
--

