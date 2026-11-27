-- Anomaly VTT: gerenciamento de arquivos por mesa.
-- A exclusão passa pela Edge Function room-storage-manager, que valida
-- a associação do mestre à mesa e usa a Storage API com service_role no servidor.
-- Não excluir objetos de Storage diretamente via SQL.
-- O bucket tabletop continua público por URL direta, mas não deve permitir enumeração.
-- A listagem é feita apenas pela Edge Function usando service_role no servidor.
DROP POLICY IF EXISTS "Delete tabletop" ON storage.objects;
DROP POLICY IF EXISTS "Public read tabletop" ON storage.objects;
