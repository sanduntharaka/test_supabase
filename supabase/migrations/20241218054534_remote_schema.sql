

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE OR REPLACE FUNCTION "public"."delete_from_cost_parameters"("user_id" "uuid", "value_to_remove" integer) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    BEGIN
        UPDATE user_profile
        SET cost_parameters = jsonb_set(
            cost_parameters::jsonb,
            '{parameters}',
            to_jsonb(ARRAY(
                SELECT element::INT
                FROM jsonb_array_elements_text(
                    (SELECT cost_parameters->'parameters'
                     FROM user_profile
                     WHERE user_profile.user_id = delete_from_cost_parameters.user_id)
                ) AS element
                WHERE element::INT != value_to_remove
            ))::JSONB
        )
        WHERE public.user_profile.user_id = delete_from_cost_parameters.user_id;

    EXCEPTION WHEN OTHERS THEN
        -- Log the error
        INSERT INTO function_error_log (function_name, error_message)
        VALUES ('delete_from_cost_parameters', SQLERRM);
        RAISE;
    END;
END;
$$;


ALTER FUNCTION "public"."delete_from_cost_parameters"("user_id" "uuid", "value_to_remove" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_cost_parameters_by_json"("input_json" "json") RETURNS TABLE("id" bigint, "parameter_name" "text", "description" "text")
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        cp.id,
        cp.parameter_name::TEXT, -- Cast to TEXT
        cp.description
    FROM public.cost_parameter cp
    WHERE cp.id IN (
        SELECT jsonb_array_elements_text(input_json::JSONB->'parameter_ids')::BIGINT
    );
END;
$$;


ALTER FUNCTION "public"."get_cost_parameters_by_json"("input_json" "json") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_cost_parameters"("user_id" "uuid", "new_parameters" integer[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    BEGIN
        UPDATE user_profile
        SET cost_parameters = jsonb_set(
            cost_parameters::jsonb,
            '{parameters}',
            to_jsonb(ARRAY(
                SELECT DISTINCT unnest(array_append(
                    ARRAY(
                        SELECT jsonb_array_elements_text(cost_parameters->'parameters')::INT
                    ),
                    unnest(update_cost_parameters.new_parameters)
                ))
            ))::JSONB
        )
        WHERE public.user_profile.user_id = update_cost_parameters.user_id;


    EXCEPTION WHEN OTHERS THEN
        -- Log the error
        INSERT INTO function_error_log (function_name, error_message)
        VALUES ('update_cost_parameters', SQLERRM);
        RAISE;
    END;
END;
$$;


ALTER FUNCTION "public"."update_cost_parameters"("user_id" "uuid", "new_parameters" integer[]) OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."cost_parameter" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "parameter_name" character varying NOT NULL,
    "description" "text"
);


ALTER TABLE "public"."cost_parameter" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."cost_parameter_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."cost_parameter_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."cost_parameter_id_seq" OWNED BY "public"."cost_parameter"."id";



CREATE TABLE IF NOT EXISTS "public"."portfolio_table" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "name" character varying NOT NULL,
    "institute" character varying,
    "type_of_ownership" character varying,
    "percentage_of_ownership" numeric,
    "user_id" "uuid" NOT NULL
);


ALTER TABLE "public"."portfolio_table" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."positions_table" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "folder_name" character varying NOT NULL,
    "isin" character varying,
    "quantity" numeric,
    "pmc" numeric,
    "user_id" "uuid" NOT NULL,
    "portfolio_id" "uuid" NOT NULL
);


ALTER TABLE "public"."positions_table" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."user_profile" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "first_name" character varying,
    "last_name" character varying,
    "address" "text",
    "phone" character varying,
    "bio" "text",
    "cost_parameters" "jsonb" DEFAULT '{"parameters": []}'::"jsonb" NOT NULL,
    "question_answer" "json",
    "privacy" character varying DEFAULT 'public'::character varying NOT NULL,
    "status" character varying DEFAULT 'normal'::character varying NOT NULL,
    "user_id" "uuid" NOT NULL
);


ALTER TABLE "public"."user_profile" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."user_profile_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."user_profile_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."user_profile_id_seq" OWNED BY "public"."user_profile"."id";



ALTER TABLE ONLY "public"."cost_parameter" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."cost_parameter_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."user_profile" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."user_profile_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."cost_parameter"
    ADD CONSTRAINT "cost_parameter_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."portfolio_table"
    ADD CONSTRAINT "portfolio_table_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."positions_table"
    ADD CONSTRAINT "positions_table_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_profile"
    ADD CONSTRAINT "user_profile_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."portfolio_table"
    ADD CONSTRAINT "portfolio_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."positions_table"
    ADD CONSTRAINT "positions_portfolio_id_fkey" FOREIGN KEY ("portfolio_id") REFERENCES "public"."portfolio_table"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."positions_table"
    ADD CONSTRAINT "positions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."user_profile"
    ADD CONSTRAINT "user_profile_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";




















































































































































































GRANT ALL ON FUNCTION "public"."delete_from_cost_parameters"("user_id" "uuid", "value_to_remove" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."delete_from_cost_parameters"("user_id" "uuid", "value_to_remove" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_from_cost_parameters"("user_id" "uuid", "value_to_remove" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_cost_parameters_by_json"("input_json" "json") TO "anon";
GRANT ALL ON FUNCTION "public"."get_cost_parameters_by_json"("input_json" "json") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_cost_parameters_by_json"("input_json" "json") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_cost_parameters"("user_id" "uuid", "new_parameters" integer[]) TO "anon";
GRANT ALL ON FUNCTION "public"."update_cost_parameters"("user_id" "uuid", "new_parameters" integer[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_cost_parameters"("user_id" "uuid", "new_parameters" integer[]) TO "service_role";


















GRANT ALL ON TABLE "public"."cost_parameter" TO "anon";
GRANT ALL ON TABLE "public"."cost_parameter" TO "authenticated";
GRANT ALL ON TABLE "public"."cost_parameter" TO "service_role";



GRANT ALL ON SEQUENCE "public"."cost_parameter_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."cost_parameter_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."cost_parameter_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."portfolio_table" TO "anon";
GRANT ALL ON TABLE "public"."portfolio_table" TO "authenticated";
GRANT ALL ON TABLE "public"."portfolio_table" TO "service_role";



GRANT ALL ON TABLE "public"."positions_table" TO "anon";
GRANT ALL ON TABLE "public"."positions_table" TO "authenticated";
GRANT ALL ON TABLE "public"."positions_table" TO "service_role";



GRANT ALL ON TABLE "public"."user_profile" TO "anon";
GRANT ALL ON TABLE "public"."user_profile" TO "authenticated";
GRANT ALL ON TABLE "public"."user_profile" TO "service_role";



GRANT ALL ON SEQUENCE "public"."user_profile_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."user_profile_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."user_profile_id_seq" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























RESET ALL;
