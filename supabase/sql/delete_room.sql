-- Anomaly VTT: protected room deletion
-- Applied to the connected Supabase project on 2026-11-19.
-- Keep this SQL in version control so the function can be recreated in another environment.

CREATE OR REPLACE FUNCTION public.delete_room(
  p_user_id uuid,
  p_room_id uuid,
  p_password text,
  p_confirm_name text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $function$
DECLARE
  v_password_hash text;
  v_room_name text;
BEGIN
  IF p_user_id IS NULL OR p_room_id IS NULL
     OR p_password IS NULL OR p_confirm_name IS NULL THEN
    RAISE EXCEPTION 'Preencha todos os campos para excluir a mesa.'
      USING ERRCODE = '22023';
  END IF;

  SELECT au.password_hash
    INTO v_password_hash
  FROM public.auth_users AS au
  WHERE au.id = p_user_id;

  IF v_password_hash IS NULL
     OR extensions.crypt(p_password, v_password_hash) IS DISTINCT FROM v_password_hash THEN
    RAISE EXCEPTION 'Senha incorreta.'
      USING ERRCODE = '28000';
  END IF;

  SELECT r.name
    INTO v_room_name
  FROM public.rooms AS r
  JOIN public.room_members AS rm
    ON rm.room_id = r.id
   AND rm.user_id = p_user_id
   AND rm.role = 'mestre'
  WHERE r.id = p_room_id
    AND r.created_by = p_user_id
  FOR UPDATE OF r;

  IF v_room_name IS NULL THEN
    RAISE EXCEPTION 'Somente o mestre que criou esta mesa pode excluí-la.'
      USING ERRCODE = '42501';
  END IF;

  IF lower(btrim(p_confirm_name)) IS DISTINCT FROM lower(btrim(v_room_name)) THEN
    RAISE EXCEPTION 'O nome digitado não corresponde ao nome da mesa.'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.board
     SET active_scene_id = NULL
   WHERE active_scene_id IN (
     SELECT s.id FROM public.scenes AS s WHERE s.room_id = p_room_id
   );

  DELETE FROM public.rooms
   WHERE id = p_room_id AND created_by = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'A mesa não foi encontrada ou não pode ser excluída.'
      USING ERRCODE = '42501';
  END IF;
END;
$function$;

-- The current client uses the Supabase anon role and a custom login system.
-- This RPC verifies the account password and creator/master relationship.
REVOKE EXECUTE ON FUNCTION public.delete_room(uuid, uuid, text, text) FROM PUBLIC, authenticated;
GRANT EXECUTE ON FUNCTION public.delete_room(uuid, uuid, text, text) TO anon;
