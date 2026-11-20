-- Exclui uma cena de uma mesa sem permitir que a mesa fique sem cenas.
-- A função valida senha, nome exato e papel de mestre antes da exclusão.
-- Os elementos da cena são removidos pelas FKs ON DELETE CASCADE.
-- A referência ativa da mesa e a referência legada de board são atualizadas
-- antes da exclusão para evitar violação de chave estrangeira.

create or replace function public.delete_scene(
  p_user_id uuid,
  p_scene_id uuid,
  p_password text,
  p_confirm_name text
)
returns uuid
language plpgsql
security definer
set search_path = public, extensions
as $function$
declare
  v_password_hash text;
  v_room_id uuid;
  v_scene_name text;
  v_scene_count integer;
  v_replacement_scene_id uuid;
begin
  if p_user_id is null or p_scene_id is null or p_password is null or p_confirm_name is null then
    raise exception 'Preencha todos os campos para excluir a cena.'
      using errcode = '22023';
  end if;

  select au.password_hash into v_password_hash
  from public.auth_users au
  where au.id = p_user_id;

  if v_password_hash is null
     or extensions.crypt(p_password, v_password_hash) is distinct from v_password_hash then
    raise exception 'Senha incorreta.'
      using errcode = '28000';
  end if;

  select s.room_id, s.name into v_room_id, v_scene_name
  from public.scenes s
  where s.id = p_scene_id
  for update;

  if v_room_id is null or not public._lib_is_room_master(p_user_id, v_room_id) then
    raise exception 'Somente o mestre desta mesa pode excluir cenas.'
      using errcode = '42501';
  end if;

  if lower(btrim(p_confirm_name)) is distinct from lower(btrim(v_scene_name)) then
    raise exception 'O nome digitado não corresponde ao nome da cena.'
      using errcode = '22023';
  end if;

  select count(*) into v_scene_count
  from public.scenes
  where room_id = v_room_id;

  if v_scene_count <= 1 then
    raise exception 'A mesa precisa manter pelo menos uma cena.'
      using errcode = '22023';
  end if;

  select s.id into v_replacement_scene_id
  from public.scenes s
  where s.room_id = v_room_id and s.id <> p_scene_id
  order by s.created_at, s.id
  limit 1;

  update public.rooms
  set active_scene_id = v_replacement_scene_id
  where id = v_room_id and active_scene_id = p_scene_id;

  update public.board
  set active_scene_id = v_replacement_scene_id
  where active_scene_id = p_scene_id;

  delete from public.scenes where id = p_scene_id and room_id = v_room_id;

  if not found then
    raise exception 'A cena não foi encontrada ou não pôde ser excluída.'
      using errcode = '42501';
  end if;

  return v_replacement_scene_id;
end;
$function$;

revoke execute on function public.delete_scene(uuid, uuid, text, text) from public;
grant execute on function public.delete_scene(uuid, uuid, text, text) to anon, authenticated;
