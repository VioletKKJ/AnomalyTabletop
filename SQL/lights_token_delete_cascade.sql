-- Anomaly VTT: ao excluir um token, excluir também a luz vinculada.
-- A luz vinculada representa um equipamento/fonte carregado pelo token.
ALTER TABLE public.lights
  DROP CONSTRAINT lights_token_id_fkey;

ALTER TABLE public.lights
  ADD CONSTRAINT lights_token_id_fkey
  FOREIGN KEY (token_id) REFERENCES public.tokens(id) ON DELETE CASCADE;
