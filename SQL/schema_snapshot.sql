-- =====================================================================
-- ANOMALY VTT - SUPABASE DATABASE SNAPSHOT
-- Capturado do projeto conectado em 2026-11-19.
--
-- Snapshot de estrutura, sem dados de usuários/senhas/mesas/tokens/arquivos.
-- Inclui tabelas, constraints, funções RPC, policies RLS e índices.
--
-- ATENÇÃO:
-- - Arquivo de referência/versionamento; não aplicar cegamente em banco
--   existente. CREATE TABLE/FUNCTION/POLICY podem conflitar.
-- - Tabelas ordenadas pelas dependências conhecidas das FKs.
-- - Estado RLS abaixo reproduz o banco atual, intencionalmente.
--   Não habilitar/desabilitar RLS nem alterar policies automaticamente.
-- - pgcrypto está instalado no schema "extensions" no projeto atual.
-- - Schemas internos do Supabase (auth/storage/realtime etc.) não são
--   exportados; policies de storage.objects estão incluídas.
-- =====================================================================

-- 1. Tabelas públicas e constraints

CREATE TABLE public.auth_users (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  username text NOT NULL,
  password_hash text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT auth_users_pkey PRIMARY KEY (id),
  CONSTRAINT auth_users_username_key UNIQUE (username)
);

CREATE TABLE public.profiles (
  id uuid NOT NULL,
  display_name text,
  role text DEFAULT 'jogador'::text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth_users(id) ON DELETE CASCADE,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_role_check CHECK ((role = ANY (ARRAY['mestre'::text, 'jogador'::text])))
);

CREATE TABLE public.rooms (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  code text NOT NULL,
  active_scene_id uuid,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT rooms_code_key UNIQUE (code),
  CONSTRAINT rooms_created_by_fkey FOREIGN KEY (created_by) REFERENCES profiles(id) ON DELETE CASCADE,
  CONSTRAINT rooms_pkey PRIMARY KEY (id)
);

CREATE TABLE public.scenes (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  name text NOT NULL,
  map_url text,
  created_at timestamp with time zone DEFAULT now(),
  room_id uuid,
  grid_config jsonb,
  CONSTRAINT scenes_pkey PRIMARY KEY (id),
  CONSTRAINT scenes_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE
);

CREATE TABLE public.board (
  id integer DEFAULT 1 NOT NULL,
  map_url text,
  updated_at timestamp with time zone DEFAULT now(),
  active_scene_id uuid,
  CONSTRAINT board_active_scene_id_fkey FOREIGN KEY (active_scene_id) REFERENCES scenes(id),
  CONSTRAINT board_pkey PRIMARY KEY (id)
);

CREATE TABLE public.room_members (
  room_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role text DEFAULT 'jogador'::text,
  CONSTRAINT room_members_pkey PRIMARY KEY (room_id, user_id),
  CONSTRAINT room_members_role_check CHECK ((role = ANY (ARRAY['mestre'::text, 'jogador'::text]))),
  CONSTRAINT room_members_room_id_fkey FOREIGN KEY (room_id) REFERENCES rooms(id) ON DELETE CASCADE,
  CONSTRAINT room_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE
);

CREATE TABLE public.drawings (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  scene_id uuid,
  kind text DEFAULT 'free'::text NOT NULL,
  points jsonb DEFAULT '[]'::jsonb NOT NULL,
  color text DEFAULT '#ffd54f'::text NOT NULL,
  width double precision DEFAULT 4 NOT NULL,
  author_id uuid,
  master_only boolean DEFAULT false NOT NULL,
  z bigint DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT drawings_author_id_fkey FOREIGN KEY (author_id) REFERENCES profiles(id) ON DELETE SET NULL,
  CONSTRAINT drawings_kind_check CHECK ((kind = ANY (ARRAY['free'::text, 'line'::text, 'rect'::text, 'ellipse'::text, 'arrow'::text]))),
  CONSTRAINT drawings_pkey PRIMARY KEY (id),
  CONSTRAINT drawings_scene_id_fkey FOREIGN KEY (scene_id) REFERENCES scenes(id) ON DELETE CASCADE
);

CREATE TABLE public.fog_elements (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  scene_id uuid,
  points text NOT NULL,
  z bigint DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  is_visible boolean DEFAULT true,
  CONSTRAINT fog_elements_pkey PRIMARY KEY (id),
  CONSTRAINT fog_elements_scene_id_fkey FOREIGN KEY (scene_id) REFERENCES scenes(id) ON DELETE CASCADE
);

CREATE TABLE public.lights (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  scene_id uuid,
  x double precision NOT NULL,
  y double precision NOT NULL,
  radius double precision DEFAULT 300,
  color text DEFAULT '#ffaa33'::text,
  intensity double precision DEFAULT 1.0,
  z bigint DEFAULT 0,
  CONSTRAINT lights_pkey PRIMARY KEY (id),
  CONSTRAINT lights_scene_id_fkey FOREIGN KEY (scene_id) REFERENCES scenes(id) ON DELETE CASCADE
);

CREATE TABLE public.map_elements (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  scene_id uuid,
  src_url text NOT NULL,
  x double precision DEFAULT 0 NOT NULL,
  y double precision DEFAULT 0 NOT NULL,
  size double precision DEFAULT 128 NOT NULL,
  rotation double precision DEFAULT 0 NOT NULL,
  flip_x boolean DEFAULT false NOT NULL,
  z double precision DEFAULT 1 NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  is_base boolean DEFAULT false NOT NULL,
  CONSTRAINT map_elements_pkey PRIMARY KEY (id),
  CONSTRAINT map_elements_scene_id_fkey FOREIGN KEY (scene_id) REFERENCES scenes(id) ON DELETE CASCADE
);

CREATE TABLE public.tokens (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  src_url text NOT NULL,
  x double precision DEFAULT 40 NOT NULL,
  y double precision DEFAULT 40 NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  size double precision DEFAULT 64 NOT NULL,
  z double precision DEFAULT 0 NOT NULL,
  rotation double precision DEFAULT 0 NOT NULL,
  flip_x boolean DEFAULT false NOT NULL,
  states _text DEFAULT '{}'::text[] NOT NULL,
  active_state integer DEFAULT 0 NOT NULL,
  scene_id uuid,
  owner_id uuid,
  vision_enabled boolean DEFAULT false NOT NULL,
  vision_radius double precision DEFAULT 400 NOT NULL,
  CONSTRAINT tokens_owner_id_fkey FOREIGN KEY (owner_id) REFERENCES profiles(id) ON DELETE SET NULL,
  CONSTRAINT tokens_pkey PRIMARY KEY (id),
  CONSTRAINT tokens_scene_id_fkey FOREIGN KEY (scene_id) REFERENCES scenes(id) ON DELETE CASCADE
);

CREATE TABLE public.walls (
  id uuid DEFAULT gen_random_uuid() NOT NULL,
  scene_id uuid,
  x1 double precision NOT NULL,
  y1 double precision NOT NULL,
  x2 double precision NOT NULL,
  y2 double precision NOT NULL,
  wall_type text DEFAULT 'wall'::text,
  is_open boolean DEFAULT false,
  z bigint DEFAULT 0,
  CONSTRAINT walls_pkey PRIMARY KEY (id),
  CONSTRAINT walls_scene_id_fkey FOREIGN KEY (scene_id) REFERENCES scenes(id) ON DELETE CASCADE
);

-- 2. Estado atual de Row Level Security

ALTER TABLE public.auth_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.board ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drawings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.fog_elements DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.lights DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.map_elements DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.room_members DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.scenes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.tokens DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.walls DISABLE ROW LEVEL SECURITY;

-- 3. Policies existentes (public e storage.objects)

CREATE POLICY "board select all" ON public.board AS permissive FOR SELECT TO public
  USING (true);

CREATE POLICY "Permitir leitura de map_elements para autenticados" ON public.map_elements AS permissive FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "map_elements select all" ON public.map_elements AS permissive FOR SELECT TO public
  USING (true);

CREATE POLICY "profiles select all" ON public.profiles AS permissive FOR SELECT TO public
  USING (true);

CREATE POLICY "scenes select all" ON public.scenes AS permissive FOR SELECT TO public
  USING (true);

CREATE POLICY "tokens select all" ON public.tokens AS permissive FOR SELECT TO public
  USING (true);

CREATE POLICY "Delete tabletop" ON storage.objects AS permissive FOR DELETE TO public
  USING ((bucket_id = 'tabletop'::text));

CREATE POLICY "Public read tabletop" ON storage.objects AS permissive FOR SELECT TO public
  USING ((bucket_id = 'tabletop'::text));

CREATE POLICY "Upload tabletop" ON storage.objects AS permissive FOR INSERT TO public
  WITH CHECK ((bucket_id = 'tabletop'::text));

-- 4. Índices adicionais (PK/UNIQUE são criados pelas constraints)

CREATE INDEX drawings_scene_idx ON public.drawings USING btree (scene_id);

-- 5. Funções do schema public

CREATE OR REPLACE FUNCTION public.add_map_element(p_user_id uuid, p_src_url text, p_x double precision, p_y double precision, p_size double precision, p_z double precision)
 RETURNS TABLE(id uuid, src_url text, x double precision, y double precision, size double precision, z double precision, rotation double precision, flip_x boolean, is_base boolean, scene_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
#variable_conflict use_column
declare v_scene_id uuid; v_row map_elements%rowtype;
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode adicionar peças'; end if;
  select b.active_scene_id into v_scene_id from board b where b.id = 1;
  insert into map_elements (scene_id, src_url, x, y, size, z) values (v_scene_id, p_src_url, p_x, p_y, p_size, p_z)
  returning * into v_row;
  return query select v_row.id, v_row.src_url, v_row.x, v_row.y, v_row.size, v_row.z, v_row.rotation, v_row.flip_x, v_row.is_base, v_row.scene_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.add_token(p_user_id uuid, p_src_url text, p_x double precision, p_y double precision, p_size double precision, p_z double precision)
 RETURNS TABLE(id uuid, src_url text, x double precision, y double precision, size double precision, z double precision, rotation double precision, flip_x boolean, states text[], active_state integer, scene_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
#variable_conflict use_column
declare v_scene_id uuid; v_row tokens%rowtype;
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode adicionar tokens'; end if;
  select b.active_scene_id into v_scene_id from board b where b.id = 1;
  insert into tokens (src_url, x, y, size, z, scene_id) values (p_src_url, p_x, p_y, p_size, p_z, v_scene_id)
  returning * into v_row;
  return query select v_row.id, v_row.src_url, v_row.x, v_row.y, v_row.size, v_row.z, v_row.rotation, v_row.flip_x, v_row.states, v_row.active_state, v_row.scene_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.add_token_state(p_user_id uuid, p_token_id uuid, p_url text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode adicionar estados'; end if;
  update tokens
  set states = array_append(states, p_url),
      active_state = coalesce(array_length(states, 1), 0) + 1
  where id = p_token_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.claim_mestre(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if exists (select 1 from profiles where role = 'mestre') then
    raise exception 'Já existe um mestre nesta mesa';
  end if;
  if not exists (select 1 from profiles where id = p_user_id) then
    raise exception 'Usuário inválido';
  end if;
  update profiles set role = 'mestre' where id = p_user_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.clear_board(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare v_scene_id uuid;
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode limpar a mesa'; end if;
  select active_scene_id into v_scene_id from board where id = 1;
  delete from tokens where scene_id = v_scene_id;
  delete from map_elements where scene_id = v_scene_id;
  update scenes set map_url = null where id = v_scene_id;
  update board set map_url = null where id = 1;
end;
$function$


CREATE OR REPLACE FUNCTION public.create_room(p_user_id uuid, p_name text, p_code text)
 RETURNS SETOF rooms
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_room_id UUID;
  v_scene_id UUID;
BEGIN
  INSERT INTO rooms (name, code, created_by)
  VALUES (p_name, p_code, p_user_id)
  RETURNING id INTO v_room_id;

  INSERT INTO scenes (room_id, name, map_url)
  VALUES (v_room_id, 'Cena Principal', '')
  RETURNING id INTO v_scene_id;

  UPDATE rooms SET active_scene_id = v_scene_id WHERE id = v_room_id;

  INSERT INTO room_members (room_id, user_id, role)
  VALUES (v_room_id, p_user_id, 'mestre')
  ON CONFLICT (room_id, user_id) DO UPDATE SET role = 'mestre';

  RETURN QUERY SELECT * FROM rooms WHERE id = v_room_id;
END;
$function$


CREATE OR REPLACE FUNCTION public.create_scene(p_user_id uuid, p_name text, p_map_url text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare new_id uuid;
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode criar cenas'; end if;
  insert into scenes (name, map_url) values (coalesce(nullif(trim(p_name), ''), 'Nova cena'), p_map_url)
  returning id into new_id;
  if p_map_url is not null then
    insert into map_elements (scene_id, src_url, x, y, size, z, is_base)
    values (new_id, p_map_url, 0, 0, 1024, 0, true);
  end if;
  update board set active_scene_id = new_id, map_url = p_map_url, updated_at = now() where id = 1;
  return new_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.delete_map_element(p_user_id uuid, p_element_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode apagar peças de mapa'; end if;
  delete from map_elements where id = p_element_id and is_base = false;
end;
$function$


CREATE OR REPLACE FUNCTION public.delete_room(p_user_id uuid, p_room_id uuid, p_password text, p_confirm_name text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
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

  -- Evita que a referência legada da tabela board bloqueie a exclusão das cenas.
  UPDATE public.board
     SET active_scene_id = NULL
   WHERE active_scene_id IN (
     SELECT s.id
     FROM public.scenes AS s
     WHERE s.room_id = p_room_id
   );

  -- As cenas e seus elementos são removidos pelas FKs ON DELETE CASCADE.
  DELETE FROM public.rooms
   WHERE id = p_room_id
     AND created_by = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'A mesa não foi encontrada ou não pode ser excluída.'
      USING ERRCODE = '42501';
  END IF;
END;
$function$


CREATE OR REPLACE FUNCTION public.delete_scene(p_user_id uuid, p_scene_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare v_active uuid; v_total int;
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode apagar cenas'; end if;
  select active_scene_id into v_active from board where id = 1;
  if v_active = p_scene_id then
    raise exception 'Troque para outra cena antes de apagar esta';
  end if;
  select count(*) into v_total from scenes;
  if v_total <= 1 then
    raise exception 'Precisa sobrar pelo menos uma cena';
  end if;
  delete from scenes where id = p_scene_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.delete_token(p_user_id uuid, p_token_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode apagar tokens'; end if;
  delete from tokens where id = p_token_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.flip_base_map_element(p_user_id uuid, p_element_id uuid, p_flip boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin perform public.flip_map_element(p_user_id, p_element_id, p_flip); end;
$function$


CREATE OR REPLACE FUNCTION public.flip_map_element(p_user_id uuid, p_element_id uuid, p_flip boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode espelhar peças de mapa'; end if;
  update map_elements set flip_x = p_flip where id = p_element_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.flip_token(p_user_id uuid, p_token_id uuid, p_flip boolean)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not exists (select 1 from profiles where id = p_user_id) then raise exception 'Usuário inválido'; end if;
  update tokens set flip_x = p_flip where id = p_token_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.get_user_rooms(p_user_id uuid)
 RETURNS TABLE(room_id uuid, room_name text, room_code text, user_role text, created_at timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT r.id, r.name, r.code, rm.role, r.created_at
  FROM room_members rm
  JOIN rooms r ON r.id = rm.room_id
  WHERE rm.user_id = p_user_id
  ORDER BY r.created_at DESC;
END;
$function$


CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
  insert into public.profiles (id, display_name, role)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', new.email), 'jogador')
  on conflict (id) do nothing;
  return new;
end;
$function$


CREATE OR REPLACE FUNCTION public.is_mestre()
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1 from profiles where id = auth.uid() and role = 'mestre'
  );
$function$


CREATE OR REPLACE FUNCTION public.is_mestre_id(p_user_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'extensions'
AS $function$
  select exists (select 1 from profiles where id = p_user_id and role = 'mestre');
$function$


CREATE OR REPLACE FUNCTION public.join_room(p_user_id uuid, p_code text)
 RETURNS SETOF rooms
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_room_id UUID;
BEGIN
  SELECT id INTO v_room_id FROM rooms WHERE code = p_code;
  
  IF v_room_id IS NULL THEN
    RAISE EXCEPTION 'Mesa com o código "%" não encontrada.', p_code;
  END IF;

  INSERT INTO room_members (room_id, user_id, role)
  VALUES (v_room_id, p_user_id, 'jogador')
  ON CONFLICT (room_id, user_id) DO NOTHING;

  RETURN QUERY SELECT * FROM rooms WHERE id = v_room_id;
END;
$function$


CREATE OR REPLACE FUNCTION public.login_user(p_username text, p_password text)
 RETURNS TABLE(out_id uuid, out_username text, out_role text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare v_id uuid;
begin
  select a.id into v_id
  from auth_users a
  where a.username = lower(trim(p_username))
    and a.password_hash = crypt(p_password, a.password_hash);

  if v_id is null then
    return; -- usuário ou senha errados: devolve zero linhas
  end if;

  -- Autoconserta uma conta cujo perfil sumiu (por exemplo, de uma
  -- migração/ajuste anterior) em vez de travar o login de alguém
  -- que tem a senha certa.
  insert into profiles (id, display_name, role)
  values (v_id, trim(p_username), 'jogador')
  on conflict (id) do nothing;

  return query select p.id, p.display_name, p.role from profiles p where p.id = v_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.move_base_map_element(p_user_id uuid, p_element_id uuid, p_x double precision, p_y double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin perform public.move_map_element(p_user_id, p_element_id, p_x, p_y); end;
$function$


CREATE OR REPLACE FUNCTION public.move_map_element(p_user_id uuid, p_element_id uuid, p_x double precision, p_y double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode mover peças de mapa'; end if;
  update map_elements set x = p_x, y = p_y where id = p_element_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.move_token(p_user_id uuid, p_token_id uuid, p_x double precision, p_y double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not exists (select 1 from profiles where id = p_user_id) then raise exception 'Usuário inválido'; end if;
  update tokens set x = p_x, y = p_y where id = p_token_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.resize_base_map_element(p_user_id uuid, p_element_id uuid, p_size double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin perform public.resize_map_element(p_user_id, p_element_id, p_size); end;
$function$


CREATE OR REPLACE FUNCTION public.resize_map_element(p_user_id uuid, p_element_id uuid, p_size double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode redimensionar peças de mapa'; end if;
  update map_elements set size = p_size where id = p_element_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.resize_token(p_user_id uuid, p_token_id uuid, p_size double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not exists (select 1 from profiles where id = p_user_id) then raise exception 'Usuário inválido'; end if;
  update tokens set size = p_size where id = p_token_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.rotate_base_map_element(p_user_id uuid, p_element_id uuid, p_rotation double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin perform public.rotate_map_element(p_user_id, p_element_id, p_rotation); end;
$function$


CREATE OR REPLACE FUNCTION public.rotate_map_element(p_user_id uuid, p_element_id uuid, p_rotation double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode girar peças de mapa'; end if;
  update map_elements set rotation = p_rotation where id = p_element_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.rotate_token(p_user_id uuid, p_token_id uuid, p_rotation double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not exists (select 1 from profiles where id = p_user_id) then raise exception 'Usuário inválido'; end if;
  update tokens set rotation = p_rotation where id = p_token_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.set_active_state(p_user_id uuid, p_token_id uuid, p_state integer)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not exists (select 1 from profiles where id = p_user_id) then raise exception 'Usuário inválido'; end if;
  update tokens set active_state = p_state where id = p_token_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.set_base_map_element_z(p_user_id uuid, p_element_id uuid, p_z double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin perform public.set_map_element_z(p_user_id, p_element_id, p_z); end;
$function$


CREATE OR REPLACE FUNCTION public.set_map(p_user_id uuid, p_map_url text)
 RETURNS TABLE(id uuid, src_url text, x double precision, y double precision, size double precision, z double precision, rotation double precision, flip_x boolean, is_base boolean, scene_id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
#variable_conflict use_column
declare v_scene_id uuid; v_row map_elements%rowtype;
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode trocar o mapa'; end if;
  select b.active_scene_id into v_scene_id from board b where b.id = 1;
  delete from map_elements m where m.scene_id = v_scene_id and m.is_base;
  update scenes s set map_url = p_map_url where s.id = v_scene_id;
  update board b set map_url = p_map_url, updated_at = now() where b.id = 1;
  insert into map_elements (scene_id, src_url, x, y, size, z, is_base)
  values (v_scene_id, p_map_url, 0, 0, 1024, 0, true)
  returning * into v_row;
  return query select v_row.id, v_row.src_url, v_row.x, v_row.y, v_row.size, v_row.z, v_row.rotation, v_row.flip_x, v_row.is_base, v_row.scene_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.set_map_element_z(p_user_id uuid, p_element_id uuid, p_z double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode mudar a camada de peças de mapa'; end if;
  update map_elements set z = p_z where id = p_element_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.set_role(p_acting_user_id uuid, p_target_user_id uuid, p_new_role text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_mestre_id(p_acting_user_id) then
    raise exception 'Só o mestre pode fazer isso';
  end if;
  if p_new_role not in ('mestre', 'jogador') then
    raise exception 'Papel inválido';
  end if;
  if p_new_role = 'mestre' then
    update profiles set role = 'jogador' where role = 'mestre';
  end if;
  update profiles set role = p_new_role where id = p_target_user_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.set_scene(p_user_id uuid, p_scene_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare v_map_url text;
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode trocar de cena'; end if;
  select map_url into v_map_url from scenes where id = p_scene_id;
  if not found then raise exception 'Cena não encontrada'; end if;
  update board set active_scene_id = p_scene_id, map_url = v_map_url, updated_at = now() where id = 1;
end;
$function$


CREATE OR REPLACE FUNCTION public.set_token_vision(p_user_id uuid, p_token_id uuid, p_enabled boolean, p_radius double precision, p_owner uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre configura a visão dos tokens'; end if;
  update tokens
     set vision_enabled = coalesce(p_enabled, false),
         vision_radius  = greatest(20, least(coalesce(p_radius, 400), 5000)),
         owner_id       = p_owner
   where id = p_token_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.set_token_z(p_user_id uuid, p_token_id uuid, p_z double precision)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
begin
  if not exists (select 1 from profiles where id = p_user_id) then raise exception 'Usuário inválido'; end if;
  update tokens set z = p_z where id = p_token_id;
end;
$function$


CREATE OR REPLACE FUNCTION public.signup_user(p_username text, p_password text)
 RETURNS TABLE(out_id uuid, out_username text, out_role text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare new_id uuid;
begin
  if p_username is null or length(trim(p_username)) < 2 then
    raise exception 'Escolha um usuário com pelo menos 2 letras';
  end if;
  if p_password is null or length(p_password) < 4 then
    raise exception 'A senha precisa ter pelo menos 4 caracteres';
  end if;

  insert into auth_users (username, password_hash)
  values (lower(trim(p_username)), crypt(p_password, gen_salt('bf')))
  returning auth_users.id into new_id;

  insert into profiles (id, display_name, role) values (new_id, trim(p_username), 'jogador');

  return query select p.id, p.display_name, p.role from profiles p where p.id = new_id;
exception when unique_violation then
  raise exception 'Esse usuário já existe, escolha outro';
end;
$function$


CREATE OR REPLACE FUNCTION public.update_token_image(p_user_id uuid, p_token_id uuid, p_url text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
declare
  v_tok tokens%rowtype;
begin
  if not public.is_mestre_id(p_user_id) then raise exception 'Só o mestre pode alterar tokens'; end if;
  select * into v_tok from tokens where id = p_token_id;
  if not found then raise exception 'Token não encontrado'; end if;
  
  if v_tok.active_state = 0 then
    update tokens set src_url = p_url where id = p_token_id;
  else
    update tokens 
    set states[v_tok.active_state] = p_url 
    where id = p_token_id;
  end if;
end;
$function$

