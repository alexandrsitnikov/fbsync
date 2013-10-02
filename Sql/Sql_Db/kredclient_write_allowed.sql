SET TERM ^ ;

ALTER PROCEDURE SP_SYNC_LOG_WRITE_ALLOWED (
    table_name varchar(50),
    mode char(1),
    row_id varchar(256))
returns (
    allowed smallint)
as
begin

-- !!! THIS IS AN INTERNAL PROCEDURE !!! DO NOT CALL IT FROM YOUR CODE !!!

--------------------------------------------------------------------------------
-- Sync System for Firebird 2.0
-- (C) Copyright, Alexandr Sitnikov, Blagoveschensk, 2007
--------------------------------------------------------------------------------

-- this procedure is returning 1 if is it OK to write to the log.
-- this is a placeholder

  allowed = 1;

  -- a?aiaiiay caeeaaea aey ia?aaiaa nenoaiu neio?iiecaoee e?aaeoiiai eeeaioa
  -- ia iiaue iaoaiecui

  if (CURRENT_USER starting with 'SYNC_DB') then
   allowed = 0;

  suspend;
end
^

SET TERM ; ^


