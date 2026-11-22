-- Mantém a RPC de propriedades compatível com as opções atuais do painel.
-- Inclui hide_name para controlar a exibição do nome flutuante do token.
-- A autorização do mestre é validada pela função _lib_is_room_master.
-- Nenhuma política RLS é alterada por este arquivo.

create or replace function public.update_token_props(p_user_id uuid, p_token_id uuid, p_props jsonb)
returns void
language plpgsql
security definer
set search_path to 'public', 'extensions'
as $function$
declare v_room uuid;
begin
  select s.room_id into v_room
  from public.tokens t
  join public.scenes s on s.id = t.scene_id
  where t.id = p_token_id;

  if v_room is null or not public._lib_is_room_master(p_user_id, v_room) then
    raise exception 'Só o mestre edita as propriedades';
  end if;

  update public.tokens set
    name        = case when jsonb_exists(p_props, 'name') then nullif(left(btrim(p_props->>'name'), 60), '') else name end,
    tint        = case when jsonb_exists(p_props, 'tint') then (case when (p_props->>'tint') ~ '^#[0-9a-fA-F]{6}$' then lower(p_props->>'tint') else null end) else tint end,
    tint_amount = case when jsonb_exists(p_props, 'tint_amount') then greatest(0, least(1, (p_props->>'tint_amount')::double precision)) else tint_amount end,
    opacity     = case when jsonb_exists(p_props, 'opacity') then greatest(0.05, least(1, (p_props->>'opacity')::double precision)) else opacity end,
    size        = case when jsonb_exists(p_props, 'size') then greatest(8, least(4096, (p_props->>'size')::double precision)) else size end,
    rotation    = case when jsonb_exists(p_props, 'rotation') then (p_props->>'rotation')::double precision else rotation end,
    flip_x      = case when jsonb_exists(p_props, 'flip_x') then (p_props->>'flip_x')::boolean else flip_x end,
    hidden      = case when jsonb_exists(p_props, 'hidden') then coalesce((p_props->>'hidden')::boolean, false) else hidden end,
    locked      = case when jsonb_exists(p_props, 'locked') then coalesce((p_props->>'locked')::boolean, false) else locked end,
    name_hidden = case when jsonb_exists(p_props, 'name_hidden') then coalesce((p_props->>'name_hidden')::boolean, false) else name_hidden end,
    hide_name   = case when jsonb_exists(p_props, 'hide_name') then coalesce((p_props->>'hide_name')::boolean, true) else hide_name end
  where id = p_token_id;
end
$function$;
