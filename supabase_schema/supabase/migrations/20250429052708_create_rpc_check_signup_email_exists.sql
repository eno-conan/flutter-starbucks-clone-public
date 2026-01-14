drop policy "deny_all" on "public"."pre_signup_users";

drop policy "select_if_email_matches" on "public"."pre_signup_users";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.check_signup_email_exists(input_email text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  email_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM auth.users WHERE email = input_email
  ) INTO email_exists;
  
  RETURN email_exists;
END;
$function$
;

create policy "select_pre_signup_users"
on "public"."pre_signup_users"
as permissive
for select
to public
using (true);



