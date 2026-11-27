-- Anomaly VTT: gerenciamento de arquivos por mesa.
-- A exclusão passa pela Edge Function room-storage-manager, que valida
-- a associação do mestre à mesa e usa a Storage API com service_role no servidor.
-- Não excluir objetos de Storage diretamente via SQL.
-- O bucket tabletop permanece público para leitura porque mapas, tokens e mídias
-- existentes usam URLs públicas. A listagem administrativa não é exposta no frontend.
DROP POLICY IF EXISTS "Delete tabletop" ON storage.objects;
