drop policy "Users can delete their own favorite stores" on "public"."favorite_stores";

drop policy "Users can insert their own favorite stores" on "public"."favorite_stores";

drop policy "Users can update their own favorite stores" on "public"."favorite_stores";

drop policy "Users can view their own favorite stores" on "public"."favorite_stores";

revoke delete on table "public"."favorite_stores" from "anon";

revoke insert on table "public"."favorite_stores" from "anon";

revoke references on table "public"."favorite_stores" from "anon";

revoke select on table "public"."favorite_stores" from "anon";

revoke trigger on table "public"."favorite_stores" from "anon";

revoke truncate on table "public"."favorite_stores" from "anon";

revoke update on table "public"."favorite_stores" from "anon";

revoke delete on table "public"."favorite_stores" from "authenticated";

revoke insert on table "public"."favorite_stores" from "authenticated";

revoke references on table "public"."favorite_stores" from "authenticated";

revoke select on table "public"."favorite_stores" from "authenticated";

revoke trigger on table "public"."favorite_stores" from "authenticated";

revoke truncate on table "public"."favorite_stores" from "authenticated";

revoke update on table "public"."favorite_stores" from "authenticated";

revoke delete on table "public"."favorite_stores" from "service_role";

revoke insert on table "public"."favorite_stores" from "service_role";

revoke references on table "public"."favorite_stores" from "service_role";

revoke select on table "public"."favorite_stores" from "service_role";

revoke trigger on table "public"."favorite_stores" from "service_role";

revoke truncate on table "public"."favorite_stores" from "service_role";

revoke update on table "public"."favorite_stores" from "service_role";

alter table "public"."favorite_stores" drop constraint "favorite_stores_store_number_fkey";

alter table "public"."favorite_stores" drop constraint "favorite_stores_user_id_fkey";

alter table "public"."favorite_stores" drop constraint "favorite_stores_pkey";

drop index if exists "public"."favorite_stores_pkey";

drop table "public"."favorite_stores";


