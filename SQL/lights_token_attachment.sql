-- Anomaly VTT: permite vincular uma fonte de luz a um token.
-- Ao excluir o token, a luz permanece na cena como fonte independente.
ALTER TABLE public.lights
  ADD COLUMN token_id uuid NULL
  REFERENCES public.tokens(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_lights_token_id
  ON public.lights(token_id)
  WHERE token_id IS NOT NULL;
