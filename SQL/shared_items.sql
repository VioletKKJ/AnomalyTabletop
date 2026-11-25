-- Anomaly VTT: itens compartilhados. Não é inventário de jogador.
-- Cada item pertence à mesa; o mestre decide se está visível a todos ou a um jogador.
-- A tabela fica com RLS ligado e sem policies. O acesso ocorre pelas RPCs abaixo.
-- A sincronização usa broadcast Realtime no canal items-<room_id>, sem publication SQL.

create table if not exists public.shared_items (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.rooms(id) on delete cascade,
  name text not null,
  description text,
  image_url text not null,
  is_shared boolean not null default false,
  target_user_id uuid references public.profiles(id) on delete cascade,
  shared_at timestamptz,
  created_by uuid references public.profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_shared_items_room on public.shared_items(room_id);
alter table public.shared_items enable row level security;

create or replace function public._items_is_member(p_user_id uuid,p_room_id uuid)
returns boolean language sql stable security definer
set search_path to 'public','extensions'
as $function$
  select exists(select 1 from public.room_members where room_id=p_room_id and user_id=p_user_id);
$function$;
revoke execute on function public._items_is_member(uuid,uuid) from public,anon,authenticated;

create or replace function public.items_list(p_user_id uuid,p_room_id uuid)
returns jsonb language plpgsql stable security definer
set search_path to 'public','extensions'
as $function$
declare v_master boolean;
begin
  if p_user_id is null or p_room_id is null or not public._items_is_member(p_user_id,p_room_id) then
    raise exception 'Você não participa desta mesa.' using errcode='42501';
  end if;
  v_master:=public._lib_is_room_master(p_user_id,p_room_id);
  return coalesce((
    select jsonb_agg(to_jsonb(i) order by i.created_at,i.id)
    from public.shared_items i
    where i.room_id=p_room_id
      and (v_master or (i.is_shared and (i.target_user_id is null or i.target_user_id=p_user_id)))
  ),'[]'::jsonb);
end;
$function$;

create or replace function public.items_save(
  p_user_id uuid,p_room_id uuid,p_item_id uuid,p_name text,p_description text,p_image_url text
)
returns jsonb language plpgsql security definer
set search_path to 'public','extensions'
as $function$
declare v_name text; v_desc text; v_row public.shared_items;
begin
  if p_user_id is null or p_room_id is null or not public._lib_is_room_master(p_user_id,p_room_id) then
    raise exception 'Somente o mestre pode gerenciar itens.' using errcode='42501';
  end if;
  v_name:=left(btrim(coalesce(p_name,'')),60);
  if v_name='' then raise exception 'Dê um nome ao item.' using errcode='22023'; end if;
  v_desc:=nullif(left(btrim(coalesce(p_description,'')),1500),'');
  if p_image_url is null or p_image_url !~* '^https?://' then
    raise exception 'Imagem inválida.' using errcode='22023';
  end if;
  if p_item_id is null then
    insert into public.shared_items(room_id,name,description,image_url,created_by)
    values(p_room_id,v_name,v_desc,p_image_url,p_user_id) returning * into v_row;
  else
    update public.shared_items set name=v_name,description=v_desc,image_url=p_image_url,updated_at=now()
    where id=p_item_id and room_id=p_room_id returning * into v_row;
    if not found then raise exception 'Item não encontrado.' using errcode='P0002'; end if;
  end if;
  return to_jsonb(v_row);
end;
$function$;

create or replace function public.items_share(p_user_id uuid,p_item_id uuid,p_shared boolean,p_target uuid)
returns jsonb language plpgsql security definer
set search_path to 'public','extensions'
as $function$
declare v_room uuid; v_on boolean:=coalesce(p_shared,false); v_row public.shared_items;
begin
  select room_id into v_room from public.shared_items where id=p_item_id;
  if v_room is null or not public._lib_is_room_master(p_user_id,v_room) then
    raise exception 'Somente o mestre pode compartilhar itens.' using errcode='42501';
  end if;
  if v_on and p_target is not null and not public._items_is_member(p_target,v_room) then
    raise exception 'O jogador escolhido não participa desta mesa.' using errcode='22023';
  end if;
  update public.shared_items set is_shared=v_on,target_user_id=case when v_on then p_target else null end,
    shared_at=case when v_on then now() else shared_at end,updated_at=now()
  where id=p_item_id returning * into v_row;
  return to_jsonb(v_row);
end;
$function$;

create or replace function public.items_delete(p_user_id uuid,p_item_id uuid)
returns void language plpgsql security definer
set search_path to 'public','extensions'
as $function$
declare v_room uuid;
begin
  select room_id into v_room from public.shared_items where id=p_item_id;
  if v_room is null or not public._lib_is_room_master(p_user_id,v_room) then
    raise exception 'Somente o mestre pode apagar itens.' using errcode='42501';
  end if;
  delete from public.shared_items where id=p_item_id;
end;
$function$;

revoke execute on function public.items_list(uuid,uuid) from public;
revoke execute on function public.items_save(uuid,uuid,uuid,text,text,text) from public;
revoke execute on function public.items_share(uuid,uuid,boolean,uuid) from public;
revoke execute on function public.items_delete(uuid,uuid) from public;
grant execute on function public.items_list(uuid,uuid) to anon,authenticated;
grant execute on function public.items_save(uuid,uuid,uuid,text,text,text) to anon,authenticated;
grant execute on function public.items_share(uuid,uuid,boolean,uuid) to anon,authenticated;
grant execute on function public.items_delete(uuid,uuid) to anon,authenticated;
